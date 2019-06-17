use strict;
use warnings;

print "1..3\n";

eval{require Math::NV; Math::NV->import(':all');};


unless($@) {print "ok 1\n"}
else {
  warn "\$\@: $@";
  print "not ok 1\n";
}

if(!$@) {
  if($Math::NV::VERSION eq '2.02') {print "ok 2\n"}
  else {
    warn "Wrong version of Math::NV - we have $Math::NV::VERSION\n";
    print "not ok 2\n";
  }
}
else {print "ok 2\n"}

if(!$@) {
  if($Math::MPFR::VERSION >= '4.07') {
    warn "\nUsing MATH::MPFR-$Math::MPFR::VERSION\n";
    print "ok 3\n";
  }
  else {
    warn "Wrong version of Math::MPFR - we have $Math::MPFR::VERSION\n";
    print "not ok 3\n";
  }
}
else {print "ok 3\n"}

