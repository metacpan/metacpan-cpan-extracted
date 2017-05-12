use warnings;
use strict;
use Math::MPFR qw(:mpfr);

my $cut = eval 'use threads; 1';

print "1..3\n";

print  "# Using Math::MPFR version ", $Math::MPFR::VERSION, "\n";
print  "# Using mpfr library version ", MPFR_VERSION_STRING, "\n";
print  "# Using gmp library version ", Math::MPFR::gmp_v(), "\n";

if($cut) {
  if($threads::VERSION < 1.71) {
    warn "Skipping all tests - need at least threads-1.71, we have version $threads::VERSION\n";
    print "ok 1\n";
    print "ok 2\n";
    print "ok 3\n";
    exit(0);
  }
}

my ($tls, $ok, $pid);
eval {$tls =  Rmpfr_buildopt_tls_p();};

my $cut_mess = $cut ? '' : "ithreads not available with this build of perl\n";
my $tls_mess = $tls ? '' :
                           $@ ? "Unable to determine whether mpfr was built with '--enable-thread-safe'\n"
                              : "Your mpfr library was not built with '--enable-thread-safe'\n";

if($cut && $tls) {   # perform tests

  Rmpfr_set_default_prec(101);
  my $thr1 = threads->create(
                      sub {
                          Rmpfr_set_default_prec(201);
                          return Rmpfr_get_default_prec();
                          } );
  my $res = $thr1->join();

  if($res == 201 && Rmpfr_get_default_prec() == 101) {$ok .= 'a'}
  else {warn "\n1a: \$res: $res\n    prec: ", Rmpfr_get_default_prec(), "\n"}

  # Needs TLS to work correctly on MS Windows
  if($pid = fork()) {
    Rmpfr_set_default_prec(102);
    waitpid($pid,0);
  } else {
    sleep 1;
    Rmpfr_set_default_prec(202);
    _save(Rmpfr_get_default_prec());
    exit(0);
  }

  sleep 2;

  if(Rmpfr_get_default_prec() == 102) {$ok .= 'b'}
  else {warn "\n1b: prec: ", Rmpfr_get_default_prec(), "\n"}

  my $f = _retrieve();

  if($f == 999999) {
    warn "Skipping test 1c - couldn't open 'save_child_setting.txt'";
    $ok .= 'c';
  }
  elsif($f == 202) {
    $ok .= 'c';
  }
  else {
    warn "\n1c: prec: $f\n";
  }

  if($ok eq 'abc') {print "ok 1\n"}
  else {
    warn "\$ok: $ok\n";
    print "not ok 1\n";
  }

  #######################

  $ok = '';

  Rmpfr_set_default_rounding_mode(GMP_RNDZ);
  my $thr2 = threads->create(
                      sub {
                          Rmpfr_set_default_rounding_mode(GMP_RNDU);
                          return Rmpfr_get_default_rounding_mode();
                          } );
  $res = $thr2->join();

  if($res == GMP_RNDU && Rmpfr_get_default_rounding_mode() == GMP_RNDZ) {$ok .= 'a'}
  else {warn "\n2a: \$res: $res\n    rounding: ", Rmpfr_get_default_rounding_mode(), "\n"}

  # Needs TLS to work correctly on MS Windows
  if($pid = fork()) {
    Rmpfr_set_default_rounding_mode(GMP_RNDU);
    waitpid($pid,0);
  } else {
    sleep 1;
    Rmpfr_set_default_rounding_mode(GMP_RNDD);
    _save(Rmpfr_get_default_rounding_mode());
    exit(0);
  }

  sleep 2;

  if(Rmpfr_get_default_rounding_mode() == GMP_RNDU) {$ok .= 'b'}
  else {warn "\n2b: rounding: ", Rmpfr_get_default_rounding_mode(), "\n"}

  $f = _retrieve();

  if($f == 999999) {
    warn "Skipping test 2c - couldn't open 'save_child_setting.txt'";
    $ok .= 'c';
  }
  elsif($f == GMP_RNDD) {
    $ok .= 'c';
  }
  else {
    warn "\n2c: rounding: $f\n";
  }

  if($ok eq 'abc') {print "ok 2\n"}
  else {
    warn "\$ok: $ok\n";
    print "not ok 2\n";
  }

  #######################

  $ok = '';

  Rmpfr_set_default_rounding_mode(GMP_RNDN);
  Rmpfr_set_default_prec(103);
  my $thr3 = threads->create(
                          {'context' => 'list'},
                      sub {
                          Rmpfr_set_default_prec(203);
                          Rmpfr_set_default_rounding_mode(GMP_RNDU);
                          return (Rmpfr_get_default_prec(), Rmpfr_get_default_rounding_mode());
                          } );
  my @res = $thr3->join();

  if($res[0] == 203 && $res[1] == GMP_RNDU && Rmpfr_get_default_prec() == 103 && Rmpfr_get_default_rounding_mode() == GMP_RNDN) {$ok .= 'a'}
  else {warn "\n3a: \$res[0]: $res[0]\n \$res[1]: $res[1]\n    prec: ", Rmpfr_get_default_prec(), "\n    rounding: ", Rmpfr_get_default_rounding_mode(), "\n"}

  # Needs TLS to work correctly on MS Windows
  if($pid = fork()) {
    Rmpfr_set_default_prec(104);
    Rmpfr_set_default_rounding_mode(GMP_RNDU);
    waitpid($pid,0);
  } else {
    sleep 1;
    Rmpfr_set_default_prec(204);
    Rmpfr_set_default_rounding_mode(GMP_RNDD);
    my $p = Rmpfr_get_default_prec();
    my $r = Rmpfr_get_default_rounding_mode();
    _save("$p $r");
    exit(0);
  }

  sleep 2;

  if(Rmpfr_get_default_rounding_mode() == GMP_RNDU && Rmpfr_get_default_prec() == 104) {$ok .= 'b'}
  else {warn "\n3b: prec: ", Rmpfr_get_default_prec(), "\n rounding: ", Rmpfr_get_default_rounding_mode(), "\n"}

  my @f = _retrieve();

  if($f[0] == 999999) {
    warn "Skipping test 3c - couldn't open 'save_child_setting.txt'";
    $ok .= 'c';
  }
  elsif($f[0] == 204 && $f[1] == GMP_RNDD) {
    $ok .= 'c';
  }
  else {
    warn "\n3c: prec: $f[0]  rounding: $f[1]\n";
  }

  if($ok eq 'abc') {print "ok 3\n"}
  else {
    warn "\$ok: $ok\n";
    print "not ok 3\n";
  }

  #######################
}
else {
  warn "Skipping all tests: ${cut_mess}${tls_mess}";
  print "ok 1\n";
  print "ok 2\n";
  print "ok 3\n";
}


sub _save {
    unless (open(WR, '>', 'save_child_setting.txt')) {
      warn "Can't open file 'save_child_setting.txt' for writing : $!";
      return 0;
    }
    print WR $_[0];
    return 1;
}

sub _retrieve {
    unless (open (RD, '<', 'save_child_setting.txt')) {
      warn "Can't open file 'save_child_setting.txt' for reading: $!";
      return 999999;
    }
    my @ret;
    my $ret = <RD>;
    chomp $ret;
    if($ret =~ / /) {
      @ret = split / /, $ret;
      return @ret;
    }
    return $ret;
}

