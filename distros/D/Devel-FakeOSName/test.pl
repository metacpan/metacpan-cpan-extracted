use strict;

use Test::More;

plan tests => 3;

my ($real, $fake) = $^O eq 'aix' ? qw(aix linux) : qw(linux aix);

require_ok( 'Devel::FakeOSName' );
require Config;
Devel::FakeOSName->import($fake);

is $^O, $fake,  "\$^O";

is $Config::Config{osname}, $fake, "\$Config::Config{osname}";






