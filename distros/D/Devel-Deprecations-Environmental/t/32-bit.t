use warnings;
use strict;

use Test::More;

use Devel::Deprecations::Environmental ();

use lib 't/lib';

my @warnings;
$SIG{__WARN__} = sub { @warnings = @_ };

Devel::Deprecations::Environmental->import('Int32');
if(~0 != 4294967295) { # BUG! But what about 128-bit perl!
    is(scalar(@warnings), 0, "didn't gripe about this 64-bit machine being 32-bit");
} else {
    like(
        $warnings[0],
        qr/32 bit integers/,
        "warned about 32 bit integers"
    );
}

done_testing;
