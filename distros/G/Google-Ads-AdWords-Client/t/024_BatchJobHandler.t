#!/usr/bin/perl
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
# Unit tests for the Google::Ads::Common::Utilities::BatchJobHandler
# module.

use strict;
use lib qw(lib t t/util);

use File::Temp qw(tempfile);
use HTTP::Response;
use Test::Exception;
use Test::MockObject::Extends;
use Test::More (tests => 14);
use TestAPIUtils qw(get_api_package);
use TestClientUtils qw(get_test_client_no_auth get_test_client);
use TestUtils qw(read_test_properties replace_properties);

use_ok("Google::Ads::AdWords::Utilities::BatchJobHandler");
use_ok("Google::Ads::AdWords::Utilities::BatchJobHandlerError");
use_ok("Google::Ads::AdWords::Utilities::BatchJobHandlerStatus");

# Mock the auth handler
my $auth_handler = Google::Ads::Common::OAuth2ApplicationsHandler->new();
$auth_handler = Test::MockObject::Extends->new($auth_handler);
$auth_handler->mock("get_access_token", sub { return "ACCESS_TOKEN"; });

my $client          = get_test_client();
my $current_version = $client->get_version();

# Mock the client.
$client = Test::MockObject::Extends->new($client);
$client->mock("_get_auth_handler", sub { return $auth_handler; });

# Instantiate the batch job handler.
my $batch_job_handler =
  Google::Ads::AdWords::Utilities::BatchJobHandler->new({client => $client});
my $batch_job_status =
  Google::Ads::AdWords::Utilities::BatchJobHandlerStatus->new({
    total_content_length => 0,
    resumable_upload_uri => 'UPLOAD_URL'
  });

# Create an operation to upload.
use_ok(get_api_package($client, "Budget"));
use_ok(get_api_package($client, "Money"));
use_ok(get_api_package($client, "BudgetOperation"));
my @operations = ();
my $budget = get_api_package($client, "Budget")->new({
  # Required attributes.
  budgetId => 1,
  name     => "Interplanetary budget #1",
  amount => get_api_package($client, "Money")->new({microAmount => 5000000}),
  deliveryMethod => "STANDARD"
});

my $budget_operation = get_api_package($client, "BudgetOperation")->new({
  operator => "ADD",
  operand  => $budget
});
push @operations, $budget_operation;

$batch_job_handler = Test::MockObject::Extends->new($batch_job_handler);
$batch_job_handler->mock("__initialize_upload", sub { return "LOCATION"; });
$batch_job_handler->mock("__check_response",    sub { return 1; });

# Upload operations in one call.
# This tests the serialization process.
$batch_job_status =
  $batch_job_handler->upload_operations(\@operations, $batch_job_status);
ok($batch_job_status, "upload operations");

# Retrieve the string representing the response SOAP XML.
# Set the HTTP Response contents.
my $properties        = read_test_properties();
my $expected_contents = $properties->getProperty("batch_job_response");
$expected_contents =
  replace_properties($expected_contents, {version => $client->get_version()});
my $response = HTTP::Response->new(200, "");
$response->content($expected_contents);
$batch_job_handler->mock("__check_response", sub { return $response; });

# This tests the deserialization process.
my $download_response = $batch_job_handler->download_response("URL");
ok($download_response, "download response $download_response");

# Verify that everything deserialized correctly without errors.
my $item = $download_response->get_rval()->[0];
ok(!$item->get_errorList(), "no error list");
is(
  $item->get_result()->get_Budget()->get_name(),
  "Interplanetary budget #1",
  "budget name"
);

# Upload operations in multiple calls.
# This tests the serialization process when multiple operations are sent in
# multiple calls.
$batch_job_status =
  Google::Ads::AdWords::Utilities::BatchJobHandlerStatus->new({
    total_content_length => 0,
    resumable_upload_uri => 'UPLOAD_URL'
  });
$batch_job_status =
  $batch_job_handler->upload_incremental_operations(\@operations,
  $batch_job_status);
ok($batch_job_status, "upload operations");

my $is_last_request = 1;
$batch_job_status =
  $batch_job_handler->upload_incremental_operations(\@operations,
  $batch_job_status, $is_last_request);
ok($batch_job_status, "upload operations");

# Test out that the error is false, and the error can be converted to
# a string.
my $batch_job_handler_error =
  Google::Ads::AdWords::Utilities::BatchJobHandlerError->new({
    type        => "UPLOAD",
    description => "test"
  });
ok(!$batch_job_handler_error, "BOOLIFY on error false");
ok($batch_job_handler_error =~ /BatchJobHandlerError\s{[^}]+}/,
  "check BatchJobHandlerError STRINGIFY");

