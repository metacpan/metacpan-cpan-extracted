use strict;
use warnings;
use Test::More;
use IPC::PubSub;
use IO::Socket::INET;
use File::Temp ':POSIX';

my @backends = qw(PlainHash);

unshift @backends, 'DBM_Deep' if eval { require DBM::Deep };
unshift @backends, 'JiftyDBI' if eval { require Jifty::DBI };
unshift @backends, 'Memcached' if eval { require Cache::Memcached } and IO::Socket::INET->new('127.0.0.1:11211');

plan tests => 33 * scalar @backends;

my $tmp = tmpnam();
END { unlink $tmp }

my %init_args = (
    DBM_Deep    => [ $tmp ],
    JiftyDBI    => [ db_init => 1 ],
    Memcached   => [ rand() . $$ ],
);

SKIP: for my $backend (@backends) {
    diag("Testing backend $backend");

    my $bus = IPC::PubSub->new( $backend, @{ $init_args{$backend} } );
    my $pub = $bus->new_publisher( "first", "second" );
    my $cache = $bus->_cache;

    is_deeply( scalar $pub->channels, { first => 1, second => 1 } );
    is_deeply( [ sort $pub->channels ], [ "first", "second" ] );
    is_deeply( $cache->publisher_indices("first"),  { $pub->uuid => 0 } );
    is_deeply( $cache->publisher_indices("second"), { $pub->uuid => 0 } );
    is_deeply( $cache->publisher_indices("third"),  {} );

    $pub->publish("third");
    is_deeply( scalar $pub->channels,
        { first => 1, second => 1, third => 1 } );
    is_deeply( [ sort $pub->channels ], [ "first", "second", "third" ] );
    is_deeply( $cache->publisher_indices("first"),  { $pub->uuid => 0 } );
    is_deeply( $cache->publisher_indices("second"), { $pub->uuid => 0 } );
    is_deeply( $cache->publisher_indices("third"),  { $pub->uuid => 0 } );

    $pub->publish("third");
    is_deeply( scalar $pub->channels,
        { first => 1, second => 1, third => 1 } );
    is_deeply( [ sort $pub->channels ], [ "first", "second", "third" ] );
    is_deeply( $cache->publisher_indices("third"),  { $pub->uuid => 0 } );

    $pub->msg("message 1");
    is_deeply( scalar $pub->channels,
        { first => 2, second => 2, third => 2 } );

    $pub->unpublish("second");
    is_deeply( scalar $pub->channels, { first => 2, third => 2 } );

    $pub->msg("message 2");
    is_deeply( scalar $pub->channels, { first => 3, third => 3 } );

    is_deeply( $cache->publisher_indices("first"),  { $pub->uuid => 2 } );
    is_deeply( $cache->publisher_indices("second"), {} );
    is_deeply( $cache->publisher_indices("third"),  { $pub->uuid => 2 } );

    is($cache->get_index( first => $pub->uuid  ), 2 );
    $cache->set_index( first => $pub->uuid, 5 );
    is($cache->get_index( first => $pub->uuid ), 5 );    
    is_deeply( $cache->publisher_indices("first"),  { $pub->uuid => 5 } );

    {
        my $pub2 = $bus->new_publisher( "first", "second", "third" );
        is_deeply( scalar $pub2->channels, { first => 1, second => 1, third => 1 } );
        is_deeply( $cache->publisher_indices("first"),  { $pub->uuid => 5, $pub2->uuid => 0 } );
        is_deeply( $cache->publisher_indices("second"), {                  $pub2->uuid => 0 } );
        is_deeply( $cache->publisher_indices("third"),  { $pub->uuid => 2, $pub2->uuid => 0 } );

        $pub2->unpublish("first");
        is_deeply( scalar $pub2->channels, { second => 1, third => 1 } );
        is_deeply( $cache->publisher_indices("first"),  { $pub->uuid => 5                   } );
        is_deeply( $cache->publisher_indices("second"), {                  $pub2->uuid => 0 } );
        is_deeply( $cache->publisher_indices("third"),  { $pub->uuid => 2, $pub2->uuid => 0 } );
    }
    is_deeply( $cache->publisher_indices("first"),  { $pub->uuid => 5 } );
    is_deeply( $cache->publisher_indices("second"), {} );
    is_deeply( $cache->publisher_indices("third"),  { $pub->uuid => 2 } );
}
