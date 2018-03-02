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
# This example gets location criteria by name.

use strict;
use lib "../../../lib";
use utf8;

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201802::OrderBy;
use Google::Ads::AdWords::v201802::Predicate;
use Google::Ads::AdWords::v201802::Selector;

use Cwd qw(abs_path);

# Example main subroutine.
sub lookup_location {
  my $client = shift;

  # Create selector.
  my $selector = Google::Ads::AdWords::v201802::Selector->new({
      fields => [
        "Id",              "LocationName", "CanonicalName", "DisplayType",
        "ParentLocations", "Reach",        "TargetingStatus"
      ],
      predicates => [
        Google::Ads::AdWords::v201802::Predicate->new({
            field    => "LocationName",
            operator => "IN",
            values   => ["Paris", "Quebec", "Spain", "Deutschland"]}
        ),
        Google::Ads::AdWords::v201802::Predicate->new({
            field    => "Locale",
            operator => "EQUALS",
            values   => "en"
          })
      ],
      ordering => [
        Google::Ads::AdWords::v201802::OrderBy->new({
            field     => "LocationName",
            sortOrder => "ASCENDING"
          })]});

  # Get all campaigns.
  my $location_criteria =
    $client->LocationCriterionService()->get({selector => $selector});

  # Display campaigns.
  foreach my $location_criterion (@{$location_criteria}) {
    my @parent_locations = ();
    if ($location_criterion->get_location()->get_parentLocations()) {
      foreach my $parent_location (
        @{$location_criterion->get_location()->get_parentLocations()})
      {
        push @parent_locations,
          sprintf("%s (%s)",
          $parent_location->get_locationName(),
          $parent_location->get_displayType());
      }
    }

    my $location = $location_criterion->get_location();
    printf "The search term '%s' returned the location '%s' of type '%s' "
      . "with parent locations '%s', reach '%d' and targeting status '%s'.\n",
      $location_criterion->get_searchTerm, $location->get_locationName(),
      $location->get_displayType(),
      scalar(@parent_locations) ? join(", ", @parent_locations) : "N/A",
      $location_criterion->get_reach(), $location->get_targetingStatus();
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
my $client = Google::Ads::AdWords::Client->new({version => "v201802"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
lookup_location($client);
