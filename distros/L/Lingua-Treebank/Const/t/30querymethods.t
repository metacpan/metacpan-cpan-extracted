# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use Test::More tests => 51;
BEGIN { use_ok('Lingua::Treebank::Const') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use constant PACK => 'Lingua::Treebank::Const';
my %examples;
my %words;
can_ok(PACK,
       qw{ root },
       qw{ path_up_to },
       qw( get_all_terminals ),
#         qw{ find_common_ancestor  },
#         qw{ equiv_to  },
#         qw{ depth_from depth },
#         qw{ height },
#         qw{ get_index },
      );

my $d = PACK->new();

ok( defined $d, "new() returned something" );

isa_ok($d, PACK, 'root node');

$examples{ex1} = <<EOEX1;
(S
  (NP
    (NNP Joe)
  )
  (VP
    (VB likes)
    (NP
      (NNP Bach)
    )
  )
  (. .)
)
EOEX1

$d->from_penn_string($examples{ex1});

#05
ok(1, "passed from_penn_string");

my $ll = $d->left_leaf();

isa_ok($ll, PACK, 'leftleaf');

is( $ll->root(), $d, 'root of leftleaf is orig root');

my @lineage = $ll->path_up_to($d);

cmp_ok(scalar @lineage, '==', 3, '3 elements in lineage of "Joe"');

is( (join '-', map { $_->tag() } @lineage), 'NNP-NP-S', 'NNP-NP-S');


my @lterms = $ll->get_all_terminals();

#10
cmp_ok(scalar @lterms, '==', 1);

is($lterms[0], $ll, 'll is own terminal');

my @words = $d->get_all_terminals();

cmp_ok(scalar @words, '==', 4, '4 terminal words under root');

my $string = '';
#13->20 (4x2 tests)
foreach (@words) {
    isa_ok($_, PACK);
    ok( $_->is_terminal() );
    $string .= ' ';
    $string .= $_->word();
}

is($string, ' Joe likes Bach .', "'Joe likes Bach .'");

$examples{ex30} = <<EOEX30;
 (NP-PRD (-NONE- *?*) )
EOEX30
$words{ex30} = "";

$examples{ex31} = <<EOEX31;
(SQ (VBZ is) (RB n't)
    (NP-SBJ (RB there) )
    (NP-PRD (-NONE- *?*) ) )
EOEX31
$words{ex31} = "is n't there";

$examples{ex32} = <<'EOEX32';
(SQ
  (SQ (VBZ is) (RB n't)
      (NP-SBJ (RB there) )
      (NP-PRD (-NONE- *?*) ) )
    (. .) (-DFL- E_S)
)
EOEX32
$words{ex32} = "is n't there . E_S";

$examples{ex33} = <<EOEX33;
(SQ
    (S
      (INTJ (UH Uh) )
      (, ,)
      (NP-SBJ (EX there) )
      (VP (BES 's)
        (ADVP (RB really) )
        (NP-PRD (DT a) (NN lot) )))
    (, ,)
    (SQ (VBZ is) (RB n't)
      (NP-SBJ (RB there) )
      (NP-PRD (-NONE- *?*) ))
    (. .) (-DFL- E_S) )
EOEX33
$words{ex33} = "Uh , there 's really a lot , is n't there . E_S";

$examples{ex40} = <<EOEX40;
(S
  (NP-SBJ (EX there) )
  (ADVP (RB really) )
  (VP (VBZ is)
     (NP-PRD (-NONE- *?*) )))
EOEX40
$words{ex40} = "there really is";

$examples{ex41} = <<EOEX41;
(SBAR (-NONE- 0) )
EOEX41
$words{ex41} = "";

$examples{ex42} = <<EOEX42;
(SBAR (-NONE- 0)
  (S
    (NP-SBJ (EX there) )
    (ADVP (RB really) )
    (VP (VBZ is)
       (NP-PRD (-NONE- *?*) ))))
EOEX42
$words{ex42} = "there really is";

$examples{ex43} = <<EOEX43;
(VP (VBP think)
    (SBAR (-NONE- 0)
      (S
        (NP-SBJ (EX there) )
        (ADVP (RB really) )
        (VP (VBZ is)
          (NP-PRD (-NONE- *?*) )))))
EOEX43
$words{ex43} = "think there really is";


$examples{ex44} = <<EOEX44;
 (S
    (NP-SBJ (PRP I) )
    (VP (VBP think) 
      (SBAR (-NONE- 0) 
        (S 
          (NP-SBJ (EX there) )
          (ADVP (RB really) )
          (VP (VBZ is) 
            (NP-PRD (-NONE- *?*) )))))
    (. .) (-DFL- E_S) )
EOEX44
$words{ex44} = "I think there really is . E_S";

$examples{ex45} = <<EOEX45;
( (S 
    (NP-SBJ (PRP I) )
    (VP (VBP think) 
      (SBAR (-NONE- 0) 
        (S 
          (NP-SBJ (EX there) )
          (ADVP (RB really) )
          (VP (VBZ is) 
            (NP-PRD (-NONE- *?*) )))))
    (. .) (-DFL- E_S) ))
EOEX45
$words{ex45} = "I think there really is . E_S";

#22->61 (10 ex * 3 tests each)
foreach ( qw{ ex30 ex31 ex32 ex33 },
	  qw{ ex40 ex41 ex42 ex43 ex44 ex45 } ) {
    my $funky = PACK->new();

    isa_ok($funky, PACK, $_);

    $funky->from_penn_string($examples{$_});
    ok(1, "able to read in '$_' string");

    my @leaflist = $funky->get_all_terminals();
#     is( $words{$_}, join (" ", map {$_->word()} @leaflist), "$_ words match");

    is($funky->text(), $words{$_}, "$_ text match");
}


