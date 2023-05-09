use 5.008001;
use strict;
use warnings;

package Log::Any::Proxy::WithStackTrace;

# ABSTRACT: Log::Any proxy to upgrade string errors to objects with stack traces
our $VERSION = '1.715';

use Log::Any::Proxy;
our @ISA = qw/Log::Any::Proxy/;

use Devel::StackTrace 2.00;
use Log::Any::Adapter::Util ();
use overload;

#pod =head1 SYNOPSIS
#pod
#pod   use Log::Any qw( $log, proxy_class => 'WithStackTrace' );
#pod
#pod   # Some adapter that knows how to handle both structured data,
#pod   # and log messages which are actually objects with a
#pod   # "stack_trace" method:
#pod   #
#pod   Log::Any::Adapter->set($adapter);
#pod
#pod   $log->error("Help!");   # stack trace gets automatically added
#pod
#pod =head1 DESCRIPTION
#pod
#pod Some log adapters, like L<Log::Any::Adapter::Sentry::Raven>, are able to
#pod take advantage of being passed message objects that contain a stack
#pod trace.  However if a stack trace is not available, and fallback logic is
#pod used to generate one, the resulting trace can be confusing if it begins
#pod relative to where the log adapter was called, and not relative to where
#pod the logging method was originally called.
#pod
#pod With this proxy in place, if any logging method is called with a message
#pod that is a non-reference scalar, that message will be upgraded into a
#pod C<Log::Any::MessageWithStackTrace> object with a C<stack_trace> method,
#pod and that method will return a trace relative to where the logging method
#pod was called.  A string overload is provided on the object to return the
#pod original message.
#pod
#pod B<Important:> This proxy should be used with a L<Log::Any::Adapter> that
#pod is configured to handle structured data.  Otherwise the object created
#pod here will just get stringified before it can be used to access the stack
#pod trace.
#pod
#pod =cut

{
    package  # hide from PAUSE indexer
      Log::Any::MessageWithStackTrace;

    use overload '""' => \&stringify;

    use Carp qw( croak );

    sub new
    {
        my ($class, $message) = @_;
        croak 'no "message"' unless defined $message;
        return bless {
            message     => $message,
            stack_trace => Devel::StackTrace->new(
                # Filter e.g "Log::Any::Proxy", "My::Log::Any::Proxy", etc.
                ignore_package => [ qr/(?:^|::)Log::Any(?:::|$)/ ],
            ),
        }, $class;
    }

    sub stringify   { $_[0]->{message}     }

    sub stack_trace { $_[0]->{stack_trace} }
}

#pod =head1 METHODS
#pod
#pod =head2 maybe_upgrade_with_stack_trace
#pod
#pod This is an internal use method that will convert a non-reference scalar
#pod message into a C<Log::Any::MessageWithStackTrace> object with a
#pod C<stack_trace> method.  A string overload is provided to return the
#pod original message.
#pod
#pod =cut

sub maybe_upgrade_with_stack_trace
{
    my ($self, @args) = @_;

    # Only want a non-ref arg, optionally followed by a structured data
    # context hashref:
    #
    return @args unless   @args == 1 ||
                        ( @args == 2 && ref $args[1] eq 'HASH' );
    return @args if ref $args[0];

    $args[0] = Log::Any::MessageWithStackTrace->new($args[0]);

    return @args;
}

my %aliases = Log::Any::Adapter::Util::log_level_aliases();

# Set up methods/aliases and detection methods/aliases
foreach my $name ( Log::Any::Adapter::Util::logging_methods(), keys(%aliases) )
{
    my $super_name = "SUPER::" . $name;
    no strict 'refs';
    *{$name} = sub {
        my ($self, @args) = @_;
        @args = $self->maybe_upgrade_with_stack_trace(@args);
        my $response = $self->$super_name(@args);
        return $response if defined wantarray;
        return;
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Any::Proxy::WithStackTrace - Log::Any proxy to upgrade string errors to objects with stack traces

=head1 VERSION

version 1.715

=head1 SYNOPSIS

  use Log::Any qw( $log, proxy_class => 'WithStackTrace' );

  # Some adapter that knows how to handle both structured data,
  # and log messages which are actually objects with a
  # "stack_trace" method:
  #
  Log::Any::Adapter->set($adapter);

  $log->error("Help!");   # stack trace gets automatically added

=head1 DESCRIPTION

Some log adapters, like L<Log::Any::Adapter::Sentry::Raven>, are able to
take advantage of being passed message objects that contain a stack
trace.  However if a stack trace is not available, and fallback logic is
used to generate one, the resulting trace can be confusing if it begins
relative to where the log adapter was called, and not relative to where
the logging method was originally called.

With this proxy in place, if any logging method is called with a message
that is a non-reference scalar, that message will be upgraded into a
C<Log::Any::MessageWithStackTrace> object with a C<stack_trace> method,
and that method will return a trace relative to where the logging method
was called.  A string overload is provided on the object to return the
original message.

B<Important:> This proxy should be used with a L<Log::Any::Adapter> that
is configured to handle structured data.  Otherwise the object created
here will just get stringified before it can be used to access the stack
trace.

=head1 METHODS

=head2 maybe_upgrade_with_stack_trace

This is an internal use method that will convert a non-reference scalar
message into a C<Log::Any::MessageWithStackTrace> object with a
C<stack_trace> method.  A string overload is provided to return the
original message.

=head1 AUTHORS

=over 4

=item *

Jonathan Swartz <swartz@pobox.com>

=item *

David Golden <dagolden@cpan.org>

=item *

Doug Bell <preaction@cpan.org>

=item *

Daniel Pittman <daniel@rimspace.net>

=item *

Stephen Thirlwall <sdt@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jonathan Swartz, David Golden, and Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
