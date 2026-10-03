#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON::MaybeXS;
use Path::Tiny;

use Kubernetes::Comb::SVG::Cell;
use Kubernetes::Comb::SVG::Layout;

my $CELL   = 'Kubernetes::Comb::SVG::Cell';
my $LAYOUT = 'Kubernetes::Comb::SVG::Layout';
my $data   = path(__FILE__)->parent->child( 'data', 'layout' );
my $json   = JSON::MaybeXS->new( utf8 => 1 );

sub cells {
  my ( $fixture ) = @_;
  return [ $CELL->cells_from(
    $json->decode( $data->child( $fixture.'.json' )->slurp_raw ),
    group_label => 'tier'
  ) ];
}

sub layout {
  my ( $fixture, %opt ) = @_;
  return $LAYOUT->new( cells => cells($fixture), %opt )->layout;
}

# id => placed cell
sub by_id { +{ map { $_->{id} => $_ } @{ $_[0]->{cells} } } }

# The ids row by row, as drawn: [ [ row 0 ids ], [ row 1 ids ], ... ] of one group
sub rows_of {
  my ( $layout, $group ) = @_;
  my @rows;
  for my $cell ( @{ $layout->{cells} } ) {
    next if defined $group ? !defined $cell->{group} || $cell->{group} ne $group
                           : defined $cell->{group};
    $rows[ $cell->{row} ][ $cell->{column} ] = $cell->{id};
  }
  return \@rows;
}

sub edges_of { [ map { $_->{from}.'>'.$_->{to} } @{ $_[0]->{edges} } ] }

sub r2 { sprintf( '%.2f', $_[0] ) + 0 }

# The honeycomb of the default size, worked out by hand
my $R      = 56;
my $W      = sqrt(3) * $R;         # hexagon width
my $STEP_X = $W + $R / 7;          # centre to centre in a row
my $STEP_Y = $STEP_X * sqrt(3) / 2;

subtest 'depth rows' => sub {
  my $layout = layout('chain');
  is_deeply( rows_of($layout),
    [ [qw( db nats )], [qw( api cache )], [qw( web )] ],
    'a row per depth, sorted by name' );
  my $cell = by_id($layout);
  is( $cell->{db}{depth},  0, 'no dependency: depth 0' );
  is( $cell->{api}{depth}, 1, 'one below its dependencies' );
  is( $cell->{web}{depth}, 2, 'one below its deepest dependency' );
  is_deeply( edges_of($layout),
    [qw( api>db api>nats cache>db web>api )], 'edges by id, sorted' );
  is_deeply( $layout->{groups},
    [ { name => undef, heading => undef, y => 0, height => $layout->{height} } ],
    'one unnamed group without a heading' );
};

subtest 'honeycomb coordinates' => sub {
  my $layout = layout('chain');
  my $cell   = by_id($layout);
  is( $cell->{db}{x}, r2( $W / 2 ), 'first cell starts at the left edge' );
  is( $cell->{db}{y}, $R, 'first row starts at the top edge' );
  is( $cell->{nats}{x}, r2( $W / 2 + $STEP_X ), 'next cell one step right' );
  is( $cell->{nats}{y}, $cell->{db}{y}, 'same row, same y' );
  is( $cell->{api}{x}, r2( $W / 2 + $STEP_X / 2 ), 'second row shifted by half a cell' );
  is( $cell->{api}{y}, r2( $R + $STEP_Y ), 'second row one step down' );
  is( $cell->{web}{x}, $cell->{db}{x}, 'third row not shifted' );
  is( $cell->{web}{y}, r2( $R + 2 * $STEP_Y ), 'third row two steps down' );
  is( $layout->{width},  r2( $STEP_X / 2 + $STEP_X + $W ), 'width reaches the right edge of the shifted row' );
  is( $layout->{height}, r2( 2 * $R + 2 * $STEP_Y ), 'height reaches the bottom of the last row' );

  my $apart = sqrt( ( $cell->{api}{x} - $cell->{db}{x} ) ** 2
                  + ( $cell->{api}{y} - $cell->{db}{y} ) ** 2 );
  ok( abs( $apart - $STEP_X ) < 0.02, 'diagonal neighbours as far apart as row neighbours' );
  ok( $STEP_X > $W, 'a gap between neighbouring hexagons' );
};

