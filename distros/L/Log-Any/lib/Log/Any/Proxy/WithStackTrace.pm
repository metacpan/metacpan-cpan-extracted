use 5.008001;
use strict;
use warnings;

package Log::Any::Proxy::WithStackTrace;

# ABSTRACT: Log::Any proxy to upgrade string errors to objects with stack traces
our $VERSION = '1.717';

use Log::Any::Proxy;
our @ISA = qw/Log::Any::Proxy/;

use Devel::StackTrace 2.00;
use Log::Any::Adapter::Util ();
use Scalar::Util qw/blessed reftype/;
use overload;

#pod =head1 SYNOPSIS
#pod
#pod   use Log::Any qw( $log, proxy_class => 'WithStackTrace' );
#pod
#pod   # Allow stack trace call stack arguments to be logged:
#pod   use Log::Any qw( $log, proxy_class => 'WithStackTrace',
#pod                          proxy_show_stack_trace_args => 1 );
#pod
#pod   # Configure some adapter that knows how to:
#pod   #  1) handle structured data, and
#pod   #  2) handle message objects which have a "stack_trace" method:
#pod   Log::Any::Adapter->set($adapter);
#pod
#pod   $log->error("Help!");   # stack trace gets automatically added,
#pod                           # starting from this line of code
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
#pod With this proxy in place, if any logging method is called with a log
#pod message that is a non-reference scalar (i.e. a string), that log message
#pod will be upgraded into a C<Log::Any::MessageWithStackTrace> object with a
#pod C<stack_trace> method, and that method will return a trace relative to
#pod where the logging method was called.  A string overload is provided on
#pod the object to return the original log message.
#pod
#pod Additionally, any call stack arguments in the stack trace will be
#pod deleted before logging, to avoid accidentally logging sensitive data.
#pod This happens both for message objects that were auto-generated from
#pod string messages, as well as for message objects that were passed in
#pod directly (if they appear to have a stack trace method).  This default
#pod argument scrubbing behavior can be turned off by specifying a true value
#pod for the C<proxy_show_stack_trace_args> import flag.
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

    sub new
    {
        my ($class, $message, %opts) = @_;

        return bless {
            message     => $message,
            stack_trace => Devel::StackTrace->new(
                # Filter e.g "Log::Any::Proxy", "My::Log::Any::Proxy", etc.
                ignore_package => [ qr/(?:^|::)Log::Any(?:::|$)/ ],
                no_args => $opts{no_args},
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
#pod   @args = $self->maybe_upgrade_with_stack_trace(@args);
#pod
#pod This is an internal-use method that will convert a non-reference scalar
#pod message into a C<Log::Any::MessageWithStackTrace> object with a
#pod C<stack_trace> method.  A string overload is provided to return the
#pod original message.
#pod
#pod Stack trace args are scrubbed out in case they contain sensitive data,
#pod unless the C<proxy_show_stack_trace_args> option has been set.
#pod
#pod =cut

sub maybe_upgrade_with_stack_trace
{
    my ($self, @args) = @_;

    # We expect a message, optionally followed by a structured data
    # context hashref.  Bail if we get anything other than that rather
    # than guess what the caller might be trying to do:
    return @args unless   @args == 1 ||
                        ( @args == 2 && ref $args[1] eq 'HASH' );

    if (ref $args[0]) {
        $self->maybe_delete_stack_trace_args($args[0])
            unless $self->{proxy_show_stack_trace_args};
    }
    else {
        $args[0] = Log::Any::MessageWithStackTrace->new(
            $args[0],
            no_args => !$self->{proxy_show_stack_trace_args},
        );
    }

    return @args;
}

#pod =head2 maybe_delete_stack_trace_args
#pod
#pod   $self->maybe_delete_stack_trace_args($arg);
#pod
#pod This is an internal-use method that, given a single argument that is a
#pod reference, tries to figure out whether the argument is an object with a
#pod stack trace, and if so tries to delete any stack trace args.
#pod
#pod The logic is based on L<Devel::StackTrace::Extract>.
#pod
#pod It specifically looks for objects with a C<stack_trace> method (which
#pod should catch anything that does L<StackTrace::Auto>, including anything
#pod that does L<Throwable::Error>), or a C<trace> method (used by
#pod L<Exception::Class> and L<Moose::Exception> and friends).
#pod
#pod It specifically ignores L<Mojo::Exception> objects, because their stack
#pod traces don't contain any call stack args.
#pod
#pod =cut

sub maybe_delete_stack_trace_args
{
    my ($self, $arg) = @_;

    return unless blessed $arg;

    if ($arg->can('stack_trace')) {
        # This should catch anything that does StackTrace::Auto,
        # including anything that does Throwable::Error.
        my $trace = $arg->stack_trace;
        $self->delete_args_from_stack_trace($trace);
    }
    elsif ($arg->isa('Mojo::Exception')) {
        # Skip these, they don't have args in their stack traces.
    }
    elsif ($arg->can('trace')) {
        # This should catch Exception::Class and Moose::Exception and
        # friends.  Make sure to check for the "trace" method *after*
        # skipping the Mojo::Exception objects, because those also have
        # a "trace" method.
        my $trace = $arg->trace;
        $self->delete_args_from_stack_trace($trace);
    }

    return;
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

#pod =head2 delete_args_from_stack_trace($trace)
#pod
#pod   $self->delete_args_from_stack_trace($trace)
#pod
#pod To scrub potentially sensitive data from C<Devel::StackTrace> arguments,
#pod this method deletes arguments from all of the C<Devel::StackTrace::Frame>
#pod in the trace.
#pod
#pod =cut

sub delete_args_from_stack_trace
{
    my ($self, $trace) = @_;

    return unless $trace && $trace->can('frames');

    foreach my $frame ($trace->frames) {
        next unless $frame->{args};
        $frame->{args} = [];
    }

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Any::Proxy::WithStackTrace - Log::Any proxy to upgrade string errors to objects with stack traces

=head1 VERSION

version 1.717

=head1 SYNOPSIS

  use Log::Any qw( $log, proxy_class => 'WithStackTrace' );

  # Allow stack trace call stack arguments to be logged:
  use Log::Any qw( $log, proxy_class => 'WithStackTrace',
                         proxy_show_stack_trace_args => 1 );

  # Configure some adapter that knows how to:
  #  1) handle structured data, and
  #  2) handle message objects which have a "stack_trace" method:
  Log::Any::Adapter->set($adapter);

  $log->error("Help!");   # stack trace gets automatically added,
                          # starting from this line of code

=head1 DESCRIPTION

Some log adapters, like L<Log::Any::Adapter::Sentry::Raven>, are able to
take advantage of being passed message objects that contain a stack
trace.  However if a stack trace is not available, and fallback logic is
used to generate one, the resulting trace can be confusing if it begins
relative to where the log adapter was called, and not relative to where
the logging method was originally called.

With this proxy in place, if any logging method is called with a log
message that is a non-reference scalar (i.e. a string), that log message
will be upgraded into a C<Log::Any::MessageWithStackTrace> object with a
C<stack_trace> method, and that method will return a trace relative to
where the logging method was called.  A string overload is provided on
the object to return the original log message.

Additionally, any call stack arguments in the stack trace will be
deleted before logging, to avoid accidentally logging sensitive data.
This happens both for message objects that were auto-generated from
string messages, as well as for message objects that were passed in
directly (if they appear to have a stack trace method).  This default
argument scrubbing behavior can be turned off by specifying a true value
for the C<proxy_show_stack_trace_args> import flag.

B<Important:> This proxy should be used with a L<Log::Any::Adapter> that
is configured to handle structured data.  Otherwise the object created
here will just get stringified before it can be used to access the stack
trace.

=head1 METHODS

=head2 maybe_upgrade_with_stack_trace

  @args = $self->maybe_upgrade_with_stack_trace(@args);

This is an internal-use method that will convert a non-reference scalar
message into a C<Log::Any::MessageWithStackTrace> object with a
C<stack_trace> method.  A string overload is provided to return the
original message.

Stack trace args are scrubbed out in case they contain sensitive data,
unless the C<proxy_show_stack_trace_args> option has been set.

=head2 maybe_delete_stack_trace_args

  $self->maybe_delete_stack_trace_args($arg);

This is an internal-use method that, given a single argument that is a
reference, tries to figure out whether the argument is an object with a
stack trace, and if so tries to delete any stack trace args.

The logic is based on L<Devel::StackTrace::Extract>.

It specifically looks for objects with a C<stack_trace> method (which
should catch anything that does L<StackTrace::Auto>, including anything
that does L<Throwable::Error>), or a C<trace> method (used by
L<Exception::Class> and L<Moose::Exception> and friends).

It specifically ignores L<Mojo::Exception> objects, because their stack
traces don't contain any call stack args.

=head2 delete_args_from_stack_trace($trace)

  $self->delete_args_from_stack_trace($trace)

To scrub potentially sensitive data from C<Devel::StackTrace> arguments,
this method deletes arguments from all of the C<Devel::StackTrace::Frame>
in the trace.

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
