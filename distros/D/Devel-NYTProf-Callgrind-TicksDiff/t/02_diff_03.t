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


my $fileout = "$temp/out.callgrind";
my $file  = "$RealBin/data/test04e.callgrind";
my $file2 = "$RealBin/data/test05e.callgrind";


    
    use_ok 'Devel::NYTProf::Callgrind::TicksDiff';
    my $tickdiff = Devel::NYTProf::Callgrind::TicksDiff->new( files => [$file,$file2] );

    is( scalar( @{$tickdiff->ticks_objects()} ), 2, "Load files by builder" );

    my $info = $tickdiff->compare();

    is( $info->{'delta_total'}, 815138, "Ticks delta total" );
    is( $info->{'delta_less'}, -1156162, "Ticks delta less" );
    is( $info->{'delta_more'}, 1971300, "Ticks delta more" );
    is( $info->{'not_found'}, 0, "Not found in B" );
    is( $info->{'max_less'}, -578081, "max less" );
    
    #use Data::Dumper;
    #print Dumper( $info );

    # compare() created the new ticks object.
    my $nobj = $tickdiff->getDeltaTicksObject();

    my @exp_ticks = qw( 132813 0 597924 0 919244 321319 0 );
    foreach my $t (0..6){
        is( $nobj->list()->[ $t ]->{'ticks'}, shift @exp_ticks, "Compare expected ticks for entry $t" );
    }


    # with negative values
    $tickdiff->allow_negative( 1 );
    my $info = $tickdiff->compare(); # recalc with negative values
    my $nobj = $tickdiff->getDeltaTicksObject();

    #print Dumper( $nobj->list() );
    #print Dumper( $info );

    my @exp_ticks = qw( 132813 -389575 597924 -578081 919244 321319 -188506 );
    foreach my $t (0..6){
        is( $nobj->list()->[ $t ]->{'ticks'}, shift @exp_ticks, "Compare expected ticks for entry $t" );
    }



    ## now do normalizing

    $tickdiff->normalize( 1 );
    my $info = $tickdiff->compare();

    my $nobj = $tickdiff->getDeltaTicksObject();


    my @exp_ticks = qw( 710894 188506 1176005 0 1497325 899400 389575 );
    foreach my $t (0..6){
        is( $nobj->list()->[ $t ]->{'ticks'}, shift @exp_ticks, "Compare expected ticks for entry $t" );
    }


    $tickdiff->saveDiffFile( $fileout );


    diag( "Loading the saved file and compare it" );

    # now load the file again and compare it
    my $ticks3 = Devel::NYTProf::Callgrind::Ticks->new( file => $fileout );
    

    my $list_a = $nobj->getBlocksAsArray();
    my $list_b = $ticks3->getBlocksAsArray();

    foreach my $i ( 0..$#$list_a ){

        my $block_a = $list_a->[ $i ];
        my $block_b = $list_b->[ $i ];

        my $fp_a = $nobj->_createFingerprintOfBlock( $block_a );
        my $fp_b = $ticks3->_createFingerprintOfBlock( $block_b );

        is( $fp_a, $fp_b, "Fingerprint of block number $i equals" );

    }




# cleanup
unlink $fileout if -e $fileout; 
rmdir $temp if -d $temp;

done_testing();
