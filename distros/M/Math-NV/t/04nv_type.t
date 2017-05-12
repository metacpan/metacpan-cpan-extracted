use strict;
use warnings;
use Math::NV qw(:all);
use Config;

print "1..1\n";

if($Config{nvtype} eq nv_type()) {print "ok 1\n"}
else {
  warn "\n\$Config{nvtype} is $Config{nvtype}\nnv_type() returns ", nv_type(), "\n";
  print "not ok 1\n";
}
