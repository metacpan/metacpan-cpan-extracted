use 5.006;
use strict;
use warnings;

use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use FSM::Basic;

plan tests => 18;

my %states = (
    'accept' => {
        'expect' => {
            'default' => {
                'final'    => 0,
                'matching' => 'prompt'
            }
        },
        'not_matching_info_last' => '% Bad passwords',
        'not_matching'           => 'accept',
        'not_matching0'          => 'close',
        'repeat'                 => 2,
        'output'                 => 'Password: '
    },
    'prompt' => {
        'expect' => {
            'not_matching' => 'prompt',
            'e[nable]'     => {
                'alternation' => 1,
                'output'      => 'in enable',
                'final'       => 0
            },
            'ot[her]' => {
                'alternation'     => 1,
                'caseinsensitive' => 1,
                'output'          => 'in enable',
                'final'           => 0
            },
            'c[onfiguration] [terminal]' => {
                'alternation'      => '1',
                'output'           => 'TERMINAL'
            }
        },
        'not_matching_info' => '% Unknown command or computer name, or unable to find computer address',
        'output'            => 'prompt> '
    },
    'close' => { 'final' => 1 },
);

my $fsm = FSM::Basic->new(\%states, 'accept');
my $final = 0;
my $out;
($final, $out) = $fsm->run('default');

($final, $out) = $fsm->run('e');
ok(
    $out eq "% Unknown command or computer name, or unable to find computer address
prompt> "
);
($final, $out) = $fsm->run('en');
ok($out eq "in enable");
($final, $out) = $fsm->run('ena');
ok($out eq "in enable");
($final, $out) = $fsm->run('enab');
ok($out eq "in enable");
($final, $out) = $fsm->run('enabl');
ok($out eq "in enable");
($final, $out) = $fsm->run('enable');
ok($out eq "in enable");
($final, $out) = $fsm->run('enables');
ok(
    $out eq "% Unknown command or computer name, or unable to find computer address
prompt> "
);

($final, $out) = $fsm->run('o');
ok(
    $out eq "% Unknown command or computer name, or unable to find computer address
prompt> "
);
($final, $out) = $fsm->run('O');
ok(
    $out eq "% Unknown command or computer name, or unable to find computer address
prompt> "
);
($final, $out) = $fsm->run('Ot');
ok(
    $out eq "% Unknown command or computer name, or unable to find computer address
prompt> "
);
($final, $out) = $fsm->run('OTH');
ok($out eq "in enable");
($final, $out) = $fsm->run('OTHER');
ok($out eq "in enable");
($final, $out) = $fsm->run('other');
ok($out eq "in enable");
($final, $out) = $fsm->run('othera');
ok(
    $out eq "% Unknown command or computer name, or unable to find computer address
prompt> "
);

($final, $out) = $fsm->run('conf t');
ok($out eq "TERMINAL");
($final, $out) = $fsm->run('conf terminal');
ok($out eq "TERMINAL");
($final, $out) = $fsm->run('conf');
ok(
    $out eq "% Unknown command or computer name, or unable to find computer address
prompt> "
);
($final, $out) = $fsm->run('conf terminale');
ok(
    $out eq "% Unknown command or computer name, or unable to find computer address
prompt> "
);
