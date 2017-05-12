package # hide from PAUSE
	Hopkins::Plugin::HMI::Catalyst::Controller::Root;
BEGIN {
  $Hopkins::Plugin::HMI::Catalyst::Controller::Root::VERSION = '0.900';
}

use strict;
use warnings;

=head1 NAME


=head1 DESCRIPTION

=cut

use Sys::Hostname::FQDN 'fqdn';

use base 'Hopkins::Plugin::HMI::Catalyst::Controller';

__PACKAGE__->config->{namespace} = '';

=head1 METHODS

=cut

=over 4

=item new

=cut

sub auto : Private
{
	my $self	= shift;
	my $c		= shift;

	$c->stash->{host}	= fqdn;
	$c->stash->{now}	= DateTime->now(time_zone => 'local');

	$c->stash->{version} =
	{
		hopkins	=> $Hopkins::VERSION,
		plugin	=> { hmi => $Hopkins::Plugin::HMI::VERSION }
	};

	$c->detach('login') if not defined $c->user;

	1;
}

sub default : Private
{
	my $self	= shift;
	my $c		= shift;

}

sub login : Local
{
	my $self	= shift;
	my $c		= shift;
	my $method	= $c->req->method;

	$c->detach("login_$method");
}

sub login_GET : Private
{
	my $self	= shift;
	my $c		= shift;

	$c->stash->{template} = 'login.tt';
}

sub login_POST : Private
{
	my $self	= shift;
	my $c		= shift;

	my $credentials = {};

	$credentials->{username} = scalar $c->req->params->{username};
	$credentials->{password} = scalar $c->req->params->{password};

	$c->detach('/default') if $c->authenticate($credentials);

	$c->stash->{error} = 'login incorrect';

	$c->detach('/login_GET');
}

sub status : Local
{
	my $self	= shift;
	my $c		= shift;

	$c->stash->{hopkins}	= $c->config->{hopkins};
	$c->stash->{template}	= 'status.tt';
}

sub end : ActionClass('RenderView') { }

=back

=head1 AUTHOR

Mike Eldridge <diz@cpan.org>

=head1 LICENSE

This program is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=cut

1;
