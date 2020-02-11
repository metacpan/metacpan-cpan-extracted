# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl IO-Uncompress-Untar.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More;
BEGIN { use_ok('Math::Spiral') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# testing Next: perl -MMath::Spiral -e '$c=new Math::Spiral(); for(my $i=0;$i<5;$i++) { print "$i\t( " . join(", ",$c->Next()) . " )\n"; }'  # correct= ['204,81,81', '127,51,51', '81,204,204', '51,127,127', '142,204,81']

my $s=new Math::Spiral();
my $t='';


foreach(0..9) { my ($xo,$yo)=$s->Next(); $t .= "($xo,$yo) "; }

ok($t eq '(0,0) (1,0) (1,1) (0,1) (-1,1) (-1,0) (-1,-1) (0,-1) (1,-1) (2,-1) ', "Next OK");

done_testing();

  # or
  #          use Test::More;   # see done_testing()
  #
  #          require_ok( 'Some::Module' );
  #
  #          # Various ways to say "ok"
  #          ok($got eq $expected, $test_name);
