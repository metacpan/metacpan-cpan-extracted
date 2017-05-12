use strict;

use lib '../lib';
use Test::More;
use FindBin qw($RealBin);
use Try::Tiny;



my $file  = "$RealBin/data/test01.callgrind";
my $file2 = "$RealBin/data/test02.callgrind";

try{
    
    use_ok 'Devel::NYTProf::Callgrind::Ticks';
    my $ticks = Devel::NYTProf::Callgrind::Ticks->new( file => $file );
    ok($ticks, "File loaded");

    ok( scalar( @{$ticks->getBlocksAsArray()}) == 7, "Amount of blocks");

    ok( scalar( keys %{ $ticks->blocks_by_id() })  == 7, "Hashed blocks" );


    my $ticks2 = Devel::NYTProf::Callgrind::Ticks->new( file => $file2 );
    ok($ticks2, "File2 loaded");


    ok( scalar( @{$ticks2->getBlocksAsArray()}) == 1, "Amount of blocks");

    ok( scalar( keys %{ $ticks2->blocks_by_id() })  == 1, "Hashed blocks" );


    ok( scalar( keys(%{$ticks2->getBlocksAsArray()->[0]}) ) != 0, "File has block at pos 0" );
    ok( $ticks->getBlockEquivalent( $ticks2->getBlocksAsArray()->[0] ), "Search for first block of file2 in file1" );


}catch{
    fail $_;
};



done_testing();
