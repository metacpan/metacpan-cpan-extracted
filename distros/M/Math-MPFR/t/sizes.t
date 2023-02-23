use warnings;
use strict;
use Math::MPFR;
use Config;

print "1..4\n";

my @sizes = Math::MPFR::_mp_sizes();

if(@sizes == 3) {print "ok 1\n"}
else {
  warn "scalar(\@sizes): ", scalar(@sizes), "\n";
  print "not ok 1\n";
}

if(Math::MPFR::_ivsize() == $Config::Config{ivsize}) {print "ok 2\n"}
else {
  warn "Math::MPFR::_ivsize(): ", Math::MPFR::_ivsize(), "\n\$Config{ivsize}: $Config::Config{ivsize}\n";
  print "not ok 2\n";
}

if(Math::MPFR::_nvsize() == $Config::Config{nvsize}) {print "ok 3\n"}
else {
  warn "Math::MPFR::_nvsize(): ", Math::MPFR::_nvsize(), "\n\$Config{nvsize}: $Config::Config{nvsize}\n";
  print "not ok 3\n";
}

my $ok = 1;

for(@sizes) {
  unless($_ >= 4 && $_ <= Math::MPFR::_ivsize()) {$ok = 0}
}

if($ok) {print "ok 4\n"}
else {print "not ok 4\n"}
