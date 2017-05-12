#!/usr/bin/env perl

# Creation date: 2007-11-30 08:55:13
# Authors: don

use strict;
use warnings;

use Test;

use JSON::DWIW;

if (JSON::DWIW->has_deserialize) {
    plan tests => 10;
}
else {
    plan tests => 1;
    
    print "# deserialize not implemented on this platform\n";
    skip("Skipping on this platform", 0); # skipping on this platform
    exit 0;
}

my $str;
my $data;
my $stats;

$str = '{"stuff":}';
$data = JSON::DWIW::deserialize($str);
ok(JSON::DWIW->get_error_string and not defined($data));
ok(JSON::DWIW::get_error_string);

$str = '{3stuff:"blah"}';
$data = JSON::DWIW::deserialize($str);
ok(JSON::DWIW->get_error_string and not defined($data));

$str = '356';
$data = JSON::DWIW::deserialize($str);
ok($data == 356);

$str = '[]';
$data = JSON::DWIW::deserialize($str);
ok(not JSON::DWIW::get_error_string and ref($data) eq 'ARRAY' and scalar(@$data) == 0);

$str = '[ ]';
$data = JSON::DWIW::deserialize($str);
ok(not JSON::DWIW->get_error_string and ref($data) eq 'ARRAY' and scalar(@$data) == 0);

$str = '[{"key_2":[[{"key_5":{"key_6":[[{"key_9":[[{"key_12":{"key_13":[{"key_15":[{"key_17":{"key_18":{"key_19":[{"key_21":{"key_22":[[{"key_25":{"key_26":{"key_27":[{"key_29":{"key_30":[[{"key_33":{"key_34":{"key_35":{"key_36":{"key_37":[{"key_39":{"key_40":[{"key_42":[{"key_44":[{"key_46":[[{"key_49":[[[{"key_53":[[{"key_56":[[[[[{"key_62":[{"key_64":{"key_65":[[[[{}]]]]}}]}]]]]]}]]}]]]}]]}]}]}]}}]}}}}}]]}}]}}}]]}}]}}}]}]}}]]}]]}}]]}]';
$data = JSON::DWIW::deserialize($str);
ok(not JSON::DWIW->get_error_string);

$stats = JSON::DWIW::get_stats();
ok($stats->{max_depth} == 70);
ok($stats->{arrays} == 36);
ok($stats->{hashes} == 34);



