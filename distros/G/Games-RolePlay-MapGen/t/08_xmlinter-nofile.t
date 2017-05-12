
use strict;
use Test;

unless( -f "xml_parser.res" ) {
    plan tests => 1;
    skip(1,1,1);
    exit 0;
}

use Games::RolePlay::MapGen;

my $pid = fork;

unless( $pid ) {
    my ($x, $y) = (15, 15);
    my $tmp = new Games::RolePlay::MapGen({ tile_size=>10, num_rooms=>"2d4", bounding_box=>join("x", $x, $y) });
       $tmp->set_generator( "Basic" );
       $tmp->add_generator_plugin( "FiveSplit" );
       $tmp->add_generator_plugin( "BasicDoors" );
       $tmp->generate; 
       $tmp->set_exporter( "XML" );
       $tmp->export( "08_map.xml" );

    exit 0;
}

waitpid($pid,0) or die "waiting for $pid: $!";

open my $in, "<", "08_map.xml" or die $!;
my $xml = do {local $/; <$in>};
my $map = new Games::RolePlay::MapGen;
   $map->set_generator("XMLImport");
   $map->generate( xml_input => $xml );

my ($x,$y) = $map->size;
plan tests => ( 2*4 * $x*$y );

CHECK_OPEN_DIRECTIONS_FOR_SANITY: { # they should really be the same from each direction ... or there's a problem.
    my $m = $map->{_the_map};
    for my $i (0..$y-1) {
        for my $j (0..$x-1) {
            my $e = $m->[$i][$j];

            for my $ar ( [n=>[y=>$i-1]], [s=>[y=>$i+1]], [e=>[x=>$j+1]], [w=>[x=>$j-1]] ) {
                my $d = $ar->[0];
                my ($k, $v) = @{$ar->[1]};

                if( my $n = $e->{nb}{$d} ) {
                    my $o = $Games::RolePlay::MapGen::opp{$d};
                    my $r = $n->{nb}{$o} == $e;

                    # warn "$d:[$k,$v]-($j,$i)-($e->{x},$e->{y})-($n->{x},$n->{y})";

                    ok( $r );
                    ok( $n->{$k}, $v );

                } else {
                    ok(1);
                    ok(1);
                }
            }
        }
    }
}
