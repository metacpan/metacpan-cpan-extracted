#!/usr/bin/env perl
use Modern::Perl;
use YAML::XS;

my %aas = (
    Ala => 'O=C(O)[C@@H](N)C',
    Cys => 'SC[C@H](N)C(O)=O',
    Asp => 'OC(C[C@H](N)C(O)=O)=O',
    Glu => 'O=C(O)[C@@H](N)CCC(O)=O',
    Phe => 'N[C@H](C(O)=O)CC1=CC=CC=C1',
    Gly => 'O=C(O)CN',
    His => 'N[C@@H](CC1=CN=CN1)C(O)=O',
    ILE => 'O=C(O)[C@@H](N)[C@@H](C)CC',
    Lys => 'N[C@H](C(O)=O)CCCCN',
    Leu => 'N[C@@H](CC(C)C)C(O)=O',
    Met => 'OC([C@@H](N)CCSC)=O',
    Asn => 'NC(C[C@H](N)C(O)=O)=O',
    Pro => 'O=C([C@@H]1CCCN1)O',
    Gln => 'OC([C@@H](N)CCC(N)=O)=O',
    Arg => 'O=C(O)[C@@H](N)CCCNC(N)=N',
    Ser => 'OC([C@@H](N)CO)=O',
    Thr => 'N[C@H](C(O)=O)[C@H](O)C',
    Val => 'N[C@H](C(O)=O)C(C)C',
    Trp => 'O=C(O)[C@@H](N)CC1=CNC2=C1C=CC=C2',
    Tyr => 'N[C@@H](CC1=CC=C(O)C=C1)C(O)=O',
);

foreach my $aa ( keys(%aas) ) {

    my $smiles = $aas{$aa};
    my @a      = `obabel -:\"$smiles\" -opdb --gen3D`;
    chomp @a;
    print Dump \@a;

}
