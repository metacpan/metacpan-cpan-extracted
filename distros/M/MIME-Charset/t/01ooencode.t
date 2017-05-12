use strict;
use Test;

BEGIN { plan tests => 18 }

use MIME::Charset qw(:trans);
if (&MIME::Charset::USE_ENCODE && $] < 5.008) {
    require Encode::JP;
    require Encode::CN;
}

my ($converted, $charset, $encoding);
my $dst = "Perl:\033\$BIBE*\@^CoE*GQJ*=PNO4o\033(B";
my $src = "Perl:\xC9\xC2\xC5\xAA\xC0\xDE\xC3\xEF\xC5\xAA".
	  "\xC7\xD1\xCA\xAA\xBD\xD0\xCE\xCF\xB4\xEF";
my $obj = MIME::Charset->new("euc-jp");
my $null = MIME::Charset->new(undef);

# test get encodings for body
($converted, $charset, $encoding) = $obj->body_encode($src);
if (MIME::Charset::USE_ENCODE) {
    ok($converted eq $dst);
    ok($charset, "ISO-2022-JP", $charset);
    ok($encoding, "7BIT", $encoding);
} else {
    ok($converted eq $src);
    ok($charset, "EUC-JP", $charset);
    ok($encoding, "8BIT", $encoding);
}

# test get encodings for body with auto-detection of 7-bit
($converted, $charset, $encoding) = $null->body_encode($dst);
if (MIME::Charset::USE_ENCODE) {
    ok($converted eq $dst);
    ok($charset, "ISO-2022-JP", $charset);
    ok($encoding, "7BIT", $encoding);
} else {
    ok($converted eq $dst);
    ok($charset, "US-ASCII", $charset);
    ok($encoding, "7BIT", $encoding);
}

# test get encodings for header
($converted, $charset, $encoding) = $obj->header_encode($src);
if (MIME::Charset::USE_ENCODE) {
    ok($converted eq $dst);
    ok($charset, "ISO-2022-JP", $charset);
    ok($encoding, "B", $encoding);
} else {
    ok($converted eq $src);
    ok($charset, "EUC-JP", $charset);
    ok($encoding, "B", $encoding);
}

# test get encodings for header with auto-detection of 7-bit
($converted, $charset, $encoding) = $null->header_encode($dst);
if (MIME::Charset::USE_ENCODE) {
    ok($converted eq $dst);
    ok($charset, "ISO-2022-JP", $charset);
    ok($encoding, "B", $encoding);
} else {
    ok($converted eq $dst);
    ok($charset, "US-ASCII", $charset);
    ok($encoding, undef, $encoding);
}

$obj = MIME::Charset->new("hz-gb-2312");
$src = "~{<:Ky2;S{#,NpJ)l6HK!#~}~";

($converted, $charset, $encoding) = $obj->header_encode($src);
ok($converted eq $src);
ok($charset, "HZ-GB-2312", $charset);
ok($encoding, "B", $encoding);

$src = "This doesn't contain non-ASCII.";
($converted, $charset, $encoding) = $obj->header_encode($src);
ok($converted eq $src);
ok($charset, "US-ASCII", $charset);
ok($encoding, undef, $encoding);

