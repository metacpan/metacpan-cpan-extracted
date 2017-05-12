use strict;
use warnings;
use Math::NV qw(:all);

print "1..2\n";

my $nv = 67.625;

if(nv_type() eq 'double') {

  eval {Cprintf("%.10f\n", $nv);};

  if(!$@) {print "ok 1\n"}
  else {
    warn "\$\@: $@";
    print "not ok 1\n";
  }

  my $str = Csprintf("%.10f", $nv, 20);

  if($str eq '67.6250000000') {print "ok 2\n"}
  else {
    warn "\$str: $str\n";
    print "not ok 2\n";
  }

}
elsif(nv_type() eq 'long double') {

  eval {Cprintf("%.10Lf\n", $nv);};

  if(!$@) {print "ok 1\n"}
  else {
    warn "\$\@: $@";
    print "not ok 1\n";
  }

  my $str = Csprintf("%.10Lf", $nv, 20);

  if($str eq '67.6250000000') {print "ok 2\n"}
  else {
    warn "\$str: $str\n";
    print "not ok 2\n";
  }

}
else {

  eval {Cprintf("%.10Qf\n", $nv);};

  if(!$@) {print "ok 1\n"}
  else {
    warn "\$\@: $@";
    print "not ok 1\n";
  }

  my $str = Csprintf("%.10Qf", $nv, 20);

  if($str eq '67.6250000000') {print "ok 2\n"}
  else {
    warn "\$str: $str\n";
    print "not ok 2\n";
  }

}




