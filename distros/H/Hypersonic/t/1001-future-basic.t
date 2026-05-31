#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
plan skip_all => "Hypersonic::Future / ::Pool not supported on native Win32 (POSIX pthread + self-pipe)" if $^O eq "MSWin32";

use_ok('Hypersonic::Future');

# Import constants
use Hypersonic::Future qw(
    STATE_PENDING STATE_DONE STATE_FAILED STATE_CANCELLED
    CB_DONE CB_FAIL CB_CANCEL CB_READY
);

# Compile Future (required before use)
Hypersonic::Future->compile();

# Test constants
{
    is(STATE_PENDING, 0, 'STATE_PENDING is 0');
    is(STATE_DONE, 1, 'STATE_DONE is 1');
    is(STATE_FAILED, 2, 'STATE_FAILED is 2');
    is(STATE_CANCELLED, 3, 'STATE_CANCELLED is 3');

    is(CB_DONE, 1, 'CB_DONE is 1');
    is(CB_FAIL, 2, 'CB_FAIL is 2');
    is(CB_CANCEL, 4, 'CB_CANCEL is 4');
    is(CB_READY, 7, 'CB_READY is 7');
}

# Test XS function registry
{
    my $funcs = Hypersonic::Future->get_xs_functions();
    ok($funcs, 'get_xs_functions returns hashref');
    ok(exists $funcs->{'Hypersonic::Future::_new'}, 'has _new');
    ok(exists $funcs->{'Hypersonic::Future::done'}, 'has done');
    ok(exists $funcs->{'Hypersonic::Future::fail'}, 'has fail');
    ok(exists $funcs->{'Hypersonic::Future::then'}, 'has then');
    ok(exists $funcs->{'Hypersonic::Future::catch'}, 'has catch');
}

# Test basic lifecycle - new
{
    my $f = Hypersonic::Future->new;
    ok($f, 'new creates a future');
    isa_ok($f, 'Hypersonic::Future');
    ok(!$f->is_ready, 'new future is not ready');
    ok(!$f->is_done, 'new future is not done');
    ok(!$f->is_failed, 'new future is not failed');
    ok(!$f->is_cancelled, 'new future is not cancelled');
}

# Test done
{
    my $f = Hypersonic::Future->new;
    my $result = $f->done('hello', 'world');
    is($result, $f, 'done returns self');
    ok($f->is_ready, 'done future is ready');
    ok($f->is_done, 'done future is done');
    ok(!$f->is_failed, 'done future is not failed');

    my @values = $f->result;
    is_deeply(\@values, ['hello', 'world'], 'result returns values');
}

# Test fail
{
    my $f = Hypersonic::Future->new;
    $f->fail('Something went wrong', 'test');
    ok($f->is_ready, 'failed future is ready');
    ok(!$f->is_done, 'failed future is not done');
    ok($f->is_failed, 'failed future is failed');

    my ($msg, $cat) = $f->failure;
    is($msg, 'Something went wrong', 'failure message correct');
    is($cat, 'test', 'failure category correct');
}

# Test cancel
{
    my $f = Hypersonic::Future->new;
    $f->cancel;
    ok($f->is_ready, 'cancelled future is ready');
    ok(!$f->is_done, 'cancelled future is not done');
    ok(!$f->is_failed, 'cancelled future is not failed');
    ok($f->is_cancelled, 'cancelled future is cancelled');
}

# Test new_done convenience
{
    my $f = Hypersonic::Future->new_done('value1', 'value2');
    ok($f->is_done, 'new_done creates done future');
    my @values = $f->result;
    is_deeply(\@values, ['value1', 'value2'], 'new_done values correct');
}

# Test new_fail convenience
{
    my $f = Hypersonic::Future->new_fail('Error!', 'category');
    ok($f->is_failed, 'new_fail creates failed future');
    my ($msg, $cat) = $f->failure;
    is($msg, 'Error!', 'new_fail message correct');
    is($cat, 'category', 'new_fail category correct');
}

# Test on_done callback - immediate for done future
{
    my $f = Hypersonic::Future->new;
    $f->done('test');

    my @captured;
    $f->on_done(sub { @captured = @_ });
    is_deeply(\@captured, ['test'], 'on_done invoked immediately for done future');
}

# Test on_done callback - deferred for pending future
{
    my $f = Hypersonic::Future->new;

    my @captured;
    $f->on_done(sub { @captured = @_ });
    is_deeply(\@captured, [], 'on_done not invoked yet for pending future');

    $f->done('deferred', 'value');
    is_deeply(\@captured, ['deferred', 'value'], 'on_done invoked when future completes');
}

# Test on_fail callback
{
    my $f = Hypersonic::Future->new;

    my @captured;
    $f->on_fail(sub { @captured = @_ });

    $f->fail('error message', 'cat');
    is($captured[0], 'error message', 'on_fail receives error message');
    is($captured[1], 'cat', 'on_fail receives category');
}

