#!perl
use strict; use warnings;
use Test::Most tests => 12;
use ok 'Device::WWN::EMC::Symmetrix', ':all';
use ok 'Device::WWN', 'normalize_wwn';

my @tests = (
    [ '50:06:04:81:D6:F3:45:42', '123456789', '03AA' ],
    [ '500604872363ee43', '479039417', '04AA' ],
    [ '500604872363ee53', '479039417', '04BA' ],
    [ '500604872363ee4c', '479039417', '13AA' ],
    [ '500604872363ee5c', '479039417', '13BA' ],
);
for my $t ( @tests ) {
    my ( $wwn, $serial, $port ) = @{ $t };

    is_deeply(
        [ wwn_to_serial_and_port( $wwn ) ],
        [ $serial, $port ],
        "wwn_to_serial_and_port: $wwn => [ $serial, $port ]",
    );
    ( $wwn = lc $wwn ) =~ s/[^a-f0-9]//ig;
    is(
        serial_and_port_to_wwn( $serial, $port ),
        $wwn,
        "serial_and_port_to_wwn: [ $serial, $port ] => $wwn",
    );
}
