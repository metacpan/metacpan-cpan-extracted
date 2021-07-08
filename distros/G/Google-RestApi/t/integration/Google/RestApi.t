#!/usr/bin/perl

use strict;
use warnings;

use YAML::Any qw(Dump);
use Test::Most tests => 3;

use aliased "Google::RestApi";

use Utils qw(:all);
init_logger();

my $config_file = rest_api_config();

my $api;
$api = RestApi->new(config_file => $config_file);
isa_ok $api, "Google::RestApi", "New api";

my $about;
is_hash $about = $api->api(
  uri => 'https://www.googleapis.com/drive/v3/about',
  params => { fields => 'user' },
), "Api login should succeed";
is_hash $about->{user}, "About drive.user";
