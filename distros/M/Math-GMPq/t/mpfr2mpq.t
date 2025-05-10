use strict;
use warnings;
use Math::GMPq qw(:mpq);
use Test::More;

eval { require Math::MPFR; };

if($@) {
  is(1,1);
  warn "Skipping tests because Math::MPFR is not available\n";
  done_testing();
  exit 0;
}
else {
  my $q = mpfr2mpq(Math::MPFR->new(0.625));
  cmp_ok("$q", 'eq', '5/8', "conversion from 0.625 is correct");
  done_testing();
}
