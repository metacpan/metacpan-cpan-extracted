package Log::Abstraction::Backend;

# Base class of the backends that Log::Abstraction sends messages to
use strict;
use warnings;

use Carp ();

our $VERSION = '0.40';

# Carp and croak from a backend report the code that called Log::Abstraction,
# not Log::Abstraction itself.  The subclasses trust this package through
# @ISA, and so Log::Abstraction too
our @CARP_NOT = ('Log::Abstraction');

# True while a message is being handed to Log::Any or Log::Dispatch.  If that
# brings it back to a Log::Abstraction (e.g. through
# Log::Any::Adapter::Abstraction), it isn't forwarded again, which would
# loop.  Set with local by the log_any and log_dispatch backends, and read by
# Log::Abstraction::_log to find the original caller
our $FORWARDING = 0;

=head1 NAME

Log::Abstraction::Backend - base class of the Log::Abstraction backends

=head1 VERSION

0.40

=head1 DESCRIPTION

For use by L<Log::Abstraction> only.  C<Log::Abstraction-E<gt>new()> builds
one object of a C<Log::Abstraction::Backend::*> class for each place a
message goes to (a file, an array, syslog ...), and each message is passed to
every one of them.  The configuration given to C<new()> is not changed.

The backends are:

  Log::Abstraction::Backend::Array        array, or logger => \@array
  Log::Abstraction::Backend::Code         logger => \&code
  Log::Abstraction::Backend::Fd           fd
  Log::Abstraction::Backend::File         file, or logger => $path
  Log::Abstraction::Backend::Journald     journald
  Log::Abstraction::Backend::LogAny       log_any, or a Log::Any logger
  Log::Abstraction::Backend::LogDispatch  log_dispatch, or a Log::Dispatch object
  Log::Abstraction::Backend::Object       any other object as the logger
  Log::Abstraction::Backend::Sendmail     sendmail
  Log::Abstraction::Backend::Syslog       syslog

=head1 METHODS

=head2 new

  my $backend = Log::Abstraction::Backend::File->new(
      file   => $path,
      level  => 4,        # numeric threshold, or undef for none
      format => $format,  # or undef
  );

Stores its arguments.  They have already been checked by
C<Log::Abstraction-E<gt>new()>; C<level> is a syslog number (0-7).

=head3 API SPECIFICATION

=head4 Input

  {
      level  => { type => 'integer', min => 0, max => 7, optional => 1 },
      format => { type => 'string', min => 1, optional => 1 },
      # and the destination, under the backend's own key (file, fd,
      # array, sendmail ...)
  }

=head4 Output

  { type => 'object', isa => 'Log::Abstraction::Backend' }

=cut

sub new {
	my ($class, %args) = @_;

	return bless { %args }, $class;
}

=head2 wants

  next unless $backend->wants($event);

True if the backend has no level of its own, or the message is at that level
or more severe.

=head3 API SPECIFICATION

=head4 Input

  { event => { type => 'hashref', schema => { priority => { type => 'integer', min => 0, max => 7 } } } }

=head4 Output

  { type => 'boolean' }

=cut

sub wants {
	my ($self, $event) = @_;

	return 1 unless(defined($self->{'level'}));
	return $event->{'priority'} <= $self->{'level'};
}

=head2 text

  my $message = $backend->text($event, $event->{text});

The message formatted with the backend's own C<format>, if it has one,
otherwise the default given.

=head3 API SPECIFICATION

=head4 Input

  {
      event   => { type => 'hashref', schema => { render => { type => 'coderef' } } },
      default => { type => 'string' },
  }

=head4 Output

  { type => 'string' }

=cut

sub text {
	my ($self, $event, $default) = @_;

	return defined($self->{'format'}) ? $event->{'render'}->($self->{'format'}) : $default;
}

=head2 emit

  $backend->emit($logger, $event);

Sends a message, which has passed the logger's level, to the backend.
C<$logger> is the C<Log::Abstraction> object.  C<$event> is a hash
reference built by C<Log::Abstraction> for each message:

  level        the level name, e.g. 'warn'
  priority     its syslog number (0-7)
  message      the message, its parts joined and redacted
  parts        the message's parts (an array reference)
  fields       the structured fields (a hash reference), or undef
  fields_text  the fields as key=value text, or undef
  text         the message with fields_text appended
  entry        the history entry (a list, as an array reference)
  class, file, line, ctx   for CODE references
  render       format a line: $event->{render}->($format), undef for
               the logger's format
  write        write a line to a path (which it checks) or a handle:
               $event->{write}->($target, $line)
  send_email, hold_email   send or keep for later an email:
               $event->{send_email}->(\%sendmail, $body)

The closures are how a backend uses Log::Abstraction's private methods.
Subclasses must override this.

=head3 API SPECIFICATION

=head4 Input

  {
      logger => { type => 'object', isa => 'Log::Abstraction' },
      event  => { type => 'hashref' },    # the keys above
  }

=head4 Output

  None.  The base class's emit() croaks "<class>: emit() is not
  implemented"; a subclass's sends the message.  A failed delivery is
  carped, not fatal; a configuration error (e.g. an invalid sendmail
  host) still croaks.

=cut

sub emit {
	my $self = shift;

	Carp::croak(ref($self), ': emit() is not implemented');
}

=head1 AUTHOR

Nigel Horne C<njh@nigelhorne.com>

=head1 SEE ALSO

L<Log::Abstraction>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2025-2026 Nigel Horne

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
