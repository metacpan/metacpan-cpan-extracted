#!/usr/bin/env perl
# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl List-BinarySearch-XS.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More;
BEGIN { use_ok('List::BinarySearch::XS', qw( binsearch binsearch_pos ) ) };



#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

can_ok( 'List::BinarySearch::XS', 'binsearch', 'binsearch_pos' ); # Fully Qualified.

can_ok( __PACKAGE__, 'binsearch', 'binsearch_pos' );  # Imported.

my @tests = (
  [ 'Odd number of elements',  [ 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 53, 59, 61 ] ],
  [ 'Even number of elements', [ 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 53, 59     ] ],
  [ 'Single element',          [ 2                                                              ] ],
  [ 'Two elements',            [ 2, 3                                                           ] ],
  [ 'Empty list',              [                                                                ] ],
);

local( $a, $b ) = ( "Hello", "world" );

# Note: We use &subroutine(...) calling convention to override prototypes.
# We want this test set to be independent of prototypes.

subtest 'binsearch() tests.' => sub {
  foreach my $test ( @tests ) {
    my( $name, $list ) = @{$test};
    test_list_bsearch( $name, $list );
  }
  my $found_ix = &binsearch( sub{no warnings qw(numeric); $a<=>$b}, "Hello", $tests[0][1] );  ## no critic(warnings)
  is( $found_ix, undef, "Searching for string using numeric comparator; item not found." );
  $found_ix = &binsearch( sub{$a cmp $b}, "Hello", $tests[0][1] );
  is( $found_ix, undef, "Searching for string using string comparator; item not found." );
  $found_ix = &binsearch( sub{$a cmp $b}, '13', $tests[0][1] );
  is( $found_ix, 5, "Stringy search successful." );

  is( "$a $b!", "Hello world!", "\$a and \$b are not clobbered." );
};


subtest 'binsearch_pos() tests.' => sub {
  my $found = &binsearch_pos( sub{$a<=>$b}, 2, $tests[0][1] );
  is( $found, 0, 'Found 2 at position 0.' );
  $found = &binsearch_pos(sub{$a<=>$b},3,$tests[0][1]);
  is( $found, 1, 'Found 3 at position 1.' );
  $found = &binsearch_pos(sub{$a<=>$b},1,$tests[0][1]);
  is( $found, 0, 'Insert point for 1 is position 0.' );
  $found = &binsearch_pos(sub{$a<=>$b},61,$tests[0][1]);
  is( $found,16,'Found 61 at position 16.');
  $found = &binsearch_pos(sub{$a<=>$b},62,$tests[0][1]);
  is($found,17,'Insert point for 62 should be position 17.');
  $found = &binsearch_pos(sub{$a<=>$b},23,$tests[0][1]);
  is($found,8,'Found 23 at position 8.');
  $found = &binsearch_pos(sub{$a<=>$b},24,$tests[0][1]);
  is($found,9,'Insert point for 24 is position 9.');
  $found = &binsearch_pos(sub{$a<=>$b},24,[]);
  is($found,0,'Insert point on empty aref is zero.');
  is("$a $b!", "Hello world!", "\$a and \$b are not clobbered." );
};


done_testing();


sub test_list_bsearch {
  my( $name, $aref ) = @_;
  foreach my $needle ( 0 .. $#{$aref} + 2 ) {
    my( $known_index ) = grep { $needle == $aref->[$_] } 0 .. $#{$aref};
    my $found_index    = &binsearch( sub{$a<=>$b}, $needle, $aref );
    my $found = defined($found_index) ? "Found." : "Not found.";
    is( $found_index, $known_index, "$name. Needle:$needle. $found" );
  }
  return;
}
