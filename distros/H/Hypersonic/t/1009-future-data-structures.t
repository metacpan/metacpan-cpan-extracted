#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
plan skip_all => "Hypersonic::Future / ::Pool not supported on native Win32 (POSIX pthread + self-pipe)" if $^O eq "MSWin32";

use Hypersonic::Future;

# Compile Future
Hypersonic::Future->compile();

# Test passing hash references
{
    my $f = Hypersonic::Future->new;
    my $hash = { name => 'test', value => 42, nested => { deep => 'data' } };
    $f->done($hash);
    
    ok($f->is_done, 'future with hashref is done');
    my ($result) = $f->result;
    is(ref($result), 'HASH', 'result is a hashref');
    is($result->{name}, 'test', 'hash key name correct');
    is($result->{value}, 42, 'hash key value correct');
    is($result->{nested}{deep}, 'data', 'nested hash data correct');
}

# Test passing array references
{
    my $f = Hypersonic::Future->new;
    my $array = [1, 2, 3, ['nested', 'array'], { mixed => 'types' }];
    $f->done($array);
    
    ok($f->is_done, 'future with arrayref is done');
    my ($result) = $f->result;
    is(ref($result), 'ARRAY', 'result is an arrayref');
    is_deeply($result, [1, 2, 3, ['nested', 'array'], { mixed => 'types' }], 'array contents correct');
}

# Test passing multiple mixed values
{
    my $f = Hypersonic::Future->new;
    my $hash = { key => 'value' };
    my $array = [1, 2, 3];
    my $scalar = 'string';
    my $number = 3.14159;
    
    $f->done($hash, $array, $scalar, $number);
    
    my @results = $f->result;
    is(scalar(@results), 4, 'got 4 results');
    is(ref($results[0]), 'HASH', 'first result is hashref');
    is(ref($results[1]), 'ARRAY', 'second result is arrayref');
    is($results[2], 'string', 'third result is string');
    is($results[3], 3.14159, 'fourth result is number');
}

# Test passing blessed objects
{
    package TestObject;
    sub new { my $class = shift; bless { @_ }, $class }
    sub get_value { shift->{value} }
    
    package main;
    
    my $f = Hypersonic::Future->new;
    my $obj = TestObject->new(value => 'object_data');
    $f->done($obj);
    
    my ($result) = $f->result;
    isa_ok($result, 'TestObject', 'result is blessed object');
    is($result->get_value, 'object_data', 'object method works');
}

# Test passing code references
{
    my $f = Hypersonic::Future->new;
    my $code = sub { return $_[0] * 2 };
    $f->done($code);
    
    my ($result) = $f->result;
    is(ref($result), 'CODE', 'result is a coderef');
    is($result->(21), 42, 'coderef works correctly');
}

# Test passing undef
{
    my $f = Hypersonic::Future->new;
    $f->done(undef);
    
    my @results = $f->result;
    is(scalar(@results), 1, 'got 1 result');
    ok(!defined($results[0]), 'result is undef');
}

# Test then() with data structures
{
    my $f = Hypersonic::Future->new;
    my $chained = $f->then(sub {
        my ($data) = @_;
        return { processed => $data->{value} * 2 };
    });
    
    $f->done({ value => 21 });
    
    ok($chained->is_done, 'chained future is done');
    my ($result) = $chained->result;
    is(ref($result), 'HASH', 'chained result is hashref');
    is($result->{processed}, 42, 'transformation correct');
}

# Test then() returning multiple data structures
{
    my $f = Hypersonic::Future->new;
    my $chained = $f->then(sub {
        return ({ first => 1 }, [2, 3], 'third');
    });
    
    $f->done('ignored');
    
    my @results = $chained->result;
    is(scalar(@results), 3, 'got 3 results from then');
    is(ref($results[0]), 'HASH', 'first is hash');
    is(ref($results[1]), 'ARRAY', 'second is array');
    is($results[2], 'third', 'third is string');
}

# Test on_done callback receives data structures
{
    my @captured;
    my $f = Hypersonic::Future->new;
    $f->on_done(sub { @captured = @_ });
    
    my $data = { complex => [1, 2, { nested => 'value' }] };
    $f->done($data);
    
    is(scalar(@captured), 1, 'callback received 1 arg');
    is_deeply($captured[0], $data, 'callback received correct data structure');
}

# Test new_done with data structures
{
    my $hash = { created => 'done' };
    my $f = Hypersonic::Future->new_done($hash, [1,2,3]);
    
    ok($f->is_done, 'new_done future is done');
    my @results = $f->result;
    is(ref($results[0]), 'HASH', 'first result is hashref');
    is(ref($results[1]), 'ARRAY', 'second result is arrayref');
}

# Test catch() receives and can return data structures
{
    my $f = Hypersonic::Future->new;
    my $caught = $f->catch(sub {
        my ($error) = @_;
        return { recovered => 1, original_error => $error };
    });
    
    $f->fail('test error');
    
    ok($caught->is_done, 'caught future is done (recovered)');
    my ($result) = $caught->result;
    is(ref($result), 'HASH', 'catch returned hashref');
    is($result->{recovered}, 1, 'recovery flag set');
    is($result->{original_error}, 'test error', 'original error preserved');
}

# Test finally() preserves data structures
{
    my $finally_ran = 0;
    my $f = Hypersonic::Future->new;
    my $final = $f->finally(sub { $finally_ran = 1 });
    
    my $complex = { data => [1, 2, 3], nested => { key => 'value' } };
    $f->done($complex);
    
    ok($finally_ran, 'finally ran');
    ok($final->is_done, 'final future is done');
    my ($result) = $final->result;
    is_deeply($result, $complex, 'finally preserved complex data structure');
}

# Test deeply nested structures survive round-trip
{
    my $deep = {
        level1 => {
            level2 => {
                level3 => {
                    level4 => {
                        data => [1, 2, 3, { inner => 'hash' }]
                    }
                }
            }
        }
    };
    
    my $f = Hypersonic::Future->new;
    $f->done($deep);
    
    my ($result) = $f->result;
    is($result->{level1}{level2}{level3}{level4}{data}[3]{inner}, 'hash', 
       'deeply nested structure survives');
}

# Test large array
{
    my @large = (1..1000);
    my $f = Hypersonic::Future->new;
    $f->done(\@large);
    
    my ($result) = $f->result;
    is(scalar(@$result), 1000, 'large array preserved');
    is($result->[0], 1, 'first element correct');
    is($result->[999], 1000, 'last element correct');
}

# Test self-referential structures (circular refs)
{
    my $circular = { name => 'root' };
    $circular->{self} = $circular;
    
    my $f = Hypersonic::Future->new;
    $f->done($circular);
    
    my ($result) = $f->result;
    is($result->{name}, 'root', 'circular ref base data correct');
    is($result->{self}{name}, 'root', 'circular ref accessible');
    is($result->{self}, $result, 'circular reference preserved');
}

done_testing;
