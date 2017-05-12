use strict;
use warnings;
use Test::More;
use Test::Number::Delta within => 1e-14;
BEGIN {
   use_ok('Math::Random::MT::Perl');
}

eval { require Math::Random::MT; };

if ($@) {
   SKIP: {
      skip 'Math::Random::MT not available', 1;
   }
} else {
   my $tests = 10;  # 2 * tests**2 total tests run
   my $seeds = 100; # more than the 624 period N

   for my $o (1..$tests) {
      my @seeds = ( rand(2**32) );
      ok my $p = Math::Random::MT->new(@seeds), 'Single seed';
      ok my $c = Math::Random::MT::Perl->new(@seeds);
      for my $r (1..$tests) {
         my $pr = $p->rand();
         my $cr = $c->rand();
         delta_ok $pr, $cr;
      }
   }

   for my $o (1..$tests) {
      my @seeds;
      push @seeds, rand(2**32) for 1..$seeds;
      ok my $p = Math::Random::MT->new(@seeds), 'Multiple seeds';
      ok my $c = Math::Random::MT::Perl->new(@seeds);
      for my $r (1..$tests) {
         my $pr = $p->rand();
         my $cr = $c->rand();
         delta_ok $pr, $cr;
      }
   }

}

done_testing();
