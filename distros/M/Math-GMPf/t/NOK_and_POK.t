use strict;
use warnings;
use Math::GMPf qw(:mpf);

print "1..38\n";

my $n = '98765' x 1000;
my $r = '98765' x 1000;
my $z;
my $check = 0;

# $Math::GMPf::NOK_POK = 1; # Uncomment to view warnings.

if(Math::GMPf::nok_pokflag() == $check) {print "ok 1\n"}
else {
  warn "\n", Math::GMPf::nok_pokflag(), " != $check\n";
  print "not ok 1\n";
}

adj($n, \$check, 1); # Should do nothing

if($n > 0) { # sets NV slot to inf, and turns on the NOK flag
  adj($n, \$check, 1);
  $z = Math::GMPf->new($n);
}

if(Math::GMPf::nok_pokflag() == $check) {print "ok 2\n"}
else {
  warn "\n", Math::GMPf::nok_pokflag(), " != $check\n";
  print "not ok 2\n";
}

if($z == $r) {print "ok 3\n"}
else {
  warn "$z != $r\n";
  print "not ok 3\n";
}

if(Math::GMPf::nok_pokflag() == $check) {print "ok 4\n"} # No change as $r is not a dualvar.
else {
  warn "\n", Math::GMPf::nok_pokflag(), " != $check\n";
  print "not ok 4\n";
}

my $inf = 999**(999**999); # value is inf, NOK flag is set.
my $nan = $inf / $inf; # value is nan, NOK flag is set.

my $discard = eval{"$inf"}; # POK flag is now also set for $inf (mostly)
$discard    = eval{"$nan"}; # POK flag is now also set for $nan (mostly)

adj($inf, \$check, 1);
$check++ if Math::GMPf::ISSUE_19550;

eval {$z = Math::GMPf->new($inf);};

if($@ =~ /^First arg to Rmpf_init_set_str is not a valid base 10 number/ ||
   $@ =~ /cannot coerce an Inf to a Math::GMPf object/) {print "ok 5\n"}
else {
  warn "\n \$\@: $@\n";
  print "not ok 5\n";
}

if(Math::GMPf::nok_pokflag() == $check) {print "ok 6\n"}
else {
  warn "\n", Math::GMPf::nok_pokflag(), " != $check\n";
  print "not ok 6\n";
}

#if(Rmpf_inf_p($z)) {print "ok 6\n"}
#else {
#  warn "\n Expected inf\n Got $z\n";
#  print "not ok 6\n";
#}

adj($inf, \$check, 1);

if($z != $inf) {print "ok 7\n"}
else {
  warn "$z == inf\n";
  print "not ok 7\n";
}

if(Math::GMPf::nok_pokflag() == $check) {print "ok 8\n"}
else {
  warn "\n", Math::GMPf::nok_pokflag(), " != $check\n";
  print "not ok 8\n";
}

adj($nan, \$check, 1);
$check++ if Math::GMPf::ISSUE_19550;

my $z2;
eval {$z2 = Math::GMPf->new($nan);};

if($@ =~ /^First arg to Rmpf_init_set_str is not a valid base 10 number/ ||
   $@ =~ /cannot coerce a NaN to a Math::GMPf object/ ||
   $@ =~ /^In _Rmpf_set_ld, cannot coerce/) {print "ok 9\n"}
else {
  warn "\n \$\@: $@\n";
  print "not ok 9\n";
}

if(Math::GMPf::nok_pokflag() == $check) {print "ok 10\n"}
else {
  warn "\n", Math::GMPf::nok_pokflag(), " != $check\n";
  print "not ok 10\n";
}

#if(Rmpf_nan_p($z2)) {print "ok 10\n"}
#else {
#  warn "\n Expected nan\n Got $z2\n";
#  print "not ok 10\n";
#}

my $fr = Math::GMPf->new(10);

adj($n, \$check, 1);

my $ret = ($fr > $n);

if(Math::GMPf::nok_pokflag() == $check) {print "ok 11\n"}
else {
  warn "\n", Math::GMPf::nok_pokflag(), " != $check\n";
  print "not ok 11\n";
}

adj($inf, \$check, 1);

$ret = ($fr < $inf);

