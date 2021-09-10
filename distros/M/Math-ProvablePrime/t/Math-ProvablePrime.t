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
use Test::FailWarnings -allow_deps => 1;
use Test::Exception;

use File::Which;

use lib "$FindBin::Bin/lib";

use parent qw(
    Test::Class
);

use Math::ProvablePrime ();

__PACKAGE__->new()->runtests();

#----------------------------------------------------------------------

sub _ACCEPT_BIGINT_LIBS {
    return qw(
        Math::BigInt::GMP  Math::BigInt::Pari
        Math::BigInt::GMPz Math::BigInt::LTM
    );
}

sub SKIP_CLASS {
    my ($self) = @_;

    my $bigint_lib = Math::BigInt->config()->{'lib'};

    if (!$self->{'_checked_lib'}) {
        $self->{'_checked_lib'} = 1;

        diag "Your Math::BigInt backend is “$bigint_lib”.";
    }


    if ( !grep { $_ eq $bigint_lib } _ACCEPT_BIGINT_LIBS() ) {
        return "I think $bigint_lib is too slow for this test. Skipping …";
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
