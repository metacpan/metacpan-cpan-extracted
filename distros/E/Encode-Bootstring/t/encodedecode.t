#!perl -T

use Test::More tests => 3;

BEGIN {
    use_ok( 'Encode::Bootstring' );
}

# Basic test with default values
my $BS = new Encode::Bootstring();
my $raw = 'Búlgarska';
my $enc = $BS->encode( $raw );
my $dec = $BS->decode( $enc );
ok( $enc ne $dec, 'not encoded' );
ok( $dec eq $raw, 'decoded same as original' );
