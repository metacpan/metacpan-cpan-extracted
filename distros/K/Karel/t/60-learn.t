#!/usr/bin/perl
use Test::Spec;
use Test::Exception;

use Karel::Robot;


describe 'Karel::Robot' => sub {
    my $r;
    before each => sub {
        $r = 'Karel::Robot'->new;
        $r->learn( << '__CMD__');
command right repeat 3 x left done end
command westward if not facing West left westward done end
command pick-all if there's a mark pick-mark pick-all done end
__CMD__
        return $r
    };

    describe 'without grid' => sub {

        it 'learns several commands' => sub {
            cmp_methods $r, [ map { [ knows => $_ ] => bool(1) }
                                  qw( right westward ) ];
        };

        it "can't run commands" => sub {
            throws_ok { $r->run('right') } qr/method "run"/, q();
        };
    };

    describe 'with a grid' => sub {
        before each => sub {
            $r->set_grid('Karel::Grid'->new(x => 5, y => 5), 3, 3, 'N');
        };

        it 'runs command' => sub {
            $r->run('right');
            $r->step while $r->is_running;
            is $r->direction, 'E';
        };

        it 'runs recursive commands' => sub {
            $r->run('westward');
            $r->step while $r->is_running;
            is $r->direction, 'W';
        };

        it 'ignores run without step' => sub {
            lives_ok { $r->run('unknown') };
            $r->run('stop');
            $r->step while $r->is_running;
        };

        it 'runs a complex command' => sub {
            $r->run('repeat 9 x drop-mark done');
            $r->step while $r->is_running;
            is $r->cover, '9';
        };

        it 'runs a deeper recursion' => sub {
            $r->run('repeat 9 x drop-mark done');
            $r->step while $r->is_running;

            $r->run('pick-all');
            $r->step while $r->is_running;
            is $r->cover, ' ';
        };

        it "can't run several commands at once" => sub {
            dies_ok { $r->run('forward forward') };
        };
    };
};

runtests();
