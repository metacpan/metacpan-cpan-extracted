#!/usr/bin/perl -w

#
# Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the full
# list)
# 
# This library is free software; you can redistribute it and/or modify it under
# the terms of the GNU Library General Public License as published by the Free
# Software Foundation; either version 2.1 of the License, or (at your option)
# any later version.
# 
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU Library General Public License for
# more details.
# 
# You should have received a copy of the GNU Library General Public License
# along with this library; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA.
#
# $Id$
#

# originally written in C by muppet in 2001 or 2002, i can't remember.
# ported from C to gtk2-perl 2003 by muppet

=doc

Create a new, self-drawing widget in Perl code.  This example shows how to
subclass Glib::Object/Gtk2::Widget types, how to override class closures,
how to define how much size you want to request for yourself, how to draw
shapes and text with Gdk, how to handle mouse events, why you'd want to
implement SET_PROPERTY for yourself, and how to emit signals.  And the
widget is actually functional, too.  :-)

=cut

package Histogram::Plot;

use warnings;
use strict;
use Glib qw/TRUE FALSE/;
use Gtk2;
use Gtk2::Gdk::Keysyms;

use constant MIN_CHART_WIDTH  => 256;
use constant MIN_CHART_HEIGHT => 100;

my %drag_info;
use constant DRAG_PAD => 2;

sub screen_to_threshold {
	my ($plot, $sx) = @_;
	my $val = ($sx - $plot->{chartleft}) * 256 / $plot->{chartwidth};
	return $val < 0 ? 0 : $val > 255 ? 255 : $val;
}
sub threshold_to_screen {
	$_[1] / 256.0 * $_[0]->{chartwidth} + $_[0]->{chartleft}
}


#
# Glib::Objects are special; they're not normal perl objects (although
# the bindings go out of their way to make them act like it).
#
# if you just want to add a new function for yourself to a Gtk2::DrawingArea,
# the stuff we're about to get into is not strictly necessary; you could just
# re-bless the object reference into the decendent class and add an @ISA for
# it, like normal perl.
#
# however, adding signals, properties, or virtual function overrides to a
# GObject-based class requires fiddling with a GObjectClass structure
# specific to that subclass.  if you added a new property to a re-blessed
# Glib::Object, *all* instances of that reblessed object's GObject parent
# would have the new property!  that's because you didn't create a new
# GObjectClass for that new subclass.
#
# in order to create a new type to which you can add signals and properties,
# and which will be indistinguishable from "normal" GObjects at the C level
# (which means you can pass it to other gtk functions), you need to 
# register your subclass with the Glib::Type subsystem.
#
# here, we're registering the current package as a new subclass of
# Gtk2::DrawingArea, and in the process adding a signal and a few
# object properties.
#
use Glib::Object::Subclass
	'Gtk2::DrawingArea',
	signals => {
		#
		# create a new signal...
		#
		threshold_changed => {
			method      => 'do_threshold_changed',
			flags       => [qw/run-first/],
			return_type => undef, # void return
			param_types => [], # instance and data are automatic
		},
		#
		# override some built-ins...  note that for this to work
		# there has to be a signal to go along with the virtual
		# function you want to override...
		#
		# i chose do_size_request to keep from having the normal
		# size_request method being called.
		size_request => \&do_size_request,
		# just to show it off...  you can use names, but you have
		# to use a qualified name, or it looks in the current package
		# at runtime, not setup time.
		expose_event => __PACKAGE__.'::expose_event',
		configure_event => \&configure_event,
		motion_notify_event => \&motion_notify_event,
		button_press_event => \&button_press_event,
		button_release_event => \&button_release_event,
		key_press_event => \&key_press_event,
		focus_in_event => \&handle_focus,
		focus_out_event => \&handle_focus,
	},
	properties => [
		Glib::ParamSpec->double ('threshold',
		                         'Threshold',
		                         'Diving line between above and below',
		                          0.0, 255.0, 127.0,
		                         [qw/readable writable/]),
		Glib::ParamSpec->boxed ('histogram',
		                        'Histogram Data',
		                        'Array reference containing histogram data',
		                        'Glib::Scalar',
		                        [qw/readable writable/]),
		Glib::ParamSpec->boolean ('continuous',
		                          'Continuous updates',
		                          'Emit the threshold_changed signal on every mouse event during drag, rather than just on release',
		                          FALSE,
		                          [qw/readable writable/]),
	],
;

