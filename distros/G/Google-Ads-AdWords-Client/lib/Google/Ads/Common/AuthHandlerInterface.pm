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

package Google::Ads::Common::AuthHandlerInterface;

# Initializes the handler with a given set of properties and the API client
# object.
sub initialize {
  my ($self, $api_client, $properties) = @_;
  die "Needs to be implemented by subclass";
}

# Method that given an HTTP:Request prepares it with the relevant
# authorization data (i.e. headers, protected resource url, etc).
sub prepare_request {
  my ($self, $endpoint, $http_headers, $envelope) = @_;
  die "Needs to be implemented by subclass";
}

# Returns true if the handler can prepare request with the appropiate
# authorization info.
sub is_auth_enabled {
  my ($self) = @_;
  die "Needs to be implemented by subclass";
}

1;

=pod

=head1 NAME

Google::Ads::Common::AuthHandlerInterface

=head1 DESCRIPTION

Interface to be implemented by concrete authorization handlers. Defines the
necessary subroutines to build authorized request against a Google API.

=head1 METHODS

=head2 initialize

Initializes the handler with a given set of properties. Used to pass parameters
such as: client ids, access tokens, etc.

=head3 Parameters

=over

=item *

A required I<api_client> with a reference to the API client object handling the
requests against the API.

=item *

A required I<properties> with a reference to a hash of properties.

=back

=head2 prepare_request

Constructs a L<HTTP::Request> valid to send an authorized request to the API.
Implementors will attach authorization headers to the request at this phase.

=head3 Parameters

=over

=item *

I<endpoint>: URL to the resource to access.

=item *

I<http_headers>: a map of HTTP headers to be included in the request.

=item *

I<envelope>: a string with the payload to be send in the request.

=back

=head2 is_auth_enabled

Method called to check if the authorization has already been setup, so the
I<prepare_request> method can be called.

=head3 Returns

True, if the authorization is in place and the class can prepare requests.
False, otherwise.

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

=head1 REPOSITORY INFORMATION

 $Rev: $
 $LastChangedBy: $
 $Id: $

=cut
