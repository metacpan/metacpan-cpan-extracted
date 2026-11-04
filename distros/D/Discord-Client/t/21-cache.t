use v5.26;
use warnings;
use Test2::V1;
use JSON::PP;
use lib 't/lib';
use TestDiscordGateway qw(rig ready_socket);
use TestDiscordREST qw(client);
use Discord::Client::Cache;
use Discord::Client;

T2->subtest(
    'bounded snapshots, LRU and TTL',
    sub {
        my $now = 0;

        # Byte and per-entry limits apply independently of the entry-count limit.
        my $cache = Discord::Client::Cache->new( max_items => 2, ttl => 10, clock => sub { $now } );

        # Inputs and returned values must not expose the stored nested snapshot.
        my $raw = { id => '1', nested => { new_field => 'preserved' } };
        $cache->put( user => $raw );
        $raw->{nested}{new_field} = 'changed';
        my $copy = $cache->get( user => '1' );
        T2->is( $copy->{nested}{new_field}, 'preserved', 'input snapshot isolated' );
        $copy->{nested}{new_field} = 'changed again';
        T2->is( $cache->get( user => '1' )->{nested}{new_field}, 'preserved', 'output snapshot isolated' );

        # Accessing the first entry makes the second entry the next eviction candidate.
        $cache->put( user => { id => '2' } );
        $cache->get( user => '1' );
        $cache->put( user => { id => '3' } );
        T2->ok( !defined( $cache->get( user => '2' ) ), 'least recently used evicted' );
        T2->is( $cache->stats->{items}, 2, 'item count bounded' );

        # Expiry applies at the exact boundary and releases byte accounting.
        $now = 10;
        T2->is( $cache->stats->{items}, 0, 'expiry also enforced on stats' );
        T2->is( $cache->stats->{bytes}, 0, 'expired byte accounting released' );
        $cache = Discord::Client::Cache->new( max_bytes => 50, max_entry_bytes => 40 );
        $cache->put( user => { id => '1', name => 'a' } );
        $cache->put( user => { id => '2', name => 'b' } );
        $cache->put( user => { id => '3', name => 'c' } );
        T2->is( $cache->stats->{bytes}, T2->number_le(50), 'total byte capacity enforced' );
        T2->ok( !$cache->put( user => { id => '4', name => 'x' x 100 } ), 'oversized entry rejected' );
        T2->is( $cache->stats->{oversized}, 1, 'oversize diagnostic' );
        $cache->clear;
        T2->is( $cache->stats->{bytes}, 0, 'clear releases all data' );
    }
);

T2->subtest(
    'Gateway updates, deletes and unavailable guilds',
    sub {
        my $cache = Discord::Client::Cache->new;
        $cache->apply(
            'GUILD_CREATE',
            {
                id => '1',
                name => 'Guild',
                channels => [ { id => '2', name => 'general' } ],
                members => [ { user => { id => '3' } } ]
            }
        );
        T2->ok( !exists( $cache->get( guild => '1' )->{members} ), 'full member list is not cached' );
        T2->is( $cache->get( channel => '2' )->{guild_id}, '1', 'observed channels associated with guild' );
        $cache->apply(
            'MESSAGE_CREATE',
            {
                id => '4',
                guild_id => '1',
                channel_id => '2',
                content => 'old',
                author => { id => '3' },
                unknown => 1
            }
        );

        # Partial updates replace supplied fields while retaining omitted and unknown fields.
        $cache->apply( 'MESSAGE_UPDATE', { id => '4', content => 'new', embeds => [] } );
        my $message = $cache->get( message => '4' );
        T2->is( $message->{content}, 'new', 'partial update merged' );
        T2->is( $message->{channel_id}, '2', 'omitted field retained' );
        T2->is( $message->{unknown}, 1, 'unknown field retained' );

        # Temporary unavailability preserves related snapshots until the guild returns.
        $cache->apply( 'GUILD_DELETE', { id => '1', unavailable => JSON::PP::true } );
        T2->ok( $cache->get( guild => '1' )->{unavailable}, 'temporary unavailable recorded' );
        T2->ok( $cache->get( message => '4' ), 'temporary outage retains snapshots' );
        $cache->apply( 'GUILD_CREATE', { id => '1', unavailable => JSON::PP::true } );
        T2->ok( $cache->get( guild => '1' )->{unavailable}, 'unavailable GUILD_CREATE remains unavailable' );
        $cache->apply( 'GUILD_CREATE', { id => '1', name => 'Back' } );
        T2->ok( !$cache->get( guild => '1' )->{unavailable}, 'available GUILD_CREATE clears flag' );

        # Permanent deletion removes related data but preserves independently shared users.
        $cache->apply( 'MESSAGE_DELETE_BULK', { ids => ['4'] } );
        T2->ok( !defined( $cache->get( message => '4' ) ), 'bulk delete removes messages' );
        $cache->apply( 'MESSAGE_CREATE', { id => '5', guild_id => '1', channel_id => '2' } );
        $cache->apply( 'CHANNEL_DELETE', { id => '2' } );
        T2->ok( !defined( $cache->get( message => '5' ) ), 'channel deletion removes its messages' );
        $cache->apply( 'CHANNEL_CREATE', { id => '6', guild_id => '1' } );
        $cache->apply( 'GUILD_DELETE', { id => '1' } );
        T2->ok( !defined( $cache->get( guild => '1' ) ) && !defined( $cache->get( channel => '6' ) ),
            'permanent guild deletion removes related data' );
        T2->ok( $cache->get( user => '3' ), 'shared users retained independently' );
    }
);

T2->subtest(
    'selected types and facade event ordering',
    sub {

        # A separate default client must not allocate a cache implicitly.
        my ($rest) = client();
        my $rig = rig( loop => $rest->loop );
        my $bot = Discord::Client->new(
            rest => $rest,
            gateway => $rig->{gateway},
            loop => $rest->loop,
            cache => { types => ['message'] }
        );

        # Application callbacks must observe the cache after the incoming event is applied.
        my $seen;
        $bot->on( message_create => sub { $seen = $_[2]->cache->get( message => $_[0]{id} ) } );
        my $started = $bot->start;
        my $websocket = ready_socket($rig);
        $started->get;
        $websocket->emit(
            {
                op => 0,
                s => 43,
                t => 'MESSAGE_CREATE',
                d => { id => '7', channel_id => '2', author => { id => '3' } }
            }
        );
        $rig->{clock}->run_deferred;
        T2->is( $seen->{id}, '7', 'cache updated before application handler' );
        T2->ok( !defined( $bot->cache->get( user => '3' ) ), 'unselected types not stored' );
        T2->is( $bot->stats->{cache}{items}, 1, 'facade diagnostics include cache' );
        $bot->close;
        $rest->close;
        ($rest) = client();
        $rig = rig( loop => $rest->loop );
        $bot = Discord::Client->new(
            rest => $rest,
            gateway => $rig->{gateway},
            loop => $rest->loop
        );
        T2->ok( !defined( $bot->cache ), 'cache disabled by default' );
        $bot->close;
        $rest->close;
    }
);

T2->done_testing;
