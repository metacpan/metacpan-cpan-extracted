#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

BEGIN {

my @Modules = qw{
    Mail::TLSRPT
    Mail::TLSRPT::Pragmas
    Mail::TLSRPT::Policy
    Mail::TLSRPT::Failure
    Mail::TLSRPT::Report
};

    plan tests => scalar @Modules;

    foreach my $Module ( @Modules ) {
        use_ok( $Module ) || print "Bail out!";
    }

}
