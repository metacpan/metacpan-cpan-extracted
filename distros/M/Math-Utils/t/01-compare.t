#!perl -T
use 5.010001;
use strict;
use warnings;
use Test::More tests => 13;

use Math::Utils qw(:compare);

my $fltcmp = generate_fltcmp();         # Use default tolerance.

ok(&$fltcmp(sqrt(2), 1.414213562) == 0, "sqrt(2) check.");

#
# In order, the comparison ops are eq, ne, gt, ge, lt, le.
# For simple testing, use a big tolerance of one half.
#
my(@relfs) = generate_relational(0.5);

#
# x positive, y positive.
#
my $x = 1;
my $y = 1.25;
my $pass = join("", map{&$_($x, $y)} @relfs);
ok($pass eq "100101", "$x op $y check returns $pass.");

$y = 1.5;
$pass = join("", map{&$_($x, $y)} @relfs);
ok($pass eq "100101", "$x op $y check returns $pass.");

$y = 1.75;
$pass = join("", map{&$_($x, $y)} @relfs);
ok($pass eq "010011", "$x op $y check returns $pass.");

#
# x negative, y negative.
#
$x = -1;
$y = -1.25;
$pass = join("", map{&$_($x, $y)} @relfs);
ok($pass eq "100101", "$x op $y check returns $pass.");

$y = -1.5;
$pass = join("", map{&$_($x, $y)} @relfs);
ok($pass eq "100101", "$x op $y check returns $pass.");

$y = -1.75;
$pass = join("", map{&$_($x, $y)} @relfs);
ok($pass eq "011100", "$x op $y check returns $pass.");

#
# x positive, y negative.
#
$x = 1;
$y = -1.25;
$pass = join("", map{&$_($x, $y)} @relfs);
ok($pass eq "011100", "$x op $y check returns $pass.");

$y = -1.5;
$pass = join("", map{&$_($x, $y)} @relfs);
ok($pass eq "011100", "$x op $y check returns $pass.");

$y = -1.75;
$pass = join("", map{&$_($x, $y)} @relfs);
ok($pass eq "011100", "$x op $y check returns $pass.");

#
# x negative, y positive.
#
$x = -1;
$y = 1.25;
$pass = join("", map{&$_($x, $y)} @relfs);
ok($pass eq "010011", "$x op $y check returns $pass.");

$y = 1.5;
$pass = join("", map{&$_($x, $y)} @relfs);
ok($pass eq "010011", "$x op $y check returns $pass.");

$y = 1.75;
$pass = join("", map{&$_($x, $y)} @relfs);
ok($pass eq "010011", "$x op $y check returns $pass.");

