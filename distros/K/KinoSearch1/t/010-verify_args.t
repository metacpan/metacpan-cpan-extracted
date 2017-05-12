use strict;
use warnings;

use Test::More tests => 6;

BEGIN { use_ok( 'KinoSearch1::Util::VerifyArgs', qw( kerror verify_args ) ) }

my %defaults = ( foo => 'FOO', bar => 'BAR' );

sub check {
    return verify_args( \%defaults, @_ );
}

my $dest = {};

my $ret = check( odd => 'number', of => );
is( $ret, 0, "An odd number of args fails verify_args" );
like( kerror(), qr/odd/, "verify_args sets the right error string" );

$ret = check( bad => 'badness' );
is( $ret, 0, "An invalid arg chokes verify_args" );
like( kerror(), qr/invalid/i, "verify_args sets the right error string" );

$ret = check( foo => 'boo' );
is( $ret, 1, "A valid arg passes verify_args" );