#
# at the lowest level, new Glib::Objects are created by Glib::Object::new.
# that function creates the instance and calls the instance initializers
# for all classes in the object's lineage, from the parent to the descendant.
# if there's any setup you would need to do in a constructor, it goes here.
#
sub INIT_INSTANCE {
	my $plot = shift;
	warn "INIT_INSTANCE $plot";

	$plot->can_focus (TRUE);

	$plot->{threshold}       = 0;
	$plot->{histogram}       = [ 0..255 ];
	$plot->{pixmap}          = undef;
	$plot->{th_gc}           = undef;
	$plot->{dragging}        = FALSE;
	$plot->{continuous}      = FALSE;
	$plot->{origin_layout}   = $plot->create_pango_layout ("0.0%");
	$plot->{maxval_layout}   = $plot->create_pango_layout ("100.0%");
	$plot->{current_layout}  = $plot->create_pango_layout ("0");
	$plot->{maxscale_layout} = $plot->create_pango_layout ("255");
	$plot->{minscale_layout} = $plot->create_pango_layout ("0");
	$plot->{max}             = 0;

	$plot->{chartwidth}      = 0;
	$plot->{chartleft}       = 0;
	$plot->{bottom}          = 0;
	$plot->{height}          = 0;

	$plot->set_events ([qw/exposure-mask
			       leave-notify-mask
			       button-press-mask
			       button-release-mask
			       pointer-motion-mask
			       pointer-motion-hint-mask/]);
}


#
# whenever anybody tries to get the value of a gobject property belonging
# to this class, this function will be called.  note that this call
# signature is different from the C version -- here we return the requested
# value.
#
sub GET_PROPERTY {
	my ($plot, $pspec) = @_;
	if ($pspec->get_name eq 'threshold') {
		return $plot->{threshold};
	} elsif ($pspec->get_name eq 'histogram') {
		return $plot->{histogram};
	} elsif ($pspec->get_name eq 'continuous') {
		return $plot->{continuous};
	}
}

#
# whenever anybody tries to set the value of a gobject property belonging
# to this class, this function will be called.  the provided Glib::Object::Base
# method just stores the value in a hash key, but here we need to do other
# bits of work when a value is changed.
#
# note that this one also is changed from the C call signature; the order
# of the arguments has been swizzled to be more consistent with GET_PROPERTY.
#
sub SET_PROPERTY {
	my ($plot, $pspec, $newval) = @_;
	if ($pspec->get_name eq 'threshold') {
		$plot->set_plot_data ($newval, ());
	} elsif ($pspec->get_name eq 'histogram') {
		$plot->set_plot_data (undef, @$newval);
	} elsif ($pspec->get_name eq 'continuous') {
		$plot->{continuous} = $newval;
	}
}


sub calc_dims {
	my $plot = shift;

	my $context = $plot->{origin_layout}->get_context;
	my $fontdesc = $context->get_font_description;
	my $metrics = $context->get_metrics ($fontdesc, undef);

	$plot->{textwidth} = 5 * $metrics->get_approximate_digit_width
			   / Gtk2::Pango->scale; #PANGO_SCALE;
	$plot->{textheight} = ($metrics->get_descent + $metrics->get_ascent)
		            / Gtk2::Pango->scale; #PANGO_SCALE;
	
	$plot->{chartleft} = $plot->{textwidth} + 2;
	$plot->{chartwidth} = $plot->allocation->width - $plot->{chartleft};
	$plot->{bottom} = $plot->allocation->height - $plot->{textheight} - 3;
	$plot->{height} = $plot->{bottom};
}

# this gets called when the widget's parent container wants to know
# how much space we want.  it's important to note that this sub will be
# called from deep within the gtk library, not from perl code, which is
# why it had to be implemented as a class closure override.
# we modify the requisition passed to us.
sub do_size_request {
	my ($plot, $requisition) = @_;
	warn "in class override for $_[0]\::do_size_request";

	$requisition->width ($plot->{textwidth} + 2 + MIN_CHART_WIDTH);
	$requisition->height ($plot->{textheight} + MIN_CHART_HEIGHT);

	# chain up to the parent class.
	shift->signal_chain_from_overridden (@_);
}


sub expose_event {
	my ($plot, $event) = @_;

	$plot->window->draw_drawable ($plot->style->fg_gc($plot->state),
				      $plot->{pixmap},
				      $event->area->x, $event->area->y,
				      $event->area->x, $event->area->y,
				      $event->area->width, $event->area->height);
	return FALSE;
}

