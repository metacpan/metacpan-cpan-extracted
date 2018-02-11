#!/usr/bin/perl
#
# Copyright 2018, Google Inc. All Rights Reserved.
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
# Unit tests for the Google::Ads::Common::Utilities::ReportQueryBuilder module.

use strict;
use lib qw(lib t t/util);

use File::Temp qw(tempfile);
use HTTP::Response;
use Test::Exception;
use Test::MockObject::Extends;
use Test::More (tests => 13);
use TestAPIUtils qw(get_api_package);
use TestClientUtils qw(get_test_client);

use_ok("Google::Ads::AdWords::Utilities::ReportQueryBuilder");

my $client          = get_test_client();
my $current_version = $client->get_version();

# Instantiate the report query builder.
my $query_builder =
  Google::Ads::AdWords::Utilities::ReportQueryBuilder->new({client => $client})
  ->select(['CampaignId', 'Impressions'])->from('CRITERIA_PERFORMANCE_REPORT');
is($query_builder->build(),
  'SELECT CampaignId, Impressions FROM CRITERIA_PERFORMANCE_REPORT');

$query_builder =
  Google::Ads::AdWords::Utilities::ReportQueryBuilder->new({client => $client})
  ->select(['CampaignId', 'Impressions'])->from('CRITERIA_PERFORMANCE_REPORT')
  ->where('Status')->in(['ENABLED', 'PAUSED']);
is($query_builder->build(),
  'SELECT CampaignId, Impressions FROM ' .
    'CRITERIA_PERFORMANCE_REPORT WHERE Status IN ["ENABLED","PAUSED"]');

$query_builder =
  Google::Ads::AdWords::Utilities::ReportQueryBuilder->new({client => $client})
  ->select(['CampaignId', 'Impressions'])->from('CRITERIA_PERFORMANCE_REPORT')
  ->where('Status')->in(['ENABLED', 'PAUSED'])->where('Impressions')
  ->greater_than(0);
is($query_builder->build(),
  'SELECT CampaignId, Impressions FROM CRITERIA_PERFORMANCE_REPORT ' .
    'WHERE Status IN ["ENABLED","PAUSED"] AND Impressions > 0');

$query_builder =
  Google::Ads::AdWords::Utilities::ReportQueryBuilder->new({client => $client})
  ->select(['CampaignId', 'Impressions'])->from('CRITERIA_PERFORMANCE_REPORT')
  ->where('Status')->in(['ENABLED', 'PAUSED'])->where('Impressions')
  ->greater_than(0)->during('20170201', '20170203');
is($query_builder->build(),
  'SELECT CampaignId, Impressions FROM CRITERIA_PERFORMANCE_REPORT WHERE ' .
    'Status IN ["ENABLED","PAUSED"] AND Impressions > 0 ' .
    'DURING 20170201,20170203');

$query_builder =
  Google::Ads::AdWords::Utilities::ReportQueryBuilder->new({client => $client})
  ->select(['CampaignId', 'Impressions'])->from('CRITERIA_PERFORMANCE_REPORT')
  ->where('Status')->in(['ENABLED', 'PAUSED'])->where('Impressions')
  ->greater_than(0)->during('YESTERDAY');
is($query_builder->build(),
  'SELECT CampaignId, Impressions FROM CRITERIA_PERFORMANCE_REPORT WHERE ' .
    'Status IN ["ENABLED","PAUSED"] AND Impressions > 0 DURING YESTERDAY');

# Test where builder with a number and IN.
my $query_builder_where_number =
  Google::Ads::AdWords::Utilities::ReportQueryBuilder->new({client => $client})
  ->select(['CampaignId', 'Impressions'])->from('CRITERIA_PERFORMANCE_REPORT')
  ->where('CampaignId')->in([1, 2, 3]);
is($query_builder_where_number->build(),
  'SELECT CampaignId, Impressions FROM CRITERIA_PERFORMANCE_REPORT WHERE ' .
  'CampaignId IN [1,2,3]');

# Test the copy function.
my $query_builder_copy =
  Google::Ads::AdWords::Utilities::ReportQueryBuilder->new(
  {client => $client, query_builder => $query_builder});
is($query_builder_copy->build(),
  'SELECT CampaignId, Impressions FROM CRITERIA_PERFORMANCE_REPORT WHERE ' .
    'Status IN ["ENABLED","PAUSED"] AND Impressions > 0 DURING YESTERDAY');

# Test duplicate fields stay while keeping order.
my $duplicate_select_query_builder =
  Google::Ads::AdWords::Utilities::ReportQueryBuilder->new({client => $client})
  ->select(['Id', 'Impressions', 'Id'])
  ->from('CRITERIA_PERFORMANCE_REPORT');
is($duplicate_select_query_builder->build(),
  'SELECT Id, Impressions, Id FROM CRITERIA_PERFORMANCE_REPORT');

# Test select being called multiple times. The last call should stick.
my $multiple_call_select_query_builder =
  Google::Ads::AdWords::Utilities::ReportQueryBuilder->new({client => $client})
  ->select(['CampaignId', 'Impressions'])
  ->select(['Id'])
  ->from('CRITERIA_PERFORMANCE_REPORT');
is($multiple_call_select_query_builder->build(),
  'SELECT Id FROM CRITERIA_PERFORMANCE_REPORT');

dies_ok {
  $client->set_die_on_faults(1);
  my $bad_date_query_builder =
    Google::Ads::AdWords::Utilities::ReportQueryBuilder
    ->new({client => $client})
    ->select(['CampaignId', 'Impressions', 'CampaignId'])
    ->from('CRITERIA_PERFORMANCE_REPORT')->during('20170202');
  $bad_date_query_builder->build();
}
"expected to die due to invalid args for dates";

dies_ok {
  $client->set_die_on_faults(1);
  my $bad_date_query_builder =
    Google::Ads::AdWords::Utilities::ReportQueryBuilder
    ->new({client => $client})
    ->select(['CampaignId', 'Impressions', 'CampaignId'])
    ->from('CRITERIA_PERFORMANCE_REPORT')->during(undef, '20170202');
  $bad_date_query_builder->build();
}
"expected to die due to invalid args for dates";

dies_ok {
  $client->set_die_on_faults(1);
  my $bad_date_query_builder =
    Google::Ads::AdWords::Utilities::ReportQueryBuilder
    ->new({client => $client})
    ->from('CRITERIA_PERFORMANCE_REPORT');
  $bad_date_query_builder->build();
}
"expected to die due to lack of select";
