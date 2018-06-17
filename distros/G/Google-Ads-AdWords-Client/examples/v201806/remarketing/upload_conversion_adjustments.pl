#!/usr/bin/perl -w
#
# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#        https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# This code example imports conversion adjustments for conversions that already
# exist. To set up a conversion tracker, run the add_conversion_tracker.pl
# example.

use strict;
use lib "../../../lib";
use utf8;

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201806::GclidOfflineConversionAdjustmentFeed;
use Google::Ads::AdWords::v201806::OfflineConversionAdjustmentFeedOperation;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);

# Replace with valid values of your account.
my $conversion_name     = "INSERT_CONVERSION_NAME_HERE";
my $gclid               = "INSERT_GCLID_HERE";
my $adjustment_type     = "INSERT_ADJUSTMENT_TYPE_HERE";
my $conversion_time     = "INSERT_CONVERSION_TIME_HERE";
my $adjustment_time     = "INSERT_ADJUSTMENT_TIME_HERE";
my $adjusted_value      = "INSERT_ADJUST_VALUE_HERE";

# Example main subroutine.
sub upload_conversion_adjustment {
  my ($client, $conversion_name, $gclid, $adjustment_type,
      $conversion_time, $adjustment_time, $adjusted_value) = @_;
  # This example demonstrates adjusting one conversion, but you can add more
  # than one operation to adjust more in a single mutate request.
  my @conversion_adjustment_operations = ();

  # Associate conversion adjustments with the existing named conversion
  # tracker. The GCLID should have been uploaded before with a conversion.
  my $feed =
      Google::Ads::AdWords::v201806::GclidOfflineConversionAdjustmentFeed->new({
      conversionName  => $conversion_name,
      adjustmentType  => $adjustment_type,
      conversionTime  => $conversion_time,
      adjustmentTime  => $adjustment_time,
      adjustedValue   => $adjusted_value,
      googleClickId   => $gclid,
  });

  my $conversion_adjustment_operation =
    Google::Ads::AdWords::v201806::OfflineConversionAdjustmentFeedOperation->new({
      operator => "ADD",
      operand  => $feed
    });

  push @conversion_adjustment_operations, $conversion_adjustment_operation;

  # Add the conversion adjustment.
  my $result =
    $client->OfflineConversionAdjustmentFeedService()
    ->mutate({operations => \@conversion_adjustment_operations});

  # Display results.
  if ($result->get_value()) {
    foreach my $adjustment_feed (@{$result->get_value()}) {
      printf "Uploaded conversion adjusted value of \"%s\" for Google Click " .
        "ID \"%s\"\n",
        $adjustment_feed->get_adjustedValue(),
        $adjustment_feed->get_googleClickId();
    }
  } else {
    print "No conversion adjustments were added.\n";
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
my $client = Google::Ads::AdWords::Client->new({version => "v201806"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
upload_conversion_adjustment($client, $conversion_name, $gclid,
    $adjustment_type, $conversion_time, $adjustment_time, $adjusted_value);