sub configure_event {
	my ($plot, $event) = @_;

	$plot->{pixmap} = Gtk2::Gdk::Pixmap->new ($plot->window,
	                                          $plot->allocation->width,
	                                          $plot->allocation->height,
	                                          -1); # same depth as window

	# update dims
	$plot->calc_dims;

	$plot->histogram_draw;

	return TRUE;
}

sub draw_th_marker {
	my ($plot, $w, $draw_text) = @_;

	my $threshold_screen = $plot->threshold_to_screen ($plot->{threshold});

	if (!$plot->{th_gc}) {
		$plot->{th_gc} = Gtk2::Gdk::GC->new ($plot->{pixmap});
		$plot->{th_gc}->copy ($plot->style->fg_gc ($plot->state));
		$plot->{th_gc}->set_function ('invert');
	}
	$w->draw_line ($plot->{th_gc},
		       $threshold_screen, 0,
		       $threshold_screen, $plot->{bottom});

	$plot->{current_layout}->set_text (sprintf '%d', $plot->{threshold});
	my ($textwidth, $textheight) = $plot->{current_layout}->get_pixel_size;
	$plot->{marker_textwidth} = $textwidth;

	# erase text
	$w->draw_rectangle ($plot->style->bg_gc($plot->state), 
			    TRUE,
			    $threshold_screen - $plot->{marker_textwidth} - 1,
			    $plot->{bottom} + 1,
			    # the extra 1 in width erases the focus ring
			    $plot->{marker_textwidth} + 2,
			    $textheight);

	if ($draw_text) {
		$w->draw_layout ($plot->{th_gc}, 
				 $threshold_screen - $plot->{marker_textwidth},
				 $plot->{bottom} + 1,
				 $plot->{current_layout});
		$plot->style->paint_focus
				($w,
				 $plot->state,
				 undef, # area
				 $plot,
				 undef, # detail
				 $threshold_screen
				    - $plot->{marker_textwidth},
				 $plot->{bottom} + 1,
				 $plot->{marker_textwidth} + 1,
				 $textheight)
			if $plot->has_focus;
	}
}

#
# the user can click either very near the vertical line of the marker
# or on (actually in the bbox of) the marker text.
#
sub marker_hit {
	my ($plot, $screen_x, $screen_y) = @_;

	my $screen_th = $plot->threshold_to_screen ($plot->{threshold});
	if ($screen_y > $plot->{bottom}) {
		# check for hit on text
		if ($screen_x > $screen_th - $plot->{marker_textwidth} &&
		    $screen_x <= $screen_th) {
			return $screen_th;
		}
	} else {
		# check for hit on line
		if ($screen_x > $screen_th - DRAG_PAD &&
		    $screen_x < $screen_th + DRAG_PAD) {
			return $screen_th;
		}
	}
	return undef;
}

sub button_press_event {
	my ($plot, $event) = @_;

	$plot->grab_focus if $plot->can_focus and not $plot->has_focus;

	return FALSE
		if ($event->button != 1 || not defined $plot->{pixmap});

	my $sx = $plot->marker_hit ($event->x, $event->y);
	return FALSE
		unless defined $sx;

	# erase the previous threshold line from the pixmap...
	$plot->{threshold_back} = $plot->{threshold};
	$plot->draw_th_marker ($plot->{pixmap}, FALSE);
	$plot->window->draw_drawable ($plot->style->fg_gc($plot->state),
				      $plot->{pixmap},
			$plot->threshold_to_screen ($plot->{threshold}) - $plot->{marker_textwidth}, 0,
			$plot->threshold_to_screen ($plot->{threshold}) - $plot->{marker_textwidth}, 0,
			$plot->{marker_textwidth} + 1, $plot->allocation->height);
	# and draw the new one on the window.
	$plot->draw_th_marker ($plot->window, TRUE);
	$plot->{dragging} = TRUE;

	$drag_info{offset_x} = 
		$plot->threshold_to_screen ($plot->{threshold}) - $event->x;

	return TRUE;
}

sub button_release_event {
	my ($plot, $event) = @_;

	return FALSE
		if ($event->button != 1 
		    || !$plot->{dragging}
		    || not defined $plot->{pixmap});

	# erase the previous threshold line from the window...
	$plot->draw_th_marker ($plot->window, FALSE);
	$plot->{threshold} = 
		$plot->screen_to_threshold ($event->x + $drag_info{offset_x});
	# and draw the new one on the pixmap.
	$plot->draw_th_marker ($plot->{pixmap}, TRUE);
	$plot->window->draw_drawable ($plot->style->fg_gc ($plot->state),
				      $plot->{pixmap},
				      0, 0, 0, 0,
				      $plot->allocation->width,
				      $plot->allocation->height);
	$plot->{dragging} = FALSE;

	# let any listeners know that if the threshold has changed
	$plot->signal_emit ("threshold-changed")
		if $plot->{threshold_back} != $plot->{threshold}
		   and not $plot->{continuous};

	return TRUE;
}

