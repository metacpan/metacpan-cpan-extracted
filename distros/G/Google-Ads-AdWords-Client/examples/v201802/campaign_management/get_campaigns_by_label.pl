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
# This example gets all campaigns with a specific label. To add a label to
# campaigns, run add_campaign_labels.pl.

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201802::OrderBy;
use Google::Ads::AdWords::v201802::Paging;
use Google::Ads::AdWords::v201802::Predicate;
use Google::Ads::AdWords::v201802::Selector;
use Google::Ads::AdWords::Utilities::PageProcessor;

use constant PAGE_SIZE => 500;

use Cwd qw(abs_path);

# Replace with valid values of your account.
my $label_id = "INSERT_LABEL_ID_HERE";

# Example main subroutine.
sub get_campaigns_by_label {
  my $client   = shift;
  my $label_id = shift;

  # Create predicate.
  # Labels filtering is performed by ID. You can use CONTAINS_ANY to select
  # campaigns with any of the label IDs, CONTAINS_ALL to select campaigns with
  # all of the label IDs, or CONTAINS_NONE to select campaigns with none of the
  # label IDs.
  my $labels_predicate = Google::Ads::AdWords::v201802::Predicate->new({
      field    => "Labels",
      operator => "CONTAINS_ANY",
      values   => [$label_id]});
  # Create selector.
  my $paging = Google::Ads::AdWords::v201802::Paging->new({
      startIndex    => 0,
      numberResults => PAGE_SIZE
  });
  my $selector = Google::Ads::AdWords::v201802::Selector->new({
      fields     => ["Id", "Name", "Labels"],
      predicates => [$labels_predicate],
      ordering   => [
        Google::Ads::AdWords::v201802::OrderBy->new({
            field     => "Name",
            sortOrder => "ASCENDING"
          })
      ],
      paging => $paging
    });

  # Paginate through results.
  # The contents of the subroutine will be executed for each campaign.
  Google::Ads::AdWords::Utilities::PageProcessor->new({
      client   => $client,
      service  => $client->CampaignService(),
      selector => $selector
    }
    )->process_entries(
    sub {
      my ($campaign) = @_;
      my @label_strings =
        map { $_->get_id() . '/' . $_->get_name() } @{$campaign->get_labels()};
      printf "Campaign found with name \"%s\" and ID %d and labels: %s.\n",
        $campaign->get_name(), $campaign->get_id(),
        join(', ', @label_strings);
    });

  return 1;
}

# Don't run the example if the file is being included.
if (abs_path($0) ne abs_path(__FILE__)) {
  return 1;
}

# Log SOAP XML request, response and API errors.
Google::Ads::AdWords::Logging::enable_all_logging();

# Get AdWords Client, credentials will be read from ~/adwords.properties.
my $client = Google::Ads::AdWords::Client->new({version => "v201802"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
get_campaigns_by_label($client, $label_id);
