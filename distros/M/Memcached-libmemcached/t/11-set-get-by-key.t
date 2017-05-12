
# tests for basic memcached_set & memcached_get
# documented in memcached_set.pod and memcached_get.pod
# test for the other functions are performed elsewhere

use strict;
use warnings;

use Test::More;

use Memcached::libmemcached
    #   functions explicitly tested by this file
    qw(
    memcached_set_by_key
    memcached_get_by_key
    ),
    #   other functions used by the tests
    qw(
    memcached_errstr
    MEMCACHED_NOTFOUND
    );

use lib 't/lib';
use libmemcached_test;

my $memc = libmemcached_test_create();

plan tests => 13;

my ($rv, $rc, $flags, $tmp);
my $t1= time();
my $m1= "master-key"; # can't have spaces
my $k1= "$0-test-key-$t1"; # can't have spaces
my $v1= "$0 test value $t1";

# get_by_key (presumably non-existant) key
print "memcached_get the not yet stored value\n";
is scalar memcached_get_by_key($memc, $m1, $k1, $flags=0, $rc=0), undef,
    'should not exist yet and so should return undef';

# test set with expiry and flags
ok memcached_set_by_key($memc, $m1, $k1, $v1, 1, 0xDEADCAFE);

is memcached_get_by_key($memc, $m1, $k1, $flags=0, $rc=0), $v1;
ok $rc;
if ($flags == 0xCAFE) {
    warn "You're limited to 16 bit flags\n";
    $flags = 0xDEADCAFE;
}
is sprintf("0x%X",$flags), '0xDEADCAFE', 'flags should be unchanged';

sleep 1;

ok not defined memcached_get_by_key($memc, $m1, $k1, $flags=0, $rc=0);
ok !$rc;
cmp_ok memcached_errstr($memc), '==', MEMCACHED_NOTFOUND();

# repeat for value with a null byte to check value_length works

my $smiley = "\x{263A}";

ok memcached_set_by_key($memc, $m1, $k1, $tmp = $smiley);
is length $tmp, length $smiley, 'utf8 arg length should not be altered';
is $tmp, $smiley, 'utf8 arg should not be altered';

$tmp = memcached_get_by_key($memc, $m1, $k1, $flags, $rc=0);
ok $rc;
{
    local $TODO = "support utf8";
    # XXX is $tmp, $smiley;
    pass "no inbuilt utf8 support\n";
}

