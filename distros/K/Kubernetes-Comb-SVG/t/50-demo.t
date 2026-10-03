#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON::MaybeXS;
use Path::Tiny;
use XML::LibXML;
use XML::LibXML::XPathContext;

use Kubernetes::Comb::SVG::Cell;

# The demo picture, SPEC 10: examples/demo.svg is committed and shown in the
# README, so it has to be what examples/demo.pl renders from
# examples/demo.json today. The script itself is run, writing to a temporary
# file -- its options exist in one place only and cannot drift from the test.

my $root     = path(__FILE__)->parent->parent;
my $examples = $root->child('examples');
my $script   = $examples->child('demo.pl');
my $svg      = $examples->child('demo.svg');
my $label    = 'app.kubernetes.io/part-of';

my $tmp   = Path::Tiny->tempdir;
my $fresh = $tmp->child('demo.svg');
my $exit  = system( $^X, '-I'.$root->child('lib'), $script->stringify, $fresh->stringify );
is( $exit, 0, 'examples/demo.pl runs' );

ok( $svg->is_file, 'examples/demo.svg is there' );
ok( $fresh->is_file && $svg->is_file && $fresh->slurp_raw eq $svg->slurp_raw,
  'examples/demo.svg is what examples/demo.pl renders' )
  or diag 'examples/demo.svg is stale -- regenerate it with: perl -Ilib examples/demo.pl';

# The same run writes the packed picture next to it.
my $monitor       = $examples->child('monitor.svg');
my $fresh_monitor = $tmp->child('monitor.svg');
ok( $monitor->is_file, 'examples/monitor.svg is there' );
ok( $fresh_monitor->is_file && $monitor->is_file
    && $fresh_monitor->slurp_raw eq $monitor->slurp_raw,
  'examples/monitor.svg is what examples/demo.pl renders' )
  or diag 'examples/monitor.svg is stale -- regenerate it with: perl -Ilib examples/demo.pl';

# What the picture has to show, asserted on the committed file.

my $xpc = XML::LibXML::XPathContext->new( XML::LibXML->load_xml( string => $svg->slurp_raw ) );
$xpc->registerNs( s => 'http://www.w3.org/2000/svg' );

sub has_class { 'contains(concat(" ",@class," ")," '.$_[0].' ")' }

my @combs = $xpc->findnodes( '//s:g[ '.has_class('comb').' ]' );
cmp_ok( scalar @combs, '>=', 10, 'ten Combs or more' );

my %phase;
$phase{ $_->getAttribute('data-phase') }++ for @combs;
# Every phase the dist knows has a Comb in the demo, Unknown aside: that is
# what a phase nobody knows falls back to.
ok( $phase{$_}, 'a '.$_.' Comb' ) for grep { $_ ne 'Unknown' } Kubernetes::Comb::SVG::Cell->known_phases;
ok( Kubernetes::Comb::SVG::Cell->is_known_phase($_), $_.' is a known phase' ) for sort keys %phase;

ok( $xpc->findnodes( '//s:g[ '.has_class('comb').' ][ '.has_class('borrowed').' ]' )->size,
  'a borrowed Comb' );
ok( $xpc->findnodes( '//s:text[ '.has_class('upstream').' ][ starts-with( ., "from " ) ]' )->size,
  'its upstream context is named' );
ok( $xpc->findnodes( '//s:g[ '.has_class('comb').' ][ '.has_class('disabled').' ]' )->size,
  'a disabled Comb' );

cmp_ok( $xpc->findnodes( '//s:g[ '.has_class('group').' ][ @data-group ]' )->size,
  '>=', 2, 'two groups or more' );

# A cell in the SVG does not say which group it is in, so that is read from
# the data.
my $data = JSON::MaybeXS->new( utf8 => 1 )->decode( $examples->child('demo.json')->slurp_raw );
my %group;
for my $comb ( @{ $data->{items} } ) {
  my $meta = $comb->{metadata};
  $group{ $meta->{namespace}.'/'.$meta->{name} } = $meta->{labels}{$label};
}
is( scalar( grep { !defined } values %group ), 0, 'every Comb carries the group label' );
ok( scalar( grep { exists $_->{spec}{enabled} && !$_->{spec}{enabled} } @{ $data->{items} } ),
  'a Comb with spec.enabled false' );

my @edges = $xpc->findnodes( '//s:path[ '.has_class('dep').' ]' );
my ( $across, $inside ) = ( 0, 0 );
for my $edge (@edges) {
  my ( $from, $to ) = map { $group{ $edge->getAttribute($_) } } qw( data-from data-to );
  next unless defined $from && defined $to;
  $from eq $to ? $inside++ : $across++;
}
ok( $across, 'an edge across groups' );
ok( $inside, 'an edge inside a group' );

# The monitor: the same Combs, packed, without edges.

my $packed = XML::LibXML::XPathContext->new( XML::LibXML->load_xml( string => $monitor->slurp_raw ) );
$packed->registerNs( s => 'http://www.w3.org/2000/svg' );
is_deeply(
  [ sort map { $_->getAttribute('data-id') } $packed->findnodes( '//s:g[ '.has_class('comb').' ]' ) ],
  [ sort map { $_->getAttribute('data-id') } @combs ],
  'monitor: the same Combs'
);
is( $packed->findnodes( '//s:path[ '.has_class('dep').' ]' )->size, 0, 'monitor: no edges' );
my ( undef, undef, $width, $height ) = split ' ', $packed->findvalue('/s:svg/@viewBox');
cmp_ok( $width, '>', $height, 'monitor: a wide picture' );

done_testing;
