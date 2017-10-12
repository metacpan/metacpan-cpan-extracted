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
# This example gets keywords related to a list of seed keywords.

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201710::Language;
use Google::Ads::AdWords::v201710::LanguageSearchParameter;
use Google::Ads::AdWords::v201710::NetworkSearchParameter;
use Google::Ads::AdWords::v201710::NetworkSetting;
use Google::Ads::AdWords::v201710::Paging;
use Google::Ads::AdWords::v201710::RelatedToQuerySearchParameter;
use Google::Ads::AdWords::v201710::SeedAdGroupIdSearchParameter;
use Google::Ads::AdWords::v201710::TargetingIdeaSelector;
use Google::Ads::Common::MapUtils;

use Cwd qw(abs_path);

# Replace with valid values of your account.
# If you do not want to use an existing ad group to seed your request, you can
# set this to undef.
my $ad_group_id = "INSERT_AD_GROUP_ID_HERE";

# Example main subroutine.
sub get_keyword_ideas {
  my ($client, $ad_group_id) = @_;

  # Create selector.
  my $selector = Google::Ads::AdWords::v201710::TargetingIdeaSelector->new({
    requestType => "IDEAS",
    ideaType    => "KEYWORD"
  });
  $selector->set_requestedAttributeTypes([
    "KEYWORD_TEXT", "SEARCH_VOLUME",
    "AVERAGE_CPC",  "COMPETITION",
    "CATEGORY_PRODUCTS_AND_SERVICES"
  ]);

  # Create related to query search parameter.
  my @search_parameters = ();
  my $related_to_query_search_parameter =
    Google::Ads::AdWords::v201710::RelatedToQuerySearchParameter->new(
    {queries => ["bakery", "pastries", "birthday cake"]});
  push @search_parameters, $related_to_query_search_parameter;

  # Set selector paging (required for targeting idea service).
  my $paging = Google::Ads::AdWords::v201710::Paging->new({
    startIndex    => 0,
    numberResults => 10
  });
  $selector->set_paging($paging);

  # Language setting (not-required).
  # The ID can be found in the documentation:
  #   https://developers.google.com/adwords/api/docs/appendix/languagecodes
  my $language_english =
    Google::Ads::AdWords::v201710::Language->new({id => 1000});
  my $language_search_parameter =
    Google::Ads::AdWords::v201710::LanguageSearchParameter->new(
    {languages => [$language_english]});
  push @search_parameters, $language_search_parameter;

  # Create network search paramter (optional).
  my $network_setting = Google::Ads::AdWords::v201710::NetworkSetting->new({
    targetGoogleSearch         => 1,
    targetSearchNetwork        => 0,
    targetContentNetwork       => 0,
    targetPartnerSearchNetwork => 0
  });
  my $network_setting_parameter =
    Google::Ads::AdWords::v201710::NetworkSearchParameter->new(
    {networkSetting => $network_setting});
  push @search_parameters, $network_setting_parameter;

  # Optional: Use an existing ad group to generate ideas.
  if ($ad_group_id) {
    my $seed_ad_group_id_search_parameter =
      Google::Ads::AdWords::v201710::SeedAdGroupIdSearchParameter->new({
        adGroupId => $ad_group_id
      });
    push @search_parameters, $seed_ad_group_id_search_parameter;
  }

  $selector->set_searchParameters(\@search_parameters);

  # Get keyword ideas.
  my $page = $client->TargetingIdeaService()->get({selector => $selector});

  # Display keyword ideas.
  if ($page->get_entries()) {
    foreach my $targeting_idea (@{$page->get_entries()}) {
      my $data =
        Google::Ads::Common::MapUtils::get_map($targeting_idea->get_data());
      my $keyword = $data->{"KEYWORD_TEXT"}->get_value();
      my $search_volume =
          $data->{"SEARCH_VOLUME"}->get_value()
        ? $data->{"SEARCH_VOLUME"}->get_value()
        : 0;
      my $categories =
          $data->{"CATEGORY_PRODUCTS_AND_SERVICES"}->get_value()
        ? $data->{"CATEGORY_PRODUCTS_AND_SERVICES"}->get_value()
        : [];
      my $average_cpc =
        $data->{"AVERAGE_CPC"}->get_value()->get_microAmount();
      my $competition = $data->{"COMPETITION"}->get_value();
      printf "Keyword with text '%s', monthly search volume %d, average CPC" .
        " %d, and competition %.2f was found with categories: '%s'\n", $keyword,
        $search_volume, $average_cpc, $competition, join(", ", @{$categories});
    }
  } else {
    print "No related keywords were found.\n";
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
my $client = Google::Ads::AdWords::Client->new({version => "v201710"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
get_keyword_ideas($client, $ad_group_id);
