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
# This example gets keyword traffic estimates.
#
# Tags: TrafficEstimatorService.get
# Author: David Torres <api.davidtorres@gmail.com>

use strict;

use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201309::AdGroupEstimateRequest;
use Google::Ads::AdWords::v201309::CampaignEstimateRequest;
use Google::Ads::AdWords::v201309::Keyword;
use Google::Ads::AdWords::v201309::KeywordEstimateRequest;
use Google::Ads::AdWords::v201309::Language;
use Google::Ads::AdWords::v201309::Location;
use Google::Ads::AdWords::v201309::TrafficEstimatorSelector;

use Cwd qw(abs_path);

# Example main subroutine.
sub estimate_keyword_traffic {
  my $client = shift;

  # Create keywords. Up to 2000 keywords can be passed in a single request.
  my @keywords = (Google::Ads::AdWords::v201309::Keyword->new({
                    text => "mars cruise",
                    matchType => "BROAD"
                  }),
                  Google::Ads::AdWords::v201309::Keyword->new({
                    text => "cheap cruise",
                    matchType => "PHRASE"
                  }),
                  Google::Ads::AdWords::v201309::Keyword->new({
                    text => "cruise",
                    matchType => "EXACT"
                  }));
  my @negative_keywords = (Google::Ads::AdWords::v201309::Keyword->new({
                    text => "moon walk",
                    matchType => "BROAD"
                  }));

  # Create a keyword estimate request for each keyword.
  my @keyword_estimate_requests;
  foreach my $keyword (@keywords) {
    push @keyword_estimate_requests,
         Google::Ads::AdWords::v201309::KeywordEstimateRequest->new({
           keyword => $keyword,
         });
  }
  foreach my $keyword (@negative_keywords) {
    push @keyword_estimate_requests,
         Google::Ads::AdWords::v201309::KeywordEstimateRequest->new({
           keyword => $keyword,
           isNegative => 1
         });
  }

  # Create ad group estimate requests.
  my $ad_group_estimate_request =
      Google::Ads::AdWords::v201309::AdGroupEstimateRequest->new({
        keywordEstimateRequests => \@keyword_estimate_requests,
        maxCpc => Google::Ads::AdWords::v201309::Money->new({
          microAmount => 1000000
        })
      });

  # Create campaign estimate requests.
  my $campaign_estimate_request =
      Google::Ads::AdWords::v201309::CampaignEstimateRequest->new({
        adGroupEstimateRequests => [$ad_group_estimate_request],
        criteria => [
          Google::Ads::AdWords::v201309::Location->new({
            id => "2840" # US - see http://goo.gl/rlrFr
          }),
          Google::Ads::AdWords::v201309::Language->new({
            id => "1000" # en - see http://goo.gl/LvMmS
          })
        ]
      });

  # Create selector.
  my $selector = Google::Ads::AdWords::v201309::TrafficEstimatorSelector->new({
    campaignEstimateRequests => [$campaign_estimate_request]
  });

  # Get traffic estimates.
  my $result = $client->TrafficEstimatorService()->get({
    selector => $selector
  });

  # Display traffic estimates.
  if ($result) {
    my $keyword_estimates = $result->get_campaignEstimates()->[0]->
        get_adGroupEstimates()->[0]->get_keywordEstimates();
    for(my $i = 0; $i < scalar(@{$keyword_estimates}); $i++) {
      # Negative keyword don't generate estimates but instead affect estimates
      # of your other keywords, the following condition just skips printing out
      # estimates for a negative keyword.
      if ($keyword_estimate_requests[$i]->get_isNegative()) {
        next;
      }

      my $keyword = $keyword_estimate_requests[$i]->get_keyword();
      my $keyword_estimate = $keyword_estimates->[$i];

      # Find the mean of the min and max values.
      my $mean_average_cpc =
          ($keyword_estimate->get_min()->get_averageCpc()->get_microAmount() +
           $keyword_estimate->get_max()->get_averageCpc()->get_microAmount()) /
          2;
      my $mean_average_position =
          ($keyword_estimate->get_min()->get_averagePosition() +
           $keyword_estimate->get_max()->get_averagePosition()) /
          2;
      my $mean_clicks =
          ($keyword_estimate->get_min()->get_clicksPerDay() +
           $keyword_estimate->get_max()->get_clicksPerDay()) / 2;
      my $mean_total_cost =
          ($keyword_estimate->get_min()->get_totalCost()->get_microAmount() +
           $keyword_estimate->get_max()->get_totalCost()->get_microAmount()) /
          2;

      printf "Results for the keyword with text '%s' and match type '%s':\n",
             $keyword->get_text(), $keyword->get_matchType();
      printf "  Estimated average CPC: %d\n", $mean_average_cpc;
      printf "  Estimated ad position: %.2f\n", $mean_average_position;
      printf "  Estimated daily clicks: %d\n", $mean_clicks;
      printf "  Estimated daily cost: %d\n\n", $mean_total_cost;
    }
  } else {
    print "No traffic estimates were returned.\n";
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
estimate_keyword_traffic($client);
