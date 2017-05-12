package # hide from PAUSE
	Hopkins::Plugin::HMI::Catalyst::Controller::Work;
BEGIN {
  $Hopkins::Plugin::HMI::Catalyst::Controller::Work::VERSION = '0.900';
}

use strict;
use warnings;

=head1 NAME

Hopkins::Plugin::HMI::Catalyst::Controller::Work

=head1 DESCRIPTION

=cut

use base 'Hopkins::Plugin::HMI::Catalyst::Controller';

=head1 METHODS

=cut

=over 4

=item abort

=cut

sub abort : Local
{
	my $self	= shift;
	my $c		= shift;
	my $queue	= shift;
	my $id		= shift;

	$c->config->{hopkins}->kernel->post(manager => abort => $queue => $id);

	$c->res->redirect($c->uri_for('/queue/details', $queue ));
}

=back

=head1 AUTHOR

Mike Eldridge <diz@cpan.org>

=head1 LICENSE

This program is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=cut

1;