# Test on_ready callback - any resolution
{
    my $f1 = Hypersonic::Future->new;
    my $f2 = Hypersonic::Future->new;
    my $f3 = Hypersonic::Future->new;

    my ($called1, $called2, $called3) = (0, 0, 0);
    $f1->on_ready(sub { $called1 = 1 });
    $f2->on_ready(sub { $called2 = 1 });
    $f3->on_ready(sub { $called3 = 1 });

    $f1->done('ok');
    $f2->fail('err');
    $f3->cancel;

    ok($called1, 'on_ready called for done');
    ok($called2, 'on_ready called for fail');
    ok($called3, 'on_ready called for cancel');
}

# Test then - chaining on done future
{
    my $f = Hypersonic::Future->new;
    $f->done(10);

    my $f2 = $f->then(sub {
        my ($val) = @_;
        return $val * 2;
    });

    ok($f2, 'then returns new future');
    ok($f2->is_done, 'chained future is done');
    my @result = $f2->result;
    is($result[0], 20, 'then callback result captured');
}

# Test then - chaining on pending future
{
    my $f = Hypersonic::Future->new;

    my $f2 = $f->then(sub {
        my ($val) = @_;
        return $val + 5;
    });

    ok(!$f2->is_ready, 'chained future not ready yet');

    $f->done(10);

    ok($f2->is_done, 'chained future done after parent resolves');
    my @result = $f2->result;
    is($result[0], 15, 'then callback executed with parent result');
}

# Test then - failure propagation
{
    my $f = Hypersonic::Future->new;
    my $f2 = $f->then(sub { return 'should not run' });

    $f->fail('original error', 'test');

    ok($f2->is_failed, 'failure propagates through then');
    my ($msg) = $f2->failure;
    is($msg, 'original error', 'error message preserved');
}

# Test catch - handling failures
{
    my $f = Hypersonic::Future->new;
    $f->fail('oops');

    my $f2 = $f->catch(sub {
        my ($err) = @_;
        return "recovered from: $err";
    });

    ok($f2->is_done, 'catch converts failure to success');
    my @result = $f2->result;
    is($result[0], 'recovered from: oops', 'catch callback result correct');
}

# Test catch - success propagation
{
    my $f = Hypersonic::Future->new;
    $f->done('success!');

    my $f2 = $f->catch(sub { return 'should not run' });

    ok($f2->is_done, 'success propagates through catch');
    my @result = $f2->result;
    is($result[0], 'success!', 'original result preserved');
}

# Test finally - always runs
{
    my $f1 = Hypersonic::Future->new;
    my $f2 = Hypersonic::Future->new;

    my ($cleanup1, $cleanup2) = (0, 0);

    my $c1 = $f1->finally(sub { $cleanup1 = 1 });
    my $c2 = $f2->finally(sub { $cleanup2 = 1 });

    $f1->done('ok');
    $f2->fail('err');

    ok($cleanup1, 'finally runs on success');
    ok($cleanup2, 'finally runs on failure');
    ok($c1->is_done, 'finally preserves success state');
    ok($c2->is_failed, 'finally preserves failure state');
}

# Test chaining complex pipeline
{
    my $f = Hypersonic::Future->new;

    my $result_captured;
    my $finally_ran = 0;

    my $chain = $f
        ->then(sub { $_[0] * 2 })
        ->then(sub { $_[0] + 10 })
        ->catch(sub { 0 })
        ->finally(sub { $finally_ran = 1 });

    $f->done(5);

    ok($chain->is_done, 'complex chain completed');
    my @r = $chain->result;
    is($r[0], 20, 'chain computed correctly: (5 * 2) + 10 = 20');
    ok($finally_ran, 'finally ran in chain');
}

# Test multiple callbacks
{
    my $f = Hypersonic::Future->new;

    my @order;
    $f->on_done(sub { push @order, 'first' });
    $f->on_done(sub { push @order, 'second' });
    $f->on_done(sub { push @order, 'third' });

    $f->done('trigger');

    is_deeply(\@order, ['first', 'second', 'third'], 'callbacks invoked in order');
}

# Test error: done twice
{
    my $f = Hypersonic::Future->new;
    $f->done('first');

    eval { $f->done('second') };
    like($@, qr/already resolved/, 'cannot done twice');
}

# Test error: fail after done
{
    my $f = Hypersonic::Future->new;
    $f->done('done');

    eval { $f->fail('error') };
    like($@, qr/already resolved/, 'cannot fail after done');
}

# Test error: result on pending
{
    my $f = Hypersonic::Future->new;

    eval { $f->result };
    like($@, qr/not done/, 'cannot get result on pending future');
}

# Test error: failure on non-failed
{
    my $f = Hypersonic::Future->new;
    $f->done('ok');

    eval { $f->failure };
    like($@, qr/not failed/, 'cannot get failure on done future');
}

done_testing;
