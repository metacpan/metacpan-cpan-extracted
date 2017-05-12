use Gtk;

#TITLE: Simple #6
#REQUIRES: Gtk

init Gtk;

                 
{
	my($window,$vbox,$hbox,$tty,$nled,$cled,$sled);

sub pixel {
	my($context, $color) = @_;
	my($pixel, $failed);
	
	$color &= 0x00FFFFFF;
	
	$pixel = $context->get_pixel(	(($color & 0xff0000) >> 8) + (($color & 0xff0000) >> 16),
									(($color & 0x00ff00) >> 0) + (($color & 0x00ff00) >> 8),
									(($color & 0x0000ff) << 0) + (($color & 0x0000ff) << 8));

	if (not defined $pixel) {
		die "unable to allocate color";
	}
	
	$pixel;
}

sub do_color_queue {
	my($tty) = @_;
	
	if (not $tty or not $tty->realized) {
		return;
	}
	
	if (not defined $tty->{color_context}) {
		$tty->{color_context} = new Gtk::Gdk::ColorContext ($tty->window->get_visual, $tty->window->get_colormap);
	}
	
	
	local($_);
	while($_ = pop @{$tty->{col_queue}}) {
		$tty->set_color($_->[0],
						pixel($tty->{color_context}, $_->[1][0]),
						pixel($tty->{color_context}, $_->[1][1]),
						pixel($tty->{color_context}, $_->[1][2]),
						pixel($tty->{color_context}, $_->[1][3]));
	}
}

sub set_color {
	my($tty, $index, $col) = @_;
	
	push @{$tty->{col_queue}}, [$index, $col];
	
	do_color_queue($tty);
}


$window = new Gtk::Widget	"GtkWindow",
		type			=>	-toplevel,
		title		=>	"hello world",
#		allow_grow		=>	0,
#		allow_shrink		=>	0,
		border_width	=>	10;

$vbox = new Gtk::VBox 0, 1;
show $vbox;
$window->add($vbox);

$tty = new Gtk::Tty	80, 24, 100;

$tty->signal_connect_after(realize => \&do_color_queue);

set_color($tty, 0, [0x000000, 0x000000, 0x000000, 0x000000]);
set_color($tty, 1, [0xd00000, 0xd00000, 0x880000, 0xff0000]);
set_color($tty, 2, [0x00d000, 0x00d000, 0x008800, 0x00ff00]);
set_color($tty, 3, [0x00d000, 0xd0d000, 0x888888, 0xffff00]);
set_color($tty, 4, [0x0000d0, 0x0000d0, 0x000088, 0x0000ff]);
set_color($tty, 5, [0xd000d0, 0xd000d0, 0x880088, 0xff00ff]);
set_color($tty, 6, [0x00d0d0, 0x00d0d0, 0x008888, 0x00ffff]);
set_color($tty, 7, [0xd0d0d0, 0xd0d0d0, 0x888888, 0xffffff]);



show $tty;

$tty->put_out("Hello, world!");

$tty->test_exec;


$vbox->pack_start($tty, 1, 1, 1);

$hbox = new Gtk::HBox 0, 1;
$vbox->pack_start($hbox, 0, 0, 1);
show $hbox;

$nled = new Gtk::Led;
$hbox->pack_start($nled, 1, 1, 1);
show $nled;

$cled = new Gtk::Led;
$hbox->pack_start($cled, 1, 1, 1);
show $cled;

$sled = new Gtk::Led;
$hbox->pack_start($sled, 1, 1, 1);
show $sled;

add_update_led $tty $nled, -num_lock;
add_update_led $tty $cled, -caps_lock;
add_update_led $tty $sled, -scroll_lock;

show $window;

$tty->grab_focus;

}

main Gtk;

