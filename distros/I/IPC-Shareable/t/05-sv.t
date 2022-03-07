use warnings;
use strict;

use IPC::Shareable;
use Test::More;

BEGIN {
    if (! $ENV{CI_TESTING}) {
        plan skip_all => "Not on a legit CI platform...";
    }
}

tie my $sv, 'IPC::Shareable', {destroy => 1};

$sv = 'foo';
is $sv, 'foo', "SCALAR created ok, and set to 'foo'";

# This is a regression test for the
# bug fixed by using Scalar::Util::reftype
# instead of looking for HASH, SCALAR, ARRAY
# in the stringified version of the scalar.

for my $mod (qw/HASH SCALAR ARRAY/){
    # --- TIESCALAR
    my $sv;
    tie($sv, 'IPC::Shareable', { destroy => 'yes' })
        or die ('this was not expected to die here');

    $sv = $mod.'foo';
    is $sv, $mod.'foo', "SCALAR regression store/fetch ok";
}

done_testing();
