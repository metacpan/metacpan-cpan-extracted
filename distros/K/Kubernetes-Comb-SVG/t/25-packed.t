#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON::MaybeXS;
use Path::Tiny;
use XML::LibXML;
use XML::LibXML::XPathContext;

use Kubernetes::Comb::SVG;
use Kubernetes::Comb::SVG::Cell;
use Kubernetes::Comb::SVG::Layout;

# The packed layout, SPEC 5 "Packed layout -- the status monitor": first the
# placement on the plain data of the layout, then the picture, parsed with a
# real XML parser.

my $SVG    = 'Kubernetes::Comb::SVG';
my $CELL   = 'Kubernetes::Comb::SVG::Cell';
my $LAYOUT = 'Kubernetes::Comb::SVG::Layout';
my $data   = path(__FILE__)->parent->child( 'data', 'layout' );
my $json   = JSON::MaybeXS->new( utf8 => 1 );

sub fixture { $json->decode( $data->child( $_[0].'.json' )->slurp_raw ) }

sub cells { [ $CELL->cells_from( ref $_[0] ? $_[0] : fixture( $_[0] ), group_label => 'tier' ) ] }

sub packed {
  my ( $combs, %opt ) = @_;
  return $LAYOUT->new( cells => cells($combs), mode => 'packed', %opt )->layout;
}

sub by_id { +{ map { $_->{id} => $_ } @{ $_[0]->{cells} } } }

# The ids row by row, as drawn, of one group
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

# The cells in the longest row of the picture
sub columns_of {
  my ( $layout ) = @_;
  my ( $most ) = sort { $b <=> $a } map { $_->{column} + 1 } @{ $layout->{cells} };
  return $most;
}

sub r2 { sprintf( '%.2f', $_[0] ) + 0 }

my $R      = 56;
my $W      = sqrt(3) * $R;
my $STEP_X = $W + $R / 7;
my $STEP_Y = $STEP_X * sqrt(3) / 2;

my @BASE = map { 'base'.$_ } 1 .. 8;

#### Placement

subtest 'placement ignores dependsOn' => sub {
  my $layout = packed( 'chain', columns => 3 );
  is_deeply( rows_of($layout), [ [qw( api cache db )], [qw( nats web )] ],
    'sorted by id, rows filled left to right, top to bottom' );
  my $cell = by_id($layout);
  is( $cell->{api}{y}, $cell->{db}{y}, 'a dependent sits in the row of its dependency' );
  is( $cell->{api}{depth}, 1, 'the depth is still reported' );
  is_deeply( [ map { $_->{from}.'>'.$_->{to} } @{ $layout->{edges} } ],
    [qw( api>db api>nats cache>db web>api )], 'and so are the edges' );

  is( $cell->{api}{x}, r2( $W / 2 ), 'first cell at the left edge' );
  is( $cell->{api}{y}, $R, 'first row at the top edge' );
  is( $cell->{cache}{x}, r2( $W / 2 + $STEP_X ), 'next cell one step right' );
  is( $cell->{nats}{x}, r2( $W / 2 + $STEP_X / 2 ), 'second row shifted by half a cell' );
  is( $cell->{nats}{y}, r2( $R + $STEP_Y ), 'second row one step down' );

  is_deeply( rows_of( packed( 'same-name', columns => 2 ) ), [ [qw( dev/api dev/db )], [qw( prod/db )] ],
    'namespace first, then name' );
};

subtest 'odd data' => sub {
  for my $name (qw( cycle unknown empty )) {
    my $layout = eval { packed($name) };
    ok( $layout, $name.': a layout' ) or diag $@;
  }
  is_deeply( packed('empty'), { width => 0, height => 0, groups => [], cells => [], edges => [] },
    'no cells: the empty layout' );
  is_deeply( rows_of( packed( 'cycle', columns => 6 ) ), [ [qw( a b below free lowest self )] ],
    'a cycle is packed like anything else' );
};

#### The grid

