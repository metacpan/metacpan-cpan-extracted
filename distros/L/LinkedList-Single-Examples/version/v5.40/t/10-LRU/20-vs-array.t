########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Example::Testy;
use v5.40;
use FindBin::libs;

use Test::More;
use Test::Deep;

use LinkedList::Single::Example::LRU;
use LinkedList::Single::Example::LRU::Array;
use LinkedList::Single::Example::LRU::Order;
use LinkedList::Single::Example::LRU::Lazy;

########################################################################
# package variables
########################################################################

# fixed seed: a failure is reproducible.

srand 20261031;

my $steps   = 3_000;

########################################################################
# tests
#
# the same random stream of get and put goes to the list cache and to
# the three array caches. the array of pairs is the oracle; what a call
# returns, the whole contents (order included) and the sequence of
# evicted entries must agree after every step.
########################################################################

for my $limit ( 1, 2, 5, 100 )
{
    # a key space three times the limit: a mix of hits and misses.

    my $keys    = 3 * $limit;

    my @impl
    = map
    {
        my $class   = $_;
        my @evicted = ();

        +{
            name    => $class =~ s{ \A LinkedList::Single::Example:: }{}rx
          , evicted => \@evicted
          , cache   =>
                $class->new
                (
                    limit       => $limit
                  , on_evict    => sub( @entry ) { push @evicted, join ' ', @entry }
                )
        }
    }
    qw
    (
        LinkedList::Single::Example::LRU
        LinkedList::Single::Example::LRU::Array
        LinkedList::Single::Example::LRU::Order
        LinkedList::Single::Example::LRU::Lazy
    );

    my %count   = ( get => 0, hit => 0, put => 0, evict => 0 );

    my $bad     = '';

    STEP:
    for my $step ( 1 .. $steps )
    {
        my $key     = int rand $keys;
        my $put     = rand() < 0.4;

        my @result
        = map
        {
            $put
            ? do { $_->{ cache }->put( $key, "v$step" ); 'put' }
            : $_->{ cache }->get( $key ) // 'miss'
        }
        @impl;

        # the contents as one string: eq_deeply on every pair of a
        # large cache at every step is far slower than the caches.

        my @flat
        = map
        {
            join '|', map { join ',', $_->@* } $_->{ cache }->contents->@*
        }
        @impl;

        if( $put )
        {
            ++$count{ put };
        }
        else
        {
            ++$count{ get };
            $result[ 0 ] ne 'miss'
            and ++$count{ hit };
        }

        for my $other ( 1 .. $#impl )
        {
            my $name    = $impl[ $other ]{ name };

            $result[ $other ] eq $result[ 0 ]
            or $bad = "step $step, $name: result '$result[ $other ]' vs '$result[ 0 ]'";

            $flat[ $other ] eq $flat[ 0 ]
            or $bad ||= "step $step, $name: contents differ";

            # the evicted list only grows, so the newest entry and the
            # count say whether it still agrees (eq_deeply of the whole
            # list at every step is quadratic).

            my( $mine, $theirs )    = map { $_->{ evicted } } @impl[ $other, 0 ];

            @$mine == @$theirs
            and ( $mine->[ -1 ] // '' ) eq ( $theirs->[ -1 ] // '' )
            or $bad ||= "step $step, $name: evicted entries differ";

            $bad
            and last STEP;
        }
    }

    ok !$bad, "limit $limit: $steps steps agree in all four caches" or diag $bad;

    cmp_deeply $_->{ evicted }, $impl[ 0 ]{ evicted }, "limit $limit: $_->{ name } evicted the same entries in the same order"
    for @impl[ 1 .. $#impl ];

    $count{ evict } = $impl[ 0 ]{ evicted }->@*;

    # the stream must have used what is being compared.

    cmp_ok $count{ hit },   '>', 0, "limit $limit: the stream had hits";
    cmp_ok $count{ evict }, '>', 0, "limit $limit: the stream evicted";

    cmp_ok $impl[ 0 ]{ cache }->size, '<=', $limit, "limit $limit: never over the limit";
}

########################################################################
# the edges
########################################################################

my @class = qw( LinkedList::Single::Example::LRU LinkedList::Single::Example::LRU::Array LinkedList::Single::Example::LRU::Order LinkedList::Single::Example::LRU::Lazy );

for my $class ( @class )
{
    my @gone    = ();

    my $cache
    = $class->new
    (
        limit       => 2
      , on_evict    => sub( $key, $value ) { push @gone, "$key=$value" }
    );

    is $cache->get( 'x' ), undef, "$class: miss on an empty cache";

    $cache->put( a => 1 );
    $cache->put( b => 2 );
    $cache->put( a => 10 );

    cmp_deeply $cache->contents, [ [ a => 10 ], [ b => 2 ] ], "$class: put of an existing key replaces and moves it";
    cmp_deeply \@gone, [], "$class: replacing evicts nothing";

    $cache->put( c => 3 );

    cmp_deeply \@gone, [ 'b=2' ], "$class: the oldest was evicted";

    is $cache->get( 'a' ), 10, "$class: get of the older entry";

    $cache->put( d => 4 );

    cmp_deeply \@gone, [ 'b=2', 'c=3' ], "$class: a hit protects the entry";

    ok $cache->exists( 'a' ),  "$class: exists";
    ok !$cache->exists( 'c' ), "$class: evicted key does not exist";

    eval { $class->new( limit => 0 ) };
    like $@, qr{not positive}, "$class: limit 0 is refused";

    eval { $class->new };
    like $@, qr{missing limit}, "$class: limit is required";
}

done_testing
__END__
