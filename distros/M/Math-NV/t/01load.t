use strict;
use warnings;

print "1..2\n";

eval{require Math::NV; Math::NV->import(':all');};

unless($@) {print "ok 1\n"}
else {
  warn "\$\@: $@";
  print "not ok 1\n";
}

if(!$@) {
  if($Math::NV::VERSION eq '1.02') {print "ok 2\n"}
  else {
    warn "Wrong version of Math::NV - we have $Math::NV::VERSION\n";
    print "not ok 2\n";
  }
}
else {print "ok 2\n"}

