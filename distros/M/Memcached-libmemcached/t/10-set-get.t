
# tests for basic memcached_set & memcached_get
# documented in memcached_set.pod and memcached_get.pod
# test for the other functions are performed elsewhere

use strict;
use warnings;

use Test::More;

use Memcached::libmemcached
    #   functions explicitly tested by this file
    qw(
    memcached_set
    memcached_get
    ),
    #   other functions used by the tests
    qw(
    memcached_errstr
    memcached_version
    MEMCACHED_NOTFOUND
    );

use lib 't/lib';
use libmemcached_test;

my $memc = libmemcached_test_create();

plan tests => 14;

diag "Testing using memcached version ".memcached_version($memc);

my ($rv, $rc, $flags, $tmp);
my $t1= time();
my $k1= "$0-test-key-$t1"; # can't have spaces
my $v1= "$0 test value $t1";

# get (presumably non-existant) key
is scalar memcached_get($memc, $k1, $flags=0, $rc=0), undef,
    'should not exist yet and so should return undef';

# test set with expiry and flags
ok memcached_set($memc, $k1, $v1, 1, 0xDEADCAFE);
is memcached_errstr($memc), 'SUCCESS';

is memcached_get($memc, $k1, $flags=0, $rc=0), $v1;
ok $rc;
if ($flags == 0xCAFE) {
    warn "You're limited to 16 bit flags\n";
    $flags = 0xDEADCAFE;
}
if ($flags == 0 && not libmemcached_version_ge($memc, "1.2.4")) {
    warn "You're old memcached version doesn't support flags!\n";
    $flags = 0xDEADCAFE;
}
is sprintf("0x%X",$flags), '0xDEADCAFE', 'flags should be unchanged';

sleep 2; # 1 second expiry plus 1 for safety margin

ok not defined memcached_get($memc, $k1, $flags=0, $rc=0);
ok !$rc;
cmp_ok memcached_errstr($memc), '==', MEMCACHED_NOTFOUND();

# repeat for value with a null byte to check value_length works

my $smiley = "\x{263A}";

ok memcached_set($memc, $k1, $tmp = $smiley);
is length $tmp, length $smiley, 'utf8 arg length should not be altered';
is $tmp, $smiley, 'utf8 arg should not be altered';

$tmp = memcached_get($memc, $k1, $flags, $rc=0);
ok $rc;
{
    local $TODO = "support utf8";
    # XXX is $tmp, $smiley;
    pass "no inbuilt utf8 support\n";
}

