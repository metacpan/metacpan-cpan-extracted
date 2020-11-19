use 5.006;
use strict;
use warnings;

use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use FSM::Basic;

plan tests => 2;

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
            'cat' => { 
                'cat' => './t/test_cat.txt',
                'final'    => 0,
            },
            'o_test' => {
                'final'    => 0,
                'output'   => 'text output in place of prompt >'
            },
            'o_test_file' => {
                'final'    => 0,
                'output_file'   => 't/output.txt'
            },
            'help' => {
                'output' => 'enable
exit
mem_usage
Switch> '
            },
            'read'      => {'cat' => 'test_cat.txt'},
        },
        'not_matching_info' => '% Unknown command or computer name, or unable to find computer address',
        'output'            => 'Switch> '
    },
    'close' => {'final' => 1},
);

my $fsm   = FSM::Basic->new( \%states, 'accept' );
my $final = 0;
my $out;
( $final, $out ) = $fsm->run( 'default' );
( $final, $out ) = $fsm->run( 'o_test' );
ok($out =~ /^text output in place of prompt >$/ );
( $final, $out ) = $fsm->run( 'o_test_file' );
ok($out =~ /^text output from file #$/ );
last if $final;

