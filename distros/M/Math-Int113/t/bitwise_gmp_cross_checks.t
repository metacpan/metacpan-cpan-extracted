use strict;
use warnings;
use Math::Int113;
use Test::More;

END { done_testing(); };

my ($gmpz, $gmp) = (1, 1);

eval {require Math::GMPz;};
$gmpz = 0 if($@);

eval {require Math::GMP;};
$gmp = 0 if($@);

my $max_gmp;

if($gmpz) {
  $max_gmp = (Math::GMPz->new(1) << 113) - 1;
  for(1 .. 10) {
    my $neg = int(rand(~0)) * -1;
    my $pos = int(rand(~0));
    my $pos_113 = Math::Int113->new($pos);
    my $comp_113 = ~(Math::Int113->new(-$neg)) + 1;
    my $pos_gmp = Math::GMPz->new($pos);
    my $comp_gmp = complement(Math::GMPz->new($neg));

    cmp_ok($comp_113, '==', Math::Int113->new("$comp_gmp"), "Math::Int113 and Math::GMPz complements match");

    my $and_113 = $pos_113 & $comp_113;
    my $and_gmp = $pos_gmp & $comp_gmp;
    cmp_ok("$and_113", 'eq', "$and_gmp", "&: Math::Int113 and Math::GMPz concur");

    my $or_113 = $pos_113 | $comp_113;
    my $or_gmp = $pos_gmp | $comp_gmp;
    cmp_ok("$or_113", 'eq', "$or_gmp", "|: Math::Int113 and Math::GMPz concur");

    my $xor_113 = $pos_113 ^ $comp_113;
    my $xor_gmp = $pos_gmp ^ $comp_gmp;
    cmp_ok("$xor_113", 'eq', "$xor_gmp", "^: Math::Int113 and Math::GMPz concur");
  }

  for(1 .. 10) {
    my $neg = int(rand(~0)) * -1;
    my $pos = int(rand(~0));
    my $pos_113 = Math::Int113->new($pos);
    my $comp_113 = ~(Math::Int113->new(-$neg) * 70000000000) + 1;
    my $pos_gmp = Math::GMPz->new($pos);
    my $comp_gmp = complement(Math::GMPz->new($neg) * 70000000000);

    cmp_ok($comp_113, '==', Math::Int113->new("$comp_gmp"), "Math::Int113 and Math::GMPz complements match");

    my $and_113 = $pos_113 & $comp_113;
    my $and_gmp = $pos_gmp & $comp_gmp;
    cmp_ok("$and_113", 'eq', "$and_gmp", "&: Math::Int113 and Math::GMPz concur");

    my $or_113 = $pos_113 | $comp_113;
    my $or_gmp = $pos_gmp | $comp_gmp;
    cmp_ok("$or_113", 'eq', "$or_gmp", "|: Math::Int113 and Math::GMPz concur");

    my $xor_113 = $pos_113 ^ $comp_113;
    my $xor_gmp = $pos_gmp ^ $comp_gmp;
    cmp_ok("$xor_113", 'eq', "$xor_gmp", "^: Math::Int113 and Math::GMPz concur");
  }

  for(1 .. 10) {
    my $neg = int(rand(~0)) * -1;
    my $pos = int(rand(~0));
    my $pos_113 = Math::Int113->new($pos) * 70000000000;
    my $comp_113 = ~(Math::Int113->new(-$neg) * 70000000000) + 1;
    my $pos_gmp = Math::GMPz->new($pos) * 70000000000;
    my $comp_gmp = complement(Math::GMPz->new($neg) * 70000000000);

    cmp_ok($comp_113, '==', Math::Int113->new("$comp_gmp"), "Math::Int113 and Math::GMPz complements match");

    my $and_113 = $pos_113 & $comp_113;
    my $and_gmp = $pos_gmp & $comp_gmp;
    cmp_ok("$and_113", 'eq', "$and_gmp", "&: Math::Int113 and Math::GMPz concur");

    my $or_113 = $pos_113 | $comp_113;
    my $or_gmp = $pos_gmp | $comp_gmp;
    cmp_ok("$or_113", 'eq', "$or_gmp", "|: Math::Int113 and Math::GMPz concur");

    my $xor_113 = $pos_113 ^ $comp_113;
    my $xor_gmp = $pos_gmp ^ $comp_gmp;
    cmp_ok("$xor_113", 'eq', "$xor_gmp", "^: Math::Int113 and Math::GMPz concur");
  }

  for(1 .. 10) {
    my $neg = int(rand(10000)) * -1;
    my $pos = int(rand(~0));
    my $pos_113 = Math::Int113->new($pos);
    my $comp_113 = ~(Math::Int113->new(-$neg)) + 1;
    my $pos_gmp = Math::GMPz->new($pos);
    my $comp_gmp = complement(Math::GMPz->new($neg));

    cmp_ok($comp_113, '==', Math::Int113->new("$comp_gmp"), "Math::Int113 and Math::GMPz complements match");

    my $and_113 = $pos_113 & $comp_113;
    my $and_gmp = $pos_gmp & $comp_gmp;
    cmp_ok("$and_113", 'eq', "$and_gmp", "&: Math::Int113 and Math::GMPz concur");

    my $or_113 = $pos_113 | $comp_113;
    my $or_gmp = $pos_gmp | $comp_gmp;
    cmp_ok("$or_113", 'eq', "$or_gmp", "|: Math::Int113 and Math::GMPz concur");

    my $xor_113 = $pos_113 ^ $comp_113;
    my $xor_gmp = $pos_gmp ^ $comp_gmp;
    cmp_ok("$xor_113", 'eq', "$xor_gmp", "^: Math::Int113 and Math::GMPz concur");
  }
}

