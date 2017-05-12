use strict;
use warnings;
use Test::More;
use Devel::TraceUse ();    # disable reporting

my @versions = (
    qw(
        5.1        5.001
        5.01       5.001
        5.005      5.005
        5.5.30     5.00503
        5.005_03   5.00503
        5.6        5.006
        5.06       5.006
        5.006      5.006
        5.6.1      5.006001
        5.6.01     5.006001
        5.6.001    5.006001
        5.06.01    5.006001
        5.006.001  5.006001
        5.010001   5.010001
        5.10       5.01
        5.60       5.06
        5.600      5.6
        9.1        9.001
        9          9
        1.9        1.009
        1.2.3.4.5  1.002003004005
        1.0002.3   1.0002003
        1.00_04    1.0004
        )
);

plan tests => @versions / 2;

while (@versions) {
    my ( $version, $expected ) = splice @versions, 0, 2;
    my $got = Devel::TraceUse::numify($version);
    is( $got, $expected, "$version => $expected" );
}

