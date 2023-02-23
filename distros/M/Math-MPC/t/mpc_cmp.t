use warnings;
use strict;
use Math::MPFR qw(:mpfr);
use Math::MPC qw(:mpc);

print "1..2\n";

my $m1 = Math::MPC->new(0, 0);
my $m2 = Math::MPC->new(0, 0);
my $m3 = Math::MPC->new(0, 1);
my $m4 = Math::MPC->new(-230, 0);
my $m5 = Math::MPC->new(-3, -7);
my $ok = '';

$ok .= 'a' if !Rmpc_cmp($m1, $m2);
$ok .= 'b' if $m1 == $m2;
$ok .= 'c' if Rmpc_cmp($m3, $m1);
$ok .= 'd' if $m3 != $m2;
$ok .= 'e' if Rmpc_cmp($m3, $m4);
$ok .= 'f' if $m3 != $m4;

if($ok eq 'abcdef') {print "ok 1\n"}
else {print "not ok 1 $ok \n"}

$ok = '';

$ok .= 'a' if !$m1;
$ok .= 'b' unless !$m3;
$ok .= 'c' unless !$m4;
$ok .= 'd' unless Rmpc_cmp_si($m4, -230);
$ok .= 'e' unless Rmpc_cmp_si_si($m5, -3, -7);

if($ok eq 'abcde') {print "ok 2\n"}
else {print "not ok 2 $ok \n"}
