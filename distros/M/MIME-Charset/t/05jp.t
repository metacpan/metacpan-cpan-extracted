use strict;
use Test::More;
eval "use Encode::EUCJPASCII";
if ($@) {
    plan skip_all => "Encode::EUCJPASCII required";
} else {
    plan tests => 18;
}

use MIME::Charset qw(:trans);

my ($converted, $charset, $encoding);
my $src = "\x5C\x7E\xA1\xB1\xA1\xBD\xA1\xC0\xA1\xC1\xA1\xC2\xA1\xDD\xA1\xEF\xA1\xF1\xA1\xF2\xA2\xCC\xA1\xC1\x8F\xA2\xC3";
my $dst = "\x5c\x7e\e\x24\x42\x21\x31\x21\x3d\x21\x40\x21\x41\x21\x42\x21\x5d\x21\x6f\x21\x71\x21\x72\x22\x4c\x21\x41\e\x24\x28\x44\x22\x43\e\x28\x42";

# test get encodings for body
($converted, $charset, $encoding) = body_encode($src, "euc-jp");
if (MIME::Charset::USE_ENCODE) {
    is($converted, $dst);
    is($charset, "ISO-2022-JP");
    is($encoding, "7BIT");
} else {
    is($converted, $src);
    is($charset, "EUC-JP");
    is($encoding, "8BIT");
}

# test get encodings for body with auto-detection of 7-bit
($converted, $charset, $encoding) = body_encode($dst);
if (MIME::Charset::USE_ENCODE) {
    is($converted, $dst);
    is($charset, "ISO-2022-JP");
    is($encoding, "7BIT");
} else {
    is($converted, $dst);
    is($charset, "US-ASCII");
    is($encoding, "7BIT");
}

# test get encodings for header
($converted, $charset, $encoding) = header_encode($src, "euc-jp");
if (MIME::Charset::USE_ENCODE) {
    is($converted, $dst);
    is($charset, "ISO-2022-JP");
    is($encoding, "B");
} else {
    is($converted, $src);
    is($charset, "EUC-JP");
    is($encoding, "B");
}

# test get encodings for header with auto-detection of 7-bit
($converted, $charset, $encoding) = header_encode($dst);
if (MIME::Charset::USE_ENCODE) {
    is($converted, $dst);
    is($charset, "ISO-2022-JP");
    is($encoding, "B");
} else {
    is($converted, $dst);
    is($charset, "US-ASCII");
    is($encoding, undef);
}

$src = $dst;

# test get encodings for body
($converted, $charset, $encoding) = body_encode($src, "iso-2022-jp");
if (MIME::Charset::USE_ENCODE) {
    is($converted, $dst);
    is($charset, "ISO-2022-JP");
    is($encoding, "7BIT");
} else {
    is($converted, $src);
    is($charset, "ISO-2022-JP");
    is($encoding, "7BIT");
}

# test get encodings for header
($converted, $charset, $encoding) = header_encode($src, "iso-2022-jp");
if (MIME::Charset::USE_ENCODE) {
    is($converted, $dst);
    is($charset, "ISO-2022-JP");
    is($encoding, "B");
} else {
    is($converted, $src);
    is($charset, "ISO-2022-JP");
    is($encoding, "B");
}

