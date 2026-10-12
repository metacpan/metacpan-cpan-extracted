package Log::Abstraction::Backend::Sendmail;

# The sendmail backend: email messages, throttled and optionally held in a digest
use strict;
use warnings;

use parent 'Log::Abstraction::Backend';

our $VERSION = '0.40';

=head1 NAME

Log::Abstraction::Backend::Sendmail - email messages

=head1 VERSION

0.40

=head1 DESCRIPTION

Built for the C<sendmail> key of a C<logger> hash.  Each message (or, with
a C<format>, the formatted line) is emailed, unless C<min_interval> seconds
have not passed since the last email; then it is dropped, or with
C<digest> held for the next email.  Log::Abstraction does the sending and
holds the throttle and digest state, which C<flush()> also uses.

For use by L<Log::Abstraction> only; see L<Log::Abstraction::Backend>.

=head1 METHODS

=head2 emit

  $backend->emit($logger, $event);

=cut

sub emit {
	my ($self, $logger, $event) = @_;

	my $sm = $self->{'sendmail'};
	my $body = $self->text($event, $event->{'text'});

	# Honour the minimum-interval throttle
	my $throttled = 0;
	if(my $interval = $sm->{'min_interval'}) {
		my $last = $logger->{'_last_email_sent'};
		$throttled = defined($last) && ((time() - $last) < $interval);
	}

	# A throttled message is dropped, or with digest held for the next
	# email.  A failed send doesn't stop the other backends (it carps)
	if(!$throttled) {
		$event->{'send_email'}->($sm, $body);
	} elsif($sm->{'digest'}) {
		$event->{'hold_email'}->($sm, $body);
	}
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
