#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use LRU::Cache;

# Test $cache->oldest and $cache->newest methods

subtest 'oldest on empty cache' => sub {
    my $c = LRU::Cache::new(5);
    my @result = $c->oldest;
    is(scalar @result, 0, 'oldest returns empty list on empty cache');
};

subtest 'newest on empty cache' => sub {
    my $c = LRU::Cache::new(5);
    my @result = $c->newest;
    is(scalar @result, 0, 'newest returns empty list on empty cache');
};

subtest 'oldest/newest with single entry' => sub {
    my $c = LRU::Cache::new(5);
    $c->set('only', 42);
    
    my ($ok, $ov) = $c->oldest;
    is($ok, 'only', 'oldest key is only entry');
    is($ov, 42, 'oldest value correct');
    
    my ($nk, $nv) = $c->newest;
    is($nk, 'only', 'newest key is only entry');
    is($nv, 42, 'newest value correct');
};

subtest 'oldest returns LRU entry' => sub {
    my $c = LRU::Cache::new(5);
    $c->set('a', 1);
    $c->set('b', 2);
    $c->set('c', 3);
    
    my ($key, $val) = $c->oldest;
    is($key, 'a', 'oldest is first inserted');
    is($val, 1, 'oldest value correct');
};

subtest 'newest returns MRU entry' => sub {
    my $c = LRU::Cache::new(5);
    $c->set('a', 1);
    $c->set('b', 2);
    $c->set('c', 3);
    
    my ($key, $val) = $c->newest;
    is($key, 'c', 'newest is last inserted');
    is($val, 3, 'newest value correct');
};

subtest 'get promotes to newest' => sub {
    my $c = LRU::Cache::new(5);
    $c->set('a', 1);
    $c->set('b', 2);
    $c->set('c', 3);
    
    $c->get('a');  # Promote 'a' to front
    
    my ($nk, $nv) = $c->newest;
    is($nk, 'a', 'after get, accessed entry becomes newest');
    is($nv, 1, 'newest value correct after get');
    
    my ($ok, $ov) = $c->oldest;
    is($ok, 'b', 'oldest is now b');
};

subtest 'set updates newest' => sub {
    my $c = LRU::Cache::new(5);
    $c->set('a', 1);
    $c->set('b', 2);
    $c->set('a', 10);  # Update 'a', should move to front
    
    my ($nk, $nv) = $c->newest;
    is($nk, 'a', 'updated entry becomes newest');
    is($nv, 10, 'newest has updated value');
};

subtest 'eviction updates oldest' => sub {
    my $c = LRU::Cache::new(3);
    $c->set('a', 1);
    $c->set('b', 2);
    $c->set('c', 3);
    $c->set('d', 4);  # Evicts 'a'
    
    my ($ok, $ov) = $c->oldest;
    is($ok, 'b', 'oldest is now b after a was evicted');
    is($ov, 2, 'oldest value correct');
    
    my ($nk, $nv) = $c->newest;
    is($nk, 'd', 'newest is newly inserted');
    is($nv, 4, 'newest value correct');
};

subtest 'delete affects oldest/newest' => sub {
    my $c = LRU::Cache::new(5);
    $c->set('a', 1);
    $c->set('b', 2);
    $c->set('c', 3);
    
    $c->delete('c');  # Delete newest
    my ($nk, $nv) = $c->newest;
    is($nk, 'b', 'newest updated after delete');
    
    $c->delete('a');  # Delete oldest
    my ($ok, $ov) = $c->oldest;
    is($ok, 'b', 'oldest updated after delete');
};

subtest 'clear empties oldest/newest' => sub {
    my $c = LRU::Cache::new(5);
    $c->set('a', 1);
    $c->set('b', 2);
    $c->clear;
    
    my @oldest = $c->oldest;
    my @newest = $c->newest;
    is(scalar @oldest, 0, 'oldest empty after clear');
    is(scalar @newest, 0, 'newest empty after clear');
};

# Test function-style API
package FuncStyleTest;
use LRU::Cache qw(import);

Test::More::subtest 'lru_oldest function' => sub {
    my $c = LRU::Cache::new(5);
    $c->set('x', 10);
    $c->set('y', 20);
    
    my ($key, $val) = lru_oldest($c);
    Test::More::is($key, 'x', 'lru_oldest returns oldest key');
    Test::More::is($val, 10, 'lru_oldest returns oldest value');
};

Test::More::subtest 'lru_newest function' => sub {
    my $c = LRU::Cache::new(5);
    $c->set('x', 10);
    $c->set('y', 20);
    
    my ($key, $val) = lru_newest($c);
    Test::More::is($key, 'y', 'lru_newest returns newest key');
    Test::More::is($val, 20, 'lru_newest returns newest value');
};

Test::More::subtest 'lru_oldest/lru_newest on empty' => sub {
    my $c = LRU::Cache::new(5);
    
    my @oldest = lru_oldest($c);
    my @newest = lru_newest($c);
    Test::More::is(scalar @oldest, 0, 'lru_oldest returns empty on empty cache');
    Test::More::is(scalar @newest, 0, 'lru_newest returns empty on empty cache');
};

package main;

done_testing;
