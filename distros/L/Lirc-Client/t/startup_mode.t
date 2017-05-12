use Test::More tests => 2;
use Lirc::Client;

my $lirc = Lirc::Client->new( {
        prog   => "lirc-client-test",
        rcfile => "samples/lircrc.4",
        debug  => 0,
        fake   => 1,
} );
ok( $lirc, "created a lirc object" );
is( $lirc->mode, 'my-test-mode', 'started in the test_mode' );
use Data::Dumper;
print Dumper $lirc->recognized_commands;
