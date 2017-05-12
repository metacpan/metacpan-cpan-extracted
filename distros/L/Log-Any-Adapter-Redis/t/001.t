
use strict;
use warnings;
use Test::More tests => 4;
use Log::Any qw($log);
use Log::Any::Adapter;

use_ok('Log::Any::Adapter::Redis');

my $redis_db = bless {}, 'RedisDB';
isa_ok( $redis_db, 'RedisDB' );

my $entry = Log::Any::Adapter->set( 'Redis', redis_db => $redis_db );
isa_ok( $entry, 'HASH' );
is( $entry->{adapter_class}, 'Log::Any::Adapter::Redis' );
