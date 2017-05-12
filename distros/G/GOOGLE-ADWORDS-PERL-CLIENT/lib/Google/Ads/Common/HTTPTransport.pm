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

package Google::Ads::Common::HTTPTransport;

use strict;
use version;
use base qw(SOAP::WSDL::Transport::HTTP);

# The following needs to be on one line because CPAN uses a particularly hacky
# eval() to determine module versions.
use Google::Ads::Common::Constants; our $VERSION = ${Google::Ads::Common::Constants::VERSION};

sub client {
  my ($self, $client) = @_;

  if (defined $client) {
    $self->{_client} = $client;
    my $can_accept = HTTP::Message::decodable;
    $self->default_header('Accept-Encoding' => scalar $can_accept);
    $self->{_user_agent} = $client->get_user_agent() .
         ($can_accept =~ /gzip/i ? " gzip" : "");
  }

  return $self->{_client};
}

sub send_receive {
  my ($self, %parameters) = @_;
  my ($envelope, $soap_action, $endpoint, $encoding, $content_type) =
      @parameters{qw(envelope action endpoint encoding content_type)};

  my $auth_handler = $self->client->_get_auth_handler();

  if (!$auth_handler) {
    $self->{_client}->get_die_on_faults() ?
        die(Google::Ads::Common::Constants::NO_AUTH_HANDLER_IS_SETUP_MESSAGE) :
        warn(Google::Ads::Common::Constants::NO_AUTH_HANDLER_IS_SETUP_MESSAGE);
    return;
  }

  # Overriding the default LWP user agent.
  $self->agent($self->{_user_agent});

  $encoding = defined($encoding) ? lc($encoding) : 'utf-8';

  $content_type = "text/xml; charset=$encoding"
      if not defined($content_type);

  my $headers = ["Content-Type", "$content_type", "SOAPAction", $soap_action];
  my $request = $auth_handler->prepare_request($endpoint, $headers, $envelope);
  my $response = $self->request( $request );

  $self->code( $response->code);
  $self->message( $response->message);
  $self->is_success($response->is_success);
  $self->status($response->status_line);

  return $response->decoded_content();
}

return 1;

=pod

=head1 NAME

Google::Ads::Common::HTTPTransport - Specialization of
L<SOAP::WSDL::Transport::HTTP> transport class with added logic to handle OAuth.

=head1 DESCRIPTION

Provides a thin transport class on top of L<SOAP::WSDL::Transport::HTTP>  to add
support to pluggable authorization methods.

=head1 ATTRIBUTES

=head2 client

Holds an instance of the API client, which will use to retrieve the current
L<Google::Ads::Common::AuthHandlerInterface>.

=head1 METHODS

=head2 send_receive

Overrides L<SOAP::WSDL::Transport::HTTP> send_receive method to change the
endpoint in case OAuth is enabled, uses the L<Google::Ads::AdWords::Client>
configured OAuth handler to leverage all the OAuth signing logic.

=head3 Parameters

The same as the L<SOAP::WSDL::Transport::HTTP> send_receive method.

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

David Torres E<lt>david.t at google.comE<gt>

=head1 REPOSITORY INFORMATION

 $Rev: $
 $LastChangedBy: $
 $Id: $

=cut
