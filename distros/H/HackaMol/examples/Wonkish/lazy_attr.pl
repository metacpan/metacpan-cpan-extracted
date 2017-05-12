#!/usr/bin/env perl
#example for showing the laziness of attributes
use Modern::Perl;
use HackaMol;

my $a1 = HackaMol::Atom->new(Z=>80);
print $a1->dump;

say $a1->symbol;

print $a1->dump;

$a1->clear_symbol;

print $a1->dump;

say $a1->symbol;

