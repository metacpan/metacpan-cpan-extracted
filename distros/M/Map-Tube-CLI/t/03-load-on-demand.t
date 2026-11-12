#!/usr/bin/perl

use 5.006;
use strict; use warnings;
use Test::More;

use Map::Tube::CLI;

# Only the requested map may be loaded, not every installed map.
# London is detected by looking in @INC, not by loading it, so that nothing
# is loaded before the CLI is asked for a map.
plan skip_all => 'Map::Tube::London required'
    unless grep { -f "$_/Map/Tube/London.pm" } grep { !ref } @INC;

my %supported = %{ Map::Tube::CLI::supported_maps() };
my @supported_files = map { (my $f = "$_.pm") =~ s{::}{/}g; $f } values %supported;

my @preloaded = grep { exists $INC{$_} } @supported_files;
plan skip_all => 'a supported map was loaded before the CLI was asked for one'
    if @preloaded;

my $cli = Map::Tube::CLI->new({ map => 'London', list_lines => 1 });
my @loaded = sort grep { exists $INC{$_} } @supported_files;

is_deeply(\@loaded, ['Map/Tube/London.pm'],
          'only the requested map is loaded');
ok(exists $cli->{maps}->{LONDON}, 'requested map object is available');

done_testing;
