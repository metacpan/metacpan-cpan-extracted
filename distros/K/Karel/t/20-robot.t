#!/usr/bin/perl
use Test::Spec;
use Test::Exception;

use Karel::Robot;
use Karel::Grid;

describe 'Karel::Robot' => sub {

    describe 'gridless' => sub {
        my $k;
        before each => sub {
            $k = 'Karel::Robot'->new;
        };

        it instantiates => sub {
            isa_ok $k, 'Karel::Robot';
        };

        it 'has no grid related attributes' => sub {
            for my $m (qw( left grid )) {
                dies_ok { $k->$m };
            }
        };
    };

    describe 'grid' => sub {
        my ($k, $grid);
        before each => sub {
            $k = 'Karel::Robot'->new;
            $grid = 'Karel::Grid'->new(x => 1, y => 2);
            $k->set_grid($grid, 1, 1);
        };

        it 'takes a grid' => sub {
            is $k->grid, $grid;
        };

        it 'changes role' => sub {
            ok $k->does('Karel::Robot::WithGrid');
        };

        it 'sets default direction if none given' => sub {
            is $k->direction, 'N';
        };

        it 'can turn' => sub {
            $k->left;
            is $k->direction, 'W';

            $k->left for 1 .. 3;
            is $k->direction, 'N';
        };

        it "can't move in edit mode" => sub {
            dies_ok { $k->run_step };
        };

        it 'knows the neighbourhood' => sub {
            is $k->facing, 'W';
            cmp_deeply [ $k->facing_coords ], [ 1, 0 ];

            $k->left;
            cmp_deeply [ $k->facing_coords ], [ 0, 1 ];
        };

    };
};

runtests();
