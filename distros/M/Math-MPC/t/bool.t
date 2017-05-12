use strict;
use warnings;
use Math::MPC qw(:mpc);
use Math::MPFR qw(:mpfr);

print "1..2\n";

print "# Using mpfr version ", MPFR_VERSION_STRING, "\n";
print "# Using mpc library version ", MPC_VERSION_STRING, "\n";

my $nan = Math::MPC->new();
my $t1 = Math::MPFR->new();
my $t2 = Math::MPFR->new();
my $untrue1 = Math::MPC->new(Math::MPFR->new(), 0);
my $untrue2 = Math::MPC->new(0, Math::MPFR->new());
my $ok = '';
my $flag_clear = 1;

if(Rmpfr_erangeflag_p()) {Rmpfr_clear_erangeflag()}

if(Rmpfr_erangeflag_p()) {
  warn "erange flag did not clear\n";
  $flag_clear = 0;
}

RMPC_RE($t1, $nan);
RMPC_IM($t2, $nan);

if(Rmpfr_nan_p($t1) && Rmpfr_nan_p($t2))
  {$ok .= 'a'}

if(Rmpfr_erangeflag_p() && $flag_clear) {
  warn "Test 1a set the erange flag\n";
  $flag_clear = 0;
}

RMPC_RE($t1, $untrue1);
RMPC_IM($t2, $untrue1);

if(Rmpfr_nan_p($t1) && !Rmpfr_nan_p($t2))
  {$ok .= 'b'}

if(Rmpfr_erangeflag_p() && $flag_clear) {
  warn "Test 1b set the erange flag\n";
  $flag_clear = 0;
}

RMPC_RE($t1, $untrue2);
RMPC_IM($t2, $untrue2);

if(!Rmpfr_nan_p($t1) && Rmpfr_nan_p($t2))
  {$ok .= 'c'}

if(Rmpfr_erangeflag_p() && $flag_clear) {
  warn "Test 1c set the erange flag\n";
  $flag_clear = 0;
}

if(!$nan)       {$ok .= 'd'}
if(Rmpfr_erangeflag_p() && $flag_clear) {
  warn "Test 1d set the erange flag\n";
  $flag_clear = 0;
}

if(!$untrue1)   {$ok .= 'e'}
if(Rmpfr_erangeflag_p() && $flag_clear) {
  warn "Test 1e set the erange flag\n";
  $flag_clear = 0;
}

if(!$untrue2)   {$ok .= 'f'}
if(Rmpfr_erangeflag_p() && $flag_clear) {
  warn "Test 1f set the erange flag\n";
  $flag_clear = 0;
}

if($nan)        {$ok .= 'A'}
if(Rmpfr_erangeflag_p() && $flag_clear) {
  warn "Test 1A set the erange flag\n";
  $flag_clear = 0;
}

if($untrue1)    {$ok .= 'B'}
if(Rmpfr_erangeflag_p() && $flag_clear) {
  warn "Test 1B set the erange flag\n";
  $flag_clear = 0;
}

if($untrue2)    {$ok .= 'C'}
if(Rmpfr_erangeflag_p() && $flag_clear) {
  warn "Test 1C set the erange flag\n";
  $flag_clear = 0;
}

if($ok eq 'abcdef') {print "ok 1\n"}
else {print "not ok 1 $ok\n"}

if(!Rmpfr_erangeflag_p()) {print "ok 2\n"}
else {
  warn "The erangeflag has been set and we don't want that\n";
  print "not ok 2\n";
}

