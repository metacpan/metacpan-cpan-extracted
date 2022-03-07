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
    'N' => 1158,
    'C' => 4365,
    'H' => 6766,
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
    'K' => 46,
    'Q' => 22,
    'H' => 16,
    'N' => 48,
    'A' => 63,
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
ok( sprintf( "%0.0f", $prot->molecular_weight('average') ) == 98092, "mw(average)" );
ok( sprintf( "%0.1f", $prot->molecular_weight('mono') )    == 98030.7, "mw(mono)"    );
ok( sprintf( "%0.2f", $prot->aliphatic_index() )           == 78.23,    "AI"          );
ok( sprintf( "%0.3f", $prot->gravy() )                     == -0.250,   "GRAVY"       );
ok( sprintf( "%0.1f", $prot->isoelectric_point() )         == 5.8,     "pI"          );
ok( sprintf( "%0.0f", $prot->charge_at_pH(7) )             == -12,   "pH 7"        );
ok( sprintf( "%0.0f", $prot->charge_at_pH(4) )             == 63,    "pH 4"        );

my @digest = $prot->digest(enzymes => [MS_TRYPSIN]);
ok( $digest[4] eq 'IWISDVK', "trpytic digest");

@digest = $prot->digest(
    enzymes => [MS_TRYPSIN],
    missed  => 1,
    nme     => 1,
    min_len => 6,
);
ok( $digest[3] eq 'AITEGRFR', "trpytic digest NME");
ok( scalar(@digest) == 118, 'tryptic digest n frags' );

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
