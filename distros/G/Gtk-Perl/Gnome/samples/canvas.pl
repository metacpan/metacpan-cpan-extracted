#!/usr/bin/perl

#TITLE: Gnome Canvas
#REQUIRES: Gtk Gnome GdkImlib

$NAME = 'Canvas';

use Gtk;
use Gtk::Gdk::ImlibImage;
use Gnome;
#init Gtk;
init Gnome "canvas.pl";

#DnD target data
@target_table = (
	{target => 'STRING', flags => 0, info => 0}
);

my($window) = new Gtk::Widget "Gtk::Window",
	-type => -toplevel,
	-visible => 1,
	-signal::destroy => sub {exit}
	;

#Gtk::Gdk::Rgb->init();
#Gtk::Widget->push_visual(Gtk::Gdk::Rgb->get_visual ());
#Gtk::Widget->push_colormap (Gtk::Gdk::Rgb->get_cmap ());
#my($canvas) = Gnome::Canvas->new_aa() ;
my($canvas) = Gnome::Canvas->new() ;

#$canvas->set_scroll_region(0,0,300,300);
$window->add($canvas);
$canvas->show;

#$canvas->set_size(300,300);
# kill 19,$$;

$canvas->drag_dest_set('all', ['copy', 'move'], @target_table);
$canvas->signal_connect('drag_data_received', \&canvas_drag_data);

$canvas->style->bg('normal', $canvas->style->white);

my $croot = $canvas->root;

my $cgroup = $croot->new($croot, "Gnome::CanvasGroup");
my $r = Gnome::CanvasItem->new($cgroup, "Gnome::CanvasRect",
	x1 => 0, x2 => 100, y1 => 0, y2 => 100,
	outline_color => "black",
	width_pixels => 2,
	);
my $rect = Gnome::CanvasItem->new($cgroup, "Gnome::CanvasRect",
	x1 => 5, x2 => 15, y1 => 5, y2 => 15,
	fill_color => "black",
	);
my $ell = $cgroup->new($cgroup, "Gnome::CanvasEllipse",
	x1 => 20, x2 => 40, y1 => 20, y2 => 40,
	fill_color => "red",
	outline_color => "blue",
	width_pixels => 3
	);

my ($cx, $cy);
my ($bp, $bpx, $bpy);
$cgroup->signal_connect("event", sub {
# 	print "EV: @_ \n(",(join "   ",%{$_[1]}),")\n";
	my($item, $event) = @_;
	if($event->{type} eq "button_press" and 
	   $event->{button} == 1) {
	   	$bp = 1; ($bpx, $bpy) = @{$event}{qw/x y/};
		print "PRESSED\n";
		$item->grab(['pointer-motion-mask', 'button-release-mask'], undef, $event->{'time'});
	} elsif($event->{type} eq "button_release" and 
	   $event->{button} == 1) {
	   	$bp = 0; 
		print "RELEASED\n";
		$item->ungrab($event->{'time'});
	} elsif($event->{type} eq "motion_notify" and $bp) {
		my $dx = $event->{x} - $bpx;
		my $dy = $event->{y} - $bpy;
		print "CX &c: $cx $cy $dx $dy\n";
		#$cgroup->move($dx, $dy);
		 $cgroup->set(x => $cx += $dx,
	 		     y => $cy += $dy);
		$bpx += $dx;
		$bpy += $dy;
	}
	return 1;
});

# my $poly = $cgroup->new($cgroup, "Gnome::CanvasPolygon",
# 	points => [30,30, 40,30, 50,40, 30,60],
# 	fill_color => "pink",
# 	outline_color => "blue",
# 	width_pixels => 3
# 	);


my $cgroup2 = $croot->new($croot, "Gnome::CanvasGroup");
my $txt = $cgroup2->new($cgroup2, "Gnome::CanvasText",
	x => 50,
	y => 50,
	text => "A string\nToinen rivi",
	fill_color => 'red',
	font => 'fixed',
	anchor => 'sw',
);

my $txt2 = $cgroup2->new($cgroup2, "Gnome::CanvasText",
	x => 80,
	y => 80,
	text => "A string\nToinen rivi",
	fill_color => 'steelblue',
	font_gdk => load Gtk::Gdk::Font('-*-helvetica-*'),
	anchor => 'center',
);

my $line = $cgroup2->new($cgroup2,"Gnome::CanvasLine",
 	points => [10,10, 40,30, 50,40, 30,80, 80, 80],
	fill_color => "green",
	width_pixels => 8,
	smooth => 1,
	spline_steps => 50
);

my $img = Gtk::Gdk::ImlibImage->load_image("save.xpm") || die;
my $imgitem = $cgroup2->new($cgroup2, "Gnome::CanvasImage",
	'image' => $img,
	'x' => 50,
	'y' => 50,
	width => $img->rgb_width,
	height => $img->rgb_height,
	);
my ($points) = $line->get('points');
print "POINTS: ", join(' ', @$points), "\n";

$img = $imgitem->get('image');
print "IMAGE: ", ref($img), "\n";

main Gtk;


sub canvas_drag_data {
	my ($canvas, $context, $x, $y, $data, $info, $time) = @_;

	if ( ($data->length() >= 0) && ($data->format() == 8) ) {
		print "creating text in canvas\n";
		$croot->new($croot, 'Gnome::CanvasText', text => $data->data(),
			'x' => $x, 'y' => $y, font => 'fixed');
		$context->finish(1, 0, $time);
	} else {
		$context->finish(0, 0, $time);
	}
}
