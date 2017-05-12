# Copyright 2013, Google Inc. All Rights Reserved.
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

package Google::Ads::Common::OAuth2ApplicationsHandler;

use strict;
use version;
use base qw(Google::Ads::Common::OAuth2BaseHandler
  Google::Ads::Common::OAuthApplicationsHandlerInterface);

# The following needs to be on one line because CPAN uses a particularly hacky
# eval() to determine module versions.
use Google::Ads::Common::Constants; our $VERSION = ${Google::Ads::Common::Constants::VERSION};

use Class::Std::Fast;
use HTTP::Request::Common;
use LWP::UserAgent;
use URI::Escape;

use constant OAUTH2_BASE_URL => "https://accounts.google.com/o/oauth2";
use constant OAUTH2_TOKEN_INFO_URL =>
  "https://www.googleapis.com/oauth2/v1/tokeninfo";

# Class::Std-style attributes. Need to be kept in the same line.
# These need to go in the same line for older Perl interpreters to understand.
my %client_secret_of : ATTR(:name<client_secret> :default<>);
my %access_type_of : ATTR(:name<access_type> :default<offline>);
my %prompt_of : ATTR(:name<prompt> :default<consent>);
my %refresh_token_of : ATTR(:name<refresh_token> :default<>);
my %redirect_uri_of :
  ATTR(:name<redirect_uri> :default<urn:ietf:wg:oauth:2.0:oob>);
my %additional_scopes_of : ATTR(:name<additional_scopes> :default<>);

# Methods from Google::Ads::Common::AuthHandlerInterface
sub initialize : CUMULATIVE(BASE FIRST) {
  my ($self, $api_client, $properties) = @_;
  my $ident = ident $self;

  $client_secret_of{$ident} = $properties->{oAuth2ClientSecret}
    || $client_secret_of{$ident};
  $access_type_of{$ident} = $properties->{oAuth2AccessType}
    || $access_type_of{$ident};
  $prompt_of{$ident} = $properties->{oAuth2ApprovalPrompt}
    || $prompt_of{$ident};
  $refresh_token_of{$ident} = $properties->{oAuth2RefreshToken}
    || $refresh_token_of{$ident};
  $redirect_uri_of{$ident} = $properties->{oAuth2RedirectUri}
    || $redirect_uri_of{$ident};
  $additional_scopes_of{$ident} = $properties->{oAuth2AdditionalScopes}
    || $additional_scopes_of{$ident};
}

# Methods from Google::Ads::Common::OAuthHandlerInterface
sub get_authorization_url {
  my ($self, $state) = @_;

  $state ||= "";
  my ($client_id, $redirect_uri, $access_type, $prompt) = (
    $self->get_client_id(),   $self->get_redirect_uri(),
    $self->get_access_type(), $self->get_prompt());

  return OAUTH2_BASE_URL . "/auth?response_type=code" . "&client_id=" .
    uri_escape($client_id) . "&redirect_uri=" . $redirect_uri . "&scope=" .
    $self->_formatted_scopes() . "&access_type=" . $access_type .
    "&prompt=" . $prompt . "&state=" . uri_escape($state);
}

sub issue_access_token {
  my ($self, $authorization_code) = @_;

  my $body =
    "code=" . uri_escape($authorization_code) . "&client_id=" .
    uri_escape($self->get_client_id()) . "&client_secret=" .
    uri_escape($self->get_client_secret()) . "&redirect_uri=" .
    uri_escape($self->get_redirect_uri()) . "&grant_type=authorization_code";

  push my @headers, "Content-Type" => "application/x-www-form-urlencoded";
  my $request =
    HTTP::Request->new("POST", OAUTH2_BASE_URL . "/token", \@headers, $body);
  my $res = $self->get___user_agent()->request($request);

  if (!$res->is_success()) {
    return $res->decoded_content();
  }

  my $content_hash = $self->__parse_auth_response($res->decoded_content());

  $self->set_access_token($content_hash->{access_token});
  $self->set_refresh_token($content_hash->{refresh_token});
  $self->set_access_token_expires(time + $content_hash->{expires_in});

  return undef;
}

# Internal methods