###################################################################################
###################################################################################
###################################################################################

if($gmp) {
  $max_gmp = (Math::GMP->new(1) << 113) - 1;
  for(1 .. 10) {
    my $neg = int(rand(~0)) * -1;
    my $pos = int(rand(~0));
    my $pos_113 = Math::Int113->new($pos);
    my $comp_113 = ~(Math::Int113->new(-$neg)) + 1;
    my $pos_gmp = Math::GMP->new($pos);
    my $comp_gmp = complement(Math::GMP->new($neg));

    cmp_ok($comp_113, '==', Math::Int113->new("$comp_gmp"), "Math::Int113 and Math::GMP complements match");

    my $and_113 = $pos_113 & $comp_113;
    my $and_gmp = $pos_gmp & $comp_gmp;
    cmp_ok("$and_113", 'eq', "$and_gmp", "&: Math::Int113 and Math::GMP concur");

    my $or_113 = $pos_113 | $comp_113;
    my $or_gmp = $pos_gmp | $comp_gmp;
    cmp_ok("$or_113", 'eq', "$or_gmp", "|: Math::Int113 and Math::GMP concur");

    my $xor_113 = $pos_113 ^ $comp_113;
    my $xor_gmp = $pos_gmp ^ $comp_gmp;
    cmp_ok("$xor_113", 'eq', "$xor_gmp", "^: Math::Int113 and Math::GMP concur");
  }

  for(1 .. 10) {
    my $neg = int(rand(~0)) * -1;
    my $pos = int(rand(~0));
    my $pos_113 = Math::Int113->new($pos);
    my $comp_113 = ~(Math::Int113->new(-$neg) * 70000000000) + 1;
    my $pos_gmp = Math::GMP->new($pos);
    my $comp_gmp = complement(Math::GMP->new($neg) * 70000000000);

    cmp_ok($comp_113, '==', Math::Int113->new("$comp_gmp"), "Math::Int113 and Math::GMP complements match");

    my $and_113 = $pos_113 & $comp_113;
    my $and_gmp = $pos_gmp & $comp_gmp;
    cmp_ok("$and_113", 'eq', "$and_gmp", "&: Math::Int113 and Math::GMP concur");

    my $or_113 = $pos_113 | $comp_113;
    my $or_gmp = $pos_gmp | $comp_gmp;
    cmp_ok("$or_113", 'eq', "$or_gmp", "|: Math::Int113 and Math::GMP concur");

    my $xor_113 = $pos_113 ^ $comp_113;
    my $xor_gmp = $pos_gmp ^ $comp_gmp;
    cmp_ok("$xor_113", 'eq', "$xor_gmp", "^: Math::Int113 and Math::GMP concur");
  }

  for(1 .. 10) {
    my $neg = int(rand(~0)) * -1;
    my $pos = int(rand(~0));
    my $pos_113 = Math::Int113->new($pos) * 70000000000;
    my $comp_113 = ~(Math::Int113->new(-$neg) * 70000000000) + 1;
    my $pos_gmp = Math::GMP->new($pos) * 70000000000;
    my $comp_gmp = complement(Math::GMP->new($neg) * 70000000000);

    cmp_ok($comp_113, '==', Math::Int113->new("$comp_gmp"), "Math::Int113 and Math::GMP complements match");

    my $and_113 = $pos_113 & $comp_113;
    my $and_gmp = $pos_gmp & $comp_gmp;
    cmp_ok("$and_113", 'eq', "$and_gmp", "&: Math::Int113 and Math::GMP concur");

    my $or_113 = $pos_113 | $comp_113;
    my $or_gmp = $pos_gmp | $comp_gmp;
    cmp_ok("$or_113", 'eq', "$or_gmp", "|: Math::Int113 and Math::GMP concur");

    my $xor_113 = $pos_113 ^ $comp_113;
    my $xor_gmp = $pos_gmp ^ $comp_gmp;
    cmp_ok("$xor_113", 'eq', "$xor_gmp", "^: Math::Int113 and Math::GMP concur");
  }

  for(1 .. 10) {
    my $neg = int(rand(10000)) * -1;
    my $pos = int(rand(~0));
    my $pos_113 = Math::Int113->new($pos);
    my $comp_113 = ~(Math::Int113->new(-$neg)) + 1;
    my $pos_gmp = Math::GMP->new($pos);
    my $comp_gmp = complement(Math::GMP->new($neg));

    cmp_ok($comp_113, '==', Math::Int113->new("$comp_gmp"), "Math::Int113 and Math::GMP complements match");

    my $and_113 = $pos_113 & $comp_113;
    my $and_gmp = $pos_gmp & $comp_gmp;
    cmp_ok("$and_113", 'eq', "$and_gmp", "&: Math::Int113 and Math::GMP concur");

    my $or_113 = $pos_113 | $comp_113;
    my $or_gmp = $pos_gmp | $comp_gmp;
    cmp_ok("$or_113", 'eq', "$or_gmp", "|: Math::Int113 and Math::GMP concur");

    my $xor_113 = $pos_113 ^ $comp_113;
    my $xor_gmp = $pos_gmp ^ $comp_gmp;
    cmp_ok("$xor_113", 'eq', "$xor_gmp", "^: Math::Int113 and Math::GMP concur");
  }
}

sub complement {
  if($_[0] < 0) {
    return ($max_gmp + $_[0]) + 1;
  }
}
