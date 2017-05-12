use strict;

use lib '../lib';
use Test::More;
use FindBin qw($RealBin);
use Try::Tiny;



my $file2 = "$RealBin/data/test02.callgrind";

try{
    
    use_ok 'Devel::NYTProf::Callgrind::Ticks';
    my $ticks2 = Devel::NYTProf::Callgrind::Ticks->new( file => $file2 );
    ok($ticks2, "File2 loaded");

    # empty ticks object
    my $ticks3 = Devel::NYTProf::Callgrind::Ticks->new();
    ok( $ticks3, "Object created" );

    ok( scalar( @{$ticks2->getBlocksAsArray()}) == 1, "Amount of blocks");
    ok( scalar( keys %{ $ticks2->blocks_by_id() })  == 1, "Hashed blocks" );

    ok( scalar( keys(%{$ticks2->getBlocksAsArray()->[0]}) ) != 0, "File has block at pos 0" );
    ok( ! defined $ticks3->getBlockEquivalent( $ticks2->getBlocksAsArray()->[0]  ), "Search for first block of file2 in empty object" );

    ## now adding a block to empty object
    is( scalar( @{$ticks3->getBlocksAsArray()}), 0, "New object, amount of blocks");
    is( scalar( keys %{ $ticks3->blocks_by_id() }), 0, "New object, hashed blocks" );

    my $nblock = $ticks2->getBlocksAsArray()->[0]; 

    # following addBlock() calls must replace the block, not add
    foreach my $i (1..3){

        $ticks3->addBlock( $nblock );

        is( scalar( @{$ticks3->getBlocksAsArray()}), 1, "New object, Amount of blocks");
        is( scalar( keys %{ $ticks3->blocks_by_id() }), 1, "New object, hashed blocks" );

    }

}catch{
    fail $_;
};



done_testing();
