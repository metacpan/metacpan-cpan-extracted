use strict;
use warnings;
use Math::Decimal64 qw(:all);
use Config;

if($Config{ivsize} > 4) {
  print "1..1\n";
  warn "\n Skipping these tests - the precision of your UV\n",
       " is greater than the precision of the _Decimal64 type\n",
       " Usefulness of UV overloading is therefore limited.\n";
  print "ok 1\n";
}
else {

  print "1..10\n";

  my $uv = ~0;
  my $uv_man = "$uv";

  my $uv_d64 = MEtoD64($uv_man, 0);

  if($uv_d64 == $uv) {print "ok 1\n"}
  else {
    warn "\n1: Expected $uv, got $uv_d64\n";
    print "not ok 1\n";
  }

  my $orig = MEtoD64('17', -1); # 1.7
  my $next = $orig * $uv;

  if($next == MEtoD64('73014444015', -1)) {print "ok 2\n"}
  else {
    warn "\n2: expected 7301444401.5, got $next\n";
    print "not ok 2\n";
  }

  $next /= $uv;
  if($next == $orig) {print "ok 3\n"}
  else {
    warn "\n3: Expected 17e-1, got $next\n";
    print "not ok 3\n";
  }

  if(UnityD64(1) == $uv / $uv_d64) {print "ok 4\n"}
  else {
    warn "\n4: Expected 1, got ", $uv / $uv_d64, "\n";
    print "not ok 4\n";
  }

  $next *= $uv;
  if($next == MEtoD64('73014444015', -1)) {print "ok 5\n"}
  else {
    warn "\n5: Expected 7301444401.5, got $next\n";
    print "not ok 5\n";
  }

  $next /= $uv;

  $next += $uv;

  if($next == MEtoD64('42949672967', -1)) {print "ok 6\n"}
  else {
    warn "\n6: Expected 4294967296.7, got $next\n";
    print "not ok 6\n";
  }

  $next -= $uv;

  if($next == $orig) {print "ok 7\n"}
  else {
    warn "\n7: Expected 17e-1, got $next\n";
    print "not ok 7\n";
  }

  my $new = $uv - $orig;

  if($new == MEtoD64('42949672933', -1)) {print "ok 8\n"}
  else {
    warn "\n8: Expected 4294967293.3, got $new\n";
    print "not ok 8\n";
  }

  if($new + $uv == MEtoD64('85899345883', -1)) {print "ok 9\n"}
  else {
    warn "\n9: Expected 8589934588.3, got ", $new + $uv, "\n";
    print "not ok 9\n";
  }

  $new -= $uv;

  if($new == -$orig) {print "ok 10\n"}
  else {
    warn "\n10: Expected -17e-1, got $new\n";
    print "not ok 10\n";
  }
}
