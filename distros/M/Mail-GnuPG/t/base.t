
print "1..1\n";

unless (eval 'require Mail::GnuPG') {
  print "not ok 1\n";
} else {
  print "ok 1\n";
}

1;
