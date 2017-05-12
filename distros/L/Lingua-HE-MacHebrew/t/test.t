
BEGIN { $| = 1; print "1..65\n"; }
END {print "not ok 1\n" unless $loaded;}

use strict;
use warnings;

use Lingua::HE::MacHebrew;
our $loaded = 1;
print "ok 1\n";

#### 2..

print "" eq encodeMacHebrew("")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "" eq decodeMacHebrew("")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "Perl" eq encodeMacHebrew("Perl")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "Perl" eq decodeMacHebrew("Perl")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "" eq Lingua::HE::MacHebrew::encode("")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "" eq Lingua::HE::MacHebrew::decode("")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "Perl" eq Lingua::HE::MacHebrew::encode("Perl")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "Perl" eq Lingua::HE::MacHebrew::decode("Perl")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

### 10..

our $ampLR = "\x{202D}\x2B\x{202C}";
our $ampRL = "\x{202E}\x2B\x{202C}";

print $ampLR eq decodeMacHebrew("\x2B")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print $ampRL eq decodeMacHebrew("\xAB")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x2B" eq encodeMacHebrew($ampLR)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\xAB" eq encodeMacHebrew($ampRL)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x{C4}" eq decodeMacHebrew("\x80")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x80" eq encodeMacHebrew("\x{C4}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x{5EA}" eq decodeMacHebrew("\xFA")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\xFA" eq encodeMacHebrew("\x{5EA}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

### 18..

our $longEnc = "\x24\x20\x28\x29";
our $longUni = "\x{202D}\x{0024}\x{0020}\x{0028}\x{0029}\x{202C}";

print $longUni eq decodeMacHebrew($longEnc)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print $longEnc eq encodeMacHebrew($longUni)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\0" eq encodeMacHebrew("\0")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\0" eq decodeMacHebrew("\0")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\cA" eq encodeMacHebrew("\cA")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\cA" eq decodeMacHebrew("\cA")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\t" eq encodeMacHebrew("\t")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\t" eq decodeMacHebrew("\t")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x7F" eq encodeMacHebrew("\x7F")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x7F" eq decodeMacHebrew("\x7F")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\n" eq encodeMacHebrew("\n")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\n" eq decodeMacHebrew("\n")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\r" eq encodeMacHebrew("\r")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\r" eq decodeMacHebrew("\r")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "0123456789" eq encodeMacHebrew("0123456789")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "0123456789" eq decodeMacHebrew("0123456789")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

### 34..

our $macDigitRL = "\xB0\xB1\xB2\xB3\xB4\xB5\xB6\xB7\xB8\xB9"; # RL only
our $uniDigit   = "\x30\x31\x32\x33\x34\x35\x36\x37\x38\x39";
our $uniDigitRL = "\x{202E}$uniDigit\x{202C}";

print "0123456789" eq encodeMacHebrew($uniDigit)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print $uniDigitRL eq decodeMacHebrew($macDigitRL)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print $macDigitRL eq encodeMacHebrew($uniDigitRL)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

# round-trip convetion for single-character strings

our $allchar = map chr, 0..255;
print $allchar eq encodeMacHebrew(decodeMacHebrew($allchar))
   ? "ok" : "not ok", " ", ++$loaded, "\n";

our $NG = 0;
for (my $char = 0; $char <= 255; $char++) {
    my $bchar = chr $char;
    my $uchar = encodeMacHebrew(decodeMacHebrew($bchar));
    $NG++ unless $bchar eq $uchar;
}
print $NG == 0
   ? "ok" : "not ok", " ", ++$loaded, "\n";

# to be downgraded on decoding.
print "\x{C4}" eq decodeMacHebrew("\x{80}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x{C4}" eq decodeMacHebrew(pack 'U', 0x80)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

### 40..

print "\x30" eq encodeMacHebrew("\x30")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x30" eq encodeMacHebrew("\x{202D}\x30") # with LRO
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\xB0" eq encodeMacHebrew("\x{202E}\x30") # with RLO
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x39" eq encodeMacHebrew("\x39")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x39" eq encodeMacHebrew("\x{202D}\x39") # with LRO
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\xB9" eq encodeMacHebrew("\x{202E}\x39") # with RLO
   ? "ok" : "not ok", " ", ++$loaded, "\n";

### 46..

our $hexNCR = sub { sprintf("&#x%x;", shift) };
our $decNCR = sub { sprintf("&#%d;" , shift) };

print "a\xC7" eq
	encodeMacHebrew(pack 'U*', 0x100ff, 0x61, 0x3042, 0xFB4B)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "a\xC7" eq
	encodeMacHebrew(\"", pack 'U*', 0x100ff, 0x61, 0x3042, 0xFB4B)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "?a?\xC7" eq
	encodeMacHebrew(\"?", pack 'U*', 0x100ff, 0x61, 0x3042, 0xFB4B)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "&#x100ff;a&#x3042;\xC7" eq
	encodeMacHebrew($hexNCR, pack 'U*', 0x100ff, 0x61, 0x3042, 0xFB4B)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "&#65791;a&#12354;\xC7" eq
	encodeMacHebrew($decNCR, pack 'U*', 0x100ff, 0x61, 0x3042, 0xFB4B)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x{5F2}\x{5B7}" eq decodeMacHebrew("\x81")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x81" eq encodeMacHebrew("\x{5F2}\x{5B7}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x81\x81\x81" eq encodeMacHebrew
	("\x{5F2}\x{5B7}\x{5F2}\x{5B7}\x{5F2}\x{5B7}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x81" eq encodeMacHebrew("\x{FB1F}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x{F86A}\x{05DC}\x{05B9}" eq decodeMacHebrew("\xC0")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\xC0" eq encodeMacHebrew("\x{F86A}\x{05DC}\x{05B9}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\xC0" eq encodeMacHebrew("\x{F89A}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x{05B8}\x{F87F}" eq decodeMacHebrew("\xDE")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\xDE" eq encodeMacHebrew("\x{05B8}\x{F87F}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\xDE" eq encodeMacHebrew("\x{F89F}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\xDE\xDE\xDE" eq encodeMacHebrew
	("\x{05B8}\x{F87F}\x{05B8}\x{F87F}\x{05B8}\x{F87F}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x{05B8}" eq decodeMacHebrew("\xCB")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\xCB" eq encodeMacHebrew("\x{05B8}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\xCB\xDE\xCB\xC8" eq encodeMacHebrew
	("\x{05B8}\x{05B8}\x{F87F}\x{05B8}\x{FB35}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

