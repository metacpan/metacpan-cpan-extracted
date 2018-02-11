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
# Unit tests for the Google::Ads::Common::Utilities::ServiceQueryBuilder module.

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

use_ok("Google::Ads::AdWords::Utilities::ServiceQueryBuilder");

my $client          = get_test_client();
my $current_version = $client->get_version();

# Instantiate the report query builder.
my $query_builder =
  Google::Ads::AdWords::Utilities::ServiceQueryBuilder->new({client => $client})
  ->select(["Id", "Name"]);
is($query_builder->build(), 'SELECT Id, Name');

$query_builder =
  Google::Ads::AdWords::Utilities::ServiceQueryBuilder->new({client => $client})
  ->select(["Id", "Name"])->where("Status")->equal_to("ENABLED");
is($query_builder->build(), 'SELECT Id, Name WHERE Status = "ENABLED"');

$query_builder =
  Google::Ads::AdWords::Utilities::ServiceQueryBuilder->new({client => $client})
  ->select(["Id", "Name"])->where("Status")->equal_to("ENABLED")
  ->order_by("Id");
is($query_builder->build(),
  'SELECT Id, Name WHERE Status = "ENABLED" ORDER BY Id ASC');

$query_builder =
  Google::Ads::AdWords::Utilities::ServiceQueryBuilder->new({client => $client})
  ->select(["Id", "Name"])->where("Status")->equal_to("ENABLED")
  ->order_by("Id")->order_by("Status", 0);
is($query_builder->build(),
  'SELECT Id, Name WHERE Status = "ENABLED" ORDER BY Id ASC, Status DESC');

$query_builder =
  Google::Ads::AdWords::Utilities::ServiceQueryBuilder->new({client => $client})
  ->select(["Id", "Name"])->where("Status")->equal_to("ENABLED")
  ->order_by("Id")->order_by("Status", 0)->limit(1, 10);
is($query_builder->build(),
  'SELECT Id, Name WHERE Status = "ENABLED" ORDER BY Id ASC, Status DESC ' .
    'LIMIT 1, 10');

# Test the copy function.
my $query_builder_copy =
  Google::Ads::AdWords::Utilities::ServiceQueryBuilder->new(
  {client => $client, query_builder => $query_builder});
is($query_builder_copy->build(),
  'SELECT Id, Name WHERE Status = "ENABLED" ORDER BY Id ASC, Status DESC ' .
    'LIMIT 1, 10');

# Test that duplicate fields get removed while keeping order.
my $duplicate_select_query_builder =
  Google::Ads::AdWords::Utilities::ServiceQueryBuilder->new({client => $client})
  ->select(["Id", "Name", "Id"]);
is($duplicate_select_query_builder->build(), 'SELECT Id, Name');

# Test multiple calls to select, where only the last call is used.
my $multiple_select_query_builder =
  Google::Ads::AdWords::Utilities::ServiceQueryBuilder
  ->new({client => $client})
  ->select(["Name"])
  ->select(["Id"]);
is($multiple_select_query_builder->build(), 'SELECT Id');

dies_ok {
  $client->set_die_on_faults(1);
  my $query_builder =
    Google::Ads::AdWords::Utilities::ServiceQueryBuilder
    ->new({client => $client})
    ->select(["Id", "Name"])->where("Status")->equal_to("ENABLED")
    ->order_by("Id")->order_by("Status", 0)->limit(1);
  $query_builder->build();
}
"expected to die due to missing page_size in limit";

dies_ok {
  $client->set_die_on_faults(1);
  my $query_builder =
    Google::Ads::AdWords::Utilities::ServiceQueryBuilder
    ->new({client => $client})
    ->select(["Id", "Name"])->where("Status")->equal_to("ENABLED")
    ->order_by("Id")->order_by("Status", 0)->limit(undef, 10);
  $query_builder->build();
}
"expected to die due to missing start_index in limit";

dies_ok {
  $client->set_die_on_faults(1);
  my $query_builder =
    Google::Ads::AdWords::Utilities::ServiceQueryBuilder
    ->new({client => $client})
    ->where("Status")->equal_to("ENABLED")
    ->order_by("Id")->order_by("Status", 0);
  $query_builder->build();
}
"expected to die due to lack of select";

dies_ok {
  $client->set_die_on_faults(1);
  my $query_builder =
    Google::Ads::AdWords::Utilities::ServiceQueryBuilder
    ->new({client => $client})
    ->select(["Id", "Name"])->where("Status")->equal_to("ENABLED")
    ->order_by("Id")->order_by("Status", 0)->limit(-1, 10);
  $query_builder->build();
}
"expected to die due to invalid start_index in limit";

dies_ok {
  $client->set_die_on_faults(1);
  my $query_builder =
    Google::Ads::AdWords::Utilities::ServiceQueryBuilder
    ->new({client => $client})
    ->select(["Id", "Name"])->where("Status")->equal_to("ENABLED")
    ->order_by("Id")->order_by("Status", 0)->limit(0, 0);
  $query_builder->build();
}
"expected to die due to invalid page_size in limit";
