#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

package My::Memcached;

use strict;
use warnings;
use parent qw(Cache::Memcached::Fast);

use JSON;
use Hash::Compact;

my $OPTIONS = {
    foo => {
        alias_for => 'f',
    },
    bar => {
        alias_for => 'b',
        default   => 'bar',
    },
};

sub get {
    my ($self, $key) = @_;
    my $value = $self->SUPER::get($key);
    Hash::Compact->new(decode_json $value, $OPTIONS);
}

sub set {
    my ($self, $key, $value, $expire) = @_;
    my $hash = Hash::Compact->new($value, $OPTIONS);
    $self->SUPER::set($key, encode_json $hash->to_hash, $expire);
}

package main;

my $key   = 'key';
my $value = { foo => 'foo' };
my $memd  = My::Memcached->new({servers => [qw(localhost:11211)]});
   $memd->set($key, $value);

my $cached_value = $memd->get($key);
is_deeply $cached_value->param('foo'), 'foo';
is_deeply $cached_value->param('bar'), 'bar';
is_deeply $cached_value->to_hash, +{ f => 'foo' };

$cached_value->param(bar => 'baz');
$memd->set($key, $cached_value->to_hash);

$cached_value = $memd->get($key);
is_deeply $cached_value->param('foo'), 'foo';
is_deeply $cached_value->param('bar'), 'baz';
is_deeply $cached_value->to_hash, +{ f => 'foo', b => 'baz' };

done_testing;
