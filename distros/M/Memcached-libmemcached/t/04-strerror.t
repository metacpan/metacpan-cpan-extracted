
# tests for functions documented in memcached_strerror.pod

use strict;
use warnings;

use Test::More;

use Memcached::libmemcached
    #   functions explicitly tested by this file
    qw(
        memcached_strerror
        memcached_errstr
    ),
    #   other functions used by the tests
    qw(
        memcached_server_add_unix_socket
        MEMCACHED_INVALID_ARGUMENTS
    );

use lib 't/lib';
use libmemcached_test;

my $memc = libmemcached_test_create();

plan tests => 6;
$| = 1;

is memcached_strerror($memc, 0), 'SUCCESS';
is memcached_strerror($memc, 1), 'FAILURE';

# XXX also test dual-var nature of return codes here
my $rc = memcached_server_add_unix_socket($memc, undef); # should fail
is $rc, undef, 'rc should not be defined';

my $errstr = $memc->errstr;
#use Devel::Peek; Dump($errstr);
cmp_ok $errstr, '==', MEMCACHED_INVALID_ARGUMENTS(),
    'should be MEMCACHED_INVALID_ARGUMENTS integer in numeric context';
cmp_ok $errstr, 'eq', "INVALID ARGUMENTS",
    'should be "INVALID ARGUMENTS" string in string context';

is $errstr, memcached_errstr($memc);
