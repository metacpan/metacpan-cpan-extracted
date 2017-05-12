package Log::Dispatch::Pipe;
use 5.008001;
use strict;
use warnings;
our $VERSION = "0.06";

use Log::Dispatch 2.00;
use parent 'Log::Dispatch::Output';

use Scalar::Util qw(openhandle);

sub new {
    my ($proto, %params) = @_;
    my $class = ref $proto || $proto;

    my $self = bless {}, $class;
    $self->_basic_init(%params);
    $self->_init(%params);

    $self;
}

sub _init {
    my ($self, %params) = @_;

    $self->{output_to} = $params{output_to};
    $self->{binmode}   = $params{binmode};

    $self->_open_handle if $params{try_at_init};
}

sub _open_handle {
    my $self = shift;

    open my $fh, '|-', $self->{output_to}
        or die "Failed opening pipe: $!";

    my $oldfh = select $fh;
    $| = 1;
    select $oldfh;

    binmode $fh, $self->{binmode}
        if $self->{binmode};

    $fh;
}

sub log_message {
    my ($self, %params) = @_;

    $self->{fh} ||= $self->_open_handle;

    my $fh = $self->{fh};
    print $fh $params{message};
}

sub DESTROY {
    my $self = shift;
    close $self->{fh} if $self->{fh} and openhandle($self->{fh});
}

1;
__END__

=encoding utf-8

=head1 NAME

Log::Dispatch::Pipe - Object for logging to pipe output

=head1 SYNOPSIS

    use Log::Dispatch;

    my $log = Log::Dispatch->new(
        outputs => [
            [
                'Pipe',
                min_level => 'info',
                output_to => 'cronolog path/to/%Y-%m-%d/something.log',
                binmode   => ':utf8',
            ]
        ],
    );

=head1 DESCRIPTION

This module provides a simple object for logging to pipe under the Log::Dispatch::* system.

=head1 METHODS

=head2 new

The constructor takes the following parameters in addition to the standard parameters documented in L<Log::Dispatch::Output>:

=over 4

=item output_to :Str

A process to be created via pipe, like "cronolog path/to/file.log".

=item binmode :Str

A layer name to be passed to binmode, like ":utf8".  Default is none.

=item try_at_init :Int

If set to C<1>, a file handle is created to make sure it can be created at initialization.  Default is C<0>.

=back

=head1 SEE ALSO

L<Log::Dispatch>

=head1 LICENSE

Copyright (C) yowcow.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

yowcow E<lt>yowcow@cpan.orgE<gt>

=cut

