use strict;
use Test;

BEGIN { plan tests => 4 }

use MIME::Charset qw(:info);

my $obj;
$obj = MIME::Charset->new("iso-8859-2");
ok($obj->body_encoding, "Q", $obj->body_encoding);
$obj = MIME::Charset->new("ANSI X3.4-1968");
ok($obj->canonical_charset, "US-ASCII", $obj->canonical_charset);
$obj = MIME::Charset->new("utf-8");
ok($obj->header_encoding, "S", $obj->header_encoding);
$obj = MIME::Charset->new("shift_jis");
if (MIME::Charset::USE_ENCODE) {
    ok($obj->output_charset, "ISO-2022-JP", $obj->output_charset);
} else {
    ok($obj->output_charset, "SHIFT_JIS", $obj->output_charset);
}
