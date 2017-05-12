use Test::More tests => 10;
use Lirc::Client;

my $lirc = Lirc::Client->new( {
        prog   => "lirc-client-test",
        rcfile => "samples/lircrc.2",
        debug  => 0,
        fake   => 1,
} );
ok( $lirc, "created a lirc object" );

pipe my $read, $write or die $!;
$lirc->sock($read);
print $write "0 0 pause test-remote\n";
print $write "0 0 exit_mode1 test-remote\n";
print $write "0 0 play test-remote\n";
print $write "0 0 pause test-remote\n";
print $write "0 0 enter_mode1 test-remote\n";
print $write "0 0 pause test-remote\n";
print $write "0 0 exit_mode1 test-remote\n";
print $write "0 0 pause test-remote\n";

print $write "0 0 button_1 test-remote\n";
print $write "0 0 button_2 test-remote\n";
print $write "0 0 button_2 test-remote-1\n";
print $write "0 0 anybutton test-remote-2\n";
close $write;

for $code (
    qw/MODE1_PAUSE PLAY PAUSE MODE1_PAUSE PAUSE
    BUTTON_1 BUTTON_2 BUTTON_2 TEST-REMOTE-2/
  )
{
    is( $lirc->next_code, $code, "received $code" );
}
