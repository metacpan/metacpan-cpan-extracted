use strict;
use Test;

my $max = $ENV{LOSMAX} || 300; print STDERR "           LOSMAX=$max, higher for more tests!";

# queue and c setup {{{
use Games::RolePlay::MapGen;
use Games::RolePlay::MapGen::MapQueue;

print STDERR " [xml]";
my $map   = Games::RolePlay::MapGen->import_xml( "vis1.map.xml" ); 
my $queue = Games::RolePlay::MapGen::MapQueue->new( $map );

my $RANGE = $ENV{LOSRANGE} || 15;
my @POI = $queue->all_open_locations;

my $c = 0;
for my $lhs(@POI) {
for my $rhs(grep {sqrt( ($lhs->[0]-$_->[0])**2 + ($lhs->[1]-$_->[1])**2 )<=$RANGE} @POI) {
    $c ++;
}}

my @doors = (
    [33,2,'e'], [0,7,'n'], [6,7,'n'], [8,7,'s'], [11,9,'e'], [16,10,'s'], [11,14,'e'], [12,17,'s'], [34,17,'n'],
    [1,18,'w'], [11,18,'w'], [9,19,'n'], [34,21,'n'], [31,22,'e'], [8,23,'n'], [16,23,'w'], [23,23,'s'], [9,29,'w'],
    [11,29,'s'], [9,30,'e'], [13,30,'e'], [28,30,'s'], [25,31,'e'], [9,33,'w'], [31,34,'w'],
);

$c = $max if $max < $c;
# }}}

plan tests => 4 * $c + $c * @doors;

TOP: for my $lhs(sort {(rand)<=>(rand)} @POI) {
     for my $rhs(sort {(rand)<=>(rand)} grep {sqrt( ($lhs->[0]-$_->[0])**2 + ($lhs->[1]-$_->[1])**2 )<=$RANGE} @POI) {

    # LOS {{{
    LOS: {
        my $xs = $queue->_line_of_sight_xs($lhs, $rhs);
        my $pl = $queue->_line_of_sight_pl($lhs, $rhs);

        ok( $xs, $pl );

        if( $xs != $pl ) {
            our $bad ++;
            warn " LOS - (@$lhs)->(@$rhs) [bad=$bad]";
            die "too much bad" if $bad > 20;
        }

    }
    # }}}
    # TLOS {{{
    TLOS: {
        my $xs = $queue->_tight_line_of_sight_xs($lhs, $rhs);
        my $pl = $queue->_tight_line_of_sight_pl($lhs, $rhs);

        ok( $xs, $pl );

        if( $xs != $pl ) {
            our $bad ++;
            warn " TLOS - (@$lhs)->(@$rhs) [bad=$bad]";
            die "too much bad" if $bad > 20;
        }

    }
    # }}}
    # RC {{{
    RC: {
        my $xs = $queue->_ranged_cover_xs($lhs, $rhs);
        my $pl = $queue->_ranged_cover_pl($lhs, $rhs);

        ok( $xs, $pl );

        if( $xs != $pl ) {
            our $bad ++;
            warn " RC - (@$lhs)->(@$rhs) [bad=$bad]";
            die "too much bad" if $bad > 20;
        }

    }
    # }}}
    # MC {{{
    MC: {
        my $xs = $queue->_melee_cover_xs($lhs, $rhs);
        my $pl = $queue->_melee_cover_pl($lhs, $rhs);

        ok( $xs, $pl );

        if( $xs != $pl ) {
            our $bad ++;
            warn " MC - (@$lhs)->(@$rhs) [bad=$bad]";
            die "too much bad" if $bad > 20;
        }

    }
    # }}}
    # CLS {{{
    CLS: {
        our %did;
        my $key = "@$lhs";
        if( $did{$key} ) {
            ok(1) for @doors;

        } else {
            $did{$key} = 1;
            for my $door (@doors) {
                my $pl = $queue->_closure_line_of_sight_pl($lhs, $door);
                my $xs = $queue->_closure_line_of_sight_xs($lhs, $door);

                ok( $xs, $pl );

                if( $xs != $pl ) {
                    our $bad ++;
                    warn " CLS - (@$lhs)->(@$door) [bad=$bad]";
                    die "too much bad" if $bad > 20;
                }
            }
        }
    }
    # }}}

    $c --;
    last TOP if $c < 1;
}}
