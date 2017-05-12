use strict;

use lib '../lib';
use Test::More;
use FindBin qw($RealBin);
use Try::Tiny;



my $file  = "$RealBin/data/test01.callgrind";
my $file2 = "$RealBin/data/test03.callgrind";


    
    use_ok 'Devel::NYTProf::Callgrind::TicksDiff';
    my $tickdiff = Devel::NYTProf::Callgrind::TicksDiff->new( files => [$file,$file2] );

    is( scalar( @{$tickdiff->ticks_objects()} ), 2, "Load files by builder" );

    my $info = $tickdiff->compare();

    is( $info->{'delta_total'}, 50060312, "Ticks delta total" );
    is( $info->{'delta_less'}, 0, "Ticks delta less" );
    is( $info->{'delta_more'}, 50060312, "Ticks delta more" );
    is( $info->{'not_found'}, 0, "Not found in B" );


    # compare() created the new ticks object.
    my $nobj = $tickdiff->getDeltaTicksObject();

    my @exp_ticks = qw( 1029059 4058 15655007 8325684 );
    foreach my $t (0..3){
        is( $nobj->list()->[ $t ]->{'ticks'}, shift @exp_ticks, "Compare expected ticks for entry $t" );
    }






done_testing();
