#!/usr/bin/env perl

use Test;

use JSON::DWIW;

if (JSON::DWIW->has_deserialize) {
    plan tests => 24;
}
else {
    plan tests => 1;
    
    print "# deserialize not implemented on this platform\n";
    skip("Skipping on this platform", 0); # skipping on this platform
    exit 0;
}

my $str = '{"key":"val","num":4}';
my $data = JSON::DWIW::deserialize($str);

my $stats = JSON::DWIW->get_stats;

ok($stats->{hashes} == 1);
ok($stats->{arrays} == 0);
ok($stats->{strings} == 3);
ok($stats->{numbers} == 1);
ok($stats->{bools} == 0);
ok($stats->{nulls} == 0);

$str = '{"array":[ 4, 3, 2]}';
$data = JSON::DWIW::deserialize($str);
$stats = JSON::DWIW->get_stats;

ok($stats->{hashes} == 1);
ok($stats->{arrays} == 1);
ok($stats->{strings} == 1);
ok($stats->{numbers} == 3);
ok($stats->{bools} == 0);
ok($stats->{nulls} == 0);

$str = '{"var1":null,"test":true,"test2":false}';
$data = JSON::DWIW::deserialize($str);
$stats = JSON::DWIW->get_stats;

ok($stats->{hashes} == 1);
ok($stats->{arrays} == 0);
ok($stats->{strings} == 3);
ok($stats->{numbers} == 0);
ok($stats->{bools} == 2);
ok($stats->{nulls} == 1);

$str = '{"var1":null,"test":true,"test2":false,"hash":{"key1":"val1"}}';
$data = JSON::DWIW::deserialize($str);
$stats = JSON::DWIW->get_stats;

ok($stats->{hashes} == 2);
ok($stats->{arrays} == 0);
ok($stats->{strings} == 6);
ok($stats->{numbers} == 0);
ok($stats->{bools} == 2);
ok($stats->{nulls} == 1);

