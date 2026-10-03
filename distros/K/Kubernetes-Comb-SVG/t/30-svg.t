#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON::MaybeXS;
use Path::Tiny;
use XML::LibXML;
use XML::LibXML::XPathContext;

use Kubernetes::Comb::SVG;

# The picture, SPEC 6 to 8: the SVG is parsed with a real XML parser and every
# assertion looks at elements and attributes.

my $SVG  = 'Kubernetes::Comb::SVG';
my $data = path(__FILE__)->parent->child( 'data', 'svg' );
my $json = JSON::MaybeXS->new( utf8 => 1 );
my $SIZE = 56;

sub fixture { $json->decode( $data->child( $_[0].'.json' )->slurp_raw ) }

# A fixture name or the combs themselves in, the parsed picture out.
sub picture {
  my ( $combs, %opt ) = @_;
  $combs = fixture($combs) unless ref $combs;
  return parse( $SVG->new( combs => $combs, %opt )->render );
}

sub parse {
  my ( $svg ) = @_;
  my $xpc = XML::LibXML::XPathContext->new( XML::LibXML->load_xml( string => $svg ) );
  $xpc->registerNs( s => 'http://www.w3.org/2000/svg' );
  return $xpc;
}

sub has_class { 'contains(concat(" ",@class," ")," '.$_[0].' ")' }

# Cells only: the legend swatches are polygon.hex as well, but never g.comb.
my $COMB = 'g[ '.has_class('comb').' ]';

sub combs { $_[0]->findnodes( '//s:'.$COMB ) }

sub comb {
  my ( $xpc, $name ) = @_;
  my ( $node ) = grep { $_->getAttribute('data-name') eq $name } combs($xpc);
  return $node;
}

sub comb_by_id {
  my ( $xpc, $id ) = @_;
  my ( $node ) = grep { $_->getAttribute('data-id') eq $id } combs($xpc);
  return $node;
}

sub classes { +{ map { $_ => 1 } split ' ', $_[0]->getAttribute('class') } }

# XPath from any node, with the svg prefix known
sub xp {
  my ( $node ) = @_;
  return $node if $node->isa("XML::LibXML::XPathContext");
  my $xpc = XML::LibXML::XPathContext->new($node);
  $xpc->registerNs( s => "http://www.w3.org/2000/svg" );
  return $xpc;
}

sub child { my ( $node, $path ) = @_; xp($node)->findnodes($path) }

sub val { my ( $node, $path ) = @_; xp($node)->findvalue($path) }

# The text of a cell's line, by class
sub line { my ( $node, $class ) = @_; join '', map { $_->textContent } child( $node, 's:text[ '.has_class($class).' ]' ) }

# Centre of a hexagon: the first point is the top corner, one radius above it
sub centre {
  my ( $node, $size ) = @_;
  my ( $x, $y ) = val( $node, q{s:polygon/@points} ) =~ /\A(\S+),(\S+)/;
  return ( $x, $y + ( $size || $SIZE ) );
}

sub tooltip { [ split /\n/, val( $_[0], "s:title" ) ] }

sub count { scalar @{ [ xp($_[0])->findnodes( $_[1] ) ] } }

sub style_text { $_[0]->findvalue('//s:style') }

sub view_box { [ split ' ', $_[0]->findvalue('/s:svg/@viewBox') ] }

