#!/usr/bin/env perl
use Modern::Perl;
use WWW::Search;
use Data::Dumper;
use HackaMol::Atom;
use HackaMol::Bond;
use HackaMol::Molecule;
use Math::Vector::Real;

my $search = new WWW::Search('PubChem');

my @ids = qw/6037/;
$search->native_query( \@ids );
my $chem   = $search->next_result;
my $smiles = $chem->{smiles};
my @a      = `obabel -:"$smiles" -oxyz --gen3D`;
chomp @a;

my @atoms = map {
    HackaMol::Atom->new(
        symbol => $_->[0],
        coords => [ V( $_->[1], $_->[2], $_->[3] ) ]
      )
  }
  map  { [split] }
  grep { m/\w+\s+-*\d+.\d+/ } @a;

$atoms[$_]->iatom( $_ + 1 ) foreach 0 .. $#atoms;

my @bonds;

foreach ( my $i = 0 ; $i < @atoms ; $i++ ) {
    my $cov_i = $atoms[$i]->covalent_radius;
    foreach ( my $j = $i + 1 ; $j < @atoms ; $j++ ) {

        my $cov_j = $atoms[$j]->covalent_radius;
        my $dist  = $atoms[$i]->distance( $atoms[$j] );
        push @bonds,
          HackaMol::Bond->new(
            name  => "$i\_$j",
            atoms => [ $atoms[$i], $atoms[$j] ],
          ) if ( $dist <= $cov_i + $cov_j + 0.45 );

    }
}

my $mol = HackaMol::Molecule->new(
    atoms => [@atoms],
    bonds => [@bonds]
);

my @sp3 = grep { $_->bond_count == 4 } @atoms;

print Dumper \@sp3;

say foreach @a;

