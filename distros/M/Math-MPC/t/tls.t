use warnings;
use strict;
use Math::MPFR qw(:mpfr);
use Math::MPC qw(:mpc);

if(3 > MPFR_VERSION_MAJOR) {
  print "1..1\n";
  warn "\nSkipping all tests - mpfr too old for tls support\n";
  print "ok 1\n";
  exit 0;
}

unless(Rmpfr_buildopt_tls_p()) {
  print "1..1\n";
  warn "\nSkipping all tests - mpfr was built without tls support\n";
  print "ok 1\n";
  exit 0;
}

my $cut = eval 'use threads; 1';
my $cut_mess = '';

if($cut) {
  if($threads::VERSION < 1.71) {
    $cut = 0;
    $cut_mess = "threads version 1.71 needed - we have only $threads::VERSION. Please update from CPAN.\n";
  }
}

print "1..5\n";

warn  "# Using Math::MPFR version ", $Math::MPFR::VERSION, "\n";
warn  "# Using mpfr library version ", MPFR_VERSION_STRING, "\n";
warn  "# Using gmp library version ", Math::MPFR::gmp_v(), "\n";

my ($ok, $pid);

if(!$cut && !$cut_mess) {$cut_mess = "ithreads not available with this build of perl\n"}

if($cut) { # perform tests

  Rmpc_set_default_prec(101);
  my $thr1 = threads->create(
                      sub {
                          Rmpc_set_default_prec(201);
                          return Rmpc_get_default_prec();
                          } );
  my $res = $thr1->join();

  if($res == 201 && Rmpc_get_default_prec() == 101) {$ok .= 'a'}
  else {warn "\n1a: \$res: $res\n    prec: ", Rmpc_get_default_prec(), "\n"}

  if($pid = fork()) {
    Rmpc_set_default_prec(102);
    waitpid($pid,0);
  } else {
    sleep 1;
    Rmpc_set_default_prec(202);
    _save(Rmpc_get_default_prec());
    exit(0);
  }

  sleep 2;

  if(Rmpc_get_default_prec() == 102) {$ok .= 'b'}
  else {warn "\n1b: prec: ", Rmpc_get_default_prec(), "\n"}

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

  Rmpc_set_default_rounding_mode(GMP_RNDZ);
  my $thr2 = threads->create(
                      sub {
                          Rmpc_set_default_rounding_mode(GMP_RNDU);
                          return Rmpc_get_default_rounding_mode();
                          } );
  $res = $thr2->join();

  if($res == GMP_RNDU && Rmpc_get_default_rounding_mode() == GMP_RNDZ) {$ok .= 'a'}
  else {warn "\n2a: \$res: $res\n    rounding: ", Rmpc_get_default_rounding_mode(), "\n"}

  if($pid = fork()) {
    Rmpc_set_default_rounding_mode(GMP_RNDU);
    waitpid($pid,0);
  } else {
    sleep 1;
    Rmpc_set_default_rounding_mode(GMP_RNDD);
    _save(Rmpc_get_default_rounding_mode());
    exit(0);
  }

  sleep 2;

  if(Rmpc_get_default_rounding_mode() == GMP_RNDU) {$ok .= 'b'}
  else {warn "\n2b: rounding: ", Rmpc_get_default_rounding_mode(), "\n"}

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

  Rmpc_set_default_rounding_mode(GMP_RNDN);
  Rmpc_set_default_prec(103);
  my $thr3 = threads->create(
                          {'context' => 'list'},
                      sub {
                          Rmpc_set_default_prec(203);
                          Rmpc_set_default_rounding_mode(GMP_RNDU);
                          return (Rmpc_get_default_prec(), Rmpc_get_default_rounding_mode());
                          } );
  my @res = $thr3->join();

  if($res[0] == 203 && $res[1] == GMP_RNDU && Rmpc_get_default_prec() == 103 && Rmpc_get_default_rounding_mode() == GMP_RNDN) {$ok .= 'a'}
  else {warn "\n3a: \$res[0]: $res[0]\n \$res[1]: $res[1]\n    prec: ", Rmpc_get_default_prec(), "\n    rounding: ", Rmpc_get_default_rounding_mode(), "\n"}

  if($pid = fork()) {
    Rmpc_set_default_prec(104);
    Rmpc_set_default_rounding_mode(GMP_RNDU);
    waitpid($pid,0);
  } else {
    sleep 1;
    Rmpc_set_default_prec(204);
    Rmpc_set_default_rounding_mode(GMP_RNDD);
    my $p = Rmpc_get_default_prec();
    my $r = Rmpc_get_default_rounding_mode();
    _save("$p $r");
    exit(0);
  }

  sleep 2;

  if(Rmpc_get_default_rounding_mode() == GMP_RNDU && Rmpc_get_default_prec() == 104) {$ok .= 'b'}
  else {warn "\n3b: prec: ", Rmpc_get_default_prec(), "\n rounding: ", Rmpc_get_default_rounding_mode(), "\n"}

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

  $ok = '';

  Rmpc_set_default_prec2(301, 302);
  my $thr4 = threads->create(
                          {'context' => 'list'},
                      sub {
                          Rmpc_set_default_prec2(310, 320);
                          my @ret = Rmpc_get_default_prec2();
                          return @ret;
                          } );
  @res = $thr4->join();
  my @p2 = Rmpc_get_default_prec2();

  if($res[0] == 310 && $res[1] == 320 && $p2[0] == 301 && $p2[1] == 302) {$ok .= 'a'}
  else {warn "\n4a: \$res[0]: $res[0]\n  \$res[1]: $res[1]\n  \$p2[0]: $p2[0]\n  \$p2[1]: $p2[1]\n" }

  if($pid = fork()) {
    Rmpc_set_default_prec2(303, 304);
    waitpid($pid,0);
  } else {
    sleep 1;
    Rmpc_set_default_prec2(330, 340);
    my @args = Rmpc_get_default_prec2();
    _save("$args[0] $args[1]");
    exit(0);
  }

  sleep 2;

  @p2 = Rmpc_get_default_prec2();

  if($p2[0] == 303 && $p2[1] == 304) {$ok .= 'b'}
  else {warn "\n4b: \$p2[0]: $p2[0]\n   \$p2[1]: $p2[1]\n"}

  @f = _retrieve();

  if($f[0] == 999999) {
    warn "Skipping test 4c - couldn't open 'save_child_setting.txt'";
    $ok .= 'c';
  }
  elsif($f[0] == 330 && $f[1] == 340) {
    $ok .= 'c';
  }
  else {
    warn "\n4c: prec: @f\n";
  }

  if($ok eq 'abc') {print "ok 4\n"}
  else {
    warn "\$ok: $ok\n";
    print "not ok 4\n";
  }

  #######################
  #######################

  $ok = '';

  Rmpc_set_default_prec2(311, 311);
  my $thr5 = threads->create(
                          {'context' => 'list'},
                      sub {
                          Rmpc_set_default_prec2(320, 330);
                          my @ret = Rmpc_get_default_prec2();
                          push @ret, Rmpc_get_default_prec();
                          return @ret;
                          } );
  @res = $thr5->join();
  @p2 = Rmpc_get_default_prec2();

  if($res[0] == 320 && $res[1] == 330 && $res[2] == 0 && $p2[0] == 311 && $p2[1] == 311 && Rmpc_get_default_prec() == 311) {$ok .= 'a'}
  else {warn "\n5a: \$res[0]: $res[0]\n  \$res[1]: $res[1]\n  \$p2[0]: $p2[0]\n  \$p2[1]: $p2[1]\n  Default Prec: ",
              Rmpc_get_default_prec(), "\n" }

  if($pid = fork()) {
    Rmpc_set_default_prec2(303, 303);
    waitpid($pid,0);
  } else {
    sleep 1;
    Rmpc_set_default_prec2(330, 340);
    my @args = Rmpc_get_default_prec2();
    push @args, Rmpc_get_default_prec();
    _save("$args[0] $args[1] $args[2]");
    exit(0);
  }

  sleep 2;

  @p2 = Rmpc_get_default_prec2();
  push @p2, Rmpc_get_default_prec();

  if($p2[0] == 303 && $p2[1] == 303 && $p2[2] == 303) {$ok .= 'b'}
  else {warn "\n5b: \$p2[0]: $p2[0]\n   \$p2[1]: $p2[1]\n  \$p2[2]: $p2[2]\n"}

  @f = _retrieve();

  if($f[0] == 999999) {
    warn "Skipping test 5c - couldn't open 'save_child_setting.txt'";
    $ok .= 'c';
  }
  elsif($f[0] == 330 && $f[1] == 340 && $f[2] == 0) {
    $ok .= 'c';
  }
  else {
    warn "\n5c: prec: @f\n";
  }

  if($ok eq 'abc') {print "ok 5\n"}
  else {
    warn "\$ok: $ok\n";
    print "not ok 5\n";
  }

  #######################

}
else {
  warn "Skipping all tests: ${cut_mess}";
  print "ok 1\n";
  print "ok 2\n";
  print "ok 3\n";
  print "ok 4\n";
  print "ok 5\n";
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

