
BEGIN { $| = 1; print "1..49\n"; }
END {print "not ok 1\n" unless $loaded;}

use Lingua::ZH::MacChinese::Traditional;
$loaded = 1;
print "ok 1\n";

### EMPTY STRING: 2..5

print "" eq Lingua::ZH::MacChinese::Traditional::encode("")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "" eq Lingua::ZH::MacChinese::Traditional::decode("")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "" eq encodeMacChineseTrad("")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "" eq decodeMacChineseTrad("")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

### Perl: 6..9

my $qperl = "\x50\x65\x72\x6C";
print $qperl eq Lingua::ZH::MacChinese::Traditional::encode("Perl")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "Perl" eq Lingua::ZH::MacChinese::Traditional::decode($qperl)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

my $perl = "\x50\x65\x72\x6C";
print $perl  eq encodeMacChineseTrad("Perl")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "Perl" eq decodeMacChineseTrad($perl)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

### CONTROL and ASCII: 10..21

# NULL must be always "\0" (otherwise can't be supported.)
print "\0" eq encodeMacChineseTrad("\0")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\0" eq decodeMacChineseTrad("\0")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

my $del = pack('U', 0x7F);
print "\x7F" eq encodeMacChineseTrad($del)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print  $del  eq decodeMacChineseTrad("\x7F")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

my $digit = "\x30\x31\x32\x33\x34\x35\x36\x37\x38\x39";
print $digit eq encodeMacChineseTrad("0123456789")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "0123456789" eq decodeMacChineseTrad($digit)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

my $asciiC = pack 'C*', 1..126;
my $asciiU = pack 'U*', 1..126;

print $asciiC eq encodeMacChineseTrad($asciiU)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print $asciiU eq decodeMacChineseTrad($asciiC)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

my $c1C = pack 'C*', 0x83..0x9f;
my $c1U = pack 'U*', 0x83..0x9f;

print $c1C eq encodeMacChineseTrad($c1U)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print $c1U eq decodeMacChineseTrad($c1C)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

my $sbyteC = pack 'C*', 0..127, 0x83..0x9f;
my $sbyteU = pack 'U*', 0..127, 0x83..0x9f;

print $sbyteC eq encodeMacChineseTrad($sbyteU)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print $sbyteU eq decodeMacChineseTrad($sbyteC)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

### IDSP: 22..27

print "\xA1\x40" eq Lingua::ZH::MacChinese::Traditional::encode("\x{3000}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x{3000}" eq Lingua::ZH::MacChinese::Traditional::decode("\xA1\x40")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\xA1\x40" eq encodeMacChineseTrad("\x{3000}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x{3000}" eq decodeMacChineseTrad("\xA1\x40")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

my $sb_idspC = pack 'C*', 0..127, 161,64, 0x83..0x9f;
my $sb_idspU = pack 'U*', 0..127, 0x3000, 0x83..0x9f;

print $sb_idspC eq encodeMacChineseTrad($sb_idspU)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print $sb_idspU eq decodeMacChineseTrad($sb_idspC)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

### MISC. CHARACTERS: 28..39

my $nbsp = pack('U', 0xA0);
print "\xA0" eq encodeMacChineseTrad($nbsp)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print $nbsp  eq decodeMacChineseTrad("\xA0")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

my $solalt = pack('U*', 0x005C, 0xF87F);
print "\x80" eq encodeMacChineseTrad($solalt)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print $solalt eq decodeMacChineseTrad("\x80")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\xA4\x40" eq encodeMacChineseTrad("\x{4E00}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x{4E00}" eq decodeMacChineseTrad("\xA4\x40")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\xF9\xD5" eq encodeMacChineseTrad("\x{9F98}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x{9F98}" eq decodeMacChineseTrad("\xF9\xD5")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\xFF" eq encodeMacChineseTrad("\x{2026}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x{2026}" eq decodeMacChineseTrad("\xFF")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\xA1\x4D" eq encodeMacChineseTrad("\x{FF0C}\x{F87D}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x{FF0C}\x{F87D}" eq decodeMacChineseTrad("\xA1\x4D")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

### CALLBACK: 40..49

# On EBCDIC platform, '&' is not equal to "\x26", etc.
sub hexNCR { sprintf("\x26\x23\x78%x\x3B", shift) } # hexadecimal NCR
sub decNCR { sprintf("\x26\x23%d\x3B" , shift) } # decimal NCR

print "\x41\x42\x43" eq encodeMacChineseTrad("ABC\x{100}\x{10000}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x41\x42\x43" eq encodeMacChineseTrad(\"", "ABC\x{100}\x{10000}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x41\x42\x43\x3F\x3F" eq encodeMacChineseTrad
	(\"\x3F", "ABC\x{100}\x{10000}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x41\x42\x43"."\x26\x23\x78\x31\x30\x30\x3B".
      "\x26\x23\x78\x31\x30\x30\x30\x30\x3B"
      eq encodeMacChineseTrad(\&hexNCR, "ABC\x{100}\x{10000}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x41\x42\x43"."\x26\x23\x32\x35\x36\x3B".
      "\x26\x23\x36\x35\x35\x33\x36\x3B"
      eq encodeMacChineseTrad(\&decNCR, "ABC\x{100}\x{10000}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

my $hh = sub { my $c = shift; $c eq "\xFC\xFE" ? "\x{10000}" : "" };

print "AB" eq decodeMacChineseTrad("\x41\xFC\xFE\x42")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "AB" eq decodeMacChineseTrad(\"", "\x41\xFC\xFE\x42")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "A?B" eq decodeMacChineseTrad(\"?", "\x41\xFC\xFE\x42")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "A\x{10000}B" eq decodeMacChineseTrad(\"\x{10000}", "\x41\xFC\xFE\x42")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "A\x{10000}B" eq decodeMacChineseTrad($hh, "\x41\xFC\xFE\x42")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

