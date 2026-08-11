# Copyright 2022 Google LLC and contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package Google::Auth::UserAuthorizer;

use strict;
use warnings;

use Moo;

use Google::Auth::Exceptions;
use URI;
use JSON::MaybeXS;
use Digest::SHA  qw(sha256);
use MIME::Base64 qw(encode_base64url);

has client_id => (
  is       => 'ro',
  required => 1,
);

has scope => (
  is       => 'ro',
  required => 1,
);

has token_store => (
  is       => 'ro',
  required => 1,
);

has callback_uri => (
  is      => 'ro',
  default => sub { '/oauth2callback' },
);

has code_verifier => (
  is       => 'rw',
  required => 0,
);

has auth_endpoint => (
  is      => 'ro',
  default => sub {
    $ENV{GOOGLE_AUTH_AUTH_ENDPOINT}
      // 'https://accounts.google.com/o/oauth2/auth';
  },
);

has token_uri => (
  is      => 'ro',
  default => sub {
    $ENV{GOOGLE_AUTH_TOKEN_URI} // 'https://oauth2.googleapis.com/token';
  },
);

around BUILDARGS => sub {
  my ($orig, $class, @args) = @_;

  # Standardize arguments to a hashref
  my $args;
  if (@args == 1 && ref $args[0] eq 'HASH') {
    $args = {%{$args[0]}};
  } else {
    $args = {@args};
  }

  if ($args->{scope} && !ref($args->{scope})) {
    $args->{scope} = [split(/\s+/, $args->{scope})];
  }
  return $class->$orig($args);
};

sub get_authorization_url {
  my ($self, %options) = @_;

  my $scope = $options{scope} // $self->scope;
  $scope = join(' ', @$scope) if ref($scope) eq 'ARRAY';

  my $redirect_uri = $self->_redirect_uri_for($options{base_url});

  my $uri    = URI->new($self->auth_endpoint);
  my %params = (
    client_id     => $self->client_id->id,
    redirect_uri  => $redirect_uri,
    response_type => 'code',
    scope         => $scope,
    access_type   => 'offline',
    prompt        => 'consent',
  );

  $params{state}      = $options{state}      if defined $options{state};
  $params{login_hint} = $options{login_hint} if defined $options{login_hint};

  if ($self->code_verifier) {
    $params{code_challenge} =
      $self->_generate_code_challenge($self->code_verifier);
    $params{code_challenge_method} = 'S256';
  }

  if ($options{additional_parameters}) {
    %params = (%params, %{$options{additional_parameters}});
  }

  $uri->query_form(%params);
  return $uri->as_string;
}

sub get_credentials {
  my ($self, $user_id, $scope) = @_;

  my $saved_token = $self->token_store->load($user_id);
  return unless $saved_token;

  my $data = decode_json($saved_token);

  if ($data->{client_id} ne $self->client_id->id) {
    Google::Auth::Error->throw('Mismatched client ID');
  }

  require Google::Auth::UserRefreshCredentials;
  my $creds = Google::Auth::UserRefreshCredentials->new(
    client_id     => $self->client_id->id,
    client_secret => $self->client_id->secret,
    scope         => $data->{scope} // $self->scope,
    access_token  => $data->{access_token},
    refresh_token => $data->{refresh_token},
    expires_at    => $data->{expiration_time_millis}
    ? $data->{expiration_time_millis} / 1000
    : undef,
  );

  # TODO: monitor credentials for refresh to update store?
  # In Ruby: return monitor_credentials user_id, credentials if credentials.includes_scope? scope

  return $creds;
}

sub get_credentials_from_code {
  my ($self, %options) = @_;

  my $user_id  = $options{user_id};
  my $code     = $options{code};
  my $scope    = $options{scope} // $self->scope;
  my $base_url = $options{base_url};

  my $redirect_uri = $self->_redirect_uri_for($base_url);

  require Google::Auth::UserRefreshCredentials;
  my $creds = Google::Auth::UserRefreshCredentials->new(
    client_id     => $self->client_id->id,
    client_secret => $self->client_id->secret,
    scope         => $scope,
    code          => $code,
    redirect_uri  => $redirect_uri,
    code_verifier => $self->code_verifier,
    token_uri     => $self->token_uri,
  );

  $creds->get_token();    # This will trigger fetch_access_token with code

  # Clear code and redirect_uri as they are not needed for refresh
  # But we can't clear them if they are ro/rw without accessors.
  # They are rw/ro respectively.

  return $creds;
}

sub get_and_store_credentials_from_code {
  my ($self, %options) = @_;
  my $creds = $self->get_credentials_from_code(%options);
  $self->store_credentials($options{user_id}, $creds);
  return $creds;
}

sub store_credentials {
  my ($self, $user_id, $credentials) = @_;

  my $data = {
    client_id              => $credentials->client_id,
    access_token           => $credentials->access_token,
    refresh_token          => $credentials->refresh_token,
    scope                  => $credentials->scope,
    expiration_time_millis => $credentials->expires_at
    ? $credentials->expires_at * 1000
    : undef,
  };
  $data->{client_secret} = $credentials->client_secret
    if $credentials->can('client_secret');

  $self->token_store->store($user_id, encode_json($data));
  return $credentials;
}

sub _redirect_uri_for {
  my ($self, $base_url) = @_;

  return $self->callback_uri if $self->callback_uri =~ /^https?:\/\//;
  return $self->callback_uri
    if $self->callback_uri eq 'urn:ietf:wg:oauth:2.0:oob';
  return $self->callback_uri if $self->callback_uri eq 'postmessage';

  if (!$base_url) {
    Google::Auth::Error->throw(
      'Absolute base url required for relative callback url');
  }

  my $uri = URI->new($base_url);

  # Resolve relative path
  $uri->path($self->callback_uri)
    ;    # This might overwrite path completely if callback_uri starts with /
  return $uri->as_string;
}

sub _generate_code_challenge {
  my ($self, $verifier) = @_;
  my $hash = sha256($verifier);
  return encode_base64url($hash);
}

1;

