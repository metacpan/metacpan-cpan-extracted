
BEGIN { $| = 1; print "1..51\n"; }
END {print "not ok 1\n" unless $loaded;}

use strict;
use warnings;

use Lingua::FA::MacFarsi;
our $loaded = 1;
print "ok 1\n";

### 2..

print "" eq encodeMacFarsi("")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "" eq decodeMacFarsi("")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "Perl" eq encodeMacFarsi("Perl")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "Perl" eq decodeMacFarsi("Perl")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "" eq Lingua::FA::MacFarsi::encode("")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "" eq Lingua::FA::MacFarsi::decode("")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "Perl" eq Lingua::FA::MacFarsi::encode("Perl")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "Perl" eq Lingua::FA::MacFarsi::decode("Perl")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

### 10..

our $ampLR = "\x{202D}\x2B\x{202C}";
our $ampRL = "\x{202E}\x2B\x{202C}";

print $ampLR eq decodeMacFarsi("\x2B")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print $ampRL eq decodeMacFarsi("\xAB")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x2B" eq encodeMacFarsi($ampLR)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\xAB" eq encodeMacFarsi($ampRL)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x{C4}" eq decodeMacFarsi("\x80")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x80" eq encodeMacFarsi("\x{C4}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x{6D2}" eq decodeMacFarsi("\xFF")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\xFF" eq encodeMacFarsi("\x{6D2}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

### 18..

our $longEnc = "\x24\x20\x28\x29";
our $longUni = "\x{202D}\x{0024}\x{0020}\x{0028}\x{0029}\x{202C}";

print $longUni eq decodeMacFarsi($longEnc)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print $longEnc eq encodeMacFarsi($longUni)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\0" eq encodeMacFarsi("\0")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\0" eq decodeMacFarsi("\0")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\cA" eq encodeMacFarsi("\cA")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\cA" eq decodeMacFarsi("\cA")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\t" eq encodeMacFarsi("\t")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\t" eq decodeMacFarsi("\t")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x7F" eq encodeMacFarsi("\x7F")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x7F" eq decodeMacFarsi("\x7F")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\n" eq encodeMacFarsi("\n")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\n" eq decodeMacFarsi("\n")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\r" eq encodeMacFarsi("\r")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\r" eq decodeMacFarsi("\r")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "0123456789" eq encodeMacFarsi("0123456789")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "0123456789" eq decodeMacFarsi("0123456789")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

### 34..

our $macDigitRL = "\xB0\xB1\xB2\xB3\xB4\xB5\xB6\xB7\xB8\xB9"; # RL only
our $uniDigit   = pack 'U*', 0x6F0..0x6F9;
our $uniDigitRL = "\x{202E}$uniDigit\x{202C}";

print "0123456789" eq encodeMacFarsi($uniDigit)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print $uniDigitRL eq decodeMacFarsi($macDigitRL)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print $macDigitRL eq encodeMacFarsi($uniDigitRL)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

# round-trip convetion for single-character strings

our $allchar = map chr, 0..255;
print $allchar eq encodeMacFarsi(decodeMacFarsi($allchar))
   ? "ok" : "not ok", " ", ++$loaded, "\n";

our $NG = 0;
for (my $char = 0; $char <= 255; $char++) {
    my $bchar = chr $char;
    my $uchar = encodeMacFarsi(decodeMacFarsi($bchar));
    $NG++ unless $bchar eq $uchar;
}
print $NG == 0
   ? "ok" : "not ok", " ", ++$loaded, "\n";

# to be downgraded on decoding.
print "\x{C4}" eq decodeMacFarsi("\x{80}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x{C4}" eq decodeMacFarsi(pack 'U', 0x80)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x30" eq encodeMacFarsi("\x{06F0}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x30" eq encodeMacFarsi("\x{202D}\x{06F0}") # with LRO
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\xB0" eq encodeMacFarsi("\x{202E}\x{06F0}") # with RLO
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x39" eq encodeMacFarsi("\x{06F9}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x39" eq encodeMacFarsi("\x{202D}\x{06F9}") # with LRO
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\xB9" eq encodeMacFarsi("\x{202E}\x{06F9}") # with RLO
   ? "ok" : "not ok", " ", ++$loaded, "\n";

### 47..

our $hexNCR = sub { sprintf("&#x%x;", shift) };
our $decNCR = sub { sprintf("&#%d;" , shift) };

print "a\xC7" eq
	encodeMacFarsi(pack 'U*', 0x100ff, 0x61, 0x3042, 0x0627)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "a\xC7" eq
	encodeMacFarsi(\"", pack 'U*', 0x100ff, 0x61, 0x3042, 0x0627)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "?a?\xC7" eq
	encodeMacFarsi(\"?", pack 'U*', 0x100ff, 0x61, 0x3042, 0x0627)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "&#x100ff;a&#x3042;\xC7" eq
	encodeMacFarsi($hexNCR, pack 'U*', 0x100ff, 0x61, 0x3042, 0x0627)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "&#65791;a&#12354;\xC7" eq
	encodeMacFarsi($decNCR, pack 'U*', 0x100ff, 0x61, 0x3042, 0x0627)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

