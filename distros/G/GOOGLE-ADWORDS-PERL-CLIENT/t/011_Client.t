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
#
# Author: David Torres <api.davidtorres@gmail.com>

use strict;

use File::Basename;
use File::Spec;
use Test::More (tests => 23);

# Set up @INC at runtime with an absolute path.
my $lib_path = File::Spec->catdir(dirname($0), "..", "lib");
push(@INC, $lib_path);

# Testing is ok to use the Client class
use_ok("Google::Ads::AdWords::Client")
    or die "Cannot load 'Google::Ads::AdWords::Client'";

# Test client initialization, including reading from properties files.
my $properties_file =
    File::Spec->catdir(dirname($0), qw(testdata client.test.input));
my $password = "password_overide";
my $client = Google::Ads::AdWords::Client->new({
  password => $password,
  properties_file => $properties_file,
});
is($client->get_email(), "user\@domain.com", "Basic properties file reading");
is($client->get_password(), $password, "Local param overrides properties file");
is($client->get_client_id(), "client_1+user\@domain.com", "Read of client id");
is($client->get_user_agent(), "perl-unit-tests");
is($client->get_developer_token(), "dev-token",
   "Read of developer token");
is($client->get_auth_token(), "auth-token",
   "Read of auth token");
is($client->get_alternate_url(), "https://adwords.google.com",
   "Read of alternate url");

# Test basic get/set methods.
$client->set_die_on_faults(1);
is($client->get_die_on_faults(), 1, "get/set die_on_faults()");

# Make sure this supports all the services we think it should for each version.
$client->set_version("v201309");
my @services = qw(AdGroupAdService
               AdGroupBidModifierService
               AdGroupCriterionService
               AdGroupFeedService
               AdGroupService
               AdParamService
               AdwordsUserListService
               AlertService
               BiddingStrategyService
               BudgetOrderService
               BudgetService
               CampaignAdExtensionService
               CampaignCriterionService
               CampaignFeedService
               CampaignService
               CampaignSharedSetService
               ConstantDataService
               ConversionTrackerService
               CustomerService
               CustomerSyncService
               DataService
               ExperimentService
               FeedItemService
               FeedMappingService
               FeedService
               GeoLocationService
               LocationCriterionService
               ManagedCustomerService
               MediaService
               MutateJobService
               OfflineConversionFeedService
               ReportDefinitionService
               SharedCriterionService
               SharedSetService
               TargetingIdeaService
               TrafficEstimatorService);
can_ok($client, @services);

ok(Google::Ads::AdWords::Client->new && Google::Ads::AdWords::Client->new,
   "Can construct more than one client object.");

# Make sure auth initialization through Client constructor gets propagated to
# the appropiate auth handlers.
my $test_email = "my_email\@test.com";
my $test_password = "my_password";
my $test_auth_token = "my_auth_token";
my $test_auth_server = "my_auth_server";
$client = Google::Ads::AdWords::Client->new({
  email => $test_email,
  password => $test_password,
  auth_token => $test_auth_token,
  auth_server => $test_auth_server
});
is($client->get_auth_token_handler()->get_email(), $test_email);
is($client->get_auth_token_handler()->get_password(), $test_password);
is($client->get_auth_token_handler()->get_auth_token(), $test_auth_token);
is($client->get_auth_token_handler()->get_auth_server(), $test_auth_server);

# Test set auth properties.
$client->set_email("john-doe\@google.com");
is($client->get_email(), "john-doe\@google.com");
is($client->get_auth_token_handler()->get_email(), "john-doe\@google.com");

$client->set_password("password");
is($client->get_password(), "password");
is($client->get_auth_token_handler()->get_password(), "password");

$client->set_auth_server("auth-server");
is($client->get_auth_server(), "auth-server");
is($client->get_auth_token_handler()->get_auth_server(), "auth-server");

$client->set_auth_token("token");
is($client->get_auth_token(), "token");
is($client->get_auth_token_handler()->get_auth_token(), "token");
