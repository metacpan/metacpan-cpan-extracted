# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::Simple tests => 63;
use Language::FP qw/perl2fp fp_eval/;
use strict;
ok(1); # If we made it this far, we're ok (1)

my ($str, $res);

sub fp($) {
    perl2fp(fp_eval shift);
}

sub alltests {

######################################################################
# Miscellaneous (8)

ok(fp '/+:<1 2 3>' eq '<6>');
ok(fp '/*:<1 2 3>' eq '<6>');
ok(fp 'apndl:<4 <1 2 3>>' eq '<4 1 2 3>');
ok(fp 'apndr:<<1 2 3> 4>' eq '<1 2 3 4>');
ok(fp 'apndr:<<> 4>' eq '<4>');
ok(fp 'distl:<4 <1 2 3>>' eq '<<4 1> <4 2> <4 3>>');
ok(fp 'distl:<<4> <1 2 3>>' eq '<<<4> 1> <<4> 2> <<4> 3>>');
ok(fp 'distr:<<4> <1 2 3>>' eq '<<4 <1 2 3>>>');
# Cool, but way too slow...
ok(fp <<'END' eq '<12>');
  /+ . @((== . [1, `1] -> `1 ; `0) .
 	(while > . [2, `0] (< -> reverse ; id) . [2, -]))
 	. distl . [id, iota]:42
END
######################################################################
# Precedence / grouping (7)
# If:
fp 'def f = < . [`2,id] -> `1 ; < . [`1,id] -> `2 ; `3';
ok(fp 'f:1' eq '<3>');
ok(fp 'f:2' eq '<2>');
ok(fp 'f:3' eq '<1>');
# While to compute 2^n, n >= 0
fp 'def f = 2 . (while < . [`0 , 1] [-.[1, `1], *.[`2, 2] ]).[id, `1]';
ok(fp 'f:0' eq '<1>');
ok(fp 'f:8' eq '<256>');
# And using negative constants:
fp 'def f2 = 2 . (while < . [`0 , 1] [+.[1, `-1], *.[`2, 2] ]).[id, `1]';
ok(fp 'f2:0' eq '<1>');
ok(fp 'f2:8' eq '<256>');

######################################################################
# Real numbers (5)
sub sqrt { $_[0] ** (1/2) }

ok(fp 'sqrt:2' eq '<1.4142135623731>');
ok(fp '*.[id,id].sqrt:2' eq '<2>');
ok(fp '/+.@`0.1111111111111111 . iota:9' eq '<1>');
ok(fp '@(== . [`1000, id]):<1000.0 1e3 1E3 1.0E3>' eq '<1 1 1 1>');
ok(fp '!=:<100.0001 100>' eq '<1>');

######################################################################
# Calling Perl from FP (2)

sub explode { split //, shift }
sub compact { (join '', @_) }

ok(fp 'trans . @explode:<"abc" "def">' eq '<<"a" "d"> <"b" "e"> <"c" "f">>');
ok(fp 'compact . @compact . distr:<<"abc" "def"> "!">' eq '<"abc!def!">');

#####################################################################
# Operator parsing (8)

ok(fp '<=:<2 2>' eq '<1>');
ok(fp '>=:<2 2>' eq '<1>');
ok(fp '<:<2 2>' eq '<"">');
ok(fp '>:<2 2>' eq '<"">');
ok(fp '==:<2 2>' eq '<1>');
ok(fp '!=:<2 2>' eq '<"">');
ok(fp '@(bu >=1):<0 1 2 3>' eq '<1 1 "" "">');
ok(fp 'bu <=1:1' eq '<1>');

}

$::FP_DEBUG = '';		# default evaluator
alltests;
$::FP_DEBUG = 'C';		# closure evaluator
alltests;
