package Gtk2::Ex::CellRendererWrappedText::TextView;
{
  $Gtk2::Ex::CellRendererWrappedText::TextView::VERSION = '0.2';
}

use Gtk2;
use Gtk2::Gdk::Keysyms;

use Glib::Object::Subclass
	Gtk2::TextView::,
	interfaces => [ 'Gtk2::CellEditable' ],
	properties => [
		Glib::ParamSpec->boolean(
			'editing-cancelled',
			'Editing Cancelled',
			'Indicates whether editing on the cell has been canceled.',
			0,
			[qw( readable writable )],
		)
	],
	;
	
sub set_text {
	my ( $w, $text ) = @_;
	$w->get_buffer->set_text( $text );
}
sub get_text {
	my ( $w ) = @_;
	my $buffer = $w->get_buffer;
	$buffer->get_text ( $buffer->get_start_iter,  $buffer->get_end_iter, 1 );
}



package Gtk2::Ex::CellRendererWrappedText;
{
  $Gtk2::Ex::CellRendererWrappedText::VERSION = '0.2';
}

use Glib::Object::Subclass
	Gtk2::CellRendererText::,
	;

sub START_EDITING {
	my ($cell, $event, $widget, $path, $background_area, $cell_area, $flags) = @_;
	

	my $e = Gtk2::Ex::CellRendererWrappedText::TextView->new;
	$e->set( 'wrap-mode', $cell->get( 'wrap-mode' ) );
	$e->get_buffer->set_text( $cell->get( 'text' ) );
	#$e->set_border_width( $cell->get( 'ypad' ) );
	$e->set_size_request( $cell_area->width - $cell->get( 'ypad' ) , $cell_area->height );
	$e->grab_focus;

	$e->signal_connect ('key-press-event' => sub {
		my ( $widget, $event ) = @_;
		
		# if user presses Ctrl + enter/return then send edited signal
		if ( ( $event->keyval == $Gtk2::Gdk::Keysyms{Return} ||  $event->keyval == $Gtk2::Gdk::Keysyms{KP_Enter} ) and $event->state & 'control-mask'
			) {
			$cell->signal_emit( edited => $path, $widget->get_text);
			$widget->destroy;
			return 1;
		}
		
		# if user presses esc - cancel editing
		elsif ( $event->keyval == $Gtk2::Gdk::Keysyms{Esc} ) {
			$widget->destroy;
			return 1;
		}
		return 0;
	});
    
        # send edited signal on focus out
	$e->signal_connect( 'focus-out-event' => sub {
		my $widget = shift;
		$cell->signal_emit( edited => $path, $widget->get_text );
	});
    
	$e->show;
	return $e;
}

sub RENDER {
	my $cell = shift;
	my ($event, $widget, $path, $background_area, $cell_area, $expose_area, $flags) = @_;
	
	$cell->set( 'wrap-width', $cell_area->width - $cell->get( 'ypad' )  );
	$cell->SUPER::RENDER( @_ );
}



1;


__END__

=head1 NAME

Gtk2::Ex::CellRendererWrappedText - Widget for displaying and editing multi-line
text entries in a TreeView

=head1 SYNOPSIS

 use Gtk2::Ex::CellRendererWrappedText;
 
 $treeview->new( $model );
 
 $cell = Gtk2::CellRender

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
 
=head1 WIDGET HIERARCHY

=over 4

=item Glib::Object

=item +-- Glib::InitiallyUnowned

=item ....+-- Gtk2::Object

=item ........+-- Gtk2::CellRenderer

=item ............+-- Gtk2::CellRendererText

=item ................+ Gtk2::Ex::CellRendererWrappedText

=back

=head1 DESCRIPTION

Gtk2::Ex::CellRendererWrappedText is a Gtk2::CellRendererText that
automatically updates the wrap-width of the of the renderer when it
is resized so that it always expands or shrinks to the avaialble area.

This module also handles editing of strings that span multiple lines by
using a TextView instead of an Entry as CellRendererText does.

Pressing <Esc> whil in edit mode cancels the edit. Pressing <Enter>  moves to
the next line. Pressing <Ctrl+Enter> or focusing out of the renderer finishes
editing and emits the 'edited' signal.

=head1 BUGS & CAVEATS

Using this module produces this warning:

    GLib-GObject-CRITICAL **: Object class Gtk2__Ex__CellRendererWrappedText__TextView
    doesn't implement property 'editing-canceled' from interface 'GtkCellEditable' at ...

This is only a warning, and a known issue with Gtk+ and the Gtk2-Perl bindings that will not
affect behaviour of the widget.

See this post for more information:

L<http://old.nabble.com/Having-issues-porting-a-CellRenderer---CellEditable-to-Gtk3-td34129064.html>

=head1 AUTHOR

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

Some code adapted from Muppet's customrenderer.pl script included in the
Gtk2 examples directory.

=head1 COPYRIGHT & LICENSE

Copyright (c) 2010-2012 Jeffrey Ray Hallock.
    
    This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
    
=cut


