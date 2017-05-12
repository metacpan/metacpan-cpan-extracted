
BEGIN { $| = 1; print "1..37\n"; }
END {print "not ok 1\n" unless $loaded;}

use Lingua::JA::MacJapanese;
$loaded = 1;
print "ok 1\n";

####

my @arys = (
  [ "\xF0\x40", "\x{E000}" ], #  2.. 3
  [ "\xF0\x41", "\x{E001}" ], #  4.. 5
  [ "\xF0\x7E", "\x{E03E}" ], #  6.. 7
  [ "\xF0\x80", "\x{E03F}" ], #  8.. 9
  [ "\xF0\x81", "\x{E040}" ], # 10..11
  [ "\xF0\xFC", "\x{E0BB}" ], # 12..13
  [ "\xF1\x40", "\x{E0BC}" ], # 14..15
  [ "\xF1\x7E", "\x{E0FA}" ], # 16..17
  [ "\xF1\x80", "\x{E0FB}" ], # 18..19
  [ "\xF1\xFC", "\x{E177}" ], # 20..21
  [ "\xF5\x95", "\x{E400}" ], # 22..23
  [ "\xF9\x40", "\x{E69C}" ], # 24..25
  [ "\xF9\xFC", "\x{E757}" ], # 26..27
  [ "\xFC\x40", "\x{E8D0}" ], # 28..29
  [ "\xFC\x7E", "\x{E90E}" ], # 30..31
  [ "\xFC\x80", "\x{E90F}" ], # 32..33
  [ "\xFC\xFC", "\x{E98B}" ], # 34..35
);

for my $ary (@arys) {
    my $mac = $ary->[0];
    my $uni = $ary->[1];

    print $mac eq encodeMacJapanese($uni)
	? "ok" : "not ok", " ", ++$loaded, "\n";

    print $uni eq decodeMacJapanese($mac)
	? "ok" : "not ok", " ", ++$loaded, "\n";
}

print "\x61\xF0\x40\xFC\xFC\x62" eq encodeMacJapanese("a\x{E000}\x{E98B}b")
    ? "ok" : "not ok", " ", ++$loaded, "\n";

print "a\x{E000}\x{E98B}b" eq decodeMacJapanese("\x61\xF0\x40\xFC\xFC\x62")
    ? "ok" : "not ok", " ", ++$loaded, "\n";

