package t::Math::ProvablePrime;

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
use Test::Exception;

use File::Which;

use lib "$FindBin::Bin/lib";

use parent qw(
    Test::Class
);

use Math::ProvablePrime ();

if ( !caller ) {
    my $test_obj = __PACKAGE__->new();
    plan tests => $test_obj->expected_tests(+1);
    $test_obj->runtests();
}

#----------------------------------------------------------------------

sub _ACCEPT_BIGINT_LIBS {
    return qw( Math::BigInt::GMP  Math::BigInt::Pari );
}

sub SKIP_CLASS {
    my ($self) = @_;

    my $bigint_lib = Math::BigInt->config()->{'lib'};

    if (!$self->{'_checked_lib'}) {
        $self->{'_checked_lib'} = 1;

        diag "Your Crypt::Perl::BigInt backend is “$bigint_lib”.";
    }


    if ( !grep { $_ eq $bigint_lib } _ACCEPT_BIGINT_LIBS() ) {
        return "“$bigint_lib” isn’t recognized as a C-based Math::BigInt backend. This module is too slow to be practical without such a backend. Skipping …";
    }

    return;
}

sub test_find : Tests(1) {
    my ($self) = @_;

    my $ossl_bin = File::Which::which('openssl');

    SKIP: {
        skip 'No OpenSSL!', 1 if !$ossl_bin;

        `$ossl_bin prime -hex ff`;
        if ($?) {
            skip "$ossl_bin can’t verify primes from the command line!", 1;
        }

        my $CHECK_COUNT = 5;

        lives_ok(
            sub {
                for ( 1 .. $CHECK_COUNT ) {
                    note "Check $_";
                    my $num_bin = substr( Math::ProvablePrime::find(2048)->as_hex(), 2 );
                    my $ossl_out = `$ossl_bin prime -hex $num_bin`;
                    die $ossl_out if $ossl_out !~ m<is prime>;

                    note "OK";
                }
            },
            "Generated and verified $CHECK_COUNT primes",
        );
    }

    return;
}
