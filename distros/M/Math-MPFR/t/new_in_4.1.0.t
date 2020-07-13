
use warnings;
use strict;
use Math::MPFR qw(:mpfr);
use POSIX;

print "1..10\n";

my $have_new = 1;
my ($inex, $p, $ret, $ok);
my $rop = Math::MPFR->new();

if(!defined(MPFR_VERSION) || 262400 > MPFR_VERSION) {$have_new = 0} # mpfr version is pre 4.1.0

my @op1 = (Math::MPFR->new(200), Math::MPFR->new(-3), Math::MPFR->new(1001));
my @op2 = (Math::MPFR->new(5), Math::MPFR->new(30), Math::MPFR->new(90));


eval { $inex = Rmpfr_dot($rop, \@op1, \@op2, scalar(@op2), MPFR_RNDN) };

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

  eval{ $inex = Rmpfr_dot($rop, \@op1, \@op2, scalar(@op2) + 1, MPFR_RNDN) };

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

# Math::MPFR provides its own implementation of Rmpfr_get_str_ndigits,
# namely Rmpfr_get_str_ndigits_alt, when built against a pre-4.1.0 version
# of the MPFR library.

eval { $p = Rmpfr_get_str_ndigits(63, 100) };

if($@) {
  if($@ =~ /^1st argument given to Rmpfr_get_str_ndigits must be in the range 2\.\.62/) {
    print "ok 4\n";
  }
  else {
    warn "\n\$\@: $@\n";
    print "not ok 4\n";
  }
}

else { print "not ok 4\n" }

$ok = 1;

for my $base(2..62) {
  for my $prec(1 .. 1000) {
    $p = Rmpfr_get_str_ndigits($base, $prec);
    my $expected = Rmpfr_get_str_ndigits_alt($base, $prec);;

    if($expected != $p) {
      warn "for base $base, prec $prec bits: $expected != $p\n";
      $ok = 0;
    }
  }
}

if($ok) { print "ok 5\n" }
else    { print "not ok 5\n" }

# Math::MPFR provides its own implementation of Rmpfr_total_order_p
# when built against a pre-4.1.0 version of the MPFR library.

$ok = 1;

my $pnan = Math::MPFR->new();              # NaN
my $nnan = Math::MPFR->new();
Rmpfr_setsign($nnan, $pnan, 1, MPFR_RNDN); # -NaN
my $pinf = Math::MPFR->new(1) / 0;         # Inf
my $ninf = Math::MPFR->new();
Rmpfr_setsign($ninf, $pinf, 1, MPFR_RNDN); # -Inf
my $preal = Math::MPFR->new(2);            # 2
my $nreal = Math::MPFR->new(-2);           # -2
my $pzero = Math::MPFR->new(0);            # 0
my $nzero = Math::MPFR->new(-0.0);         # - 0

Rmpfr_clear_erangeflag();

for([$nnan, $ninf],   [$ninf, $nreal], [$nreal, $nzero], [$nzero, $pzero],
    [$pzero, $preal], [$preal, $pinf], [$pinf, $pnan],   [$nnan, $pnan]) {
  my @x = @{$_};
  if(!Rmpfr_total_order_p($x[0], $x[1])) {
    warn "$x[0] is not less than or equal to $x[1]\n";
    $ok = 0;
  }

  if(Rmpfr_total_order_p($x[1], $x[0])) {
    warn "$x[1] <= $x[0]\n";
   $ok = 0;
  }
}

for([$nnan, $nnan], [$pnan, $pnan], [$nzero, $nzero], [$pzero, $pzero]) {
  my @x = @{$_};
  if(!Rmpfr_total_order_p($x[0], $x[1])) {
    warn "$x[0] != $x[1]\n";
    $ok = 0;
  }

  if(!Rmpfr_total_order_p($x[1], $x[0])) {
    warn "$x[1] is not less than or equal to $x[0]\n";
   $ok = 0;
  }
}

  if($ok) { print "ok 6\n" }
  else    { print "not ok 6\n" }

  # Rmpfr_total_order_p() should not set erangeflag
  if(Rmpfr_erangeflag_p) {
    Rmpfr_clear_erangeflag();
    print "not ok 7\n";
  }
  else { print "ok 7\n" }

eval { $ret = Rmpfr_cmpabs_ui($nreal, 1) };

if($have_new) {

  if($ret > 0) { print "ok 8\n" }
  else {
    warn "$ret <= 0\n";
    print "not ok 8\n";
  }

  Rmpfr_clear_erangeflag();

  $ret = Rmpfr_cmpabs_ui($nnan, 1);

  if($ret == 0) { print "ok 9\n" }
  else {
    warn "$ret != 0\n";
    print "not ok 9\n";
  }

  if(Rmpfr_erangeflag_p()) {
    Rmpfr_clear_erangeflag;
    print "ok 10\n";
  }
  else {
    warn "erangeflag not set\n";
    print "not ok 10\n";
  }
}

else {

  if($@ =~ /^The Rmpfr_cmpabs_ui function requires mpfr\-4\.1\.0/) { print "ok 8\n" }
  else {
    warn "\$\@: $@\n";
    print "not ok 8\n";
  }

  warn "\n Skipping tests 9 & 10 - we don't have mpfr-4.1.0 or later\n";
  print "ok 9\n";
  print "ok 10\n";
}

