use warnings;
use strict;

print "1..3\n";

eval {require Math::Float128;};

if($@) {
  warn "\$\@: $@";
  print "not ok 1\nnot ok 2\n";
}
else {
  print "ok 1\n";
  my $v = $Math::Float128::VERSION;

  if($v eq '0.15') {print "ok 2\n"}
  else {
    warn "Loaded version $v\n";
    print "not ok 2\n";
  }

  if($v == $Math::Float128::Constant::VERSION) {print "ok 3\n"}
  else {
    warn "Loaded version $Math::Float128::Constant::VERSION of Math::Float::Constant\n";
    print "not ok 3\n";
  }
}



