# encoding: KOI8R
# This file is encoded in KOI8-R.
die "This file is not encoded in KOI8-R.\n" if q{‚ } ne "\x82\xa0";

use strict;
use KOI8R;

my $__FILE__ = __FILE__;

my %uc = ();
@uc{qw(a b c d e f g h i j k l m n o p q r s t u v w x y z)} =
    qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z);
%uc = (%uc,
    "\xA3" => "\xB3", # CYRILLIC LETTER IO
    "\xC0" => "\xE0", # CYRILLIC LETTER IU
    "\xC1" => "\xE1", # CYRILLIC LETTER A
    "\xC2" => "\xE2", # CYRILLIC LETTER BE
    "\xC3" => "\xE3", # CYRILLIC LETTER TSE
    "\xC4" => "\xE4", # CYRILLIC LETTER DE
    "\xC5" => "\xE5", # CYRILLIC LETTER IE
    "\xC6" => "\xE6", # CYRILLIC LETTER EF
    "\xC7" => "\xE7", # CYRILLIC LETTER GE
    "\xC8" => "\xE8", # CYRILLIC LETTER KHA
    "\xC9" => "\xE9", # CYRILLIC LETTER II
    "\xCA" => "\xEA", # CYRILLIC LETTER SHORT II
    "\xCB" => "\xEB", # CYRILLIC LETTER KA
    "\xCC" => "\xEC", # CYRILLIC LETTER EL
    "\xCD" => "\xED", # CYRILLIC LETTER EM
    "\xCE" => "\xEE", # CYRILLIC LETTER EN
    "\xCF" => "\xEF", # CYRILLIC LETTER O
    "\xD0" => "\xF0", # CYRILLIC LETTER PE
    "\xD1" => "\xF1", # CYRILLIC LETTER IA
    "\xD2" => "\xF2", # CYRILLIC LETTER ER
    "\xD3" => "\xF3", # CYRILLIC LETTER ES
    "\xD4" => "\xF4", # CYRILLIC LETTER TE
    "\xD5" => "\xF5", # CYRILLIC LETTER U
    "\xD6" => "\xF6", # CYRILLIC LETTER ZHE
    "\xD7" => "\xF7", # CYRILLIC LETTER VE
    "\xD8" => "\xF8", # CYRILLIC LETTER SOFT SIGN
    "\xD9" => "\xF9", # CYRILLIC LETTER YERI
    "\xDA" => "\xFA", # CYRILLIC LETTER ZE
    "\xDB" => "\xFB", # CYRILLIC LETTER SHA
    "\xDC" => "\xFC", # CYRILLIC LETTER REVERSED E
    "\xDD" => "\xFD", # CYRILLIC LETTER SHCHA
    "\xDE" => "\xFE", # CYRILLIC LETTER CHE
    "\xDF" => "\xFF", # CYRILLIC LETTER HARD SIGN
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
