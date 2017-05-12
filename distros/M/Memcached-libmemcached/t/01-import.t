# tests for functions documented in memcached_create.pod

use strict;
use warnings;

use Carp;
use Test::More tests => 16;

BEGIN { use_ok( 'Memcached::libmemcached' ) }

#$Exporter::Verbose = 1;

ok !defined &memcached_create, 'should not import func by default';
Memcached::libmemcached->import( 'memcached_create' );
ok  defined &memcached_create, 'should import func on demand';

# we use exists not defined for constants because they're handled by AUTOLOAD

ok !exists &MEMCACHED_SUCCESS, 'should not import MEMCACHED_SUCCESS by default';
ok !exists &MEMCACHED_FAILURE, 'should not import MEMCACHED_FAILURE by default';
Memcached::libmemcached->import( 'MEMCACHED_SUCCESS' );
ok  exists(&MEMCACHED_SUCCESS), 'should import MEMCACHED_SUCCESS on demand';
ok !exists &MEMCACHED_FAILURE, 'should not import MEMCACHED_FAILURE when importing MEMCACHED_SUCCESSi';

ok defined MEMCACHED_SUCCESS();

ok !exists &MEMCACHED_HASH_MD5, 'should not import MEMCACHED_HASH_MD5 by default';
ok !exists &MEMCACHED_HASH_CRC, 'should not import MEMCACHED_HASH_CRC by default';
Memcached::libmemcached->import( ':memcached_hash_t' );
ok  exists &MEMCACHED_HASH_MD5, 'should import MEMCACHED_HASH_MD5 by :memcached_hash tag';
ok  exists &MEMCACHED_HASH_CRC, 'should import MEMCACHED_HASH_CRC by :memcached_hash tag';

ok MEMCACHED_HASH_MD5();
ok MEMCACHED_HASH_CRC();
cmp_ok MEMCACHED_HASH_MD5(), '!=', MEMCACHED_HASH_CRC();

if (0) { # can't do this yet
Memcached::libmemcached->import( 'LIBMEMCACHED_MAJOR_VERSION', 'LIBMEMCACHED_MAJOR_VERSION' );
ok my $lib_major_ver = LIBMEMCACHED_MAJOR_VERSION();
ok my $lib_minor_ver = LIBMEMCACHED_MAJOR_VERSION();
ok my $pm_ver  = Memcached::libmemcached->VERSION;
like $pm_ver, qr/^$lib_major_ver+\.$lib_minor_ver\d\d$/,
    "Memcached::libmemcached version should match X.YYZZ where X.YY is the libmemcached version ($lib_major_ver.$lib_minor_ver)";
}

ok 1;
