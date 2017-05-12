#!/perl
use strict;
use warnings;

use Test::More;

use Device::Temperature::TMP102;

ok( my $dev = Device::Temperature::TMP102->new(),
    "Creating a new Device::Temperature::TMP102 object"
);

while ( my $line = <DATA> ) {
    chomp $line;
    next if $line =~ m|^\#|;

    my ( $temp, $bin, $h1, $h2 ) = split /,/, $line;

    my $hex_string = lc( "0x" . $h2 . "0" . $h1 );

    is( $dev->convertTemp( hex( $hex_string ) ),
        $temp,
        "Checking $hex_string => $temp"
    );
}

done_testing;


__DATA__
# taken from https://www.sparkfun.com/datasheets/Sensors/Temperature/tmp102.pdf
127.9375,011111111111,7F,F
100,011001000000,64,0
80,010100000000,50,0
75,010010110000,4B,0
50,001100100000,32,0
25,000110010000,19,0
0.25,000000000100,00,4
0,000000000000,00,0
-0.25,111111111100,FF,C
-25,111001110000,E7,0
-55,110010010000,C9,0
