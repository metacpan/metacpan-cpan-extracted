# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'IO::Socket::RedisPubSub' ); }

my $object = IO::Socket::RedisPubSub->new ();
isa_ok ($object, 'IO::Socket::RedisPubSub');


