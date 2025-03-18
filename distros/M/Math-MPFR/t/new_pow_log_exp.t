
# Here we test the new pow() functions that were added in mpfr-4.2.0:
# Rmpfr_powr, Rmpfr_log2p1, Rmpfr_log10p1' Rmpfr_compound_si, Rmpfr_exp2m1,
# Rmpfr_exp10m1, Rmpfr_pown, Rmpfr_pow_uj and Rmpfr_pow_sj.

use strict;
use warnings;
use Config;
use Test::More;
use Math::MPFR qw(:mpfr);

my $has_420 = 0;
$has_420++ if MPFR_VERSION() >= 262656; # mpfr-4.2.0 or later

my $iv_is_longlong = Math::MPFR::_has_longlong();

# my $pi = Math::MPFR->new('3.1415926535897931');

my $rop1 = Math::MPFR->new();
my $rop2 = Math::MPFR->new();
my $op   = Math::MPFR->new('0.999999999');
my $op2  = Math::MPFR->new(7);


if($has_420) {

  my $rop_check = exp($op2 * log($op));
  Rmpfr_powr($rop1, $op, $op2, MPFR_RNDN);
  cmp_ok( abs($rop_check - $rop1), '==', 0, "Rmpfr_powr is in range ($rop1 | $rop_check)" );

  $rop_check = ($op + 1) ** -7;
  Rmpfr_compound_si($rop1, $op, -7, MPFR_RNDN);
  cmp_ok( abs($rop_check - $rop1), '<', 1e-17, "Rmpfr_compound_si is in range ($rop1 | $rop_check)" );

  Rmpfr_log2($rop2, $op + 1, MPFR_RNDN);
  Rmpfr_log2p1 ($rop1, $op, MPFR_RNDN);
  cmp_ok( abs($rop2 - $rop1), '==', 0, "Rmpfr_log2p1 is in range ($rop1 | $rop2)" );

  Rmpfr_log10($rop2, $op + 1, MPFR_RNDN);
  Rmpfr_log10p1 ($rop1, $op, MPFR_RNDN);
  cmp_ok( abs($rop2 - $rop1), '==', 0, "Rmpfr_log10p1 is in range ($rop1 | $rop2)" );

  $rop_check = (2 ** Math::MPFR->new(6)) - 1;
  Rmpfr_exp2m1 ($rop1, Math::MPFR->new(6), MPFR_RNDN);
  cmp_ok( abs($rop_check - $rop1), '==', 0, "Rmpfr_exp2m1 is in range ($rop1 | $rop_check)" );

  $rop_check = (10 ** Math::MPFR->new(5)) - 1;
  Rmpfr_exp10m1 ($rop1, Math::MPFR->new(5), MPFR_RNDN);
  cmp_ok( abs($rop_check - $rop1), '==', 0, "Rmpfr_exp10m1 is in range ($rop1 | $rop_check)" );

  $rop_check = $op ** 7;
  Rmpfr_pow_uj($rop1, $op, 7, MPFR_RNDN);
  cmp_ok($rop_check, '==', $rop1, 'Rmpfr_pow_uj is ok');

  $rop_check = $op ** -7;
  Rmpfr_pow_sj($rop1, $op, -7, MPFR_RNDN);
  cmp_ok($rop_check, '==', $rop1, 'Rmpfr_pow_sj is ok');

  Rmpfr_pown($rop2, $op, -7, MPFR_RNDN);
  cmp_ok($rop2, '==', $rop1, 'Rmpfr_pown is ok');
}
else {

  eval { Rmpfr_powr($rop2, $op, $op, MPFR_RNDN);  };
  like ( $@, qr/^Rmpfr_powr function not implemented until/,   'Rmpfr_powr not implemented'   );

  eval { Rmpfr_pow_uj($rop1, $op, 7, MPFR_RNDN);  };
  like ( $@, qr/^Rmpfr_pow_uj function not implemented until/, 'Rmpfr_pow_uj not implemented' );

  eval { Rmpfr_pow_sj($rop1, $op, -7, MPFR_RNDN); };
  like ( $@, qr/^Rmpfr_pow_sj function not implemented until/, 'Rmpfr_pow_sj not implemented' );

  eval { Rmpfr_pown($rop2, $op, -7, MPFR_RNDN);   };
  like ( $@, qr/^Rmpfr_pown function not implemented until/,   'Rmpfr_pown not implemented'   );

  eval { Rmpfr_compound_si($rop1, $op, 7, MPFR_RNDN);  };
  like ( $@, qr/^Rmpfr_compound_si function not implemented until/, 'Rmpfr_compound_si not implemented' );

  eval { Rmpfr_log2p1($rop1, $op, MPFR_RNDN);   };
  like ( $@, qr/^Rmpfr_log2p1 function not implemented until/,   'Rmpfr_log2p1 not implemented'   );

  eval { Rmpfr_log10p1($rop1, $op, MPFR_RNDN);   };
  like ( $@, qr/^Rmpfr_log10p1 function not implemented until/,   'Rmpfr_log10p1 not implemented' );

  eval { Rmpfr_exp2m1($rop1, $op, MPFR_RNDN);   };
  like ( $@, qr/^Rmpfr_exp2m1 function not implemented until/,   'Rmpfr_exp2m1 not implemented'   );

  eval { Rmpfr_exp10m1($rop1, $op, MPFR_RNDN);   };
  like ( $@, qr/^Rmpfr_exp10m1 function not implemented until/,   'Rmpfr_exp10m1 not implemented' );

}

my $inex1 = Rmpfr_pow_IV($rop1, Math::MPFR->new(2), -11, MPFR_RNDN);
my $inex2 = Rmpfr_pow_si($rop2, Math::MPFR->new(2), -11, MPFR_RNDN);

cmp_ok( $rop1,  '==', $rop2, "Rmpfr_pow_IV and Rmpfr_pow_si calculate same result" );
cmp_ok( $inex1, '==', 0,     "Rmpfr_pow_IV returns 0" );
cmp_ok( $inex2, '==', 0,     "Rmpfr_pow_si returns 0" );

$inex1 = Rmpfr_pow_IV($rop1, Math::MPFR->new(2), 11, MPFR_RNDN);
$inex2 = Rmpfr_pow_ui($rop2, Math::MPFR->new(2), 11, MPFR_RNDN);

cmp_ok( $rop1,  '==', $rop2, "Rmpfr_pow_IV and Rmpfr_pow_ui calculate same result" );
cmp_ok( $inex1, '==', 0,     "Rmpfr_pow_IV returns 0" );
cmp_ok( $inex2, '==', 0,     "Rmpfr_pow_ui returns 0" );

done_testing();
