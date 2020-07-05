#!perl
use Test::More tests => 6;
use_ok( 'HiPi' );
use_ok( 'HiPi::RaspberryPi' );


my $rawisraspberry = 0;

if ( $^O =~ /^linux/i ) {
    my $revraw = qx(cat /proc/cpuinfo | grep 'Revision') || '';
    chomp($revraw);
    $rawisraspberry = ( $revraw =~ /^Revision\s+:\s+[0-9[A-F]+$/i ) ? 1 : 0;
}

SKIP: {
      skip 'not on raspberry', 4 unless $rawisraspberry;

diag('Basic tests are running');

ok( HiPi::is_raspberry_pi(), 'HiPi says Raspberry Pi' );
my $pi = HiPi::RaspberryPi->new();
ok( $pi->is_raspberry(), 'Pi says Raspberry Pi' );

# board info
ok( $pi->hardware =~ /^BCM(27|28)/, 'hardware check as expected' );
ok( $pi->processor =~ /^BCM(2835|2836|2837|2711)/, 'processor check as expected' );

} # END OF SKIP MAIN

1;