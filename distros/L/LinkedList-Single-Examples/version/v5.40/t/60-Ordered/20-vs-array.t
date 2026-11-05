########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Example::Testy;
use v5.40;
use FindBin::libs;

use Test::More;
use Test::Deep;

use LinkedList::Single::Example::Ordered;
use LinkedList::Single::Example::Ordered::Sorted;
use LinkedList::Single::Example::Ordered::Buckets;
use LinkedList::Single::Example::Ordered::Hash;

########################################################################
# package variables
########################################################################

# fixed seed: a failure is reproducible.

srand 20261031;

my $steps   = 3_000;

# how often the whole-bucket detach was used, to show the stream got there.

my $detached    = 0;

{
    no warnings 'redefine';

    my $orig    = \&LinkedList::Single::Example::Ordered::_detach;

    *LinkedList::Single::Example::Ordered::_detach
    = sub { ++$detached; goto &$orig };
}

# a result as one string: eq_deeply on every pair of a large map at every
# step is far slower than the maps.

sub flat( $pair )
{
    join '|', map { join ',', map { $_ // 'u' } ref $_ ? $_->@* : $_ } $pair->@*
}

########################################################################
# tests
#
# the same random stream of put, delete, get, range and cut goes to the
# list map, to the sorted array, to the array of buckets and to the hash.
# the sorted array is the oracle: what each call returns, and the whole
# contents in key order, must agree after every step.
########################################################################

for my $bucket ( 1, 2, 4, 16 )
{
    my @impl
    = (
        [ list      => LinkedList::Single::Example::Ordered->new( bucket => $bucket )           ]
      , [ sorted    => LinkedList::Single::Example::Ordered::Sorted->new                        ]
      , [ buckets   => LinkedList::Single::Example::Ordered::Buckets->new( bucket => $bucket )  ]
      , [ hash      => LinkedList::Single::Example::Ordered::Hash->new                          ]
    );

    my %count   = map { $_ => 0 } qw( put delete get range cut cut_rows );

    my $bad     = '';

    for my $step ( 1 .. $steps )
    {
        my $roll    = rand;
        my $key     = int rand 300;
        my $hi      = $key + int rand 60;

        my( $op, @arg )
        = $roll < 0.50  ? ( put    => $key, "v$step" )
        : $roll < 0.68  ? ( delete => $key           )
        : $roll < 0.80  ? ( get    => $key           )
        : $roll < 0.90  ? ( range  => $key, $hi      )
        :                 ( cut    => $key, $hi      )
        ;

        ++$count{ $op };

        my @result
        = map
        {
            my $got = $_->[ 1 ]->$op( @arg );

            $op eq 'range' || $op eq 'cut'
            ? join ';', map { flat $_ } $got->@*
            : $op eq 'put'
            ? ''
            : $got // 'u'
        }
        @impl;

        $op eq 'cut'
        and $count{ cut_rows } += () = $result[ 0 ] =~ m{;}g;

        my @flat
        = map
        {
            join ';', map { flat $_ } $_->[ 1 ]->contents->@*
        }
        @impl;

        for my $other ( 1 .. $#impl )
        {
            $result[ $other ] eq $result[ 0 ]
            or $bad = "step $step ($op @arg), $impl[ $other ][ 0 ]: result '$result[ $other ]' vs '$result[ 0 ]'";

            $flat[ $other ] eq $flat[ 0 ]
            or $bad ||= "step $step ($op @arg), $impl[ $other ][ 0 ]: contents differ";

            $impl[ $other ][ 1 ]->size == $impl[ 0 ][ 1 ]->size
            or $bad ||= "step $step ($op @arg), $impl[ $other ][ 0 ]: size differs";
        }

        $bad
        and last;
    }

    ok !$bad, "bucket $bucket: $steps steps agree in all four maps" or diag $bad;

    cmp_ok $count{ $_ }, '>', 0, "bucket $bucket: the stream had $_" for qw( put delete get range cut );
    cmp_ok $count{ cut_rows }, '>', 0, "bucket $bucket: cuts took entries out";
}

cmp_ok $detached, '>', 0, 'Whole buckets were detached in bulk by the stream';

########################################################################
# the edges
########################################################################

for my $class ( qw( LinkedList::Single::Example::Ordered LinkedList::Single::Example::Ordered::Sorted LinkedList::Single::Example::Ordered::Buckets LinkedList::Single::Example::Ordered::Hash ) )
{
    my $map = $class->new( bucket => 2 );

    is $map->get( 5 ), undef, "$class: miss on an empty map";
    is $map->delete( 5 ), undef, "$class: delete of nothing";

    cmp_deeply $map->range( 0, 10 ), [], "$class: range of an empty map";
    cmp_deeply $map->cut( 0, 10 ), [], "$class: cut of an empty map";

    $map->put( $_, "v$_" ) for 5, 1, 9, 3, 7;
    $map->put( 3, 'three' );

    is $map->size, 5, "$class: replacing does not grow the map";
    is $map->get( 3 ), 'three', "$class: replaced value";

    cmp_deeply $map->range( 3, 7 ), [ [ 3, 'three' ], [ 5, 'v5' ], [ 7, 'v7' ] ]
    , "$class: range includes both ends";

    cmp_deeply $map->range( 4, 4 ), [], "$class: range with nothing in it";
    cmp_deeply $map->range( 8, 2 ), [], "$class: backwards range is empty";
    cmp_deeply $map->range( -10, 100 ), $map->contents, "$class: range of everything is the contents";

    cmp_deeply $map->cut( 3, 7 ), [ [ 3, 'three' ], [ 5, 'v5' ], [ 7, 'v7' ] ]
    , "$class: cut returns the entries";

    cmp_deeply $map->contents, [ [ 1, 'v1' ], [ 9, 'v9' ] ], "$class: and removes them";

    cmp_deeply $map->cut( -5, 100 ), [ [ 1, 'v1' ], [ 9, 'v9' ] ], "$class: cut of everything";

    is $map->size, 0, "$class: empty again";

    $map->put( 2, 'two' );

    is $map->get( 2 ), 'two', "$class: usable after being emptied";
}

done_testing
__END__
