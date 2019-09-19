#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use FindBin;
use MS::Reader::MGF;
use File::Temp qw/tempfile/;
use IO::Handle;

chdir $FindBin::Bin;

require_ok ("MS::Reader::MGF");

# check that compressed and uncompressed FHs return identical results
my $fn = 'corpus/test.mgf.gz';

ok (my $p = MS::Reader::MGF->new($fn), "created parser object");

ok( my $s = $p->next_spectrum, "read first record"  );
ok(    $s = $p->next_spectrum, "read second record" );
ok( $s->rt == 5063.5157, "rt()" );
ok( my $mz  = $s->mz,  "read m/z array" );
ok( my $int = $s->int, "read m/z array" );
ok( scalar(@$mz) == scalar(@$int), "identical array lengths" );
ok( scalar(@$mz) == 413, "correct array lengths" );
ok( $p->n_spectra == 32, "correct spectrum count" );
ok( $p->curr_index == 2, "correct index" );
my $idx = $p->get_index_by_id('Medicago_TMT_POOL1_2ug.10015.10015.3');
ok( $idx == 12, "get_index_by_id()" );
$p->goto_spectrum($idx);
ok( $p->curr_index == 12, "goto_spectrum()" );
ok( $s = $p->next_spectrum, "read second record" );
$int = $s->int;
$mz  = $s->mz;
ok( are_equal($mz->[4], 101.505, 3), "mz()" );
ok( are_equal($int->[6], 96.992, 3), "int()" );
ok( $s->ms_level == -1, "ms_level()" );

ok( my $dump = $s->dump, "dump()" );
ok( substr($dump,0,5) eq 'bless', "dump() returns Dumper text" );

my $last_id;
while ($s = $p->next_spectrum) {
    # do nothing - just want to check that end is reached
    $last_id = $s->id;
}
ok( $last_id eq 'Medicago_TMT_POOL1_2ug.10035.10035.3', "id()" );


done_testing();


sub are_equal {

    my ($v1, $v2, $dp) = @_;
    return sprintf("%.${dp}f", $v1) eq sprintf("%.${dp}f", $v2);

}
