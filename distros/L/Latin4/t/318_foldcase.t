# encoding: Latin4
# This file is encoded in Latin-4.
die "This file is not encoded in Latin-4.\n" if q{‚ } ne "\x82\xa0";

use Latin4;
print "1..30\n";

if (fc('ABCDEF') eq fc('abcdef')) {
    print qq{ok - 1 fc('ABCDEF') eq fc('abcdef')\n};
}
else {
    print qq{not ok - 1 fc('ABCDEF') eq fc('abcdef')\n};
}

if ("\FABCDEF\E" eq "\Fabcdef\E") {
    print qq{ok - 2 "\\FABCDEF\\E" eq "\\Fabcdef\\E"\n};
}
else {
    print qq{not ok - 2 "\\FABCDEF\\E" eq "\\Fabcdef\\E"\n};
}

if ("\FABCDEF\E" =~ /\Fabcdef\E/) {
    print qq{ok - 3 "\\FABCDEF\\E" =~ /\\Fabcdef\\E/\n};
}
else {
    print qq{not ok - 3 "\\FABCDEF\\E" =~ /\\Fabcdef\\E/\n};
}

if ("\Fabcdef\E" =~ /\FABCDEF\E/) {
    print qq{ok - 4 "\\Fabcdef\\E" =~ /\\FABCDEF\\E/\n};
}
else {
    print qq{not ok - 4 "\\Fabcdef\\E" =~ /\\FABCDEF\\E/\n};
}

if ("\FABCDEF\E" =~ /\Fabcdef\E/i) {
    print qq{ok - 5 "\\FABCDEF\\E" =~ /\\Fabcdef\\E/i\n};
}
else {
    print qq{not ok - 5 "\\FABCDEF\\E" =~ /\\Fabcdef\\E/i\n};
}

if ("\Fabcdef\E" =~ /\FABCDEF\E/i) {
    print qq{ok - 6 "\\Fabcdef\\E" =~ /\\FABCDEF\\E/i\n};
}
else {
    print qq{not ok - 6 "\\Fabcdef\\E" =~ /\\FABCDEF\\E/i\n};
}

my $var = 'abcdef';
if ("\FABCDEF\E" =~ /\F$var\E/i) {
    print qq{ok - 7 "\\FABCDEF\\E" =~ /\\F\$var\\E/i\n};
}
else {
    print qq{not ok - 7 "\\FABCDEF\\E" =~ /\\F\$var\\E/i\n};
}

$var = 'ABCDEF';
if ("\Fabcdef\E" =~ /\F$var\E/i) {
    print qq{ok - 8 "\\Fabcdef\\E" =~ /\\F\$var\\E/i\n};
}
else {
    print qq{not ok - 8 "\\Fabcdef\\E" =~ /\\F\$var\\E/i\n};
}

my %fc = ();
@fc{qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)} =
    qw(a b c d e f g h i j k l m n o p q r s t u v w x y z);
