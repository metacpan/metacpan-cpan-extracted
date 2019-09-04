# encoding: Latin8
# This file is encoded in Latin-8.
die "This file is not encoded in Latin-8.\n" if q{‚ } ne "\x82\xa0";

use strict;
use Latin8;

my $__FILE__ = __FILE__;

my %uc = ();
@uc{qw(a b c d e f g h i j k l m n o p q r s t u v w x y z)} =
    qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z);
%uc = (%uc,
    "\xA2" => "\xA1", # LATIN LETTER B WITH DOT ABOVE
    "\xA5" => "\xA4", # LATIN LETTER C WITH DOT ABOVE
    "\xAB" => "\xA6", # LATIN LETTER D WITH DOT ABOVE
    "\xB1" => "\xB0", # LATIN LETTER F WITH DOT ABOVE
    "\xB3" => "\xB2", # LATIN LETTER G WITH DOT ABOVE
    "\xB5" => "\xB4", # LATIN LETTER M WITH DOT ABOVE
    "\xB8" => "\xA8", # LATIN LETTER W WITH GRAVE
    "\xB9" => "\xB7", # LATIN LETTER P WITH DOT ABOVE
    "\xBA" => "\xAA", # LATIN LETTER W WITH ACUTE
    "\xBC" => "\xAC", # LATIN LETTER Y WITH GRAVE
    "\xBE" => "\xBD", # LATIN LETTER W WITH DIAERESIS
    "\xBF" => "\xBB", # LATIN LETTER S WITH DOT ABOVE
    "\xE0" => "\xC0", # LATIN LETTER A WITH GRAVE
    "\xE1" => "\xC1", # LATIN LETTER A WITH ACUTE
    "\xE2" => "\xC2", # LATIN LETTER A WITH CIRCUMFLEX
    "\xE3" => "\xC3", # LATIN LETTER A WITH TILDE
    "\xE4" => "\xC4", # LATIN LETTER A WITH DIAERESIS
    "\xE5" => "\xC5", # LATIN LETTER A WITH RING ABOVE
    "\xE6" => "\xC6", # LATIN LETTER AE
    "\xE7" => "\xC7", # LATIN LETTER C WITH CEDILLA
    "\xE8" => "\xC8", # LATIN LETTER E WITH GRAVE
    "\xE9" => "\xC9", # LATIN LETTER E WITH ACUTE
    "\xEA" => "\xCA", # LATIN LETTER E WITH CIRCUMFLEX
    "\xEB" => "\xCB", # LATIN LETTER E WITH DIAERESIS
    "\xEC" => "\xCC", # LATIN LETTER I WITH GRAVE
    "\xED" => "\xCD", # LATIN LETTER I WITH ACUTE
    "\xEE" => "\xCE", # LATIN LETTER I WITH CIRCUMFLEX
    "\xEF" => "\xCF", # LATIN LETTER I WITH DIAERESIS
    "\xF0" => "\xD0", # LATIN LETTER W WITH CIRCUMFLEX
    "\xF1" => "\xD1", # LATIN LETTER N WITH TILDE
    "\xF2" => "\xD2", # LATIN LETTER O WITH GRAVE
    "\xF3" => "\xD3", # LATIN LETTER O WITH ACUTE
    "\xF4" => "\xD4", # LATIN LETTER O WITH CIRCUMFLEX
    "\xF5" => "\xD5", # LATIN LETTER O WITH TILDE
    "\xF6" => "\xD6", # LATIN LETTER O WITH DIAERESIS
    "\xF7" => "\xD7", # LATIN LETTER T WITH DOT ABOVE
    "\xF8" => "\xD8", # LATIN LETTER O WITH STROKE
    "\xF9" => "\xD9", # LATIN LETTER U WITH GRAVE
    "\xFA" => "\xDA", # LATIN LETTER U WITH ACUTE
    "\xFB" => "\xDB", # LATIN LETTER U WITH CIRCUMFLEX
    "\xFC" => "\xDC", # LATIN LETTER U WITH DIAERESIS
    "\xFD" => "\xDD", # LATIN LETTER Y WITH ACUTE
    "\xFE" => "\xDE", # LATIN LETTER Y WITH CIRCUMFLEX
    "\xFF" => "\xAF", # LATIN LETTER Y WITH DIAERESIS
);

printf("1..%d\n", scalar(keys %uc));

my $tno = 1;
for my $char (sort keys %uc){
    if (uc($char) eq $uc{$char}) {
        printf(qq{ok - $tno uc("\\x%02X") eq "\\x%02X" $^X $__FILE__\n}, ord($char), ord($uc{$char}));
    }
    else {
        printf(qq{not ok - $tno uc("\\x%02X") eq "\\x%02X" $^X $__FILE__\n}, ord($char), ord($uc{$char}));
    }
    $tno++;
}

__END__
