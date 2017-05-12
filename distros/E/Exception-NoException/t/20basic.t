#!perl
# $Id: /src/Exception-NoException/trunk/t/20basic.t 168 2006-08-16T21:29:24.508066Z josh  $
use Test::More tests => 5;
use Exception::NoException;

my $did_not_die = '';
eval {
    die Exception::NoException->new;
    $did_not_die = 1;
};
my $e = $@;

is( $did_not_die, '', 'Died' );

# Conversion overloading
is( $e,           '', "Stringifies as ''" );
cmp_ok( $e, '==', 0, 'Numifies as 0' );
my $is_false;
if ($e) {
    $is_false = 0;
}
else {
    $is_false = 1;
}
ok( $is_false, 'Boolifies as false' );

is( ref($e),      '', 'No exception' );
