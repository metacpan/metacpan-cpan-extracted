use strict;
use warnings;

print "1..3\n";

eval {require Math::Complex_C::L; Math::Complex_C::L->import('l_get_prec', 'l_set_prec');};

if($@) {
  warn "\$\@: $@";
  print "not ok 1\n";
}
else {print "ok 1\n"}

if($Math::Complex_C::L::VERSION eq '0.06') {
  print "ok 2\n";
}
else {
  warn "version: $Math::Complex_C::L::VERSION\n";
  print "not ok 2\n";
}

warn "\nDefault decimal precision is ", l_get_prec(), "\n";

my $new_set = 5 + l_get_prec();

l_set_prec($new_set);

if($new_set == l_get_prec()) {print "ok 3\n"}
else {
  warn "\nExpected $new_set\nGot ", l_get_prec(), "\n";
  print "not ok 3\n";
}



