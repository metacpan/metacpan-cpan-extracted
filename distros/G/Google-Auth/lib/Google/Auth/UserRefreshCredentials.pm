package Google::Auth::UserRefreshCredentials;

use strict;
use warnings;

use Moo;
extends 'Google::Auth::Credentials';

use JSON::PP;
use LWP::UserAgent;
use Google::Auth;
use Google::Auth::Exceptions;
use Google::Auth::RetryHelper;
use Log::Any qw($log);

has json_key => (
  is       => 'ro',
  required => 0,
);

has client_id => (
  is       => 'ro',
  required => 0,
);

has client_secret => (
  is       => 'ro',
  required => 0,
);

has refresh_token => (
  is       => 'rw',
  required => 0,
);

has code => (
  is       => 'rw',
  required => 0,
);

has redirect_uri => (
  is       => 'ro',
  required => 0,
);

has token_uri => (
  is       => 'ro',
  required => 0,
  default  => sub {
    $ENV{GOOGLE_AUTH_TOKEN_URI} || 'https://oauth2.googleapis.com/token';
  },
);

has code_verifier => (
  is       => 'ro',
  required => 0,
);

has scope => (
  is       => 'ro',
  required => 0,
);

has ua => (
  is      => 'ro',
  default => sub {
    my $ua = LWP::UserAgent->new(timeout => 10);
    $ua->env_proxy;
    return $ua;
  },
);

around BUILDARGS => sub {
  my ($orig, $class, @args) = @_;
  my $args = $class->$orig(@args);

  if (my $json = $args->{json_key}) {
    $args->{client_id}     //= $json->{client_id};
    $args->{client_secret} //= $json->{client_secret};
    $args->{refresh_token} //= $json->{refresh_token};
    $args->{token_uri}     //= $json->{token_uri} if defined $json->{token_uri};
  }

  return $args;
};

sub fetch_access_token {
  my ($self, %options) = @_;

  my $client_id     = $self->client_id;
  my $client_secret = $self->client_secret;
  my $refresh_token = $self->refresh_token;
  my $token_uri     = $self->token_uri;

  $self->_validate_url($token_uri, 'token_uri');

  if (!defined $client_id || !defined $client_secret) {
    $log->errorf(
'Missing client_id or client_secret for UserRefreshCredentials token exchange'
    );
    Google::Auth::Error->throw(
      'Missing client_id or client_secret to fetch token');
  }

  my $post_body;
  if ($self->code) {
    if (!defined $self->redirect_uri) {
      Google::Auth::Error->throw(
        'Missing redirect_uri for authorization_code grant');
    }
    $post_body = {
      'grant_type'    => 'authorization_code',
      'client_id'     => $client_id,
      'client_secret' => $client_secret,
      'code'          => $self->code,
      'redirect_uri'  => $self->redirect_uri,
    };
    $post_body->{code_verifier} = $self->code_verifier
      if $self->code_verifier;
  } elsif ($refresh_token) {
    $post_body = {
      'grant_type'    => 'refresh_token',
      'client_id'     => $client_id,
      'client_secret' => $client_secret,
      'refresh_token' => $refresh_token,
    };
  } else {
    Google::Auth::Error->throw('Missing refresh_token or code to fetch token');
  }

  my $ua = $self->ua;

  my $response = Google::Auth::RetryHelper->execute_with_retry(
    sub {
      my $res = $ua->post($token_uri, $post_body);
      if (!$res->is_success) {
        $log->warnf('Token request failed at %s: status %s',
          $token_uri, $res->code);
        Google::Auth::Error->throw('HTTP request failed with status ' .
            $res->code . ': ' . $res->decoded_content);
      }
      return $res;
    },
    %options
  );

  my $res_data = decode_json($response->decoded_content);
  my $token    = $res_data->{access_token};
  my $expires  = $res_data->{expires_in} // 3600;

  $self->access_token($token);
  $self->expires_at(time() + $expires);

  if ($res_data->{refresh_token}) {
    $self->refresh_token($res_data->{refresh_token});
  }

  return $token;
}

1;
