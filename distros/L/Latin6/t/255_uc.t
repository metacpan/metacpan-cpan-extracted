# encoding: Latin6
# This file is encoded in Latin-6.
die "This file is not encoded in Latin-6.\n" if q{‚ } ne "\x82\xa0";

use strict;
use Latin6;

my $__FILE__ = __FILE__;

my %uc = ();
@uc{qw(a b c d e f g h i j k l m n o p q r s t u v w x y z)} =
    qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z);
%uc = (%uc,
    "\xB1" => "\xA1", # LATIN LETTER A WITH OGONEK
    "\xB2" => "\xA2", # LATIN LETTER E WITH MACRON
    "\xB3" => "\xA3", # LATIN LETTER G WITH CEDILLA
    "\xB4" => "\xA4", # LATIN LETTER I WITH MACRON
    "\xB5" => "\xA5", # LATIN LETTER I WITH TILDE
    "\xB6" => "\xA6", # LATIN LETTER K WITH CEDILLA
    "\xB8" => "\xA8", # LATIN LETTER L WITH CEDILLA
    "\xB9" => "\xA9", # LATIN LETTER D WITH STROKE
    "\xBA" => "\xAA", # LATIN LETTER S WITH CARON
    "\xBB" => "\xAB", # LATIN LETTER T WITH STROKE
    "\xBC" => "\xAC", # LATIN LETTER Z WITH CARON
    "\xBE" => "\xAE", # LATIN LETTER U WITH MACRON
    "\xBF" => "\xAF", # LATIN LETTER ENG
    "\xE0" => "\xC0", # LATIN LETTER A WITH MACRON
    "\xE1" => "\xC1", # LATIN LETTER A WITH ACUTE
    "\xE2" => "\xC2", # LATIN LETTER A WITH CIRCUMFLEX
    "\xE3" => "\xC3", # LATIN LETTER A WITH TILDE
    "\xE4" => "\xC4", # LATIN LETTER A WITH DIAERESIS
    "\xE5" => "\xC5", # LATIN LETTER A WITH RING ABOVE
    "\xE6" => "\xC6", # LATIN LETTER AE
    "\xE7" => "\xC7", # LATIN LETTER I WITH OGONEK
    "\xE8" => "\xC8", # LATIN LETTER C WITH CARON
    "\xE9" => "\xC9", # LATIN LETTER E WITH ACUTE
    "\xEA" => "\xCA", # LATIN LETTER E WITH OGONEK
    "\xEB" => "\xCB", # LATIN LETTER E WITH DIAERESIS
    "\xEC" => "\xCC", # LATIN LETTER E WITH DOT ABOVE
    "\xED" => "\xCD", # LATIN LETTER I WITH ACUTE
    "\xEE" => "\xCE", # LATIN LETTER I WITH CIRCUMFLEX
    "\xEF" => "\xCF", # LATIN LETTER I WITH DIAERESIS
    "\xF0" => "\xD0", # LATIN LETTER ETH (Icelandic)
    "\xF1" => "\xD1", # LATIN LETTER N WITH CEDILLA
    "\xF2" => "\xD2", # LATIN LETTER O WITH MACRON
    "\xF3" => "\xD3", # LATIN LETTER O WITH ACUTE
    "\xF4" => "\xD4", # LATIN LETTER O WITH CIRCUMFLEX
    "\xF5" => "\xD5", # LATIN LETTER O WITH TILDE
    "\xF6" => "\xD6", # LATIN LETTER O WITH DIAERESIS
    "\xF7" => "\xD7", # LATIN LETTER U WITH TILDE
    "\xF8" => "\xD8", # LATIN LETTER O WITH STROKE
    "\xF9" => "\xD9", # LATIN LETTER U WITH OGONEK
    "\xFA" => "\xDA", # LATIN LETTER U WITH ACUTE
    "\xFB" => "\xDB", # LATIN LETTER U WITH CIRCUMFLEX
    "\xFC" => "\xDC", # LATIN LETTER U WITH DIAERESIS
    "\xFD" => "\xDD", # LATIN LETTER Y WITH ACUTE
    "\xFE" => "\xDE", # LATIN LETTER THORN (Icelandic)
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
