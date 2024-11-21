use warnings;
use strict;
use Math::BigInt;
use Math::MPFR qw(:mpfr);
use Config;

# Because of the way I (sisyphus) build this module with MS
# Visual Studio, XSubs that take a filehandle argument might
# not work correctly. It therefore suits my purposes to be
# able to avoid calling (and testing) those XSubs.
# Hence the references to $ENV{SISYPHUS_SKIP} in this script.

my $tests = 7;
$tests = 5 if ($ENV{SISYPHUS_SKIP} || $Config{nvtype} eq '__float128');

print "1..$tests\n";

print  "# Using Math::MPFR version ", $Math::MPFR::VERSION, "\n";
print  "# Using mpfr library version ", MPFR_VERSION_STRING, "\n";
print  "# Using gmp library version ", Math::MPFR::gmp_v(), "\n";

Rmpfr_set_default_prec(80);

my $ok = '';
my $buf;
my $copy = $buf;
my $ul = 123;
my $ret;
my $mpfr1 = Math::MPFR->new(1234567.625);

$ret = Rmpfr_printf("For testing: %.30Rf\n", $mpfr1);

if($ret == 52) {$ok .= 'a'}
else {warn "1a: $ret\n"}

$ok .= 'b' if $ret == Rmpfr_printf("For testing: %.30RNf\n", $mpfr1);
$ok .= 'c' if $ret == Rmpfr_printf("For testing: %.30R*f\n", GMP_RNDN, $mpfr1);
unless($ENV{SISYPHUS_SKIP}) {
  $ok .= 'd' if $ret == Rmpfr_fprintf(\*STDOUT, "For testing: %.30Rf\n", $mpfr1);
  $ok .= 'e' if $ret == Rmpfr_fprintf(\*STDOUT, "For testing: %.30RNf\n", $mpfr1);
  $ok .= 'f' if $ret == Rmpfr_fprintf(\*STDOUT, "For testing: %.30R*f\n", GMP_RNDZ, $mpfr1);
}
$ok .= 'g' if $ret == Rmpfr_sprintf($buf, "For testing: %.30Rf\n", $mpfr1, 200);
$ok .= 'h' if $ret == Rmpfr_sprintf($buf, "For testing: %.30RNf\n", $mpfr1, 200);
$ok .= 'i' if $ret == Rmpfr_sprintf($buf, "For testing: %.30R*f\n", GMP_RNDN, $mpfr1, 60);

if(length($buf) == 52) {$ok .= 'j'}
else {warn "length \$buf: ", length($buf), "\n"}

Math::MPFR::_readonly_on($buf);
eval {Rmpfr_sprintf($buf, "For testing: %.30R*f\n", GMP_RNDN, $mpfr1, 200);};

if($@ =~ /Modification of a read-only value attempted/) {$ok .= 'k'}
else { warn "\n1k: \$\@: $@\n"}

Math::MPFR::_readonly_off($buf);

Rmpfr_sprintf($buf, "For testing: %.30Rf\n", $mpfr1, 200);
$ok .= 'm' if "For testing: 1234567.625000000000000000000000000000\n" eq $buf;

Rmpfr_sprintf($buf, "For testing: %.30RNf\n", $mpfr1, 200);
$ok .= 'n' if "For testing: 1234567.625000000000000000000000000000\n" eq $buf;

Rmpfr_sprintf($buf, "For testing: %.30R*f\n", GMP_RNDU, $mpfr1, 200);
$ok .= 'o' if "For testing: 1234567.625000000000000000000000000000\n" eq $buf;

Rmpfr_sprintf($buf, "For some more testing: %.30Rf\n", $mpfr1, 200);
$ok .= 'p' if "For some more testing: 1234567.625000000000000000000000000000\n" eq $buf;

Rmpfr_sprintf($buf, "For some more testing: %.30RNf\n", $mpfr1, 200);
$ok .= 'q' if "For some more testing: 1234567.625000000000000000000000000000\n" eq $buf;

