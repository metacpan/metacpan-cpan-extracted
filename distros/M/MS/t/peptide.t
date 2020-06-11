#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use BioX::Seq::Stream;
use FindBin;
use MS::Peptide;
use MS::Protein;
use MS::CV qw/:MS/;
use List::Util qw/sum/;

chdir $FindBin::Bin;

my $fn = 'corpus/fer.fa';

require_ok ("MS::Peptide");

ok( my $prot = MS::Protein->new(
    BioX::Seq::Stream->new($fn)->next_seq
), "new()" );

# DSKTSPALTQ
ok( my $pep = $prot->range(70 => 79), "range()" );
ok( $pep eq "DSKTSPALTQ", "as string" );

# test formatting
ok( $pep->as_string(fmt=>'original') eq "DSKTSPALTQ", "as_string orig" );
ok( $pep->as_string(adjacent=>1) eq "E.DSKTSPALTQ.D", "as_string adj" );

ok( $pep->prev  eq 'E', "prev" );
ok( $pep->next  eq 'D', "next" );
ok( $pep->start == 70, "start" );
ok( $pep->end   == 79, "end" );
ok( are_equal($pep->mz(type=>'mono',charge=>1), 1047.5322, 3), "mz +1" );
ok( are_equal($pep->mz(type=>'mono',charge=>2), 524.2700, 3), "mz +2" );
ok( are_equal($pep->neutral_mass(type=>'mono'), 1046.5244, 3), "mz +2" );
ok( are_equal($pep->neutral_mass(type=>'average'), 1047.1173, 3), "mz +2" );

# test single mod
ok( my $pep2 = $pep->copy(), "copy()" );
my $res = $pep2->add_mod(5, 'Phospho');
ok( $pep2->add_mod(5, 'Phospho'), "add_mod()" );
ok( $pep2->as_string(fmt=>'case') eq "DSKTsPALTQ", "as_string case" );
ok( are_equal($pep2->mz, 1207.46489, 3), "mz phospho" );

# test multi mod
ok( my $pep3 = $pep->copy(), "copy()" );
ok( $pep3->add_mod([2,4,5,9], 'Phospho'), "add_mod() multi" );
ok( $pep3->as_string(fmt=>'case') eq "DsKtsPALtQ", "as_string case" );
ok( are_equal($pep3->mz, 1367.39755, 3), "mz phospho multi" );
ok( my @mods = $pep3->mod_array(), "mod_array()" );
ok( scalar @mods == $pep->length()+2, "mod_array() length" );
ok( are_equal( sum(@mods), 320, 0 ), "mod_array() sum" );

# test bad mod
ok( my $pep4 = $pep->copy(), "copy()" );
like( exception {$pep4->add_mod(12,'Phospho')}, qr/Residue index out/,
    "add_mod() bad loc" );
like( exception {$pep4->add_mod(2,'Fosfo')}, qr/Bad modification/,
    "add_mod() bad mod" );

# residue_positions()
ok( $pep->residue_positions('SQ') ~~ [2,5,10], "residue_positions()" );

ok( $pep->prev('A') eq 'A', "set start" );
ok( $pep->next('Y') eq 'Y', "set end" );
print $pep->as_string(adjacent=>1), "\n";
ok( $pep->as_string(adjacent=>1) eq "A.DSKTSPALTQ.Y", "as_string new adj" );
ok( $pep->start(100) == 100, "set start" );
ok( $pep->end(200) == 200, "set end" );
like( exception {$pep->start('A')}, qr/Value must be numeric/,
    "set start bad val" );
like( exception {$pep->end('Y')}, qr/Value must be numeric/,
    "set end bad val" );

ok( $pep->make_heavy( [1..$pep->length()], 'C' ), "make_heavy()" );
ok( are_equal($pep->neutral_mass, 1089.66866, 3), "C13" );

done_testing();



sub are_equal {

    my ($v1, $v2, $dp) = @_;
    return abs($v2 - $v1) < 10**-$dp;

}