sub _refresh_access_token {
  my $self = shift;

  if (
    !(
         $self->get_client_id()
      && $self->get_client_secret()
      && $self->get_refresh_token()))
  {
    return 0;
  }

  my $body =
    "refresh_token=" . uri_escape($self->get_refresh_token()) .
    "&client_id=" . uri_escape($self->get_client_id()) . "&client_secret=" .
    uri_escape($self->get_client_secret()) . "&grant_type=refresh_token";

  push my @headers, "Content-Type" => "application/x-www-form-urlencoded";
  my $request =
    HTTP::Request->new("POST", OAUTH2_BASE_URL . "/token", \@headers, $body);
  my $res = $self->get___user_agent()->request($request);

  if (!$res->is_success()) {
    warn($res->decoded_content());
    return 0;
  }

  my $content_hash = $self->__parse_auth_response($res->decoded_content());

  $self->set_access_token($content_hash->{access_token});
  $self->set_access_token_expires(time + $content_hash->{expires_in});

  return 1;
}

sub _formatted_scopes {
  my $self = shift;
  die "Need to be implemented by subclass";
}

1;

=pod

=head1 NAME

Google::Ads::Common::OAuth2ApplicationsHandler

=head1 DESCRIPTION

A generic abstract implementation of L<Google::Ads::Common::OAuth2BaseHandler>
that supports OAuth2 for Web/Install Applications semantics.

It is meant to be specialized and its L<_scope> and L<_formatted_scopes> methods
be properly implemented.

=head1 ATTRIBUTES

Each of these attributes can be set via
Google::Ads::Common::OAuth2ApplicationsHandler->new().

Alternatively, there is a get_ and set_ method associated with each attribute
for retrieving or setting them dynamically.

=head2 api_client

A reference to the API client used to send requests.

=head2 client_id

OAuth2 client id obtained from the Google APIs Console.

=head2 client_secret

OAuth2 client secret obtained from the Google APIs Console.

=head2 access_type

OAuth2 access type to be requested when following the authorization flow. It
defaults to offline but it can be set to online.

=head2 prompt

OAuth2 prompt to be used when following the authorization flow. It
defaults to consent.

=head2 redirect_uri

Redirect URI as set for you in the Google APIs console, to which the
authorization flow will callback with the verification code. Defaults to
urn:ietf:wg:oauth:2.0:oob for the installed applications flow.

=head2 access_token

Stores an OAuth2 access token after the authorization flow is followed or for
you to manually set it in case you had it previously stored.
If this is manually set this handler will verify its validity before preparing
a request.

=head2 refresh_token

Stores an OAuth2 refresh token in case of an offline L<access_type> is
requested. It is automatically used by the handler to request new access tokens
i.e. when they expire or found invalid.

=head2 additional_scopes

Stores additional OAuth2 scopes as a comma-separated string.
The scope defines which services the tokens
are allowed to access e.g. https://www.googleapis.com/auth/analytics

=head1 METHODS

=head2 initialize

Initializes the handler with properties such as the client_id and
client_secret to use for generating authorization requests.

=head3 Parameters

=over

=item *

A required I<api_client> with a reference to the API client object handling the
requests against the API.

=item *

A hash reference with the following keys:
{
  # Refer to the documentation of the L<client_secret> property.
  oAuth2ClientId => "client-id",
  # Refer to the documentation of the L<client_secret> property.
  oAuth2ClientSecret => "client-secret",
  # Refer to the documentation of the L<access_type> property.
  oAuth2AccessType => "access-type",
  # Refer to the documentation of the L<prompt> property.
  oAuth2ApprovalPrompt => "approval-prompt",
  # Refer to the documentation of the L<refresh_token> property.
  oAuth2AccessToken => "access-token",
  # Refer to the documentation of the L<refresh_token> property.
  oAuth2RefreshToken => "refresh-token",
  # Refer to the documentation of the L<redirect_uri> property.
  oAuth2RedirectUri => "secret",
}

=head2 is_auth_enabled

Refer to L<Google::Ads::Common::AuthHandlerInterface> documentation of this
method.

=head2 prepare_request

Refer to L<Google::Ads::Common::AuthHandlerInterface> documentation of this
method.

=head2 get_authorization_url

Refer to L<Google::Ads::Common::OAuthApplicationsHandlerInterface> documentation
of this method.

=head2 issue_access_token

Refer to L<Google::Ads::Common::OAuthApplicationsHandlerInterface> documentation
of this method.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Google Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=head1 REPOSITORY INFORMATION

 $Rev: $
 $LastChangedBy: $
 $Id: $

=cut
