#!/usr/bin/perl
use Test::Spec;
use Test::Exception;

use Karel::Grid;

describe 'Karel::Grid' => sub {
    describe 'default' => sub {
        my $g;
        before each => sub {
            $g = 'Karel::Grid'->new(x => 1, y => 2);
        };

        it 'features an empty cell' => sub {
            is $g->at(1, 2), ' ';
        };

        it 'features walls' => sub {
            cmp_methods $g, [ [ 'at', 0, 0 ] => 'W',
                              [ 'at', 2, 2 ] => 'W',
                            ];
        };

        it "can't go beyond boundaries" => sub {
            dies_ok { $g->at(3, 1) };
        };
    };

    describe building => sub {
        my $g;
        before each => sub {
            $g = 'Karel::Grid'->new(x => 1, y => 2);
            $g->build_wall(1, 2);
        };

        it 'builds a wall' => sub {
            is $g->at(1, 2), 'w';
        };

        it 'removes a wall' => sub {
            $g->remove_wall(1, 2);
            is $g->at(1, 2), ' ';
        };

        it "can't remove a non-wall" => sub {
            dies_ok { $g->remove_wall(1, 1) };
        };

        it "can't build unknown objects internally" => sub {
            dies_ok { $g->_set(1, 2, '!') };
        };
    };

    describe marks => sub {
        my $g;
        before each => sub {
            $g = 'Karel::Grid'->new(x => 1, y => 2);
            $g->drop_mark(1, 2);
        };

        it 'can be dropped' => sub {
            is $g->at(1, 2), 1;
        };

        it 'can be picked' => sub {
            $g->pick_mark(1, 2);
            is $g->at(1, 2), ' ';
        };

        they 'can be more up to nine' => sub {
            $g->drop_mark(1, 2) for 2 .. 9;
            is $g->at(1, 2), 9;
            dies_ok { $g->drop_mark(1, 2) };
        };

        they 'can be picked all' => sub {
            $g->drop_mark(1, 2) for 2 .. 9;
            $g->pick_mark(1, 2) for 1 .. 9;
            is $g->at(1, 2), ' ';
            dies_ok { $g->pick_mark(1, 2) };
        };
    };

    describe clearing => sub {
        my $g;
        before each => sub {
            $g = 'Karel::Grid'->new(x => 1, y => 2);
        };

        it 'can remove a mark' => sub {
            $g->drop_mark(1, 2);
            $g->clear(1, 2);
            is $g->at(1, 2), ' ';
        };

        it 'can remove a wall' => sub {
            $g->build_wall(1, 2);
            $g->clear(1, 2);
            is $g->at(1, 2), ' ';
        };

        it "can't remove a boundary" => sub {
            dies_ok { $g->clear(0, 0) };
        };
    };
};

runtests();
