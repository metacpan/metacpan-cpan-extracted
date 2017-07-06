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

package TestClientUtils;

use strict;
use vars qw(@EXPORT_OK @ISA);

use Google::Ads::AdWords::Client;

use Exporter;
use File::Basename;
use File::Spec;
use Test::MockObject::Extends;
use TestUtils qw(read_client_properties);

@ISA       = qw(Exporter);
@EXPORT_OK
  = qw(get_test_client get_test_manager_account_client get_test_client_no_auth);

sub get_test_client {
  my $api_version = shift;

  my $properties_file =
    File::Spec->catdir(dirname($0), qw(testdata client.properties));

  my $client =
    Google::Ads::AdWords::Client->new({properties_file => $properties_file});

  Google::Ads::AdWords::Logging::enable_all_logging();
  if ($api_version) {
    $client->set_version($api_version);
  }

  return $client;
}

sub get_test_manager_account_client {
  my $api_version = shift;

  my $client = get_test_client($api_version);

  my $client_properties = read_client_properties();

  my $manager_account_client_id
    = $client_properties->getProperty('managerAccountClientId');

  die "No manager account client ID found" unless $manager_account_client_id;

  $client->set_client_id($manager_account_client_id);
}

sub get_test_client_no_auth {
  my $properties_file =
    File::Spec->catdir(dirname($0), qw(testdata client.properties));

  my $client =
    Google::Ads::AdWords::Client->new({properties_file => $properties_file});

  $client = Test::MockObject::Extends->new($client);
  $client->mock("_get_auth_handler", sub { return undef; });
  $client->mock("get_last_soap_request", sub { return "N/A"; });

  return $client;
}

return 1;
