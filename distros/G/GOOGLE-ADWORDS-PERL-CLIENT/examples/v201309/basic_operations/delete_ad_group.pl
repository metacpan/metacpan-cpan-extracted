#!/usr/bin/perl -w
#
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
#
# This example renames and deletes an ad group by setting the status to
# 'DELETED'. To get ad groups, run basic_operations/get_ad_groups.pl.
#
# Tags: AdGroupService.mutate
# Author: David Torres <api.davidtorres@gmail.com>

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201309::AdGroup;
use Google::Ads::AdWords::v201309::AdGroupOperation;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);

# Replace with valid values of your account.
my $ad_group_id = "INSERT_AD_GROUP_ID_HERE";

# Example main subroutine.
sub delete_ad_group {
  my $client = shift;
  my $ad_group_id = shift;

  # Create ad group with DELETED status.
  my $ad_group = Google::Ads::AdWords::v201309::AdGroup->new({
    id => $ad_group_id,
    # When deleting an ad group, it is a good practice to also rename it to
    # avoid name collisions when creating new ad groups.
    name => "Deleted Ad Group - " . uniqid(),
    status => "DELETED"
  });

  # Create operation.
  my $operation = Google::Ads::AdWords::v201309::AdGroupOperation->new({
    operand => $ad_group,
    operator => "SET"
  });

  # Delete ad group.
  my $result = $client->AdGroupService()->mutate({
    operations => [$operation]
  });

  # Display ad groups.
  if ($result->get_value()) {
    my $ad_group = $result->get_value()->[0];
    printf "The ad group with id \"%d\" was renamed to \"%s\" and deleted.\n",
           $ad_group->get_id(), $ad_group->get_name();
  } else {
    print "No ad group was deleted.\n";
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
my $client = Google::Ads::AdWords::Client->new({version => "v201309"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
delete_ad_group($client, $ad_group_id);
