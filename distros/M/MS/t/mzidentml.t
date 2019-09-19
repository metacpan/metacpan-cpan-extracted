#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use FindBin;
use MS::Reader::MzIdentML;

chdir $FindBin::Bin;

require_ok ("MS::Reader::MzIdentML");

# check that compressed and uncompressed FHs return identical results
my $fn = 'corpus/test3.mzid.gz';

ok (my $p = MS::Reader::MzIdentML->new($fn), "created parser object");

ok ($p->n_ident_lists == 2, "n_ident_lists()");

ok ($p->raw_file('LCMALDI_spectra') eq
    'proteinscape://www.medizinisches-proteom-center.de/PSServer/Project/Sample/Separation_1D_LC/Fraction_X',
    "raw_file()");

ok (my $g = $p->next_protein_group, "next_protein_group()");
ok ($g->id eq 'group1', "id()");
my $i = 1;
++$i while ( $g = $p->next_protein_group );
ok ($i == 7, "next_protein_group() 2");

$p->goto_ident_list(1);

ok (my $r = $p->next_spectrum_result, "next_spectrum_result()");
ok ($r->id eq 'Mas_spec2b', "id()");
ok( ! defined $r->name, "name() not defined in file" );
ok( $r->spectrum_id eq 'databasekey=2',  "spectrum_id()" );
my $pe_id = $r->hits()->[0]->{PeptideEvidenceRef}->{peptideEvidence_ref};
ok( $pe_id eq 'PE1_Mas_spec2b_pep1', "hits()" );
my $pe = $p->fetch_peptideevidence_by_id($pe_id);
ok( $pe->id eq 'PE1_Mas_spec2b_pep1', "PE ID()" );
ok( $pe->is_decoy eq 'false', "is_decoy()" );
ok( $pe->peptide_id eq 'prot5_pep1', "peptide_id()" );
my $pep = $p->fetch_peptide_by_id($pe->peptide_id);
ok( $pep->seq eq 'DGHNLISLLEVLSGDSLPR', "peptide seq()" );

$i = 1;
while (my $r = $p->next_spectrum_result) {
    ++$i;
}
ok ($i == 9, "next_spectrum_result() 2");

done_testing();
