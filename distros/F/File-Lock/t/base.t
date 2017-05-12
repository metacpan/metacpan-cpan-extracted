print "1..1\n";

unless (eval 'require File::Lock') {
  print "not ok 1\n";
} else {
  print "ok 1\n";
}
