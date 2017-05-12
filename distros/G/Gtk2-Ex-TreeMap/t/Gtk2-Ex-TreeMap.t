#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 5;

use Gtk2::Ex::TreeMap;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

my $treemap = Gtk2::Ex::TreeMap->new([600,400]);
isa_ok($treemap, "Gtk2::Ex::TreeMap");
ok($treemap->draw_map_simple([6,6,4,3,2,2,1]));
ok($treemap->get_image);

$treemap = Gtk2::Ex::TreeMap->new([600,400]);
ok($treemap->draw_map_simple([2,1]));
ok($treemap->get_image);