subtest 'size' => sub {
  my $small = by_id( layout( 'chain', size => 28 ) );
  my $big   = by_id( layout('chain') );
  is( $small->{db}{y}, 28, 'radius is the size' );
  ok( abs( $small->{web}{y} * 2 - $big->{web}{y} ) <= 0.02, 'everything scales with size' );
  ok( abs( $small->{nats}{x} * 2 - $big->{nats}{x} ) <= 0.02, 'the gap scales too' );
};

subtest 'wrap at columns' => sub {
  my $layout = layout( 'wrap', columns => 3 );
  is_deeply( rows_of($layout),
    [ [qw( base1 base2 base3 )], [qw( base4 base5 base6 )], [qw( base7 base8 )], [qw( top )] ],
    'a depth row longer than columns wraps into the next rows' );
  my $cell = by_id($layout);
  is( $cell->{base4}{x}, r2( $W / 2 + $STEP_X / 2 ), 'wrapped row is shifted' );
  is( $cell->{base7}{x}, r2( $W / 2 ), 'row after it is not' );
  is( $cell->{top}{x}, r2( $W / 2 + $STEP_X / 2 ), 'next depth keeps alternating' );
  is( $cell->{top}{depth}, 1, 'wrapping does not change the depth' );
  is( $cell->{top}{row},   3, 'but the drawn row' );

  is_deeply( rows_of( layout('wrap') ),
    [ [qw( base1 base2 base3 base4 base5 base6 )], [qw( base7 base8 )], [qw( top )] ],
    'default is six columns' );
  is_deeply( rows_of( layout( 'wrap', columns => 8 ) ),
    [ [ map { 'base'.$_ } 1 .. 8 ], [qw( top )] ], 'a row of exactly columns does not wrap' );
};

subtest 'groups' => sub {
  my $layout = layout('groups');
  is_deeply( [ map { $_->{name} } @{ $layout->{groups} } ], [ 'alpha', 'beta', undef ],
    'groups in name order, the unnamed last' );
  is_deeply( rows_of( $layout, 'alpha' ), [ [qw( a1 )], [qw( a2 )] ], 'alpha' );
  is_deeply( rows_of( $layout, 'beta' ),  [ [qw( b0 )], [qw( b1 )] ], 'beta' );
  is_deeply( rows_of( $layout, undef ),   [ [qw( z )] ], 'unnamed' );

  my ( $alpha, $beta, $rest ) = @{ $layout->{groups} };
  my $cell = by_id($layout);
  is( $alpha->{y}, 0, 'first group at the top' );
  is( $alpha->{heading}{x}, 0, 'heading at the left edge' );
  ok( $alpha->{heading}{y} > 0, 'heading baseline below the top' );
  ok( $alpha->{heading}{y} < $cell->{a1}{y} - $R, 'heading above the first hexagon' );
  ok( $beta->{y} > $alpha->{y} + $alpha->{height}, 'space between two groups' );
  ok( $beta->{heading}{y} > $cell->{a2}{y} + $R, 'next heading below the last hexagon' );
  ok( $rest->{heading}, 'the unnamed group gets room for a heading among others' );
  is( $rest->{y} + $rest->{height}, $layout->{height}, 'last group ends the picture' );
  is( $cell->{b0}{x}, $cell->{a1}{x}, 'every group starts unshifted' );
  is_deeply( [ map { $_->{id} } @{ $layout->{cells} } ], [qw( a1 a2 b0 b1 z )],
    'cells listed group by group, row by row' );

  my $one = layout('one-group');
  is( $one->{groups}[0]{name}, 'alpha', 'a single named group' );
  ok( $one->{groups}[0]{heading}, 'has its heading' );
};

subtest 'depth across groups' => sub {
  my $cell = by_id( layout('groups') );
  is( $cell->{b1}{depth}, 2, 'depth counts dependencies in other groups' );
  is( $cell->{b1}{row},   1, 'rows inside the group follow depth order' );

  my $layout = layout('gap-depth');
  $cell = by_id($layout);
  is( $cell->{a3}{depth}, 2, 'a1 > b1 > a3' );
  is_deeply( rows_of( $layout, 'alpha' ), [ [qw( a1 )], [qw( a3 )] ],
    'a depth with no cell in the group takes no row' );
  is_deeply( rows_of( $layout, 'beta' ), [ [qw( b1 )] ], 'a group starting at depth 1 starts at row 0' );
};

