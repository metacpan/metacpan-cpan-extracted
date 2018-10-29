
use warnings;
use strict;
use Math::MPFR qw(:mpfr);
use POSIX;

print "1..4\n";

my $have_new = 1;
my ($inex, $p);
my $rop = Math::MPFR->new();

if(!defined(MPFR_VERSION) || 262400 > MPFR_VERSION) {$have_new = 0} # mpfr version is pre 4.1.0

my @op1 = (Math::MPFR->new(200), Math::MPFR->new(-3), Math::MPFR->new(1001));
my @op2 = (Math::MPFR->new(5), Math::MPFR->new(30), Math::MPFR->new(90));


eval {$inex = Rmpfr_dot($rop, \@op1, \@op2, scalar(@op2), MPFR_RNDN);};

if($have_new) {
  if($rop == 91000) {print "ok 1\n"}
  else {
    warn "\nExpected 91000\nGot $rop\n";
    print "not ok 1\n";
  }

  if($inex == 0) {print "ok 2\n"}
  else {
    warn "\nExpected inex == 0\nGot inex == $inex\n";
    print "not ok 2\n";
  }

  push(@op1, 1);

  eval{$inex = Rmpfr_dot($rop, \@op1, \@op2, scalar(@op2) + 1, MPFR_RNDN);};

  if($@ =~ /^2nd last arg to Rmpfr_dot is too large/) {print "ok 3\n"}
  else {
    warn "\n \$\@:\n$@\n";
    print "not ok 3\n";
  }
}
else {
  if($@ =~ /^The Rmpfr_dot function requires mpfr\-4\.1\.0/) {print "ok 1\n"}
  else {
    warn "\n\$\@:\n $@\n";
    print "not ok 1\n";
  }

  warn "\n Skipping tests 2 & 3 - we don't have mpfr-4.1.0 or later\n";
  print "ok 2\nok 3\n";
}

eval {$p = Rmpfr_get_str_ndigits(5, 100);};

if($have_new) {
  my $expected = 1 + POSIX::ceil(100 * log(2) / log(5));
  if($expected == $p) {print "ok 4\n"}
  else {
    warn "\n Expected $expected, got $p\n";
    print "not ok 4\n";
  }
}
else {
  if($@ =~ /^The Rmpfr_get_str_ndigits function requires mpfr\-4\.1\.0/) {print "ok 4\n"}
  else {
    warn "\n \$\@:\n $@\n";
    print "not ok 4\n";
  }
}

