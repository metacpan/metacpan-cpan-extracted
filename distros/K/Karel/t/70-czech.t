#!/usr/bin/perl
use utf8;
use Test::Spec;

use Karel::Robot;
use Karel::Parser::Czech;

my $COMMAND_RIGHT = 'příkaz vpravo opakuj 3 krát vlevo hotovo konec';

describe 'Karel::Robot with a Czech parser' => sub {
    my $robot;
    before each => sub {
        $robot = 'Karel::Robot'->new(parser => 'Karel::Parser::Czech'->new);
        $robot->set_grid('Karel::Grid'->new(x => 1, y => 1), 1, 1, 'N');
    };

    it 'runs core commands' => sub {
        $robot->run('vlevo');
        $robot->step while $robot->is_running;
        is $robot->direction, 'W';
    };

    it 'learns Czech commands' => sub {
        $robot->learn($COMMAND_RIGHT);
        $robot->run('vpravo');
        $robot->step while $robot->is_running;
        is $robot->direction, 'E';
    };

    it 'runs a complex Czech command' => sub {
        $robot->learn($COMMAND_RIGHT);
        $robot->run('opakuj 2 x vpravo hotovo');
        $robot->step while $robot->is_running;
        is $robot->direction, 'S';
    };

    it 'understands winds' => sub {
        $robot->learn($COMMAND_RIGHT
                      . ' příkaz na-jih'
                      . ' dokud není jih vpravo na-jih hotovo konec');
        $robot->run('na-jih');
        my $directions = q();
        while ($robot->is_running) {
            $robot->step;
            $directions .= $robot->direction;
        }
        $directions =~ tr///cs;
        is $directions, 'NWSENWS';
    };
};

runtests();
