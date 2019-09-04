# encoding: Greek
# This file is encoded in Greek.
die "This file is not encoded in Greek.\n" if q{ } ne "\x82\xa0";

use strict;
use Greek;

my $__FILE__ = __FILE__;

my %uc = ();
@uc{qw(a b c d e f g h i j k l m n o p q r s t u v w x y z)} =
    qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z);
%uc = (%uc,
    "\xDC" => "\xB6", # GREEK LETTER ALPHA WITH TONOS
    "\xDD" => "\xB8", # GREEK LETTER EPSILON WITH TONOS
    "\xDE" => "\xB9", # GREEK LETTER ETA WITH TONOS
    "\xDF" => "\xBA", # GREEK LETTER IOTA WITH TONOS
    "\xE1" => "\xC1", # GREEK LETTER ALPHA
    "\xE2" => "\xC2", # GREEK LETTER BETA
    "\xE3" => "\xC3", # GREEK LETTER GAMMA
    "\xE4" => "\xC4", # GREEK LETTER DELTA
    "\xE5" => "\xC5", # GREEK LETTER EPSILON
    "\xE6" => "\xC6", # GREEK LETTER ZETA
    "\xE7" => "\xC7", # GREEK LETTER ETA
    "\xE8" => "\xC8", # GREEK LETTER THETA
    "\xE9" => "\xC9", # GREEK LETTER IOTA
    "\xEA" => "\xCA", # GREEK LETTER KAPPA
    "\xEB" => "\xCB", # GREEK LETTER LAMDA
    "\xEC" => "\xCC", # GREEK LETTER MU
    "\xED" => "\xCD", # GREEK LETTER NU
    "\xEE" => "\xCE", # GREEK LETTER XI
    "\xEF" => "\xCF", # GREEK LETTER OMICRON
    "\xF0" => "\xD0", # GREEK LETTER PI
    "\xF1" => "\xD1", # GREEK LETTER RHO
    "\xF3" => "\xD3", # GREEK LETTER SIGMA
    "\xF4" => "\xD4", # GREEK LETTER TAU
    "\xF5" => "\xD5", # GREEK LETTER UPSILON
    "\xF6" => "\xD6", # GREEK LETTER PHI
    "\xF7" => "\xD7", # GREEK LETTER CHI
    "\xF8" => "\xD8", # GREEK LETTER PSI
    "\xF9" => "\xD9", # GREEK LETTER OMEGA
    "\xFA" => "\xDA", # GREEK LETTER IOTA WITH DIALYTIKA
    "\xFB" => "\xDB", # GREEK LETTER UPSILON WITH DIALYTIKA
    "\xFC" => "\xBC", # GREEK LETTER OMICRON WITH TONOS
    "\xFD" => "\xBE", # GREEK LETTER UPSILON WITH TONOS
    "\xFE" => "\xBF", # GREEK LETTER OMEGA WITH TONOS
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
