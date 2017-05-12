#!/usr/bin/perl
#
# Copyright 2013, Google Inc. All Rights Reserved.
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
# Unit tests for the Google::Ads::Common::MapUtils module.
#
# Author: David Torres <david.t@google.com>

use strict;
use lib qw(lib t t/util);

use Test::More (tests => 6);
use TestAPIUtils qw(get_api_package);
use TestClientUtils qw(get_test_client_no_auth);

use_ok("Google::Ads::Common::MapUtils");

my $client = get_test_client_no_auth();
use_ok(get_api_package($client, "String_StringMapEntry"));

my $api_map = [get_api_package($client, "String_StringMapEntry")->new({
  key => "key.1", value => "value.1"
}), get_api_package($client, "String_StringMapEntry")->new({
  key => "key.2", value => "value.2"
})];

my $native_map = Google::Ads::Common::MapUtils::get_map($api_map);
is($native_map->{"key.1"}, "value.1");
is($native_map->{"key.2"}, "value.2");

$api_map = Google::Ads::Common::MapUtils::build_api_map({
  "key.1" => "value.1",
  "key.2" => "value.2"
});

is(scalar @{$api_map}, 2);
ok(($api_map->[0]->{"key"} eq "key.1" &&
    $api_map->[0]->{"value"} eq "value.1" &&
    $api_map->[1]->{"key"} eq "key.2" &&
    $api_map->[1]->{"value"} eq "value.2") ||
   ($api_map->[0]->{"key"} eq "key.2" &&
    $api_map->[0]->{"value"} eq "value.2" &&
    $api_map->[1]->{"key"} eq "key.1" &&
    $api_map->[1]->{"value"} eq "value.1"));
