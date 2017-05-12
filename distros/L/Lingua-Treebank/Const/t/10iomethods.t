# -*- perl -*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 15;
BEGIN {
    #01
    use_ok('Lingua::Treebank::Const');
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use constant PACK => 'Lingua::Treebank::Const';

#2
can_ok(PACK, qw( from_penn_string as_penn_text ) );

my $d = PACK->new();
#3
ok( defined $d, "new() returned something" );
#4
isa_ok($d, PACK, "and it's a " . PACK);

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

#5
ok(1, "passed from_penn_string");

my $ex2 = <<EOEX2;
(S (NP  (NNP Joe) ) (VP  (VB likes) (NP (NNP Bach) ) )  (. .))
EOEX2

my $d2 = PACK->new();

#6
isa_ok($d2, PACK);

$d2->from_penn_string($ex2);

#7
ok(1, "passed second from_penn_string");

#8
ok( ( $d->equiv_to($d2) ) , 'trees are equivalent');

# Put in TODO tests for malformed data here


# put in handling cases for writing data out as well
#  my $ex1prime = $d->as_text();
#9
is ( $d->as_penn_text(), $d2->as_penn_text(), 'tree texts match');

# diag ( $d->as_penn_text() );

# parens
my $ex3 = <<EOEX3;
(S (NP (-LRB- ()(NNP Joe)(-RRB- )))(VP (VB likes)(NP (NNP Bach)))(. .))
EOEX3
my $d3 = PACK->new();
$d3->from_penn_string($ex3);
#10
isa_ok($d3, PACK);
#11
is ($d3->as_penn_text(0, '', '', '') . "\n", $ex3, 'tree text w/ parens matches');

# UNBALANCED parens
my $ex4 = <<EOEX4;
(S (NP (-LRB- ()(NNP Joe))(VP (VB likes)(NP (NNP Bach)))(. .))
EOEX4
my $d4 = PACK->new();
$d4->from_penn_string($ex4);
#12
isa_ok($d4, PACK);
#13
is ($d4->as_penn_text(0, '', '', '') . "\n", $ex4, 'tree text w/ unbalanced parens matches');


# UNBALANCED parens -- not first item
my $ex5 = <<EOEX5;
(S (NP (PRP I)(-LRB- ()(NNP Joe))(VP (VB likes)(NP (NNP Bach)))(. .))
EOEX5
my $d5 = PACK->new();
$d5->from_penn_string($ex5);
# 14
isa_ok($d5, PACK);
#15
is ($d5->as_penn_text(0, '', '', '') . "\n", $ex5, 'tree text w/ unbalanced parens matches');
