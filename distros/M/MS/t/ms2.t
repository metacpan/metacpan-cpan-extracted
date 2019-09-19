#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use FindBin;
use MS::Reader::MSn;
use File::Temp qw/tempfile/;
use IO::Handle;

chdir $FindBin::Bin;

require_ok ("MS::Reader::MSn");

# check that compressed and uncompressed FHs return identical results
my $fn = 'corpus/test.ms2.gz';

ok (my $p = MS::Reader::MSn->new($fn), "created parser object");

ok( my $s = $p->next_spectrum, "read first record"  );
ok(    $s = $p->next_spectrum, "read second record" );
ok( $s->rt == 84.39193, "read RT" );
ok( my $mz  = $s->mz,  "read m/z array" );
ok( my $int = $s->int, "read m/z array" );
ok( scalar(@$mz) == scalar(@$int), "identical array lengths" );
ok( scalar(@$mz) == 413, "identical array lengths" );
ok( $p->n_spectra == 32, "correct spectrum count" );
ok( $p->curr_index == 2, "correct index" );
my $idx = $p->get_index_by_id('10015');
ok( $idx == 12, "get_index_by_id()" );
$p->goto_spectrum($idx);
ok( $p->curr_index == 12, "goto_spectrum()" );
ok( $s = $p->next_spectrum, "read second record" );
$int = $s->int;
$mz  = $s->mz;
ok( $mz->[4]  == 101.5045, "mz()" );
ok( $int->[6] == 96.992,  "int()" );
ok( $s->ms_level == 2, "ms_level()" );
my $last_id;
while ($s = $p->next_spectrum) {
    # do nothing - just want to check that end is reached
    $last_id = $s->id;
}
ok( $last_id eq '10035', "id()" );

done_testing();