subtest 'root, title, desc, style, defs' => sub {
  my $xpc = picture( 'phases', title => 'Lab' );
  my $root = $xpc->findnodes('/s:svg')->get_node(1);
  is( $root->getAttribute('xmlns'), 'http://www.w3.org/2000/svg', 'xmlns' );
  is( $root->getAttribute('role'), 'img', 'role img' );
  is( $root->getAttribute('aria-labelledby'), 'comb-title comb-desc', 'labelled by title and desc' );
  ok( $root->hasAttribute('class') && classes($root)->{'comb-svg'}, 'svg.comb-svg' );
  like( $root->getAttribute('viewBox'), qr/\A0 0 [\d.]+ [\d.]+\z/, 'viewBox' );
  ok( !$root->hasAttribute('width') && !$root->hasAttribute('height'), 'no fixed pixel size' );

  is( $xpc->findvalue('/s:svg/s:title[@id="comb-title"]'), 'Lab', 'title element, id comb-title' );
  is( count( $xpc, '/s:svg/s:desc[@id="comb-desc"]' ), 1, 'desc element, id comb-desc' );
  is( $xpc->findvalue('/s:svg/s:text[@class="heading"]'), 'Lab', 'text.heading carries the title' );
  is( $xpc->findvalue('/s:svg/s:rect[@class="panel"]/@class'), 'panel', 'rect.panel' );
  is( count( $xpc, '/s:svg/s:defs/s:marker[@id="comb-arrow"]' ), 1, 'arrow marker in defs' );

  is( count( $xpc, '//s:style' ), 1, 'exactly one style element' );
  my $css = style_text($xpc);
  for my $var (qw( running pending blocked needsconfig disabled error stopped notdeployed unknown bg fg )) {
    like( $css, qr/--comb-\Q$var\E:#/, '--comb-'.$var.' custom property' );
  }
  my @media = $css =~ /(\@media \(prefers-color-scheme:dark\))/g;
  is( scalar @media, 1, 'one prefers-color-scheme dark block' );
};

subtest 'default title' => sub {
  my $xpc = picture('no-status');
  is( $xpc->findvalue('/s:svg/s:title'), 'Combs', 'default title is Combs' );
};

subtest 'desc: the summary' => sub {
  is( picture('phases')->findvalue('/s:svg/s:desc'),
    '8 Combs: 1 Running, 1 Pending, 1 Blocked, 1 NeedsConfig, 1 Disabled, 1 Error, 1 Stopped, 1 NotDeployed',
    'fixed phase order' );
  is( picture('no-status')->findvalue('/s:svg/s:desc'), '1 Comb: 1 Unknown', 'singular, Unknown counted' );
  is( picture( [] )->findvalue('/s:svg/s:desc'), '0 Combs', 'empty is 0 Combs' );
  my @mixed = map { { metadata => { name => 'n'.$_ }, status => { phase => $_ < 5 ? 'Running' : 'Error' } } } 1 .. 6;
  push @mixed, { metadata => { name => 'u' }, status => { phase => 'Blocked' } }, { metadata => { name => 'v' } };
  is( picture( \@mixed )->findvalue('/s:svg/s:desc'),
    '8 Combs: 4 Running, 1 Blocked, 2 Error, 1 Unknown',
    'counts per phase in the fixed order, Unknown last' );
  my @rest = map { { metadata => { name => 'n'.$_ }, status => { phase => $_ < 3 ? 'NotDeployed' : 'Stopped' } } } 1 .. 3;
  push @rest, { metadata => { name => 'e' }, status => { phase => 'Error' } }, { metadata => { name => 'v' } };
  is( picture( \@rest )->findvalue('/s:svg/s:desc'),
    '5 Combs: 1 Error, 1 Stopped, 2 NotDeployed, 1 Unknown',
    'Stopped and NotDeployed are counted as themselves, after Error and before Unknown' );
};

subtest 'every phase' => sub {
  my $xpc = picture('phases');
  my @nodes = combs($xpc);
  is( scalar @nodes, 8, 'one g.comb per cell' );
  for my $phase (qw( Running Pending Blocked NeedsConfig Disabled Error Stopped NotDeployed )) {
    my $node = comb( $xpc, lc $phase );
    ok( $node, $phase.': cell found' );
    ok( classes($node)->{ 'phase-'.$phase }, $phase.': class phase-'.$phase );
    is( $node->getAttribute('data-phase'), $phase, $phase.': data-phase' );
    is( line( $node, 'phase' ), $phase, $phase.': phase as text, not by colour alone' );
    is( count( $node, 's:polygon[ '.has_class('hex').' ]' ), 1, $phase.': one hexagon' );
    is( line( $node, 'name' ), lc $phase, $phase.': name text' );
    is( count( $node, 's:text[ '.has_class('upstream').' ]' ), 0, $phase.': no upstream line' );
    is( !!classes($node)->{disabled}, $phase eq 'Disabled', $phase.': muted only when Disabled' );
    is_deeply( tooltip($node), [ lc $phase, 'phase: '.$phase ], $phase.': tooltip names the phase, no raw text in brackets' );
  }
  my @points = map { val( $_, q{s:polygon/@points} ) } @nodes;
  is( scalar( () = $points[0] =~ /,/g ), 6, 'a hexagon has six points' );
  my %id = map { $_->getAttribute('data-id') => 1 } @nodes;
  is( scalar keys %id, 8, 'eight distinct data-id' );
};

subtest 'unknown phase' => sub {
  my $node = comb( picture('unknown-phase'), 'odd' );
  ok( classes($node)->{'phase-Unknown'}, 'class phase-Unknown' );
  is( $node->getAttribute('data-phase'), 'Unknown', 'data-phase is Unknown' );
  is( line( $node, 'phase' ), 'Unknown', 'phase text is Unknown' );
  ok( ( grep { $_ eq 'phase: Unknown (Frobnicating)' } @{ tooltip($node) } ),
    'tooltip keeps the original phase text' );
};

subtest 'missing status' => sub {
  my $node = comb( picture('no-status'), 'bare' );
  ok( classes($node)->{'phase-Unknown'}, 'class phase-Unknown' );
  is( line( $node, 'phase' ), 'Unknown', 'phase text Unknown' );
  is_deeply( tooltip($node), [ 'bare', 'phase: Unknown' ], 'tooltip: no original phase, no message' );
  ok( !classes($node)->{borrowed} && !classes($node)->{disabled}, 'neither borrowed nor disabled' );
};

subtest 'disabled' => sub {
  my $xpc = picture('disabled');
  my $off = comb( $xpc, 'off' );
  ok( classes($off)->{disabled}, 'spec.enabled false: class disabled' );
  ok( classes($off)->{'phase-Disabled'}, 'and phase-Disabled' );
  is( $off->getAttribute('data-phase'), 'Disabled', 'data-phase Disabled whatever status says' );
  is( line( $off, 'phase' ), 'Disabled', 'phase text' );
  my $on = comb( $xpc, 'on' );
  ok( !classes($on)->{disabled}, 'the enabled one is not disabled' );
  ok( classes( comb( picture('phases'), 'disabled' ) )->{disabled}, 'status phase Disabled is muted too' );
};

subtest 'borrowed' => sub {
  my $xpc = picture('borrowed');
  my $with = comb( $xpc, 'with-context' );
  ok( classes($with)->{borrowed}, 'borrowed class' );
  is( line( $with, 'upstream' ), 'from prod', 'upstream line names the context' );
  ok( ( grep { $_ eq 'upstream: context prod' } @{ tooltip($with) } ), 'tooltip: context only' );
  ok( ( grep { $_ eq 'via: prod' } @{ tooltip($with) } ), 'tooltip: via' );

  my $without = comb( $xpc, 'no-context' );
  ok( classes($without)->{borrowed}, 'borrowed without context' );
  is( line( $without, 'upstream' ), 'borrowed', 'upstream line says borrowed' );
  ok( ( grep { $_ eq 'upstream: recorded' } @{ tooltip($without) } ), 'tooltip: neither class nor context' );

  my $own = comb( $xpc, 'own' );
  ok( !classes($own)->{borrowed}, 'own cell is not borrowed' );
  is( count( $own, 's:text[ '.has_class('upstream').' ]' ), 0, 'no text.upstream unless borrowed' );
  ok( !( grep { /\A(?:upstream|via):/ } @{ tooltip($own) } ), 'and nothing of an upstream in its tooltip' );

  my $both = comb( $xpc, 'both' );
  ok( classes($both)->{borrowed}, 'class and context: borrowed' );
  is( line( $both, 'upstream' ), 'from dev', 'the line in the cell names the context only' );
  is_deeply( tooltip($both),
    [ 'both', 'phase: Running', 'upstream: Kubernetes::Comb::Upstream::K8s, context dev', 'via: dev, prod' ],
    'tooltip: class and context, then via' );

  my $class = comb( $xpc, 'class-only' );
  ok( classes($class)->{borrowed}, 'Pending with an upstream: borrowed' );
  is( line( $class, 'upstream' ), 'borrowed', 'no context: the line says borrowed' );
  is_deeply( tooltip($class), [ 'class-only', 'phase: Pending', 'upstream: Kubernetes::Comb::Upstream::K8s' ],
    'tooltip: class only, no via line' );

  # A recorded upstream the Comb does not borrow from: no marking, but the
  # tooltip still names it.
  my %not = (
    'needs-config' => [ 'needs-config', 'phase: NeedsConfig',
      'upstream: Kubernetes::Comb::Upstream::K8s, context dev (not borrowing)', 'via: dev' ],
    'unreachable'  => [ 'unreachable', 'phase: Pending', 'upstream: context dev (not borrowing)' ],
    'switched-off' => [ 'switched-off', 'phase: Disabled', 'upstream: recorded (not borrowing)' ]
  );
  for my $name ( sort keys %not ) {
    my $cell = comb( $xpc, $name );
    ok( !classes($cell)->{borrowed}, $name.': no borrowed class' );
    is( count( $cell, 's:text[ '.has_class('upstream').' ]' ), 0, $name.': no upstream line' );
    is_deeply( tooltip($cell), $not{$name}, $name.': the tooltip names the upstream and says it is not borrowing' );
  }
  is_deeply( [ sort map { $_->getAttribute('data-name') } grep { classes($_)->{borrowed} } combs($xpc) ],
    [qw( both class-only no-context with-context )], 'the borrowed class on exactly the borrowing cells' );
};

subtest 'tooltip lines' => sub {
  my $xpc = picture('tooltip');
  is_deeply(
    tooltip( comb( $xpc, 'api' ) ),
    [
      'lab/api', 'namespace: lab', 'class: My::Api', 'phase: Blocked',
      'message: waiting for db', 'endpoint: http 8080', 'endpoint: admin',
      'upstream: context prod (not borrowing)', 'via: prod, edge', 'missing: gone'
    ],
    'id, namespace, class, phase, message, endpoints, upstream, via, missing'
  );
  is_deeply( tooltip( comb( $xpc, 'db' ) ), [ 'lab/db', 'namespace: lab', 'phase: Unknown' ], 'a bare cell' );
};

subtest 'groups' => sub {
  my $xpc = picture( 'groups', group_label => 'tier' );
  my @groups = $xpc->findnodes( '//s:g[ '.has_class('group').' ]' );
  is( scalar @groups, 3, 'two named groups and the unnamed one' );
  is_deeply(
    [ map { $_->hasAttribute('data-group') ? $_->getAttribute('data-group') : undef } @groups ],
    [ 'backend', 'frontend', undef ],
    'name order, the unnamed group last, without data-group'
  );
  is( val( $groups[0], q{s:text[@class="group-name"]} ), 'backend', 'heading text' );
  is( val( $groups[1], q{s:text[@class="group-name"]} ), 'frontend', 'heading text' );
  is( count( $groups[0], 's:line[@class="group-rule"]' ), 1, 'named group has a rule' );
  is( count( $groups[2], 's:text' ), 0, 'unnamed group has no text' );

  my %y = map { $_->getAttribute('data-name') => ( centre($_) )[1] } combs($xpc);
  is_deeply( [ sort keys %y ], [qw( alpha beta loose zeta )], 'every cell drawn once' );
  cmp_ok( $y{beta}, '<', $y{alpha}, 'backend above frontend' );
  cmp_ok( $y{alpha}, '<', $y{loose}, 'unnamed group below the named ones' );
  is( $y{beta}, $y{zeta}, 'cells of one group and depth share a row' );

  my $plain = picture( 'groups' );
  is( count( $plain, '//s:g[ '.has_class('group').' ]' ), 0, 'without group_label there is no heading' );
  is( count( $plain, '//s:'.$COMB ), 4, 'all cells still drawn' );
};

subtest 'depth rows' => sub {
  my $xpc = picture('chain');
  my %y = map { $_->getAttribute('data-name') => ( centre($_) )[1] } combs($xpc);
  cmp_ok( $y{db}, '<', $y{api}, 'the dependency is above its dependent' );
  cmp_ok( $y{api}, '<', $y{web}, 'one row per depth' );
};

subtest 'wrap at columns' => sub {
  my $xpc = picture( 'wrap', columns => 2 );
  my %row;
  $row{ ( centre($_) )[1] }++ for combs($xpc);
  is_deeply( [ map { $row{$_} } sort { $a <=> $b } keys %row ], [ 2, 2, 1 ], 'five cells at columns 2: 2, 2, 1' );
  my %default;
  $default{ ( centre($_) )[1] }++ for combs( picture('wrap') );
  is_deeply( [ values %default ], [5], 'default columns keep five cells in one row' );
};

subtest 'cycle' => sub {
  my $xpc;
  is( eval { $xpc = picture('cycle'); 1 }, 1, 'a cycle and a self-dependency render' ) or diag $@;
  is( count( $xpc, '//s:'.$COMB ), 3, 'three cells' );
  my ( $ya, $yb ) = map { ( centre( comb( $xpc, $_ ) ) )[1] } qw( a b );
  is( $ya, $yb, 'the cells of a cycle share a row' );
  my %edge = map { $_->getAttribute('data-from').'>'.$_->getAttribute('data-to') => 1 }
    $xpc->findnodes('//s:path[@class="dep"]');
  ok( $edge{'a>b'} && $edge{'b>a'}, 'both edges of the cycle are drawn' );
};

subtest 'cycle edges bow to opposite sides' => sub {
  my $xpc = picture( [
    { metadata => { name => 'a' }, spec => { dependsOn => ['c'] } },
    { metadata => { name => 'b' } },
    { metadata => { name => 'c' }, spec => { dependsOn => ['a'] } }
  ] );
  my $row = ( centre( comb( $xpc, 'a' ) ) )[1];
  my %bow;
  for my $path ( $xpc->findnodes('//s:path[@class="dep"]') ) {
    my ( $start, $via, $end ) = $path->getAttribute('d') =~ /\AM\S+ (\S+)Q\S+ (\S+) \S+ (\S+)\z/;
    $bow{ $path->getAttribute('data-from') } = [ map { $_ - $row } $start, $via, $end ];
  }
  is_deeply( [ sort keys %bow ], [ 'a', 'c' ], 'both edges of a cycle are bows' );
  is( scalar( grep { $_ < -$SIZE * 0.4 } @{ $bow{a} } ), 3, 'left to right bows above the labels' );
  is( scalar( grep { $_ > $SIZE * 0.4 } @{ $bow{c} } ), 3, 'right to left bows below the labels' );
};

subtest 'unknown dependency' => sub {
  my $xpc = picture('unknown-dep');
  is( count( $xpc, '//s:'.$COMB ), 1, 'a picture' );
  is( count( $xpc, '//s:path[@class="dep"]' ), 0, 'no edge to a name that is not there' );
  is( count( $xpc, '//s:g[@class="deps"]' ), 0, 'and no empty g.deps' );
  ok( ( grep { $_ eq 'missing: ghost' } @{ tooltip( comb( $xpc, 'api' ) ) } ), 'listed as missing in the tooltip' );
};

subtest 'identity is namespace/name' => sub {
  my $xpc = picture('same-name');
  is( count( $xpc, '//s:'.$COMB ), 3, 'same name in two namespaces: two cells' );
  is_deeply(
    [ sort map { $_->getAttribute('data-id') } combs($xpc) ],
    [ 'dev/api', 'dev/db', 'prod/db' ],
    'data-id is namespace/name'
  );
  is( count( $xpc, '//s:'.$COMB.'[@data-name="db"]' ), 2, 'data-name is the plain name' );
  my @edges = $xpc->findnodes('//s:path[@class="dep"]');
  is( scalar @edges, 1, 'one edge' );
  is( $edges[0]->getAttribute('data-from'), 'dev/api', 'from the dependent' );
  is( $edges[0]->getAttribute('data-to'), 'dev/db', 'to the dependency in its own namespace' );
};

subtest 'edges' => sub {
  my $xpc = picture('chain');
  my @edges = $xpc->findnodes('//s:g[@class="deps"]/s:path[@class="dep"]');
  is_deeply(
    [ sort map { $_->getAttribute('data-from').'>'.$_->getAttribute('data-to') } @edges ],
    [ 'api>db', 'web>api' ],
    'from is the dependent, to the dependency'
  );
  is( $_->getAttribute('marker-end'), 'url(#comb-arrow)', 'arrowhead at the dependency' ) for $edges[0];
  like( $_->getAttribute('d'), qr/\AM/, 'path data' ) for $edges[0];
  for my $name ( 'chain', 'cycle' ) {
    my $pic = picture($name);
    my $n   = count( $pic, '//s:path[@class="dep"]' );
    is(
      count( $pic, '//s:g[@class="deps"]/s:path[@class="dep"]/following-sibling::*[1][self::s:circle][@class="dep-start"]' ),
      $n, $name.': every edge is followed by its start dot'
    );
    is( count( $pic, '//s:circle[@class="dep-start"]' ), $n, $name.': and there is no other start dot' );
  }
  is( count( $xpc, '//s:g[@class="deps"]/following-sibling::s:'.$COMB ), 3, 'edges come before the cells' );
  is( count( $xpc, '//s:'.$COMB.'/preceding-sibling::s:g[@class="deps"]' ), 1, "all of them in one g.deps" );

  my $off = picture( 'chain', edges => 0 );
  is( count( $off, '//s:path[@class="dep"]' ), 0, 'edges => 0: no path.dep' );
  is( count( $off, '//s:g[@class="deps"]' ), 0, 'edges => 0: no g.deps' );
  is( count( $off, '//s:'.$COMB ), 3, 'edges => 0: cells still drawn' );

  is( count( picture('phases'), '//s:g[@class="deps"]' ), 0, 'no dependencies: no g.deps' );
};

subtest 'legend' => sub {
  my $xpc = picture('phases');
  my @items = $xpc->findnodes('//s:g[@class="legend"]/s:g[ '.has_class('legend-item').' ]');
  is( scalar @items, 8, 'one item per phase that occurs' );
  is_deeply(
    [ map { $_->getAttribute('data-phase') } @items ],
    [qw( Running Pending Blocked NeedsConfig Disabled Error Stopped NotDeployed )],
    'fixed phase order'
  );
  ok( classes( $items[0] )->{'phase-Running'}, 'item carries the phase class' );
  is( $items[0]->getAttribute('data-count'), 1, 'data-count' );
  is( count( $items[0], 's:polygon[ '.has_class('hex').' ]' ), 1, 'legend swatch is a hexagon' );
  like( $items[0]->textContent, qr/Running\s+1/, 'item text: phase and count' );
  is( count( $xpc, '//s:'.$COMB ), 8, 'swatches are not cells' );
  for my $n ( 6, 7 ) {
    my $phase = ( 'Stopped', 'NotDeployed' )[ $n - 6 ];
    ok( classes( $items[$n] )->{ 'phase-'.$phase }, $phase.': legend item carries the phase class' );
    is( $items[$n]->getAttribute('data-count'), 1, $phase.': data-count' );
    like( $items[$n]->textContent, qr/\A\s*$phase\s+1\s*\z/, $phase.': item text, phase and count' );
  }

  my $some = picture( [
    ( map { { metadata => { name => 'r'.$_ }, status => { phase => 'Running' } } } 1 .. 3 ),
    { metadata => { name => 'x' }, status => { phase => 'Error' } },
    { metadata => { name => 'u' } }
  ] );
  my %count = map { $_->getAttribute('data-phase') => $_->getAttribute('data-count') }
    $some->findnodes('//s:g[ '.has_class('legend-item').' ]');
  is_deeply( \%count, { Running => 3, Error => 1, Unknown => 1 }, 'only phases that occur, with counts' );

  my $rest = picture( [
    ( map { { metadata => { name => 's'.$_ }, status => { phase => 'Stopped' } } } 1 .. 2 ),
    ( map { { metadata => { name => 'd'.$_ }, status => { phase => 'NotDeployed' } } } 1 .. 3 ),
    { metadata => { name => 'odd' }, status => { phase => 'Hibernating' } }
  ] );
  is_deeply(
    [ map { $_->getAttribute('data-phase').'='.$_->getAttribute('data-count') }
        $rest->findnodes('//s:g[ '.has_class('legend-item').' ]') ],
    [ 'Stopped=2', 'NotDeployed=3', 'Unknown=1' ],
    'Stopped and NotDeployed have their own entries with counts; another string is Unknown'
  );

  is( count( picture( 'phases', legend => 0 ), '//s:g[@class="legend"]' ), 0, 'legend => 0: no legend' );
  is( count( picture( [] ), '//s:g[@class="legend"]' ), 0, 'no cells: no legend' );
};

# The rows of text.name as they are drawn: the <tspan>s of a wrapped name,
# else the one text.
# What a name line reaches above its baseline: about three quarters of the
# name font, 0.22 of the size.
my $ASCENT = $SIZE * 0.22 * 0.75;

sub name_rows {
  my ( $node ) = @_;
  my @spans = child( $node, 's:text[ '.has_class('name').' ]/s:tspan' );
  return [ map { $_->textContent } @spans ? @spans : child( $node, 's:text[ '.has_class('name').' ]' ) ];
}

# Baselines of the text lines of a cell, top to bottom.
sub baselines {
  my ( $node ) = @_;
  return map { $_->getAttribute('y') } child( $node, 's:text[@y] | s:text/s:tspan[@y]' );
}

subtest 'long names' => sub {
  my @names = qw(
    db exactly11ch cert-manager gpu-operator nvidia-device-plugin
    averyveryverylongname web-frontend-with-a-long-name a-b-c-d-e-f-g-h -leading trailing-end-
  );
  my $combs = [ map { { metadata => { name => $_ } } } @names ];
  my $xpc   = picture($combs);
  my $rows  = sub { name_rows( comb( $xpc, $_[0] ) ) };
  my $small = sub { classes( ( child( comb( $xpc, $_[0] ), 's:text[ '.has_class('name').' ]' ) )[0] )->{'name-small'} };

  is_deeply( $rows->('db'), ['db'], 'a short name is one line, untouched' );
  is_deeply( $rows->('exactly11ch'), ['exactly11ch'], 'eleven characters still fit on one line' );
  is( count( comb( $xpc, 'db' ), 's:text/*' ), 0, 'one line: no tspan' );

  is_deeply( $rows->('cert-manager'), [ 'cert-', 'manager' ], 'cert-manager on two lines' );
  is_deeply( $rows->('gpu-operator'), [ 'gpu-', 'operator' ], 'gpu-operator on two lines' );
  ok( !$small->('cert-manager'), 'two lines that fit keep the name font' );
  is_deeply( $rows->('nvidia-device-plugin'), [ 'nvidia-', 'device-plugin' ],
    'nvidia-device-plugin: the break with the shorter longest line' );
  ok( $small->('nvidia-device-plugin'), 'thirteen characters a line: the small font' );
  is( line( comb( $xpc, $_ ), 'name' ), $_, $_.': the whole name is readable' )
    for qw( cert-manager gpu-operator nvidia-device-plugin );
  is_deeply( $rows->('a-b-c-d-e-f-g-h'), [ 'a-b-c-d-', 'e-f-g-h' ], 'of two equal breaks the earlier' );
  is_deeply( $rows->('-leading'), ['-leading'], 'a name that fits is not broken' );
  is_deeply( $rows->('trailing-end-'), [ 'trailing-', 'end-' ], 'no break after the last character' );

  is_deeply( $rows->('averyveryverylongname'), ["averyveryv\x{2026}"],
    'no break point: one line, cut with an ellipsis' );
  ok( !$small->('averyveryverylongname'), 'and in the name font' );
  is_deeply( $rows->('web-frontend-with-a-long-name'), [ 'web-frontend-', "with-a-long-\x{2026}" ],
    'too long for two small lines: the line that overflows is cut' );
  ok( $small->('web-frontend-with-a-long-name'), 'in the small font' );

  my $node = comb( $xpc, 'web-frontend-with-a-long-name' );
  is( $node->getAttribute('data-name'), 'web-frontend-with-a-long-name', 'data-name keeps the whole name' );
  is( tooltip($node)->[0], 'web-frontend-with-a-long-name', 'the tooltip keeps the whole name' );

  for my $name (@names) {
    my $cell = comb( $xpc, $name );
    is( count( $cell, 's:text[ '.has_class('name').' ]' ), 1, $name.': one text.name' );
    is( count( $cell, 's:text/*[not(self::s:tspan)]' ), 0, $name.': nothing but tspan inside a text' );
    my ( $x, $y ) = centre($cell);
    my @at = baselines($cell);
    is( scalar @at, @{ $rows->($name) } + 1, $name.': a baseline per line' );
    is_deeply( \@at, [ sort { $a <=> $b } @at ], $name.': lines top to bottom' );
    cmp_ok( $at[0] - $ASCENT, '>=', $y - $SIZE / 2, $name.': first line inside the full-width band' );
    cmp_ok( $at[-1], '<=', $y + $SIZE / 2, $name.': last line inside the full-width band' );
    cmp_ok( $at[$_] - $at[ $_ - 1 ], '>=', $SIZE * 0.2, $name.': lines do not overlap' ) for 1 .. $#at;
    is( $_->getAttribute('x') + 0, $x + 0, $name.': line centred on the cell' )
      for child( $cell, 's:text[@x] | s:text/s:tspan' );
  }

  like( style_text($xpc), qr/\.name-small\{font-size:[0-9.]+px\}/, 'the small font has its rule' );
  unlike( style_text( picture( [ map { { metadata => { name => $_ } } } qw( db cert-manager ) ] ) ),
    qr/name-small/, 'and only when a cell needs it' );

  my $render = sub { $SVG->new( combs => $combs, @_ )->render };
  is( $render->(), $render->(), 'wrapped names: same bytes' );
  is_deeply( name_rows( comb( picture( $combs, size => 20 ), 'nvidia-device-plugin' ) ),
    [ 'nvidia-', 'device-plugin' ], 'the break does not depend on size' );
};

subtest 'long names: borrowed and hostile' => sub {
  my $upstream = { status => { phase => 'Running', upstream => { context => 'prod' } } };
  my $xpc = picture( [
    { metadata => { name => 'gpu-operator' }, %$upstream },
    { metadata => { name => 'nvidia-device-plugin' }, %$upstream }
  ] );
  for my $name (qw( gpu-operator nvidia-device-plugin )) {
    my $cell = comb( $xpc, $name );
    ok( classes($cell)->{borrowed}, $name.': borrowed' );
    is( line( $cell, 'name' ), $name, $name.': the whole name on two lines' );
    is( scalar @{ name_rows($cell) }, 2, $name.': two rows' );
    is( line( $cell, 'upstream' ), 'from prod', $name.': upstream line' );
    my ( undef, $y ) = centre($cell);
    my @at = baselines($cell);
    is( scalar @at, 4, $name.': name, name, phase, upstream' );
    cmp_ok( $at[0] - $ASCENT, '>=', $y - $SIZE / 2, $name.': first line inside the full-width band' );
    cmp_ok( $at[-1], '<=', $y + $SIZE / 2, $name.': upstream baseline inside the full-width band' );
    cmp_ok( $at[$_] - $at[ $_ - 1 ], '>=', $SIZE * 0.2, $name.': lines do not overlap' ) for 1 .. $#at;
  }

  # A break point inside hostile and non-ASCII names: each row is escaped.
  my @evil = ( '</svg>-<script>alert(1)</script>', "<b>&\"'-caf\x{e9}_\x{1F600}.\x{4e2d}\x{6587}" );
  my $svg  = $SVG->new( combs => [ map { { metadata => { name => $_ } } } @evil ] )->render;
  my $safe;
  is( eval { $safe = parse($svg); 1 }, 1, 'well-formed XML' ) or diag $@;
  unlike( $svg, qr/<script/i, 'no literal script tag in the bytes' );
  unlike( $svg, qr/[^\x00-\x7F]/, 'plain ASCII output' );
  is( count( $safe, '//*[local-name()="script" or local-name()="b"]' ), 0, 'no element from a name' );
  is_deeply( name_rows( comb( $safe, $evil[0] ) ), [ '</svg>-', "<script>aler\x{2026}" ], 'hostile name: rows are text' );
  is_deeply( name_rows( comb( $safe, $evil[1] ) ), [ "<b>&\"'-", "caf\x{e9}_\x{1F600}.\x{4e2d}\x{6587}" ],
    'non-ASCII name: broken by characters, whole' );
};

#### The reason line

# The text lines of a cell as they are drawn, top to bottom: class, text,
# baseline as an offset from the centre, font size. The fonts are those of
# the style: shares of the size.
my %FONT = ( name => 0.22, 'name-small' => 0.185, phase => 0.17, reason => 0.15, upstream => 0.15 );

sub cell_lines {
  my ( $node, $size ) = @_;
  $size ||= $SIZE;
  my ( undef, $cy ) = centre( $node, $size );
  my @lines;
  for my $text ( child( $node, 's:text' ) ) {
    my $class = classes($text);
    my ( $kind ) = grep { $class->{$_} } qw( name-small name phase reason upstream );
    my @spans = child( $text, 's:tspan' );
    push @lines, map { {
      class => $kind eq 'name-small' ? 'name' : $kind,
      text  => $_->textContent,
      at    => $_->getAttribute('y') - $cy,
      font  => $FONT{$kind} * $size
    } } @spans ? @spans : $text;
  }
  return @lines;
}

# Half the width of a pointy-top hexagon at a distance from its centre line.
sub hex_half {
  my ( $distance, $size ) = @_;
  $distance = abs $distance;
  return $distance <= $size / 2 ? $size * sqrt(3) / 2 : sqrt(3) * ( $size - $distance );
}

# Every line of a cell is inside the outline, at the width its text is
# estimated to have (0.59 of the font a character), and no line reaches into
# the next: a line is taken to span from three quarters of its font above the
# baseline to a quarter below.
sub lines_fit {
  my ( $node, $size, $label ) = @_;
  my @lines = cell_lines( $node, $size );
  my $ok = 1;
  for my $i ( 0 .. $#lines ) {
    my $line = $lines[$i];
    my ( $top, $bottom ) = ( $line->{at} - 0.75 * $line->{font}, $line->{at} + 0.25 * $line->{font} );
    my $half = length( $line->{text} ) * $line->{font} * 0.59 / 2;
    my ( $room ) = sort { $a <=> $b } hex_half( $top, $size ), hex_half( $bottom, $size );
    $ok = 0, diag( $label.': '.$line->{class}.' line pokes out: '.$half.' > '.$room ) if $half > $room + 0.02;
    next unless $i;
    my $above = $lines[ $i - 1 ];
    $ok = 0, diag( $label.': '.$line->{class}.' line overlaps the '.$above->{class}.' line' )
      if $top < $above->{at} + 0.25 * $above->{font} - 0.02;
  }
  ok( $ok, $label.': every line inside the outline, none overlapping' );
}

sub reason_cr {
  my ( $name, $phase, $reason, $context ) = @_;
  return {
    metadata => { name => $name },
    status   => {
      phase => $phase,
      defined $reason  ? ( conditions => [ { type => 'Ready', status => 'False', reason => $reason } ] ) : (),
      defined $context ? ( upstream => { context => $context } ) : ()
    }
  };
}

# The rows of the reason of a cell: the tspans of its text.reason, else the
# one text.
sub reason_rows {
  my ( $node ) = @_;
  my @spans = child( $node, 's:text[ '.has_class('reason').' ]/s:tspan' );
  return [ map { $_->textContent } @spans ? @spans : child( $node, 's:text[ '.has_class('reason').' ]' ) ];
}

subtest 'reason line' => sub {
  my $xpc = picture( [
    reason_cr( 'ok',       'Running', 'DeployFailed' ),
    reason_cr( 'failed',   'Error',   'DeployFailed' ),
    reason_cr( 'sixteen',  'Error',   'ExactlySixteenCh' ),
    reason_cr( 'config',   'NeedsConfig', 'MissingPrerequisites' ),
    reason_cr( 'stopped',  'Stopped', 'Stopped' ),
    reason_cr( 'silent',   'Pending' ),
    reason_cr( 'lent',     'Running', undef, 'prod' ),
    reason_cr( 'waiting',  'Pending', 'Deployed', 'prod' ),
    reason_cr( 'starting', 'Starting', 'ImagePull' ),
    { metadata => { name => 'off' }, spec => { enabled => 0 }, status => {
      conditions => [ { type => 'Ready', status => 'False', reason => 'Disabled', message => 'disabled by spec.enabled' } ]
    } }
  ] );
  my $has = sub { count( comb( $xpc, $_[0] ), 's:text[ '.has_class('reason').' ]' ) };

  is( $has->('ok'), 0, 'Running: no reason line, whatever its conditions say' );
  is( $has->('lent'), 0, 'Running and borrowed: none' );
  is( $has->('silent'), 0, 'not Running without a reason: none' );
  is( $has->('stopped'), 0, 'a reason that only repeats the phase: none' );
  is( $has->('failed'), 1, 'not Running with a reason: one text.reason' );
  is( line( comb( $xpc, 'failed' ), 'reason' ), 'DeployFailed', 'the reason as text' );
  is( line( comb( $xpc, 'sixteen' ), 'reason' ), 'ExactlySixteenCh', 'sixteen characters fit' );
  is_deeply( reason_rows( comb( $xpc, 'config' ) ), [ 'Missing', 'Prerequisites' ], 'a longer reason is broken into two lines, whole' );
  is( line( comb( $xpc, 'starting' ), 'reason' ), 'ImagePull', 'an Unknown cell says why too' );
  is_deeply( reason_rows( comb( $xpc, 'off' ) ), [ 'disabled by', 'spec.enabled' ], 'Disabled: the message stands in, on two lines' );
  ok( classes( comb( $xpc, 'off' ) )->{disabled}, 'in a cell that is muted as a whole' );
  ok( !( grep { /reason|DeployFailed|Deployed/ } @{ tooltip( comb( $xpc, 'failed' ) ) } ),
    'the tooltip does not gain the reason' );

  is_deeply( [ map { $_->{class} } cell_lines( comb( $xpc, 'waiting' ) ) ],
    [qw( name phase reason upstream )], 'order: name, phase, reason, upstream' );
  is_deeply( [ map { $_->{text} } cell_lines( comb( $xpc, 'waiting' ) ) ],
    [ 'waiting', 'Pending', 'Deployed', 'from prod' ], 'and their texts' );
  is_deeply( [ map { $_->{class} } cell_lines( comb( $xpc, 'failed' ) ) ],
    [qw( name phase reason )], 'order without upstream' );
  for my $name (qw( failed waiting off )) {
    my $cell = comb( $xpc, $name );
    my ( $x ) = centre($cell);
    is( $_->getAttribute('x') + 0, $x + 0, $name.': line centred on the cell' )
      for child( $cell, 's:text[@x] | s:text/s:tspan' );
    is( count( $cell, 's:text/*' ), $name eq 'off' ? 2 : 0, $name.': an element inside a text only for a second reason line' );
  }

  # Cells without a reason line sit where they always sat: name and phase
  # centred, a borrowed cell as before.
  my $at = sub { [ map { sprintf '%.2f', $_->{at} } cell_lines( comb( $xpc, $_[0] ) ) ] };
  is_deeply( $at->('ok'), [ map { sprintf '%.2f', $_ * $SIZE } -0.07, 0.23 ], 'name and phase where they were' );
  is_deeply( $at->($_), $at->('ok'), $_.': no reason line, same baselines' ) for qw( silent stopped );
  is_deeply( $at->('lent'), [ map { sprintf '%.2f', $_ * $SIZE } -0.17, 0.13, 0.38 ], 'borrowed: where it was' );
  is_deeply( $at->('failed'), $at->('lent'), 'a reason line sits where the upstream line of a borrowed cell sits' );

  my $style = style_text($xpc);
  like( $style, qr/^\.comb-svg \.reason\{font-size:8\.4px;fill:var\(--comb-muted\)\}$/m,
    'the reason line has its rule: small, muted, not italic' );
  like( $style, qr/\.reason\{.*\.disabled text\{/s, 'the muting of a Disabled cell comes after it' );
  my ( $upstream ) = $style =~ /\.upstream\{font-size:([0-9.]+)px/;
  is( $upstream, '8.4', 'the font of the upstream line' );
};

subtest 'reason line: inside the hexagon' => sub {
  my @names   = qw( db gpu-operator nvidia-device-plugin web-frontend-with-a-long-name averyveryverylongname );
  my @reasons = ( 'Deployed', 'MissingPrerequisites', 'UpstreamEndpointsMissing',
    'deploy failed: timeout while waiting for rollout', 'W' x 40 );
  my ( @combs, $n );
  for my $name (@names) {
    for my $reason (@reasons) {
      for my $context ( undef, 'prod', 'a-rather-long-context-name' ) {
        my $cr = reason_cr( $name, 'Pending', $reason, $context );
        $cr->{metadata}{namespace} = 'n'.++$n;
        push @combs, $cr;
      }
    }
  }
  for my $size ( 20, $SIZE, 90 ) {
    my $xpc = picture( \@combs, size => $size );
    my ( %lines, %shape );
    for my $cell ( combs($xpc) ) {
      my @lines = cell_lines( $cell, $size );
      my $id    = $cell->getAttribute('data-id');
      lines_fit( $cell, $size, 'size '.$size.' '.$id );
      my @reason = grep { $_->{class} eq 'reason' } @lines;
      $lines{ scalar @lines }++;
      $shape{ join ' ', map { $_->{class} } @lines }++;
      cmp_ok( $reason[0]{at} + 0.25 * $reason[0]{font}, '<=', $size / 2 + 0.02,
        'size '.$size.' '.$id.': the first reason line is inside the full-width band' );
      cmp_ok( length $_->{text}, '<=', 16, 'size '.$size.' '.$id.': sixteen characters at most' ) for @reason;
      cmp_ok( $lines[0]{at} - 0.75 * $lines[0]{font}, '>=', -0.55 * $size - 0.02, 'size '.$size.' '.$id.': the block starts inside' );
      cmp_ok( $lines[-1]{at} + 0.25 * $lines[-1]{font}, '<=', 0.55 * $size + 0.02, 'size '.$size.' '.$id.': the block ends inside' );
    }
    is_deeply( [ sort keys %lines ], [ 3, 4, 5 ], 'size '.$size.': cells of three, four and five lines, never six' );
    is_deeply( [ sort keys %shape ], [
      'name name phase reason', 'name name phase reason reason', 'name name phase reason upstream',
      'name phase reason', 'name phase reason reason', 'name phase reason reason upstream', 'name phase reason upstream'
    ], 'size '.$size.': every line-count case, and no second reason line between a name on two lines and an upstream line' );
  }

  # The worst case by name: a wrapped name, phase, reason and upstream line.
  my $xpc  = picture( \@combs );
  my ( $worst ) = grep { $_->getAttribute('data-name') eq 'nvidia-device-plugin'
    && line( $_, 'upstream' ) =~ /\Afrom a-rather/ && line( $_, 'reason' ) =~ /\AW/ } combs($xpc);
  my @lines = cell_lines($worst);
  is_deeply( [ map { $_->{class} } @lines ], [qw( name name phase reason upstream )], 'five lines' );
  is( $lines[3]{text}, ( 'W' x 15 )."\x{2026}", 'the reason cut to sixteen' );
  cmp_ok( $lines[0]{at} - 0.75 * $lines[0]{font}, '>=', -0.55 * $SIZE - 0.02, 'the first name line starts inside' );
  cmp_ok( $lines[-1]{at} + 0.25 * $lines[-1]{font}, '<=', 0.55 * $SIZE + 0.02, 'the upstream line ends inside' );

  # The same cells without a reason are not moved by all this.
  my @plain = map { reason_cr( $_, 'Pending', undef, 'prod' ) } @names;
  my $plain = picture( \@plain );
  for my $name (@names) {
    my @at = map { $_->{at} } cell_lines( comb( $plain, $name ) );
    my $rows = @{ name_rows( comb( $plain, $name ) ) };
    my $step = $rows == 1 ? 0 : $at[1] - $at[0];
    is( sprintf( '%.2f', $at[$rows] - $at[ $rows - 1 ] ), sprintf( '%.2f', 0.3 * $SIZE ),
      $name.' without a reason: phase advance as before' );
    is( sprintf( '%.2f', $at[-1] - $at[-2] ), sprintf( '%.2f', 0.25 * $SIZE ),
      $name.' without a reason: upstream advance as before' );
    is( sprintf( '%.2f', $at[0] ), sprintf( '%.2f', -0.17 * $SIZE - $step / 2 ),
      $name.' without a reason: starts where it did' );
  }
};

subtest 'reason line: two lines before cutting' => sub {
  my $long  = 'deploy failed: timeout while waiting for rollout';
  my $cut   = sub { $_[0]."\x{2026}" };
  my @cells = (
    # [ name, upstream context ], then reason => the rows expected
    [ [ 'db' ], [
      MissingPrerequisites     => [ 'Missing', 'Prerequisites' ],
      UpstreamUnreachable      => [ 'Upstream', 'Unreachable' ],
      UpstreamNotRunning       => [ 'Upstream', 'NotRunning' ],
      DependenciesFailed       => [ 'Dependencies', 'Failed' ],
      UpstreamEndpointsMissing => [ 'Upstream', 'EndpointsMissing' ],
      $long                    => [ 'deploy failed:', $cut->('timeout while w') ],
      'W' x 40                 => [ $cut->( 'W' x 15 ) ],
      DeployFailed             => ['DeployFailed'],
      ExactlySixteenCh         => ['ExactlySixteenCh'],
      ReplicaSet2Unavailable   => [ 'ReplicaSet2', 'Unavailable' ],
      "crash loop \t  back off again" => [ 'crash loop', 'back off again' ],
      ABCDEFGHIJKLMNOPQRSTUVWXYZ      => [ $cut->('ABCDEFGHIJKLMNO') ],
      'Averyveryverylongprefix Tail'  => [ $cut->('Averyveryverylo') ],
      RolloutInProgress               => [ 'RolloutIn', 'Progress' ],
      "d\x{e9}ploiement\x{c9}chou\x{e9}Partout" => [ "d\x{e9}ploiement", "\x{c9}chou\x{e9}Partout" ]
    ] ],
    # Under a name on two lines the second reason line holds 14 characters.
    [ [ 'gpu-operator' ], [
      MissingPrerequisites     => [ 'Missing', 'Prerequisites' ],
      UpstreamUnreachable      => [ 'Upstream', 'Unreachable' ],
      UpstreamNotRunning       => [ 'Upstream', 'NotRunning' ],
      DependenciesFailed       => [ 'Dependencies', 'Failed' ],
      UpstreamEndpointsMissing => [ 'Upstream', $cut->('EndpointsMiss') ],
      $long                    => [ 'deploy failed:', $cut->('timeout while') ],
      'W' x 40                 => [ $cut->( 'W' x 15 ) ],
      DeployFailed             => ['DeployFailed']
    ] ],
    # Under a name in the small font, 15.
    [ [ 'nvidia-device-plugin' ], [
      MissingPrerequisites     => [ 'Missing', 'Prerequisites' ],
      UpstreamEndpointsMissing => [ 'Upstream', $cut->('EndpointsMissi') ],
      'W' x 40                 => [ $cut->( 'W' x 15 ) ],
      DeployFailed             => ['DeployFailed']
    ] ],
    [ [ 'db', 'prod' ], [
      MissingPrerequisites     => [ 'Missing', 'Prerequisites' ],
      UpstreamEndpointsMissing => [ 'Upstream', 'EndpointsMissing' ],
      $long                    => [ 'deploy failed:', $cut->('timeout while w') ],
      'W' x 40                 => [ $cut->( 'W' x 15 ) ],
      DeployFailed             => ['DeployFailed']
    ] ],
    # No room for a sixth line: the reason stays on one, cut.
    [ [ 'gpu-operator', 'prod' ], [
      MissingPrerequisites => [ $cut->('MissingPrerequi') ],
      $long                => [ $cut->('deploy failed: ') ],
      DeployFailed         => ['DeployFailed']
    ] ],
    [ [ 'nvidia-device-plugin', 'prod' ], [
      MissingPrerequisites => [ $cut->('MissingPrerequi') ],
      DeployFailed         => ['DeployFailed']
    ] ]
  );

  my ( @combs, @expect, $n );
  for my $case (@cells) {
    my ( $cell, $reasons ) = @$case;
    my @pairs = @$reasons;
    while ( my ( $reason, $rows ) = splice @pairs, 0, 2 ) {
      my $cr = reason_cr( $cell->[0], $cell->[1] ? 'Pending' : 'Error', $reason, $cell->[1] );
      $cr->{metadata}{namespace} = 'n'.++$n;
      push @combs, $cr;
      my $short = $reason =~ /\A[\x20-\x7E]{1,24}\z/ ? $reason : 'reason '.$n;
      push @expect, {
        id     => 'n'.$n.'/'.$cell->[0],
        rows   => $rows,
        reason => $reason,
        label  => $cell->[0].( $cell->[1] ? ', borrowed' : '' ).', '.$short
      };
    }
  }

  for my $size ( 20, $SIZE, 90 ) {
    my $xpc = picture( \@combs, size => $size );
    for my $expect (@expect) {
      my $cell  = comb_by_id( $xpc, $expect->{id} );
      my $label = 'size '.$size.' '.$expect->{label};
      is_deeply( reason_rows($cell), $expect->{rows}, $label.': the rows of the reason' );
      lines_fit( $cell, $size, $label );
      next unless $size == $SIZE;

      my @lines  = cell_lines($cell);
      my @reason = grep { $_->{class} eq 'reason' } @lines;
      my @names  = grep { $_->{class} eq 'name' } @lines;
      my ( $phase ) = grep { $_->{class} eq 'phase' } @lines;
      is( count( $cell, 's:text[ '.has_class('reason').' ]' ), 1, $label.': one text.reason' );
      cmp_ok( scalar @lines, '<=', 5, $label.': five lines at most' );
      cmp_ok( $lines[0]{at} - 0.75 * $lines[0]{font}, '>=', -0.55 * $SIZE - 0.02, $label.': the block starts inside' );
      cmp_ok( $lines[-1]{at} + 0.25 * $lines[-1]{font}, '<=', 0.55 * $SIZE + 0.02, $label.': the block ends inside' );

      my ( $text ) = child( $cell, 's:text[ '.has_class('reason').' ]' );
      my ( $x )    = centre($cell);
      if ( @reason == 2 ) {
        ok( !$text->hasAttribute('x') && !$text->hasAttribute('y'), $label.': the text itself is not placed' );
        is( count( $text, 's:tspan[@x and @y]' ), 2, $label.': two tspan, each placed' );
        is( count( $text, '*[not(self::s:tspan)] | s:tspan/*' ), 0, $label.': and nothing else' );
        is( $_->getAttribute('x') + 0, $x + 0, $label.': line centred on the cell' ) for child( $text, 's:tspan' );
        is( sprintf( '%.2f', $reason[1]{at} - $reason[0]{at} ), sprintf( '%.2f', 0.17 * $SIZE ),
          $label.': the second line 0.17 of the size below the first' );
        is( line( $cell, 'reason' ), join( '', @{ $expect->{rows} } ), $label.': the text content is what is shown' );
        ( my $whole = $expect->{reason} ) =~ s/\s+//g;
        ( my $shown = line( $cell, 'reason' ) ) =~ s/\s+//g;
        is( $shown, $whole, $label.': and that is the whole reason' ) unless $expect->{rows}[1] =~ /\x{2026}\z/;
      }
      else {
        is( count( $text, '*' ), 0, $label.': one line, no tspan' );
        is( $text->getAttribute('x') + 0, $x + 0, $label.': line centred on the cell' );
      }

      # A cell with a reason and more than three lines: the phase has more
      # air above it than the name lines have between them -- 0.28 of the
      # size, but for two name lines in the name font over a reason and an
      # upstream line, where the band leaves 0.25.
      next unless @lines > 3;
      my $air  = $phase->{at} - $names[-1]{at};
      my $full = @names == 2 && $lines[-1]{class} eq 'upstream' && $names[0]{font} > 0.2 * $SIZE;
      cmp_ok( $air, '>', $names[1]{at} - $names[0]{at} + 0.3, $label.': the phase is further from the name than a name line' )
        if @names > 1;
      is( sprintf( '%.2f', $air ), sprintf( '%.2f', ( $full ? 0.25 : 0.28 ) * $SIZE ),
        $label.': '.( $full ? 0.25 : 0.28 ).' of the size' );
    }
  }

  # A cell that is not tight is where it was: one name line, phase and a
  # reason that fits; the same holds for every cell without a reason line.
  my $at = sub { [ map { sprintf '%.2f', $_->{at} / $SIZE } cell_lines( $_[0] ) ] };
  my $xpc = picture( [
    reason_cr( 'api', 'Error', 'DeployFailed' ),
    reason_cr( 'gpu-operator', 'Running', 'MissingPrerequisites' ),
    reason_cr( 'gpu-scheduler', 'Running', 'MissingPrerequisites', 'prod' ),
    reason_cr( 'web', 'Error', 'MissingPrerequisites' )
  ] );
  is_deeply( $at->( comb( $xpc, 'api' ) ), [qw( -0.17 0.13 0.38 )], 'three lines: where they were' );
  is_deeply( $at->( comb( $xpc, 'gpu-operator' ) ), [qw( -0.19 0.05 0.35 )], 'a wrapped Running name: where it was' );
  is_deeply( $at->( comb( $xpc, 'gpu-scheduler' ) ), [qw( -0.29 -0.05 0.25 0.50 )], 'borrowed as well: where it was' );
  my @web  = map { $_->{at} / $SIZE } cell_lines( comb( $xpc, 'web' ) );
  my @want = ( -0.265, 0.015, 0.215, 0.385 );
  ok( !( grep { abs( $web[$_] - $want[$_] ) > 0.001 } 0 .. 3 ) && @web == 4,
    'a reason on two lines: the block centred as a whole' ) or diag join ' ', @web;

  # Hostile reasons with a break point: each line is escaped on its own.
  my @evil = (
    '<b>&"\'</b> <script>x</script>',
    '</text>okFine<script>alert(1)</script>',
    "&amp;<i>\x{e9}t\x{e9} ]]> <!--\x{1F600}--> &lt;"
  );
  my $combs = [ map { reason_cr( 'evil'.$_, 'Error', $evil[$_] ) } 0 .. $#evil ];
  my $svg   = $SVG->new( combs => $combs )->render;
  my $safe;
  is( eval { $safe = parse($svg); 1 }, 1, 'hostile reasons: well-formed XML' ) or diag $@;
  unlike( $svg, qr/<script|<b>|<i>|<!--/i, 'no literal tag or comment in the bytes' );
  unlike( $svg, qr/[^\x00-\x7F]/, 'plain ASCII output' );
  is( count( $safe, '//*[local-name()="script" or local-name()="b" or local-name()="i"] | //comment()' ), 0,
    'no element and no comment from a reason' );
  is_deeply( reason_rows( comb( $safe, 'evil0' ) ), [ '<b>&"\'</b>', "<script>x</scri\x{2026}" ],
    'broken at the space, both lines text' );
  is_deeply( reason_rows( comb( $safe, 'evil1' ) ), [ '</text>ok', "Fine<script>ale\x{2026}" ],
    'broken before the capital, both lines text' );
  is_deeply( reason_rows( comb( $safe, 'evil2' ) ), [ "&amp;<i>\x{e9}t\x{e9} ]]>", "<!--\x{1F600}--> &lt;" ],
    'entities, non-ASCII and a comment round-trip as text' );
  for my $name (qw( evil0 evil1 evil2 )) {
    my $cell = comb( $safe, $name );
    is( count( $cell, '*[not(self::s:title or self::s:polygon or self::s:text)]' ), 0, $name.': cell has only its own children' );
    is( count( $cell, 's:text/*[not(self::s:tspan)] | s:text/s:tspan/*' ), 0, $name.': texts hold tspan and text only' );
  }

  my @args = ( combs => \@combs, layout => 'packed', blink => ['Error'] );
  is( $SVG->new(@args)->render, $SVG->new(@args)->render, 'wrapped reasons: same bytes' );
  is_deeply( reason_rows( comb( picture( [ reason_cr( 'db', 'Error', 'MissingPrerequisites' ) ], size => 20 ), 'db' ) ),
    [ 'Missing', 'Prerequisites' ], 'the break does not depend on size' );
};

subtest 'reason line: escaped, only when needed, stable' => sub {
  my @evil = ( '</text></svg><script>alert(1)</script>', "<b>&\"' caf\x{e9} \x{1F600}", "ctl\x01\x08x" );
  my $combs = [ map { reason_cr( 'evil'.$_, 'Error', $evil[$_] ) } 0 .. $#evil ];
  my $svg   = $SVG->new( combs => $combs )->render;
  my $safe;
  is( eval { $safe = parse($svg); 1 }, 1, 'well-formed XML' ) or diag $@;
  unlike( $svg, qr/<script|<b>/i, 'no literal tag in the bytes' );
  unlike( $svg, qr/[^\x00-\x7F]/, 'plain ASCII output' );
  unlike( $svg, qr/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/, 'no control character in the document' );
  is( count( $safe, '//*[local-name()="script" or local-name()="b"]' ), 0, 'no element from a reason' );
  is( line( comb( $safe, 'evil0' ), 'reason' ), "</text></svg><s\x{2026}", 'hostile reason: text, cut' );
  is( line( comb( $safe, 'evil1' ), 'reason' ), "<b>&\"' caf\x{e9} \x{1F600}", 'special and non-ASCII characters round-trip' );
  is( line( comb( $safe, 'evil2' ), 'reason' ), 'ctlx', 'control characters dropped' );
  is( count( comb( $safe, 'evil0' ), '*[not(self::s:title or self::s:polygon or self::s:text)]' ), 0,
    'cell has only its own children' );

  my $hostile = picture('hostile');
  my $cell    = comb( $hostile, '</svg><script>alert(1)</script>' );
  is_deeply( reason_rows($cell), [ 'msg "quoted" &', "<b>bold</b> 'x'" ],
    'hostile fixture: the message stands in, as text, broken at a space' );
  is_deeply( [ map { $_->{class} } cell_lines($cell) ], [qw( name phase reason reason upstream )], 'above its upstream line' );

  # A picture without a reason line carries nothing of this card.
  my $running = [
    reason_cr( 'db', 'Running', 'DeployFailed' ),
    reason_cr( 'nvidia-device-plugin', 'Running', 'Deployed', 'prod' ),
    reason_cr( 'gone', 'Stopped', 'Stopped' ),
    reason_cr( 'idle', 'NotDeployed', 'NotChecked' )
  ];
  my $bare = [ map { reason_cr( $_->{metadata}{name}, $_->{status}{phase}, undef,
    $_->{status}{upstream} ? 'prod' : undef ) } @$running ];
  my $quiet = $SVG->new( combs => $running )->render;
  unlike( $quiet, qr/reason/, 'no reason line: no rule and no element' );
  is( $quiet, $SVG->new( combs => $bare )->render, 'the same bytes as without any condition' );
  unlike( $SVG->new( combs => fixture($_) )->render, qr/reason/, $_.' fixture: nothing of it' )
    for qw( phases borrowed chain disabled groups );

  my $one = $SVG->new( combs => [ @$running, reason_cr( 'api', 'Error', 'DeployFailed' ) ] )->render;
  is( () = $one =~ /\.reason\{/g, 1, 'one cell with a reason: the rule, once' );
  is( count( parse($one), '//s:text[ '.has_class('reason').' ]' ), 1, 'and one element' );

  my @args = ( combs => $combs, layout => 'packed', blink => ['Error'] );
  is( $SVG->new(@args)->render, $SVG->new(@args)->render, 'reason lines: same bytes' );
};

subtest 'escaping' => sub {
  my $svg = $SVG->new( combs => fixture('hostile'), group_label => 'tier', title => '<b>"T" & \'t\'</b>' )->render;
  my $xpc;
  is( eval { $xpc = parse($svg); 1 }, 1, 'well-formed XML' ) or diag $@;
  is( count( $xpc, '//*[local-name()="script"]' ), 0, 'no script element anywhere' );
  is( count( $xpc, '//@*[starts-with(local-name(),"on")]' ), 0, 'no event handler attribute' );
  unlike( $svg, qr/<script/i, 'no literal script tag in the bytes' );
  unlike( $svg, qr/[^\x00-\x7F]/, 'plain ASCII output' );

  is_deeply(
    [ sort map { $_->getAttribute('data-name') } combs($xpc) ],
    [ sort 'ctlx', 'q"uo\'te&amp;<>', '</svg><script>alert(1)</script>' ],
    'data-name round-trips the original string (control characters dropped)'
  );
  my $evil = comb( $xpc, '</svg><script>alert(1)</script>' );
  is( $evil->getAttribute('data-id'), 'ns"\'&<>/</svg><script>alert(1)</script>', 'data-id round-trips' );
  my $tip = tooltip($evil);
  ok( ( grep { $_ eq 'namespace: ns"\'&<>' } @$tip ), 'namespace in the tooltip, verbatim' );
  ok( ( grep { $_ eq 'message: msg "quoted" & <b>bold</b> \'x\'' } @$tip ), 'message in the tooltip, verbatim' );
  ok( ( grep { $_ eq 'upstream: Evil::</title><script>c</script>&"\', context ctx"><script>x</script>&' } @$tip ),
    'upstream class and context in the tooltip, verbatim' );
  is( count( $evil, 's:title/*' ), 0, 'no element inside the tooltip' );
  my $blocked = fixture('hostile');
  $blocked->[0]{status}{phase} = 'Blocked';
  my $idle = comb( picture($blocked), '</svg><script>alert(1)</script>' );
  ok( ( grep { $_ eq 'upstream: Evil::</title><script>c</script>&"\', context ctx"><script>x</script>& (not borrowing)' }
    @{ tooltip($idle) } ), 'the same of a cell that is not borrowing' );
  ok( !classes($idle)->{borrowed} && !count( $idle, 's:text[ '.has_class('upstream').' ]' ),
    'which has neither the class nor the line' );
  is( count( $idle, '*[not(self::s:title or self::s:polygon or self::s:text)]' ), 0, 'and only its own children' );
  is( count( $evil, '*[not(self::s:title or self::s:polygon or self::s:text)]' ), 0, 'cell has only its own children' );
  is( count( $evil, 's:text/*[not(self::s:tspan)]' ), 0, 'no element but a tspan inside any text' );
  is( count( $evil, 's:text/s:tspan' ), 2, 'and of those the two lines of its reason' );
  is( count( $evil, 's:text/s:tspan/*' ), 0, 'with nothing but text inside' );
  like( line( $evil, 'upstream' ), qr/\Afrom ctx">/, 'upstream line is text' );

  my @heads = $xpc->findnodes('//s:g[ '.has_class('group').' ]');
  is( $heads[0]->getAttribute('data-group'), 'grp"\'&<script>', 'data-group round-trips' );
  is( val( $heads[0], "s:text" ), 'grp"\'&<script>', 'group heading text round-trips' );

  my $odd = comb( $xpc, 'q"uo\'te&amp;<>' );
  ok( ( grep { $_ eq 'phase: Unknown (Run"ning<script>)' } @{ tooltip($odd) } ), 'raw phase escaped in the tooltip' );
  is( line( $odd, 'phase' ), 'Unknown', 'phase text is the known name' );

  my $title = '<b>"T" & \'t\'</b>';
  is( $xpc->findvalue('/s:svg/s:title'), $title, 'title option round-trips in <title>' );
  is( $xpc->findvalue('/s:svg/s:text[@class="heading"]'), $title, 'and in the heading' );

  my $ctl = comb( $xpc, 'ctlx' );
  ok( $ctl, 'control characters are dropped, the cell is drawn' );
  unlike( $svg, qr/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/, 'no control character in the document' );
};

subtest 'unicode' => sub {
  my $name = "caf\x{e9}-\x{1F600}-\x{4e2d}";
  my $svg  = $SVG->new( combs => [ { metadata => { name => $name } } ] )->render;
  unlike( $svg, qr/[^\x00-\x7F]/, 'ASCII bytes, no encoding question' );
  is( ( combs( parse($svg) ) )[0]->getAttribute('data-name'), $name, 'data-name round-trips' );
};

subtest 'link' => sub {
  my $one = sub {
    my ( $href ) = @_;
    my $xpc = picture( [ { metadata => { name => 'a' } } ], link => sub { $href } );
    return $xpc;
  };
  for my $href ( 'cells/a.html', '/cells/a', '#a', '?x=1', 'a/b:c', 'http://h/p', 'https://h/p?a=1&b=2',
    'HTTPS://h/', '//h/x' ) {
    my $xpc = $one->($href);
    my @a = $xpc->findnodes('//s:a');
    is( scalar @a, 1, 'accepted: '.$href );
    is( $a[0]->getAttribute('href'), $href, '  href round-trips' ) if @a;
    is( count( $xpc, '//s:a/s:'.$COMB ), 1, '  the anchor wraps the cell' );
  }
  for my $href (
    'javascript:alert(1)', 'JavaScript:alert(1)', 'jAvAsCrIpT:alert(1)', 'data:text/html,x', 'vbscript:x',
    'mailto:a@b', 'ftp://h/x', ' https://h/', "\thttps://h/", "https://h/ x", "java\tscript:alert(1)",
    "java\nscript:alert(1)", "https://h/\x00", ''
  ) {
    my $shown = $href; $shown =~ s/([^\x20-\x7e])/sprintf '\x%02x', ord $1/ge;
    my $xpc = $one->($href);
    is( count( $xpc, '//s:a' ), 0, 'refused: "'.$shown.'"' );
    is( count( $xpc, '//s:'.$COMB ), 1, '  cell still drawn' );
  }
  is( count( $one->(undef), '//s:a' ), 0, 'undef: no anchor' );
  is( count( picture('link'), '//s:a' ), 0, 'no link option: no anchor' );

  my $xpc = picture( [ { metadata => { name => 'a' } } ], link => sub { 'x"onload="y&z<>' } );
  my ( $a ) = $xpc->findnodes('//s:a');
  is( $a->getAttribute('href'), 'x"onload="y&z<>', 'href is escaped as an attribute' );
  is( count( $xpc, '//@*[local-name()="onload"]' ), 0, 'no injected attribute' );

  my @seen;
  picture( 'link', link => sub { push @seen, $_[0]; undef } );
  is_deeply( [ map { ref $_ } @seen ], [ ('Kubernetes::Comb::SVG::Cell') x 3 ], 'callback gets the Cell' );
  is_deeply( [ sort map { $_->id } @seen ], [qw( a b c )], 'once per cell' );

  my @warn;
  my $died = do {
    local $SIG{__WARN__} = sub { push @warn, @_ };
    picture( 'link', link => sub { die "nope\n" if $_[0]->name eq 'b'; '/'.$_[0]->name } );
  };
  is( count( $died, '//s:'.$COMB ), 3, 'a dying callback still gives the picture' );
  is_deeply( [ map { $_->getAttribute('href') } $died->findnodes('//s:a') ], [ '/a', '/c' ], 'only the cell that died has no link' );
  is( scalar @warn, 1, 'one warning' );
  like( $warn[0], qr/link callback died for b: nope/, 'the warning says which cell and why' );
};

subtest 'theme' => sub {
  my $default = style_text( picture('phases') );
  like( $default, qr/--comb-running:#1a7f37/, 'default Running colour' );

  my $css = style_text( picture( 'phases', theme => { Running => '#ff00aa', Error => 'rgb(1, 2, 3)', Blocked => 'tomato' } ) );
  like( $css, qr/--comb-running:#ff00aa;/, 'a hex colour lands in the style (light)' );
  like( $css, qr/\@media \(prefers-color-scheme:dark\)\{[^}]*--comb-running:#ff00aa/, 'and in the dark block' );
  like( $css, qr/--comb-error:rgb\(1, 2, 3\)/, 'rgb() is accepted' );
  like( $css, qr/--comb-blocked:tomato/, 'a colour name is accepted' );
  like( $css, qr/--comb-pending:#bf8700/, 'other phases keep their default' );

  my ( $l, $d ) = modes($default);
  is_deeply( [ $l->{'--comb-stopped'}, $d->{'--comb-stopped'} ], [ '#0891b2', '#39c5cf' ], 'default Stopped: cyan, light and dark' );
  is_deeply( [ $l->{'--comb-notdeployed'}, $d->{'--comb-notdeployed'} ], [ '#0969da', '#58a6ff' ],
    'default NotDeployed: blue, light and dark' );
  for my $phase (qw( Stopped NotDeployed )) {
    my $var = '--comb-'.lc $phase;
    like( $default, qr/\.phase-$phase \.hex\{fill:var\($var\);stroke:var\($var\)\}/, $phase.': the hexagon rule uses '.$var );
    ( $l, $d ) = modes( style_text( picture( 'phases', theme => { $phase => '#abcdef' } ) ) );
    is_deeply( [ $l->{$var}, $d->{$var} ], [ ('#abcdef') x 2 ], $phase.': one theme colour serves both modes' );
    ( $l, $d ) = modes( style_text( picture( 'phases', theme => { $phase => { light => '#010203', dark => '#fdfeff' } } ) ) );
    is_deeply( [ $l->{$var}, $d->{$var} ], [ '#010203', '#fdfeff' ], $phase.': theme {light,dark}' );
    is( $l->{'--comb-unknown'}, '#475569', $phase.': Unknown keeps its own colour' );
  }

  for my $bad (
    'red;}</style><script>x</script>', 'url(http://evil/x)', 'expression(alert(1))',
    '#ff00aa; background:url(x)', "#fff\n}", '}', 'red"', { a => 1 }
  ) {
    my $xpc = picture( 'phases', theme => { Running => $bad } );
    my $style = style_text($xpc);
    like( $style, qr/--comb-running:#1a7f37/, 'hostile theme value falls back to the default' );
    unlike( $style, qr/evil|script|expression|background/, '  and does not reach the style' );
    is( count( $xpc, '//s:style' ), 1, '  style element count unchanged' );
    is( count( $xpc, '//*[local-name()="script"]' ), 0, '  no script' );
  }

  my $xpc = picture( 'phases', theme => { Bogus => '#123456', running => '#123456', BG => '#123456' } );
  my $style = style_text($xpc);
  unlike( $style, qr/--comb-bogus|#123456/, 'unknown key and wrong case are ignored' );
  like( $style, qr/--comb-bg:#ffffff/, 'the base colours keep their default' );
};

# The two blocks of custom properties: what .comb-svg carries in light mode
# and what the prefers-color-scheme dark block overrides.
sub modes {
  my ( $css ) = @_;
  my ( $light ) = $css =~ /\A\.comb-svg\{([^}]*)\}/;
  my ( $dark )  = $css =~ /\@media \(prefers-color-scheme:dark\)\{\.comb-svg\{([^}]*)\}\}/;
  return map { +{ map { split /:/, $_, 2 } split /;/, $_ } } $light, $dark;
}

subtest 'theme: light and dark' => sub {
  my ( $light, $dark ) = modes( style_text( picture(
    'phases',
    theme => {
      Error   => { light => '#110000', dark => 'rgb(255, 0, 0)' },
      Running => { dark => '#00ff00' },
      Pending => { light => 'gold' },
      Blocked => '#abcdef',
      Unknown => { light => 'url(http://evil/x)', dark => '#222222' },
      Disabled => { light => 'red;}</style><script>x</script>', dark => '}' },
      NeedsConfig => { Light => '#123123', other => '#123123' }
    }
  ) ) );
  is( $light->{'--comb-error'}, '#110000', 'light value in the light block' );
  is( $dark->{'--comb-error'}, 'rgb(255, 0, 0)', 'dark value in the dark block' );
  is( $light->{'--comb-running'}, '#1a7f37', 'a missing light keeps the default' );
  is( $dark->{'--comb-running'},  '#00ff00', '  next to the given dark' );
  is( $light->{'--comb-pending'}, 'gold',    'a given light' );
  is( $dark->{'--comb-pending'},  '#e3b341', '  next to the default dark' );
  is( $light->{'--comb-blocked'}.$dark->{'--comb-blocked'}, '#abcdef#abcdef', 'one colour serves both' );
  is( $light->{'--comb-unknown'}, '#475569', 'a bad light falls back on its own' );
  is( $dark->{'--comb-unknown'},  '#222222', '  the good dark is kept' );
  is( $light->{'--comb-disabled'}.$dark->{'--comb-disabled'}, '#8c959f#6e7681', 'both bad: both defaults' );
  is( $light->{'--comb-needsconfig'}.$dark->{'--comb-needsconfig'}, '#8250df#a371f7',
    'hash keys other than light and dark are ignored' );

  my $svg = $SVG->new( combs => fixture('phases'),
    theme => { Error => { light => 'red;}</style><script>x</script>', dark => 'expression(evil)' },
      bg => { light => '#fff</style>', dark => 'url(//evil)' } } )->render;
  my $xpc = parse($svg);
  unlike( $svg, qr/evil|script|expression/, 'nothing of a hostile mode value reaches the output' );
  is( count( $xpc, '//s:style' ), 1, '  one style element' );
  is( count( $xpc, '//*[local-name()="script"]' ), 0, '  no script' );
};

subtest 'theme: surfaces' => sub {
  my %default = ( bg => [ '#ffffff', '#0d1117' ], border => [ '#d0d7de', '#30363d' ],
    fg => [ '#1f2328', '#e6edf3' ], muted => [ '#59636e', '#9198a1' ], edge => [ '#57606a', '#9198a1' ] );
  my ( $light, $dark ) = modes( style_text( picture('phases') ) );
  for my $key ( sort keys %default ) {
    is_deeply( [ $light->{ '--comb-'.$key }, $dark->{ '--comb-'.$key } ], $default{$key}, $key.': default' );
  }
  ( $light, $dark ) = modes( style_text( picture(
    'phases',
    theme => {
      bg     => { light => '#fafafa', dark => '#000000' },
      fg     => 'hsl(210, 10%, 20%)',
      muted  => { dark => 'silver' },
      border => 'javascript:alert(1)',
      edge   => { light => '#101010', dark => 'x;y' }
    }
  ) ) );
  is_deeply( [ $light->{'--comb-bg'}, $dark->{'--comb-bg'} ], [ '#fafafa', '#000000' ], 'bg: light and dark' );
  is_deeply( [ $light->{'--comb-fg'}, $dark->{'--comb-fg'} ], [ ('hsl(210, 10%, 20%)') x 2 ], 'fg: one colour for both' );
  is_deeply( [ $light->{'--comb-muted'}, $dark->{'--comb-muted'} ], [ '#59636e', 'silver' ], 'muted: dark only' );
  is_deeply( [ $light->{'--comb-border'}, $dark->{'--comb-border'} ], $default{border}, 'border: a bad colour falls back' );
  is_deeply( [ $light->{'--comb-edge'}, $dark->{'--comb-edge'} ], [ '#101010', '#9198a1' ], 'edge: bad dark falls back alone' );
  is( $light->{'--comb-running'}, '#1a7f37', 'phases untouched' );
};

my $ANIMATION = qr/animation|keyframes|reduced-motion|comb-blink/;

subtest 'blink' => sub {
  my $plain = $SVG->new( combs => fixture('phases') )->render;
  unlike( $plain, $ANIMATION, 'no blink: no animation CSS at all' );
  is( $SVG->new( combs => fixture('phases'), blink => [] )->render, $plain, 'empty blink: the same bytes' );
  is( $SVG->new( combs => fixture('phases'), blink_seconds => 3 )->render, $plain,
    'blink_seconds without blink: the same bytes' );

  my $xpc = picture( 'phases', blink => [ 'Error', 'Blocked' ] );
  my $css = style_text($xpc);
  is( count( $xpc, '//s:style' ), 1, 'still one style element' );
  is( count( $xpc, '//*[local-name()="script" or local-name()="animate" or local-name()="set"]' ), 0,
    'no script, no SMIL: the animation is CSS' );
  my @keyframes = $css =~ /(\@keyframes [\w-]+)/g;
  is_deeply( \@keyframes, ['@keyframes comb-blink'], 'one keyframes rule, its name prefixed' );
  like( $css, qr/\@keyframes comb-blink\{50%\{fill-opacity:[\d.]+;stroke-width:[\d.]+\}\}/,
    'the pulse touches fill-opacity and stroke-width of the hexagon only' );
  unlike( $css, qr/\@keyframes[^\n]*(?<!fill-)opacity:0?(?:\.0+)?[;}]/, 'nothing fades to nothing' );

  my ( $rule ) = $css =~ /^([^\n@]*)\{animation:comb-blink 1\.2s ease-in-out infinite\}$/m;
  ok( defined $rule, 'animation rule: the default period, eased, endless' );
  is_deeply( [ split /,/, $rule ],
    [ '.comb-svg .comb.phase-Blocked .hex', '.comb-svg .comb.phase-Error .hex' ],
    'for the hexagons of the named phases only' );
  my @blinking = $css =~ /\.comb\.phase-(\w+)/g;
  is_deeply( [ sort keys %{ { map { $_ => 1 } @blinking } } ], [qw( Blocked Error )],
    'no other phase in any blink rule' );

  my ( $reduced ) = $css =~ /^\@media \(prefers-reduced-motion:reduce\)\{(.*)\}$/m;
  ok( defined $reduced, 'a prefers-reduced-motion block' );
  my ( $selector, $body ) = $reduced =~ /\A([^{]*)\{([^}]*)\}\z/;
  is( $selector, $rule, '  for the same cells' );
  like( $body, qr/\Aanimation:none;stroke-width:([\d.]+)\z/, '  animation off, an outline width instead' );
  my ( $thick ) = $body =~ /stroke-width:([\d.]+)/;
  my ( $normal ) = $css =~ /\.comb-svg \.hex\{[^}]*stroke-width:([\d.]+)/;
  cmp_ok( $thick, '>', $normal, '  thicker than the normal outline' );

  my %phase = map { $_->getAttribute('data-phase') => classes($_) } combs($xpc);
  ok( $phase{Error}{comb} && $phase{Error}{'phase-Error'}, 'the cells carry the classes the rules select' );
  is( count( $xpc, '//s:g[ '.has_class('legend-item').' ][ '.has_class('comb').' ]' ), 0,
    'legend swatches are no g.comb: they do not blink' );

  for my $case ( [ 2.5, '2.5s' ], [ 1, '1s' ], [ 0.333, '0.33s' ], [ 0.0001, '0.01s' ], [ 9**9**9, '1.2s' ],
    [ 1e30, '1.2s' ] ) {
    my ( $seconds, $want ) = @$case;
    my $style = style_text( picture( 'phases', blink => ['Error'], blink_seconds => $seconds ) );
    my ( $got ) = $style =~ /animation:comb-blink (\S+) /;
    is( $got, $want, 'blink_seconds '.$seconds.' is written as '.$want );
  }

  my $one = $SVG->new( combs => fixture('phases'), blink => ['Error'] )->render;
  for my $case (
    [ 'unknown phase' => [ 'Error', 'Bogus' ] ],
    [ 'wrong case' => [ 'Error', 'blocked' ] ],
    [ 'hostile name' => [ 'Error', 'x .hex{}</style><script>alert(1)</script>', 'Error{fill:url(//evil)}' ] ],
    [ 'duplicates' => [ 'Error', 'Error', 'Error' ] ]
  ) {
    my ( $name, $blink ) = @$case;
    is( $SVG->new( combs => fixture('phases'), blink => $blink )->render, $one, $name.': ignored, same bytes' );
  }
  is( $SVG->new( combs => fixture('phases'), blink => [ 'Bogus', '' ] )->render, $plain,
    'only unknown phases: no animation CSS, the plain picture' );

  for my $phase (qw( Stopped NotDeployed )) {
    my $style = style_text( picture( 'phases', blink => [$phase] ) );
    my ( $only ) = $style =~ /^([^\n@]*)\{animation:comb-blink /m;
    is( $only, '.comb-svg .comb.phase-'.$phase.' .hex', 'blink '.$phase.': its hexagons pulse, no others' );
  }

  my $all = style_text( picture( 'phases', blink => [ reverse $SVG->phases ] ) );
  my ( $every ) = $all =~ /^([^\n@]*)\{animation:comb-blink /m;
  is_deeply( [ $every =~ /\.comb\.phase-(\w+) \.hex/g ], [ $SVG->phases ],
    'every phase can blink, written in the order of the legend' );

  is( $SVG->new( combs => fixture('phases'), blink => [qw( Error Blocked Pending )] )->render,
    $SVG->new( combs => fixture('phases'), blink => [qw( Pending Error Blocked Error )] )->render,
    'determinism: order and repeats in blink do not change the bytes' );

  ok( !eval { $SVG->new( combs => [], blink => 'Error' ); 1 }, 'blink that is no array dies' );
  ok( !eval { $SVG->new( combs => [], blink_seconds => $_ ); 1 }, 'blink_seconds '.$_.' dies' ) for 0, -1, 'fast';
};

subtest 'size and columns' => sub {
  my $base  = view_box( picture('wrap') );
  my $small = view_box( picture( 'wrap', size => 28 ) );
  cmp_ok( $small->[2], '<', $base->[2], 'a smaller size narrows the viewBox' );
  cmp_ok( $small->[3], '<', $base->[3], 'and lowers it' );
  my $narrow = view_box( picture( 'wrap', columns => 2 ) );
  cmp_ok( $narrow->[2], '<', $base->[2], 'fewer columns narrow the viewBox' );
  cmp_ok( $narrow->[3], '>', $base->[3], 'and make it taller' );
  my $big = comb( picture( 'wrap', size => 100 ), 'c1' );
  is( count( $big, 's:polygon' ), 1, 'cell drawn at another size' );
  my $pts = [ val( $big, q{s:polygon/@points} ) =~ /(-?[\d.]+),(-?[\d.]+)/g ];
  my @ys  = @$pts[ grep { $_ % 2 } 0 .. $#$pts ];
  my ( $min, $max ) = ( sort { $a <=> $b } @ys )[ 0, -1 ];
  is( sprintf( '%.0f', $max - $min ), 200, 'hexagon height is twice the size option' );
};

subtest 'self-contained' => sub {
  my %run = (
    hostile => [ 'hostile', link => sub { 'https://h/'.$_[0]->name =~ s/\W//gr }, group_label => 'tier' ],
    chain   => ['chain'],
    full    => [ 'tooltip', link => sub { '/x' }, theme => { Running => '#abcdef' } ],
    empty   => [ [] ]
  );
  for my $label ( sort keys %run ) {
    my ( $combs, @opt ) = @{ $run{$label} };
    my $svg = $SVG->new( combs => ref $combs ? $combs : fixture($combs), @opt )->render;
    my $xpc = parse($svg);
    is( count( $xpc, '//*[local-name()="script" or local-name()="image" or local-name()="foreignObject" or local-name()="use" or local-name()="iframe"]' ), 0, $label.': no script, image, foreignObject, use' );
    is( count( $xpc, '//s:style' ), 1, $label.': one style element' );
    is( count( $xpc, '//@*[local-name()="href" and not(parent::s:a)]' ), 0, $label.': href only on anchors' );
    my @external = grep { !m{\Ahttps?://h/} && !m{\A/x\z} } map { $_->value } $xpc->findnodes('//s:a/@href');
    is( scalar @external, 0, $label.': anchors point only where the callback said' );
    unlike( $svg, qr/xlink/i, $label.': no xlink' );
    my $css = style_text($xpc);
    unlike( $css, qr/\@import|url\(|https?:|\/\//, $label.': style has no import, url() or external reference' );
    my @urls = map { $_->value } $xpc->findnodes('//@*[contains(.,"url(")]');
    is_deeply( [ grep { $_ ne 'url(#comb-arrow)' } @urls ], [], $label.': the only url() is the arrow marker' );
    is( count( $xpc, '//@*[local-name()="src" or local-name()="data"]' ), 0, $label.': no src attribute' );
    my %id;
    $id{$_}++ for map { $_->value } $xpc->findnodes('//@id');
    is_deeply( [ sort keys %id ], [ 'comb-arrow', 'comb-desc', 'comb-title' ], $label.': a fixed set of ids' );
  }
};

subtest 'determinism' => sub {
  my @args = ( combs => fixture('tooltip'), group_label => 'tier', title => 'Lab' );
  my $first = $SVG->new(@args)->render;
  is( $first, $SVG->new(@args)->render, 'two objects, same bytes' );
  my $object = $SVG->new(@args);
  is( $object->render, $object->render, 'one object rendered twice, same bytes' );

  my $hostile = fixture('hostile');
  is( $SVG->new( combs => $hostile )->render, $SVG->new( combs => $hostile )->render, 'hostile input is stable too' );
  my $out = $first;
  unlike( $out, qr/\d{4}-\d{2}-\d{2}|\bid="[a-f0-9]{8,}/, 'no timestamp, no generated id' );

  my @cr = @{ fixture('chain') };
  my $forward  = $SVG->new( combs => [@cr] )->render;
  my $backward = $SVG->new( combs => [ reverse @cr ] )->render;
  my ( $f, $b ) = ( parse($forward), parse($backward) );
  my $place = sub { +{ map { $_->getAttribute('data-id') => join( ',', centre($_) ) } combs( $_[0] ) } };
  is_deeply( $place->($b), $place->($f), 'input order does not move any cell' );
  is( $backward, $forward, 'input order does not change the bytes' );
};

subtest 'input shapes' => sub {
  {
    package Local::CR;
    sub new { my ( $class, $cr ) = @_; bless { cr => $cr }, $class }
    sub TO_JSON { $_[0]{cr} }
  }
  my $xpc = picture( [ map { Local::CR->new($_) } @{ fixture('phases') } ] );
  is( count( $xpc, '//s:'.$COMB ), 8, 'objects answering TO_JSON' );
  is( $xpc->findvalue('/s:svg/s:desc'), picture('phases')->findvalue('/s:svg/s:desc'), 'same picture as plain hashes' );

  my $list = picture('list');
  is( count( $list, '//s:'.$COMB ), 2, 'a List hash with items' );
  is( $list->findvalue('/s:svg/s:desc'), '2 Combs: 1 Running, 1 Error', 'summary of the list' );

  my $single = picture( Local::CR->new( { metadata => { name => 'solo' } } ) );
  is( count( $single, '//s:'.$COMB ), 1, 'one object, not wrapped in an array' );
};

subtest 'empty input' => sub {
  for my $empty ( [], { kind => 'List', items => [] } ) {
    my $xpc = picture($empty);
    is( count( $xpc, '/s:svg' ), 1, 'a valid document' );
    is( count( $xpc, '//s:'.$COMB ), 0, 'no cells' );
    is( count( $xpc, '//s:g[@class="legend" or @class="deps"]' ), 0, 'no legend, no edges' );
    is( $xpc->findvalue('/s:svg/s:desc'), '0 Combs', 'desc' );
    my $box = view_box($xpc);
    ok( $box->[2] > 0 && $box->[3] > 0, 'viewBox has a positive size' );
    is( count( $xpc, '//s:style' ), 1, 'style still there' );
    is( count( $xpc, '/s:svg/s:text[@class="heading"]' ), 1, 'heading still there' );
  }
};

subtest 'a Comb without a name is an error' => sub {
  my $ok = eval { $SVG->new( combs => fixture('no-name') )->render; 1 };
  ok( !$ok, 'dies' );
  like( $@, qr/metadata\.name/, 'and says what is missing' );
  ok( !eval { $SVG->new( combs => [ {} ] )->render; 1 }, 'an empty hash is no Comb' );
};

done_testing;
