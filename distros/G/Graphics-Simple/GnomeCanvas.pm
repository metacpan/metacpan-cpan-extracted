=head1 NAME

Graphics::Simple::GnomeCanvas -- implement Graphics::Simple using Gnome Canvas

=head1 SYNOPSIS

	use Graphics::Simple;
	# use those operations

=head1 DESCRIPTION

The module C<Graphics::Simple::GnomeCanvas> is an implementation
of the C<Graphics::Simple> API.

=head1 DEVICE-DEPENDENT OPERATIONS

=head2 stop

Waiting is implemented by waiting for a button click in any of the windows
managed by this module.

=cut

use strict;
print "GSGTK\n";

package Graphics::Simple::GnomeCanvas;
use strict;

use base 'Graphics::Simple::Window';

use Gtk; 
use Gnome;
init Gnome "simplegraph";

use vars qw/$BP/;
$BP = 0; # A global variable, button pressed to indicate continuing.

sub _construct {
	my($type, $x, $y) = @_;
	my $t = Gtk::Window->new('-toplevel');
	my $c = Gnome::Canvas->new();
	$c->set_usize($x,$y);
	$c->set_scroll_region(0,0,$x,$y);
	$t->add($c);
	$t->show_all;
	my $this = bless {
		C => $c,
	}, $type;
	$c->signal_connect("event", sub {
		my($w, $e) = @_;
		# print "WE: $w, $e: $e->{type}\n";
		if($e->{type} eq "button_press") {
			$BP ++; 
		}
	});
	return $this;
}

sub _line {
	my $this = shift;
	my $name = shift;
#	print "POI: @_\n";
	my $g = $this->{C}->root;
	my $l = $g->new($g, "Gnome::CanvasLine",
		points => [@_],
		fill_color => $this->{Current_Color},
		width_units => $this->{Current_LineWidth},
	);
	$this->{I}{$name} = $l;
}

sub _ellipse {
	my($this, $name, $x1, $y1, $x2, $y2) = @_;
	my $g = $this->{C}->root;
	my $c = $g->new($g, "Gnome::CanvasEllipse",
		x1 => $x1, y1 => $y1,
		x2 => $x2, y2 => $y2,
		outline_color => $this->{Current_Color},
		width_units => $this->{Current_LineWidth},
	);
	$this->{I}{$name} = $c;
}

sub _text {
	my($this, $name, $x, $y, $text) = @_;
#	print "T: $x $y $text\n";
	my $g = $this->{C}->root;
	my $c = $g->new($g, "Gnome::CanvasText",
		x => $x, y => $y,
		text => $text,
		fill_color => $this->{Current_Color},
	);
	$this->{I}{$name} = $c;
}

sub _remove {
	my($this, $n) = @_;
	(delete $this->{I}{$n})->destroy;
}

sub _image {
	my($this, $n, $x, $y, $w, $h, $d, $str) = @_;
	my $pixmap = Gtk::Gdk::Pixmap->new(
		$this->{C}->window,
		$w,
		$h,
		-1
	);
	my $gc = $this->{C}->style->fg_gc;
	if($depth == 1) {
		$pixmap->draw_gray_image(
			$gc,
			0,0,
			$w, $h,
			'NONE',
			$w
		);
	} elsif($depth == 3) {
		$pixmap->draw_rgb_image(
			$gc,
			0,0,
			$w, $h,
			'NONE',
			$w*3
		);
	} else {
		die("Depth must be 3");
	}
	my $wid = Gtk::Pixmap->new(
		$pm, undef
	);
	my $g = $this->{C}->root;
	my $c = $g->new($g, "Gnome::CanvasWidget",
		widget => $wid,
		x => $x,
		y => $y,
		# XXX width + height
	);
	$this->{I}{$name} = $c;
}

sub _clear {
	my($this) = @_;
	for(values %{$this->{I}}) {
		print "DEST $_\n";
		$_->destroy;
	}
	delete $this->{I};
}

sub _finish {
	my($this) = @_;
	$this->_wait();
}

# For now, just press button 1
sub _wait {
	my($this) = @_;
	$BP = 0;
	print "Waiting... Click a button in the window\n";
	Gtk->main_iteration while !$BP;
	print "Continuing...\n";
}


1;

=head1 AUTHOR

Copyright(C) Tuomas J. Lukka 1999. All rights reserved.
This software may be distributed under the same conditions as Perl itself.

=cut
