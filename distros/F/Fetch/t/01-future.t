#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use Fetch;

plan tests => 19;

# ---- resolution + state --------------------------------------------------
{
    my $f = Fetch::Future->new;
    ok(!$f->is_ready, 'new future is pending');
    $f->done(1, 2, 3);
    ok($f->is_ready && $f->is_done, 'done -> ready/done');
    is_deeply([$f->get], [1, 2, 3], 'get returns all values');
    is(scalar($f->get), 1, 'get in scalar returns first value');
}

# ---- failure -------------------------------------------------------------
{
    my $f = Fetch::Future->new;
    $f->fail("boom\n");
    ok($f->is_failed, 'fail -> failed');
    is(scalar($f->failure), "boom\n", 'failure() returns the reason');
    my $died = !eval { $f->get; 1 };
    ok($died && $@ eq "boom\n", 'get on a failed future rethrows');
}

# ---- cancel --------------------------------------------------------------
{
    my $f = Fetch::Future->new;
    $f->cancel;
    ok($f->is_cancelled, 'cancel -> cancelled');
}

# ---- on_done / on_fail ---------------------------------------------------
{
    my (@d, @e);
    my $f = Fetch::Future->new;
    $f->on_done(sub { @d = @_ });
    $f->on_fail(sub { @e = @_ });
    $f->done('yay');
    is_deeply(\@d, ['yay'], 'on_done fired with values');
    is_deeply(\@e, [],      'on_fail not fired on success');

    my $g = Fetch::Future->new;
    my @ge;
    $g->on_fail(sub { @ge = @_ });
    $g->fail('nope');
    is_deeply(\@ge, ['nope'], 'on_fail fired on failure');
}

# ---- then / else / followed_by / transform -------------------------------
{
    my $f = Fetch::Future->new;
    my $chained = $f->then(sub { Fetch::Future->done_future($_[0] * 2) });
    $f->done(21);
    is(scalar($chained->get), 42, 'then maps the value');

    my $e = Fetch::Future->new;
    my $rescued = $e->else(sub { Fetch::Future->done_future('recovered') });
    $e->fail('x');
    is(scalar($rescued->get), 'recovered', 'else rescues a failure');

    my $t = Fetch::Future->new;
    my $tr = $t->transform(done => sub { "[$_[0]]" });
    $t->done('v');
    is(scalar($tr->get), '[v]', 'transform reshapes the value');
}

# ---- combinators ---------------------------------------------------------
{
    my ($a, $b) = (Fetch::Future->new, Fetch::Future->new);
    my $all = Fetch::Future->needs_all($a, $b);
    $a->done(1); ok(!$all->is_ready, 'needs_all pending until all done');
    $b->done(2); ok($all->is_done,   'needs_all done when all done');

    my ($c, $d) = (Fetch::Future->new, Fetch::Future->new);
    my $any = Fetch::Future->needs_any($c, $d);
    $c->done('first');
    ok($any->is_done, 'needs_any done on first success');
}

# ---- CPAN Future interop -------------------------------------------------
SKIP: {
    skip 'Future not installed', 2 unless eval { require Future; 1 };
    my $n  = Fetch::Future->new;
    my $cf = $n->as_cpan_future;
    isa_ok($cf, 'Future', 'as_cpan_future');
    $n->done(7);
    is(scalar($cf->get), 7, 'CPAN future resolves with our value');
}
