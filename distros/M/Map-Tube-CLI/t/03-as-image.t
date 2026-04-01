#!/usr/bin/env perl

use v5.14;
use strict;
use warnings FATAL => 'all';
use Capture::Tiny ':all';
use Map::Tube::CLI;
use Test::More;

my $min_tcm = 1.39;
eval "use Map::Tube::London $min_tcm";
plan skip_all => "Map::Tube::London $min_tcm required" if $@;

my $map = Map::Tube::London->new( );
plan skip_all => 'Map::Tube::Plugin::Graph required' unless $map->can('as_image');

my $cli;
eval { $cli = Map::Tube::CLI->new( map => 'London', generate_map => 1 ) };
ok($cli, 'Instantiating map tube client (1)');
if ($cli) {
  my $fname = 'London.png';
  unlink($fname);
  $cli->run( );
  ok(-s $fname, 'Generating PNG image of whole map');
  unlink($fname);
}

eval { $cli = Map::Tube::CLI->new( map => 'London', generate_map => 1, line => 'Bakerloo' ) };
ok($cli, 'Instantiating map tube client (2)');
if ($cli) {
  my $fname = 'Bakerloo.png';
  unlink($fname);
  $cli->run( );
  ok(-s $fname, 'Generating PNG image of one line');
  unlink($fname);
}

done_testing;
