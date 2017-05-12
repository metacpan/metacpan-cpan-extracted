
# tests for functions documented in memcached_get.pod
# (except for memcached_fetch_result)

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
plan tests => 15;

my ($rv, $rc, $flags);
my $t1= time();

my $flag_orig = 0xF000F00F;
my %data = map { ("k$_.$t1" => "v$_.$t1") } (1..$items);


my ($get_cb_expected_defsv, @get_cb_expected_args);
my $get_cb_called = 0;
my $get_cb = sub {
    ++$get_cb_called;
    print "get_cb(@_)\n";
    is $_, $get_cb_expected_defsv, '$_ should be the value';
    is_deeply \@_, \@get_cb_expected_args, '@_ should be $key and $flags';
    return;
};
$memc->set_callback_coderefs(undef, $get_cb);

print "test read-only access to values from callback\n";
ok memcached_set($memc, $_, $data{$_}, 0, $flag_orig)
    for keys %data;

for my $k (keys %data) {
    $get_cb_expected_defsv = $data{$k};
    @get_cb_expected_args  = ( $k, $flag_orig );
    is memcached_get($memc, $k), $data{$k};
}
is $get_cb_called, scalar keys %data;

$get_cb_called = 0;
$memc->set_callback_coderefs(undef, sub { ++$get_cb_called; return });
my %got;
ok memcached_mget_into_hashref($memc, [ keys %data ], \%got);
is_deeply \%got, \%data;


print "test modification of values by callback\n";

$get_cb = sub {
    $_ = uc($_).lc($_);
    $_[1] = 0xE0E0E0E0;
    return;
};
$memc->set_callback_coderefs(undef, $get_cb);

for my $k (keys %data) {
    my $v = $data{$k};
    is memcached_get($memc, $k, my $flags), uc($v).lc($v);
    is $flags, 0xE0E0E0E0;
}
