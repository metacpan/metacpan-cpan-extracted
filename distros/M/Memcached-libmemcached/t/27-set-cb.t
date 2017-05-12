
# tests for functions documented in memcached_set.pod

use strict;
use warnings;

use Test::More;

use Memcached::libmemcached
    #   functions explicitly tested by this file
    qw(
    ),
    #   other functions used by the tests
    qw(
        memcached_set
        memcached_get
        memcached_mget
        memcached_mget_into_hashref
    );

use lib 't/lib';
use libmemcached_test;

my $memc = libmemcached_test_create();

my $items = 2;
plan tests => 21;

my ($rv, $rc, $flags);
my $t1= time();

my $flag_orig = 0xF000F00F;
my %data = map { ("k$_.$t1" => "val$_.$t1") } (1..$items);

my ($set_cb_expected_defsv, @set_cb_expected_args);
my $set_cb_called = 0;
my $set_cb = sub {
    ++$set_cb_called;
    print "set_cb(@_)\n";
    is $_, $set_cb_expected_defsv, '$_ should be the value';
    is scalar @_, 2, '@_ should be two elems: $key and $flags';
    is $_[0], $set_cb_expected_args[0], 'arg 0 should be the key';
    is $_[1], $set_cb_expected_args[1], 'arg 1 should be the flags';
    return;
};
$memc->set_callback_coderefs($set_cb, undef);

print "test read-only access to values from callback\n";
for my $k (keys %data) {
    $set_cb_expected_defsv = $data{$k};
    @set_cb_expected_args  = ( $k, $flag_orig );
    ok memcached_set($memc, $k, $data{$k}, 0, $flag_orig);
}

for my $k (keys %data) {
    $set_cb_expected_defsv = $data{$k};
    @set_cb_expected_args  = ( $k, $flag_orig );
    is memcached_get($memc, $k), $data{$k};
}
is $set_cb_called, scalar keys %data;

$set_cb_called = 0;
$memc->set_callback_coderefs(undef, sub { ++$set_cb_called; return });
my %got;
ok memcached_mget_into_hashref($memc, [ keys %data ], \%got);
is_deeply \%got, \%data;


print "test modification of values by callback\n";

my $expected_flags = 0xE0E0E0E0;
$set_cb = sub {
    $_ = uc($_).lc($_);
    $_[1] = $expected_flags;
    return;
};
$memc->set_callback_coderefs(undef, $set_cb);

for my $k (keys %data) {
    my $v = $data{$k};
    ok memcached_set($memc, $k, $v);
    is memcached_get($memc, $k, my $flags), uc($v).lc($v);
    is $flags, $expected_flags, "flags is $flags (expected $expected_flags)" ;
}
