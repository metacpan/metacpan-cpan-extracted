use strict;
use warnings;
use Test::More;
use lib './t';

my @argv = qw(
    --string Alice
    Life
    --number 42
    --list mostly --list harmless
    Universe and
    --hash animal=dolphin --hash fish=babel
    --implicit
    -s -42
    --end 999
    --beeblebrox
    --so-long
    --both 99
    Everything
    );

BEGIN {
    no warnings 'once';
    $App::Foo::DEFAULT_AND_ACTION = 1;
}

use App::Foo;
eval { App::Foo->new };
like($@, qr/both/, "default and action");

done_testing;