%fc = (%fc,
    "\xA1" => "\xB1",     # LATIN CAPITAL LETTER A WITH OGONEK --> LATIN SMALL LETTER A WITH OGONEK
    "\xA3" => "\xB3",     # LATIN CAPITAL LETTER R WITH CEDILLA --> LATIN SMALL LETTER R WITH CEDILLA
    "\xA5" => "\xB5",     # LATIN CAPITAL LETTER I WITH TILDE --> LATIN SMALL LETTER I WITH TILDE
    "\xA6" => "\xB6",     # LATIN CAPITAL LETTER L WITH CEDILLA --> LATIN SMALL LETTER L WITH CEDILLA
    "\xA9" => "\xB9",     # LATIN CAPITAL LETTER S WITH CARON --> LATIN SMALL LETTER S WITH CARON
    "\xAA" => "\xBA",     # LATIN CAPITAL LETTER E WITH MACRON --> LATIN SMALL LETTER E WITH MACRON
    "\xAB" => "\xBB",     # LATIN CAPITAL LETTER G WITH CEDILLA --> LATIN SMALL LETTER G WITH CEDILLA
    "\xAC" => "\xBC",     # LATIN CAPITAL LETTER T WITH STROKE --> LATIN SMALL LETTER T WITH STROKE
    "\xAE" => "\xBE",     # LATIN CAPITAL LETTER Z WITH CARON --> LATIN SMALL LETTER Z WITH CARON
    "\xBD" => "\xBF",     # LATIN CAPITAL LETTER ENG --> LATIN SMALL LETTER ENG
    "\xC0" => "\xE0",     # LATIN CAPITAL LETTER A WITH MACRON --> LATIN SMALL LETTER A WITH MACRON
    "\xC1" => "\xE1",     # LATIN CAPITAL LETTER A WITH ACUTE --> LATIN SMALL LETTER A WITH ACUTE
    "\xC2" => "\xE2",     # LATIN CAPITAL LETTER A WITH CIRCUMFLEX --> LATIN SMALL LETTER A WITH CIRCUMFLEX
    "\xC3" => "\xE3",     # LATIN CAPITAL LETTER A WITH TILDE --> LATIN SMALL LETTER A WITH TILDE
    "\xC4" => "\xE4",     # LATIN CAPITAL LETTER A WITH DIAERESIS --> LATIN SMALL LETTER A WITH DIAERESIS
    "\xC5" => "\xE5",     # LATIN CAPITAL LETTER A WITH RING ABOVE --> LATIN SMALL LETTER A WITH RING ABOVE
    "\xC6" => "\xE6",     # LATIN CAPITAL LETTER AE --> LATIN SMALL LETTER AE
    "\xC7" => "\xE7",     # LATIN CAPITAL LETTER I WITH OGONEK --> LATIN SMALL LETTER I WITH OGONEK
    "\xC8" => "\xE8",     # LATIN CAPITAL LETTER C WITH CARON --> LATIN SMALL LETTER C WITH CARON
    "\xC9" => "\xE9",     # LATIN CAPITAL LETTER E WITH ACUTE --> LATIN SMALL LETTER E WITH ACUTE
    "\xCA" => "\xEA",     # LATIN CAPITAL LETTER E WITH OGONEK --> LATIN SMALL LETTER E WITH OGONEK
    "\xCB" => "\xEB",     # LATIN CAPITAL LETTER E WITH DIAERESIS --> LATIN SMALL LETTER E WITH DIAERESIS
    "\xCC" => "\xEC",     # LATIN CAPITAL LETTER E WITH DOT ABOVE --> LATIN SMALL LETTER E WITH DOT ABOVE
    "\xCD" => "\xED",     # LATIN CAPITAL LETTER I WITH ACUTE --> LATIN SMALL LETTER I WITH ACUTE
    "\xCE" => "\xEE",     # LATIN CAPITAL LETTER I WITH CIRCUMFLEX --> LATIN SMALL LETTER I WITH CIRCUMFLEX
    "\xCF" => "\xEF",     # LATIN CAPITAL LETTER I WITH MACRON --> LATIN SMALL LETTER I WITH MACRON
    "\xD0" => "\xF0",     # LATIN CAPITAL LETTER D WITH STROKE --> LATIN SMALL LETTER D WITH STROKE
    "\xD1" => "\xF1",     # LATIN CAPITAL LETTER N WITH CEDILLA --> LATIN SMALL LETTER N WITH CEDILLA
    "\xD2" => "\xF2",     # LATIN CAPITAL LETTER O WITH MACRON --> LATIN SMALL LETTER O WITH MACRON
    "\xD3" => "\xF3",     # LATIN CAPITAL LETTER K WITH CEDILLA --> LATIN SMALL LETTER K WITH CEDILLA
    "\xD4" => "\xF4",     # LATIN CAPITAL LETTER O WITH CIRCUMFLEX --> LATIN SMALL LETTER O WITH CIRCUMFLEX
    "\xD5" => "\xF5",     # LATIN CAPITAL LETTER O WITH TILDE --> LATIN SMALL LETTER O WITH TILDE
    "\xD6" => "\xF6",     # LATIN CAPITAL LETTER O WITH DIAERESIS --> LATIN SMALL LETTER O WITH DIAERESIS
    "\xD8" => "\xF8",     # LATIN CAPITAL LETTER O WITH STROKE --> LATIN SMALL LETTER O WITH STROKE
    "\xD9" => "\xF9",     # LATIN CAPITAL LETTER U WITH OGONEK --> LATIN SMALL LETTER U WITH OGONEK
    "\xDA" => "\xFA",     # LATIN CAPITAL LETTER U WITH ACUTE --> LATIN SMALL LETTER U WITH ACUTE
    "\xDB" => "\xFB",     # LATIN CAPITAL LETTER U WITH CIRCUMFLEX --> LATIN SMALL LETTER U WITH CIRCUMFLEX
    "\xDC" => "\xFC",     # LATIN CAPITAL LETTER U WITH DIAERESIS --> LATIN SMALL LETTER U WITH DIAERESIS
    "\xDD" => "\xFD",     # LATIN CAPITAL LETTER U WITH TILDE --> LATIN SMALL LETTER U WITH TILDE
    "\xDE" => "\xFE",     # LATIN CAPITAL LETTER U WITH MACRON --> LATIN SMALL LETTER U WITH MACRON
    "\xDF" => "\x73\x73", # LATIN SMALL LETTER SHARP S --> LATIN SMALL LETTER S, LATIN SMALL LETTER S
);
my $before_fc = join "\t",               sort keys %fc;
my $after_fc  = join "\t", map {$fc{$_}} sort keys %fc;

