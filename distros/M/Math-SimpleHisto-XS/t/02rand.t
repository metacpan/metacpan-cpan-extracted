use strict;
use warnings;
use Test::More;
BEGIN { use_ok('Math::SimpleHisto::XS') };

# I am simply too lazy to test a random number generator reliably.
# Thus, I just test whether the functions "work"

my $rand = Math::SimpleHisto::XS::RNG::rand(12.3);
ok(defined $rand);
ok($rand >= 0.);
ok($rand <= 12.3);

my $rng = Math::SimpleHisto::XS::RNG->new(123);
isa_ok($rng, 'Math::SimpleHisto::XS::RNG');
$rand = $rng->rand;
ok(defined $rand);
ok($rand >= 0.);
ok($rand <= 1);

done_testing;