if(Math::GMPf::nok_pokflag() == $check) {print "ok 12\n"}
else {
  warn "\n", Math::GMPf::nok_pokflag(), " != $check\n";
  print "not ok 12\n";
}

adj($inf, \$check, 1);

$ret = ($fr >= $inf);

if(Math::GMPf::nok_pokflag() == $check) {print "ok 13\n"}
else {
  warn "\n", Math::GMPf::nok_pokflag(), " != $check\n";
  print "not ok 13\n";
}

adj($inf, \$check, 1);

$ret = ($fr <= $inf);

if(Math::GMPf::nok_pokflag() == $check) {print "ok 14\n"}
else {
  warn "\n", Math::GMPf::nok_pokflag(), " != $check\n";
  print "not ok 14\n";
}

adj($inf, \$check, 1);

$ret = ($fr <=> $inf);

if(Math::GMPf::nok_pokflag() == $check) {print "ok 15\n"}
else {
  warn "\n", Math::GMPf::nok_pokflag(), " != $check\n";
  print "not ok 15\n";
}

adj($inf, \$check, 1);

eval {$ret = $fr * $inf;};

if($@ =~ /supplied to Math::GMPf::overload_mul/ ||
   $@ =~ /In Rmpf_set_d, cannot coerce an Inf to a Math::GMPf object/ ||
   $@ =~ /In _Rmpf_set_ld, cannot coerce/) {print "ok 16\n"}
else {
  warn "\n \$\@: $@\n";
  print "not ok 16\n";
}

if(Math::GMPf::nok_pokflag() == $check) {print "ok 17\n"}
else {
  warn "\n", Math::GMPf::nok_pokflag(), " != $check\n";
  print "not ok 17\n";
}

adj($inf, \$check, 1);

eval {$ret = $fr + $inf;};

if($@ =~ /supplied to Math::GMPf::overload_add/ ||
   $@ =~ /In Rmpf_set_d, cannot coerce an Inf to a Math::GMPf object/ ||
   $@ =~ /In _Rmpf_set_ld, cannot coerce/) {print "ok 18\n"}
else {
  warn "\n \$\@: $@\n";
  print "not ok 18\n";
}

if(Math::GMPf::nok_pokflag() == $check) {print "ok 19\n"}
else {
  warn "\n", Math::GMPf::nok_pokflag(), " != $check\n";
  print "not ok 19\n";
}

adj($inf, \$check, 1);

eval {$ret = $fr - $inf;};

if($@ =~ /supplied to Math::GMPf::overload_sub/ ||
   $@ =~ /In Rmpf_set_d, cannot coerce an Inf to a Math::GMPf object/ ||
   $@ =~ /In _Rmpf_set_ld, cannot coerce/) {print "ok 20\n"}
else {
  warn "\n \$\@: $@\n";
  print "not ok 20\n";
}

if(Math::GMPf::nok_pokflag() == $check) {print "ok 21\n"}
else {
  warn "\n", Math::GMPf::nok_pokflag(), " != $check\n";
  print "not ok 21\n";
}

adj($inf, \$check, 1);

eval {$ret = $fr / $inf;};

if($@ =~ /supplied to Math::GMPf::overload_div/ ||
   $@ =~ /In Rmpf_set_d, cannot coerce an Inf to a Math::GMPf object/ ||
   $@ =~ /In _Rmpf_set_ld, cannot coerce/) {print "ok 22\n"}
else {
  warn "\n \$\@: $@\n";
  print "not ok 22\n";
}

if(Math::GMPf::nok_pokflag() == $check) {print "ok 23\n"}
else {
  warn "\n", Math::GMPf::nok_pokflag(), " != $check\n";
  print "not ok 23\n";
}

# adj($inf, \$check, 1); # overload_pow does not currently accept string arguments.

eval {$ret = $inf ** $fr;};

if($@ =~ /^Invalid argument supplied to Math::GMPf::overload_pow/) {print "ok 24\n"}
else {
  warn "\n \$\@: $@\n";
  print "not ok 24\n";
}

if(Math::GMPf::nok_pokflag() == $check) {print "ok 25\n"}
else {
  warn "\n", Math::GMPf::nok_pokflag(), " != $check\n";
  print "not ok 25\n";
}

adj($inf, \$check, 1);

eval {$fr *= $inf;};

