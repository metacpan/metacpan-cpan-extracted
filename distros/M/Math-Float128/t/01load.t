use warnings;
use strict;

print "1..2\n";

eval {require Math::Float128;};

if($@) {
  warn "\$\@: $@";
  print "not ok 1\nnot ok 2\n";
}
else {
  print "ok 1\n";
  my $v = $Math::Float128::VERSION;
  if($v eq '0.14') {print "ok 2\n"}
  else {
    warn "Loaded version $v\n";
    print "not ok 2\n";
  }
}