sub key_press_event {
	my ($plot, $event) = @_;
	my $increment;

	my $keyval = $event->keyval;
	if ($keyval == $Gtk2::Gdk::Keysyms{Up} ||
	    $keyval == $Gtk2::Gdk::Keysyms{KP_Up} ||
	    $keyval == $Gtk2::Gdk::Keysyms{Left} ||
	    $keyval == $Gtk2::Gdk::Keysyms{KP_Left}) {
		# just a jump to the left...
		$increment = -1;
	} elsif ($keyval == $Gtk2::Gdk::Keysyms{Down} ||
		 $keyval == $Gtk2::Gdk::Keysyms{KP_Down} ||
		 $keyval == $Gtk2::Gdk::Keysyms{Right} ||
		 $keyval == $Gtk2::Gdk::Keysyms{KP_Right}) {
		# and a step to the ri-i-ight
		$increment = 1;
	} else {
		$increment = 0;
	}

	if ($increment) {
		if ($event->state >= 'control-mask') {
			# Ctrl+Arrow jumps to the relevant extreme.
			$increment *= 256;
		} elsif ($event->state >= 'shift-mask') {
			# Shift+Arrow bumps by a larger increment.
			$increment *= 10;
		}

		my $newthresh = $plot->{threshold} + $increment;
		$newthresh = 0 if $newthresh < 0;
		$newthresh = 255 if $newthresh > 255;
		if ($newthresh != $plot->{threshold}) {
			# use set so the redraw happens correctly.
			$plot->set (threshold => $newthresh);
			# always emit.
			$plot->signal_emit ('threshold-changed');
		}

		return TRUE;

	} else {
		return FALSE;
	}
}

sub handle_focus {
	my $plot = shift;
	my $ret = $plot->signal_chain_from_overridden (@_);
	# erase
	$plot->draw_th_marker ($plot->{pixmap}, FALSE);
	# redraw
	$plot->draw_th_marker ($plot->{pixmap}, TRUE);
	return $ret;
}



my $sizer;

sub motion_notify_event {
	my ($plot, $event) = @_;

	my ($x, $y, $state);

	if ($event->is_hint) {
		(undef, $x, $y, $state) = $event->window->get_pointer;
	} else {
		$x = $event->x;
		$y = $event->y;
		$state = $event->state;
	}
	if ($plot->{dragging}) {
		return FALSE
			unless $state >= 'button1-mask'
			    and defined $plot->{pixmap};
		
		$plot->draw_th_marker ($plot->window, FALSE);
		
		$x += $drag_info{offset_x};
		
		# confine to valid region
		my $t = $plot->screen_to_threshold ($x);
		$x = $plot->threshold_to_screen (0) if $t < 0;
		$x = $plot->threshold_to_screen (255) if $t > 255;
		
		$plot->{threshold} = $plot->screen_to_threshold ($x);
		$plot->draw_th_marker ($plot->window, TRUE);

		$plot->signal_emit ("threshold-changed")
			if $plot->{continuous};

	} else {
		my $c = undef;
		my $sx = $plot->marker_hit ($x, $y);
		if (defined $sx) {
			$sizer = Gtk2::Gdk::Cursor->new ('GDK_SB_H_DOUBLE_ARROW')
				if not defined $sizer;
			$c = $sizer;
		}
		$plot->window->set_cursor ($c);
	}

	return TRUE;
}



