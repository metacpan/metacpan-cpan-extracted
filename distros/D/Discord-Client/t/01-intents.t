use v5.26;
use warnings;
use Test2::V1;
use Discord::Client::Intents;

# Check explicit bit positions and idempotent composition without a Gateway connection.
my $class = 'Discord::Client::Intents';
T2->is( $class->bits(), 0, 'empty intents are allowed' );
T2->is( $class->bits('GUILDS'), 1, 'guilds bit' );
T2->is( $class->bits( 'GUILDS', 'GUILD_MESSAGES', 'GUILDS' ), 513, 'OR combines bits, duplicates harmless' );
T2->is( $class->bits('MESSAGE_CONTENT'), 32768, 'privileged intent is explicit' );
T2->is( $class->bits('GUILD_EXPRESSIONS'), 8, 'current expression intent' );

# Reject misspellings instead of silently enabling an unintended subscription.
T2->like( T2->dies( sub { $class->bits('NOT_AN_INTENT') } ), qr/unknown Discord intent/, 'unknown intent rejected' );

T2->done_testing;
