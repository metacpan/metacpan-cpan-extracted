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
# This code example adds an AdWords conversion tracker and an upload conversion
# tracker.

use strict;
use lib "../../../lib";
use utf8;

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201809::AdWordsConversionTracker;
use Google::Ads::AdWords::v201809::ConversionTrackerOperation;
use Google::Ads::AdWords::v201809::UploadConversion;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);

# Example main subroutine.
sub add_conversion_trackers {
  my $client = shift;

  my @conversion_trackers = ();

  # Create AdWords conversion tracker.
  my $adwords_conversion_tracker =
    Google::Ads::AdWords::v201809::AdWordsConversionTracker->new({
      name => "Earth to Mars Cruises Conversion #" . uniqid(),
      # Additional properties (non-required).
      status                               => "ENABLED",
      category                             => "DEFAULT",
      viewthroughLookbackWindow            => 15,
      defaultRevenueValue                  => 23.41,
      alwaysUseDefaultRevenueValue         => 1
    });
  push @conversion_trackers, $adwords_conversion_tracker;

  # Create an upload conversion for offline conversion imports.
  my $upload_conversion_tracker =
    Google::Ads::AdWords::v201809::UploadConversion->new({
      # Set an appropriate category. This field is optional, and will be set to
      # DEFAULT if not mentioned.
      category                             => "LEAD",
      name                                 => "Upload Conversion #" . uniqid(),
      viewthroughLookbackWindow            => 30,
      ctcLookbackWindow                    => 90,
      # Optional: Set the default currency code to use for conversions
      # that do not specify a conversion currency. This must be an ISO 4217
      # 3-character currency code such as "EUR" or "USD".
      # If this field is not set on this UploadConversion, AdWords will use
      # the account's currency.
      defaultRevenueCurrencyCode => "EUR",
      # Optional: Set the default revenue value to use for conversions
      # that do not specify a conversion value. Note that this value
      # should NOT be in micros.
      defaultRevenueValue => 2.50,
      # Optional: To upload fractional conversion credits, mark the upload conversion
      # as externally attributed. See
      # https://developers.google.com/adwords/api/docs/guides/conversion-tracking#importing_externally_attributed_conversions
      # to learn more about importing externally attributed conversions.
      # isExternallyAttributed => true
    });
  push @conversion_trackers, $upload_conversion_tracker;

  my @operations = ();
  for my $conversion_tracker (@conversion_trackers) {
    # Create operation.
    my $conversion_operation =
      Google::Ads::AdWords::v201809::ConversionTrackerOperation->new({
        operator => "ADD",
        operand  => $conversion_tracker
      });
    push @operations, $conversion_operation;
  }

  # Add conversion trackers.
  my $result =
    $client->ConversionTrackerService()
    ->mutate({operations => \@operations});

  # Display conversion tracker.
  if ($result->get_value()) {
    foreach my $conversion_tracker (@{$result->get_value()}) {
      printf "Conversion tracker with ID %d, name \"%s\", status \"%s\" " .
        "and category \"%s\" was added.\n", $conversion_tracker->get_id(),
        $conversion_tracker->get_name(), $conversion_tracker->get_status(),
        $conversion_tracker->get_category();
      if ($conversion_tracker
        ->isa("Google::Ads::AdWords::v201809::AdWordsConversionTracker")) {
        printf("Google global site tag:\n%s\n\n",
          $conversion_tracker->get_googleGlobalSiteTag());
        printf("Google event snippet:\n%s\n\n",
          $conversion_tracker->get_googleEventSnippet());
      }
    }
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
my $client = Google::Ads::AdWords::Client->new({version => "v201809"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
add_conversion_trackers($client);
