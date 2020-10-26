use 5.006;
use strict;
use warnings;

use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use FSM::Basic;

plan tests => 3;

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
            'enable'       => {
                'swapregex' => 1,
                'output'    => 'in enable',
                'final'     => 0
            },
            'other' => {
                'output'          => 'in other',
                'caseinsensitive' => 1,
                'final'           => 0
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

($final, $out) = $fsm->run('other');
ok($out eq "in other");
($final, $out) = $fsm->run('OTHER');
ok($out eq "in other");
($final, $out) = $fsm->run('OtheR');
ok($out eq "in other");

