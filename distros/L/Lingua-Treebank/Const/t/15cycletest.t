# -*- perl -*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More tests => 6;

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

#6
SKIP: {
  eval { require Devel::Cycle; };
  skip ("devel::cycle not installed", 1) if $@;
  my @cycles;
  Devel::Cycle::find_cycle($ex1, sub { push @cycles, @_;} );
  is(scalar @cycles, 0, "no reference cycles found");
}

