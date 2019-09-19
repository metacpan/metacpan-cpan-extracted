#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use FindBin;
use MS::Reader::MzXML;

chdir $FindBin::Bin;

require_ok ("MS::Reader::MzXML");

my $fn = 'corpus/test.mzXML.gz';

ok (my $p = MS::Reader::MzXML->new($fn), "created parser object");

ok ($p->n_spectra == 35, "n_spectra()");

ok( my $s = $p->next_spectrum, "read first record"  );

ok( $s = $p->next_spectrum, "read second record" );
ok( are_equal( $s->rt,  5063.2261, 1), "rt()" );
ok( my $mz  = $s->mz,  "mz()" );
ok( my $int = $s->int, "int()" );
ok( scalar(@$mz) == scalar(@$int), "identical array lengths" );
ok( scalar(@$mz) == 764, "correct array lengths" );

ok( $p->n_spectra == 35, "record_count()" );
my $r = $p->{msRun};
ok( $p->curr_index($r)   == 2, "curr_index()" );

my $idx = $p->get_index_by_id( $r => '10014' );
ok( $idx == 13, "get_index_by_id()" );
$p->goto($r => $idx);
ok( $p->curr_index($r) == 13, "goto()" );

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
ok( $last_id eq '10035', "id()" );
$idx = $p->find_by_time(5074.6);
ok( $idx == 29, "find_by_time()" );
$p->goto_spectrum( 29 );
$s = $p->next_spectrum;
ok (my $pre = $s->precursor, "precursor()");
ok ($pre->{scan_id} eq '10026', "precursor id" );
ok ($pre->{charge}    == 2, "precursor charge");
ok (are_equal($pre->{iso_mz},    423.75, 2  ), "precursor iso_mz"    );
ok (are_equal($pre->{iso_lower}, 422.75, 2  ), "precursor iso_lower" );
ok (are_equal($pre->{iso_upper}, 424.75, 2  ), "precursor iso_upper" );
ok (are_equal($pre->{mono_mz},  423.748, 3  ), "precursor mono_mz"   );
ok (are_equal($pre->{intensity}, 8347.699, 3), "precursor intensity" );

$idx = $p->find_by_time(5072.5, 2);
$s = $p->fetch_spectrum($idx);
ok ($s->scan_number == 10025, "find_by_time()");
my $win = $s->scan_window;
ok (are_equal($win->[0],100,1), "scan_window() 1");
ok (are_equal($win->[1],900.7,1), "scan_window() 2");

done_testing();


sub are_equal {

    my ($v1, $v2, $dp) = @_;
    return sprintf("%.${dp}f", $v1) eq sprintf("%.${dp}f", $v2);

}