subtest 'cycle' => sub {
  my $layout = eval { layout('cycle') };
  ok( $layout, 'a cycle gives a layout' ) or return diag($@);
  my $cell = by_id($layout);
  is( $cell->{a}{depth}, 0, 'cycle without outside dependency is at depth 0' );
  is( $cell->{b}{depth}, $cell->{a}{depth}, 'the cells of a cycle share a depth' );
  is( $cell->{b}{row}, $cell->{a}{row}, 'and a row' );
  is( $cell->{self}{depth}, 0, 'a self-reference is no depth' );
  is( $cell->{below}{depth},  1, 'a cell depending on a cycle sits below it' );
  is( $cell->{lowest}{depth}, 2, 'and what depends on that, below again' );
  is_deeply( rows_of($layout), [ [qw( a b free self )], [qw( below )], [qw( lowest )] ], 'rows' );
  is_deeply( edges_of($layout), [qw( a>b b>a below>a lowest>below lowest>self )],
    'both edges of the cycle, none from a cell to itself' );
};

subtest 'long chain and long cycle' => sub {
  my $n = 20_000;
  my @chain = map { +{
    metadata => { name => 'c'.$_ },
    $_ ? ( spec => { dependsOn => [ 'c'.( $_ - 1 ) ] } ) : ()
  } } 0 .. $n - 1;
  my $cell = by_id( $LAYOUT->new( cells => [ $CELL->cells_from( \@chain ) ] )->layout );
  is( $cell->{ 'c'.( $n - 1 ) }{depth}, $n - 1, 'a long chain needs no deep recursion' );

  $chain[0]{spec} = { dependsOn => [ 'c'.( $n - 1 ) ] };
  $cell = by_id( $LAYOUT->new( cells => [ $CELL->cells_from( \@chain ) ] )->layout );
  is( scalar( grep { $_->{depth} != 0 } values %$cell ), 0, 'a long cycle shares depth 0' );
};

subtest 'unknown dependency' => sub {
  my $layout = layout('unknown');
  my $cell   = by_id($layout);
  is( $cell->{lonely}{depth}, 0, 'only an unknown dependency: depth 0' );
  is( $cell->{api}{depth},    1, 'the known one still counts' );
  is_deeply( edges_of($layout), ['api>db'], 'no edge to a cell that is not there' );
};

subtest 'identity is the id' => sub {
  my $layout = layout('same-name');
  is_deeply( rows_of($layout), [ [qw( dev/db prod/db )], [qw( dev/api )] ],
    'same name twice: ordered by id' );
  is_deeply( edges_of($layout), ['dev/api>dev/db'], 'edge to the right one' );

  my $cells = cells('same-name');
  my $twice = $LAYOUT->new( cells => [ @$cells, @$cells ] )->layout;
  is_deeply( $twice, $layout, 'a cell handed in twice is placed once' );
};

subtest 'empty input' => sub {
  for my $layout ( layout('empty'), $LAYOUT->new->layout ) {
    is_deeply( $layout, { width => 0, height => 0, groups => [], cells => [], edges => [] },
      'empty layout' );
  }
};

subtest 'determinism' => sub {
  my $canon = JSON::MaybeXS->new( canonical => 1 );
  for my $fixture (qw( chain wrap groups cycle same-name )) {
    my $cells = cells($fixture);
    my $want  = $canon->encode( $LAYOUT->new( cells => $cells )->layout );
    is( $canon->encode( $LAYOUT->new( cells => [ reverse @$cells ] )->layout ), $want,
      $fixture.': input order does not matter' );
    is( $canon->encode( $LAYOUT->new( cells => $cells )->layout ), $want,
      $fixture.': twice the same' );
  }
};

subtest 'rounding' => sub {
  for my $size ( 56, 17.3, 100 / 3 ) {
    my $layout = layout( 'groups', size => $size );
    my @numbers = (
      @{$layout}{qw( width height )},
      ( map { ( $_->{x}, $_->{y} ) } @{ $layout->{cells} } ),
      ( map { ( $_->{y}, $_->{height}, $_->{heading}{x}, $_->{heading}{y} ) } @{ $layout->{groups} } )
    );
    is( scalar( grep { $_ !~ /\A\d+(?:\.\d{1,2})?\z/ } @numbers ), 0,
      'size '.$size.': at most two decimals, never negative' )
      or diag( join ' ', @numbers );
  }
};

done_testing;
