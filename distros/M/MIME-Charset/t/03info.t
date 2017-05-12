use strict;
use Test;

BEGIN { plan tests => 4 }

use MIME::Charset qw(:info);

ok(body_encoding("iso-8859-2"), "Q", body_encoding("iso-8859-2"));
ok(canonical_charset("ANSI X3.4-1968"), "US-ASCII",
   canonical_charset("ANSI X3.4-1968"));
ok(header_encoding("utf-8"), "S", header_encoding("utf-8"));
if (MIME::Charset::USE_ENCODE) {
    ok(output_charset("shift_jis"), "ISO-2022-JP",
       output_charset("shift_jis"));
} else {
    ok(output_charset("shift_jis"), "SHIFT_JIS", output_charset("shift_jis"));
}
