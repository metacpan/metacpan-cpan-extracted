# Copyright 2012, Google Inc. All Rights Reserved.
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

package Google::Ads::Common::AuthTokenHandler;

use strict;
use version;
use base qw(Google::Ads::Common::AuthHandlerInterface);

# The following needs to be on one line because CPAN uses a particularly hacky
# eval() to determine module versions.
use Google::Ads::Common::Constants; our $VERSION = ${Google::Ads::Common::Constants::VERSION};

use Google::Ads::Common::AuthError;
use Google::Ads::Common::CaptchaRequiredError;

use Class::Std::Fast;
use HTTP::Request;
use LWP::UserAgent;
use URI::Escape;

# These constants should be fairly, well, constant. But if anything does change
# with the ClientLogin mechanism, this should be updated.
use constant ACCOUNT_TYPE => "GOOGLE";
use constant DEFAULT_SERVER => "https://www.google.com";
use constant AUTH_URL => "%s/accounts/ClientLogin";
use constant CAPTCHA_URL_PATH => "/accounts/";
use constant AUTH_TOKEN_LIFETIME => 23;

# Class::Std-style attributes. Need to be kept in the same line.
my %api_client_of : ATTR(:name<api_client> :default<>);
my %email_of : ATTR(:init_arg<email> :get<email> :default<>);
my %password_of : ATTR(:init_arg<password> :get<password> :default<>);
my %auth_server_of : ATTR(:name<auth_server> :default<>);
my %auth_token_of : ATTR(:init_arg<auth_token> :get<auth_token> :default<>);
my %issued_in_of : ATTR(:name<issued_in> :default<>);
my %__user_agent_of : ATTR(:name<__user_agent> :default<>);

sub START {
  my ($self, $ident) = @_;

  $__user_agent_of{$ident} ||= LWP::UserAgent->new();
  $auth_server_of{$ident} = DEFAULT_SERVER;
}

# Methods from Google::Ads::Common::AuthHandlerInterface
sub initialize {
  my ($self, $api_client, $properties) = @_;
  my $ident = ident $self;

  $api_client_of{$ident} = $api_client;
  $email_of{$ident} = $properties->{email} || $email_of{$ident};
  $password_of{$ident} = $properties->{password} || $password_of{$ident};
  $auth_token_of{$ident} = $properties->{authToken} || $auth_token_of{$ident};
  $auth_server_of{$ident} = $properties->{authServer} ||
      $auth_server_of{$ident};
}

sub is_auth_enabled {
  my ($self) = @_;

  return $self->__get_auth_token();
}

# Class own methods.

# Forces a refresh of the auth token.
sub refresh_auth_token {
  my ($self) = @_;

  return $self->issue_new_token();
}

# Custom setters with logic to invalidate other dependent fields.
sub set_email {
  my ($self, $email) = @_;

  $email_of{ident $self} = $email;
  $auth_token_of{ident $self} = undef;
  $issued_in_of{ident $self} = undef;
}

sub set_password {
  my ($self, $password) = @_;

  $password_of{ident $self} = $password;
  $auth_token_of{ident $self} = undef;
  $issued_in_of{ident $self} = undef;
}

sub set_auth_token {
  my ($self, $token) = @_;

  $auth_token_of{ident $self} = $token;
  $issued_in_of{ident $self} = undef;
}

# Uses the ClientLogin web service to request a new auth token.
sub issue_new_token {
  my ($self, $captcha_token, $captcha_code) = @_;

  warnings::warnif("deprecated",
      Google::Ads::Common::Constants::CLIENT_LOGIN_DEPRECATION_MESSAGE);

  my $error;
  my $service = uri_escape($self->_service())
    or $error = Google::Ads::Common::AuthError->new({
      code => "",
      content => "",
      message => "Required 'service' not available, handler " .
                 "not properly initiliazed?."
    });
  my $email = uri_escape($self->get_email())
    or $error = Google::Ads::Common::AuthError->new({
      code => "",
      content => "",
      message => "Required 'email' not available, handler " .
                 "not properly initiliazed?."
    });
  my $password = uri_escape($self->get_password())
    or $error = Google::Ads::Common::AuthError->new({
      code => "",
      content => "",
      message => "Required 'password' not available, handler " .
                 "not properly initiliazed?."
    });

  if (!$error) {
    my $server = $self->get_auth_server();
    my $user_agent = $self->get___user_agent();

    # The ClientLogin interface is documented at
    # https://developers.google.com/accounts/docs/AuthForInstalledApps
    my $data = sprintf("accountType=%s&Email=%s&Passwd=%s&service=%s",
                       ACCOUNT_TYPE, $email, $password, $service);

    if ($captcha_token && $captcha_code) {
     $data .= sprintf("&logintoken=%s&logincaptcha=%s", $captcha_token,
                      $captcha_code);
    }

    # my $userAgent = LWP::UserAgent->new();
    $user_agent->env_proxy();
    $user_agent->agent(sprintf("%s: %s", __PACKAGE__, $0));

    my $request = HTTP::Request->new(POST => sprintf(AUTH_URL, $server));
    $request->content_type("application/x-www-form-urlencoded");
    $request->content($data);

    my $response = $user_agent->request($request);
    my $content = $response->content();

    if ($response->is_success()) {

      # Sample response body:
      #   SID=DQAAAGgA...7Zg8CTN
      #   LSID=DQAAAGsA...lk8BBbG
      #   Auth=DQAAAGgA...dk3fA5N
      # We only care about the Auth token.
      if ($content =~ /Auth=(.+)$/) {
        $self->set_auth_token($1);
        $self->set_issued_in(time);
        return;
      } else {
        $error = "Invalid successful response: ${content} from auth server";
      }
    }

    my %content_hash = __content_to_hash($content);

    if (exists $content_hash{Error} &&
        $content_hash{Error} eq "CaptchaRequired") {
      my $captcha_image = $server . CAPTCHA_URL_PATH . $content_hash{CaptchaUrl};

      $error = Google::Ads::Common::CaptchaRequiredError->new({
        token => $content_hash{CaptchaToken},
        image => $captcha_image,
        url => $content_hash{Url},
        message => $response->message(),
        code => $response->code(),
        content => $response->content()
      });
    } else {
      $error = Google::Ads::Common::AuthError->new({
        message => $response->message(),
        code => $response->code(),
        content => $response->content()
      });
    }
  }

  return $error;
}

