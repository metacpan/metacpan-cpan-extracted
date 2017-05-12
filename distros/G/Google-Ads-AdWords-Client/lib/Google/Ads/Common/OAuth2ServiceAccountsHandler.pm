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

package Google::Ads::Common::OAuth2ServiceAccountsHandler;

use strict;
use version;
use base qw(Google::Ads::Common::OAuth2BaseHandler);

# The following needs to be on one line because CPAN uses a particularly hacky
# eval() to determine module versions.
use Google::Ads::Common::Constants; our $VERSION = ${Google::Ads::Common::Constants::VERSION};

use Crypt::OpenSSL::RSA;
use HTTP::Request;
use JSON::Parse qw(parse_json);
use LWP::UserAgent;
use MIME::Base64 qw(encode_base64 decode_base64);
use utf8;

use constant OAUTH2_BASE_URL => "https://accounts.google.com/o/oauth2";

# Class::Std-style attributes. Need to be kept in the same line.
# These need to go in the same line for older Perl interpreters to understand.
my %email_address_of : ATTR(:name<email_address> :default<>);
my %delegated_email_address_of :
  ATTR(:name<delegated_email_address> :default<>);
my %additional_scopes_of : ATTR(:name<additional_scopes> :default<>);
my %pem_file_of : ATTR(:name<pem_file> :default<>);
my %json_file_of : ATTR(:name<json_file> :default<>);
my %__crypt_module_of : ATTR(:name<__crypt_module> :default<>);

# Constructor
sub START {
  my ($self, $ident) = @_;

  $__crypt_module_of{$ident} ||= "Crypt::OpenSSL::RSA";
}

sub initialize : CUMULATIVE(BASE FIRST) {
  my ($self, $api_client, $properties) = @_;
  my $ident = ident $self;

  $email_address_of{$ident} = $properties->{oAuth2ServiceAccountEmailAddress}
    || $email_address_of{$ident};
  $delegated_email_address_of{$ident} =
       $properties->{oAuth2ServiceAccountDelegateEmailAddress}
    || $delegated_email_address_of{$ident};
  $pem_file_of{$ident} = $properties->{oAuth2ServiceAccountPEMFile}
    || $pem_file_of{$ident};
  $json_file_of{$ident} = $properties->{oAuth2ServiceAccountJSONFile}
    || $json_file_of{$ident};
  $additional_scopes_of{$ident} = $properties->{oAuth2AdditionalScopes}
    || $additional_scopes_of{$ident};
}

sub _refresh_access_token {
  my $self = shift;

  if ($self->get_json_file() and $self->get_pem_file()) {
    warn("Only one of oAuth2ServiceAccountPEMFile or " .
    "oAuth2ServiceAccountJSONFile can be specified in adwords.properties.");
    return 0;
  }

  my $file = $self->__read_certificate_file() || return 0;

  my $iat                     = time;
  my $exp                     = $iat + 3600;
  my $iss                     = $self->get_email_address();
  my $delegated_email_address = $self->get_delegated_email_address();
  my $scope                   = $self->_formatted_scopes();

  my $header = '{"alg":"RS256","typ":"JWT"}';
  my $claims = "{
    \"iss\":\"${iss}\",
    \"sub\":\"${delegated_email_address}\",
    \"scope\":\"${scope}\",
    \"aud\":\"" . OAUTH2_BASE_URL . "/token\",
    \"exp\":${exp},
    \"iat\":${iat}
  }";

  my $encoded_header = __encode_base64_url($header);
  my $encoded_claims = __encode_base64_url($claims);

  my $key = $self->get___crypt_module()->new_private_key($file) || return 0;
  $key->use_pkcs1_padding();
  $key->use_sha256_hash();

  my $signature         = $key->sign("${encoded_header}.${encoded_claims}");
  my $encoded_signature = __encode_base64_url($signature);
  my $assertion = "${encoded_header}.${encoded_claims}.${encoded_signature}";
  my $body =
    "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer" .
    "&assertion=" . $assertion;
  push my @headers, "Content-Type" => "application/x-www-form-urlencoded";
  my $request =
    HTTP::Request->new("POST", OAUTH2_BASE_URL . "/token", \@headers, $body);
  my $user_agent = $self->get___user_agent();
  my $res        = $user_agent->request($request);

  if (!$res->is_success()) {
    warn($res->decoded_content());
    return 0;
  }

  my $content_hash = $self->__parse_auth_response($res->decoded_content());

  $self->set_access_token($content_hash->{access_token});
  $self->set_access_token_expires($iat + $content_hash->{expires_in});
}

