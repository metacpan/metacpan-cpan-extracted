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

package Google::Auth::WebUserAuthorizer;

use Moo;
extends 'Google::Auth::UserAuthorizer';

use JSON::MaybeXS;
use Google::Auth::Exceptions;
use URI;

my $coder = JSON::MaybeXS->new->ascii->pretty->allow_nonref;

use constant {
  STATE_PARAM        => 'state',
  AUTH_CODE_KEY      => 'code',
  ERROR_CODE_KEY     => 'error',
  SESSION_ID_KEY     => 'session_id',
  CALLBACK_STATE_KEY => 'g-auth-callback',
  CURRENT_URI_KEY    => 'current_uri',
  XSRF_KEY           => 'g-xsrf-token',
  SCOPE_KEY          => 'scope',
};

# Generic request handling: assumes $request is a hash reference with
# 'session', 'url', and 'parameters' keys, or objects supporting those methods.

sub _get_session {
  my ($request) = @_;
  if (ref($request) eq 'HASH') {
    return $request->{session};
  } elsif ($request->can('session')) {
    return $request->session;
  }
  return;
}

sub _get_url {
  my ($request) = @_;
  if (ref($request) eq 'HASH') {
    return $request->{url};
  } elsif ($request->can('url')) {
    return $request->url;
  }
  return;
}

sub _get_param {
  my ($request, $key) = @_;
  if (ref($request) eq 'HASH') {
    return $request->{parameters}->{$key} // $request->{$key};
  } elsif ($request->can('param')) {
    return $request->param($key);
  } elsif ($request->can('parameters')) {
    return $request->parameters->{$key};
  }
  return;
}

sub handle_auth_callback_deferred {
  my ($class, $request) = @_;
  my ($callback_state, $redirect_uri) =
    $class->extract_callback_state($request);

  my $session = _get_session($request);
  Google::Auth::Error->throw('Sessions must be enabled') unless $session;

  $session->{+CALLBACK_STATE_KEY} = $coder->encode($callback_state);
  return $redirect_uri;
}

sub handle_auth_callback {
  my ($self, $user_id, $request) = @_;

  my ($callback_state, $redirect_uri) = $self->extract_callback_state($request);
  $self->validate_callback_state($callback_state, $request);

  my $creds = $self->get_and_store_credentials_from_code(
    user_id  => $user_id,
    code     => $callback_state->{+AUTH_CODE_KEY},
    scope    => $callback_state->{+SCOPE_KEY},
    base_url => _get_url($request),
  );

  return ($creds, $redirect_uri);
}

sub get_authorization_url {
  my ($self, %options) = @_;

  my $request = $options{request};
  Google::Auth::Error->throw('Request is required') unless $request;

  my $session = _get_session($request);
  Google::Auth::Error->throw('Sessions must be enabled') unless $session;

  my $state       = $options{state}       // {};
  my $redirect_to = $options{redirect_to} // _get_url($request);

  # Generate XSRF token
  require Google::Auth;
  my $random_bytes = Google::Auth::get_secure_random_bytes(32);
  my $xsrf_token   = unpack('H*', $random_bytes);
  $session->{+XSRF_KEY} = $xsrf_token;

  my $state_data = {
    %$state,
    SESSION_ID_KEY()  => $xsrf_token,
    CURRENT_URI_KEY() => $redirect_to,
  };

  $options{state}    = $coder->encode($state_data);
  $options{base_url} = _get_url($request);

  return $self->SUPER::get_authorization_url(%options);
}

sub get_credentials {
  my ($self, $user_id, $request, $scope) = @_;

  my $session = $request ? _get_session($request) : undef;

  if ($session && exists $session->{+CALLBACK_STATE_KEY}) {
    my $state_json     = delete $session->{+CALLBACK_STATE_KEY};
    my $callback_state = $coder->decode($state_json);

    $self->validate_callback_state($callback_state, $request);

    return $self->get_and_store_credentials_from_code(
      user_id  => $user_id,
      code     => $callback_state->{+AUTH_CODE_KEY},
      scope    => $callback_state->{+SCOPE_KEY},
      base_url => _get_url($request),
    );
  }

  return $self->SUPER::get_credentials($user_id, $scope);
}

sub extract_callback_state {
  my ($class, $request) = @_;

  my $state_json = _get_param($request, STATE_PARAM) // '{}';
  my $state      = $coder->decode($state_json);

  my $redirect_uri = $state->{+CURRENT_URI_KEY};

  my $callback_state = {
    AUTH_CODE_KEY()  => _get_param($request, AUTH_CODE_KEY),
    ERROR_CODE_KEY() => _get_param($request, ERROR_CODE_KEY),
    SESSION_ID_KEY() => $state->{+SESSION_ID_KEY},
    SCOPE_KEY()      => _get_param($request, SCOPE_KEY),
  };

  return ($callback_state, $redirect_uri);
}

sub validate_callback_state {
  my ($self, $state, $request) = @_;

  Google::Auth::Error->throw('Missing authorization code in request')
    unless defined $state->{+AUTH_CODE_KEY};

  if ($state->{+ERROR_CODE_KEY}) {
    Google::Auth::Error->throw(
      'Authorization error: ' . $state->{+ERROR_CODE_KEY});
  }

  my $session = _get_session($request);
  Google::Auth::Error->throw('Sessions must be enabled') unless $session;

  my $stored_xsrf   = $session->{+XSRF_KEY};
  my $received_xsrf = $state->{+SESSION_ID_KEY};

  if ( !defined $stored_xsrf
    || !defined $received_xsrf
    || $stored_xsrf ne $received_xsrf)
  {
    Google::Auth::Error->throw('State token does not match expected value');
  }
}

package Google::Auth::WebUserAuthorizer::CallbackApp;

# To be implemented if we want a turnkey Plack app similar to Ruby's rack app.
# For now, WebUserAuthorizer provides the helpers to build one easily.

1;
