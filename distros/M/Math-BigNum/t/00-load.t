#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok('Math::BigNum') || print "Bail out!\n";
}

diag("Testing Math::BigNum $Math::BigNum::VERSION, Perl $], $^X");

warn "-" x 40, "\n";
warn("# LONG_MIN[1] : ", Math::GMPq::_long_min(),  "\n") if defined(&Math::GMPq::_long_min);
warn("# LONG_MIN[2] : ", Math::BigNum::LONG_MIN,   "\n");
warn("# ULONG_MAX[1]: ", Math::GMPq::_ulong_max(), "\n") if defined(&Math::GMPq::_ulong_max);
warn("# ULONG_MAX[2]: ", Math::BigNum::ULONG_MAX,  "\n");
warn "-" x 40, "\n";
