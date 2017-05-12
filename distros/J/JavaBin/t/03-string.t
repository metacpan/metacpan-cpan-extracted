use strict;
use utf8;
use warnings;

use JavaBin;
use Test::More 0.96;

binmode Test::More->builder->$_, ':utf8' for qw/failure_output output todo_output/;

for (
    '',
    'perl',
    "☃",
    "Grüßen",
    'The quick brown fox jumped over the lazy dog',
    'Access to computers—and anything which might teach you something about the way the world works—should be unlimited and total. Always yield to the Hands-On Imperative!',
) {
    utf8::encode my $bytes = $_;

    subtest qq/"$bytes"/, sub {
        my $expected = "\2";
        my $len = length $bytes;

        if ( $len < 31 ) {
            $expected .= chr( 32 | $len );
        }
        else {
            $expected .= chr( 32 | 31 );

            $len -= 31;

            while ($len & ~127) {
                $expected .= chr( ($len & 127) | 128 );

                $len = $len >> 7;
            }

            $expected .= chr $len;
        }

        $expected .= $bytes;

        is my $got = to_javabin($_), $expected, 'to_javabin';

        is from_javabin($got), $_, 'from_javabin';
    };
}

done_testing;
