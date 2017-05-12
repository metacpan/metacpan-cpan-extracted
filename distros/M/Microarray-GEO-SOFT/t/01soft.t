use strict;
use Test::More tests => 86;
use FindBin qw($Bin);
use File::Basename;
use List::Vectorize qw(!table);
use Data::Dumper;
my $dir = $Bin;

use Microarray::GEO::SOFT;

my $microarray = Microarray::GEO::SOFT->new;
is($microarray->soft_dir, '.tmp_soft');

$microarray = Microarray::GEO::SOFT->new(tmp_dir => "tmp");
is($microarray->soft_dir, 'tmp');
rmdir($microarray->soft_dir);

is(Microarray::GEO::SOFT::_check_type("$dir/../extdata/GSE10626_family.soft"), "SERIES");
is(Microarray::GEO::SOFT::_check_type("$dir/../extdata/GDS3718.soft"), "DATASET");
is(Microarray::GEO::SOFT::_check_type("$dir/../extdata/GPL1261.annot"), "PLATFORM");

# test gse file
$microarray = Microarray::GEO::SOFT->new(file => "$dir/../extdata/GSE10626_family.soft");
my $gse = $microarray->parse;
is(ref($gse), "Microarray::GEO::SOFT::GSE");

is_deeply($gse->meta,
          {accession => 'GSE10626',
           title     => 'MuRF1-dependent regulation of systemic carbohydrate metabolism as revealed from transgenic mouse studies',
           platform  => ['GPL6526'],});
is($gse->accession, 'GSE10626');
is($gse->title, 'MuRF1-dependent regulation of systemic carbohydrate metabolism as revealed from transgenic mouse studies');
is_deeply($gse->platform, ['GPL6526']);

my $gpl_list = $gse->list('GPL');
my $gsm_list = $gse->list('GSM');

is(scalar(@$gpl_list), 1);
is(scalar(@$gsm_list), 4);

is(ref($gpl_list->[0]), 'Microarray::GEO::SOFT::GPL');
is(ref($gsm_list->[0]), 'Microarray::GEO::SOFT::GSM');
is(ref($gsm_list->[1]), 'Microarray::GEO::SOFT::GSM');
is(ref($gsm_list->[2]), 'Microarray::GEO::SOFT::GSM');
is(ref($gsm_list->[3]), 'Microarray::GEO::SOFT::GSM');

# test GPL part in GSE
is_deeply($gpl_list->[0]->meta,
          {accession => 'GPL6526',
		   title     => '[Mouse4302_Mm_UG] Affymetrix GeneChip Mouse Genome 430 2.0 Array [Brainarray Version 9]',
		   platform  => 'GPL6526',});
is($gpl_list->[0]->accession, 'GPL6526');
is($gpl_list->[0]->title, '[Mouse4302_Mm_UG] Affymetrix GeneChip Mouse Genome 430 2.0 Array [Brainarray Version 9]');
is($gpl_list->[0]->platform, 'GPL6526');
is_deeply($gpl_list->[0]->rownames, ['Mm.100043_at', 'Mm.100065_at', 'Mm.100068_at', 'Mm.100084_at', 'Mm.100112_at', 'Mm.100116_at', 'Mm.100117_at', 'Mm.100125_at', 'Mm.100144_at', 'Mm.100163_at']);
is_deeply($gpl_list->[0]->colnames, ['UniGeneID', 'GeneName', 'GeneSymbol', 'EnsemblID', 'EntrezID', 'SPOT_ID']);
is($gpl_list->[0]->matrix->[0]->[0], 'Mm.100043');
is($gpl_list->[0]->matrix->[2]->[2], 'Amot');
is($gpl_list->[0]->matrix->[9]->[4], '23919');
           
# test GSM parts in GSE
is($gsm_list->[0]->title, 'MuRF1 transgene_1');
is($gsm_list->[0]->accession, 'GSM267838');
is($gsm_list->[0]->platform, 'GPL6526');
is($gsm_list->[1]->title, 'MuRF1 transgene_2');
is($gsm_list->[1]->accession, 'GSM267839');
is($gsm_list->[1]->platform, 'GPL6526');
is($gsm_list->[2]->title, 'WT1');
is($gsm_list->[2]->accession, 'GSM267840');
is($gsm_list->[2]->platform, 'GPL6526');
is($gsm_list->[3]->title, 'WT2');
is($gsm_list->[3]->accession, 'GSM267841');
is($gsm_list->[3]->platform, 'GPL6526');


