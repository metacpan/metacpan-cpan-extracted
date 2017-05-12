package t::Math::ProvablePrime::Rand;

use strict;
use warnings;

BEGIN {
    if ( $^V ge v5.10.1 ) {
        require autodie;
    }
}

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More;
use Test::NoWarnings;

use parent qw(
    Test::Class
);

use Math::BigInt ();

use Math::ProvablePrime::Rand ();

if ( !caller ) {
    my $test_obj = __PACKAGE__->new();
    plan tests => $test_obj->expected_tests(+1);
    $test_obj->runtests();
}

#----------------------------------------------------------------------

sub test_int : Tests(2) {
    my $TIME_LIMIT = 10;    #seconds

    my $start = time;

    my $n = 0;

    eval {
        while ( time < ($start + $TIME_LIMIT) ) {
            $n++;
            my @nums =  map { int rand 0xffffffff } 0, 1;

            @nums = sort { $a <=> $b } @nums;

            my $int = Math::ProvablePrime::Rand::int( @nums );
            die "$int < $nums[0]" if $int < $nums[0];
            die "$int > $nums[1]" if $int > $nums[1];
        }
    };

    ok( !$@, "scalar limits ($n times)" ) or diag $@;

    $n = 0;
    $start = time;

    eval {
        while ( time < ($start + $TIME_LIMIT) ) {
            $n++;
            my @nums = map {
                my @pieces = map { int rand 0xffffffff } 0 .. 3;
                my $hex = join q<>, map { sprintf '%08x', $_ } @pieces;
                Math::BigInt->from_hex($hex);
            } 0, 1;

            @nums = sort { $a <=> $b } @nums;

            my $int = Math::ProvablePrime::Rand::int( @nums );
            die "$int < $nums[0]" if $int < $nums[0];
            die "$int > $nums[1]" if $int > $nums[1];
        }
    };

    ok( !$@, "Math::BigInt limits ($n times)" ) or diag $@;

    return;
}