# Internal methods

# Returns or refresh an auth token, based in its lifetime.
sub __get_auth_token {
  my ($self) = @_;

  if ($self->get_auth_token()) {
    if ($self->get_issued_in() &&
        ($self->get_issued_in() + (1000 * 60 * 60 * AUTH_TOKEN_LIFETIME)) <
         time && $self->get_email()) {
      $self->issue_new_token();
    }
  } elsif ($self->get_email()) {
    my $error = $self->issue_new_token();
    if (defined($error)) {
      if ($self->get_api_client()->get_die_on_faults()) {
        die "An error as occurred trying to retrieve the authorization token. " .
            "Error: " . $error;
      }
      warn "An error as occurred trying to retrieve the authorization token. " .
          "Error: " . $error;
    }
  }

  return $self->get_auth_token();
}

sub __content_to_hash {
  my $content = shift;
  return map {$_ =~ /^(.+?)=(.+)$/; if (defined $1) { $1 => $2 } else
              { 0 => 0 }} split(/\n/, $content);
}

# Returns the ClientLogin service name to use when requesting an new Auth Token.
# This is specific to ClientLogin and the product.
sub _service {
  my ($self) = @_;
  die "Needs to be implemented by subclass";
}

return 1;

=pod

=head1 NAME

Google::Ads::Common::AuthTokenHandler

=head1 DESCRIPTION

Google::Ads::Common::AuthTokenHandler implements most of the methods required
to request AuthTokens using the ClientLogin protocol, see
L<https://developers.google.com/accounts/docs/AuthForInstalledApps> for more
information about the protocol.

=head1 ATTRIBUTES

Each of these attributes can be set via the constructor as a hash.
Alternatively, there is a get_ and set_ method associated with each attribute
for retrieving or setting them dynamically.

=head2 email

The email of the account to authorization against.

=head2 password

The password to use for authorization.

=head2 auth_server

Endpoint of the authorization server.

=head2 auth_token

Auth token either manually set or generated.

=head2 issued_in

L<time> in which the token was issued if it was requested by this class.

=head1 METHODS

=head2 initialize

Initializes the handler with properties such as the email and password to use
for generating AuthTokens.

=head3 Parameters

=over

=item *

A required I<api_client> with a reference to the API client object handling the
requests against the API.

=item *

A hash reference with the following keys:
{
  # The service name to access.
  service => "adwords",
  # The email address of a Google Account.
  email => "user@domain.com",
  # The password for the Google Account.
  password => "password",
}

=head2 is_auth_enabled

=head3 Returns

True, if a valid AuthToken is available or can be generated to use within API
requests.

=head2 refresh_auth_token

Forces refreshing the auth token using the credentials set in the handler.

=head2 issue_new_token

Calls the authorization server to generate a new AuthToken. Sets the generated
AuthToken in the L<auth_token> property as well as the L<issued_in> property.
A captcha token and code can be passed to this method to handle captcha challenges

=head3 Parameters

=over

=item *

An optional captcha token, obtained from a captcha challenge error. See
L<Google::Ads::Common::CaptchaRequiredError>.

=item *

An optional captcha code, obtained from the user by looking at the captcha
image.

=back

=head3 Returns

Returns an error of type L<Google::Ads::Common::CaptchaRequiredError> or
L<Google::Ads::Common::AuthError> if an error occurred while generating the
token.

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Google Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=head1 AUTHOR

David Torres E<lt>david.t at google.comE<gt>

=head1 REPOSITORY INFORMATION

 $Rev: $
 $LastChangedBy: $
 $Id: $

=cut
