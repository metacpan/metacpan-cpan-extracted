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
# This example adds an AdWords conversion tracker.

use strict;
use lib "../../../lib";
use utf8;

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201705::AdWordsConversionTracker;
use Google::Ads::AdWords::v201705::ConversionTrackerOperation;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);

# Example main subroutine.
sub add_conversion_tracker {
  my $client = shift;

  # Create adwords conversion tracker.
  my $conversion_tracker =
    Google::Ads::AdWords::v201705::AdWordsConversionTracker->new({
      name => "Earth to Mars Cruises Conversion #" . uniqid(),
      # Additional properties (non-required).
      status                               => "ENABLED",
      category                             => "DEFAULT",
      textFormat                           => "HIDDEN",
      viewthroughLookbackWindow            => 15,
      conversionPageLanguage               => "en",
      backgroundColor                      => "#0000FF",
      defaultRevenueValue                  => 1,
      alwaysUseDefaultRevenueValue         => 1
    });

  # Create operation.
  my $conversion_operation =
    Google::Ads::AdWords::v201705::ConversionTrackerOperation->new({
      operator => "ADD",
      operand  => $conversion_tracker
    });

  # Add conversion tracker.
  my $result =
    $client->ConversionTrackerService()
    ->mutate({operations => [$conversion_operation]});

  # Display conversion tracker.
  if ($result->get_value()) {
    my $conversion_tracker = $result->get_value()->[0];
    printf "Conversion tracker with id \"%d\", name \"%s\", status \"%s\" " .
      "and category \"%s\" was added.\n", $conversion_tracker->get_id(),
      $conversion_tracker->get_name(), $conversion_tracker->get_status(),
      $conversion_tracker->get_category();
    printf "With associated code snippet:\n%s\n",
      $conversion_tracker->get_snippet();
  } else {
    print "No conversion tracker was added.";
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
my $client = Google::Ads::AdWords::Client->new({version => "v201705"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
add_conversion_tracker($client);
