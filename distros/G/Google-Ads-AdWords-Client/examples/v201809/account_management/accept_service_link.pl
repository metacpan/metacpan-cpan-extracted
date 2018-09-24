#!/usr/bin/perl -w
#
# Copyright 2017, Google Inc. All Rights Reserved.
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
#
# This example accepts a pending invitation to link your AdWords account to a
# Google Merchant Center account.

use strict;

use lib "../../../lib";
use utf8;

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201809::ServiceLink;
use Google::Ads::AdWords::v201809::ServiceLinkOperation;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);

# Replace with valid values of your account.
my $service_link_id = "INSERT_SERVICE_LINK_ID_HERE";

# Example main subroutine.
sub accept_service_link {
  my $client          = shift;
  my $service_link_id = shift;

  my $service_link = Google::Ads::AdWords::v201809::ServiceLink->new({
    serviceLinkId => $service_link_id,
    serviceType   => "MERCHANT_CENTER",
    linkStatus    => "ACTIVE"
  });

  # Create the operation to set the status to ACTIVE.
  my $op = Google::Ads::AdWords::v201809::ServiceLinkOperation->new({
    operator => "SET",
    operand  => $service_link
  });

  # Update the service link.
  my $mutated_service_links =
    $client->CustomerService->mutateServiceLinks({operations => [$op]});

  # Display the results.
  foreach my $mutated_service_link ($mutated_service_links) {
    printf(
      "Service link with service link ID %d, " .
        "type '%s' updated to status: %s.\n",
      $mutated_service_link->get_serviceLinkId(),
      $mutated_service_link->get_serviceType(),
      $mutated_service_link->get_linkStatus());

  }

  return 1;
}

# Don't run the example if the file is being included.
if (abs_path($0) ne abs_path(__FILE__)) {
  return 1;
}

# Log SOAP XML request, response and API errors.
Google::Ads::AdWords::Logging::enable_all_logging();

# Get AdWords Client, credentials will be read from ~/adwords.properties.
my $client = Google::Ads::AdWords::Client->new({version => "v201809"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
accept_service_link($client, $service_link_id);
