use strict;
use warnings;

use POSIX qw( strftime );

use Device::FTDI::SPI;

use Time::HiRes qw( sleep );

my $spi = Device::FTDI::SPI->new(
    mode       => 0,
    clock_rate => 1E6,
);

sub max7221_write_digit
{
   my ( $digit, $value ) = @_;
   $spi->write( pack "C C", $digit+1, $value );
}

# Decode mode all
$spi->write( pack "C C", 0x09, 0xff );

# Intensity medium
$spi->write( pack "C C", 0x0A, 4 );

# Scan Limit 8
$spi->write( pack "C C", 0x0B, 7 );

# Display test for 1 second on startup
$spi->write( pack "C C", 0x0F, 1 );

# Blank all the digits
$spi->write( pack "C C", $_, 0x0f ) for 1 .. 8;

# No shutdown
$spi->write( pack "C C", 0x0C, 1 )->get;

sleep 1;
# Display test off
$spi->write( pack "C C", 0x0F, 0 )->get;

while(1) {
    my $digits = strftime "%H%M%S", localtime();
    print "Time: $digits\n";

    max7221_write_digit( 0, substr $digits, 5, 1 );
    max7221_write_digit( 1, substr $digits, 4, 1 );
    max7221_write_digit( 3, substr $digits, 3, 1 );
    max7221_write_digit( 4, substr $digits, 2, 1 );
    max7221_write_digit( 6, substr $digits, 1, 1 );
    max7221_write_digit( 7, substr $digits, 0, 1 )->get;

    sleep 1;
}
