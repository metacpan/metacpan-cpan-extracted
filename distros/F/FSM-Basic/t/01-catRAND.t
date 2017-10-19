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
                'catRAND' => './t/test_cat.txt ./t/test_cat1.txt',
                'final'   => 0
            },
            'help' => {
                'output' => 'enable
exit
mem_usage
Switch> '
            }
        },
        'read' => { 'cat' => 'test_cat.txt' },

        'not_matching_info' =>
'% Unknown command or computer name, or unable to find computer address',
        'output' => 'Switch> '
    },
    'close' => { 'final' => 1 },
);

my @ins   = qw( default cat);
my $fsm   = FSM::Basic->new( \%states, 'accept' );
my $final = 0;
my $out;
( $final, $out ) = $fsm->run('default');
ok( $out eq "Switch> " );
my %tot = ( 'Hello World' => 0, 'Hello Universe' => 0 );
for ( 1 .. 20000 ) {
    ( $final, $out ) = $fsm->run('catRAND');
    $out =~ s/\nSwitch.*//m;
    $tot{$out}++;
}

my $res = $tot{'Hello Universe'} / $tot{'Hello World'};
$res = $res > 1 ? 1/$res : $res ;
ok( $res > 0.95 );
last if $final;

