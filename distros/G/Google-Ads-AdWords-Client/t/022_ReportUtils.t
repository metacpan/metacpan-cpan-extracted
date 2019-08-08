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
use Test::More (tests => 28);
use TestClientUtils qw(get_test_client_no_auth get_test_client);

# The reporting tests force a lot of warnings. This is a signal handler
# to avoid cluttering the test results with warnings.
local $SIG{__WARN__} = sub { };

use_ok("Google::Ads::Common::ReportUtils");
use_ok("Google::Ads::Common::ReportDownloadHandler");
use_ok("Google::Ads::Common::ReportDownloadError");

# Mock the auth handler
my $auth_handler = Google::Ads::Common::OAuth2ApplicationsHandler->new();
$auth_handler = Test::MockObject::Extends->new($auth_handler);
$auth_handler->mock("get_access_token", sub { return "ACCESS_TOKEN"; });

my $client = get_test_client();
$client = Test::MockObject::Extends->new($client);
$client->mock("_get_auth_handler", sub { return $auth_handler; });

# Test each of the ReportDownloadHandler methods for a failed request.
my $report_handler = Google::Ads::Common::ReportUtils::get_report_handler({
    query => "SELECT CampaignId, Impressions " .
      "FROM CAMPAIGN_PERFORMANCE_REPORT " . "DURING THIS_MONTH",
    format => "CSV"
  },
  $client
);
ok($report_handler, "report handler");
is(300, $report_handler->get___user_agent()->timeout(), "default timeout");

my $report_as_string = $report_handler->get_as_string();
ok(!$report_as_string, "report as string");
ok($report_as_string->isa("Google::Ads::Common::ReportDownloadError"),
  "check report handler->report_as_string return type");
ok($report_as_string =~ /ReportDownloadError\s\{[^}]+\}/,
  "check ReportDownloadError STRINGIFY");

my ($fh, $filename) = tempfile();
my $report_save = $report_handler->save($filename);
ok(!$report_save, "report save");
ok($report_save->isa("Google::Ads::Common::ReportDownloadError"),
  "check report handler->save return type");

my $is_callback_invoked     = 0;
my $report_process_contents = $report_handler->process_contents(
  sub {
    $is_callback_invoked = 1;
  });
ok(!$report_process_contents, "report process contents");
ok($report_process_contents->isa("Google::Ads::Common::ReportDownloadError"),
  "check report handler->process_contents return type");
is($is_callback_invoked, 0, "callback should not be invoked on error");

# Make sure the timeout and server are properly set if specified.
my $timeout = 5;
my $server  = "http://www.example.com";
$report_handler = Google::Ads::Common::ReportUtils::get_report_handler({
    query => "SELECT CampaignId, Impressions " .
      "FROM CAMPAIGN_PERFORMANCE_REPORT " . "DURING THIS_MONTH",
    format => "CSV"
  },
  $client, $server, $timeout
);
ok($report_handler, "report handler");
is($timeout, $report_handler->get___user_agent()->timeout(),
  "timeout override");
is(
  $server . '/api/adwords/reportdownload/' . $client->get_version(),
  $report_handler->get___http_request()->uri(),
  "server override"
);

# Test each of the ReportDownloadHandler methods for a successful request.

# Create a mock LWP::UserAgent that will return status 200 (success) and
# a predefined content string.
my $expected_contents = "Row 1\nRow 2\n";
my $user_agent_mock   = Test::MockObject->new();
$user_agent_mock->mock(
  request => sub {
    my ($self, $http_request, $content_cb) = @_;
    my $response = HTTP::Response->new(200, "");
    if ($content_cb) {
      # If given a callback then invoke it, passing the predefined content string
      # and HTTPResponse. Split up the content by line so the test confirms
      # multiple callback invocations occurred.
      foreach my $content_line (split /\n/, $expected_contents) {
        $content_cb->($content_line . "\n", $response);
      }
    } else {
      # Otherwise, simply set the content on the HTTPResponse.
      $response->content($expected_contents);
    }
    return $response;
  });
$user_agent_mock->mock(default_header => sub { return ""; });
$user_agent_mock->mock(agent => sub { return "MOCK_AGENT"; });
$report_handler->set___user_agent($user_agent_mock);

# handler->get_as_string test
$report_as_string = $report_handler->get_as_string();
ok($report_as_string);
is($report_as_string, $expected_contents, "successful report as string");
ok(
  !$report_as_string->isa("Google::Ads::Common::ReportDownloadError"),
  "check successful report handler->get_as_string return type"
);

# handler->save test
($fh, $filename) = tempfile();
$report_save = $report_handler->save($filename);
ok($report_save, "successful report save");
ok($report_save->isa("HTTP::Response"),
  "check successful report handler->save return type");

# handler->process_contents test
my $callback_contents;
$report_process_contents = $report_handler->process_contents(
  sub {
    my ($data, $http_response) = @_;
    ok($data,          "callback data");
    ok($http_response, "callback response");
    $callback_contents = $callback_contents . $data;
  });
ok($report_process_contents, "successful report process_contents");
ok($report_process_contents->isa("HTTP::Response"),
  "check successful report handler->process_contents return type");
is($callback_contents, $expected_contents, "response contents from callback");