subtest 'columns' => sub {
  is_deeply( rows_of( packed( 'wrap', columns => 4 ) ),
    [ [ @BASE[ 0 .. 3 ] ], [ @BASE[ 4 .. 7 ] ], ['top'] ], 'four cells per row' );
  is_deeply( rows_of( packed( 'wrap', columns => 20 ) ), [ [ @BASE, 'top' ] ],
    'more columns than cells: one row' );
};

subtest 'rows' => sub {
  is_deeply( rows_of( packed( 'wrap', rows => 2 ) ), [ [ @BASE[ 0 .. 4 ] ], [ @BASE[ 5 .. 7 ], 'top' ] ],
    'two rows: the fewest columns that fit' );
  is_deeply( rows_of( packed( 'wrap', rows => 1 ) ), [ [ @BASE, 'top' ] ], 'one row' );
  is( scalar @{ rows_of( packed( 'wrap', rows => 3 ) ) }, 3, 'three rows of three' );
  is( scalar @{ rows_of( packed( 'wrap', rows => 4 ) ) }, 3,
    'nine cells in four rows need three columns, which fill three rows only' );
  is( scalar @{ rows_of( packed( 'wrap', rows => 50 ) ) }, 9, 'more rows than cells: one cell per row' );
};

subtest 'aspect' => sub {
  my $wide = packed('wrap');
  my $tall = packed( 'wrap', aspect => 9 / 16 );
  is( columns_of($wide), 4, 'default 16/9: nine cells in rows of four' );
  is_deeply( rows_of($wide), rows_of( packed( 'wrap', aspect => 16 / 9 ) ), 'the default is 16/9' );
  is( columns_of($tall), 2, '9/16: rows of two' );
  ok( $wide->{width} > $wide->{height}, 'a wide aspect gives a wide honeycomb' );
  ok( $tall->{width} < $tall->{height}, 'a tall aspect gives a tall one' );
  is( columns_of( packed( 'wrap', aspect => 1000 ) ), 9, 'extremely wide: one row' );
  is( columns_of( packed( 'wrap', aspect => 0.001 ) ), 1, 'extremely tall: one column' );

  # The chosen grid is the closest one: no other column count comes nearer.
  for my $aspect ( 16 / 9, 9 / 16, 1, 4 / 3, 3 ) {
    for my $name (qw( wrap groups )) {
      my $count = scalar @{ cells($name) };
      my ( $best, $miss );
      for my $columns ( 1 .. $count ) {
        my $layout = packed( $name, columns => $columns );
        my $off = abs( log( $layout->{width} / $layout->{height} ) - log($aspect) );
        ( $best, $miss ) = ( $layout, $off ) if !defined $miss || $off < $miss - 1e-9;
      }
      is_deeply( packed( $name, aspect => $aspect ), $best,
        $name.' at '.r2($aspect).': the column count closest to the aspect' );
    }
  }
};

subtest 'frame' => sub {
  is( columns_of( packed( 'wrap', aspect => 1 ) ), 3, 'square, the honeycomb alone: three columns' );
  is( columns_of( packed( 'wrap', aspect => 1, frame_height => 300 ) ), 5,
    'with a frame that adds height: wider, so the whole is square' );
  is( columns_of( packed( 'wrap', aspect => 1, frame_width => 600 ) ), 1,
    'with a frame that adds width: narrower' );
  my $framed = packed( 'wrap', columns => 3, frame_width => 100, frame_height => 100 );
  is_deeply( $framed, packed( 'wrap', columns => 3 ), 'the frame is never part of the result' );
};

subtest 'precedence' => sub {
  is_deeply( packed( 'wrap', columns => 2, rows => 1, aspect => 1000 ), packed( 'wrap', columns => 2 ),
    'columns beats rows and aspect' );
  is_deeply( packed( 'wrap', rows => 2, aspect => 0.001 ), packed( 'wrap', rows => 2 ),
    'rows beats aspect' );
  is_deeply( packed( 'wrap', columns => 6 ), packed( 'wrap', columns => 6, rows => 9 ),
    'a given 6 is given, though it is the default of the depth layout' );
  isnt( columns_of( packed( 'wrap', rows => 1 ) ), 6, 'the default 6 does not count as given' );
};

