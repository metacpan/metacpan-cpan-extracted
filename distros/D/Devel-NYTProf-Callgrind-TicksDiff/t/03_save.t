use strict;

use lib '../lib';
use Test::More;
use FindBin qw($RealBin);
use Try::Tiny;
use File::Temp;

use warnings;
no warnings 'misc'; # reuse of var names

my $temp = File::Temp->newdir();

diag( "Temp dir: $temp" );

my $file2 = "$RealBin/data/test04e.callgrind";
my $fileout = "$temp/out.callgrind";

try{
    
    use_ok 'Devel::NYTProf::Callgrind::Ticks';
    my $ticks2 = Devel::NYTProf::Callgrind::Ticks->new( file => $file2 );
    ok($ticks2, "File2 loaded");

    # empty ticks object
    my $ticks3 = Devel::NYTProf::Callgrind::Ticks->new();
    ok( $ticks3, "Object created" );

    ok( scalar( @{$ticks2->getBlocksAsArray()}) == 7, "Amount of blocks");
    ok( scalar( keys %{ $ticks2->blocks_by_id() })  == 7, "Hashed blocks" );

    ok( scalar( keys(%{$ticks2->getBlocksAsArray()->[0]}) ) != 0, "File has block at pos 0" );
    ok( ! defined $ticks3->getBlockEquivalent( $ticks2->getBlocksAsArray()->[0]  ), "Search for first block of file2 in empty object" );

    ## now adding a block to empty object
    is( scalar( @{$ticks3->getBlocksAsArray()}), 0, "New object, amount of blocks");
    is( scalar( keys %{ $ticks3->blocks_by_id() }), 0, "New object, hashed blocks" );

    my $list = $ticks2->getBlocksAsArray();
    foreach my $block ( @$list ){
        $ticks3->addBlock( $block );
    }


    $ticks3->saveFile( $fileout );

    diag( "Loading the saved file and compare it" );

    # now load the file again and compare it
    my $ticks3 = Devel::NYTProf::Callgrind::Ticks->new( file => $fileout );
    

    my $list_a = $ticks2->getBlocksAsArray();
    my $list_b = $ticks3->getBlocksAsArray();

    foreach my $i ( 0..$#$list_a ){

        my $block_a = $list_a->[ $i ];
        my $block_b = $list_b->[ $i ];

        my $fp_a = $ticks2->_createFingerprintOfBlock( $block_a );
        my $fp_b = $ticks3->_createFingerprintOfBlock( $block_b );

        is( $fp_a, $fp_b, "Fingerprint of block number $i equals" );

    }


}catch{
    fail $_;
};


# cleanup
unlink $fileout if -e $fileout; 
rmdir $temp if -d $temp;

done_testing();
