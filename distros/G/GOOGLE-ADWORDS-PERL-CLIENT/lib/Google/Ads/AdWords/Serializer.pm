# Copyright 2011, Google Inc. All Rights Reserved.
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

package Google::Ads::AdWords::Serializer;

use strict;
use utf8;
use version;

use base qw(SOAP::WSDL::Serializer::XSD);

# The following needs to be on one line because CPAN uses a particularly hacky
# eval() to determine module versions.
use Google::Ads::Common::Constants;
use Google::Ads::AdWords::Constants; our $VERSION = ${Google::Ads::AdWords::Constants::VERSION};
use Google::Ads::AdWords::Logging;

use Class::Std::Fast;
use SOAP::WSDL::Factory::Serializer;

# A list of headers that need to be scrubbed before logging due to sensitive
# content.
use constant SCRUBBED_HEADERS => qw(authToken password developerToken);

# Class attributes used to hook this class with the AdWords client.
my %client_of :ATTR(:name<client> :default<>);

# Invoked by SOAP::WSDL to serialize outgoing SOAP requests.
sub serialize {
  my $self = shift;
  my $client = $self->get_client();
  my $request = $self->SUPER::serialize(@_);
  utf8::is_utf8 $request and utf8::encode $request;

  my $sanitized_request = __scrub_request($request);

  my $auth_handler = $client->_get_auth_handler();
  if ($auth_handler && $client->_get_auth_handler()->isa(
      "Google::Ads::Common::AuthTokenHandler")) {
    Google::Ads::AdWords::Logging::get_soap_logger->warn(
        Google::Ads::Common::Constants::CLIENT_LOGIN_DEPRECATION_MESSAGE);
  }

  Google::Ads::AdWords::Logging::get_soap_logger->info("Outgoing Request:\n" .
      $sanitized_request);
  $client->set_last_soap_request($sanitized_request);

  return $request;
}

# Invoked by SOAP::WSDL to serialize outgoing SOAP header, AdWords header
# information is injected at this time.
sub serialize_header {
  my $self = shift;
  my $client = $self->get_client();
  my $client_header = $client->_get_header();
  my $adwords_header = $_[1];

  # Set request header parameters based on configured header parameters
  # through the client class.
  if ($adwords_header->can("set_clientEmail")) {
    $adwords_header->set_clientEmail($client_header->{clientEmail});
  } elsif ($client_header->{clientEmail} &&
           $client_header->{clientEmail} ne "") {
    if ($client->get_die_on_faults()) {
      die("Version " . $client->get_version() .
          " has no support for identifying clients by email.");
    } else {
      warn("Version " . $client->get_version() .
           " has no support for identifying clients by email.");
    }
  }
  $adwords_header->set_clientCustomerId($client_header->{clientCustomerId});
  $adwords_header->set_developerToken($client_header->{developerToken});
  $adwords_header->set_userAgent($client_header->{userAgent});
  $adwords_header->set_validateOnly($client_header->{validateOnly});
  if ($adwords_header->can("set_partialFailure")) {
    $adwords_header->set_partialFailure($client_header->{partialFailure});
  }

  # Serialize the header.
  my $header = $self->SUPER::serialize_header(@_);

  # Hack the header inner elements to correctly include the namespaces.
  my $xmlns = "https://adwords.google.com/api/adwords/cm/" .
      $client->get_version;
  $header =~ s/<authToken>/<authToken xmlns="$xmlns">/;
  $header =~ s/<clientEmail>/<clientEmail xmlns="$xmlns">/;
  $header =~ s/<developerToken>/<developerToken xmlns="$xmlns">/;
  $header =~ s/<userAgent>/<userAgent xmlns="$xmlns">/;
  $header =~ s/<validateOnly>/<validateOnly xmlns="$xmlns">/;
  $header =~ s/<clientCustomerId>/<clientCustomerId xmlns="$xmlns">/;
  $header =~ s/<partialFailure>/<partialFailure xmlns="$xmlns">/;

  return $header;
}

# Private method to redact sensitive information from requests before logging.
sub __scrub_request {
  my ($request) = @_;
  my $scrubbed_request = $request;
  foreach my $header (SCRUBBED_HEADERS) {
    $scrubbed_request =~
        s!<$header([^>]*)>.+?</$header>!<$header$1>REDACTED</$header>!;
  }
  return $scrubbed_request;
}

return 1;

=pod

=head1 NAME

Google::Ads::AdWords::Serializer

=head1 DESCRIPTION

Google::Ads::AdWords::Deserializer extends the
L<SOAP::WSDL::Serializer::XSD|SOAP::WSDL::Serializer::XSD> module. Above the
normal functionality of
L<SOAP::WSDL::Serializer::XSD|SOAP::WSDL::Serializer::XSD>, this module
implements hooks into
L<Google::Ads::AdWords::Client|Google::Ads::AdWords::Client> to inject AdWords
API Header parameters as well as hooks into
L<Google::Ads::AdWords::Client|Google::Ads::AdWords::Logging> to log SOAP
request XML.

=head1 METHODS

=head2 serialize

A method automatically invoked by SOAP::WSDL when an outgoing request needs to
be serialized into SOAP XML. SOAP XML request is logged by this method.

=head3 Parameters

The SOAP request.

=head3 Returns

The SOAP XML string representing the request.

=head2 serialize_header

A method automatically invoked by SOAP::WSDL when an outgoing request header
needs to be serialized into SOAP XML. At this time API headers are injected in
the message.

=head3 Parameters

The SOAP request.

=head3 Returns

The SOAP XML string representing the request.

=head2 __scrub_request (Private)

Scrubs sensitive password and auth token information from the request before
it's logged.

=head3 Parameters

The serialized SOAP request XML string.

=head3 Returns

A redacted version of the string.

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Google Inc.

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

David Torres E<lt>api.davidtorres at gmail.comE<gt>

=head1 REPOSITORY INFORMATION

 $Rev: $
 $LastChangedBy: $
 $Id: $

=cut
