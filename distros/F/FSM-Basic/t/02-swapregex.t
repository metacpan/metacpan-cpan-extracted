use 5.006;
use strict;
use warnings;

use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use FSM::Basic;

plan tests => 7;

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
                'output'  => 'in enable',
                'final'     => 0
            }
        },
        'not_matching_info' => '% Unknown command or computer name, or unable to find computer address',
        'output'            => 'prompt> '
    },
    'close' => { 'final' => 1 },
);


my $fsm   = FSM::Basic->new( \%states, 'accept' );
my $final = 0;
my $out;
( $final, $out ) = $fsm->run( 'default' );


( $final, $out ) = $fsm->run( 'e' );
ok( $out eq "in enable" );
( $final, $out ) = $fsm->run( 'en' );
ok( $out eq "in enable" );
( $final, $out ) = $fsm->run( 'ena' );
ok( $out eq "in enable" );
( $final, $out ) = $fsm->run( 'enab' );
ok( $out eq "in enable" );
( $final, $out ) = $fsm->run( 'enabl' );
ok( $out eq "in enable" );
( $final, $out ) = $fsm->run( 'enable' );
ok( $out eq "in enable" );
( $final, $out ) = $fsm->run( 'enables' );
ok( $out eq "% Unknown command or computer name, or unable to find computer address
prompt> " );


