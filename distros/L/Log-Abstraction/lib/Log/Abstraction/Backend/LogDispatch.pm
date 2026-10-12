package Log::Abstraction::Backend::LogDispatch;

# The log_dispatch backend: send messages on to Log::Dispatch
use strict;
use warnings;

use parent 'Log::Abstraction::Backend';

use Carp ();
use Readonly ();

our $VERSION = '0.40';

# The Log::Dispatch level name for each internal level name
Readonly::Hash my %LEVEL => (
	trace     => 'debug',    # Log::Dispatch has nothing below debug
	debug     => 'debug',
	info      => 'info',
	notice    => 'notice',
	warn      => 'warning',
	error     => 'error',
	critical  => 'critical',
	alert     => 'alert',
	emergency => 'emergency',
);

=head1 NAME

Log::Abstraction::Backend::LogDispatch - send messages on to Log::Dispatch

=head1 VERSION

0.40

=head1 DESCRIPTION

Built for the C<log_dispatch> key of a C<logger> hash, or a
L<Log::Dispatch> object as the C<logger>.  Calls its C<log()> method with
the level (C<warn> becomes C<warning>, and C<trace>, which Log::Dispatch
doesn't have, C<debug>) and the message with the structured fields as
C<key=value> text, or with a C<format> the formatted line.  If
Log::Dispatch dies, it carps.

Nothing is sent while a message is already being forwarded (see
C<$Log::Abstraction::Backend::FORWARDING>).

For use by L<Log::Abstraction> only; see L<Log::Abstraction::Backend>.

=head1 METHODS

=head2 emit

  $backend->emit($logger, $event);

=cut

sub emit {
	my ($self, $logger, $event) = @_;

	return if($Log::Abstraction::Backend::FORWARDING);
	local $Log::Abstraction::Backend::FORWARDING = 1;

	my $ok = eval {
		$self->{'log_dispatch'}->log(
			level   => $LEVEL{$event->{'level'}},
			message => $self->text($event, $event->{'text'}),
		);
		1;
	};
	Carp::carp(ref($logger), ": Log::Dispatch failed: $@") if(!$ok);
}

=head1 AUTHOR

Nigel Horne C<njh@nigelhorne.com>

=head1 SEE ALSO

L<Log::Abstraction>, L<Log::Abstraction::Backend>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2025-2026 Nigel Horne

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
