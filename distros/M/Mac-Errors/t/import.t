use strict;

use Test::More 0.95;

BEGIN {
    use_ok( 'Mac::Errors', qw( $MacError %MacErrors fnfErr ) );
}

my $count = keys %MacErrors;
ok( $count > 0, 'There are at least some errors' );



my $err = -43;
$! = $err;

my $error = $MacErrors{$err};

cmp_ok( $error->number, '==', $err, 'number() returns the original error' );
cmp_ok( $error->number, '==', fnfErr(), 'number() returns the right number' );

SKIP: {
	skip "You aren't on MacPerl", 1 unless $^O eq 'MacOS';
	is( $error->description, $MacError, '$MacError returns the same description' );
	}
SKIP: {
	skip "You are on MacPerl", 1 if $^O eq 'MacOS';
	ok( ! defined $MacError, '$MacError is undef unless on MacPerl' );
	}

is( $error->symbol, "fnfErr" );

done_testing();
