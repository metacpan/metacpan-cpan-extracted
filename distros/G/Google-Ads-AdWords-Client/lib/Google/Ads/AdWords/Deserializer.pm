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

package Google::Ads::AdWords::Deserializer;

use strict;
use warnings;
use utf8;
use version;
use Scalar::Util qw(blessed);

use base qw(SOAP::WSDL::Deserializer::XSD);

# The following needs to be on one line because CPAN uses a particularly hacky
# eval() to determine module versions.
use Google::Ads::AdWords::Constants; our $VERSION = ${Google::Ads::AdWords::Constants::VERSION};
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::RequestStats;
use Google::Ads::SOAP::Deserializer::MessageParser;

# Class attributes used to hook this class with the AdWords client
my %client_of : ATTR(:name<client> :default<>);

# Invoked by SOAP::WSDL to deserialize incoming SOAP responses.
sub deserialize {
  my $self           = shift;
  my ($response_xml) = @_;
  my $client         = $self->get_client();
  utf8::is_utf8 $response_xml and utf8::encode $response_xml;

  my $request_message = sprintf("Outgoing request:\n%s",
    $client->get_last_soap_request());
  my $response_message = sprintf("Incoming response:\n%s", $response_xml);
  $client->set_last_soap_response($response_xml);

  my $response_header =
    $self->__get_element_content($response_xml, "ResponseHeader");

  my $request_stats;
  if ($response_header) {
    my $request_id =
      $self->__get_element_content($response_header, "requestId");
    my $service_name =
      $self->__get_element_content($response_header, "serviceName");
    my $method_name =
      $self->__get_element_content($response_header, "methodName");
    my $operations =
      $self->__get_element_content($response_header, "operations");
    my $response_time =
      $self->__get_element_content($response_header, "responseTime");

    my $auth_handler = $client->_get_auth_handler();
    $request_stats = Google::Ads::AdWords::RequestStats->new({
      client_id     => $client->get_client_id(),
      server        => $client->get_alternate_url(),
      service_name  => $service_name,
      method_name   => $method_name,
      response_time => $response_time,
      request_id    => $request_id,
      operations    => $operations
    });
  }

  $response_xml =~ s!<soap:Header>.*</soap:Header>!<soap:Header></soap:Header>!;
  my @response = $self->_deserialize($response_xml);
  my $is_fault = $response[0]->isa("SOAP::WSDL::SOAP::Typelib::Fault");

  if ($request_stats) {
    $request_stats->set_is_fault($is_fault);
    if ($is_fault) {
      $request_stats->set_fault_message($response[0]->get_faultstring());
      Google::Ads::AdWords::Logging::get_awapi_logger->logwarn($request_stats);
    } else {
      Google::Ads::AdWords::Logging::get_awapi_logger->info($request_stats);
    }
    $client->_push_new_request_stats($request_stats);
  }

  if ($is_fault) {
    Google::Ads::AdWords::Logging::get_soap_logger->info($request_message);
    Google::Ads::AdWords::Logging::get_soap_logger->info($response_message);
    if ($self->get_client->get_die_on_faults) {
      die(
        sprintf("A fault was returned by the server:\n%s\n",
          $response[0]->get_faultstring()));
    }
  } else {
    Google::Ads::AdWords::Logging::get_soap_logger->debug($request_message);
    Google::Ads::AdWords::Logging::get_soap_logger->debug($response_message);
  }

  # Unwrapping the response if contains an rval no value for the user to see the
  # outer response object.
  if ($response[0] && $response[0]->can('get_rval')) {
    $response[0] = $response[0]->get_rval();
  }

  return @response;
}

sub _deserialize {
  my ($self, $content) = @_;

  my $parser = Google::Ads::SOAP::Deserializer::MessageParser->new(
    {strict => $self->get_strict()});
  $parser->class_resolver($self->get_class_resolver());
  eval { $parser->parse_string($content) };
  if ($@) {
    return $self->generate_fault({
      code    => 'SOAP-ENV:Server',
      role    => 'urn:localhost',
      message => "Error deserializing message: $@. \n" .
        "Message was: \n$content"
    });
  }
  return ($parser->get_data(), $parser->get_header());
}

# Retrieves the content of a given XML element.
sub __get_element_content {
  my ($self, $xml, $element_name) = @_;

  my $regex =
    "<(?:[^:>]+:)?${element_name}(?:\\s[^>]*)?>(.+?)" .
    "</(?:[^:>]+:)?${element_name}(?:\\s[^>]*)?>";

  $xml =~ /$regex/ and my $content = $1;

  return $content;
}

# Invoked by SOAP::WSDL when deserialize die()s.
sub generate_fault {
  my ($self, $args) = @_;
  Google::Ads::AdWords::Logging::get_soap_logger->info($args->{message});
  die($args->{message});
}

return 1;

=pod

=head1 NAME

Google::Ads::AdWords::Deserializer

=head1 DESCRIPTION

Google::Ads::AdWords::Deserializer extends the
L<SOAP::WSDL::Deserializer::XSD|SOAP::WSDL::Deserializer::XSD> module.
The default deserializer used by <SOAP::WSDL|SOAP::WSDL>.
Above the normal functionality of
L<SOAP::WSDL::Deserializer::XSD|SOAP::WSDL::Deserializer::XSD>,
this module implements hooks into
L<Google::Ads::AdWords::Logging|Google::Ads::AdWords::Logging> to simplify
logging and keeping track of all the information in the AdWords API response
headers.

=head1 METHODS

=head2 deserialize

A method automatically invoked by SOAP::WSDL when an incoming SOAP XML response
needs to be deserialized.

=head3 Parameters

The SOAP XML response string.

=head3 Returns

A L<SOAP::WSDL|SOAP::WSDL> object representing the SOAP response. Most of the
API calls return their result wrapped within an <rval> tag, that gets unwrapped
and the inner object is returned instead in those cases.

=head3 Exceptions

If deserialization fails or the SOAP response contains a
L<SOAP::WSDL::SOAP::Typelib::Fault11> object and
Google::Ads::AdWords::Client::get_die_on_faults() is set to true, then a die
call is triggered.

If L<Google::Ads::AdWords::Client::get_die_on_faults()> is set to false then the
deserialized message will be passed back, containing a
L<SOAP::WSDL::SOAP::Typelib::Fault11> object.

=head2 generate_fault

A method automatically invoked on deserialization if an error occurred and
L<Google::Ads::AdWords::Client::get_die_on_faults()> is set to true.

=head3 Parameters

A L<SOAP::WSDL::SOAP::Typelib::Fault11> object.

=head3 Exceptions

Always die()s with the value of the input parameter's message.

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

=head1 REPOSITORY INFORMATION

 $Rev: $
 $LastChangedBy: $
 $Id: $

=cut
