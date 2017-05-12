# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use Gnome::StockIcons;
#########################
&show_all();
# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.
sub show_all {
use Gtk;
init Gtk;
$false=0;
$true=1;
 $window =  new Gtk::Window( 'toplevel' );

my $width=400;
my $heigth=400;

$window->set_usize( $width, $heigth );
$window->set_default_size( $width, $heigth );

$window->set_title(  'SynSim' );
#$window->signal_connect( 'delete_event', sub { Gtk->exit( 0 ); return 1} );
$window->signal_connect( 'delete_event', sub { $window->destroy();print "ok 1\n"; exit( 0)} );
my $main_vbox = new Gtk::VBox( $false, 0 );
$window->add( $main_vbox );
$main_vbox->show();

$window->show();
my $style = $window->get_style()->bg( 'normal' );

my ( $pixmap, $mask ) = Gtk::Gdk::Pixmap->create_from_xpm_d( $window->window,
                                                        $style,
                                                        @calculator_font);
my $pixmapwid = new Gtk::Pixmap( $pixmap, $mask );
$pixmapwid->show();

$main_vbox->pack_start( $pixmapwid, $false, $false, 2 );

my $table = new Gtk::Table( 12, 12, $false );
$table->set_row_spacing( 0, 2 );
$table->set_col_spacing( 0, 2 );
#$main_vbox->pack_start( $console_table, $true, $true, 0 );

$table->show();
$main_vbox->pack_start($table, $true, $true, 2 );

$i=0;$j=0;

foreach my $icon (qw(
	stock_add
	stock_align_center
	stock_align_justify
	stock_align_left
	stock_align_right
	stock_attach
	stock_book_blue
	stock_book_green
	stock_book_open
	stock_book_red
	stock_book_yellow
	stock_bottom
	stock_button_apply
	stock_button_cancel
	stock_button_close
	stock_button_no
	stock_button_ok
	stock_button_yes
	stock_cdrom
	stock_clear
	stock_close
	stock_colorselector
	stock_convert
	stock_copy
	stock_cut
	stock_down_arrow
	stock_exec
	stock_exit
	stock_first
	stock_font
	stock_help
	stock_home
	stock_index
	stock_jump_to
	stock_last
	stock_left_arrow
	stock_line_in
	stock_mail
	stock_mail_compose
	stock_mail_forward
	stock_mail_receive
	stock_mail_reply
	stock_mail_send
	stock_menu_about
	stock_menu_blank
	stock_menu_scores
	stock_mic
	stock_midi
	stock_multiple_file
	stock_new
	stock_not
	stock_open
	stock_paste
	stock_preferences
	stock_print
	stock_properties
	stock_redo
	stock_refresh
	stock_remove
	stock_revert
	stock_right_arrow
	stock_save
	stock_save_as
	stock_scores
	stock_search
	stock_search_replace
	stock_spellcheck
	stock_stop
	stock_table_borders
	stock_table_fill
	stock_text_bold
	stock_text_bulleted_list
	stock_text_indent
	stock_text_italic
	stock_text_numbered_list
	stock_text_strikeout
	stock_text_underline
	stock_text_unindent
	stock_timer
	stock_timer_stopped
	stock_top
	stock_trash
	stock_trash_full
	stock_undelete
	stock_undo
	stock_up_arrow
	stock_volume
		    )) {
$i++;
if($i==10){$i=0;$j++}
$ii=$i+1;
$jj=$j+1;
 ( $pixmap, $mask ) = Gtk::Gdk::Pixmap->create_from_xpm_d( $window->window,
                                                        $style,
                                                        @$icon);
 $pixmapwid = new Gtk::Pixmap( $pixmap, $mask );
$pixmapwid->show();

#$main_vbox->pack_start( $pixmapwid, $false, $false, 2 );
$table->attach( $pixmapwid,$i ,$ii,$j, $jj,[],[],2,2);
}
$idle = Gtk->idle_add( sub {sleep 2;print "ok 1\n";exit(0)} );
main Gtk;
return 1;

}
