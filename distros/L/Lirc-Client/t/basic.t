use strict;
use warnings;

use Test::More tests => 12;
use Lirc::Client;

# Test set 2 -- create client with ordered list of arguments
my $lirc = Lirc::Client->new( 'lclient_test', 'samples/lircrc', undef, 1, 1 );
ok $lirc, "Created new Lirc::Client with ordered args";
is( $lirc->prog,   'lclient_test',   'program name correct' );
is( $lirc->rcfile, 'samples/lircrc', 'resource file correct' );
is( $lirc->dev,    '/dev/lircd',     'lircd device correct' );
is( $lirc->debug,  1,                'debug flag set correctly' );
is( $lirc->fake,   1,                'fake lirc dev flag set correctly' );

# Test set 3 -- create client with named arguments
$lirc = Lirc::Client->new(
    'lclient_test',
    {
        rcfile => 'samples/lircrc',
        debug  => 1,
        fake   => 1,
    } );
ok $lirc, "Created new Lirc::Client with named args";
is( $lirc->prog,   'lclient_test',   'program name correct' );
is( $lirc->rcfile, 'samples/lircrc', 'resource file correct' );
is( $lirc->dev,    '/dev/lircd',     'lircd device correct' );
is( $lirc->debug,  1,                'debug flag set correctly' );
is( $lirc->fake,   1,                'fake lirc dev flag set correctly' );
