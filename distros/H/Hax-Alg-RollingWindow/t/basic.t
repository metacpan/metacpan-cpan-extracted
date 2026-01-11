use strict;
use warnings;

use Test::More;

use lib 'lib';
use Hax::Alg::RollingWindow;

sub dies_like {
    my ($code, $re) = @_;
    my $ok = eval { $code->(); 1 };
    my $err = $@;

    ok(!$ok, "dies as expected");
    like($err, $re, "error matches");
}


# --- constructor validation ---

dies_like(sub { Hax::Alg::RollingWindow->new() }, qr/capacity is required/);
dies_like(sub { Hax::Alg::RollingWindow->new(capacity => 0) }, qr/capacity must be > 0/);
dies_like(sub { Hax::Alg::RollingWindow->new(capacity => 'x') }, qr/capacity must be a positive integer/);
dies_like(sub { Hax::Alg::RollingWindow->new(capacity => 5, nope => 1) }, qr/unknown argument 'nope'/);
dies_like(sub { Hax::Alg::RollingWindow->new(capacity => 5, on_evict => 123) }, qr/on_evict must be a CODE reference/);


# --- basic behavior ---

my @evicted;
my $w = Hax::Alg::RollingWindow->new(
    capacity => 3,
    on_evict => sub { push @evicted, $_[0] },
);

ok($w->is_empty, "starts empty");
ok(!$w->is_full,  "starts not full");
is($w->capacity, 3, "capacity accessor");
is($w->size, 0, "size starts 0");
is_deeply([ $w->values ], [], "values empty");
is($w->oldest, undef, "oldest empty");
is($w->newest, undef, "newest empty");

$w->add(10);
is($w->size, 1, "size after add 1");
is_deeply([ $w->values ], [10], "values after add 1");
is($w->oldest, 10, "oldest after add 1");
is($w->newest, 10, "newest after add 1");

$w->add(20, 30);
is($w->size, 3, "size at capacity");
ok($w->is_full, "is_full true");
is_deeply([ $w->values ], [10, 20, 30], "values at capacity");
is($w->oldest, 10, "oldest at capacity");
is($w->newest, 30, "newest at capacity");

# eviction behavior: overwrite-oldest
$w->add(40); # evicts 10
is_deeply(\@evicted, [10], "evicted oldest on overflow");
is_deeply([ $w->values ], [20, 30, 40], "values after overflow 1");
is($w->oldest, 20, "oldest after overflow 1");
is($w->newest, 40, "newest after overflow 1");

# multiple add overflow
$w->add(50, 60); # should evict 20 then 30
is_deeply(\@evicted, [10, 20, 30], "evicted in correct order on multi-add");
is_deeply([ $w->values ], [40, 50, 60], "values after multi-add overflow");
is($w->size, 3, "size stays at cap after multi-add overflow");

# wraparound stress (forces head movement)
$w->add(70, 80, 90, 100);
is_deeply([ $w->values ], [80, 90, 100], "values after many adds (wraparound)");
is_deeply(\@evicted, [10, 20, 30, 40, 50, 60, 70], "eviction list after many adds");

# get() behavior
is($w->get(0), 80, "get(0) oldest");
is($w->get(1), 90, "get(1) middle");
is($w->get(2), 100, "get(2) newest");

is($w->get(3), undef, "get out of range returns undef");
is($w->get(-1), undef, "get negative index returns undef");
is($w->get("abc"), undef, "get non-integer returns undef");
is($w->get(undef), undef, "get undef returns undef");
is($w->get(), undef, "get missing arg returns undef");

# clear() behavior
$w->clear;
ok($w->is_empty, "empty after clear");
ok(!$w->is_full, "not full after clear");
is($w->size, 0, "size 0 after clear");
is_deeply([ $w->values ], [], "values empty after clear");
is($w->oldest, undef, "oldest undef after clear");
is($w->newest, undef, "newest undef after clear");

done_testing;
