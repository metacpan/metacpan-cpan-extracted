# also some testing of Rmpz_cmp_sj and Rmpz_cmp_uj

use strict;
use warnings;
use Config;
use Math::GMPz qw(:mpz IOK_flag);

use Test::More;

my $rop = Math::GMPz->new();

if($Config{ivtype} ne 'long long' && $Config{ivtype} ne '__int64') {
  eval { Rmpz_set_sj($rop, -11); };
  like($@, qr/Rmpz_set_sj function not implemented/, 'Rmpz_set_sj not implemented');

  eval { Rmpz_set_uj($rop, -11); };
  like($@, qr/Rmpz_set_uj function not implemented/, 'Rmpz_set_uj not implemented');

  eval { Rmpz_cmp_sj($rop, -11); };
  like($@, qr/Rmpz_cmp_sj is unavailable/, 'Rmpz_cmp_sj not implemented');

  eval { Rmpz_cmp_uj($rop, -11); };
  like($@, qr/Rmpz_cmp_uj is unavailable/, 'Rmpz_cmp_uj not implemented');

  done_testing();
  exit 0;
}

else {
  Rmpz_set_sj($rop, -11);
  cmp_ok($rop, '<', 0, 'small negative assigned as -ve');
  cmp_ok($rop, '==', -11, 'small negative value correctly assigned');
  cmp_ok(Rmpz_cmp_sj($rop, -11), '==', 0, 'small negative value correctly compared');

  Rmpz_set_sj($rop, -(~0 >> 1));
  cmp_ok($rop, '<', 0, 'large negative value assigned as +ve');
  cmp_ok($rop, '==', -(~0 >> 1), 'large negative value correctly assigned');
  cmp_ok(Rmpz_cmp_sj($rop, -(~0 >> 1)), '==', 0, 'large negative value correctly compared');

  Rmpz_set_sj($rop, ~0 >> 1);
  cmp_ok($rop, '>', 0, 'large positive value assigned as +ve');
  cmp_ok($rop, '==', ~0 >> 1, 'large positive value correctly assigned');
  cmp_ok(Rmpz_cmp_sj($rop, ~0 >> 1), '==', 0, 'large positive value correctly compared');

  Rmpz_set_uj($rop, -1);
  cmp_ok($rop, '==', ~0, "-1 correctly assigned as " . ~0);
  cmp_ok(Rmpz_cmp_uj($rop, ~0), '==', 0, '~0 correctly compared');

  Rmpz_set_uj($rop, ~0);
  cmp_ok($rop, '==', ~0,  ~0 . " correctly assigned as " . ~0);

  Rmpz_set_sj($rop, ~0);
  cmp_ok($rop, '==', -1,  ~0 . " correctly assigned as " . -1);
  cmp_ok(Rmpz_cmp_sj($rop, -1), '==', 0, '-1 correctly compared');

}

for(1 .. 1000) {
  my $iv = int(rand(~0));
  $iv = -$iv unless $_ % 3;

  my $type = IOK_flag($iv);
  next unless $type; # skip if $iv is not an IV/UV

  if($type == 1) {         # is signed
    Rmpz_set_sj($rop, $iv);
    cmp_ok($rop, '==', $iv, "$iv (IV) assigned correctly");
    cmp_ok(Rmpz_cmp_sj($rop, $iv), '==', 0, "$iv (IV) compared correctly");
  }
  else {                   # is unsigned
    Rmpz_set_uj($rop, $iv);
    cmp_ok($rop, '==', $iv, "$iv (UV) assigned correctly");
    cmp_ok(Rmpz_cmp_uj($rop, $iv), '==', 0, "$iv (UV) compared correctly");
  }

  cmp_ok(Rmpz_fits_IV_p($rop), '!=', 0, "$rop fits IV");

  my $check = Rmpz_get_IV($rop);

  cmp_ok($check, '==', $iv, "Rmpz_get_IV retrieves $iv");

}

done_testing();
