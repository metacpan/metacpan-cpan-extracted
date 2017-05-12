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

package Google::Ads::Common::OAuthApplicationsHandlerInterface;

use base qw(Google::Ads::Common::AuthHandlerInterface);

# Method to retrieve an authorization URL for the user to put in a
# browser and authorize a request token.
# Meant to be implemented by a concrete class, which should issue a request
# token and return a valid URL for the user to authorize the token.
# The implementor must save the request token in the token attribute for later
# use by the upgrade_token method.
# A callback URL can be passed to re-direct the user after the token is
# authorized.
sub get_authorization_url {
  my ($self, $callback) = @_;
  die "Needs to be implemented by subclass";
}

# Method to issue an access token given an authorization code. After calling
# this method the auth handler should be prepared to prepare HTTP requests
# against protected resources.
sub issue_access_token {
  my ($self, $auth_code) = @_;
  die "Needs to be implemented by subclass";
}

1;

=pod

=head1 NAME

Google::Ads::Common::OAuthApplicationsHandlerInterface

=head1 DESCRIPTION

Abstract interface for oauth flows that require user interaction.

Meant be implemented by concrete OAuth handlers that require user intervention
for authorizing requests against the API.

=head1 METHODS

=head2 get_authorization_url

Meant to be implemented by a concrete class, which should return a valid URL
for the user to authorize the access to the API.

=head3 Returns

The URL for the user to authorize access to his account. The user first must
login in the account that want to grant access to.

=head2 issue_access_token

Method to upgrade/obtain an authorized access token.

=head3 Parameters

=over

=item *

The verifier code returned to your callback page or printed out if using 'oob'
special callback URL.

=back

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
