#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use Lingua::Guess;
binmode STDOUT, ":utf8";
my $guesser = Lingua::Guess->new ();
my @lines = split (/\n/, <<EOF);
This is a test of the language checker
Verifions que le détecteur de langues marche
Sprawdźmy, czy odgadywacz języków pracuje
EOF
for my $line (@lines) {
    my $guess = $guesser->simple_guess ($line);
    print "'$line' was $guess\n";
}
