package Log::Any::Adapter::Sentry::Raven;

# ABSTRACT: Log::Any::Adapter for Sentry::Raven
use version;
our $VERSION = 'v0.0.1'; # VERSION

#pod =head1 SYNPOSIS
#pod
#pod     use Log::Any::Adapter;
#pod     Log::Any::Adapter->set('Sentry::Raven',
#pod         sentry => Sentry::Raven->new(
#pod             sentry_dsn  => $dsn,
#pod             environment => 'production',
#pod             ...
#pod         )
#pod     );
#pod
#pod =head1 DESCRIPTION
#pod
#pod This is a backend to L<Log::Any> for L<Sentry::Raven>.
#pod
#pod It takes two arguments:
#pod
#pod =over
#pod
#pod =item sentry (REQUIRED)
#pod
#pod An instantiated L<Sentry::Raven> object.
#pod Note that if you set any sentry-specific context directly through the sentry
#pod object, it will be picked up here eg.
#pod
#pod     $sentry->add_context( Sentry::Raven->request_context($url, %p) )
#pod
#pod If L<Devel::StackTrace> is installed, this will add a stack trace for you
#pod (As of writing, L<Sentry::Raven> requires it, so it will be).
#pod
#pod =item log_level (OPTIONAL)
#pod
#pod The minimum log_level to log. Defaults to C<trace> (everything).
#pod
#pod =back
#pod
#pod Any L<Log::Any/Log context data> will be sent to Sentry as tags.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Log::Any>, L<Sentry::Raven>
#pod
#pod =cut

use strict;
use warnings;

use Carp qw(carp croak);
use Log::Any::Adapter::Util qw(make_method numeric_level);
use Scalar::Util qw(blessed);
use Sentry::Raven;

use base qw(Log::Any::Adapter::Base);

sub init {
    my $self = shift;

    my $sentry = $self->{sentry};
    croak "An initialized Sentry::Raven object must be passed as the 'sentry' arg"
        unless blessed($sentry) && $sentry->isa('Sentry::Raven');

    # copied from Log::Any::Adapter::Stderr
    if ( exists $self->{log_level} && $self->{log_level} =~ /\D/ ) {
        my $numeric_level = numeric_level( $self->{log_level} );
        if ( !defined($numeric_level) ) {
            carp( sprintf 'Invalid log level "%s". Defaulting to "%s"', $self->{log_level}, 'trace' );
        }
        $self->{log_level} = $numeric_level;
    }
    if ( !defined $self->{log_level} ) {
        $self->{log_level} = numeric_level('trace');
    }
}

my $Include_Stack_Trace = do { eval { require Devel::StackTrace; 1 } };
sub structured {
    my ($self, $level, $category, @log_args) = @_;

    my $is_level = "is_$level";
    return unless $self->$is_level;

    my $log_any_context = {};
    if ((ref $log_args[-1]) eq 'HASH') {
        $log_any_context = pop @log_args;
    }

    my $log_message = join "\n" => @log_args;

    my $sentry_severity = $level;
    for ($sentry_severity) {
        s/trace/debug/ or
        s/notice/info/ or
        s/critical|alert|emergency/fatal/
    }

    my @message_args = (
        $log_message,
        level => $sentry_severity,
        tags  => $log_any_context,
    );
    if ($Include_Stack_Trace) {
        push @message_args,
             Sentry::Raven->stacktrace_context(Devel::StackTrace->new)
    }

    # https://docs.sentry.io/data-management/event-grouping/
    $self->{sentry}->capture_message( @message_args );
}

for my $method ( Log::Any->detection_methods() ) {
    my $method_base = substr($method, 3); # chop of is_
    my $method_level = numeric_level($method_base);
    make_method(
        $method,
        sub { return $method_level <= $_[0]->{log_level} },
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Any::Adapter::Sentry::Raven - Log::Any::Adapter for Sentry::Raven

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

This is a backend to L<Log::Any> for L<Sentry::Raven>.

It takes two arguments:

=over

=item sentry (REQUIRED)

An instantiated L<Sentry::Raven> object.
Note that if you set any sentry-specific context directly through the sentry
object, it will be picked up here eg.

    $sentry->add_context( Sentry::Raven->request_context($url, %p) )

If L<Devel::StackTrace> is installed, this will add a stack trace for you
(As of writing, L<Sentry::Raven> requires it, so it will be).

=item log_level (OPTIONAL)

The minimum log_level to log. Defaults to C<trace> (everything).

=back

Any L<Log::Any/Log context data> will be sent to Sentry as tags.

=head1 SYNPOSIS

    use Log::Any::Adapter;
    Log::Any::Adapter->set('Sentry::Raven',
        sentry => Sentry::Raven->new(
            sentry_dsn  => $dsn,
            environment => 'production',
            ...
        )
    );

=head1 SEE ALSO

L<Log::Any>, L<Sentry::Raven>

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 - 2020 by Grant Street Group.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
