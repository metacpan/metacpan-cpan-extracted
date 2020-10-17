use strict;
use warnings;

use Test::More;
use FindBin;

use lib "$FindBin::Bin/../lib";
use FSM::Basic;

plan tests => 2;

my $P= 0;
$P = 1 if -f '/bin/ping';
$P = 2 if -f  '/sbin/ping';


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
            'exit'         => {
                'matching' => 'close',
                'final'    => 0
            },
            "ping1 (.*)"           => { "exec" => "/bin/ping -c 3 __1__" },
            "test1 (\\w+)\\s+(.*)" => { "exec" => "/bin/ping -c 3 __2__" },
            "ping2 (.*)"           => { "exec" => "/sbin/ping -c 3 __1__" },
            "test2 (\\w+)\\s+(.*)" => { "exec" => "/sbin/ping -c 3 __2__" }
        },
        'not_matching_info' => '% Unknown command or computer name, or unable to find computer address',
        'output'            => 'Switch> '
    },
    'close' => { 'final' => 1 },
);

my $fsm = FSM::Basic->new(\%states, 'accept');
my $final = 0;
my $out;
($final, $out) = $fsm->run('default');
if ($P == 1 ) {
    ($final, $out) = $fsm->run('ping1 127.0.0.1');
    ok($out =~ /3 packets transmitted, 3 (.*)received/mg);
    ($final, $out) = $fsm->run('test1 on 127.0.0.1');
    ok($out =~ /3 packets transmitted, 3 (.*)received/mg);
} elsif ($P ==2 ) {
    ($final, $out) = $fsm->run('ping2 127.0.0.1');
    ok($out =~ /3 packets transmitted, 3 (.*)received/mg);
    ($final, $out) = $fsm->run('test2 on 127.0.0.1');
    ok($out =~ /3 packets transmitted, 3 (.*)received/mg);
}else {
    BAIL_OUT( "no binary ping in /bin nor /sbin" );
}
last if $final;