if($@ =~ /supplied to Math::GMPf::overload_mul_eq/ ||
   $@ =~ /In Rmpf_set_d, cannot coerce an Inf to a Math::GMPf object/ ||
   $@ =~ /In _Rmpf_set_ld, cannot coerce/) {print "ok 26\n"}
else {
  warn "\n \$\@: $@\n";
  print "not ok 26\n";
}

if(Math::GMPf::nok_pokflag() == $check) {print "ok 27\n"}
else {
  warn "\n", Math::GMPf::nok_pokflag(), " != $check\n";
  print "not ok 27\n";
}

adj($inf, \$check, 1);

eval {$fr += $inf;};

if($@ =~ /supplied to Math::GMPf::overload_add_eq/ ||
   $@ =~ /In Rmpf_set_d, cannot coerce an Inf to a Math::GMPf object/ ||
   $@ =~ /In _Rmpf_set_ld, cannot coerce/) {print "ok 28\n"}
else {
  warn "\n \$\@: $@\n";
  print "not ok 28\n";
}

if(Math::GMPf::nok_pokflag() == $check) {print "ok 29\n"}
else {
  warn "\n", Math::GMPf::nok_pokflag(), " != $check\n";
  print "not ok 29\n";
}

adj($inf, \$check, 1);

eval {$fr -= $inf;};

if($@ =~ /supplied to Math::GMPf::overload_sub_eq/ ||
   $@ =~ /In Rmpf_set_d, cannot coerce an Inf to a Math::GMPf object/ ||
   $@ =~ /In _Rmpf_set_ld, cannot coerce/) {print "ok 30\n"}
else {
  warn "\n \$\@: $@\n";
  print "not ok 30\n";
}

if(Math::GMPf::nok_pokflag() == $check) {print "ok 31\n"}
else {
  warn "\n", Math::GMPf::nok_pokflag(), " != $check\n";
  print "not ok 31\n";
}

adj($inf, \$check, 1);

eval {$fr /= $inf;};

if($@ =~ /supplied to Math::GMPf::overload_div_eq/ ||
   $@ =~ /In Rmpf_set_d, cannot coerce an Inf to a Math::GMPf object/ ||
   $@ =~ /In _Rmpf_set_ld, cannot coerce/) {print "ok 32\n"}
else {
  warn "\n \$\@: $@\n";
  print "not ok 32\n";
}

if(Math::GMPf::nok_pokflag() == $check) {print "ok 33\n"}
else {
  warn "\n", Math::GMPf::nok_pokflag(), " != $check\n";
  print "not ok 33\n";
}

# adj($inf, \$check, 1); # overload_pow does not currently accept string arguments.

eval {$inf **= Math::GMPf->new(1);};

if($@ =~ /^Invalid argument supplied to Math::GMPf::overload_pow/) {print "ok 34\n"}
else {
  warn "\n \$\@: $@\n";
  print "not ok 34\n";
}

if(Math::GMPf::nok_pokflag() == $check) {print "ok 35\n"}
else {
  warn "\n", Math::GMPf::nok_pokflag(), " != $check\n";
  print "not ok 35\n";
}

adj($n, \$check, 1);

$ret = ($z != $n);

if(Math::GMPf::nok_pokflag() == $check) {print "ok 36\n"}
else {
  warn "\n", Math::GMPf::nok_pokflag(), " != $check\n";
  print "not ok 36\n";
}

my $nv = 1.3;
my $s = "$nv";

my $mpf = Math::GMPf->new($nv);

$check++ if GMPF_PV_NV_BUG;

if(Math::GMPf::nok_pokflag() == $check) {print "ok 37\n"}
else {
  warn "\n", Math::GMPf::nok_pokflag(), " != $check\n";
  print "not ok 37\n";
}

if(Math::GMPf::ISSUE_19550) {
  if($] < 5.035010) {
    warn "ISSUE_19550 unexpectedly set\n";
    print "not ok 38\n";
  }
  else {
    warn "ISSUE_19550 set\n";
    print "ok 38\n";
  }
}
else {
  warn "ISSUE_19550 not set\n";
  print "ok 38\n";
}

########

sub adj {
  if(Math::GMPf::_SvNOK($_[0]) && Math::GMPf::_SvPOK($_[0])) {
  ${$_[1]} += $_[2];
  }
}
