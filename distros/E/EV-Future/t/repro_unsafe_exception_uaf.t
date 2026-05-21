use strict;
use warnings;
use Test::More;
use EV;
use EV::Future;

# Unsafe mode + sync exception used to leave ctx->is_freed_ptr pointing at a
# dead stack slot. When async tasks later completed and *_cleanup ran, it
# wrote 1 to that dangling pointer. SAVEDESTRUCTOR_X now clears the field on
# unwind so the later write becomes a no-op.

# Burn stack to make a dangling stack pointer point at meaningful memory.
sub churn {
    my $n = shift;
    my @buf = (1) x 256;
    return $n ? churn($n - 1) : @buf;
}

subtest 'parallel unsafe sync-exception with later async completion' => sub {
    our @w;
    eval {
        parallel([
            sub { my $d = shift; push @w, EV::timer 0.01, 0, sub { $d->() } },
            sub { my $d = shift; $d->(); die "boom\n" },
        ], sub { }, 1);
    };
    is($@, "boom\n", 'exception propagated');

    churn(40);

    eval { EV::run };
    ok(!$@, 'EV::run completed without error') or diag $@;
    @w = ();
};

subtest 'series unsafe sync-exception with async continuation' => sub {
    our @w;
    eval {
        series([
            sub {
                my $d = shift;
                push @w, EV::timer 0.01, 0, sub { $d->() };
                die "boom\n";
            },
            sub { shift->() },
        ], sub { }, 1);
    };
    is($@, "boom\n", 'exception propagated');

    churn(40);

    eval { EV::run };
    ok(!$@, 'EV::run completed without error') or diag $@;
    @w = ();
};

subtest 'parallel_limit unsafe sync-exception with later async completion' => sub {
    our @w;
    eval {
        parallel_limit([
            sub { my $d = shift; push @w, EV::timer 0.01, 0, sub { $d->() } },
            sub { my $d = shift; $d->(); die "boom\n" },
        ], 2, sub { }, 1);
    };
    is($@, "boom\n", 'exception propagated');

    churn(40);

    eval { EV::run };
    ok(!$@, 'EV::run completed without error') or diag $@;
    @w = ();
};

subtest 'race unsafe sync-exception with later async completion' => sub {
    our @w;
    eval {
        race([
            sub { my $d = shift; push @w, EV::timer 0.01, 0, sub { $d->("late") } },
            sub { die "boom\n" },
        ], sub { }, 1);
    };
    is($@, "boom\n", 'exception propagated');

    churn(40);

    eval { EV::run };
    ok(!$@, 'EV::run completed without error') or diag $@;
    @w = ();
};

done_testing;
