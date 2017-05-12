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

package Google::Ads::AdWords::AuthTokenHandler;

use strict;
use version;
use base qw(Google::Ads::Common::AuthTokenHandler);

# The following needs to be on one line because CPAN uses a particularly hacky
# eval() to determine module versions.
use Google::Ads::AdWords::Constants; our $VERSION = ${Google::Ads::AdWords::Constants::VERSION};

use Class::Std::Fast;

# Class methods from Google::Ads::Common::AuthTokenHandler
sub prepare_request {
  my ($self, $endpoint, $http_headers, $envelope) = @_;

  my $version = $self->get_api_client()->get_version();

  if ($version gt Google::Ads::AdWords::Constants::LAST_SUPPORTED_CLIENT_LOGIN_VERSION) {
      my $message = "ClientLogin is not supported in " . $version .
          " of the AdWords API. Please refer to the ClientLogin to OAuth2" .
          " migration guide at" .
          " https://developers.google.com/adwords/api/docs/guides/clientlogin-to-oauth2-migration-guide" .
          " for more information.";
      $self->get_api_client()->get_die_on_faults() ?
          die($message) :
          warn($message);
  }

  my $xmlns = "https://adwords.google.com/api/adwords/cm/" . $version;
  my $header = "<authToken xmlns=\"$xmlns\">" . $self->__get_auth_token() .
      "</authToken>";

  $envelope =~ s/(<RequestHeader [^>]+>)/$1${header}/;

  return HTTP::Request->new('POST', $endpoint, $http_headers, $envelope);
}

sub _service {
  return "adwords";
}

1;

=pod

=head1 NAME

Google::Ads::AdWords::AuthTokenHandler

=head1 DESCRIPTION

A concrete implementation of L<Google::Ads::Common::AuthTokenHandler> that
defines the auth service name required to access AdWords API servers using
ClientLogin, see
L<https://developers.google.com/accounts/docs/AuthForInstalledApps> for details
of the protocol.

Refer to the base object L<Google::Ads::Common::AuthTokenHandler>
for a complete documentation of all the methods supported by this handler class.

=head1 METHODS

=head2 _service

Method defined by L<Google::Ads::AdWords::AuthTokenHandler> and implemented
in this class as a requirement for the ClientLogin protocol.

=head3 Returns

Returns the AdWords API service name used to generate the AuthToken.

=head2 prepare_request

Method defined by B<Google::Ads::AdWords::AuthTokenHandler> and implemented
in this class as a requirement for sending requests to the AdWords API.

=head3 Returns

A new L<HTTP:Request> with the I<authToken> header properly set with the
authorization information.

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
