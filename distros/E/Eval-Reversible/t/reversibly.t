#!/usr/bin/perl

use v5.10.1;
use strict;
use warnings;

use Test2::Bundle::More;
use Test2::Tools::Exception;

use Eval::Reversible qw< reversibly to_undo >;

############################################################

# NOTE: Test plans are important because there's a lot of independent pass/fail tests.

subtest 'Basic tests' => sub {
    plan tests => 9;

    # Success
    ok(lives {
        reversibly {
            pass 'Reversible sub was called';
            to_undo { fail 'Undo stack was called' };
            to_undo { fail 'Undo stack was called' };
            to_undo { fail 'Undo stack was called' };
            pass 'Reversible sub finished';
        } 'Fail message should never be seen here';
    }, 'reversibly lives') or note $@;

    # Failure
    my $die_msg = dies {
        reversibly {
            pass 'Reversible sub was called';
            to_undo { pass 'Undo stack was called' };
            to_undo { pass 'Undo stack was called' };
            to_undo { pass 'Undo stack was called' };
            die 'Reversible sub is dying';
            fail 'Reversible sub finished';
        };
    };

    ok defined $die_msg, 'reversibly dies';
    like $die_msg, qr/The exception that caused rollback was: Reversible sub is dying/, 'Correct death message';
};

subtest 'Bad to_undo usage' => sub {
    plan tests => 5;

    like(
        dies {
            to_undo { fail 'Bad to_undo usage' };
        },
        qr/Cannot call to_undo/,
        'to_undo before reversibly dies with proper error',
    );

    # Success
    ok(lives {
        reversibly {
            pass 'Reversible sub was called';
            to_undo { fail 'Undo stack was called' };
            to_undo { fail 'Undo stack was called' };
            to_undo { fail 'Undo stack was called' };
            pass 'Reversible sub finished';
        } 'Fail message should never be seen here';
    }, 'reversibly lives') or note $@;

    like(
        dies {
            to_undo { fail 'Bad to_undo usage' };
        },
        qr/Cannot call to_undo/,
        'to_undo after reversibly dies with proper error',
    );
};

############################################################

done_testing;
