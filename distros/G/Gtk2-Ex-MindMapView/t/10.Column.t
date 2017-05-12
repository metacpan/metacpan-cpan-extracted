# 10.Column.t - Test the Gtk2::Ex::MindMapView::Layout::Column
# -----------------------------------------------------------------------------
use Test::More tests => 18;

BEGIN {
chdir 't' if -d 't';
use lib '../lib';
use_ok( 'Gtk2::Ex::MindMapView' );
use_ok( 'Gtk2::Ex::MindMapView::Item' );
use_ok( 'Gtk2::Ex::MindMapView::ItemFactory' );
use_ok( 'Gtk2::Ex::MindMapView::Layout::Column' );
}

diag( "Testing Gtk2::Ex::MindMapView::Layout::Column $Gtk2::Ex::MindMapView::Layout::Column::VERSION" );

use Gtk2 '-init';

use constant BENCHMARK_INSET=>7;

my $text = 'Hello World!';

my $font_desc = Gtk2::Pango::FontDescription->from_string('Ariel Normal 10');

my $view = Gtk2::Ex::MindMapView->new(aa=>1);

isa_ok( $view, 'Gtk2::Ex::MindMapView');

my $factory = Gtk2::Ex::MindMapView::ItemFactory->new(view=>$view);

isa_ok( $factory, 'Gtk2::Ex::MindMapView::ItemFactory');


my $benchmark_text = Gnome2::Canvas::Item->new($view->root, 'Gnome2::Canvas::Text',
	font_desc=>$font_desc,
	text=>$text);

my $benchmark_x      = $benchmark_text->get('x');

my $benchmark_y      = $benchmark_text->get('y');

my $benchmark_height = $benchmark_text->get('text-height') + (BENCHMARK_INSET * 2);

my $benchmark_width  = $benchmark_text->get('text-width') + (BENCHMARK_INSET * 2);


my $item1 = $factory->create_item(
	border=>'Gtk2::Ex::MindMapView::Border::RoundedRect',
	content=>'Gtk2::Ex::MindMapView::Content::EllipsisText',
        font_desc=>$font_desc,
	text=>$text);

isa_ok( $item1, 'Gtk2::Ex::MindMapView::Item');

my $item2 = $factory->create_item(
	border=>'Gtk2::Ex::MindMapView::Border::RoundedRect',
	content=>'Gtk2::Ex::MindMapView::Content::EllipsisText',
        font_desc=>$font_desc,
	text=>$text);

isa_ok( $item2, 'Gtk2::Ex::MindMapView::Item');

my $column = Gtk2::Ex::MindMapView::Layout::Column->new(column_no=>0);

$column->add(undef, $item1);

$column->add($item1, $item2);

$column->layout();

my ($h1, $w1) = $item1->get(qw(height width));

is($h1, $benchmark_height, 'item 1 height should be ' . $benchmark_height);

is($w1, $benchmark_width, 'item 1 width should be ' . $benchmark_width);

my ($h2, $w2) = $item2->get(qw(height width));

is($h2, $benchmark_height, 'item 2 height should be ' . $benchmark_height);

is($w2, $benchmark_width, 'item 2 width should be ' . $benchmark_width);

my $height = $column->{height};

my $benchmark_column_height = (2 * $benchmark_height) + $column->get_vertical_padding();

is($height, $benchmark_column_height, 'column height should be ' . $benchmark_column_height);

my $width = $column->{width};

my $benchmark_column_width = $benchmark_width;

is($width, $benchmark_column_width, 'column width should be ' . $benchmark_column_width);


my $vertical_padding = $column->get_vertical_padding();

is($vertical_padding, 10, 'vertical padding should be 10');


my $max_width = $column->get_max_width();

is($max_width, 400, 'maximum width should be 400');


my %clusters = %{$column->{clusters}};

my @clusters = values( %clusters);

is(scalar( @clusters), 1, 'There should be one cluster.');


foreach my $cluster (@clusters)
{
    isa_ok($cluster, 'Gtk2::Ex::MindMapView::Layout::Cluster');
}

$column->{clusters} = undef;

$item1->{border} = undef;

$item1->{hotspots} = undef;

$item1 = undef;

$item2->{border} = undef;

$item2->{hotspots} = undef;

$item2 = undef;

$factory->{view} = undef;

$factory = undef;

$view = undef;
