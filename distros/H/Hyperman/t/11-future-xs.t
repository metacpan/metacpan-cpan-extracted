#!perl
use strict;
use warnings;
use Test::More;
use Hyperman::Future;

sub F { Hyperman::Future->new }

# ---- transform -----------------------------------------------------------
{
    my $f = F();
    my $g = $f->transform(done => sub { map { $_ * 2 } @_ });
    $f->done(1, 2, 3);
    is_deeply([$g->get], [2, 4, 6], 'transform done rewrites result values');
}
{
    my $f = F();
    my $g = $f->transform(fail => sub { "wrapped: $_[0]" });
    $f->fail("inner\n");
    is($g->failure, "wrapped: inner\n", 'transform fail rewrites failure');
}

# ---- wait_any ------------------------------------------------------------
{
    my ($a, $b) = (F(), F());
    my $any = Hyperman::Future->wait_any($a, $b);
    $b->fail("first\n");
    ok($any->is_ready && $any->is_failed, 'wait_any takes the first outcome, even failure');
    is($any->failure, "first\n", 'failure carried');
    $a->done('late');
    ok($any->is_failed, 'later result ignored');
}

# ---- cancel propagates up a then-chain ----------------------------------
{
    my $f = F();
    my $g = $f->then(sub { 'never' });
    $g->cancel;
    ok($g->is_cancelled, 'derived future cancelled');
    ok($f->is_cancelled, 'cancellation propagated to pending upstream');
}
{
    my $f = F()->done('already');
    my $g = $f->then(sub { 'ran' });
    my $h = $g->then(sub { $_[0] });
    $h->cancel;
    ok(!$f->is_cancelled, 'resolved upstream untouched by cancel');
}

# ---- long then-chain runs with bounded stack (trampolined) ---------------
{
    my $f = F();
    my $g = $f;
    $g = $g->then(sub { $_[0] + 1 }) for 1 .. 50_000;
    $f->done(0);
    is(scalar($g->get), 50_000, '50k-deep then-chain resolves (no deep recursion)');
}

# ---- failure keeps extra detail values -----------------------------------
{
    my $f = F();
    $f->fail("msg\n", 'category', 'detail1', 'detail2');
    my @err = $f->failure;
    is_deeply(\@err, ["msg\n", 'category', 'detail1', 'detail2'],
        'failure list keeps category and details');
    is(scalar($f->failure), "msg\n", 'scalar failure is the message');
}

# ---- exceptions that are objects survive get -----------------------------
{
    my $f = F();
    $f->fail({ code => 42 });
    ok(!eval { $f->get; 1 }, 'get dies on ref failure');
    is_deeply($@, { code => 42 }, 'ref exception rethrown intact');
}

# ---- CPAN Future interop -------------------------------------------------
SKIP: {
    skip 'CPAN Future not installed', 4 unless eval { require Future; 1 };

    my $f = F();
    my $cf = $f->as_cpan_future;
    isa_ok($cf, 'Future', 'as_cpan_future');
    $f->done('over');
    is(scalar($cf->get), 'over', 'resolution mirrored into CPAN Future');

    my $other = Future->new;
    my $hf = Hyperman::Future->from_future($other);
    isa_ok($hf, 'Hyperman::Future', 'from_future');
    $other->done('back');
    is(scalar($hf->get), 'back', 'resolution mirrored from CPAN Future');
}

done_testing;
