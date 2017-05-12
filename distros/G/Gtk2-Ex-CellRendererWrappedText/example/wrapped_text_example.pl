use Gtk2 -init;

use strict;
use warnings;

use Gtk2::Ex::CellRendererWrappedText;


use Glib qw(FALSE TRUE);

my $w = Gtk2::Window->new( 'toplevel' );
$w->set_title( 'CellRendererWrappedText' );
$w->signal_connect( 'delete-event' => sub { Gtk2->main_quit; FALSE; } );

my $vbox = Gtk2::VBox->new;
$w->add ($vbox);


my $label = Gtk2::Label->new;
$label->set_markup ('<big>F-Words</big>');
$vbox->pack_start ($label, FALSE, FALSE, 0);

# create and load the model
my $model = Gtk2::ListStore->new ( 'Glib::String', 'Glib::String' );


foreach (
		[ 'foo',        'bar'],
		[ 'fluffy',     "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed et eros velit, eget adipiscing est. Duis eu lectus turpis. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Suspendisse malesuada, odio in malesuada aliquam, nibh tortor placerat nulla, sed rhoncus metus mauris ut nibh. Cras ac enim libero. Nullam tristique accumsan libero vel iaculis. Cras id nibh eu nunc vulputate venenatis. Aenean sit amet rutrum enim. Cras eu lacus ut dui interdum ultrices eu bibendum turpis. Pellentesque quis arcu eros. Vestibulum non magna purus. Nulla augue nibh, pulvinar quis aliquam blandit, malesuada rhoncus urna. Vivamus tincidunt diam vel eros placerat quis facilisis mauris cursus. Nulla tincidunt, ante lobortis molestie interdum, nulla purus consequat lectus, venenatis euismod tellus tortor eget quam. Nullam nisl risus, ultricies nec adipiscing id, sollicitudin sed eros. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. "],
		[ 'flurble',    "*Milk\n*Eggs\n*Drugs"],) {
	my $iter = $model->append;
	$model->set ($iter, 0, $_->[0], 1, $_->[1] );
}

my $view = Gtk2::TreeView->new_with_model( $model );
$view->set_rules_hint ( 1 );
$view->set_reorderable ( 1 );

my ( $cell, $column );

# standard text render
$cell = Gtk2::CellRendererText->new;
$cell->set( editable => 1 );
$cell->set( wrap_width => 400 );
$cell->signal_connect (edited => sub {
		my ($cell, $text_path, $new_text, $model) = @_;
		my $path = Gtk2::TreePath->new_from_string ($text_path);
		my $iter = $model->get_iter ($path);
		$model->set ($iter, 0, $new_text);
	}, $model);

$column = Gtk2::TreeViewColumn->new_with_attributes( 'Normal', $cell, text => 0 );
$column->set_resizable( 1 );
$view->append_column ($column);

# multiline text render
$cell = Gtk2::Ex::CellRendererWrappedText->new;
$cell->set( editable => 1 );
$cell->set( wrap_mode => 'word' );
$cell->set( wrap_width => 400 );
$cell->signal_connect (edited => sub {
		my ($cell, $text_path, $new_text, $model) = @_;
		my $path = Gtk2::TreePath->new_from_string ($text_path);
		my $iter = $model->get_iter ($path);
		$model->set ($iter, 1, $new_text);
	}, $model);

$column = Gtk2::TreeViewColumn->new_with_attributes( 'Wrapped', $cell, text => 1 );
$column->set_resizable( 1 );
$view->append_column ($column);

my $scroll = Gtk2::ScrolledWindow->new;
$scroll->set_policy ('never', 'automatic');
$scroll->add ($view);
$vbox->pack_start ($scroll, TRUE, TRUE, 0);


$w->set_default_size (400, 300);
$w->show_all;

Gtk2->main;