if (fc("$before_fc") eq "$after_fc") {
    print qq{ok - 9 fc("\$before_fc") eq "\$after_fc"\n};
}
else {
    print qq{not ok - 9 fc("\$before_fc") eq "\$after_fc"\n};
}

if (fc("$after_fc") eq "$after_fc") {
    print qq{ok - 10 fc("\$after_fc") eq "\$after_fc"\n};
}
else {
    print qq{not ok - 10 fc("\$after_fc") eq "\$after_fc"\n};
}

if (fc("$before_fc") eq fc("$after_fc")) {
    print qq{ok - 11 fc("\$before_fc") eq fc("\$after_fc")\n};
}
else {
    print qq{not ok - 11 fc("\$before_fc") eq fc("\$after_fc")\n};
}

if ("\F$before_fc\E" eq "$after_fc") {
    print qq{ok - 12 "\\F\$before_fc\\E" eq "\$after_fc"\n};
}
else {
    print qq{not ok - 12 "\\F\$before_fc\\E" eq "\$after_fc"\n};
}

if ("\F$after_fc\E" eq "$after_fc") {
    print qq{ok - 13 "\\F\$after_fc\\E" eq "\$after_fc"\n};
}
else {
    print qq{not ok - 13 "\\F\$after_fc\\E" eq "\$after_fc"\n};
}

if ("\F$before_fc\E" eq "\F$after_fc\E") {
    print qq{ok - 14 "\\F\$before_fc\\E" eq "\\F\$after_fc\\E"\n};
}
else {
    print qq{not ok - 14 "\\F\$before_fc\\E" eq "\\F\$after_fc\\E"\n};
}

if ("$after_fc" =~ /\F$before_fc\E/) {
    print qq{ok - 15 "\$after_fc" =~ /\\F\$before_fc\\E/\n};
}
else {
    print qq{not ok - 15 "\$after_fc" =~ /\\F\$before_fc\\E/\n};
}

if ("$after_fc" =~ /\F$after_fc\E/) {
    print qq{ok - 16 "\$after_fc" =~ /\\F\$after_fc\\E/\n};
}
else {
    print qq{not ok - 16 "\$after_fc" =~ /\\F\$after_fc\\E/\n};
}

if ("\F$before_fc\E" =~ /$after_fc/) {
    print qq{ok - 17 "\\F\$before_fc\\E" =~ /\$after_fc/\n};
}
else {
    print qq{not ok - 17 "\\F\$before_fc\\E" =~ /\$after_fc/\n};
}

