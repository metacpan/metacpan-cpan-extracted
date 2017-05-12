#!perl -T
#
# ENV: FAST_TEST=1 : skip all slow tests.

use strict;
use warnings;
use Test::More tests => 6;
use Data::Dumper;
use License::Syntax;
my $o = new License::Syntax {nofsync => 1};

#1
$o->loadmap_csv('synopsis.csv', 'lauaas#c');
$o->loadmap_csv('license_map.csv', 'as');
ok(defined($o), "new with csv map");

my $s = $o->_saveable_map();
#2
ok(scalar(@$s) > 10, "_saveable_map()");
# warn Dumper $s;

unlink(         't/tmpmap.csv');
$o->savemap_csv('t/tmpmap.csv');
#3
ok(-s 't/tmpmap.csv' > 1000, 'savemap_csv()');

unless($ENV{FAST_TEST})
  {
    unlink(            't/tmpmap.sqlite');
    $o->savemap_sqlite('t/tmpmap.sqlite', 'lic_map', 'old_name', 'new_name', 1);
  }
else
  {
    warn "FAST_TEST defined. relying on existing t/tmpmap.sqlite\n";
  }
#4
ok(-s 't/tmpmap.sqlite' > 1000, 'savemap_sqlite()');
undef $o;

$o = new License::Syntax 't/tmpmap.sqlite;lic_map(old_name,new_name)';
#5
ok(defined($o), "new with sqlite map");

$o->savemap_csv('t/tmpmap2.csv');
#6
ok (-s 't/tmpmap2.csv' == -s 't/tmpmap.csv', 'csv unchanged after sqlite conversion');


