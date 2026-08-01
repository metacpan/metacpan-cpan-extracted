#!perl
use strict;
use warnings;
use Test::More;
use Hyperman::Future;

sub F { Hyperman::Future->new }

# ---- basic done ----------------------------------------------------------
{
    my $f = F();
    ok(!$f->is_ready, 'pending');
    my @got;
    $f->on_done(sub { @got = @_ });
    $f->done(1, 2, 3);
    ok($f->is_ready && $f->is_done, 'done');
    is_deeply(\@got, [1,2,3], 'on_done fired with values');
    is_deeply([$f->get], [1,2,3], 'get returns values');
    is(scalar($f->get), 1, 'scalar get first value');
}

# ---- callback registered after completion fires immediately --------------
{
    my $f = F()->done('x');
    my $got;
    $f->on_done(sub { $got = shift });
    is($got, 'x', 'late on_done fires immediately');
}

# ---- fail ----------------------------------------------------------------
{
    my $f = F();
    my $err;
    $f->on_fail(sub { $err = shift });
    $f->fail("boom\n");
    ok($f->is_failed, 'failed');
    is($err, "boom\n", 'on_fail fired');
    is($f->failure, "boom\n", 'failure()');
    ok(!eval { $f->get; 1 }, 'get dies on failure');
    is($@, "boom\n", 'get rethrows failure');
}

# ---- then chaining (value) -----------------------------------------------
{
    my $f = F();
    my $g = $f->then(sub { my $v = shift; $v * 2 });
    $f->done(21);
    is(scalar($g->get), 42, 'then transforms value');
}

# ---- then chaining (returns a future) ------------------------------------
{
    my $f = F();
    my $inner = F();
    my $g = $f->then(sub { $inner });
    $f->done('go');
    ok(!$g->is_ready, 'chained future waits on inner');
    $inner->done('deep');
    is(scalar($g->get), 'deep', 'then flattens returned future');
}

# ---- then propagates failure past on_done --------------------------------
{
    my $f = F();
    my $g = $f->then(sub { 'never' });
    $f->fail("bad\n");
    ok($g->is_failed, 'failure skips on_done and propagates');
    is($g->failure, "bad\n", 'failure carried through then');
}

# ---- else recovers -------------------------------------------------------
{
    my $f = F();
    my $g = $f->else(sub { 'recovered' });
    $f->fail("oops\n");
    is(scalar($g->get), 'recovered', 'else recovers from failure');
}

# ---- exception in callback becomes failure -------------------------------
{
    my $f = F();
    my $g = $f->then(sub { die "in cb\n" });
    $f->done(1);
    ok($g->is_failed, 'die in then becomes failure');
    like($g->failure, qr/in cb/, 'exception captured');
}

# ---- needs_all -----------------------------------------------------------
{
    my ($a, $b) = (F(), F());
    my $all = Hyperman::Future->needs_all($a, $b);
    $a->done('A');
    ok(!$all->is_ready, 'needs_all waits for all');
    $b->done('B');
    is_deeply([$all->get], ['A','B'], 'needs_all collects results');
}

# ---- needs_all fails fast ------------------------------------------------
{
    my ($a, $b) = (F(), F());
    my $all = Hyperman::Future->needs_all($a, $b);
    $a->fail("nope\n");
    ok($all->is_failed, 'needs_all fails fast');
    is($all->failure, "nope\n", 'first failure wins');
}

# ---- wait_all ------------------------------------------------------------
{
    my ($a, $b) = (F(), F());
    my $all = Hyperman::Future->wait_all($a, $b);
    $a->fail("x\n"); $b->done('ok');
    ok($all->is_ready && $all->is_done, 'wait_all ready when all ready, regardless of outcome');
}

# ---- needs_any -----------------------------------------------------------
{
    my ($a, $b) = (F(), F());
    my $any = Hyperman::Future->needs_any($a, $b);
    $a->fail("a\n");
    ok(!$any->is_ready, 'needs_any keeps waiting after one failure');
    $b->done('winner');
    is(scalar($any->get), 'winner', 'needs_any yields first success');
}

# ---- cancel --------------------------------------------------------------
{
    my $f = F();
    $f->cancel;
    ok($f->is_cancelled && $f->is_ready, 'cancelled');
}

done_testing;
