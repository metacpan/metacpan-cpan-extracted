#!perl
use strict;
use warnings;
use Test::More;
use Hyperman::Future;

# The arms of the future core the other files leave: a third on_ready
# callback, a continuation that returns a future, callbacks that die, the
# fail mapper, the empty combinators, and a foreign awaitable of every state
# resolving into ours, cancelled through its own method.

# A duck-typed awaitable: everything hm_any_* asks of a class it does not know.
package Duck;
sub new { my ($class, %o) = @_; bless { %o, cbs => [] }, $class }
sub on_ready { my ($self, $cb) = @_; push @{ $self->{cbs} }, $cb; $cb->($self) if $self->{state}; return $self }
sub is_ready { $_[0]{state} ? 1 : 0 }
sub is_done { ($_[0]{state} || '') eq 'done' }
sub is_failed { ($_[0]{state} || '') eq 'failed' }
sub is_cancelled { ($_[0]{state} || '') eq 'cancelled' }
sub get { @{ $_[0]{values} || [] } }
sub failure { @{ $_[0]{values} || [] } }
sub cancel { my $self = shift; $self->{state} = 'cancelled'; $self->{cancelled}++; $_->($self) for @{ $self->{cbs} }; $self }
sub settle { my ($self, $state, @v) = @_; $self->{state} = $state; $self->{values} = \@v; $_->($self) for @{ $self->{cbs} }; $self }
package main;

# --- three on_ready callbacks share one slot as a list ---
{
    my $f = Hyperman::Future->new;
    my @ran;
    $f->on_ready(sub { push @ran, 1 });
    $f->on_ready(sub { push @ran, 2 });
    $f->on_ready(sub { push @ran, 3 });
    $f->done('x');
    is_deeply(\@ran, [1, 2, 3], 'three callbacks run in order');
}

# --- a continuation that returns a future flattens, one that dies fails ---
{
    my $f = Hyperman::Future->new;
    my $inner = Hyperman::Future->new;
    my $g = $f->followed_by(sub { $inner });
    $f->done('ignored');
    ok(!$g->is_ready, 'the returned future is awaited');
    $inner->done('inner');
    is_deeply([ $g->_values ], ['inner'], 'and its result flows through');

    my $d = Hyperman::Future->new;
    my $dies = $d->followed_by(sub { die "cont boom\n" });
    $d->done;
    ok($dies->is_failed, 'a continuation that dies fails the result');
    like(($dies->_values)[0], qr/cont boom/, 'with its message');

    my $e = Hyperman::Future->new;
    my $empty = $e->followed_by(sub { () });
    $e->done(1);
    is_deeply([ $empty->_values ], [undef], 'a continuation returning nothing is done with undef');

    my $t = Hyperman::Future->new;
    my $then_dies = $t->then(sub { die "then boom\n" });
    $t->done(1);
    ok($then_dies->is_failed, 'a then callback that dies fails the result');
    my $u = Hyperman::Future->new;
    my $passed = $u->then(undef, sub { 'handled' });
    $u->done('kept', 'both');
    is_deeply([ $passed->_values ], ['kept', 'both'], 'then with no done callback passes the values on');

    my $cancel_me = Hyperman::Future->new;
    my $after = $cancel_me->then(sub { 'never' });
    $cancel_me->cancel;
    ok($after->is_cancelled, 'cancelling the input cancels the chained future');
    my $outer = Hyperman::Future->new;
    my $chained = $outer->followed_by(sub { my $in = Hyperman::Future->new; $in });
    $outer->done;
    $chained->cancel;
    ok($chained->is_cancelled, 'cancelling a future waiting on a returned one is cancelled');
}

# --- transform: the fail mapper, a mapper that dies, no mapper ---
{
    my $f = Hyperman::Future->new;
    my $mapped = $f->transform(fail => sub { "mapped: $_[0]" });
    $f->fail("raw\n");
    like(($mapped->_values)[0], qr/^mapped: raw/, 'the fail mapper rewrites the failure');
    my $g = Hyperman::Future->new;
    my $dies = $g->transform(done => sub { die "map boom\n" });
    $g->done(1);
    ok($dies->is_failed, 'a mapper that dies fails the result');
    my $h = Hyperman::Future->new;
    my $plain = $h->transform(done => undef);
    $h->done(7, 8);
    is_deeply([ $plain->_values ], [7, 8], 'no mapper copies the values');
    my $c = Hyperman::Future->new;
    my $tc = $c->transform;
    $c->cancel;
    ok($tc->is_cancelled, 'a cancelled input cancels the transform');
}

