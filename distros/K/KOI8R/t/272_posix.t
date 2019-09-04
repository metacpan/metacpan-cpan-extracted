# encoding: KOI8R
# This file is encoded in KOI8-R.
die "This file is not encoded in KOI8-R.\n" if q{‚ } ne "\x82\xa0";

use strict;
use KOI8R;
print "1..1792\n";

my $__FILE__ = __FILE__;

my $tno = 1;

for my $ord (0x00 .. 0x7F) {
    $_ = chr($ord);
    my $match = 0;
    if (/[[:alnum:]]/) {
        $match++;
    }
    if (/[[:^alnum:]]/) {
        $match++;
    }
    if ($match == 1) {
        printf qq{ok - $tno "\\x%02X" =~ /[[:alnum:]]/ ($match) $^X $__FILE__\n}, $ord;
    }
    else {
        printf qq{not ok - $tno "\\x%02X" =~ /[[:alnum:]]/ ($match) $^X $__FILE__\n}, $ord;
    }
    $tno++;
}

for my $ord (0x00 .. 0x7F) {
    $_ = chr($ord);
    my $match = 0;
    if (/[[:alpha:]]/) {
        $match++;
    }
    if (/[[:^alpha:]]/) {
        $match++;
    }
    if ($match == 1) {
        printf qq{ok - $tno "\\x%02X" =~ /[[:alpha:]]/ ($match) $^X $__FILE__\n}, $ord;
    }
    else {
        printf qq{not ok - $tno "\\x%02X" =~ /[[:alpha:]]/ ($match) $^X $__FILE__\n}, $ord;
    }
    $tno++;
}

for my $ord (0x00 .. 0x7F) {
    $_ = chr($ord);
    my $match = 0;
    if (/[[:ascii:]]/) {
        $match++;
    }
    if (/[[:^ascii:]]/) {
        $match++;
    }
    if ($match == 1) {
        printf qq{ok - $tno "\\x%02X" =~ /[[:ascii:]]/ ($match) $^X $__FILE__\n}, $ord;
    }
    else {
        printf qq{not ok - $tno "\\x%02X" =~ /[[:ascii:]]/ ($match) $^X $__FILE__\n}, $ord;
    }
    $tno++;
}

for my $ord (0x00 .. 0x7F) {
    $_ = chr($ord);
    my $match = 0;
    if (/[[:blank:]]/) {
        $match++;
    }
    if (/[[:^blank:]]/) {
        $match++;
    }
    if ($match == 1) {
        printf qq{ok - $tno "\\x%02X" =~ /[[:blank:]]/ ($match) $^X $__FILE__\n}, $ord;
    }
    else {
        printf qq{not ok - $tno "\\x%02X" =~ /[[:blank:]]/ ($match) $^X $__FILE__\n}, $ord;
    }
    $tno++;
}

for my $ord (0x00 .. 0x7F) {
    $_ = chr($ord);
    my $match = 0;
    if (/[[:cntrl:]]/) {
        $match++;
    }
    if (/[[:^cntrl:]]/) {
        $match++;
    }
    if ($match == 1) {
        printf qq{ok - $tno "\\x%02X" =~ /[[:cntrl:]]/ ($match) $^X $__FILE__\n}, $ord;
    }
    else {
        printf qq{not ok - $tno "\\x%02X" =~ /[[:cntrl:]]/ ($match) $^X $__FILE__\n}, $ord;
    }
    $tno++;
}

for my $ord (0x00 .. 0x7F) {
    $_ = chr($ord);
    my $match = 0;
    if (/[[:digit:]]/) {
        $match++;
    }
    if (/[[:^digit:]]/) {
        $match++;
    }
    if ($match == 1) {
        printf qq{ok - $tno "\\x%02X" =~ /[[:digit:]]/ ($match) $^X $__FILE__\n}, $ord;
    }
    else {
        printf qq{not ok - $tno "\\x%02X" =~ /[[:digit:]]/ ($match) $^X $__FILE__\n}, $ord;
    }
    $tno++;
}

for my $ord (0x00 .. 0x7F) {
    $_ = chr($ord);
    my $match = 0;
    if (/[[:graph:]]/) {
        $match++;
    }
    if (/[[:^graph:]]/) {
        $match++;
    }
    if ($match == 1) {
        printf qq{ok - $tno "\\x%02X" =~ /[[:graph:]]/ ($match) $^X $__FILE__\n}, $ord;
    }
    else {
        printf qq{not ok - $tno "\\x%02X" =~ /[[:graph:]]/ ($match) $^X $__FILE__\n}, $ord;
    }
    $tno++;
}

