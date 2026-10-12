package Log::Abstraction::Backend::Object;

# The object backend: call the logger object's method for the level
use strict;
use warnings;

use parent 'Log::Abstraction::Backend';

use Carp ();

our $VERSION = '0.40';

=head1 NAME

Log::Abstraction::Backend::Object - call a logger object's method for each message

=head1 VERSION

0.40

=head1 DESCRIPTION

Built for any object given as the C<logger> other than a L<Log::Any> logger
or a L<Log::Dispatch> object (see L<Log::Abstraction::Backend::LogAny> and
L<Log::Abstraction::Backend::LogDispatch>), e.g. a L<Log::Log4perl> logger.
The method named after the level is called with the message's parts, and
the structured fields as C<key=value> text.  An object without a
C<notice> method gets C<info>; one without C<critical>, C<alert> or
C<emergency> gets C<fatal>, or else C<error>.  Otherwise it croaks.

For use by L<Log::Abstraction> only; see L<Log::Abstraction::Backend>.

=head1 METHODS

=head2 emit

  $backend->emit($logger, $event);

=cut

sub emit {
	my ($self, $logger, $event) = @_;

	my $object = $self->{'object'};
	my $method = $event->{'level'};
	if(!$object->can($method)) {
		# Log::Log4perl has no notice(), critical(), alert() or
		# emergency(); use the nearest method it does have
		my @fallbacks = ($method eq 'notice') ? ('info')
			: ($method =~ /^(?:critical|alert|emergency)$/) ? ('fatal', 'error')
			: ();
		($method) = grep { $object->can($_) } @fallbacks;
		if(!defined($method)) {
			Carp::croak(
				ref($logger), ': ', ref($object),
				" doesn't know how to deal with the $event->{level} message",
			);
		}
	}
	my $fields_text = $event->{'fields_text'};
	$object->$method(
		@{$event->{'parts'}},
		(defined($fields_text) ? ((length($event->{'message'}) ? ' ' : '') . $fields_text) : ()),
	);
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
