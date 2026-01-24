# Check that a couple of values continue
# to be assigned and printed correctly.
# Skip thes tests on perl versions < 5.30.0
# as those perls were buggy and may well fail
# the tests.

use strict;
use warnings;
use Math::MPFR qw(:mpfr);
use Config;

use Test::More;

if ($] < 5.03) {
  is(1,1);
  warn " Skipping tests that may fail because this perl ($]) is old and buggy";
  done_testing();
  exit 0;
}

if($Math::MPFR::NV_properties{bits} == 53) {
  cmp_ok(sprintf('%.17g', 1180591620717411303424.0), 'eq', '1.1805916207174113e+21', '1.1805916207174113e+21 from float ok'  );
  cmp_ok(sprintf('%.17g', 1180591620717411303424  ), 'eq', '1.1805916207174113e+21', '1.1805916207174113e+21 from integer ok');

  cmp_ok(sprintf('%.17g', 2092367245128893587945263141069222138700785148154678170965.0), 'eq', '2.0923672451288935e+57',
                                                        '2.0923672451288936e+57 from float ok'  );
  cmp_ok(sprintf('%.17g', 2092367245128893587945263141069222138700785148154678170965  ), 'eq', '2.0923672451288935e+57',
                                                        '2.0923672451288936e+57 from integer ok');

  Rmpfr_set_default_prec(53);
  cmp_ok(Rmpfr_get_NV(Math::MPFR->new('1180591620717411303424'), MPFR_RNDN), '==', 1180591620717411303424,
                                                                                 '1180591620717411303424 equivalence ok');

  cmp_ok(Rmpfr_get_NV(Math::MPFR->new('2092367245128893587945263141069222138700785148154678170965'), MPFR_RNDN), '==',
                                       2092367245128893587945263141069222138700785148154678170965,
                                      '2092367245128893587945263141069222138700785148154678170965 equivalence ok');
}
elsif($Math::MPFR::NV_properties{bits} == 64) {
  cmp_ok(sprintf('%.21g', 1180591620717411303424.0), 'eq', '1.18059162071741130342e+21', '1.18059162071741130342e+21 from float ok'  );
  cmp_ok(sprintf('%.21g', 1180591620717411303424  ), 'eq', '1.18059162071741130342e+21', '1.18059162071741130342e+21 from integer ok');

  cmp_ok(sprintf('%.21g', 2092367245128893587945263141069222138700785148154678170965.0), 'eq', '2.092367245128893588e+57',
                                                     '2.092367245128893588e+57 from float ok'  );
  cmp_ok(sprintf('%.21g', 2092367245128893587945263141069222138700785148154678170965  ), 'eq', '2.092367245128893588e+57',
                                                     '2.092367245128893588e+57 from integer ok');

  Rmpfr_set_default_prec(64);
  cmp_ok(Rmpfr_get_NV(Math::MPFR->new('1180591620717411303424'), MPFR_RNDN), '==', 1180591620717411303424,
                                                                                 '1180591620717411303424 equivalence ok');

  cmp_ok(Rmpfr_get_NV(Math::MPFR->new('2092367245128893587945263141069222138700785148154678170965'), MPFR_RNDN), '==',
                                       2092367245128893587945263141069222138700785148154678170965,
                                      '2092367245128893587945263141069222138700785148154678170965 equivalence ok');
}
elsif($Math::MPFR::NV_properties{bits} == 113) {
  cmp_ok(sprintf('%.36g', 1180591620717411303424.0), 'eq', '1180591620717411303424', '1180591620717411303424 from float ok'  );
  cmp_ok(sprintf('%.36g', 1180591620717411303424  ), 'eq', '1180591620717411303424', '1180591620717411303424 from integer ok');

  cmp_ok(sprintf('%.36g', 2092367245128893587945263141069222138700785148154678170965.0), 'eq', '2.09236724512889358794526314106922204e+57',
                                     '2.09236724512889358794526314106922204e+57 from float ok'  );
  cmp_ok(sprintf('%.36g', 2092367245128893587945263141069222138700785148154678170965  ), 'eq', '2.09236724512889358794526314106922204e+57',
                                     '2.09236724512889358794526314106922204e+57 from integer ok');

  Rmpfr_set_default_prec(113);
  cmp_ok(Rmpfr_get_NV(Math::MPFR->new('1180591620717411303424'), MPFR_RNDN), '==', 1180591620717411303424,
                                                                                 '1180591620717411303424 equivalence ok');

  cmp_ok(Rmpfr_get_NV(Math::MPFR->new('2092367245128893587945263141069222138700785148154678170965'), MPFR_RNDN), '==',
                                       2092367245128893587945263141069222138700785148154678170965,
                                      '2092367245128893587945263141069222138700785148154678170965 equivalence ok');
}
else {
  warn "No tests for this type of NV\n";
  is(1,1);
  done_testing();
  exit 0;
}

done_testing()
