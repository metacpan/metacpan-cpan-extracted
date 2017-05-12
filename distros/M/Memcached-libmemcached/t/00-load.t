#!perl -T

use strict;
use warnings;

use Test::More tests => 5;

BEGIN {
	use_ok( 'Memcached::libmemcached' );
}

my $VERSION = $Memcached::libmemcached::VERSION;
ok $VERSION, '$Memcached::libmemcached::VERSION should be defined';

diag( "Testing Memcached::libmemcached $VERSION, Perl $], $^O, $^X" );

ok defined &Memcached::libmemcached::memcached_lib_version,
    '&Memcached::libmemcached::memcached_lib_version should be defined';

my $lib_version = Memcached::libmemcached::memcached_lib_version(); # 1.0.8
ok $lib_version;

# 1.0.8 => 1.00.08
(my $lib_ver = $lib_version) =~ s/\.(\d)\b/ sprintf ".%02d", $1 /eg;
$lib_ver =~ s/\.(\d+)$/$1/; # drop second period

like $VERSION, qr/^\Q$lib_ver\E\d\d/,
    "$VERSION should be $lib_ver with two digits appended",
