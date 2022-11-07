use warnings;
use strict;

use Test::More;

use Devel::Deprecations::Environmental ();

use lib 't/lib';

my @warnings;
$SIG{__WARN__} = sub { @warnings = @_ };

Devel::Deprecations::Environmental->import('Internal::Int64');
if(~0 == 4294967295) {
    is(scalar(@warnings), 0, "didn't gripe about this 32-bit machine being 64-bit");
} else {
    like(
        $warnings[0],
        qr/64 bit integers/,
        "warned about 64 bit integers"
    );
}

done_testing;
