#!/usr/bin/perl -w
#
# Copyright 2016, Google Inc. All Rights Reserved.
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
# This code example imports offline conversion values for specific clicks to
# your account. To get Google Click ID for a click, run
# CLICK_PERFORMANCE_REPORT.

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201607::UploadConversion;
use Google::Ads::AdWords::v201607::ConversionTrackerOperation;
use Google::Ads::AdWords::v201607::OfflineConversionFeed;
use Google::Ads::AdWords::v201607::OfflineConversionFeedOperation;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);

# Replace with valid values of your account.
my $conversion_name  = "INSERT_CONVERSION_NAME_HERE";
my $gclid            = "INSERT_GCLID_HERE";
my $conversion_time  = "INSERT_CONVERSION_TIME_HERE";
my $conversion_value = "INSERT_CONVERSION_VALUE_HERE";

# Example main subroutine.
sub upload_offline_conversions {
  my $client           = shift;
  my $conversion_name  = shift;
  my $gclid            = shift;
  my $conversion_time  = shift;
  my $conversion_value = shift;

  my @conversion_tracker_operations = ();
  my @offline_conversion_operations = ();

  # Create an upload conversion. Once created, this entry will be visible
  # under Tools and Analysis->Conversion and will have Source = Import.
  my $upload_conversion = Google::Ads::AdWords::v201607::UploadConversion->new({
      category                  => 'PAGE_VIEW',
      name                      => $conversion_name,
      viewthroughLookbackWindow => 30,
      ctcLookbackWindow         => 90
  });

  my $upload_operation =
    Google::Ads::AdWords::v201607::ConversionTrackerOperation->new({
      operator => "ADD",
      operand  => $upload_conversion
    });

  push @conversion_tracker_operations, $upload_operation;

  # Add the upload conversion.
  my $tracker_result =
    $client->ConversionTrackerService()
    ->mutate({operations => \@conversion_tracker_operations});

  # Display results.
  if ($tracker_result->get_value()) {
    foreach my $conversion_tracker (@{$tracker_result->get_value()}) {
      printf "New upload conversion type with name \"%s\" and ID \"%d\" " .
        "was created.\n",
        $conversion_tracker->get_name(),
        $conversion_tracker->get_id();
    }
  } else {
    print "No upload conversions were added.\n";
    return;
  }

  # Associate offline conversions with the upload conversion we created.
  my $feed = Google::Ads::AdWords::v201607::OfflineConversionFeed->new({
      conversionName  => $conversion_name,
      conversionTime  => $conversion_time,
      conversionValue => $conversion_value,
      googleClickId   => $gclid
  });

  my $offline_conversion_operation =
    Google::Ads::AdWords::v201607::OfflineConversionFeedOperation->new({
      operator => "ADD",
      operand  => $feed
    });

  push @offline_conversion_operations, $offline_conversion_operation;

  # Add the upload conversion.
  my $feed_result =
    $client->OfflineConversionFeedService()
    ->mutate({operations => \@offline_conversion_operations});

  # Display results.
  if ($feed_result->get_value()) {
    foreach my $oc_feed (@{$feed_result->get_value()}) {
      printf "Uploaded offline conversion value of \"%s\" for Google Click " .
        "ID \"%s\" was created.\n",
        $oc_feed->get_conversionName(),
        $oc_feed->get_googleClickId();
    }
  } else {
    print "No offline conversion were added.\n";
    return;
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
my $client = Google::Ads::AdWords::Client->new({version => "v201607"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
upload_offline_conversions($client, $conversion_name, $gclid, $conversion_time,
  $conversion_value);
