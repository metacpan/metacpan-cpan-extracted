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
# This example gets keyword traffic estimates.

use strict;

use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201609::AdGroupEstimateRequest;
use Google::Ads::AdWords::v201609::CampaignEstimateRequest;
use Google::Ads::AdWords::v201609::Keyword;
use Google::Ads::AdWords::v201609::KeywordEstimateRequest;
use Google::Ads::AdWords::v201609::Language;
use Google::Ads::AdWords::v201609::Location;
use Google::Ads::AdWords::v201609::TrafficEstimatorSelector;

use Cwd qw(abs_path);

# Example main subroutine.
sub estimate_keyword_traffic {
  my $client = shift;

  # Create keywords. Refer to the TrafficEstimatorService documentation for
  # the maximum number of keywords that can be passed in a single request.
  # https://developers.google.com/adwords/api/docs/reference/latest/TrafficEstimatorService
  my @keywords = (
    Google::Ads::AdWords::v201609::Keyword->new({
        text      => "mars cruise",
        matchType => "BROAD"
      }
    ),
    Google::Ads::AdWords::v201609::Keyword->new({
        text      => "cheap cruise",
        matchType => "PHRASE"
      }
    ),
    Google::Ads::AdWords::v201609::Keyword->new({
        text      => "cruise",
        matchType => "EXACT"
      }));

  my @negative_keywords = (
    Google::Ads::AdWords::v201609::Keyword->new({
        text      => "moon walk",
        matchType => "BROAD"
      }));

  # Create a keyword estimate request for each keyword.
  my @keyword_estimate_requests;
  foreach my $keyword (@keywords) {
    push @keyword_estimate_requests,
      Google::Ads::AdWords::v201609::KeywordEstimateRequest->new(
      {keyword => $keyword,});
  }
  foreach my $keyword (@negative_keywords) {
    push @keyword_estimate_requests,
      Google::Ads::AdWords::v201609::KeywordEstimateRequest->new({
        keyword    => $keyword,
        isNegative => 1
      });
  }

  # Create ad group estimate requests.
  my $ad_group_estimate_request =
    Google::Ads::AdWords::v201609::AdGroupEstimateRequest->new({
      keywordEstimateRequests => \@keyword_estimate_requests,
      maxCpc =>
        Google::Ads::AdWords::v201609::Money->new({microAmount => 1000000})});

  my $location = Google::Ads::AdWords::v201609::Location->new({
      id => "2840"    # US - see http://goo.gl/rlrFr
  });
  my $language = Google::Ads::AdWords::v201609::Language->new({
      id => "1000"    # en - see http://goo.gl/LvMmS
  });

  # Create campaign estimate requests.
  my $campaign_estimate_request =
    Google::Ads::AdWords::v201609::CampaignEstimateRequest->new({
      adGroupEstimateRequests => [$ad_group_estimate_request],
      criteria                => [$location, $language]});

  # Optional: Request a list of campaign level estimates segmented by platform.
  my $platform_estimate_request = "1";

  # Create selector.
  my $selector = Google::Ads::AdWords::v201609::TrafficEstimatorSelector->new({
      campaignEstimateRequests  => [$campaign_estimate_request],
      platformEstimateRequested => [$platform_estimate_request]});

  # Get traffic estimates.
  my $result = $client->TrafficEstimatorService()->get({selector => $selector});

  # Display traffic estimates.
  if ($result) {
    my $campaign_estimates = $result->get_campaignEstimates();
    if ($campaign_estimates) {
      # Display the campaign level estimates segmented by platform.
      foreach my $campaign_estimate (@{$campaign_estimates}) {
        if ($campaign_estimate->get_platformEstimates()) {
          foreach
            my $platform_estimate (@{$campaign_estimate->get_platformEstimates()})
          {
            my $platform_message = sprintf(
              "Results for the platform with ID: %d and name : %s",
              $platform_estimate->get_platform()->get_id(),
              $platform_estimate->get_platform()->get_platformName());
            display_mean_estimates(
              $platform_message,
              $platform_estimate->get_minEstimate(),
              $platform_estimate->get_maxEstimate());
          }
        }

        if ($campaign_estimate->get_adGroupEstimates()) {
          my $keyword_estimates =
            $campaign_estimate->get_adGroupEstimates()->[0]
            ->get_keywordEstimates();
          for (my $i = 0 ; $i < scalar(@{$keyword_estimates}) ; $i++) {
            # Negative keywords don't generate estimates but instead affect
            # estimates of your other keywords, the following condition just
            # skips printing out estimates for a negative keyword.
            if ($keyword_estimate_requests[$i]->get_isNegative()) {
              next;
            }

            my $keyword = $keyword_estimate_requests[$i]->get_keyword();
            my $keyword_estimate = $keyword_estimates->[$i];
            my $keyword_message =
              sprintf
              "Results for the keyword with text '%s' and match type '%s':\n",
              $keyword->get_text(), $keyword->get_matchType();
            display_mean_estimates(
              $keyword_message,
              $keyword_estimate->get_min(),
              $keyword_estimate->get_max());
          }
        }
      }
    }
  } else {
    print "No traffic estimates were returned.\n";
  }
  return 1;
}

# Display the mean estimates.
sub display_mean_estimates {
  my ($message, $min_estimate, $max_estimate) = @_;

  # Find the mean of the min and max values.
  my $mean_average_cpc = calculate_money_mean($min_estimate->get_averageCpc(),
    $max_estimate->get_averageCpc());
  my $mean_average_position = calculate_mean(
    $min_estimate->get_averagePosition(),
    $max_estimate->get_averagePosition());
  my $mean_clicks = calculate_mean($min_estimate->get_clicksPerDay(),
    $max_estimate->get_clicksPerDay());
  my $mean_total_cost = calculate_money_mean($min_estimate->get_totalCost(),
    $max_estimate->get_totalCost());

  printf "%s:\n",                            $message;
  printf "  Estimated average CPC: %.2f\n",  $mean_average_cpc;
  printf "  Estimated ad position: %.2f\n",  $mean_average_position;
  printf "  Estimated daily clicks: %.2f\n", $mean_clicks;
  printf "  Estimated daily cost: %.2f\n\n", $mean_total_cost;
}

# Calculates the mean microAmount of two Money objects if neither is
# null, else returns NaN.
sub calculate_money_mean {
  my ($min_money, $max_money) = @_;

  if ($min_money && $max_money) {
    return calculate_mean($min_money->get_microAmount(),
      $max_money->get_microAmount());
  }
  return 'NaN';
}

# Calculates the mean of two numbers if neither is null, else returns NaN.
sub calculate_mean {
  my ($min, $max) = @_;

  if (defined($min) && defined($max)) {
    return ($min + $max) / 2;
  }
  return 'NaN';
}

# Don't run the example if the file is being included.
if (abs_path($0) ne abs_path(__FILE__)) {
  return 1;
}

# Log SOAP XML request, response and API errors.
Google::Ads::AdWords::Logging::enable_all_logging();

# Get AdWords Client, credentials will be read from ~/adwords.properties.
my $client = Google::Ads::AdWords::Client->new({version => "v201609"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
estimate_keyword_traffic($client);
