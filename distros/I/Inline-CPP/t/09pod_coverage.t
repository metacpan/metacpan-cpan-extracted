use strict;
use warnings;
use Test::More;


if ( not $ENV{RELEASE_TESTING} ) {
    my $msg =
        'Author Test: Set $ENV{RELEASE_TESTING} to a true value to run.';
    plan( skip_all => $msg );
}


# Satisfy CPANTS, even though all functions are internal.

eval "use Test::Pod::Coverage 1.00"; ## no critic (eval)


plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage"
    if $@;


# Test for Inline::CPP, Inline::grammar, and Inline::CPP::Config (though the
# latter has no functions.

# There really aren't any functions explicitly called by the user. Everything
# is for internal use, and doesn't require POD documentation.
my $trustme = {
    trustme => [
        qr/(?:
              ^_
            | call          # Inline::CPP internal functions.
            | check
            | const
            | get
            | info
            | make
            | register
            | type
            | validate
            | write
            | wrap
            | xs_
        )/x
    ]
};

pod_coverage_ok( 'Inline::CPP',          $trustme );
pod_coverage_ok( 'Inline::CPP::Config',  $trustme );


done_testing();
