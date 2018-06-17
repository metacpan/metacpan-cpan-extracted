#!/usr/bin/perl -w
#
# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# This example updates an expanded text ad. To get expanded text ads, run
# get_expanded_text_ads.pl .

use strict;
use lib "../../../lib";
use utf8;

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201806::AdOperation;
use Google::Ads::AdWords::v201806::ExpandedTextAd;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);

# Replace with valid values of your account.
my $ad_id = "INSERT_AD_ID_HERE";

# Example main subroutine.
sub update_expanded_text_ad {
    my ($client, $ad_id) = @_;

    my @operations = ();
    # Creates an expanded text ad using the provided ad ID.
    my $expanded_text_ad = Google::Ads::AdWords::v201806::ExpandedTextAd->new({
        id              => $ad_id,
        headlinePart1   => "Cruise to Pluto #" . substr(uniqid(), 0, 8),
        headlinePart2   => "Tickets on sale now",
        description     => "Best space cruise ever.",
        finalUrls       => [ "http://www.example.com/" ],
        finalMobileUrls => [ "http://www.example.com/mobile" ]
    });

    # Creates ad group ad operation and add it to the list.
    my $operation =
        Google::Ads::AdWords::v201806::AdOperation->new({
            operator => "SET",
            operand  => $expanded_text_ad
        });
    push @operations, $operation;

    # Updates the ad on the server.
    my $result =
        $client->AdService()->mutate({ operations => \@operations });
    my $updated_ad = $result->get_value()->[0];

    # Prints out some information.
    printf("Expanded text ad with ID %d was updated.\n",
        $updated_ad->get_id());
    printf("Headline part 1 is '%s'.\nHeadline part 2 is '%s'." .
        "'\nDescription is '%s'.\n",
        $updated_ad->get_headlinePart1(),
        $updated_ad->get_headlinePart2(),
        $updated_ad->get_description()
    );
    printf(
        "Final URL is '%s'.\nFinal mobile URL is '%s'.\n",
        $updated_ad->get_finalUrls()->[0],
        $updated_ad->get_finalMobileUrls()->[0]
    );

    return 1;
}

# Don't run the example if the file is being included.
if (abs_path($0) ne abs_path(__FILE__)) {
    return 1;
}

# Log SOAP XML request, response and API errors.
Google::Ads::AdWords::Logging::enable_all_logging();

# Get AdWords Client, credentials will be read from ~/adwords.properties.
my $client = Google::Ads::AdWords::Client->new({ version => "v201806" });

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
update_expanded_text_ad($client, $ad_id);
