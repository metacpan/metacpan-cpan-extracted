#!/usr/bin/perl
#
# Copyright 2014, Google Inc. All Rights Reserved.
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
# Unit tests for the Google::Ads::AdWords::Reports::ReportingConfiguration
# module.

use strict;
use lib qw(lib t t/util);

use File::Temp qw(tempfile);
use Test::MockObject::Extends;
use Test::More (tests => 23);
use TestClientUtils qw(get_test_client_no_auth get_test_client);

# The reporting tests force a lot of warnings. This is a signal handler
# to avoid cluttering the test results with warnings.
local $SIG{__WARN__} = sub { };

use_ok("Google::Ads::AdWords::Reports::ReportingConfiguration");

my $client = get_test_client_no_auth();
ok($client->get_reporting_config(), "reporting configuration present");

is($client->get_reporting_config()->get_skip_header(),
  undef, "skip_header should be undef");
is($client->get_reporting_config()->get_skip_column_header(),
  undef, "skip_column_header should be undef");
is($client->get_reporting_config()->get_skip_summary(),
  undef, "skip_summary should be undef");
is($client->get_reporting_config()->get_include_zero_impressions(),
  undef, "include_zero_impressions should be undef");
is($client->get_reporting_config()->get_use_raw_enum_values(),
  undef, "use_raw_enum_values should be undef");

# Construct a new reporting config.
my $reporting_config =
  Google::Ads::AdWords::Reports::ReportingConfiguration->new({
    skip_header              => 1,
    skip_column_header       => 0,
    skip_summary             => 0,
    include_zero_impressions => 0,
    use_raw_enum_values      => 0
  });

$client->set_reporting_config($reporting_config);

is($client->get_reporting_config()->get_skip_header(),
  1, "skip_header should be set by constructor");
is($client->get_reporting_config()->get_skip_column_header(),
  0, "skip_column_header should be set by constructor");
is($client->get_reporting_config()->get_skip_summary(),
  0, "skip_summary should be set by constructor");
is($client->get_reporting_config()->get_include_zero_impressions(),
  0, "include_zero_impressions should be set by constructor");
is($client->get_reporting_config()->get_use_raw_enum_values(),
  0, "use_raw_enum_values should be set by constructor");

# Mutate the reporting config
$client->get_reporting_config->set_skip_header(0);
is($client->get_reporting_config()->get_skip_header(),
  0, "skip_header should be set to false");

$client->get_reporting_config->set_skip_column_header(1);
is($client->get_reporting_config()->get_skip_column_header(),
  1, "skip_column_header should be set to true");

$client->get_reporting_config->set_skip_summary(1);
is($client->get_reporting_config()->get_skip_summary(),
  1, "skip_summary should be set to true");

$client->get_reporting_config->set_include_zero_impressions(1);
is($client->get_reporting_config()->get_include_zero_impressions(),
  1, "include_zero_impressions should be set to true");

$client->get_reporting_config->set_use_raw_enum_values(1);
is($client->get_reporting_config()->get_use_raw_enum_values(),
  1, "use_raw_enum_values should be set to true");

ok($client->get_reporting_config()->as_string(), "as_string");

# Clear the reporting config and confirm that ReportUtils
# does not fail. Added to test the fix for issue #7:
# https://github.com/googleads/googleads-perl-lib/issues/7
$client = get_test_client();
$client->set_reporting_config(undef);

# Mock the auth handler
my $auth_handler = Google::Ads::Common::OAuth2ApplicationsHandler->new();
$auth_handler = Test::MockObject::Extends->new($auth_handler);
$auth_handler->mock("get_access_token", sub { return "ACCESS_TOKEN"; });

$client = Test::MockObject::Extends->new($client);
$client->mock("_get_auth_handler", sub { return $auth_handler; });

use_ok("Google::Ads::Common::ReportUtils");
use_ok("Google::Ads::Common::ReportDownloadError");

# The download will not actually download anything due to the missing
# report definition and test credentials, but the call should at least
# complete without a runtime error.
my $report_handler = Google::Ads::Common::ReportUtils::get_report_handler({
    query => "SELECT CampaignId, Impressions " .
      "FROM CAMPAIGN_PERFORMANCE_REPORT " . "DURING THIS_MONTH",
    format => "CSV"
  },
  $client
);
ok($report_handler, "report handler");
my $report_result = $report_handler->get_as_string();
ok(!$report_result, "report error should evaluate to false in boolean context");
# A ReportDownloadError indicates that the request was sent.
ok($report_result->isa("Google::Ads::Common::ReportDownloadError"),
  "check report result return type");
