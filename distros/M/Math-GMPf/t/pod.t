eval "use Test::Pod 1.00";

if($@) {
  print "1..1\n";
  warn "Skipping test 1 - no recent version of Test::Pod installed\n";
  print "ok 1\n";
}

else {
  warn "\nTest::Pod version: $Test::Pod::VERSION\n";
  warn "\nPod::Simple version: $Pod::Simple::VERSION\n";
  Test::Pod::all_pod_files_ok();
}
