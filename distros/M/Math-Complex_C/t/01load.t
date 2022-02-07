use strict;
use warnings;

print "1..3\n";

eval {require Math::Complex_C; Math::Complex_C->import('d_get_prec', 'd_set_prec');};

if($@) {
  warn "\$\@: $@";
  print "not ok 1\n";
}
else {print "ok 1\n"}

if($Math::Complex_C::VERSION eq '0.15') {
  print "ok 2\n";
}
else {
  warn "version: $Math::Complex_C::VERSION\n";
  print "not ok 2\n";
}

warn "\nDefault decimal precision is ", d_get_prec(), "\n";

my $new_set = 5 + d_get_prec();

d_set_prec($new_set);

if($new_set == d_get_prec()) {print "ok 3\n"}
else {
  warn "\nExpected $new_set\nGot ", d_get_prec(), "\n";
  print "not ok 3\n";
}




