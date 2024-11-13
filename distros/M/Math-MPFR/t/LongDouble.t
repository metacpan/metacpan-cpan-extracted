# Rewrite to just test that Rmpfr_get_LD is retrieving the Math::LongDouble value correctly.
# Skip the test suite entirely if $Config{longdblkind} is not defined, or if nvsize is 8.

use warnings;
use strict;
use Config;
use Math::MPFR qw(:mpfr);

use Test::More;

eval {require Math::LongDouble;};

if($@) {
  warn "Skipping all tests - Math::LongDouble not found\n";
  cmp_ok(1, '==', 1, 'dummy test');
  done_testing();
  exit 0;
}
elsif($Math::LongDouble::VERSION < 0.20) {
  warn "Skipping all tests as Math::LongDouble is too old - update to at least version 0.20\n";
  cmp_ok(1, '==', 1, 'dummy test');
  done_testing();
  exit 0;
}
elsif(!defined $Config{longdblkind} ) {
  warn "Skipping all tests - \$Config{longdblkind} is not defined\n";
  cmp_ok(1, '==', 1, 'dummy test');
  done_testing();
  exit 0;
}
elsif($Config{longdblkind} < 0 ) {
  warn "Skipping all tests - unknown type of long double\n";
  cmp_ok(1, '==', 1, 'dummy test');
  done_testing();
  exit 0;
}
elsif($Config{longdblkind} == 0 ) {
  warn "Skipping all tests - long double is actually double\n";
  cmp_ok(1, '==', 1, 'dummy test');
  done_testing();
  exit 0;
}

my $ldblk = $Config{longdblkind};
warn "\nLDBLKIND: $ldblk\n";
my $prec = 64;
$prec = 113 if($ldblk == 1 || $ldblk == 2);
$prec = 2098 if $ldblk > 4;

Rmpfr_set_default_prec($prec);
my $op1 = Math::MPFR->new(1) / 10;
my $op2 = Math::MPFR->new('1.4') / 10;
my $rop1 = Math::MPFR->new();
my $rop2 = Math::MPFR->new();


my $ld1 = Math::LongDouble->new();
my $ld2 = Math::LongDouble->new();

Rmpfr_get_LD($ld1, $op1, MPFR_RNDN);
Rmpfr_get_LD($ld2, $op2, MPFR_RNDN);

my $inex1 = Rmpfr_set_LD($rop1, $ld1, MPFR_RNDN);
my $inex2 = Rmpfr_set_LD($rop2, $ld2, MPFR_RNDN);

cmp_ok($inex1, '==', 0, "inex1 is 0");
cmp_ok($inex2, '==', 0, "inex2 is 0");

if($prec == 64) {
 my($ld1_str, $ld2_str) = ("$ld1", "$ld2");
 $ld1_str =~ s/\-(0+)?1$/-1/; # standardize format
 $ld2_str =~ s/\-(0+)?1$/-1/; # standardize_format
 cmp_ok($ld1_str, 'eq', '1.00000000000000000001e-1', "0.1 renders correctly");
 cmp_ok($ld2_str, 'eq', '1.40000000000000000001e-1', "1.4/10 renders correctly");
 cmp_ok($op1, '==', $rop1, "0.1 does the round trip");
 cmp_ok($op2, '==', $rop2, "1.4/10 does the round trip");
}

if($prec == 113) {
 my($ld1_str, $ld2_str) = ("$ld1", "$ld2");
 $ld1_str =~ s/\-(0+)?1$/-1/; # standardize format
 $ld2_str =~ s/\-(0+)?1$/-1/; # standardize_format
 cmp_ok($ld1_str, 'eq', '1.00000000000000000000000000000000005e-1', "0.1 renders correctly");
 cmp_ok($ld2_str, 'eq', '1.39999999999999991118215802998747672e-1', "1.4/10 renders correctly");
 cmp_ok($op1, '==', $rop1, "0.1 does the round trip");
 cmp_ok($op2, '==', $rop2, "1.4/10 does the round trip");
}

if($prec == 2098) {
 my($ld1_str, $ld2_str) = ("$ld1", "$ld2");
 $ld1_str =~ s/\-(0+)?2$/-2/; # standardize format
 $ld2_str =~ s/\-(0+)?1$/-1/; # standardize_format
 cmp_ok($ld1_str, '==', '9.99999999999999999999999999999996918512088980422635110435291864116290339037362855378887616097927093505859375e-2', "0.1 renders correctly");
 cmp_ok($ld2_str, '==', '1.400000000000000000000000000000004930380657631323783823303533017413935457540219431393779814243316650390625e-1', "1.4/10 renders correctly");
 cmp_ok($op1, '==', $rop1, "0.1 does the round trip");
 cmp_ok($op2, '==', $rop2, "1.4/10 does the round trip");
}

done_testing();

__END__