Rmpfr_sprintf($buf, "For some more testing: %.30R*f\n", GMP_RNDN, $mpfr1, 200);
$ok .= 'r' if "For some more testing: 1234567.625000000000000000000000000000\n" eq $buf;

Rmpfr_sprintf ($buf, "%Pu\n", prec_cast(Rmpfr_get_prec($mpfr1)), 200);

if($buf == 80) {$ok .= 's'}
else {warn "1s: $buf\n"}

Rmpfr_sprintf($buf, "%.30Rb\n", $mpfr1, 200);
if(lc($buf) eq "1.001011010110100001111010000000p+20\n") {$ok .= 't'}
else {warn "1t: $buf\n"}

Rmpfr_sprintf($buf, "%.30RNb\n", $mpfr1, 200);
if(lc($buf) eq "1.001011010110100001111010000000p+20\n") {$ok .= 'u'}
else {warn "1u: $buf\n"}

Rmpfr_sprintf($buf, "%.30R*b\n", GMP_RNDD, $mpfr1, 200);
if(lc($buf) eq "1.001011010110100001111010000000p+20\n") {$ok .= 'v'}
else {warn "1v: $buf\n"}

$ret = Rmpfr_printf("hello world", 0);
if($ret == 11) {$ok .= 'w'}
else {warn "1w: $ret\n"}

$ret = Rmpfr_printf("$ul", 0);
if($ret == 3) {$ok .= 'x'}
else {warn "1x: $ret\n"}

unless($ENV{SISYPHUS_SKIP}) {
  $ret = Rmpfr_fprintf(\*STDOUT, "hello world", 0);
  if($ret == 11) {$ok .= 'y'}
  else {warn "1y: $ret\n"}

  $ret = Rmpfr_fprintf(\*STDOUT, "$ul", 0);
  if($ret == 3) {$ok .= 'z'}
  else {warn "1z: $ret\n"}
}

$ret = Rmpfr_sprintf($buf, "hello world", 0, 15);
if($ret == 11) {$ok .= 'A'}
else {warn "1A: $ret\n"}
if($buf eq 'hello world') {$ok .= 'B'}
else {warn "1B: $buf\n"}

$ret = Rmpfr_sprintf($buf, "$ul", 0, 5);
if($ret == 3) {$ok .= 'C'}
else {warn "\n1C: $ret $buf\n"}
if($buf eq "123") {$ok .= 'D'}
else {warn "\n1D: $buf\n"}

if(!$copy) {$ok .= 'E'}
else {
  warn "\n1l: \$copy: $copy\n";
}

Rmpfr_printf("\n", 0); # Otherwise Test::Harness gets confused

my $expected = $ENV{SISYPHUS_SKIP} ? 'abcghijkmnopqrstuvwxABCDE'
                                   : 'abcdefghijkmnopqrstuvwxyzABCDE';

if($ok eq $expected) {print "ok 1\n"}
else {
  warn "got: $ok\n";
  print "not ok 1 $ok\n";
}

$ok = '';

my $mbi = Math::BigInt->new(123);
eval {Rmpfr_printf("%RNd", $mbi);};
if($@ =~ /Unrecognised object/) {$ok .= 'a'}
else {warn "2a got: $@\n"}

unless($ENV{SISYPHUS_SKIP}) {
  eval {Rmpfr_fprintf(\*STDOUT, "%RDd", $mbi);};
  if($@ =~ /Unrecognised object/) {$ok .= 'b'}
  else {warn "2b got: $@\n"}
}

eval {Rmpfr_sprintf($buf, "%RNd", $mbi, 200);};
if($@ =~ /Unrecognised object/) {$ok .= 'c'}
else {warn "2c got: $@\n"}

