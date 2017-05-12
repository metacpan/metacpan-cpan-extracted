# tests for functions documented in memcached_create.pod

use strict;
use warnings;

use Test::More tests => 6;

BEGIN {
use_ok( 'Memcached::libmemcached',
#   functions explicitly tested by this file
qw(
),
#   other functions used by the tests
qw(
));
}

my ($memc, $memc2);

ok $memc = Memcached::libmemcached->new;
is ref $memc, 'Memcached::libmemcached';
undef $memc;

{   package MyMemc;
    use base qw(Memcached::libmemcached);
}

ok $memc = MyMemc->new;
is ref $memc, 'MyMemc';

ok 1;