my $gds_list = $gse->merge;
is(scalar(@$gds_list), 1);
is(ref($gds_list->[0]), 'Microarray::GEO::SOFT::GDS');
is($gds_list->[0]->platform, $gpl_list->[0]->accession);
my $g = $gds_list->[0];
is_deeply($g->meta, 
          {accession  => 'GDS_merge_1_from_GSE10626',
		   title      => 'merged from GSE10626 under GPL6526',
		   platform   => 'GPL6526',});
is($g->accession, 'GDS_merge_1_from_GSE10626');
is($g->title, 'merged from GSE10626 under GPL6526');
is($g->platform, 'GPL6526'); 
is_deeply($g->rownames, ['Mm.100043_at', 'Mm.100065_at', 'Mm.100068_at', 'Mm.100084_at', 'Mm.100112_at', 'Mm.100116_at', 'Mm.100117_at', 'Mm.100125_at', 'Mm.100144_at', 'Mm.100163_at']);
is_deeply($g->colnames, ['GSM267838', 'GSM267839', 'GSM267840', 'GSM267841']);
is_deeply($g->colnames_explain, ['MuRF1 transgene_1', 'MuRF1 transgene_2', 'WT1', 'WT2']);
is(scalar(@{$g->matrix}), 10);
my $n_col = sum(test($gsm_list, sub {$_[0]->platform eq $g->platform}));
is(scalar(@{$g->matrix->[0]}), $n_col);
is(scalar(@{$g->matrix->[1]}), $n_col);
is(scalar(@{$g->matrix->[2]}), $n_col);
is(scalar(@{$g->matrix->[3]}), $n_col);
is(scalar(@{$g->matrix->[4]}), $n_col);
is(scalar(@{$g->matrix->[5]}), $n_col);
is(scalar(@{$g->matrix->[6]}), $n_col);
is(scalar(@{$g->matrix->[7]}), $n_col);

my $e = $g->id_convert($gpl_list->[0], "GeneSymbol");
is_deeply($e->feature, ['Gckr', '1300012G16Rik', 'Amot', 'St6galnac1', 'Brwd3', 'Zxdc', '5730406M06Rik', 'Sh3bgrl2', 'S100a6', 'Insl5']);
$e = $g->id_convert($gpl_list->[0], qr/genesymbol/i);
is_deeply($e->feature, ['Gckr', '1300012G16Rik', 'Amot', 'St6galnac1', 'Brwd3', 'Zxdc', '5730406M06Rik', 'Sh3bgrl2', 'S100a6', 'Insl5']);

# now the order of probe id in GPL is not the same as the order of probe id in gds
($gpl_list->[0]->{table}->{matrix}->[1], $gpl_list->[0]->{table}->{matrix}->[2]) = ($gpl_list->[0]->{table}->{matrix}->[2], $gpl_list->[0]->{table}->{matrix}->[1]);
($gpl_list->[0]->{table}->{rownames}->[1], $gpl_list->[0]->{table}->{rownames}->[2]) = ($gpl_list->[0]->{table}->{rownames}->[2], $gpl_list->[0]->{table}->{rownames}->[1]);
is_deeply($gpl_list->[0]->rownames, ['Mm.100043_at', 'Mm.100068_at', 'Mm.100065_at', 'Mm.100084_at', 'Mm.100112_at', 'Mm.100116_at', 'Mm.100117_at', 'Mm.100125_at', 'Mm.100144_at', 'Mm.100163_at']);

$e = $g->id_convert($gpl_list->[0], "GeneSymbol");
is(ref($e), 'Microarray::ExprSet');
is_deeply($e->feature, ['Gckr', '1300012G16Rik', 'Amot', 'St6galnac1', 'Brwd3', 'Zxdc', '5730406M06Rik', 'Sh3bgrl2', 'S100a6', 'Insl5']);

