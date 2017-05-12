use warnings;
use strict;
use Math::MPFR qw(:mpfr);

my $cut = eval 'use threads; 1';

print "1..1\n";

print  "# Using Math::MPFR version ", $Math::MPFR::VERSION, "\n";
print  "# Using mpfr library version ", MPFR_VERSION_STRING, "\n";
print  "# Using gmp library version ", Math::MPFR::gmp_v(), "\n";

if($cut) {
  if($threads::VERSION < 1.71) {
    warn "Skipping this test script - need at least threads-1.71, we have version $threads::VERSION\n";
    print "ok 1\n";
    exit(0);
  }
}

my ($tls, $ok);
eval {$tls =  Rmpfr_buildopt_tls_p();};

my $cut_mess = $cut ? '' : "ithreads not available with this build of perl\n";
my $tls_mess = $tls ? '' :
                           $@ ? "Unable to determine whether mpfr was built with '--enable-thread-safe'\n"
                              : "Your mpfr library was not built with '--enable-thread-safe'\n";

if($cut && $tls) {   # perform tests

####
  my $thr1 = threads->create(
                          {'context' => 'list'},
                      sub {
                           my @ret;
                           $ret[0] = Rmpfr_underflow_p() ? 1 : 0;
                           Rmpfr_set_underflow();
                           $ret[1] = Rmpfr_underflow_p() ? 1 : 0;
                           return @ret;
                          } );

  my @r = $thr1->join();

  if($r[0] == 0 && $r[1] == 1) {$ok .= 'a'}
  else {warn "1a: \$r[0]: $r[0]  \$r[1]: $r[1]\n"}

  if(!Rmpfr_underflow_p()) {$ok .= 'b'}
  else {warn "1b: Underflow set\n"}
####
####
  my $thr2 = threads->create(
                          {'context' => 'list'},
                      sub {
                           my @ret;
                           $ret[0] = Rmpfr_overflow_p() ? 1 : 0;
                           Rmpfr_set_overflow();
                           $ret[1] = Rmpfr_overflow_p() ? 1 : 0;
                           return @ret;
                          } );

  @r = $thr2->join();

  if($r[0] == 0 && $r[1] == 1) {$ok .= 'c'}
  else {warn "1c: \$r[0]: $r[0]  \$r[1]: $r[1]\n"}

  if(!Rmpfr_overflow_p()) {$ok .= 'd'}
  else {warn "1d: Overflow set\n"}
####
####
  my $thr3 = threads->create(
                          {'context' => 'list'},
                      sub {
                           my @ret;
                           $ret[0] = Rmpfr_nanflag_p() ? 1 : 0;
                           Rmpfr_set_nanflag();
                           $ret[1] = Rmpfr_nanflag_p() ? 1 : 0;
                           return @ret;
                          } );

  @r = $thr3->join();

  if($r[0] == 0 && $r[1] == 1) {$ok .= 'e'}
  else {warn "1e: \$r[0]: $r[0]  \$r[1]: $r[1]\n"}

  if(!Rmpfr_nanflag_p()) {$ok .= 'f'}
  else {warn "1f: Nanflag set\n"}
####
####
  my $thr4 = threads->create(
                          {'context' => 'list'},
                      sub {
                           my @ret;
                           $ret[0] = Rmpfr_inexflag_p() ? 1 : 0;
                           Rmpfr_set_inexflag();
                           $ret[1] = Rmpfr_inexflag_p() ? 1 : 0;
                           return @ret;
                          } );

  @r = $thr4->join();

  if($r[0] == 0 && $r[1] == 1) {$ok .= 'g'}
  else {warn "1g: \$r[0]: $r[0]  \$r[1]: $r[1]\n"}

  if(!Rmpfr_inexflag_p()) {$ok .= 'h'}
  else {warn "1h: Inexflag set\n"}
####
####
  my $thr5 = threads->create(
                          {'context' => 'list'},
                      sub {
                           my @ret;
                           $ret[0] = Rmpfr_erangeflag_p() ? 1 : 0;
                           Rmpfr_set_erangeflag();
                           $ret[1] = Rmpfr_erangeflag_p() ? 1 : 0;
                           return @ret;
                          } );

  @r = $thr5->join();

  if($r[0] == 0 && $r[1] == 1) {$ok .= 'i'}
  else {warn "1i: \$r[0]: $r[0]  \$r[1]: $r[1]\n"}

  if(!Rmpfr_erangeflag_p()) {$ok .= 'j'}
  else {warn "1j: Underflow set\n"}
####
####
  my $thr6 = threads->create(
                          {'context' => 'list'},
                      sub {
                           my @ret;
                           $ret[0] = Rmpfr_divby0_p() ? 1 : 0;
                           Rmpfr_set_divby0();
                           $ret[1] = Rmpfr_divby0_p() ? 1 : 0;
                           return @ret;
                          } );

  @r = $thr6->join();

  if($r[0] == 0 && $r[1] == 1) {$ok .= 'k'}
  else {warn "1k: \$r[0]: $r[0]  \$r[1]: $r[1]\n"}

  if(!Rmpfr_divby0_p()) {$ok .= 'l'}
  else {warn "1l: Divide-by-zero set\n"}
####

  if($ok eq 'abcdefghijkl') {print "ok 1\n"}
  else {
    warn "\$ok: $ok\n";
    print "not ok 1\n";
  }

}
else {
  warn "Skipping all tests: ${cut_mess}${tls_mess}";
  print "ok 1\n";
}

