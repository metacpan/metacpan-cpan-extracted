#!/usr/bin/env perl

# Creation date: 2007-11-08 19:36:33
# Authors: don

use strict;
use warnings;

use Test;

BEGIN { plan tests => 5 };

use JSON::DWIW qw/deserialize_json from_json/;

my $json = '{"var1":"val1"}';
my $data = { var1 => 'val1' };
my $stats;

my $deser_skip = JSON::DWIW->has_deserialize ? '' : 'Skip -- deserialize not available';

unless ($deser_skip) {
    $data = JSON::DWIW::deserialize($json);
    $stats = JSON::DWIW::get_stats();
}

skip($deser_skip, ($data and $data->{var1} eq 'val1'));
skip($deser_skip, ($stats and $stats->{strings} == 2 and $stats->{hashes} == 1));

my $str = JSON::DWIW::serialize($data);
ok($str and $str eq '{"var1":"val1"}');

$data = deserialize_json($json);
ok($data and $data->{var1} eq 'val1');

$data = from_json($json);
ok($data and $data->{var1} eq 'val1');
