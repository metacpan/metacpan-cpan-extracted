package # hide from PAUSE
	Hopkins::Plugin::HMI::Catalyst::Controller::Queue;
BEGIN {
  $Hopkins::Plugin::HMI::Catalyst::Controller::Queue::VERSION = '0.900';
}

use strict;
use warnings;

=head1 NAME

Hopkins::Plugin::HMI::Catalyst::Controller::Queue

=head1 DESCRIPTION

=cut

use base 'Hopkins::Plugin::HMI::Catalyst::Controller';

=head1 METHODS

=cut

=over 4

=item halt

=cut

sub halt : Local
{
	my $self	= shift;
	my $c		= shift;
	my $name	= shift;

	$c->config->{hopkins}->queue($name)->halt;

	$c->res->redirect($c->req->referer);
}

=item start

=cut

sub start : Local
{
	my $self	= shift;
	my $c		= shift;
	my $name	= shift;

	$c->config->{hopkins}->queue($name)->start;

	$c->res->redirect($c->req->referer);
}

=item freeze

=cut

sub freeze : Local
{
	my $self	= shift;
	my $c		= shift;
	my $name	= shift;

	$c->config->{hopkins}->queue($name)->freeze;

	$c->res->redirect($c->req->referer);
}

=item thaw

=cut

sub thaw : Local
{
	my $self	= shift;
	my $c		= shift;
	my $name	= shift;

	$c->config->{hopkins}->queue($name)->thaw;

	$c->res->redirect($c->req->referer);
}

=item details

=cut

sub details : Local
{
	my $self	= shift;
	my $c		= shift;
	my $name	= shift;

	my $queue = $c->config->{hopkins}->queue($name);

	$c->res->redirect($c->uri_for('/status')) if not defined $queue;

	$c->stash->{queue}		= $queue;
	$c->stash->{template}	= 'queue/details.tt';
}

=back

=head1 AUTHOR

Mike Eldridge <diz@cpan.org>

=head1 LICENSE

This program is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=cut

1;
