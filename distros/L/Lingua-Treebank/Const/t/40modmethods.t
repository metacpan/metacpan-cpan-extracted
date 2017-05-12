# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;
BEGIN { use_ok('Lingua::Treebank::Const') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use constant PACK => 'Lingua::Treebank::Const';

can_ok(PACK,
       qw( insert_at detach_at ),
#         qw ( flatten retract replace detach prepend append) ,
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