# read gds data
undef($microarray);
$microarray = Microarray::GEO::SOFT->new(file => "$dir/../extdata/GDS3718.soft");
my $gds = $microarray->parse;
is(ref($gds), "Microarray::GEO::SOFT::GDS");

is_deeply($gds->meta,
          {accession => 'GDS3718',
		   title     => 'Zinc finger Zbtb20 deficiency effect on the developing hippocampus',
		   platform  => 'GPL1261',});
is($gds->platform, 'GPL1261');
is($gds->accession, 'GDS3718');
is($gds->title, 'Zinc finger Zbtb20 deficiency effect on the developing hippocampus');

is_deeply($gds->rownames, ['1415670_at', '1415671_at', '1415672_at', '1415673_at', '1415674_a_at', '1415675_at', '1415676_a_at', '1415677_at', '1415678_at', '1415679_at']);
is_deeply($gds->colnames, ['GSM506899', 'GSM506900', 'GSM506901', 'GSM506902']);
is_deeply($gds->colnames_explain, ['wildtype P2 hippocampus rep1; src: P2 control hippocampus', 'wildtype P2 hippocampus rep2; src: P2 control hippocampus', 'ZBTB20-KO P2 hippocampus rep1; src: P2 knockout hippocampus', 'ZBTB20-KO P2 hippocampus rep2; src: P2 knockout hippocampus']);

# read gpl data
undef($microarray);
$microarray = Microarray::GEO::SOFT->new(file => "$dir/../extdata/GPL1261.annot");
my $gpl = $microarray->parse;
is(ref($gpl), "Microarray::GEO::SOFT::GPL");

is_deeply($gpl->meta,
          {accession => 'GPL1261',
		   title     => '[Mouse430_2] Affymetrix Mouse Genome 430 2.0 Array',
		   platform  => 'GPL1261',});
is($gpl->accession, 'GPL1261');
is($gpl->title, '[Mouse430_2] Affymetrix Mouse Genome 430 2.0 Array');
is($gpl->platform, 'GPL1261');
is_deeply($gpl->rownames, ['1415670_at', '1415671_at', '1415672_at', '1415673_at', '1415674_a_at', '1415675_at', '1415676_a_at', '1415677_at', '1415678_at', '1415679_at']);
is_deeply($gpl->colnames, ['Gene title', 'Gene symbol', 'Gene ID', 'UniGene title', 'UniGene symbol', 'UniGene ID', 'Nucleotide Title', 'GI', 'GenBank Accession', 'Platform_CLONEID', 'Platform_ORF', 'Platform_SPOTID', 'Chromosome location', 'Chromosome annotation', 'GO:Function', 'GO:Process', 'GO:Component', 'GO:Function ID', 'GO:Process ID', 'GO:Component ID']);
is($gpl->matrix->[0]->[0], 'coatomer protein complex, subunit gamma');
is($gpl->matrix->[2]->[2], '57437');
is($gpl->matrix->[9]->[8], 'NM_025498');
       
# convert the gds id
$e = $gds->id_convert($gpl, qr/\bgene[\s_\-]?symbol\b/i);
is(ref($e), 'Microarray::ExprSet');
is_deeply($e->feature, ['Copg', 'Atp6v0d1', 'Golga7', 'Psph', 'Trappc4', 'Dpm2', 'Psmb5', 'Dhrs1', 'Ppm1a', 'Gm12396']);


# reading gds with using identifier
undef($microarray);
$microarray = Microarray::GEO::SOFT->new(file => "$dir/../extdata/GDS3718.soft");
$gds = $microarray->parse(use_identifier => 1);
is(ref($gds), "Microarray::GEO::SOFT::GDS");
is_deeply($gds->rownames, ['Copg', 'Atp6v0d1', 'Golga7', 'Psph', 'Trappc4', 'Dpm2', 'Psmb5', 'Dhrs1', 'Ppm1a', 'Gm12396']);

$e = $gds->soft2exprset;
is(ref($e), 'Microarray::ExprSet');
is_deeply($e->feature, ['Copg', 'Atp6v0d1', 'Golga7', 'Psph', 'Trappc4', 'Dpm2', 'Psmb5', 'Dhrs1', 'Ppm1a', 'Gm12396']);

rmdir($microarray->soft_dir);
