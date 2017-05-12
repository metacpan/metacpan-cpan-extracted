# 09.Balanced.t - Test the Gtk2::Ex::MindMapView::Layout::Balanced
# -----------------------------------------------------------------------------
use Test::More tests => 15;

BEGIN {
chdir 't' if -d 't';
use lib '../lib';
use_ok( 'Gtk2::Ex::MindMapView' );
use_ok( 'Gtk2::Ex::MindMapView::Item' );
use_ok( 'Gtk2::Ex::MindMapView::ItemFactory' );
use_ok( 'Gtk2::Ex::MindMapView::Layout::Balanced' );
}

diag( "Testing Gtk2::Ex::MindMapView::Layout::Balanced $Gtk2::Ex::MindMapView::Layout::Balanced::VERSION" );

use Gtk2 '-init';

my $view = Gtk2::Ex::MindMapView->new(aa=>1);

isa_ok( $view, 'Gtk2::Ex::MindMapView');

my $factory = Gtk2::Ex::MindMapView::ItemFactory->new(view=>$view);

isa_ok( $factory, 'Gtk2::Ex::MindMapView::ItemFactory');

my $item1 = $factory->create_item(
	border=>'Gtk2::Ex::MindMapView::Border::RoundedRect',
	content=>'Gtk2::Ex::MindMapView::Content::EllipsisText',
	text=>'Item One');

isa_ok( $item1, 'Gtk2::Ex::MindMapView::Item');

$view->add_item($item1);

my $item2 = $factory->create_item(
	border=>'Gtk2::Ex::MindMapView::Border::RoundedRect',
	content=>'Gtk2::Ex::MindMapView::Content::EllipsisText',
	text=>'Item Two');

isa_ok( $item2, 'Gtk2::Ex::MindMapView::Item');

$view->add_item($item1, $item2);

my $graph = $view->{graph};

my $layout = Gtk2::Ex::MindMapView::Layout::Balanced->new(graph=>$graph);

my $lhs_weight = $layout->{lhs_weight};

is($lhs_weight, 0, 'LHS weight should be 0');

my $rhs_weight = $layout->{rhs_weight};

my $benchmark_rhs_weight = $item2->get_weight();

is($rhs_weight, $benchmark_rhs_weight, 'RHS weight should be ' . $benchmark_rhs_weight);

my $item_count = $layout->{item_count};

is($item_count, 2, 'Item count should be 2');


my %allocated = %{$layout->{allocated}};

my @allocated = values( %allocated);

is(scalar( @allocated), 2, 'There should be two items allocated.');


my %columns = %{$layout->{columns}};

my @columns = values( %columns);

is(scalar( @columns), 2, 'There should be two columns.');


foreach my $column (@columns)
{
    isa_ok($column, 'Gtk2::Ex::MindMapView::Layout::Column');
}

$view->clear();

$item1->{border} = undef;

$item1->{hotspots} = undef;

$item1 = undef;

$factory->{view} = undef;

$factory = undef;

$view = undef;
