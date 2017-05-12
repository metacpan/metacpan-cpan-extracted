
BEGIN { $| = 1; print "1..52\n"; }
END {print "not ok 1\n" unless $loaded;}

use Lingua::ZH::MacChinese::Simplified;
$loaded = 1;
print "ok 1\n";

### EMPTY STRING: 2..5

print "" eq Lingua::ZH::MacChinese::Simplified::encode("")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "" eq Lingua::ZH::MacChinese::Simplified::decode("")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "" eq encodeMacChineseSimp("")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "" eq decodeMacChineseSimp("")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

### Perl: 6..9

my $qperl = "\x50\x65\x72\x6C";
print $qperl eq Lingua::ZH::MacChinese::Simplified::encode("Perl")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "Perl" eq Lingua::ZH::MacChinese::Simplified::decode($qperl)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

my $perl = "\x50\x65\x72\x6C";
print $perl  eq encodeMacChineseSimp("Perl")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "Perl" eq decodeMacChineseSimp($perl)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

### CONTROL and ASCII: 10..21

# NULL must be always "\0" (otherwise can't be supported.)
print "\0" eq encodeMacChineseSimp("\0")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\0" eq decodeMacChineseSimp("\0")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

my $del = pack('U', 0x7F);
print "\x7F" eq encodeMacChineseSimp($del)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print $del  eq decodeMacChineseSimp("\x7F")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

my $digit = "\x30\x31\x32\x33\x34\x35\x36\x37\x38\x39";
print $digit eq encodeMacChineseSimp("0123456789")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "0123456789" eq decodeMacChineseSimp($digit)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

my $asciiC = pack 'C*', 1..126;
my $asciiU = pack 'U*', 1..126;

print $asciiC eq encodeMacChineseSimp($asciiU)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print $asciiU eq decodeMacChineseSimp($asciiC)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

my $c1C = pack 'C*', 0x83..0x9f;
my $c1U = pack 'U*', 0x83..0x9f;

print $c1C eq encodeMacChineseSimp($c1U)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print $c1U eq decodeMacChineseSimp($c1C)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

my $sbyteC = pack 'C*', 0..127, 0x83..0x9f;
my $sbyteU = pack 'U*', 0..127, 0x83..0x9f;

print $sbyteC eq encodeMacChineseSimp($sbyteU)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print $sbyteU eq decodeMacChineseSimp($sbyteC)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

### IDSP: 22..27

print "\xA1\xA1" eq Lingua::ZH::MacChinese::Simplified::encode("\x{3000}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x{3000}" eq Lingua::ZH::MacChinese::Simplified::decode("\xA1\xA1")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\xA1\xA1" eq encodeMacChineseSimp("\x{3000}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x{3000}" eq decodeMacChineseSimp("\xA1\xA1")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

my $sb_idspC = pack 'C*', 0..127, 161,161, 0x83..0x9f;
my $sb_idspU = pack 'U*', 0..127, 0x3000,  0x83..0x9f;

print $sb_idspC eq encodeMacChineseSimp($sb_idspU)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print $sb_idspU eq decodeMacChineseSimp($sb_idspC)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

### MISC. CHARACTERS: 28..39

my $nbsp = pack('U', 0xA0);
print "\xA0" eq encodeMacChineseSimp($nbsp)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print $nbsp  eq decodeMacChineseSimp("\xA0")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

my $uualt = pack('U*', 0x00FC, 0xF87F);
print "\x80" eq encodeMacChineseSimp($uualt)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print $uualt eq decodeMacChineseSimp("\x80")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\xB0\xA1" eq encodeMacChineseSimp("\x{554A}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x{554A}" eq decodeMacChineseSimp("\xB0\xA1")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\xF7\xFE" eq encodeMacChineseSimp("\x{9F44}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x{9F44}" eq decodeMacChineseSimp("\xF7\xFE")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\xFF" eq encodeMacChineseSimp("\x{2026}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x{2026}" eq decodeMacChineseSimp("\xFF")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\xA6\xD9" eq encodeMacChineseSimp("\x{FF0C}\x{F87E}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x{FF0C}\x{F87E}" eq decodeMacChineseSimp("\xA6\xD9")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

### LATIN SMALL LETTER N WITH GRAVE: 40..42

print "\xA8\xBF" eq encodeMacChineseSimp("\x{01F9}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\xA8\xBF" eq encodeMacChineseSimp("n\x{300}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x{01F9}" eq decodeMacChineseSimp("\xA8\xBF")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

### CALLBACK: 43..52

# On EBCDIC platform, '&' is not equal to "\x26", etc.
sub hexNCR { sprintf("\x26\x23\x78%x\x3B", shift) } # hexadecimal NCR
sub decNCR { sprintf("\x26\x23%d\x3B" , shift) } # decimal NCR

print "\x41\x42\x43" eq encodeMacChineseSimp("ABC\x{100}\x{10000}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x41\x42\x43" eq encodeMacChineseSimp(\"", "ABC\x{100}\x{10000}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x41\x42\x43\x3F\x3F" eq encodeMacChineseSimp
	(\"\x3F", "ABC\x{100}\x{10000}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x41\x42\x43"."\x26\x23\x78\x31\x30\x30\x3B".
      "\x26\x23\x78\x31\x30\x30\x30\x30\x3B"
      eq encodeMacChineseSimp(\&hexNCR, "ABC\x{100}\x{10000}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x41\x42\x43"."\x26\x23\x32\x35\x36\x3B".
      "\x26\x23\x36\x35\x35\x33\x36\x3B"
      eq encodeMacChineseSimp(\&decNCR, "ABC\x{100}\x{10000}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

my $hh = sub { my $c = shift; $c eq "\xFC\xFE" ? "\x{10000}" : "" };

print "AB" eq decodeMacChineseSimp("\x41\xFC\xFE\x42")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "AB" eq decodeMacChineseSimp(\"", "\x41\xFC\xFE\x42")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "A?B" eq decodeMacChineseSimp(\"?", "\x41\xFC\xFE\x42")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "A\x{10000}B" eq decodeMacChineseSimp(\"\x{10000}", "\x41\xFC\xFE\x42")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "A\x{10000}B" eq decodeMacChineseSimp($hh, "\x41\xFC\xFE\x42")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

