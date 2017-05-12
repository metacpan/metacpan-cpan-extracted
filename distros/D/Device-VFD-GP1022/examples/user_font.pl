use strict;
use warnings;
use lib 'lib';
use utf8;

use Device::VFD::GP1022;
use Device::VFD::GP1022::Message;

my $vfd = Device::VFD::GP1022->new('/dev/ttyUSB0');
#$vfd->switch;

$vfd->message( vfd_encode {
    RAW 0x1B80;

    RAW 0x9004;
    RAW ((0xFFFF) x 36);
    STR 'AAA';

    RAW 0x1B80;

    RAW 0x9003;
    RAW ((0xFFFF) x 18);

#    RAW 0x1B80;
#    RAW 0x1B81;
#    RAW 0x1B82;
#    RAW 0x1B83;

    BLINKLINE sub {
        RAW 0x1B8E;
        RAW 0x1B8F;
    }, 5;
    RAW 0x1B90;
    BLINKLINE 'HOGA', 5;
#0, 1, 0, 142, 27, 143, 27, 5, 142, 255, 142, 144, 27,fg

    RAW 0x1B80;

    RAW 0x9004, ((0xFFFF) x 36);
    STR 'AAA';

    RAW 0x1B80;

    RAW 0x9003, ((0xFFFF) x 18);

    RAW 0x1B91;
    RAW 0x1B92;
    RAW 0x1B93;

    return;
#    for (1..10) {

        BLINKLINE 'あげますaaaaaaaaaaaaaaaa', 5;
        UP '丸丸丸丸丸', 2;
        OPEN 'おーーーぷんーーーー';
        CLOSE 'くろーーーず';
#    }
} );