#### Groups

subtest 'groups' => sub {
  my $layout = packed( 'groups', columns => 2 );
  is_deeply( [ map { $_->{name} } @{ $layout->{groups} } ], [ 'alpha', 'beta', undef ],
    'groups in name order, the unnamed last' );
  is_deeply( rows_of( $layout, 'alpha' ), [ [qw( a1 a2 )] ], 'alpha is its own block' );
  is_deeply( rows_of( $layout, 'beta' ),  [ [qw( b0 b1 )] ], 'beta too' );
  is_deeply( rows_of( $layout, undef ),   [ [qw( z )] ], 'and the unnamed' );
  my $cell = by_id($layout);
  ok( $cell->{b0}{y} > $cell->{a1}{y} + 2 * $R, 'blocks are stacked' );
  ok( $layout->{groups}[1]{heading}, 'with their headings' );

  is_deeply( rows_of( packed( 'groups', rows => 2 ), 'alpha' ), [ [qw( a1 )], [qw( a2 )] ],
    'rows holds for every block on its own' );
  is( columns_of( packed( 'groups', aspect => 0.001 ) ), 1, 'aspect: one column count for all blocks' );
  is( columns_of( packed( 'groups', aspect => 1000 ) ), 2, 'at most the largest block in a row' );
};

#### Stability

subtest 'stable while the set of Combs is the same' => sub {
  my $combs  = fixture('wrap');
  my $before = packed($combs);
  my @phases = qw( Error Blocked Pending Running NeedsConfig Disabled Bogus );
  my $n      = 0;
  $_->{status} = { phase => $phases[ $n++ % @phases ] } for @{ $combs->{items} };
  is_deeply( packed($combs), $before, 'phases changing move nothing' );
  is_deeply( packed( { items => [ reverse @{ $combs->{items} } ] } ), $before,
    'nor does the order of the input' );
};

#### The picture

sub picture {
  my ( $combs, %opt ) = @_;
  my $xpc = XML::LibXML::XPathContext->new(
    XML::LibXML->load_xml( string => $SVG->new( combs => $combs, %opt )->render ) );
  $xpc->registerNs( s => 'http://www.w3.org/2000/svg' );
  return $xpc;
}

my $COMB = '//s:g[ contains(concat(" ",@class," ")," comb ") ]';
my $DEP  = '//s:path[ contains(concat(" ",@class," ")," dep ") ]';

# data-id => the corners of its hexagon
sub hexagons {
  my ( $xpc ) = @_;
  return +{ map { $_->getAttribute('data-id') => $xpc->findvalue( 's:polygon/@points', $_ ) }
    $xpc->findnodes($COMB) };
}

subtest 'picture: placement' => sub {
  my $combs = fixture('wrap');
  my $xpc   = picture( $combs, layout => 'packed', columns => 3 );
  is( $xpc->findnodes($COMB)->size, 9, 'every Comb is drawn' );
  my %y;
  $y{ $xpc->findvalue( 's:text[1]/@y', $_ ) }++ for $xpc->findnodes($COMB);
  is_deeply( [ sort values %y ], [ 3, 3, 3 ], 'columns => 3: three rows of three' );
  my $place = hexagons($xpc);
  isnt( $place->{top}, hexagons( picture( $combs, columns => 3 ) )->{top},
    'not where the depth layout puts it' );

  my $n = 0;
  $_->{status} = { phase => $n++ % 2 ? 'Error' : 'Running' } for @{ $combs->{items} };
  my $after = picture( $combs, layout => 'packed', columns => 3 );
  is_deeply( hexagons($after), $place, 'phases changing move no hexagon' );
  is( $after->findnodes( $COMB.'[@data-phase="Error"]' )->size, 4, 'while the phases are drawn' );
};

