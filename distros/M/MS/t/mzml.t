#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use FindBin;
use MS::Reader::MzML;
use MS::CV qw/:MS/;

chdir $FindBin::Bin;

require_ok ("MS::Reader::MzML");

my $fn    = 'corpus/test.mzML.gz';
my $fn_np = 'corpus/test.np.mzML.gz';

ok (my $p = MS::Reader::MzML->new($fn), "created parser object");

ok ($p->id eq 'Medicago_TMT_POOL1_2ug', "id()");
ok ($p->n_spectra == 35, "n_spectra()");

ok( my $s = $p->next_spectrum, "read first record"  );
ok( $s = $p->next_spectrum, "read second record" );
ok( are_equal( $s->rt,  5063.2261, 3), "rt()" );
ok( my $mz  = $s->mz,  "mz()" );
ok( my $int = $s->int, "int()" );
ok( scalar(@$mz) == scalar(@$int), "identical array lengths" );
ok( scalar(@$mz) == 764, "correct array lengths" );

ok( $p->n_spectra == 35, "record_count()" );
my $ref = $p->{run}->{spectrumList};
ok( $p->curr_index($ref)   == 2, "curr_index()" );

my $idx = $p->spectrum_index_by_id(
    'controllerType=0 controllerNumber=1 scan=10014' );
ok( $idx == 13, "spectrum_index_by_id()" );
$p->goto($ref => $idx);
ok( $p->curr_index($ref) == 13, "goto()" );

ok( $s = $p->next_spectrum, "read second record" );
$int = $s->int;
$mz  = $s->mz;
ok( are_equal($mz->[4],  300.0572, 3), "mz()"  );
ok( are_equal($int->[6], 3538.943, 3), "int()" );
ok( $s->ms_level == 1, "ms_level()" );
my $last_id;
while ($s = $p->next_spectrum) {
    $last_id = $s->id;
}
ok( $last_id eq 'controllerType=0 controllerNumber=1 scan=10035', "id()" );
$idx = $p->find_by_time(5074.6);
ok( $idx == 29, "find_by_time()" );
$p->goto($ref => 29);
$s = $p->next_spectrum;
ok (my $pre = $s->precursor, "precursor()");
ok ($pre->{scan_id} eq 'controllerType=0 controllerNumber=1 scan=10026',
    "precursor id" );
ok ($pre->{iso_mz}    == 423.75, "precursor iso_mz");
ok ($pre->{iso_lower} == 422.75, "precursor iso_lower");
ok ($pre->{iso_upper} == 424.75, "precursor iso_upper");
ok ($pre->{charge}    == 2, "precursor charge");
ok (are_equal($pre->{mono_mz},    423.748, 3), "precursor mono_mz");
ok (are_equal($pre->{intensity}, 8347.699, 3), "precursor intensity");

$idx = $p->find_by_time(5072.5);
$s = $p->fetch_spectrum($idx);
ok ($s->scan_number == 10025, "find_by_time()");
my $win = $s->scan_window;
ok (are_equal($win->[0],100,1), "scan_window() 1");
ok (are_equal($win->[1],895,1), "scan_window() 2");

ok( ($mz, $int) = $s->mz_int_by_range([200,210],[300,310]),
    "mz_int_by_range()" );
ok( scalar @$mz == 14 && scalar @$int == 14, "expected number of peaks" );

ok (my $v1 = $s->param(MS_BASE_PEAK_INTENSITY), "param() 1");
ok (my ($v2,$u2) = $s->param(MS_BASE_PEAK_INTENSITY), "param() 2");
ok (are_equal($v1, 162, 0), "param() 3");
ok (are_equal($v1, $v2, 0), "param() 4");
ok ($u2 eq MS_NUMBER_OF_DETECTOR_COUNTS, "param() 5");

ok ($p->get_tic->isa('MS::Reader::MzML::Chromatogram'), "get_tic()");
ok ($p->get_bpc->isa('MS::Reader::MzML::Chromatogram'), "get_bpc()");
ok ($p->get_xic(mz => '157.117', err_ppm => 10)->isa('MS::Reader::MzML::Chromatogram'), "get_bpc()");

my $app_id = '12345';
ok( $p->set_app_data($app_id, 'foo' => 'bar'), "set_app_data()" );
ok( $p->get_app_data($app_id, 'foo') eq 'bar', "get_app_data()" );

ok( my $dump = $p->dump, "dump()" );
ok( substr($dump,0,5) eq 'bless', "dump returned Dumper text" );
ok( $dump = $s->dump, "record dump()" );
ok( substr($dump,0,1) eq '{', "record dump returned Dumper text" );

# test numPress
ok ($p = MS::Reader::MzML->new($fn_np), "created parser object");

ok ($p->id eq 'Medicago_TMT_POOL1_2ug', "id()");
ok ($p->n_spectra == 35, "n_spectra()");

ok( $s = $p->next_spectrum, "read first record"  );
ok( $s = $p->next_spectrum, "read second record" );
$ref = $p->{run}->{spectrumList};
$idx = $p->spectrum_index_by_id(
    'controllerType=0 controllerNumber=1 scan=10014' );
$p->goto($ref => $idx);
ok( $s = $p->next_spectrum, "read second record" );
$int = $s->int;
$mz  = $s->mz;
ok( are_equal($mz->[4],  300.0572, 3), "mz()"  );
ok( are_equal($int->[6], 3538.943, 0), "int()" );

# test chromatogram methods
my $bpc = $p->get_bpc;
my $tic = $p->get_tic; # already exists in mzML
my $x_tic = $tic->rt;
my $y_tic = $tic->int;
my $x_bpc = $bpc->rt;
my $y_bpc = $bpc->int;

ok( are_equal($x_tic->[0], 0, 0), "tic 1" );
ok( are_equal($x_tic->[ $#{$x_tic} ], 13800, 0), "tic 2" );
ok( are_equal($y_tic->[0], 8938029, 0), "tic 3" );
ok( are_equal($y_tic->[ $#{$y_tic} ], 6181, 0), "tic 4" );
ok( are_equal($x_bpc->[0], 5063, 0), "bpc 1" );
ok( are_equal($x_bpc->[ $#{$x_bpc} ], 5073, 0), "bpc 2" );
ok( are_equal($y_bpc->[0], 441363, 0), "bpc 3" );
ok( are_equal($y_bpc->[ $#{$y_bpc} ], 394657, 0), "bpc 4" );

# test reading from existing index
ok ($p = MS::Reader::MzML->new($fn), "created parser object");
ok( $s = $p->next_spectrum, "read first record"  );
ok( $s = $p->next_spectrum, "read second record" );
ok( are_equal( $s->rt,  5063.2261, 3), "rt()" );

done_testing();

sub are_equal {

    my ($v1, $v2, $dp) = @_;
    return sprintf("%.${dp}f", $v1) eq sprintf("%.${dp}f", $v2);

}
