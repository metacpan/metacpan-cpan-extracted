#!/usr/bin/perl
use Test::Spec;
use Test::Exception;

use Karel::Robot;


sub count_steps {
    my $r = shift;
    my $c = 0;
    $c++, $r->step while $r->is_running;
    return $c
}


my $GRID =  << '__GRID__';
# karel v0.01 4 3
WWWWWW
W    W
W ^   W
W    W
WWWWWW
__GRID__

my $GRID_9_MARKS =  << '__GRID__';
# karel v0.01 1 1
WWW
W^9W
WWW
__GRID__

my $GRID_3x3 = << '__GRID__';
# karel v0.01 3 3
WWWWW
W   W
W   W
W ^  W
WWWWW
__GRID__

my $GRID_NARROW = << '__GRID__';
# karel v0.01 1 4
WWW
W W
W W
W W
W^ W
WWW
__GRID__


describe 'Karel::Robot internally' => sub {
    my $robot_running_a_structure = sub {
        my ($grid, $struct) = @_;
        my $r = 'Karel::Robot'->new;
        $r->load_grid( string => $grid );
        $r->_run($struct);
        return $r
    };

    it 'creates stack' => sub {
        my $r = $robot_running_a_structure->($GRID, [ ['f'], ['l'] ]);
        ok $r->_stack;
    };

    it 'steps through single commands' => sub {
        my $r = $robot_running_a_structure->($GRID, [ ['f'], ['l'] ]);
        $r->step;
        cmp_methods $r, [ x => 2, y => 1, facing => 'W' ];

        $r->step;
        cmp_methods $r, [ x => 2, y => 1, direction => 'W' ];
    };

    it 'empties the stack' => sub {
        my $r = $robot_running_a_structure->($GRID, [ ['f'], ['l'] ]);
        $r->step for 1, 2;
        ok ! $r->_stack;
        dies_ok { $r->step };
    };

    it 'steps through a repeat structure' => sub {
        my $r = $robot_running_a_structure->(
            $GRID, [ ['r', 3, [ ['r', 2, [ ['l'] ] ] ] ], ['f'] ]
        );
        is count_steps($r), 12;
        cmp_methods $r, [ direction => 'S', y => 3 ];
    };

    it 'steps through dropping' => sub {
        my $r = $robot_running_a_structure->($GRID, [ ['r', 9, [ ['d'] ] ] ]);
        is count_steps($r), 11;
        is $r->cover, '9';
    };

    it 'steps through picking' => sub {
        my $r = $robot_running_a_structure->(
            $GRID_9_MARKS, [ ['r', 3, [ ['r', 3, [ ['p'] ] ] ] ] ]
        );
        is count_steps($r), 14;
        is $r->cover, ' ';
    };

    it 'steps through while and if, checking walls and marks' => sub {
        my $r = $robot_running_a_structure->(
            $GRID_3x3,
            [ ['w', '!w', [ ['f'] ] ],
              ['i', 'w', [ ['l'], ['l'] ] ],
              ['i', 'm', [ ['p'] ], [ ['d'] ] ] ]
        );
        count_steps($r);
        cmp_methods $r, [ y => 1, direction => 'S', cover => '1' ];
    };

    it 'steps through nested loops, checking winds' => sub {
        my $r = $robot_running_a_structure->(
            $GRID_NARROW,
            [ ['r', 4, [ ['i', '!w', [ ['f'] ] ],
                         ['d'] ] ],
              ['w', '!S', [ ['r', 3, [ ['l'] ] ] ] ] ]
        );
        count_steps($r);
        cmp_methods $r, [ y         => 1,
                          direction => 'S',
                          cover     => '2',
                          facing    => '1',
                        ];
    };

    it 'quits correctly' => sub {
        my $r = $robot_running_a_structure->(
            $GRID,
            [ ['r', 2, [ ['i', 'N', [ ['l'], ['q'] ] ] ] ],
              ['f'], ['f'] ]
        );
        is count_steps($r), 3;
    };

    it 'calls external commands' => sub {
        my $r = $robot_running_a_structure->(
            $GRID, [ [ 'c', 'right' ], ['l'] ]);
        $r->_set_knowledge({ right => [ [ [ 'r', 3, [ ['l'] ] ] ],
                                        'definition']  });
        count_steps($r);
        is $r->direction, 'N';
    };
};

runtests();
