# Check to see if .smallprof works  (it's setup in part2, used in part3 and
#   checked here).
print "1..2\n";
open(SPO,'smallprof.out');  
@lines = <SPO>;
if (grep /^\s+1 .+check_for_invocation/,@lines) {
  print "ok 1\n";
} else {
  print "not ok 1\n";
}
if (grep /nok 1/,@lines) {
  print "not ok 2\n";
} else {
  print "ok 2\n";
}

unlink '.smallprof';  # So as to not confuse the natives
unlink 'smallprof.out';
