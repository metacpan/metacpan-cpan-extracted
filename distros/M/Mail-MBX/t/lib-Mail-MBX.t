#! perl

use strict;
use warnings;

use Mail::MBX      ();
use File::Basename ();

use Test::More 'tests' => 15;
use Test::Exception;

my $datadir = File::Basename::dirname($0) . '/data';

#
# Make sure we're able to read our paltry little test MBX directory
#
{
    my $file = "$datadir/test.mbx";
    my $mbx;

    lives_ok {
        $mbx = Mail::MBX->open($file);
    }
    "Mail::MBX->open() is able to open $file without dying";

    my $expected_count = 3;
    my $found_count    = 0;

    while ( my $mbx_message = $mbx->message ) {
        ok( 1, "\$mbx->message() found a message" );

        lives_ok {
            while ( $mbx_message->read( my $buf, 4096 ) ) { }
        }
        '$mbx_message->read() does not die';

        lives_ok {
            $mbx_message->reset;
        }
        '$mbx_message->reset() does not die';

        lives_ok {
            while ( $mbx_message->read( my $buf, 4096 ) ) { }
        }
        '$mbx_message->read() does not die after $mbx_message->reset()';

        $found_count++;
    }

    is( $found_count => $expected_count, "\$mbx->message() found $expected_count messages" );
}

#
# Make sure we're able to choke on malformed MBX mailboxes.
#
{
    my $file = "$datadir/malformed.mbx";
    my $mbx  = Mail::MBX->open($file);

    throws_ok {
        $mbx->message;
    }
    qr/Invalid syntax/, "\$mbx->message() properly dies when trying to open malformed MBX file $file";
}
