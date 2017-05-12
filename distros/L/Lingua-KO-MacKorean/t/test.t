
BEGIN { $| = 1; print "1..59\n"; }
END {print "not ok 1\n" unless $loaded;}

use Lingua::KO::MacKorean;
$loaded = 1;
print "ok 1\n";

### EMPTY STRING: 2..5

print "" eq Lingua::KO::MacKorean::encode("")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "" eq Lingua::KO::MacKorean::decode("")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "" eq encodeMacKorean("")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "" eq decodeMacKorean("")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

### Perl: 6..9

my $qperl = "\x50\x65\x72\x6C";
print $qperl eq Lingua::KO::MacKorean::encode("Perl")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "Perl" eq Lingua::KO::MacKorean::decode($qperl)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

my $perl = "\x50\x65\x72\x6C";
print $perl  eq encodeMacKorean("Perl")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "Perl" eq decodeMacKorean($perl)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

### CONTROL and ASCII: 10..21

# NULL must be always "\0" (otherwise can't be supported.)
print "\0" eq encodeMacKorean("\0")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\0" eq decodeMacKorean("\0")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

my $del = pack('U', 0x7F);
print "\x7F" eq encodeMacKorean($del)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print  $del  eq decodeMacKorean("\x7F")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

my $digit = "\x30\x31\x32\x33\x34\x35\x36\x37\x38\x39";
print $digit eq encodeMacKorean("0123456789")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "0123456789" eq decodeMacKorean($digit)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

my $asciiC = pack 'C*', 1..126;
my $asciiU = pack 'U*', 1..126;

print $asciiC eq encodeMacKorean($asciiU)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print $asciiU eq decodeMacKorean($asciiC)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

my $c1C = pack 'C*', 0x85..0x9f;
my $c1U = pack 'U*', 0x85..0x9f;

print $c1C eq encodeMacKorean($c1U)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print $c1U eq decodeMacKorean($c1C)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

my $sbyteC = pack 'C*', 0..127, 0x85..0x9f;
my $sbyteU = pack 'U*', 0..127, 0x85..0x9f;

print $sbyteC eq encodeMacKorean($sbyteU)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print $sbyteU eq decodeMacKorean($sbyteC)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

### IDSP: 22..27

print "\xA1\xA1" eq Lingua::KO::MacKorean::encode("\x{3000}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x{3000}" eq Lingua::KO::MacKorean::decode("\xA1\xA1")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\xA1\xA1" eq encodeMacKorean("\x{3000}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x{3000}" eq decodeMacKorean("\xA1\xA1")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

my $sb_idspC = pack 'C*', 0..127, 161,161, 0x85..0x9f;
my $sb_idspU = pack 'U*', 0..127, 0x3000,  0x85..0x9f;

print $sb_idspC eq encodeMacKorean($sb_idspU)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print $sb_idspU eq decodeMacKorean($sb_idspC)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

### MISC. CHARACTERS: 28..46

my $nbsp = pack('U', 0xA0);
print "\x80" eq encodeMacKorean($nbsp)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print $nbsp  eq decodeMacKorean("\x80")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x81" eq encodeMacKorean("\x{20A9}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x{20A9}" eq decodeMacKorean("\x81")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\xA1\x4D" eq encodeMacKorean("\x{FE59}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x{FE59}" eq decodeMacKorean("\xA1\x4D")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\xA1\x4D" eq encodeMacKorean("(\x{F878}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\xB0\xA1" eq encodeMacKorean("\x{AC00}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x{AC00}" eq decodeMacKorean("\xB0\xA1")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\xFD\xFE" eq encodeMacKorean("\x{8A70}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x{8A70}" eq decodeMacKorean("\xFD\xFE")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\xFF" eq encodeMacKorean("\x{2026}\x{F87F}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x{2026}\x{F87F}" eq decodeMacKorean("\xFF")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\xA1\x41" eq encodeMacKorean("\x{300C}\x{F87F}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x{300C}\x{F87F}" eq decodeMacKorean("\xA1\x41")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\xA9\x41" eq encodeMacKorean("\x{F860}A.")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x{F860}A." eq decodeMacKorean("\xA9\x41")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x41\xAA\xF9\x78" eq encodeMacKorean("A\x{F862}(21)x")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "A\x{F862}(21)x" eq decodeMacKorean("\x41\xAA\xF9\x78")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

### CALLBACK: 47..56

# On EBCDIC platform, '&' is not equal to "\x26", etc.
sub hexNCR { sprintf("\x26\x23\x78%x\x3B", shift) } # hexadecimal NCR
sub decNCR { sprintf("\x26\x23%d\x3B" , shift) } # decimal NCR

print "\x41\x42\x43" eq encodeMacKorean("ABC\x{100}\x{10000}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x41\x42\x43" eq encodeMacKorean(\"", "ABC\x{100}\x{10000}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x41\x42\x43\x3F\x3F" eq encodeMacKorean
	(\"\x3F", "ABC\x{100}\x{10000}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x41\x42\x43"."\x26\x23\x78\x31\x30\x30\x3B".
      "\x26\x23\x78\x31\x30\x30\x30\x30\x3B"
      eq encodeMacKorean(\&hexNCR, "ABC\x{100}\x{10000}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x41\x42\x43"."\x26\x23\x32\x35\x36\x3B".
      "\x26\x23\x36\x35\x35\x33\x36\x3B"
      eq encodeMacKorean(\&decNCR, "ABC\x{100}\x{10000}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

my $hh = sub { my $c = shift; $c eq "\xC9\xA1" ? "\x{10000}" : "" };

print "AB" eq decodeMacKorean("\x41\xC9\xA1\x42")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "AB" eq decodeMacKorean(\"", "\x41\xC9\xA1\x42")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "A?B" eq decodeMacKorean(\"?", "\x41\xC9\xA1\x42")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "A\x{10000}B" eq decodeMacKorean(\"\x{10000}", "\x41\xC9\xA1\x42")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "A\x{10000}B" eq decodeMacKorean($hh, "\x41\xC9\xA1\x42")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

### MISC. CHARACTERS: 57..59

print "\xAD\x6F" eq encodeMacKorean("\x{571F}\x{20DE}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\xAD\x6F\x61" eq encodeMacKorean("\x{571F}\x{20DE}a")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\xAD\x7D" eq encodeMacKorean("\x{571F}\x{20DE}\x{F87C}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";
