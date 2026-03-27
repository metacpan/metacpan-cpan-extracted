use strict;
use warnings;

use Test::More;

eval { require Math::GMP_OLOAD;};

if(!$@) {
  warn "Math::GMP_OLOAD has successfully loaded\n";
  cmp_ok($Math::GMP_OLOAD::VERSION, 'eq', "0.03", '$Math::GMP_OLOAD::VERSION eq "0.03"');
}
else {
  warn "\$\@: $@\n Math::GMP has not loaded - hence Math::GMP_OLOAD has also failed to load\n";
  like($@, qr/^Math::GMP_OLOAD failed to load Math::GMP/, "Math::GMP_OLOAD failed to load as expected");
}

done_testing();
