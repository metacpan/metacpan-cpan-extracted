#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
plan skip_all => "Hypersonic::Future / ::Pool not supported on native Win32 (POSIX pthread + self-pipe)" if $^O eq "MSWin32";

use_ok('Hypersonic::Future');

# Compile Future (required before use)
Hypersonic::Future->compile();

# needs_all with all already done
{
    my $f1 = Hypersonic::Future->new_done('a', 'b');
    my $f2 = Hypersonic::Future->new_done('c');
    my $f3 = Hypersonic::Future->new_done('d', 'e', 'f');

    my $all = Hypersonic::Future->needs_all($f1, $f2, $f3);
    ok($all->is_done, 'needs_all with all done futures is done');

    # needs_all now returns flat list of first result from each subfuture
    my @results = $all->result;
    is(scalar(@results), 3, 'needs_all has 3 results');
    is($results[0], 'a', 'first subfuture result');
    is($results[1], 'c', 'second subfuture result');
    is($results[2], 'd', 'third subfuture result');
}

# needs_all with pending futures
{
    my $f1 = Hypersonic::Future->new;
    my $f2 = Hypersonic::Future->new;

    my $all = Hypersonic::Future->needs_all($f1, $f2);
    ok(!$all->is_ready, 'needs_all with pending futures is not ready');

    $f1->done('first');
    ok(!$all->is_ready, 'needs_all still not ready after one done');

    $f2->done('second');
    ok($all->is_done, 'needs_all done after all futures complete');

    my @results = $all->result;
    is($results[0], 'first', 'first result correct');
    is($results[1], 'second', 'second result correct');
}

# needs_all with one failing
{
    my $f1 = Hypersonic::Future->new;
    my $f2 = Hypersonic::Future->new;

    my $all = Hypersonic::Future->needs_all($f1, $f2);

    $f1->fail('error', 'test');
    ok($all->is_failed, 'needs_all fails when any future fails');

    my ($msg, $cat) = $all->failure;
    is($msg, 'error', 'failure message propagated');
    is($cat, 'test', 'failure category propagated');
}

# needs_all with already failed future
{
    my $f1 = Hypersonic::Future->new_fail('already failed', 'category');
    my $f2 = Hypersonic::Future->new_done('ok');

    my $all = Hypersonic::Future->needs_all($f1, $f2);
    ok($all->is_failed, 'needs_all immediately fails with already-failed future');

    my ($msg) = $all->failure;
    is($msg, 'already failed', 'failure message correct');
}

# needs_any with one already done
{
    my $f1 = Hypersonic::Future->new_done('winner');
    my $f2 = Hypersonic::Future->new;

    my $any = Hypersonic::Future->needs_any($f1, $f2);
    ok($any->is_done, 'needs_any with one done is immediately done');

    my @results = $any->result;
    is($results[0], 'winner', 'needs_any has first success result');
}

# needs_any with pending futures
{
    my $f1 = Hypersonic::Future->new;
    my $f2 = Hypersonic::Future->new;

    my $any = Hypersonic::Future->needs_any($f1, $f2);
    ok(!$any->is_ready, 'needs_any with pending futures is not ready');

    $f1->done('first wins');
    ok($any->is_done, 'needs_any done when first succeeds');

    my @results = $any->result;
    is($results[0], 'first wins', 'needs_any has first winner');
}

# needs_any - second one wins
{
    my $f1 = Hypersonic::Future->new;
    my $f2 = Hypersonic::Future->new;

    my $any = Hypersonic::Future->needs_any($f1, $f2);

    $f1->fail('first failed');
    ok(!$any->is_ready, 'needs_any not ready after first fails');

    $f2->done('second wins');
    ok($any->is_done, 'needs_any done when second succeeds');

    my @results = $any->result;
    is($results[0], 'second wins', 'needs_any has second winner');
}

# needs_any - all fail
{
    my $f1 = Hypersonic::Future->new;
    my $f2 = Hypersonic::Future->new;

    my $any = Hypersonic::Future->needs_any($f1, $f2);

    $f1->fail('error1');
    ok(!$any->is_ready, 'needs_any not ready after first fails');

    $f2->fail('error2', 'cat2');
    ok($any->is_failed, 'needs_any fails when all fail');

    my ($msg, $cat) = $any->failure;
    is($msg, 'error2', 'needs_any has last failure message');
    is($cat, 'cat2', 'needs_any has last failure category');
}

# needs_all with cancellation
{
    my $f1 = Hypersonic::Future->new;
    my $f2 = Hypersonic::Future->new;

    my $all = Hypersonic::Future->needs_all($f1, $f2);

    $f1->cancel;
    ok($all->is_cancelled, 'needs_all cancels when any future cancels');
}

# wait_all works like needs_all
{
    my $f1 = Hypersonic::Future->new_done('a');
    my $f2 = Hypersonic::Future->new_done('b');

    my $all = Hypersonic::Future->wait_all($f1, $f2);
    ok($all->is_done, 'wait_all done with done futures');

    my @results = $all->result;
    is($results[0], 'a', 'wait_all first result');
    is($results[1], 'b', 'wait_all second result');
}

# wait_any works like needs_any
{
    my $f1 = Hypersonic::Future->new_done('winner');
    my $f2 = Hypersonic::Future->new;

    my $any = Hypersonic::Future->wait_any($f1, $f2);
    ok($any->is_done, 'wait_any done with first done');

    my @results = $any->result;
    is($results[0], 'winner', 'wait_any has winner');
}

# needs_all with then chaining
{
    my $f1 = Hypersonic::Future->new;
    my $f2 = Hypersonic::Future->new;

    my $result;
    my $chain = Hypersonic::Future->needs_all($f1, $f2)->then(sub {
        my @results = @_;
        $result = \@results;
        return 'chained';
    });

    ok(!$chain->is_ready, 'chained needs_all not ready yet');

    $f1->done('a');
    ok(!$chain->is_ready, 'chained needs_all still not ready');

    $f2->done('b');
    ok($chain->is_done, 'chained needs_all done');

    is(ref($result), 'ARRAY', 'then callback received results array');
    is_deeply($result, ['a', 'b'], 'then callback got flat results');
    is($chain->result, 'chained', 'then transform applied');
}

# needs_any with catch chaining
{
    my $f1 = Hypersonic::Future->new;
    my $f2 = Hypersonic::Future->new;

    my $caught;
    my $chain = Hypersonic::Future->needs_any($f1, $f2)->catch(sub {
        my ($err) = @_;
        $caught = $err;
        return 'recovered';
    });

    $f1->fail('err1');
    $f2->fail('err2');

    ok($chain->is_done, 'catch recovered from needs_any failure');
    is($caught, 'err2', 'catch received error');
    is($chain->result, 'recovered', 'catch transform applied');
}

# Multiple values in needs_any
{
    my $f = Hypersonic::Future->new;
    my $any = Hypersonic::Future->needs_any($f);

    $f->done('a', 'b', 'c');
    ok($any->is_done, 'needs_any done');

    my @results = $any->result;
    is_deeply(\@results, ['a', 'b', 'c'], 'needs_any preserves all values');
}

done_testing;
