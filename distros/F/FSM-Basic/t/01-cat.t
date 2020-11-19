use 5.006;
use strict;
use warnings;

use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use FSM::Basic;

plan tests => 1;

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
            'cat' => { 'cat' => './t/test_cat.txt',
            'final'    => 0
            },
            'help' => {
                'output' => 'enable
exit
mem_usage
Switch> '
            },
            'mem_usage' => {'do' => 'my ( $tot,$avail) = (split /\\n/ ,do { local( @ARGV, $/ ) = "/proc/meminfo" ; <> })[0,2];$tot =~ s/\\D*//g; $avail =~ s/\\D*//g; sprintf "%0.2f %%\\n",(100*($tot-$avail)/$tot); '},
        },
            'read'      => {'cat' => 'test_cat.txt'},
        
        'not_matching_info' => '% Unknown command or computer name, or unable to find computer address',
        'output'            => 'Switch> '
    },
    'close' => {'final' => 1},
);

my $fsm   = FSM::Basic->new( \%states, 'accept' );
my $final = 0;
my $out;
( $final, $out ) = $fsm->run( 'default' );
( $final, $out ) = $fsm->run( 'cat' );

ok($out =~ /^Hello World/ );
last if $final;

