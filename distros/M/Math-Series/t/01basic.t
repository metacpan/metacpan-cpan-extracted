use strict;
use warnings;

use Test::More tests => 517;

use_ok('Math::Series');

my @args = (
    {
        formula       => 'n*x',
        start_value   => 1,
        iteration_var => 'n',
        previous_var  => 'x',
        start_index   => 0,
    },
    {
        formula     => 'n*x',
        start_value => 1,
    },
    {
        formula     => 'n*x',
        start_value => 1,
        start_index => 0,
    },
    {
        formula       => 'n*x',
        start_value   => 1,
        iteration_var => 'n',
        previous_var  => 'x',
        start_index   => 4,
    },
    {
        formula     => 'n*x',
        start_value => 1,
        start_index => 4,
    },
    {
        formula       => 'n*x',
        start_value   => 1,
        iteration_var => 'n',
        start_index   => 4,
    },
);

foreach my $args (@args) {
    my $ca = Math::Series->new(%$args);
    my $cb = Math::Series->new( %$args, cached => 1 );
    isa_ok( $ca, 'Math::Series' );
    isa_ok( $cb, 'Math::Series' );

    my $cn = Math::Series->new( %$args, cached => 0 );
    isa_ok( $cn, 'Math::Series' );

    ok( $ca->cached() == 1, 'sequence cached by default' );
    ok( $cb->cached() == 1, 'sequence cached by default, as requested' );
    ok( $cn->cached() == 0, 'sequence not cached, as requested' );

    $ca->cached(0);
    ok( $ca->cached() == 0, 'sequence not cached after change' );
    $ca->cached(1);
    ok( $ca->cached() == 1, 'sequence cached after change' );

    my @range = map { $_ + $ca->{start_index} } ( 0 .. 7 );
    my @results = $ca->{start_index} == 4
      ? qw/
      1
      6
      42
      336
      3024
      30240
      332640
      3991680
      51891840
      726485760
      10897286400
      174356582400
      /
      : qw/
      1
      2
      6
      24
      120
      720
      5040
      40320
      362880
      3628800
      39916800
      479001600
      /;

    foreach (@range) {
        ok( $ca->current_index() == $_,
            'Testing current_index() of cached object.' );
        ok( $cn->current_index() == $_,
            'Testing current_index() of uncached object.' );
        ok( $ca->next()->value() == $results[ $_ - $ca->{start_index} ],
            'Testing next() of cached object.' );
        ok( $cn->next()->value() == $results[ $_ - $ca->{start_index} ],
            'Testing next() of uncached object.' );
    }

    $Math::Series::warnings = $Math::Series::warnings = 0;
    foreach ( reverse @range ) {
        ok( $ca->back()->value() == $results[ $_ - $ca->{start_index} ],
            'Testing back() of cached object.' );
        ok( $cn->back()->value() == $results[ $_ - $ca->{start_index} ],
            'Testing back() of uncached object.' );
        ok( $ca->current_index() == $_,
            'Testing current_index() of cached object after back().' );
        ok( $cn->current_index() == $_,
            'Testing current_index() of uncached object after back().' );
    }

    ok(
        $ca->current_index( 5 + $ca->{start_index} ) == 5 + $ca->{start_index},
        'Testing setting current_index() on cached object.'
    );
    ok(
        $cn->current_index( 5 + $ca->{start_index} ) == 5 + $ca->{start_index},
        'Testing setting current_index() on uncached object.'
    );

    ok(
        $ca->at_index( 4 + $ca->{start_index} )->value() == $results[4],
        'Testing at_index() (below current index) on cached object.'
    );
    ok(
        $cn->at_index( 4 + $ca->{start_index} )->value() == $results[4],
        'Testing at_index() (below current index) on uncached object.'
    );

    ok(
        $ca->at_index( 6 + $ca->{start_index} )->value() == $results[6],
        'Testing at_index() (above cur. index but cached) on cached object.'
    );
    ok(
        $cn->at_index( 6 + $ca->{start_index} )->value() == $results[6],
        'Testing at_index() (above cur. index) on uncached object.'
    );

    ok(
        $ca->at_index( 9 + $ca->{start_index} )->value() == $results[9],
        'Testing at_index() (above current index) on cached object.'
    );
    ok(
        $cn->at_index( 9 + $ca->{start_index} )->value() == $results[9],
        'Testing at_index() (above current index) on uncached object.'
    );

    ok(
        !defined( $ca->at_index( -1 + $ca->{start_index} ) ),
        'Testing at_index() with invalid index on cached object.'
    );
    ok(
        !defined( $cn->at_index( -1 + $ca->{start_index} ) ),
        'Testing at_index() with invalid index on uncached object.'
    );

    my $c = $ca->current_index( $ca->{start_index} - 1 );
    ok(
        !defined( $ca->current_index( $ca->{start_index} - 1 ) ),
        'Testing current_index() with invalid index on cached object.'
    );
    ok(
        !defined( $cn->current_index( $cn->{start_index} - 1 ) ),
        'Testing current_index() with invalid index on uncached object.'
    );

    $ca->current_index( $ca->{start_index} );
    $cn->current_index( $cn->{start_index} );

    ok( !defined( $ca->back() ),
        'Testing back() with invalid index on cached object.' );
    ok( !defined( $cn->back() ),
        'Testing back() with invalid index on uncached object.' );
}
