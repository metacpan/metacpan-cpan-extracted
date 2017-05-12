use strict;
use warnings;
use Math::Decimal64 qw(:all);

my $t = 1;
print "1..$t\n";

eval {require Math::LongDouble;};

unless($@) {
  my $d64 = Math::Decimal64->new('1237', -4);
  my $ldxd64 = Math::LongDouble::ZeroLD(1);
  D64toLD($ldxd64, $d64);

  my $d64xld = Math::Decimal64->new();
  LDtoD64($d64xld, $ldxd64);

  if($d64 == $d64xld) {print "ok 1\n"}
  else {
    warn "\$d64: $d64\n\$d64xld: $d64xld\n";
    print "not ok 1\n";
  }
}
else {
  warn "Skipping all tests - no Math::LongDouble\n";
  for(1..$t) {print "ok $t\n"}
}

