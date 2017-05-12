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
# This code example imports offline call conversion values for calls
# related to the ads in your account. To set up a conversion tracker, run the
# add_conversion_tracker.pl example using UploadCallConversion as the
# conversion tracker.

use strict;
use lib "../../../lib";
use utf8;

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201702::OfflineCallConversionFeed;
use Google::Ads::AdWords::v201702::OfflineCallConversionFeedOperation;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);

# Replace with valid values of your account.
my $caller_id        = "INSERT_CALLER_ID_HERE";
# For times use the format yyyyMMdd HHmmss tz. For more details on formats,
# see: https://developers.google.com/adwords/api/docs/appendix/codes-formats#date-and-time-formats
# For time zones, see: https://developers.google.com/adwords/api/docs/appendix/codes-formats#timezone-ids
my $call_start_time  = "INSERT_CALL_START_TIME_HERE";
my $conversion_name  = "INSERT_CONVERSION_NAME_HERE";
my $conversion_time  = "INSERT_CONVERSION_TIME_HERE";
my $conversion_value = "INSERT_CONVERSION_VALUE_HERE";

# Example main subroutine.
sub upload_offline_call_conversions {
  my $client                             = shift;
  my $caller_id                          = shift;
  my $call_start_time                    = shift;
  my $conversion_name                    = shift;
  my $conversion_time                    = shift;
  my $conversion_value                   = shift;
  my @offline_call_conversion_operations = ();

  # Associate offline call conversions with the existing named
  # conversion tracker. If this tracker was newly created, it may be a
  # few hours before it can accept conversions.
  my $feed = Google::Ads::AdWords::v201702::OfflineCallConversionFeed->new({
    callerId        => $caller_id,
    callStartTime   => $call_start_time,
    conversionName  => $conversion_name,
    conversionTime  => $conversion_time,
    conversionValue => $conversion_value
  });

  my $offline_call_conversion_operation =
    Google::Ads::AdWords::v201702::OfflineCallConversionFeedOperation->new({
      operator => "ADD",
      operand  => $feed
    });

  push @offline_call_conversion_operations, $offline_call_conversion_operation;

  # This example uploads only one call conversion, but you can upload multiple
  # call conversions by passing additional operations.
  my $result =
    $client->OfflineCallConversionFeedService()
    ->mutate({operations => \@offline_call_conversion_operations});

  # Display results.
  if ($result->get_value()) {
    foreach my $feed_result (@{$result->get_value()}) {
      printf "Uploaded offline call conversion value of \"%s\" for caller ID " .
        "\"%s\".\n",
        $feed_result->get_conversionValue(),
        $feed_result->get_callerId();
    }
  } else {
    print "No offline call conversions were added.\n";
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
my $client = Google::Ads::AdWords::Client->new({version => "v201702"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
upload_offline_call_conversions($client, $caller_id, $call_start_time,
  $conversion_name, $conversion_time, $conversion_value);
