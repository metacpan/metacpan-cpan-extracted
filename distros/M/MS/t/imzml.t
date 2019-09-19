#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use FindBin;
use MS::Reader::ImzML;
#use MS::CV qw/:MS/;

chdir $FindBin::Bin;

require_ok ("MS::Reader::ImzML");

my $fn = 'corpus/test.imzML.gz';

ok (my $p = MS::Reader::ImzML->new($fn), "created parser object");

ok ($p->id eq 'Experiment01', "id()");
ok ($p->n_spectra == 9, "n_spectra()");

ok( my $s = $p->next_spectrum, "read first record"  );
ok( $s = $p->next_spectrum, "read second record" );
ok( my $mz  = $s->mz,  "mz()" );
ok( my $int = $s->int, "int()" );
ok( scalar(@$mz) == scalar(@$int), "identical array lengths" );
ok( scalar(@$mz) == 8399, "correct array lengths" );

my $ref = $p->{run}->{spectrumList};
ok( $p->curr_index($ref)   == 2, "curr_index()" );

my $idx = $p->get_index_by_id( $ref =>
    'Scan=5' );
ok( $idx == 4, "get_index_by_id()" );
$p->goto($ref => $idx);
ok( $p->curr_index($ref) == 4, "goto()" );

ok( $s = $p->next_spectrum, "read second record" );
$int = $s->int;
$mz  = $s->mz;
ok( are_equal($mz->[12],  101.083, 3), "mz()"  );
ok( are_equal($int->[12], 0.354, 3), "int()" );
ok( $s->ms_level == 1, "ms_level()" );
my $last_id;
my ($x, $y) = (undef, undef);
while ($s = $p->next_spectrum) {
    $last_id = $s->id;
    ($x, $y) = $s->coords();
}
ok( $last_id eq 'Scan=9', "id()" );
ok( $x == 3, "coords()" );
ok( $y == 3, "coords()" );

done_testing();

sub are_equal {

    my ($v1, $v2, $dp) = @_;
    return sprintf("%.${dp}f", $v1) eq sprintf("%.${dp}f", $v2);

}
