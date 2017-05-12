#!/usr/bin/env perl

use Test;

BEGIN { plan tests => 27 }

use JSON::DWIW;

my $str = '{"key":"val","num":4}';
my $data = JSON::DWIW->from_json($str);

my $stats = JSON::DWIW->get_stats;

ok($stats->{hashes} == 1);
ok($stats->{arrays} == 0);
ok($stats->{strings} == 3);
ok($stats->{numbers} == 1);
ok($stats->{bools} == 0);
ok($stats->{nulls} == 0);

$str = '{"array":[ 4, 3, 2]}';
$data = JSON::DWIW->from_json($str);
$stats = JSON::DWIW->get_stats;

ok($stats->{hashes} == 1);
ok($stats->{arrays} == 1);
ok($stats->{strings} == 1);
ok($stats->{numbers} == 3);
ok($stats->{bools} == 0);
ok($stats->{nulls} == 0);

$str = '{"var1":null,"test":true,"test2":false}';
$data = JSON::DWIW->from_json($str);
$stats = JSON::DWIW->get_stats;

ok($stats->{hashes} == 1);
ok($stats->{arrays} == 0);
ok($stats->{strings} == 3);
ok($stats->{numbers} == 0);
ok($stats->{bools} == 2);
ok($stats->{nulls} == 1);

$str = '{"var1":null,"test":true,"test2":false,"hash":{"key1":"val1"}}';
$data = JSON::DWIW->from_json($str);
$stats = JSON::DWIW->get_stats;

ok($stats->{hashes} == 2);
ok($stats->{arrays} == 0);
ok($stats->{strings} == 6);
ok($stats->{numbers} == 0);
ok($stats->{bools} == 2);
ok($stats->{nulls} == 1);

$str = '[{"key_2":[[{"key_5":{"key_6":[[{"key_9":[[{"key_12":{"key_13":[{"key_15":[{"key_17":{"key_18":{"key_19":[{"key_21":{"key_22":[[{"key_25":{"key_26":{"key_27":[{"key_29":{"key_30":[[{"key_33":{"key_34":{"key_35":{"key_36":{"key_37":[{"key_39":{"key_40":[{"key_42":[{"key_44":[{"key_46":[[{"key_49":[[[{"key_53":[[{"key_56":[[[[[{"key_62":[{"key_64":{"key_65":[[[[{}]]]]}}]}]]]]]}]]}]]]}]]}]}]}]}}]}}}}}]]}}]}}}]]}}]}}}]}]}}]]}]]}}]]}]';
$data = JSON::DWIW->from_json($str);
$stats = JSON::DWIW->get_stats;
ok($stats->{max_depth} == 70);
ok($stats->{arrays} == 36);
ok($stats->{hashes} == 34);
