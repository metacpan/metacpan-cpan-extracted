# encoding: KOI8U
# This file is encoded in KOI8-U.
die "This file is not encoded in KOI8-U.\n" if q{‚ } ne "\x82\xa0";

use KOI8U;
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
    "\xB3" => "\xA3",     # CYRILLIC CAPITAL LETTER IO --> CYRILLIC SMALL LETTER IO
    "\xB4" => "\xA4",     # CYRILLIC CAPITAL LETTER UKRAINIAN IE --> CYRILLIC SMALL LETTER UKRAINIAN IE
    "\xB6" => "\xA6",     # CYRILLIC CAPITAL LETTER BYELORUSSIAN-UKRAINIAN I --> CYRILLIC SMALL LETTER BYELORUSSIAN-UKRAINIAN I
    "\xB7" => "\xA7",     # CYRILLIC CAPITAL LETTER YI --> CYRILLIC SMALL LETTER YI
    "\xBD" => "\xAD",     # CYRILLIC CAPITAL LETTER GHE WITH UPTURN --> CYRILLIC SMALL LETTER GHE WITH UPTURN
    "\xE0" => "\xC0",     # CYRILLIC CAPITAL LETTER YU --> CYRILLIC SMALL LETTER YU
    "\xE1" => "\xC1",     # CYRILLIC CAPITAL LETTER A --> CYRILLIC SMALL LETTER A
    "\xE2" => "\xC2",     # CYRILLIC CAPITAL LETTER BE --> CYRILLIC SMALL LETTER BE
    "\xE3" => "\xC3",     # CYRILLIC CAPITAL LETTER TSE --> CYRILLIC SMALL LETTER TSE
    "\xE4" => "\xC4",     # CYRILLIC CAPITAL LETTER DE --> CYRILLIC SMALL LETTER DE
    "\xE5" => "\xC5",     # CYRILLIC CAPITAL LETTER IE --> CYRILLIC SMALL LETTER IE
    "\xE6" => "\xC6",     # CYRILLIC CAPITAL LETTER EF --> CYRILLIC SMALL LETTER EF
    "\xE7" => "\xC7",     # CYRILLIC CAPITAL LETTER GHE --> CYRILLIC SMALL LETTER GHE
    "\xE8" => "\xC8",     # CYRILLIC CAPITAL LETTER HA --> CYRILLIC SMALL LETTER HA
    "\xE9" => "\xC9",     # CYRILLIC CAPITAL LETTER I --> CYRILLIC SMALL LETTER I
    "\xEA" => "\xCA",     # CYRILLIC CAPITAL LETTER SHORT I --> CYRILLIC SMALL LETTER SHORT I
    "\xEB" => "\xCB",     # CYRILLIC CAPITAL LETTER KA --> CYRILLIC SMALL LETTER KA
    "\xEC" => "\xCC",     # CYRILLIC CAPITAL LETTER EL --> CYRILLIC SMALL LETTER EL
    "\xED" => "\xCD",     # CYRILLIC CAPITAL LETTER EM --> CYRILLIC SMALL LETTER EM
    "\xEE" => "\xCE",     # CYRILLIC CAPITAL LETTER EN --> CYRILLIC SMALL LETTER EN
    "\xEF" => "\xCF",     # CYRILLIC CAPITAL LETTER O --> CYRILLIC SMALL LETTER O
    "\xF0" => "\xD0",     # CYRILLIC CAPITAL LETTER PE --> CYRILLIC SMALL LETTER PE
    "\xF1" => "\xD1",     # CYRILLIC CAPITAL LETTER YA --> CYRILLIC SMALL LETTER YA
    "\xF2" => "\xD2",     # CYRILLIC CAPITAL LETTER ER --> CYRILLIC SMALL LETTER ER
    "\xF3" => "\xD3",     # CYRILLIC CAPITAL LETTER ES --> CYRILLIC SMALL LETTER ES
    "\xF4" => "\xD4",     # CYRILLIC CAPITAL LETTER TE --> CYRILLIC SMALL LETTER TE
    "\xF5" => "\xD5",     # CYRILLIC CAPITAL LETTER U --> CYRILLIC SMALL LETTER U
    "\xF6" => "\xD6",     # CYRILLIC CAPITAL LETTER ZHE --> CYRILLIC SMALL LETTER ZHE
    "\xF7" => "\xD7",     # CYRILLIC CAPITAL LETTER VE --> CYRILLIC SMALL LETTER VE
    "\xF8" => "\xD8",     # CYRILLIC CAPITAL LETTER SOFT SIGN --> CYRILLIC SMALL LETTER SOFT SIGN
    "\xF9" => "\xD9",     # CYRILLIC CAPITAL LETTER YERU --> CYRILLIC SMALL LETTER YERU
    "\xFA" => "\xDA",     # CYRILLIC CAPITAL LETTER ZE --> CYRILLIC SMALL LETTER ZE
    "\xFB" => "\xDB",     # CYRILLIC CAPITAL LETTER SHA --> CYRILLIC SMALL LETTER SHA
    "\xFC" => "\xDC",     # CYRILLIC CAPITAL LETTER E --> CYRILLIC SMALL LETTER E
    "\xFD" => "\xDD",     # CYRILLIC CAPITAL LETTER SHCHA --> CYRILLIC SMALL LETTER SHCHA
    "\xFE" => "\xDE",     # CYRILLIC CAPITAL LETTER CHE --> CYRILLIC SMALL LETTER CHE
    "\xFF" => "\xDF",     # CYRILLIC CAPITAL LETTER HARD SIGN --> CYRILLIC SMALL LETTER HARD SIGN
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

