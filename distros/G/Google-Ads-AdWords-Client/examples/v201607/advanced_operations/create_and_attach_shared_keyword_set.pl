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
# This example creates a shared list of negative broad match keywords, then
# attaches them to a campaign.

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201607::CampaignSharedSet;
use Google::Ads::AdWords::v201607::CampaignSharedSetOperation;
use Google::Ads::AdWords::v201607::Keyword;
use Google::Ads::AdWords::v201607::SharedCriterion;
use Google::Ads::AdWords::v201607::SharedCriterionOperation;
use Google::Ads::AdWords::v201607::SharedSet;
use Google::Ads::AdWords::v201607::SharedSetOperation;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);

# Replace with valid values of your account.
my $campaign_id = "INSERT_CAMPAIGN_ID_HERE";

# Example main subroutine.
sub create_and_attach_shared_keyword_set {
  my $client      = shift;
  my $campaign_id = shift;

  # Keywords to include in the shared set.
  my @keywords = ('mars cruise', 'mars hotels');

  # Create the shared negative keyword set.
  my $shared_set = Google::Ads::AdWords::v201607::SharedSet->new({
      name => 'Negative keyword list #' . uniqid(),
      type => 'NEGATIVE_KEYWORDS'
  });

  # Add the shared set.
  my $shared_set_result = $client->SharedSetService()->mutate({
      operations => [
        Google::Ads::AdWords::v201607::SharedSetOperation->new({
            operator => 'ADD',
            operand  => $shared_set
          })]});

  $shared_set = $shared_set_result->get_value(0);

  printf "Shared set with ID %d and name '%s' was successfully added.\n",
    $shared_set->get_sharedSetId(),
    $shared_set->get_name();

  # Add negative keywords to the shared set.
  my @shared_criterion_operations = ();
  foreach my $keyword (@keywords) {
    my $keyword_criterion = Google::Ads::AdWords::v201607::Keyword->new({
        text      => $keyword,
        matchType => 'BROAD'
    });

    my $shared_criterion = Google::Ads::AdWords::v201607::SharedCriterion->new({
        criterion   => $keyword_criterion,
        negative    => 1,
        sharedSetId => $shared_set->get_sharedSetId()});

    my $shared_criterion_operation =
      Google::Ads::AdWords::v201607::SharedCriterionOperation->new({
        operator => 'ADD',
        operand  => $shared_criterion
      });

    push @shared_criterion_operations, $shared_criterion_operation;
  }

  my $shared_criterion_result =
    $client->SharedCriterionService()
    ->mutate({operations => \@shared_criterion_operations});

  foreach my $shared_criterion (@{$shared_criterion_result->get_value()}) {
    printf "Added shared criterion ID %d '%s' to shared set with ID %d.\n",
      $shared_criterion->get_criterion()->get_id(),
      $shared_criterion->get_criterion()->get_text(),
      $shared_criterion->get_sharedSetId();
  }

  # Attach the negative keyword shared set to the campaign.
  my $campaign_shared_set =
    Google::Ads::AdWords::v201607::CampaignSharedSet->new({
      campaignId  => $campaign_id,
      sharedSetId => $shared_set->get_sharedSetId()});

  my $campaign_shared_set_result = $client->CampaignSharedSetService->mutate({
      operations => [
        Google::Ads::AdWords::v201607::CampaignSharedSetOperation->new({
            operator => 'ADD',
            operand  => $campaign_shared_set
          })]});

  $campaign_shared_set = $campaign_shared_set_result->get_value(0);

  printf "Shared set ID %d was attached to campaign ID %d.\n",
    $campaign_shared_set->get_sharedSetId(),
    $campaign_shared_set->get_campaignId();

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
create_and_attach_shared_keyword_set($client, $campaign_id);
