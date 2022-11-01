use strict;
use warnings;
use Math::GMPf qw(:mpf IOK_flag NOK_flag POK_flag);

use Test::More;

my $f_iv = Math::GMPf->new();
my $f_nv = Math::GMPf->new();

my @in = (~0, 1000 .. 1100, ~0 >> 1, ~0 >> 2, (~0 >> 1) - 1);

for(@in) {

  my $iv = $_;
  $iv *= -1 unless $_ & 1;
  if(IOK_flag($_)) {
    Rmpf_set_IV($f_iv, $iv);
    cmp_ok($f_iv, '==', Rmpf_init_set_IV($iv), "$iv: Rmpz_set_IV() and Rmpz_init_set_IV() agree");
  }
  else {
    Rmpf_set_NV($f_nv, $iv);
    cmp_ok($f_nv, '==', Rmpf_init_set_NV($iv), "$iv: Rmpz_set_NV() and Rmpz_init_set_NV() agree");
  }

  my $nv = sqrt($_);
  $nv *= -1 unless $_ & 1;
  if(NOK_flag($nv)) {
    Rmpf_set_NV($f_nv, $nv);
    cmp_ok($f_nv, '==', Rmpf_init_set_NV($nv), "$nv: Rmpz_set_NV() and Rmpz_init_set_NV() agree");
  }
  else {
    Rmpf_set_IV($f_iv, $nv);
    cmp_ok($f_iv, '==', Rmpf_init_set_IV($nv), "$nv: Rmpz_set_IV() and Rmpz_init_set_IV() agree");
  }

  cmp_ok(POK_flag("$nv"), '==', 1, "POK_flag set as expected"  );
  cmp_ok(POK_flag(2.3)  , '==', 0, "POK_flag unset as expected");
}

done_testing();

__END__

