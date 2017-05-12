
use Gtk;
use Gtk::Atoms;

use PDL;

#TITLE: PDL
#REQUIRES: Gtk PDL

init Gtk;

sub bbox_widget_destroy {
	my($widget, $todestroy) = @_;
	
}

sub destroy_tooltips {
#	print "Destroy_tooltips: ", Dumper(\@_);
	my($widget, $window) = @_;
	#$$window->{tooltips}->unref;
	$$window = undef;
}


sub cursor_expose_event {
	my($widget, $event, $data) = @_;
	my($darea, $drawable, $black_gc, $gray_gc, $white_gc, $max_width, $max_height);
	
	$darea = $widget;
	$drawable = $widget->window;
	$white_gc = $widget->style->white_gc;
	$gray_gc = $widget->style->bc_gc('normal');
	$black_gc = $widget->style->black_gc;
	$max_width = $widget->allocation->{width};
	$max_height = $widget->allocation->{width};
	
	$drawable->draw_rectangle($white_gc, 1, 0, 0, $max_width, $max_height/2);
	$drawable->draw_rectangle($black_gc, 1, 0, $max_height/2, $max_width, $max_height/2);
	$drawable->draw_rectangle($gray_gc, 1, $max_width/3, $max_height/3, $max_width/3, $max_height/3);
	
	1;
}

sub destroy_window {
	my($widget, $windowref, $w2) = @_;
	$$windowref = undef;
	$w2 = undef if defined $w2;
	0;
}


my($color_idle)=0;
my($color_count)=1;

$color_buf = zeroes(byte,3,64,64);

{
	my($i,$j);
	for($i=0;$i<64;$i++) {
		for($j=0;$j<64;$j++) {
			$color_buf->set(0, $i, $j, $i);
			$color_buf->set(1, $i, $j, $i+(64-$j));
			$color_buf->set(2, $i, $j, $j);
		}
	}
}

sub color_idle_func {
	my($preview) = @_;
	my($i,$j,$k,$buf);
	
	for($i=0;$i<64;$i++)
	{
		my($slice) = $color_buf->slice(":,:,$i");
		$preview->draw_row(${$slice->get_dataref},0,$i,64);
	}
	
	my($slice) = $color_buf->slice("0:2:2,:,:");
	$slice ++;
	$slice %= 256;
	
	$preview->draw(undef);
	
	return 1;
}


sub color_preview_destroy {
	my($widget,$windowref) = @_;
	if ($color_idle) {
		Gtk->idle_remove($color_idle);
	}
	$color_idle=0;
	
	destroy_window($window, $windowref);
}

sub create_color_preview {
	my($preview,$buf,$i,$j,$k);
	
	if (not defined $cp_window) {
		Gtk::Widget->push_visual(Gtk::Preview->get_visual);
		Gtk::Widget->push_colormap(Gtk::Preview->get_cmap);
		
		$cp_window = new Gtk::Window "toplevel";
		$cp_window->signal_connect("destroy", \&color_preview_destroy, \$cp_window);
		$cp_window->signal_connect("delete_event", \&color_preview_destroy, \$cp_window);
		$cp_window->set_title("test");
		$cp_window->border_width(10);
		
		$preview = new Gtk::Preview("color");
		$preview->size(64,64);
		$cp_window->add($preview);
		$preview->show;
		
		$color_idle = Gtk->idle_add(\&color_idle_func, $preview);
		
		Gtk::Widget->pop_colormap;
		Gtk::Widget->pop_visual;
		
	}
	if (!visible $cp_window) {
		show $cp_window;
	} else {
		destroy $cp_window;
	}
}

my($gray_idle)=0;
my($gray_count)=1;

$gray_buf = zeroes(byte,64,64);

{
	my($i,$j);
	for($i=0;$i<64;$i++) {
		for($j=0;$j<64;$j++) {
			$gray_buf->set($i,$j, $i+$j);
		}
	}
}

sub gray_idle_func {
	my($preview) = @_;
	my($i,$j,$k,$buf);
	
	$gray_buf ++;
	$gray_buf %= 256;
	
	for($i=0;$i<64;$i++)
	{
		my($line) = $gray_buf->slice(":,$i");
		$preview->draw_row(${$line->get_dataref},0,$i,64);
	}
	
	$preview->draw(undef);
	
	return 1;
}