if ("\F$before_fc\E" =~ /\F$before_fc\E/) {
    print qq{ok - 18 "\\F\$before_fc\\E" =~ /\\F\$before_fc\\E/\n};
}
else {
    print qq{not ok - 18 "\\F\$before_fc\\E" =~ /\\F\$before_fc\\E/\n};
}

if ("\F$before_fc\E" =~ /\F$after_fc\E/) {
    print qq{ok - 19 "\\F\$before_fc\\E" =~ /\\F\$after_fc\\E/\n};
}
else {
    print qq{not ok - 19 "\\F\$before_fc\\E" =~ /\\F\$after_fc\\E/\n};
}

if ("\F$after_fc\E" =~ /$after_fc/) {
    print qq{ok - 20 "\\F\$after_fc\\E" =~ /\$after_fc/\n};
}
else {
    print qq{not ok - 20 "\\F\$after_fc\\E" =~ /\$after_fc/\n};
}

if ("\F$after_fc\E" =~ /\F$before_fc\E/) {
    print qq{ok - 21 "\\F\$after_fc\\E" =~ /\\F\$before_fc\\E/\n};
}
else {
    print qq{not ok - 21 "\\F\$after_fc\\E" =~ /\\F\$before_fc\\E/\n};
}

if ("\F$after_fc\E" =~ /\F$after_fc\E/) {
    print qq{ok - 22 "\\F\$after_fc\\E" =~ /\\F\$after_fc\\E/\n};
}
else {
    print qq{not ok - 22 "\\F\$after_fc\\E" =~ /\\F\$after_fc\\E/\n};
}

if ("$after_fc" =~ /\F$before_fc\E/i) {
    print qq{ok - 23 "\$after_fc" =~ /\\F\$before_fc\\E/i\n};
}
else {
    print qq{not ok - 23 "\$after_fc" =~ /\\F\$before_fc\\E/i\n};
}

if ("$after_fc" =~ /\F$after_fc\E/i) {
    print qq{ok - 24 "\$after_fc" =~ /\\F\$after_fc\\E/i\n};
}
else {
    print qq{not ok - 24 "\$after_fc" =~ /\\F\$after_fc\\E/i\n};
}

if ("\F$before_fc\E" =~ /$after_fc/i) {
    print qq{ok - 25 "\\F\$before_fc\\E" =~ /\$after_fc/i\n};
}
else {
    print qq{not ok - 25 "\\F\$before_fc\\E" =~ /\$after_fc/i\n};
}

if ("\F$before_fc\E" =~ /\F$before_fc\E/i) {
    print qq{ok - 26 "\\F\$before_fc\\E" =~ /\\F\$before_fc\\E/i\n};
}
else {
    print qq{not ok - 26 "\\F\$before_fc\\E" =~ /\\F\$before_fc\\E/i\n};
}

if ("\F$before_fc\E" =~ /\F$after_fc\E/i) {
    print qq{ok - 27 "\\F\$before_fc\\E" =~ /\\F\$after_fc\\E/i\n};
}
else {
    print qq{not ok - 27 "\\F\$before_fc\\E" =~ /\\F\$after_fc\\E/i\n};
}

if ("\F$after_fc\E" =~ /$after_fc/i) {
    print qq{ok - 28 "\\F\$after_fc\\E" =~ /\$after_fc/i\n};
}
else {
    print qq{not ok - 28 "\\F\$after_fc\\E" =~ /\$after_fc/i\n};
}

if ("\F$after_fc\E" =~ /\F$before_fc\E/i) {
    print qq{ok - 29 "\\F\$after_fc\\E" =~ /\\F\$before_fc\\E/i\n};
}
else {
    print qq{not ok - 29 "\\F\$after_fc\\E" =~ /\\F\$before_fc\\E/i\n};
}

if ("\F$after_fc\E" =~ /\F$after_fc\E/i) {
    print qq{ok - 30 "\\F\$after_fc\\E" =~ /\\F\$after_fc\\E/i\n};
}
else {
    print qq{not ok - 30 "\\F\$after_fc\\E" =~ /\\F\$after_fc\\E/i\n};
}

__END__