# Return the private key string from either the PEM file or JSON file specified.
sub __read_certificate_file {
  my $self = shift;
  my $private_key;

  if (!$self->get_pem_file() and !$self->get_json_file()) {
    return 0;
  }

  # JSON File
  if ($self->get_json_file()) {
    my $file_str;
    open(MYFILE, $self->get_json_file()) || return 0;
    while (<MYFILE>) {
      $file_str .= $_;
    }
    my $json_values = parse_json ($file_str);
    $private_key = $json_values->{'private_key'};
    $self->set_email_address($json_values->{'client_email'});
    close(MYFILE);
  }
  # PEM File
  else {
    open(MYFILE, $self->get_pem_file()) || return 0;
    while (<MYFILE>) {
      $private_key .= $_;
    }
    close(MYFILE);
  }

  return $private_key;
}

sub __encode_base64_url($) {
  my ($s) = shift;
  $s = encode_base64($s);
  $s =~ tr{+/}{-_};
  $s =~ s/=*$//;
  $s =~ s/\n//g;
  return $s;
}

sub _scope {
  my $self = shift;
  die "Need to be implemented by subclass";
}

sub _formatted_scopes {
  my $self = shift;
  die "Need to be implemented by subclass";
}

sub _throw_error {
  my ($self, $err_msg) = @_;

  $self->get_api_client()->get_die_on_faults() ? die($err_msg) : warn($err_msg);
}

1;

=pod

=head1 NAME

Google::Ads::Common::OAuth2ServiceAccountsHandler

=head1 DESCRIPTION

A generic abstract implementation of L<Google::Ads::Common::OAuth2BaseHandler>
that supports OAuth2 for Service Accounts semantics.

It is meant to be specialized and its L<_scope> and L<_formatted_scopes> methods
be properly implemented.

=head1 ATTRIBUTES

Each of these attributes can be set via
Google::Ads::Common::OAuth2ServiceAccountsHandler->new().

Alternatively, there is a get_ and set_ method associated with each attribute
for retrieving or setting them dynamically.

=head2 api_client

A reference to the API client used to send requests.

=head2 client_id

OAuth2 client id obtained from the Google APIs Console.

=head2 email_address

Service account email address as found in the Google API Console.

=head2 delegated_email_address

Delegated email address of the accounts that has access to the API.

=head2 pem_file

Private key PEM file path. Keep in mind that the Google API Console generates
files in PKCS12 format and it should be converted to PEM format with no password
for this module to function.

=head2 json_file

JOSN file path. This contains the private key and client id needed for
authentication.

=head2 access_token

Stores an OAuth2 access token after the authorization flow is followed or for
you to manually set it in case you had it previously stored.
If this is manually set this handler will verify its validity before preparing
a request.

=head2 additional_scopes

Stores additional OAuth2 scopes as a comma-separated string.
The scope defines which services the tokens
are allowed to access e.g. https://www.googleapis.com/auth/analytics

=head1 METHODS

=head2 initialize

Initializes the handler with properties for generating authorization requests.

=head3 Parameters

=over

=item *

A required I<api_client> with a reference to the API client object handling the
requests against the API.

=item *

A hash reference with the following keys (with this example being for a simple
JSON keyfile):
{
  # Refer to the documentation of the L<delegated_email_address> property.
  oAuth2ServiceAccountDelegateEmailAddress => "delegated-email-address",
  # Refer to the documentation of the L<json_file> property.
  oAuth2ServiceAccountJSONFile => "json-file-path",
}

=head2 is_auth_enabled

Refer to L<Google::Ads::Common::AuthHandlerInterface> documentation of this
method.

=head2 prepare_request

Refer to L<Google::Ads::Common::AuthHandlerInterface> documentation of this
method.

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
