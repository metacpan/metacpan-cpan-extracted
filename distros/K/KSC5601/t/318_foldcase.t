# encoding: KSC5601
# This file is encoded in KS C 5601.
die "This file is not encoded in KS C 5601.\n" if q{あ} ne "\xa4\xa2";

use KSC5601;
print "1..13\n";

my $__FILE__ = __FILE__;

if ($] < 5.016) {
    for my $tno (1 .. 13) {
        print qq{ok - $tno # SKIP $^X/$] $^O $__FILE__\n};
    }
    exit;
}

if (fc('ABCDEF') eq fc('abcdef')) {
    print qq{ok - 1 fc('ABCDEF') eq fc('abcdef')\n};
}
else {
    print qq{not ok - 1 fc('ABCDEF') eq fc('abcdef')\n};
}

if (fc('アイウエオ') eq 'アイウエオ') {
    print qq{ok - 2 fc('アイウエオ') eq 'アイウエオ'\n};
}
else {
    print qq{not ok - 2 fc('アイウエオ') eq 'アイウエオ'\n};
}

if ("\FABCDEF\E" eq "\Fabcdef\E") {
    print qq{ok - 3 "\\FABCDEF\\E" eq "\\Fabcdef\\E"\n};
}
else {
    print qq{not ok - 3 "\\FABCDEF\\E" eq "\\Fabcdef\\E"\n};
}

if ("\Fアイウエオ\E" eq "アイウエオ") {
    print qq{ok - 4 "\\Fアイウエオ\\E" eq "アイウエオ"\n};
}
else {
    print qq{not ok - 4 "\\Fアイウエオ\\E" eq "アイウエオ"\n};
}

if ("\FABCDEF\E" =~ /\Fabcdef\E/) {
    print qq{ok - 5 "\\FABCDEF\\E" =~ /\\Fabcdef\\E/\n};
}
else {
    print qq{not ok - 5 "\\FABCDEF\\E" =~ /\\Fabcdef\\E/\n};
}

if ("\Fabcdef\E" =~ /\FABCDEF\E/) {
    print qq{ok - 6 "\\Fabcdef\\E" =~ /\\FABCDEF\\E/\n};
}
else {
    print qq{not ok - 6 "\\Fabcdef\\E" =~ /\\FABCDEF\\E/\n};
}

if ("\FABCDEF\E" =~ /\Fabcdef\E/i) {
    print qq{ok - 7 "\\FABCDEF\\E" =~ /\\Fabcdef\\E/i\n};
}
else {
    print qq{not ok - 7 "\\FABCDEF\\E" =~ /\\Fabcdef\\E/i\n};
}

if ("\Fabcdef\E" =~ /\FABCDEF\E/i) {
    print qq{ok - 8 "\\Fabcdef\\E" =~ /\\FABCDEF\\E/i\n};
}
else {
    print qq{not ok - 8 "\\Fabcdef\\E" =~ /\\FABCDEF\\E/i\n};
}

my $var = 'abcdef';
if ("\FABCDEF\E" =~ /\F$var\E/i) {
    print qq{ok - 9 "\\FABCDEF\\E" =~ /\\F\$var\\E/i\n};
}
else {
    print qq{not ok - 9 "\\FABCDEF\\E" =~ /\\F\$var\\E/i\n};
}

$var = 'ABCDEF';
if ("\Fabcdef\E" =~ /\F$var\E/i) {
    print qq{ok - 10 "\\Fabcdef\\E" =~ /\\F\$var\\E/i\n};
}
else {
    print qq{not ok - 10 "\\Fabcdef\\E" =~ /\\F\$var\\E/i\n};
}

if ("アイウエオ" =~ /\Fアイウエオ\E/) {
    print qq{ok - 11 "アイウエオ" =~ /\\Fアイウエオ\\E/\n};
}
else {
    print qq{not ok - 11 "アイウエオ" =~ /\\Fアイウエオ\\E/\n};
}

if ("アイウエオ" =~ /\Fアイウエオ\E/i) {
    print qq{ok - 12 "アイウエオ" =~ /\\Fアイウエオ\\E/i\n};
}
else {
    print qq{not ok - 12 "アイウエオ" =~ /\\Fアイウエオ\\E/i\n};
}

$var = 'アイウエオ';
if ("アイウエオ" =~ /\F$var\E/i) {
    print qq{ok - 13 "アイウエオ" =~ /\\F\$var\\E/i\n};
}
else {
    print qq{not ok - 13 "アイウエオ" =~ /\\F\$var\\E/i\n};
}

__END__

