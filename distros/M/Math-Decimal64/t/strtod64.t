use warnings;
use strict;
use Math::Decimal64 qw(:all);

print "1..1\n";

my $d64;

if(have_strtod64()){

  $d64 = STRtoD64('-9307199254740993');

  if($d64 == Math::Decimal64::_testvalD64(-1)) {print "ok 1\n"}
  else {
    warn "\$d64: $d64\n";
    print "not ok 1\n";
  }
}

else {
  eval{$d64 = STRtoD64('-1');};
  if($@) {print "ok 1\n"}
  else {
    warn "No \$\@\n";
    print "not ok 1\n";
  }
}


