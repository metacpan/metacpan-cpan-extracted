#!/usr/bin/perl
use Test::Spec;
use Test::Exception;
use Karel::Robot;

my $SMALL_GRID = << '__GRID__';
# karel v0.01 2 2
WWWW
W> 1W
W9wW
WWWW
__GRID__

my $GRID_WITH_ALL_MARKS = << '__GRID__';
# karel v0.01 4 3
WWWWWW
W1234W
W5678W
W9wv  W
WWWWWW
__GRID__

my $INVALID_GRID_MISPLACED_OUTER_WALL = << '__GRID__';
# karel v0.01 2 1
WWWW
W> WW
WWWW
__GRID__

describe 'Karel::Robot::load_grid' => sub {

    my $r;
    before each => sub { $r = 'Karel::Robot'->new };

    it 'validates type' => sub {
        dies_ok { $r->load_grid( url => 'http://' ) };
    };

    it 'from a handle' => sub {
        open my $FH, '<', \$SMALL_GRID or die "Can't read from a handle";
        lives_ok { $r->load_grid( handle => $FH ) };
        cmp_methods $r, [ x => 1, y => 1, direction => 'E' ];
    };

    it 'from a string' => sub {
        lives_ok { $r->load_grid( string => $GRID_WITH_ALL_MARKS ) };
        cmp_methods $r, [ x => 3, y => 3, direction => 'S' ];
    };

    it 'from a file' => sub {
        lives_ok { $r->load_grid( file => 't/minimal.kg' ) };
    };

    it 'validates the starting position' => sub {
        throws_ok { $r->load_grid( file => 't/invalid.kg' ) }
            qr/Wall at starting position/, q();
    };

    it 'reverts to backup after a failure' => sub {
        $r->load_grid( string => $SMALL_GRID );
        eval { $r->load_grid( file => 't/invalid.kg' ) };
        cmp_methods $r, [ x => 1, y => 1, direction => 'E' ];
    };

    it 'rejects misplaced outer walls' => sub {
        throws_ok {
            $r->load_grid( string => $INVALID_GRID_MISPLACED_OUTER_WALL )
        } qr/Unknown or invalid grid character 'W'/, q();
    };

};

runtests();
