#!/usr/bin/env perl

use v5.14;
use strict;
use warnings FATAL => 'all';
use lib 't/';
use File::Spec;
use Test::More tests => 9;
use Sample;

my $map = Sample->new( xml => File::Spec->catfile('t', 'map-unicode.xml') );

my $ret = $map->name();
is($ret, 'Unicode', 'Map name');

$ret = $map->bgcolor();
is($ret, undef, 'Initially undefined bgcolor');
$ret = $map->bgcolor('#887766');
is($ret, '#887766', 'Setting bgcolor to RRGGBB');
$ret = $map->bgcolor('green');
is($ret, 'green', 'Setting bgcolor to named value');
eval { $ret = $map->bgcolor('grok'); fail('Setting bgcolor to unknown name should fail');};
$ret = $map->bgcolor();
is($ret, 'green', 'bgcolor should be unchanged after fail');

$ret = $map->line_change_penalty();
is($ret, 0.5, 'Default line change penalty');

$ret = $map->line_change_penalty(0);
is($ret, 0.0, 'Line change penalty 0');

$ret = $map->line_change_penalty(0.9);
is($ret, 0.9, 'Line change penalty 0.9');

eval { $ret = $map->line_change_penalty(-0.1); fail('Line change penalty < 0 not allowed'); };
is($ret, 0.9, 'Line change penalty unchanged after fail');

done_testing;
