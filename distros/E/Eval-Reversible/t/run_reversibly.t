#!/usr/bin/perl

use v5.10.1;
use strict;
use warnings;

use Test2::Bundle::More;
use Test2::Tools::Exception;

use Eval::Reversible;

############################################################

# NOTE: Test plans are important because there's a lot of independent pass/fail tests.

subtest 'Basic tests' => sub {
    plan tests => 8;

    my $reversible = Eval::Reversible->new(
        failure_warning => 'Fail message should never be seen here',
    );
    isa_ok $reversible, 'Eval::Reversible';

    # Success
    ok(lives {
        $reversible->run_reversibly(sub {
            pass 'Reversible sub was called';
            $reversible->add_undo(sub { fail 'Undo stack was called' });
            pass 'Reversible sub finished';
        });
    }, 'run_reversibly lives') or note $@;

    $reversible->failure_warning('');

    # Failure
    my $die_msg = dies {
        $reversible->run_reversibly(sub {
            pass 'Reversible sub was called';

            # This also tests that the previous undo stack above was automatically cleared out
            $reversible->add_undo(sub { pass 'Undo stack was called' });

            die 'Reversible sub is dying';
            fail 'Reversible sub finished';
        });
    };

    ok defined $die_msg, 'run_reversibly dies';
    like $die_msg, qr/The exception that caused rollback was: Reversible sub is dying/, 'Correct death message';
};

subtest 'Class method call' => sub {
    plan tests => 4;

    # Failure
    my $die_msg = dies {
        Eval::Reversible->run_reversibly(sub {
            my $reversible = shift;
            pass 'Reversible sub was called';
            $reversible->add_undo(sub { pass 'Undo stack was called' });
            die 'Reversible sub is dying';
            fail 'Reversible sub finished';
        });
    };

    ok defined $die_msg, 'run_reversibly dies';
    like $die_msg, qr/The exception that caused rollback was: Reversible sub is dying/, 'Correct death message';
};

subtest 'Larger undo stack' => sub {
    plan tests => 7;

    my $reversible = Eval::Reversible->new;
    isa_ok($reversible, 'Eval::Reversible');

    my $undo = 0;

    # Undo stack order
    my $die_msg = dies {
        $reversible->run_reversibly(sub {
            $reversible->add_undo(sub { $undo++; cmp_ok($undo, '==', 3, 'Third undo coderef ran in order') });
            pass 'Reversible sub was called';
            $reversible->add_undo(sub { $undo++; cmp_ok($undo, '==', 2, 'Second undo coderef ran in order') });
            $reversible->add_undo(sub { $undo++; cmp_ok($undo, '==', 1, 'First undo coderef ran in order') });

            die 'Reversible sub is dying';
            fail 'Reversible sub finished';
        });
    };

    ok defined $die_msg, 'run_reversibly dies';
    like $die_msg, qr/The exception that caused rollback was: Reversible sub is dying/, 'Correct death message';
};

subtest 'Post-reversibly undo execute' => sub {
    plan tests => 7;

    my $reversible = Eval::Reversible->new;
    isa_ok $reversible, 'Eval::Reversible';

    # Success
    ok(lives {
        $reversible->run_reversibly(sub {
            pass 'Reversible sub was called';
            $reversible->add_undo(sub { pass 'Undo stack was called' });
            pass 'Reversible sub finished';
        });
    }, 'run_reversibly lives') or note $@;

    ok !$reversible->is_undo_empty, 'Undo stack is NOT empty';
    $reversible->run_undo;
    ok  $reversible->is_undo_empty, 'Undo stack is empty';
};

subtest 'Stack manipulation' => sub {
    plan tests => 9;

    my $reversible = Eval::Reversible->new;
    isa_ok($reversible, 'Eval::Reversible');

    # pop_undo
    my $die_msg = dies {
        $reversible->run_reversibly(sub {
            $reversible->add_undo(sub { pass 'Undo stack was called' });
            pass 'Reversible sub was called';
            $reversible->add_undo(sub { fail 'This undo coderef should have never ran' });
            $reversible->pop_undo;

            die 'Reversible sub is dying';
            fail 'Reversible sub finished';
        });
    };

    ok defined $die_msg, 'run_reversibly dies';
    like $die_msg, qr/The exception that caused rollback was: Reversible sub is dying/, 'Correct death message';

    # clear_undo
    $die_msg = dies {
        $reversible->run_reversibly(sub {
            $reversible->add_undo(sub { fail 'Undo stack was not cleared' });
            pass 'Reversible sub was called';
            $reversible->add_undo(sub { fail 'Undo stack was not cleared' });
            $reversible->add_undo(sub { fail 'Undo stack was not cleared' });
            $reversible->clear_undo;
            ok $reversible->is_undo_empty, 'Undo stack is empty';

            die 'Reversible sub is dying';
            fail 'Reversible sub finished';
        });
    };

    ok defined $die_msg, 'run_reversibly dies';
    like $die_msg, qr/The exception that caused rollback was: Reversible sub is dying/, 'Correct death message';
};

subtest 'Arm/Disarm' => sub {
    plan tests => 11;

    my $reversible = Eval::Reversible->new;
    isa_ok($reversible, 'Eval::Reversible');

    # External disarm
    $reversible->disarm;

    my $die_msg = dies {
        $reversible->run_reversibly(sub {
            pass 'Reversible sub was called';
            $reversible->add_undo(sub { fail 'Undo stack was called' });
            die 'Reversible sub is dying';
            fail 'Reversible sub finished';
        });
    };

    ok defined $die_msg, 'run_reversibly dies';
    like $die_msg, qr/^Reversible sub is dying/, 'Correct death message (plain version)';

    # Re-arming
    $reversible->arm;

    $die_msg = dies {
        $reversible->run_reversibly(sub {
            pass 'Reversible sub was called';
            $reversible->add_undo(sub { pass 'Undo stack was called' });
            die 'Reversible sub is dying';
            fail 'Reversible sub finished';
        });
    };

    ok defined $die_msg, 'run_reversibly dies';
    like $die_msg, qr/The exception that caused rollback was: Reversible sub is dying/, 'Correct death message';

    # Internal disarm
    $die_msg = dies {
        $reversible->run_reversibly(sub {
            pass 'Reversible sub was called';
            $reversible->add_undo(sub { fail 'Undo stack was called' });
            $reversible->disarm;
            die 'Reversible sub is dying';
            fail 'Reversible sub finished';
        });
    };

    ok defined $die_msg, 'run_reversibly dies';
    like $die_msg, qr/^Reversible sub is dying/, 'Correct death message (plain version)';
};

############################################################

done_testing;
