#!/usr/bin/perl
use Test::Spec;

use Karel::Robot;
use Karel::Grid;


my $program1 = << '__EOF__';
command turn-about repeat 2 x lleft done end
command right turn-about left end
command turn-twice repeat 2 x right done end
command ten-steps
    repeat 10 times
        if there's a wall
            repeat 2 x turn-about done
        else
            forward
        done
    done
end
__EOF__

my $program2 = 'command lleft left left left left left end';

my @highlighted = (
    'ten-steps',
    (
        'repeat 10 times.*done',
        'repeat 2 x turn-about done',
        (
            'repeat 2 x lleft done',
            ('left') x 5,
            ('repeat 2 x lleft done') x 2,
            ('left') x 5,
            ('repeat 2 x lleft done') x 2,
            ('repeat 2 x turn-about done') x 2,
        ) x 2,
        'repeat 10 times.*done'
    ) x 10,
    'repeat 10 times.*done',
    'ten-steps',
    'NO MORE COMMANDS',
);


my $r = 'Karel::Robot'->new;
$r->learn($program2);
$r->learn($program1);
$r->set_grid( 'Karel::Grid'->new(x => 3, y => 3), 2, 1 );

describe 'source code' => sub {
    it 'is used in stepping through' => sub {
        $r->run('ten-steps');
        while ($r->is_running) {
            my ($src, $from, $length) = $r->current;
            substr $src, $from + $length, 0, '>>';
            substr $src, $from, 0, '<<';
            $r->step;
            my $re = shift @highlighted;
            like $src, qr/<<$re>>/s;
        }
    };

};


runtests();
