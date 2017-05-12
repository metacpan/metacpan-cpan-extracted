
# test packets with DAO extensions
# Wed May 5 2008, Hessu, OH7LZB

use Test;

BEGIN { plan tests => 19 };
use Ham::APRS::FAP qw(parseaprs);

my($aprspacket, $retval);
my %h;

# uncompressed packet with human-readable DAO
# DAO in beginning of comment
$aprspacket = "K0ELR-15>APOT02,WIDE1-1,WIDE2-1,qAo,K0ELR:/102033h4133.03NX09029.49Wv204/000!W33! 12.3V 21C/A=000665";
$retval = parseaprs($aprspacket, \%h);

ok($retval, 1, "failed to parse an uncompressed packet with WGS84 human-readable DAO");
ok($h{'daodatumbyte'}, 'W', "incorrect DAO datum byte");
ok($h{'comment'}, '12.3V 21C', "incorrect comment parsing");
ok(sprintf('%.5f', $h{'latitude'}), "41.55055", "incorrect latitude parsing");
ok(sprintf('%.5f', $h{'longitude'}), "-90.49155", "incorrect longitude parsing");
ok(sprintf('%.0f', $h{'altitude'}), 203, "incorrect altitude");
ok(sprintf('%.3f', $h{'posresolution'}), "1.852", "incorrect position resolution");

# compressed packet with BASE91 DAO
# DAO in end of comment
%h = ();
$aprspacket = "OH7LZB-9>APZMDR,WIDE2-2,qAo,OH2RCH:!/0(yiTc5y>{2O http://aprs.fi/!w11!";
$retval = parseaprs($aprspacket, \%h);

ok($retval, 1, "failed to parse an uncompressed packet with WGS84 BASE91 DAO");
ok($h{'daodatumbyte'}, 'W', "incorrect DAO datum byte");
ok($h{'comment'}, 'http://aprs.fi/', "incorrect comment parsing");
ok(sprintf('%.5f', $h{'latitude'}), "60.15273", "incorrect latitude parsing");
ok(sprintf('%.5f', $h{'longitude'}), "24.66222", "incorrect longitude parsing");
ok(sprintf('%.4f', $h{'posresolution'}), "0.1852", "incorrect position resolution");

# mic-e packet with BASE91 DAO
# DAO in middle of comment
%h = ();
$aprspacket = "OH2JCQ-9>VP1U88,TRACE2-2,qAR,OH2RDK-5:'5'9\"^Rj/]\"4-}Foo !w66!Bar";
$retval = parseaprs($aprspacket, \%h);

ok($retval, 1, "failed to parse a mic-e packet with WGS84 BASE91 DAO");
ok($h{'daodatumbyte'}, 'W', "incorrect DAO datum byte");
ok($h{'comment'}, ']Foo Bar', "incorrect comment parsing");
ok(sprintf('%.5f', $h{'latitude'}), "60.26471", "incorrect latitude parsing");
ok(sprintf('%.5f', $h{'longitude'}), "25.18821", "incorrect longitude parsing");
ok(sprintf('%.4f', $h{'posresolution'}), "0.1852", "incorrect position resolution");

