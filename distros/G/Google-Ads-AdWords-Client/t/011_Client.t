#!/usr/bin/perl
#
# Copyright 2011, Google Inc. All Rights Reserved.
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
# Unit (not functional) tests for the Google::Ads::AdWords::Client module.
# Functional tests of the various AdWords API services will be performed in a
# separate test.

use strict;

use File::Basename;
use File::Spec;
use Test::Exception;
use Test::More (tests => 29);

# Set up @INC at runtime with an absolute path.
my $lib_path = File::Spec->catdir(dirname($0), "..", "lib");
push(@INC, $lib_path);

# Testing is ok to use the Client class
use_ok("Google::Ads::AdWords::Client")
  or die "Cannot load 'Google::Ads::AdWords::Client'";

# Test client initialization, including reading from properties files.
my $properties_file =
  File::Spec->catdir(dirname($0), qw(testdata client.test.input));
my $client_id = "client_id_override";
my $client    = Google::Ads::AdWords::Client->new({
    client_id       => $client_id,
    properties_file => $properties_file,
});
is($client->get_client_id(),       $client_id);
is($client->get_user_agent(),      "perl-unit-tests");
is($client->get_developer_token(), "dev-token", "Read of developer token");
is($client->get_oauth_2_handler()->get_refresh_token(),
  "refresh-token", "Read of refresh token");
is($client->get_alternate_url(),
  "https://adwords.google.com", "Read of alternate url");

# Test basic get/set methods.
$client->set_die_on_faults(1);
is($client->get_die_on_faults(), 1, "get/set die_on_faults()");

# Make sure this supports all the services we think it should for each version.
$client->set_version("v201702");
my @services = qw(AccountLabelService
  AdCustomizerFeedService
  AdGroupAdService
  AdGroupBidModifierService
  AdGroupCriterionService
  AdGroupExtensionSettingService
  AdGroupFeedService
  AdGroupService
  AdParamService
  AdwordsUserListService
  BatchJobService
  BiddingStrategyService
  BudgetOrderService
  BudgetService
  CampaignCriterionService
  CampaignExtensionSettingService
  CampaignFeedService
  CampaignService
  CampaignSharedSetService
  ConstantDataService
  ConversionTrackerService
  CustomerExtensionSettingService
  CustomerFeedService
  CustomerService
  CustomerSyncService
  DataService
  DataService
  DraftAsyncErrorService
  FeedItemService
  FeedMappingService
  FeedService
  LabelService
  LocationCriterionService
  ManagedCustomerService
  MediaService
  OfflineCallConversionFeedService
  OfflineConversionFeedService
  ReportDefinitionService
  SharedCriterionService
  SharedSetService
  TargetingIdeaService
  TrafficEstimatorService
  TrialAsyncErrorService
  TrialService);
can_ok($client, @services);

ok(Google::Ads::AdWords::Client->new && Google::Ads::AdWords::Client->new,
  "Can construct more than one client object.");

# Test set auth properties.
my $test_oauth2_refresh_token = "my_oauth2_refresh_token";
$client->get_oauth_2_handler()->set_refresh_token($test_oauth2_refresh_token);
is($client->get_oauth_2_handler()->get_refresh_token(),
  $test_oauth2_refresh_token);

my $test_oauth2_client_secret = "my_client_secret";
$client->get_oauth_2_handler()->set_client_secret($test_oauth2_client_secret);
is($client->get_oauth_2_handler()->get_client_secret(),
  $test_oauth2_client_secret);

my $test_oauth2_client_id = "my_oauth2_client_id";
$client->get_oauth_2_handler()->set_client_id($test_oauth2_client_id);
is($client->get_oauth_2_handler()->get_client_id(), $test_oauth2_client_id);

$properties_file =
  File::Spec->catdir(dirname($0),
  qw(testdata client.withreportconfig.test.input));

# Test non-ASCII and ASCII user agent.
$client->set_user_agent("你好");
dies_ok {
  $client->_get_header()
}
"expected to die";

$client->set_user_agent("hello");
ok($client->_get_header());

# Test that a ReportingConfiguration passed to the constructor takes
# precedence over the reporting settings in the properties file.
use_ok("Google::Ads::AdWords::Reports::ReportingConfiguration")
  or die "Cannot load 'Google::Ads::AdWords::Reports::ReportingConfiguration'";
my $reporting_config_override =
  Google::Ads::AdWords::Reports::ReportingConfiguration->new({
    skip_header              => 0,
    skip_column_header       => 0,
    skip_summary             => 0,
    include_zero_impressions => 0,
    use_raw_enum_values      => 0
  });
ok($reporting_config_override, "create reporting config");

$client = Google::Ads::AdWords::Client->new({
    reporting_config => $reporting_config_override,
    properties_file  => $properties_file,
});
ok($client, "create client with reporting config override");

is($client->get_reporting_config(),
  $reporting_config_override, "override report config attribute");
is($client->get_reporting_config()->get_skip_header(),
  0, "override report config skip header");
is($client->get_reporting_config()->get_skip_column_header(),
  0, "override report config skip column header");
is($client->get_reporting_config()->get_skip_summary(),
  0, "override report config skip summary");
is($client->get_reporting_config()->get_include_zero_impressions(),
  0, "override report config include zero impressions");
is($client->get_reporting_config()->get_use_raw_enum_values(),
  0, "override report config use raw enum values");

# Test that if no ReportingConfiguration is passed to the constructor then
# reporting settings are taken from the properties file.
$client =
  Google::Ads::AdWords::Client->new({properties_file => $properties_file});
ok($client, "create client without reporting config override");

is($client->get_reporting_config()->get_skip_header(),
  1, "report config skip header");
is($client->get_reporting_config()->get_skip_column_header(),
  1, "report config skip column header");
is($client->get_reporting_config()->get_skip_summary(),
  1, "report config skip summary");
is($client->get_reporting_config()->get_include_zero_impressions(),
  1, "report config include zero impressions");
is($client->get_reporting_config()->get_use_raw_enum_values(),
  1, "report config use raw enum values");
