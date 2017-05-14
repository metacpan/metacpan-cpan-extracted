package TestHelper;

use strict;
use warnings;

=head1 NAME

TestHelper

=head1 DESCRIPTION

TestHelper for hopkins

=cut

use POE::API::Peek;

use base 'POE::API::Peek';

=head1 METHODS

=over 4

=item new

=cut

sub events_waiting
{
	my $self	= shift;
	my $alias	= shift;

	my $session	= $self->resolve_alias($alias);
	my @queue	= $self->event_queue_dump;

	my @list =
		grep { $_ ne '_garbage_collect' }
		map { $_->{event} }
		grep { $session->ID == $_->{destination}->ID } @queue;

	return \@list;
}

sub sessions_running
{
	my $self	= shift;
	my @aliases	= @_;

	foreach my $session ($self->session_list) {
		shift @aliases if scalar(@aliases)
			&& grep { $aliases[0] eq $_ } $self->session_alias_list($session);
	}

	return scalar @aliases ? 0 : 1;
}

=head1 SEE ALSO

L<TestHelper>

=head1 AUTHOR

Mike Eldridge <diz@cpan.org>

=head1 LICENSE

=cut

1;