for my $ord (0x00 .. 0x7F) {
    $_ = chr($ord);
    my $match = 0;
    if (/[[:lower:]]/) {
        $match++;
    }
    if (/[[:^lower:]]/) {
        $match++;
    }
    if ($match == 1) {
        printf qq{ok - $tno "\\x%02X" =~ /[[:lower:]]/ ($match) $^X $__FILE__\n}, $ord;
    }
    else {
        printf qq{not ok - $tno "\\x%02X" =~ /[[:lower:]]/ ($match) $^X $__FILE__\n}, $ord;
    }
    $tno++;
}

for my $ord (0x00 .. 0x7F) {
    $_ = chr($ord);
    my $match = 0;
    if (/[[:print:]]/) {
        $match++;
    }
    if (/[[:^print:]]/) {
        $match++;
    }
    if ($match == 1) {
        printf qq{ok - $tno "\\x%02X" =~ /[[:print:]]/ ($match) $^X $__FILE__\n}, $ord;
    }
    else {
        printf qq{not ok - $tno "\\x%02X" =~ /[[:print:]]/ ($match) $^X $__FILE__\n}, $ord;
    }
    $tno++;
}

for my $ord (0x00 .. 0x7F) {
    $_ = chr($ord);
    my $match = 0;
    if (/[[:punct:]]/) {
        $match++;
    }
    if (/[[:^punct:]]/) {
        $match++;
    }
    if ($match == 1) {
        printf qq{ok - $tno "\\x%02X" =~ /[[:punct:]]/ ($match) $^X $__FILE__\n}, $ord;
    }
    else {
        printf qq{not ok - $tno "\\x%02X" =~ /[[:punct:]]/ ($match) $^X $__FILE__\n}, $ord;
    }
    $tno++;
}

for my $ord (0x00 .. 0x7F) {
    $_ = chr($ord);
    my $match = 0;
    if (/[[:space:]]/) {
        $match++;
    }
    if (/[[:^space:]]/) {
        $match++;
    }
    if ($match == 1) {
        printf qq{ok - $tno "\\x%02X" =~ /[[:space:]]/ ($match) $^X $__FILE__\n}, $ord;
    }
    else {
        printf qq{not ok - $tno "\\x%02X" =~ /[[:space:]]/ ($match) $^X $__FILE__\n}, $ord;
    }
    $tno++;
}

for my $ord (0x00 .. 0x7F) {
    $_ = chr($ord);
    my $match = 0;
    if (/[[:upper:]]/) {
        $match++;
    }
    if (/[[:^upper:]]/) {
        $match++;
    }
    if ($match == 1) {
        printf qq{ok - $tno "\\x%02X" =~ /[[:upper:]]/ ($match) $^X $__FILE__\n}, $ord;
    }
    else {
        printf qq{not ok - $tno "\\x%02X" =~ /[[:upper:]]/ ($match) $^X $__FILE__\n}, $ord;
    }
    $tno++;
}

for my $ord (0x00 .. 0x7F) {
    $_ = chr($ord);
    my $match = 0;
    if (/[[:word:]]/) {
        $match++;
    }
    if (/[[:^word:]]/) {
        $match++;
    }
    if ($match == 1) {
        printf qq{ok - $tno "\\x%02X" =~ /[[:word:]]/ ($match) $^X $__FILE__\n}, $ord;
    }
    else {
        printf qq{not ok - $tno "\\x%02X" =~ /[[:word:]]/ ($match) $^X $__FILE__\n}, $ord;
    }
    $tno++;
}

for my $ord (0x00 .. 0x7F) {
    $_ = chr($ord);
    my $match = 0;
    if (/[[:xdigit:]]/) {
        $match++;
    }
    if (/[[:^xdigit:]]/) {
        $match++;
    }
    if ($match == 1) {
        printf qq{ok - $tno "\\x%02X" =~ /[[:xdigit:]]/ ($match) $^X $__FILE__\n}, $ord;
    }
    else {
        printf qq{not ok - $tno "\\x%02X" =~ /[[:xdigit:]]/ ($match) $^X $__FILE__\n}, $ord;
    }
    $tno++;
}

__END__