# --- the empty combinators ---
{
    my $na = Hyperman::Future->needs_any;
    ok($na->is_failed, 'needs_any on nothing fails');
    like(($na->_values)[0], qr/needs_any on empty list/, 'and says so');
    my $wa = Hyperman::Future->wait_any;
    like(($wa->_values)[0], qr/wait_any on empty list/, 'wait_any on nothing fails too');
    my $all = Hyperman::Future->wait_all;
    ok($all->is_done, 'wait_all on nothing is done');
    my $d1 = Duck->new;
    my $d2 = Duck->new;
    my $any = Hyperman::Future->needs_any($d1, $d2);
    $d1->settle('failed', 'first down');
    ok(!$any->is_ready, 'needs_any waits past one failure');
    $d2->settle('failed', 'second down');
    ok($any->is_failed, 'and fails on the last');
    like(($any->_values)[0], qr/second down/, 'with the last failure');
    my $d3 = Duck->new;
    my $d4 = Duck->new;
    my $need = Hyperman::Future->needs_all($d3, $d4);
    $d3->settle('done', 'ok');
    $d4->cancel;
    ok($need->is_cancelled, 'a cancelled input cancels needs_all');
    my $d5 = Duck->new;
    my $wany = Hyperman::Future->wait_any($d5);
    $d5->cancel;
    ok($wany->is_ready, 'wait_any settles when its only input is cancelled');
}

# --- foreign awaitables of every state ---
{
    my $done = Duck->new;
    my $f = Hyperman::Future->new;
    my $g = $f->followed_by(sub { $done });
    $f->done;
    $done->settle('done', 'quack');
    is_deeply([ $g->_values ], ['quack'], 'a foreign done future resolves ours');

    my $failed = Duck->new;
    my $h = Hyperman::Future->new;
    my $i = $h->followed_by(sub { $failed });
    $h->done;
    $failed->settle('failed', 'honk');
    ok($i->is_failed, 'a foreign failed future fails ours');
    is_deeply([ $i->_values ], ['honk'], 'with its failure');

    my $gone = Duck->new;
    my $j = Hyperman::Future->new;
    my $k = $j->followed_by(sub { $gone });
    $j->done;
    $gone->cancel;
    ok($k->is_cancelled, 'a foreign cancelled future cancels ours');

    my $winner = Duck->new;
    my $loser = Duck->new;
    my $race = Hyperman::Future->wait_any($winner, $loser);
    $winner->settle('done', 'won');
    is($loser->{cancelled}, 1, 'the foreign input that lost is cancelled through its own method');
    is_deeply([ $race->_values ], ['won'], 'and the winner\'s value is the result');

    my $from = Hyperman::Future->from_future(Duck->new->settle('done', 'early'));
    is_deeply([ $from->_values ], ['early'], 'from_future takes a settled foreign future');
    my $pending = Duck->new;
    my $later = Hyperman::Future->from_future($pending);
    $pending->settle('failed', 'late');
    ok($later->is_failed, 'and follows one that settles later');
    my $cp = Duck->new;
    my $cancelled = Hyperman::Future->from_future($cp);
    $cp->cancel;
    ok($cancelled->is_cancelled, 'or is cancelled');
}

# --- get on a failure that carries no message ---
{
    my $bare = Hyperman::Future->fail_future;
    my $err = eval { $bare->get; "none" } // $@;
    like($err, qr/^Failed/, "get on a failure without a message dies with Failed");
}

# --- a CPAN Future on the other side ---
SKIP: {
    skip 'Future is not installed', 4 unless eval { require Future; 1 };
    my $ours = Hyperman::Future->new;
    my $cpan = $ours->as_cpan_future;
    $ours->done('to cpan');
    is_deeply([ $cpan->get ], ['to cpan'], 'a done future reaches its CPAN mirror');
    my $failing = Hyperman::Future->new;
    my $cpanf = $failing->as_cpan_future;
    $failing->fail("cpan fail\n");
    like(scalar $cpanf->failure, qr/cpan fail/, 'and a failure');
    my $cancelling = Hyperman::Future->new;
    my $cpanc = $cancelling->as_cpan_future;
    $cancelling->cancel;
    ok($cpanc->is_cancelled, 'and a cancel');
    my $theirs = Future->new;
    my $mirrored = Hyperman::Future->from_future($theirs);
    $theirs->done('from cpan');
    is_deeply([ $mirrored->_values ], ['from cpan'], 'a CPAN future resolves ours');
}

done_testing;
