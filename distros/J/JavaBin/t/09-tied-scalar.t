use strict;
use warnings;

use JavaBin;
use Test::More;
use Tie::Scalar;

tie my $scalar, 'Tie::StdScalar';

for ( 'undef', '123', '"foo"', '[qw/foo bar/]', '{qw/foo bar/}' ) {
    eval "\$scalar = $_";

    is_deeply from_javabin( to_javabin $scalar ), $scalar, "tied $_ can round-trip";
}

done_testing;