subtest 'picture: grid options reach the layout' => sub {
  my $combs = fixture('wrap');
  my $render = sub { $SVG->new( combs => $combs, layout => 'packed', @_ )->render };
  isnt( $render->(), $render->( aspect => 9 / 16 ), 'aspect' );
  isnt( $render->(), $render->( rows => 1 ), 'rows' );
  isnt( $render->(), $render->( columns => 6 ), 'columns: a given 6 is not the default' );
  is( $render->( columns => 2, rows => 1 ), $render->( columns => 2 ), 'columns beats rows' );
  is( $render->( rows => 2, aspect => 9 / 16 ), $render->( rows => 2 ), 'rows beats aspect' );
  is( $render->(), $render->(), 'two renders are byte-identical' );
};

subtest 'picture: aspect is met by the whole canvas' => sub {
  my $combs = fixture('wrap');
  my $ratio = sub {
    my ( undef, undef, $width, $height )
      = split ' ', picture( $combs, layout => 'packed', @_ )->findvalue('/s:svg/@viewBox');
    return $width / $height;
  };
  for my $aspect ( 16 / 9, 9 / 16, 1 ) {
    my ( $closest ) = sort { $a <=> $b }
      map { abs( log( $ratio->( columns => $_ ) ) - log($aspect) ) } 1 .. 9;
    ok( abs( abs( log( $ratio->( aspect => $aspect ) ) - log($aspect) ) - $closest ) < 1e-9,
      r2($aspect).': no column count brings the viewBox closer' );
  }
  cmp_ok( $ratio->(), '>', 1, 'default: a wide picture' );
  cmp_ok( $ratio->( aspect => 9 / 16 ), '<', 1, '9/16: an upright one' );
};

subtest 'picture: groups' => sub {
  my $xpc = picture( fixture('groups'), layout => 'packed', group_label => 'tier' );
  is_deeply( [ map { $_->getAttribute('data-group') } $xpc->findnodes('//s:g[@data-group]') ],
    [qw( alpha beta )], 'a heading per named group' );
  is( $xpc->findnodes($COMB)->size, 5, 'every Comb is drawn' );
};

subtest 'picture: edges' => sub {
  my $combs = fixture('chain');
  is( picture( $combs, layout => 'packed' )->findnodes($DEP)->size, 0, 'packed: no edges by default' );
  is( picture( $combs, layout => 'packed', edges => 1 )->findnodes($DEP)->size, 4,
    'packed: edges => 1 wins' );
  is( picture( $combs, layout => 'packed', edges => 0 )->findnodes($DEP)->size, 0,
    'packed: edges => 0' );
  is( picture($combs)->findnodes($DEP)->size, 4, 'depth: edges by default' );
  is( picture( $combs, edges => 0 )->findnodes($DEP)->size, 0, 'depth: edges => 0' );
};

subtest 'the depth layout is what it was' => sub {
  for my $name (qw( chain wrap groups cycle )) {
    my $combs = fixture($name);
    my %opt   = ( combs => $combs, group_label => 'tier' );
    is( $SVG->new( %opt, layout => 'depth' )->render, $SVG->new(%opt)->render,
      $name.': layout => depth is the default' );
    is( $SVG->new( %opt, rows => 1, aspect => 3 )->render, $SVG->new(%opt)->render,
      $name.': rows and aspect do nothing to it' );
    is( $SVG->new( %opt, columns => 6 )->render, $SVG->new(%opt)->render,
      $name.': six columns given or by default' );
  }
};

subtest 'bad option values' => sub {
  for my $bad ( [ layout => 'spiral' ], [ rows => 0 ], [ rows => 1.5 ], [ aspect => 0 ],
    [ aspect => '16:9' ] ) {
    ok( !eval { $SVG->new( combs => [], @$bad ); 1 },
      $bad->[0].' => '.$bad->[1].': refused by the constructor, like every option of the wrong type' );
  }
};

done_testing;
