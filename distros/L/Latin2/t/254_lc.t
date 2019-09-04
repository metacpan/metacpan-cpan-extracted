# encoding: Latin2
# This file is encoded in Latin-2.
die "This file is not encoded in Latin-2.\n" if q{ } ne "\x82\xa0";

use strict;
use Latin2;

my $__FILE__ = __FILE__;

my %lc = ();
@lc{qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)} =
    qw(a b c d e f g h i j k l m n o p q r s t u v w x y z);
%lc = (%lc,
    "\xA1" => "\xB1", # LATIN LETTER A WITH OGONEK
    "\xA3" => "\xB3", # LATIN LETTER L WITH STROKE
    "\xA5" => "\xB5", # LATIN LETTER L WITH CARON
    "\xA6" => "\xB6", # LATIN LETTER S WITH ACUTE
    "\xA9" => "\xB9", # LATIN LETTER S WITH CARON
    "\xAA" => "\xBA", # LATIN LETTER S WITH CEDILLA
    "\xAB" => "\xBB", # LATIN LETTER T WITH CARON
    "\xAC" => "\xBC", # LATIN LETTER Z WITH ACUTE
    "\xAE" => "\xBE", # LATIN LETTER Z WITH CARON
    "\xAF" => "\xBF", # LATIN LETTER Z WITH DOT ABOVE
    "\xC0" => "\xE0", # LATIN LETTER R WITH ACUTE
    "\xC1" => "\xE1", # LATIN LETTER A WITH ACUTE
    "\xC2" => "\xE2", # LATIN LETTER A WITH CIRCUMFLEX
    "\xC3" => "\xE3", # LATIN LETTER A WITH BREVE
    "\xC4" => "\xE4", # LATIN LETTER A WITH DIAERESIS
    "\xC5" => "\xE5", # LATIN LETTER L WITH ACUTE
    "\xC6" => "\xE6", # LATIN LETTER C WITH ACUTE
    "\xC7" => "\xE7", # LATIN LETTER C WITH CEDILLA
    "\xC8" => "\xE8", # LATIN LETTER C WITH CARON
    "\xC9" => "\xE9", # LATIN LETTER E WITH ACUTE
    "\xCA" => "\xEA", # LATIN LETTER E WITH OGONEK
    "\xCB" => "\xEB", # LATIN LETTER E WITH DIAERESIS
    "\xCC" => "\xEC", # LATIN LETTER E WITH CARON
    "\xCD" => "\xED", # LATIN LETTER I WITH ACUTE
    "\xCE" => "\xEE", # LATIN LETTER I WITH CIRCUMFLEX
    "\xCF" => "\xEF", # LATIN LETTER D WITH CARON
    "\xD0" => "\xF0", # LATIN LETTER D WITH STROKE
    "\xD1" => "\xF1", # LATIN LETTER N WITH ACUTE
    "\xD2" => "\xF2", # LATIN LETTER N WITH CARON
    "\xD3" => "\xF3", # LATIN LETTER O WITH ACUTE
    "\xD4" => "\xF4", # LATIN LETTER O WITH CIRCUMFLEX
    "\xD5" => "\xF5", # LATIN LETTER O WITH DOUBLE ACUTE
    "\xD6" => "\xF6", # LATIN LETTER O WITH DIAERESIS
    "\xD8" => "\xF8", # LATIN LETTER R WITH CARON
    "\xD9" => "\xF9", # LATIN LETTER U WITH RING ABOVE
    "\xDA" => "\xFA", # LATIN LETTER U WITH ACUTE
    "\xDB" => "\xFB", # LATIN LETTER U WITH DOUBLE ACUTE
    "\xDC" => "\xFC", # LATIN LETTER U WITH DIAERESIS
    "\xDD" => "\xFD", # LATIN LETTER Y WITH ACUTE
    "\xDE" => "\xFE", # LATIN LETTER T WITH CEDILLA
);

printf("1..%d\n", scalar(keys %lc));

my $tno = 1;
for my $char (sort keys %lc){
    if (lc($char) eq $lc{$char}) {
        printf(qq{ok - $tno lc("\\x%02X") eq "\\x%02X" $^X $__FILE__\n}, ord($char), ord($lc{$char}));
    }
    else {
        printf(qq{not ok - $tno lc("\\x%02X") eq "\\x%02X" $^X $__FILE__\n}, ord($char), ord($lc{$char}));
    }
    $tno++;
}

__END__
