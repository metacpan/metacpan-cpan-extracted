package MVC::Neaf::X::ServerStat;

use strict;
use warnings;

our $VERSION = 0.19;

=head1 NAME

MVC::Neaf::X::ServerStat - server request/performance statistics.

=head1 DESCRIPTION

This module provides a simple interface to gather request timing statistics.

Despite being a part of Neaf (Not Even A Framework), it does not depend on
the rest of it and can be used se[parately.

=head1 SYNOPSIS

=head1 METHODS

=cut

use Carp;
use Time::HiRes qw(time);
use Scalar::Util qw(weaken);

=head2 new( %args )

Valid options:

=over

=item * on_write = CODEREF - a sub that will be executed when it's time
to flush data.

CODEREF is a function that receiver an arrayref containing arrayrefs with
the following data: script_name(), http status, time spent in controller,
total time spent, and Unix time when request came in. E.g.

    [
        [ "/path/to/app", 200, 0.01, 0.02, 10444555333 ]
    ]

This format MAY be extended in the future.

iitem * write_thresh_count (n) -
how many records may be accumulated before writing.

=item * write_thresh_time (n.nn) -
for how much time (in seconds) the data may be accumulated.

Set either to -1 to ensure EVERY record flushes immediately.

=back

No checks are done whatsoever, but this MAY change in the future.

=cut

sub new {
    my ($class, %opt) = @_;

    $opt{write_thresh_count} ||= 100;
    $opt{write_thresh_time}  ||= 10;

    my $self = bless \%opt, $class;

    $self->{on_write} ||= do {
        croak "$class->new(): do_write unimplemented and on_write not set"
            unless $class->can("do_write");

        my $other_self = $self;
        weaken $other_self; # avoid circular pointers
        sub {
            defined $other_self and $other_self->do_write( @_ );
        };
    };

    croak "$class->new(): on_write must be a coderef"
        unless ref $self->{on_write} eq 'CODE';

    return $self;
};

=head2 record_start()

Start motinoring a request.

=cut

sub record_start {
    my $self = shift;

    carp "WARN: ".(ref $self)
        . "->record_start() called but previous still running: "
        . $self->{current_request}->[0] || "(unknown)"
            if exists $self->{current_request};

    $self->{current_request} = [ undef, undef, undef, undef, time ];
    return $self;
};

=head2 record_controller( $req->script_name )

When the controller is done, make the first record.

B<EXPERIMENTAL>. The name may change in the future.

=cut

sub record_controller {
    my ($self, $path) = @_;

    if (!exists $self->{current_request}) {
        carp "WARN: ".(ref $self)
            ."->record_controller() called but no request was started";
        return;
    };

    $self->{current_request}->[0] = $path;
    $self->{current_request}->[2] = time - $self->{current_request}->[4];

    return $self;
};

=head2 record_finish( $status [, $req] )

Finish monitoring request, possible flushing the data via on_write.

If 2nd argument is given, use it to postpone recording data.
This is done so to avoid delaying the request being served.

If 2nd argument is missing, data is flushed immediately
if either threshold (see new()) has been exceeded.

=cut

sub record_finish {
    my ($self, $status, $req) = @_;

    if (!exists $self->{current_request}) {
        carp "WARN: ".(ref $self)
            ."->record_finish() called but no request was started";
        return;
    };

    $self->{current_request}->[1] = $status;
    $self->{current_request}->[3] = time - $self->{current_request}->[4];

    my $q = $self->{queue} ||= [];
    push @$q, delete $self->{current_request};

    if ( scalar @$q >= $self->{write_thresh_count}
        or $q->[-1][4] - $q->[0][4] >= $self->{write_thresh_time} ) {
            delete $self->{queue};
            my $do_write = $self->{on_write};
            $req
                ? $req->postpone( sub { $do_write->($q) } )
                : $do_write->($q);
    };

    return $self;
};

=head2 do_write( [[ ... ], ... ] )

If this method is implemented in a subclass,
it will be used instead of on_write callback if no such callback provided.

The first argument is the stat object itself,
the second one is the same as for on_write.

=cut

sub DESTROY {
    my $self = shift;

    # always write stats on exit
    if ($self->{on_write} and $self->{queue}) {
        $self->{on_write}->( delete $self->{queue} );
    };
};

1;