sub histogram_draw {
	my $plot = shift;
	my $gc = $plot->style->fg_gc ($plot->state);

	# erase (the hard way)
	$plot->{pixmap}->draw_rectangle ($plot->style->bg_gc ($plot->state),
	                                 TRUE, 0, 0,
	                                 $plot->allocation->width,
	                                 $plot->allocation->height);

	if ($plot->{max} != 0 && scalar(@{$plot->{histogram}})) {
		##GdkPoint points[256+2];
		my @hist = @{ $plot->{histogram} };
		my @points = ();
		for (my $i = 0; $i < 256; $i++) {
			push @points,
				$i/256.0 * $plot->{chartwidth} + $plot->{chartleft},
				$plot->{bottom} - $plot->{height} * $hist[$i] / $plot->{max};
		}
		$plot->{pixmap}->draw_polygon ($gc, TRUE, @points,
		              $plot->allocation->width, $plot->{bottom} + 1,
		              $plot->{chartleft}, $plot->{bottom} + 1);
	}
	# mark threshold
	# should draw this after the scale...
	draw_th_marker ($plot, $plot->{pixmap}, TRUE);
	# the annotations
	$plot->{pixmap}->draw_line ($gc, 0, 0, $plot->{chartleft}, 0);
	$plot->{pixmap}->draw_line ($gc, 0, $plot->{bottom},
				    $plot->{chartleft}, $plot->{bottom});
	$plot->{pixmap}->draw_line ($gc, $plot->{chartleft}, $plot->{bottom}, 
				    $plot->{chartleft},
				    $plot->{bottom} + $plot->{textheight} + 1);
	$plot->{pixmap}->draw_line ($gc,
		       $plot->allocation->width - 1, $plot->{bottom},
		       $plot->allocation->width - 1, $plot->{bottom} + $plot->{textheight} + 1);
	$plot->{pixmap}->draw_layout ($gc,
			 $plot->{chartleft} - (1 + $plot->{textwidth}),
			 1, $plot->{maxval_layout});
	$plot->{pixmap}->draw_layout ($gc,
			 $plot->{chartleft} - (1 + $plot->{textwidth}),
			 $plot->{bottom} - 1 - $plot->{textheight}, 
			 $plot->{origin_layout});
	$plot->{pixmap}->draw_layout ($gc,
			 $plot->{chartleft} + 2, $plot->{bottom} + 1,
			 $plot->{minscale_layout});
}

#
# change the data displayed in the window, with all the necessary
# work to get it properly updated.
#
# @threshold: new threshold.  ignored if undef.
# @histogram: new histogram.  if not empty, copy to the histwin's
#             internal histogram cache.  MUST be 256 items long.
#
sub set_plot_data {
	my ($plot, $threshold, @hist) = @_;

	$plot->{threshold} = $threshold if defined $threshold;

	if (@hist) {
		my $total = 0;
		my $max = 0;
		for (my $i = 0; $i < 256; $i++) {
			$total += $hist[$i];
			$max = $hist[$i]
				if $hist[$i] > $max;
		}
		$plot->{max} = $max;
		$plot->{histogram} = \@hist;
		$plot->{maxval_layout}->set_text 
			( sprintf "%4.1f%%", (100.0 * $plot->{max}) / $total );
	}


	# update dims since text may have changed
	$plot->calc_dims;

	# if the pixmap doesn't exist, we haven't been put on screen yet.
	# don't bother drawing anything.
	if ($plot->{pixmap}) {
		$plot->histogram_draw;
		$plot->queue_draw;
	}
}

sub do_threshold_changed {
	warn "default threshold handler\n";
}

################
#
# public methods
#
# we inherit new from Glib::Object::Subclass, and all the stuff we'd need
# to get to is available as object properties, so, well, there's no work
# to do here.  :-)
#


##########################################################################
# now let's take that code for a test drive...
#
package main;

use Glib qw/TRUE FALSE/;
use Gtk2 qw/-init/;

my $window = Gtk2::Window->new;
$window->signal_connect (delete_event => sub { Gtk2->main_quit; FALSE });

my $vbox = Gtk2::VBox->new;
$window->add ($vbox);
$window->set_border_width (6);

#
# a nicely framed histogram plot with some cheesy data
#
my $plot = Histogram::Plot->new (
	threshold => 64,
	histogram => [ map { sin $_/256*3.1415 } (0..255) ]
);

my $frame = Gtk2::Frame->new;
$vbox->pack_start ($frame, TRUE, TRUE, 0);
$frame->add ($plot);
$frame->set_shadow_type ('in');

#
# a way to manipulate one of the properties...
#
my $check = Gtk2::CheckButton->new ("Continuous");
$vbox->pack_start ($check, FALSE, FALSE, 0);
$check->set_active ($plot->get ('continuous'));
$check->signal_connect (toggled => sub {
		$plot->set (continuous => $check->get_active);
		1;
		});

#
# do something fun when the threshold changes.
#
my $label = Gtk2::Label->new (sprintf 'threshold: %d',
                                       $plot->get ('threshold'));
$vbox->pack_start ($label, FALSE, FALSE, 0);

$plot->signal_connect (threshold_changed => sub {
	$label->set_text (sprintf 'threshold: %d', $plot->get('threshold'));
	});

#
# all systems go!
#
$window->show_all;
Gtk2->main;

# explicit clean up makes us see various messages on a debug build.
undef $plot;
undef $window;
