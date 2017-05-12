#!/usr/bin/perl -- -*- mode: cperl -*-
eval { require B; };
if ($@) {
  print "1..0 # SKIP: Compiler B not available\n";
  warn "Compiler B not available[$@]\n";
  exit;
} else {
  require Config;
  if ($Config::Config{usethreads} && $Config::Config{usethreads}) {
    print "1..0 # SKIP: Threaded perl not supported\n";
    exit;
  } else {
    print "1..3\n";
    require B::FindAmpersand;
    print "ok 1\n";
  }
}

"ok 2" =~ /.*/ && print "$&\n";

$SIG{__WARN__} = sub { print "ok 3\n" if $_[0] =~ /Found/};
B::FindAmpersand::compile()->();
