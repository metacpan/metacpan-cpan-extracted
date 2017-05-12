#!perl -T

use strict;
use warnings;

use Test::More tests => 4;

use Math::BigNum qw(e pi);    # import 'e' and 'pi'

my $e  = Math::BigNum->e;
my $pi = Math::BigNum->pi;

is(e,  $e);
is(pi, $pi);

ok("$e" =~ /^2\.71828182/);
ok("$pi" =~ /^3\.14159265/);
