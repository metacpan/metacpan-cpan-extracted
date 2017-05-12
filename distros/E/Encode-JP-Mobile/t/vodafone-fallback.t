use strict;
use warnings;
use Test::More tests => 3;
use Encode;
use Encode::JP::Mobile;

{
    my $u = "\x{0647}";
    is encode("x-sjis-vodafone", $u, Encode::FB_HTMLCREF), "&#1607;";
}

{
    my $u = "\x{0647}";
    my $var = encode("x-sjis-vodafone", $u, sub { "x" . $_[0] });
    is $var, "x1607";
}

{
    my $s = "\x1b\x24\x47\x21\x0f";
    decode('x-sjis-vodafone', $s, Encode::FB_HTMLCREF);
    is $s, "\x1b\x24\x47\x21\x0f";
}

