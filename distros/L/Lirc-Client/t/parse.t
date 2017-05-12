use strict;
use warnings;

use Test::More tests => 2;
use Lirc::Client;

# Test 2 -- can we create an new client based on lclient_test?
my $lirc = Lirc::Client->new( {
        prog   => 'lclient_test',
        rcfile => 'samples/lircrc',
        fake   => 1,
} );
ok $lirc, "Created new Lirc::Client";

# Test 3 -- can we get the command list?
my $commands = {
    'son-cable-CABLE_STOP-' => {
        'prog'   => 'lclient_test',
        'config' => 'STOP',
        'button' => 'CABLE_STOP',
        'remote' => 'son-cable'
    },
    'son-cable-CABLE_PAUSE-' => {
        'prog'   => 'lclient_test',
        'config' => 'PAUSE',
        'button' => 'CABLE_PAUSE',
        'remote' => 'son-cable'
    },
    'son-cable-CABLE_PLAY-' => {
        'prog'   => 'lclient_test',
        'config' => 'PLAY',
        'button' => 'CABLE_PLAY',
        'remote' => 'son-cable'
    },
    'son-cable-CABLE_ENTER-' => {
        'mode'   => 'enter_mode',
        'prog'   => 'lclient_test',
        'button' => 'CABLE_ENTER',
        'remote' => 'son-cable'
    },
    'son-cable-CABLE_STOP-enter_mode' => {
        'prog'   => 'lclient_test',
        'config' => 'ENTER_STOP',
        'button' => 'CABLE_STOP',
        'remote' => 'son-cable'
    },
    'son-cable-CABLE_PLAY-enter_mode' => {
        'prog'   => 'lclient_test',
        'config' => 'ENTER_PLAY',
        'button' => 'CABLE_PLAY',
        'remote' => 'son-cable'
    },
    '*-BUTTON_1-' => {
        'prog'   => 'lclient_test',
        'config' => 'button_1',
        'button' => 'BUTTON_1',
        'remote' => '*'
    },
    '*-BUTTON_2-' => {
        'prog'   => 'lclient_test',
        'config' => 'button_2',
        'button' => 'BUTTON_2',
        'remote' => '*'
    },

};

is_deeply $lirc->recognized_commands, $commands, "Recognized commands";
