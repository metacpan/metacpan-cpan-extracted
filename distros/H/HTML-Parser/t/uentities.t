use strict;
use warnings;
use utf8;

use HTML::Entities qw(decode_entities encode_entities);
use Test::More tests => 26;

# Test Unicode entities

SKIP: {
    skip "Unicode entities not selected", 26
        if !&HTML::Entities::UNICODE_SUPPORT;

    is(decode_entities("&euro"),  "&euro");
    is(decode_entities("&euro;"), "\x{20AC}");

    is(decode_entities("&aring"),  "å");
    is(decode_entities("&aring;"), "å");

    is(decode_entities("&#500000"), chr(500000));

    is(decode_entities("&#x10FFFD"), "\x{10FFFD}");

    is(decode_entities("&#xFFFC"), "\x{FFFC}");


    is(decode_entities("&#xFDD0"),     "\x{FFFD}");
    is(decode_entities("&#xFDD1"),     "\x{FFFD}");
    is(decode_entities("&#xFDE0"),     "\x{FFFD}");
    is(decode_entities("&#xFDEF"),     "\x{FFFD}");
    is(decode_entities("&#xFFFF"),     "&#xFFFF");
    is(decode_entities("&#x10FFFF"),   "\x{FFFD}");
    is(decode_entities("&#x110000"),   "&#x110000");
    is(decode_entities("&#XFFFFFFFF"), "&#XFFFFFFFF");

    is(decode_entities("&#0"),   "&#0");
    is(decode_entities("&#0;"),  "&#0;");
    is(decode_entities("&#x0"),  "&#x0");
    is(decode_entities("&#X0;"), "&#X0;");

    is(decode_entities("&#&aring&#229&#229;&#xFFF"), "&#ååå\x{FFF}");

    # This might fail when we get more than 64 bit UVs
    is(decode_entities("&#0009999999999999999999999999999;"),
        "&#0009999999999999999999999999999;");
    is(decode_entities("&#xFFFF0000FFFF0000FFFF1"), "&#xFFFF0000FFFF0000FFFF1");

    my $err;
    for ([32, 48], [120, 169], [240, 250], [250, 260], [965, 975], [3000, 3005])
    {
        my $x = join("", map chr, $_->[0] .. $_->[1]);

        my $e = encode_entities($x);
        my $d = decode_entities($e);

        unless ($d eq $x) {
            diag "Wrong decoding in range $_->[0] .. $_->[1]";

            # use Devel::Peek; Dump($x); Dump($d);
            $err++;
        }
    }
    ok(!$err);


    is(decode_entities("&#56256;&#56453;"), chr(0x100085));

    is(decode_entities("&#56256"), chr(0xFFFD));

    is(decode_entities("\260&rsquo;\260"), "\x{b0}\x{2019}\x{b0}");
}