# no longer have Rmpfr_sprintf_ret().
#eval {Rmpfr_sprintf_ret("%RUd", $mbi, 200);};
#if($@ =~ /Unrecognised object/) {$ok .= 'd'}
#else {warn "2d got: $@\n"}

$ok .= 'd';

unless($ENV{SISYPHUS_SKIP}) {
  eval {Rmpfr_fprintf(\*STDOUT, "%R*d", GMP_RNDN, $mbi, $ul);};
  if($@ =~ /must take 3 or 4 arguments/) {$ok .= 'e'}
  else {warn "2e got: $@\n"}
}

eval {Rmpfr_sprintf($buf, "%R*d", GMP_RNDN, $mbi, $ul, 50);};
if($@ =~ /must take 4 or 5 arguments/) {$ok .= 'f'}
else {warn "2f got: $@\n"}

eval {Rmpfr_sprintf("%RNd", $mbi);};
if($@ =~ /must take 4 or 5 arguments/) {$ok .= 'g'}
else {warn "2g got: $@\n"}


unless($ENV{SISYPHUS_SKIP}) {
  eval {Rmpfr_fprintf(\*STDOUT, "%R*d", 4, $mbi);};
  if(MPFR_VERSION_MAJOR >= 3) {
    if($@ =~ /Unrecognised object supplied/) {$ok .= 'h'}
    else {warn "2h got: $@\n"}
  }
  else {
    if($@ =~ /Invalid 3rd argument/) {$ok .= 'h'}
    else {warn "2h got: $@\n"}
  }
}

eval {Rmpfr_sprintf("%R*d", 4, $mbi, 50);};

# Changed in response to http://www.cpantesters.org/cpan/report/2c6e2406-6bf5-1014-981d-364b06b49268
# which used mpfr-2.4.2
#if(MPFR_VERSION_MAJOR >= 3) {
  if($@ =~ /Unrecognised object supplied/) {$ok .= 'i'}
  else {warn "2i got: $@\n"}
#}
#else {
#  if($@ =~ /Invalid 3rd argument/) {$ok .= 'i'}
#  else {warn "2i got: $@\n"}
#}

eval {Rmpfr_printf("%R*d", 4, $mbi);};
if(MPFR_VERSION_MAJOR >= 3) {
  if($@ =~ /Unrecognised object supplied/) {$ok .= 'j'}
  else {warn "2j got: $@\n"}
}
else {
  if($@ =~ /Invalid 2nd argument/) {$ok .= 'j'}
  else {warn "2j got: $@\n"}
}

$expected = $ENV{SISYPHUS_SKIP} ? 'acdfgij'
                                : 'abcdefghij';

if($ok eq $expected) {print "ok 2\n"}
else {print "not ok 2 $ok\n"}



# $mpfr1 contains the value 1.234567625e6.

$ok = '';

$ret = Rmpfr_snprintf($buf, 5, "%.0Rf", $mpfr1, 10);

if($buf eq '1234' && $ret == 7) {$ok .= 'a'}
else {warn "3a: $buf $ret\n"}

$ret = Rmpfr_snprintf($buf, 6, "%.0Rf", $mpfr1, 10);

if($ret == 7) {$ok .= 'b'}
else {warn "3b: $ret\n"}

if($buf eq '12345') {$ok .= 'c'}
else {warn "3c: $buf\n"}

if($ok eq 'abc') {print "ok 3\n"}
else {print "not ok 3\n"}

$ok = '';

$ret = Rmpfr_snprintf($buf, 7, "%.0R*f", GMP_RNDD, $mpfr1, 10);

if($buf eq '123456' && $ret == 7) {$ok .= 'a'}
else {warn "4a: $ret\n"}

#Rmpfr_printf("%.0R*f", GMP_RNDD, $mpfr1);

$ret = Rmpfr_snprintf($buf, 6, "%.0R*f", GMP_RNDD, $mpfr1 / 10, 10);