sub gray_preview_destroy {
	my($widget,$windowref) = @_;
	if ($gray_idle) {
		Gtk->idle_remove($gray_idle);
	}
	$gray_idle=0;
	
	destroy_window($window, $windowref);
}

sub create_gray_preview {
	my($preview,$buf,$i,$j,$k);
	
	if (not defined $gp_window) {
		Gtk::Widget->push_visual(Gtk::Preview->get_visual);
		Gtk::Widget->push_colormap(Gtk::Preview->get_cmap);
		
		$gp_window = new Gtk::Window "toplevel";
		$gp_window->signal_connect("destroy", \&gray_preview_destroy, \$gp_window);
		$gp_window->signal_connect("delete_event", \&gray_preview_destroy, \$gp_window);
		$gp_window->set_title("test");
		$gp_window->border_width(10);
		
		$preview = new Gtk::Preview("grayscale");
		$preview->size(64,64);
		$gp_window->add($preview);
		$preview->show;
		
		#for($i=0;$i<64;$i++)
		#{
		#	for($j=0;$j<64;$j++)
		#	{
		#		vec($buf,$j,8) = $i+$j;
		#	}
		#	$preview->draw_row($buf, 0, $i, 64);
		#}
		
		$gray_idle = Gtk->idle_add(\&gray_idle_func, $preview);
		
		Gtk::Widget->pop_colormap;
		Gtk::Widget->pop_visual;
		
	}
	if (!visible $gp_window) {
		show $gp_window;
	} else {
		destroy $gp_window;
	}
}

sub create_main_window {
	my(@buttons,$window,$box1,$scw, $box2,$button,$separator, $buffer, $label);
	@buttons = (
      	"color preview", \&create_color_preview,
      	"gray preview", \&create_gray_preview,
	);
	
	$window = new Gtk::Window('toplevel');
	$window->set_name("PDL tests");
	$window->set_uposition(20, 20);
	$window->set_usize(200, -1);
	
	$window->signal_connect("destroy" => \&Gtk::main_quit);
	$window->signal_connect("delete_event" => \&Gtk::false);

	$box1 = new Gtk::VBox(0, 0);
	$window->add($box1);
	$box1->show;
	
	$buffer = sprintf "Gtk+ v%d.%d", Gtk->major_version, Gtk->minor_version;
	
	if (Gtk->micro_version > 0) {
		$buffer .= sprintf ".%d", Gtk->micro_version;
	}
	
	$label = new Gtk::Label $buffer;
	show $label;
	$box1->pack_start($label, 0, 0, 0);

	$scw = new Gtk::ScrolledWindow(undef, undef);
	$scw->set_policy('automatic', 'automatic');
	$scw->show;
	$scw->border_width(10);
	
	$box1->pack_start($scw, 1, 1, 0);

	$box2 = new Gtk::VBox(0, 0);
	$box2->show;
	$box2->border_width(10);
	$scw->add_with_viewport($box2);
	
	for($i=0;$i<@buttons;$i+=2) {
		$button = new Gtk::Button($buttons[$i]);
		if (defined $buttons[$i+1]) {
			$button->signal_connect(clicked => $buttons[$i+1]);
		} else {
			$button->set_sensitive(0);
		}
		$box2->pack_start($button, 1, 1, 0);
		show $button;
	}
	
	$separator = new Gtk::HSeparator;
	$box1->pack_start($separator, 0, 1, 0);
	$separator->show;
	
	$box2 = new Gtk::VBox(0, 10);
	$box2->border_width(10);
	$box1->pack_start($box2, 0, 1, 0);
	$box2->show();
	
	$button = new Gtk::Button "close";
	signal_connect $button "clicked", \&do_exit;
	$box2->pack_start($button, 1, 1, 0);
	$button->can_default(1);
	$button->grab_default();
	$button->show;
	
	$window->show;
	
}

parse Gtk::Rc "testgtkrc";

create_main_window;

main Gtk;
