package GunMojo::OAuth2;

use warnings;
use strict;
use Mojo::Base qw/Mojolicious::Controller Mojolicious::Session/;
use URI::Escape qw/uri_escape/;
use Time::Local qw/timelocal/;

my ( $self, $class ) = @_;
bless $self, $class;

our $VERSION = 0.01;

# Much of this code is adapted from this Gist on Github: https://gist.github.com/3726907

sub login {
	my $self = shift;

	$self->redirect_to( join "",
		$self->config->{google_oauth}->{oauth_base}, "/auth",
		"?client_id=", $self->config->{google_oauth}->{client_id}, "&response_type=code",
        	"&scope=", $self->config->{google_oauth}->{scope},
		"&redirect_uri=", uri_escape( $self->config->{google_oauth}->{cb} )
	);

	return 1;
}

sub callback {
	my $self = shift;

	my $ts = timelocal(localtime());
	open my $fh, '>', '/tmp/cb-debug'. $ts;
	use Data::Dumper;

	# Debug original parameters from GET request
	print $fh "Params from CB:\n";
	print $fh Dumper $self->param;
	print $fh "Code? --> ", $self->param('code') ? $self->param('code') : 'None', "\n\n";

	# Get tokens from auth code
	my $res = $self->app->ua->post_form(
		"$self->config->{google_oauth}->{oauth_base}/token",
		{
			code		=> $self->param('code'),
			redirect_uri	=> $self->config->{google_oauth}->{cb},
			client_id	=> $self->config->{google_oauth}->{client_id},
			client_secret	=> $self->config->{google_oauth}->{client_secret},
			scope		=> $self->config->{google_oauth}->{scope},
			grant_type	=> 'authorization_code',
		}
	)->res;

	# Debug ua response
	print $fh "POST ", $self->config->{google_oauth}->{oauth_base}, "/token\n";
	print $fh "code: ", $self->param('code'), "\n";
	print $fh "redirect_uri: ", $self->config->{google_oauth}->{cb}, "\n";
	print $fh "client_id: ", $self->config->{google_oauth}->{client_id}, "\n";
	print $fh "client_secret: ", $self->config->{google_oauth}->{client_secret}, "\n";
	print $fh "scope: ", $self->config->{google_oauth}->{scope}, "\n";
	print $fh "grant_type: authorization_code", "\n\n";

	print $fh Dumper $res;
	close $fh;

	if ( $res->is_status_class(200) ) {
		# Save access token to session and re-direct to admin page
		$self->session->{access_token} = $res->json->{access_token};
		$self->redirect_to('/admin');
	}
	else {
		# Authentication or OAuth2 failure, explain cause
		$self->redirect_to('/oauth2/fail');
	}
	return 1;
}

1;