#Rmpfr_printf("%.0R*f", GMP_RNDD, $mpfr1 / 10);

if($ret == 6) {$ok .= 'b'}
else {warn "4b: $ret\n"}

if($buf eq '12345') {$ok .= 'c'}
else {warn "4c: $buf\n"}

if($ok eq 'abc') {print "ok 4\n"}
else {
  warn "4: \$ok: $ok\n";
  print "not ok 4\n";
}

$ok = '';

unless($ENV{SISYPHUS_SKIP}) {
  eval{Rmpfr_fprintf(\*STDOUT, "%Pu\n", GMP_RNDN, 123);};
  if($@ =~ /In Rmpfr_fprintf: The rounding argument is specific to Math::MPFR objects/) {$ok .= 'a'}
  else {warn "\n5a: \$\@: $@\n"}
}

eval{Rmpfr_sprintf ($buf, "%Pu\n", GMP_RNDN, 123, 100);};
if($@ =~ /In Rmpfr_sprintf: The rounding argument is specific to Math::MPFR objects/) {$ok .= 'b'}
else {warn "\n5b: \$\@: $@\n"}

eval{Rmpfr_snprintf ($buf, 10, "%Pu\n", GMP_RNDN, 123, 100);};
if($@ =~ /In Rmpfr_snprintf: The rounding argument is specific to Math::MPFR objects/) {$ok .= 'c'}
else {warn "\n5c: \$\@: $@\n"}

$expected = $ENV{SISYPHUS_SKIP} ? 'bc'
                                : 'abc';
if($ok eq $expected) {print "ok 5\n"}
else {
  warn "5: \$ok: $ok\n";
  print "not ok 5\n";
}

# The following are mainly aimed at checking WIN32_FMT_BUG workaround:

unless($ENV{SISYPHUS_SKIP}) {
  if($Config{nvsize} == 8) {
    my $ret = Rmpfr_fprintf(\*STDOUT, "For testing %%a formatting: %a\n", sqrt(2.0));
    #print "RET: $ret\n";
    if($ret == 48) {print "ok 6\n"}
    else {
      warn "Expected 48 but got $ret\n";
      print "not ok 6\n";
    }

    $ret = Rmpfr_fprintf(\*STDOUT, "For testing %%A formatting: %A\n", sqrt(2.0));
    if($ret == 48) {print "ok 7\n"}
    else {
      warn "Expected 48 but got $ret\n";
      print "not ok 7\n";
    }
  }
  elsif($Config{nvtype} ne '__float128') {
    if(length(sqrt(2.0)) < 25) { # 80-bit extended precision long double
      my $ret = Rmpfr_fprintf(\*STDOUT, "For testing %%La formatting: %La\n", sqrt(2.0));
      #print "RET: $ret\n";
      if($ret == 51 || $ret == 52) {print "ok 6\n"}
      else {
        warn "Expected 51 or 52 but got $ret\n";
        print "not ok 6\n";
      }

      $ret = Rmpfr_fprintf(\*STDOUT, "For testing %%LA formatting: %LA\n", sqrt(2.0));
      if($ret == 51 || $ret == 52) {print "ok 7\n"}
      else {
        warn "Expected 51 or 52 but got $ret\n";
        print "not ok 7\n";
      }
    }
    else { # IEEE 754 long double
      my $ret = Rmpfr_fprintf(\*STDOUT, "For testing %%La formatting: %La\n", sqrt(2.0));
      #print "RET: $ret\n";
      if($ret == 64) {print "ok 6\n"}
      else {
        warn "Expected 64 but got $ret\n";
        print "not ok 6\n";
      }

      $ret = Rmpfr_fprintf(\*STDOUT, "For testing %%LA formatting: %LA\n", sqrt(2.0));
      if($ret == 64) {print "ok 7\n"}
      else {
        warn "Expected 64 but got $ret\n";
        print "not ok 7\n";
      }
    }
  }
}

__END__

