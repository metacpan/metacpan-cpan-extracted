use strict;
use Test;
use Games::RolePlay::MapGen;
use Games::RolePlay::MapGen::MapQueue;
use List::Util qw(sum);

my $map = new Games::RolePlay::MapGen;
   $map->set_generator( "XMLImport" ); print STDERR " [xml]";
   $map->generate( xml_input_file => "vis1.map.xml" ); 

my $queue = new Games::RolePlay::MapGen::MapQueue( $map );

my @num_tests = (
    [s => 8,7] => [
        [8,7, '0.7000'], [8,8, '0.7000'], # sqrt(0.49**2 + 0.5**2)
        [7,7, '1.0509'], [7,8, '1.0509'], # not sure how we get these, probably varies with our extrude settings
        [9,7, '1.0509'], [9,8, '1.0509'], 
        [8,6, '1.1935'], 
        [4,7, '4.0535'],
    ],

    [e => 1,18] => [
        [1,17, '1.0509'], [2,17, '1.0509'], # there used to be calculations for some of these, 
        [1,18, '0.7000'], [2,18, '0.7000'], # as long as they're sorta the right magnitude, they're considered
        [1,19, '1.0509'], [2,19, '1.0509'], # correct -- but they're hand-checked for sanity.
        [1,15, '3.0710'],
        [1,21, '3.0710'],
        [2,15, '3.0710'],
        [1,14, '4.0535'],
    ],
);

plan tests => (sum map { int @$_ } values %{{@num_tests}} ) +
    2 + 2*(1+ 11-3 )*(1+ 7-5) + # around y7
    2 + 2*(1+ 19-14)*(1+ 1-0) + # around x2
    0;

RANGES: {
    while( my ($door, $tests) = splice @num_tests, 0, 2) {
        my $dobj = $map->{_the_map}[ $door->[2] ][ $door->[1] ]{od}{$door->[0]};
        for my $test (@$tests) {
            my $precalc = pop @$test;
            $queue->replace( me_r => ($test->[0],$test->[1]) );
            my $r = $queue->closure_line_of_sight( me_r => $dobj );
               $r =~ s/(\.\d{4})\d+/$1/;

            ok( "(@$test)(@$door): $r", "(@$test)(@$door): $precalc" );
        }
    }
}

AROUNDY7: {
    my $door1a = $map->{_the_map}[ 8 ][ 8 ]{od}{n};
    my $door1b = $map->{_the_map}[ 7 ][ 8 ]{od}{s};

    ok( ref $door1a );
    ok( ref $door1b );

    # some symmetry tests first
    # we'll ensure numerical accuracy after we ensure everything is calculated fairly from all perspectives
    # here we'll reflect things around the line at y=7
    for my $y ( 5 ..  7 ) { my $ay  = 1 + 7 + (7 - $y);
    for my $x ( 3 .. 11 ) {
    for my $door ($door1a, $door1b) {
            $queue->replace( me1 => ($x, $y) );
            $queue->replace( me2 => ($x, $ay) );

            my $top    = $queue->closure_line_of_sight( me1 => $door );
            my $bottom = $queue->closure_line_of_sight( me2 => $door );

            ok( "($x,$y)=~($x,$ay): $bottom", "($x,$y)=~($x,$ay): $top" );
    }}}
}

AROUNDX2: {
    my $door2a = $map->{_the_map}[ 18 ][ 1 ]{od}{e};
    my $door2b = $map->{_the_map}[ 18 ][ 2 ]{od}{w};

    ok( ref $door2a );
    ok( ref $door2b );

    for my $x (  0 ..  1 ) { my $ax  = 3 - $x;
    for my $y ( 14 .. 19 ) {
    for my $door ($door2a, $door2b) {
            $queue->replace( me1 => ($x,  $y) );
            $queue->replace( me2 => ($ax, $y) );

            my $left  = $queue->closure_line_of_sight( me1 => $door );
            my $right = $queue->closure_line_of_sight( me2 => $door );

            ok( "($x,$y)=~($ax,$y): $left", "($x,$y)=~($ax,$y): $right" );
    }}}
}
