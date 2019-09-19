#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use BioX::Seq::Stream;
use FindBin;
use MS::Protein;
use MS::CV qw/:MS/;

chdir $FindBin::Bin;

my $fn = 'corpus/fer.fa';

my $atoms_expected = {
    'N' => 1159,
    'C' => 4368,
    'H' => 6773,
    'O' => 1346,
    'S' => 34
};
my $residues_expected = {
    'C' => 13,
    'F' => 37,
    'W' => 10,
    'T' => 67,
    'E' => 45,
    'R' => 35,
    'S' => 84,
    'D' => 49,
    'K' => 47,
    'Q' => 22,
    'H' => 16,
    'N' => 48,
    'A' => 62,
    'L' => 76,
    'I' => 45,
    'M' => 21,
    'Y' => 41,
    'G' => 72,
    'P' => 48,
    'V' => 57
};

require_ok ("MS::Protein");

ok( my $prot = MS::Protein->new(
    BioX::Seq::Stream->new($fn)->next_seq
), "new()" );

# basics
ok( length($prot->seq) == 895, "seq()" );
ok( sprintf( "%0.2f", $prot->molecular_weight('average') ) == 98148.68, "mw(average)" );
ok( sprintf( "%0.2f", $prot->molecular_weight('mono') )    == 98087.77, "mw(mono)"    );
ok( sprintf( "%0.2f", $prot->aliphatic_index() )           == 78.12,    "AI"          );
ok( sprintf( "%0.3f", $prot->gravy() )                     == -0.257,   "GRAVY"       );
ok( sprintf( "%0.2f", $prot->isoelectric_point() )         == 5.88,     "pI"          );
ok( sprintf( "%0.2f", $prot->charge_at_pH(7) )             == -11.39,   "pH 7"        );
ok( sprintf( "%0.2f", $prot->charge_at_pH(4) )             == 63.76,    "pH 4"        );

my @digest = $prot->digest(enzymes => [MS_TRYPSIN]);
ok( $digest[5] eq 'IWISDVK', "trpytic digest");

# molecular composition
my $atoms = $prot->n_atoms;
for (keys %{$atoms_expected}) {
    ok( $atoms_expected->{$_} eq $atoms->{$_}, "atom $_" );
}
my $resis = $prot->n_residues;
for (keys %{$residues_expected}) {
    ok( $residues_expected->{$_} eq $resis->{$_}, "residue $_" );
}

done_testing();
