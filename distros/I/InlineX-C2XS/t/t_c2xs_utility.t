use warnings;
use strict;
use InlineX::C2XS qw(c2xs);

print "1..2\n";

if(-e 'blib/script/c2xs') {print "ok 1\n"}
else {
  warn "No 'blib/script/c2xs' found\n";
  print "not ok 1\n";
}

if($^O =~ /MSWin32/i) {
  if(-e 'blib/script/c2xs.bat') {print "ok 2\n"}
  else {
    warn "No 'blib/script/c2xs.bat' found\n";
    print "not ok 2\n";
  }
}
else {
  warn "Skipping test 2 - not MS Windows\n";
  print "ok 2\n";
}
