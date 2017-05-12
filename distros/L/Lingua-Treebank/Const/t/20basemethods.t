# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 34;

BEGIN {
    #01
    use_ok('Lingua::Treebank::Const')
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
use constant PACK => 'Lingua::Treebank::Const';

can_ok(PACK,
       qw( is_root is_terminal ),
       qw( insert_at append prepend ),
       qw( prev_sib next_sib ),
       qw( left_leaf right_leaf ),
       qw( prev_leaf next_leaf ),
      );

my $d = PACK->new();

ok( defined $d, "new() returned something" );

isa_ok($d, PACK, 'root node');

my $ex1 = <<EOEX1;
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

$d->from_penn_string($ex1);

#05
ok(1, "passed from_penn_string");

is( $d->tag(), 'S', 'top tag is "S"' );

ok( ( $d->is_root() ) , 'top is root' );

ok( not $d->is_terminal() );

ok( (not defined $d->prev_sib() ), 'root node has no prev_sib');
#10
ok( (not defined $d->next_sib() ), 'root node has no next_sib');


my PACK $joe = $d->left_leaf();
isa_ok($joe, PACK, '"Joe" node');

ok( $joe->is_terminal() , ' left leaf is terminal');

is( $joe->tag(), 'NNP', ' leftmost tag is "NNP"');

is( $joe->word(), 'Joe', ' leftmost word is "Joe"');

#15
ok( (not $joe->is_root()) , ' leftmost not a root');

ok( (not defined $joe->prev_leaf()), " leftmost's prev_leaf not defined");

ok( ( not defined $joe->prev_sib() ), " leftmost has no immediate sib (l)");
ok( ( not defined $joe->next_sib() ), " leftmost has no immediate sib (r)");

is ($joe->right_leaf(), $joe, ' right leaf of terminal is self');

#20
is($joe->left_leaf(), $joe, ' left leaf of terminal is self');

my $likes = $joe->next_leaf();

isa_ok($likes, PACK, '"likes" node');

is($likes->prev_leaf, $joe, ' next-previous is original');

is($likes->word(), 'likes', ' "likes" node has right word');


is($likes->tag(), 'VB', '"likes" node has right tag');

#25
isnt($likes->parent(), $joe->parent(),
     '"Joe" and "likes" do not share a parent');

is ($likes->parent()->parent(), $d, ' root is grandparent of "likes"');

is ($joe->parent()->parent(), $d, ' root is grandparent of "joe"');

my $rl = $d->right_leaf();

isa_ok($rl, PACK, 'rightmost leaf');

is($rl->word(), '.', "rightmost leaf is '.'");

#30
is($rl->tag(), '.', "rightmost tag is '.'");

ok( ( not defined $rl->next_sib() ),
    "right-leaf has no next_sib" );

is($rl->parent, $d, "rl parent is the root");

is($rl->prev_sib(), $likes->parent(),
   "rl's prev sib is the parent of likes");

is($likes->parent->next_sib(), $rl,
   'next sib of "likes"->parent is rl');





