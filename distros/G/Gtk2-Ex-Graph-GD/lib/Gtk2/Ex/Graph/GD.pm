package Gtk2::Ex::Graph::GD;

our $VERSION = '0.04';

use strict;
use warnings;
use Data::Dumper;
use GD::Graph::bars;
use GD::Graph::pie;
use GD::Graph::lines;
use GD::Graph::linespoints;
use GD::Graph::area;
use Gtk2;
use Glib qw /TRUE FALSE/;

sub new {
	my ($class, $width, $height, $type) = @_;
	my $self  = {};
	bless ($self, $class);
	$type or $type = 'bars';
	$self->{graph} = undef;
	$self->{graphhash} = undef;
	$self->{graphtype} = $type;
	$self->{imagesize} = [$width, $height];
	$self->{eventbox} = $self->_create_eventbox;
	$self->{optionsmenu} = $self->_create_optionsmenu;
	$self->_set_type($type);
	$self->_init_tooltip;
	return $self;
}

sub signal_connect {
	my ($self, $signal, $callback) = @_;
	$self->{signals}->{$signal} = $callback;
}

sub _create_eventbox {
	my ($self) = @_;
	my $eventbox = Gtk2::EventBox->new;
	# $eventbox->add_events (['pointer-motion-mask', 'pointer-motion-hint-mask', 'button-press-mask']);
	$eventbox->add_events ('pointer-motion-mask');
	$eventbox->signal_connect ('motion-notify-event' => 
		sub {
			my ($widget, $event) = @_;
			my ($x, $y) = ($event->x, $event->y);
			my @imageallocatedsize = $self->{graphimage}->allocation->values;
			$x -= ($imageallocatedsize[2] - $self->{imagesize}->[0])/2;
			$y -= ($imageallocatedsize[3] - $self->{imagesize}->[1])/2;
			if ($self->{graphtype} eq 'bars') {
				my $hotspot = $self->_check_bars_hotspot($x,$y);
				if ($hotspot) {
					my ($measure, $xvalue, $yvalue) = @$hotspot;
					my $tooltipstring = $measure 
						? "($measure, $xvalue, $yvalue)" 
						: "($xvalue, $yvalue)";
					$self->_show_tooltip($tooltipstring);
					&{ $self->{signals}->{'mouse-over'} } ($hotspot)
							if $self->{signals}->{'mouse-over'};
				}
			} elsif ($self->{graphtype} eq 'lines' or $self->{graphtype} eq 'linespoints') {
				my $hotspot = $self->_check_lines_hotspot($x,$y);
				if ($hotspot) {
					my ($measure, $xvalue0, $yvalue0, $xvalue1, $yvalue1) = @$hotspot;
					my $tooltipstring = $measure 
						? "($measure, ($xvalue0, $yvalue0), ($xvalue1, $yvalue1))"
						: "(($xvalue0, $yvalue0), ($xvalue1, $yvalue1))";
					$self->_show_tooltip($tooltipstring);
					&{ $self->{signals}->{'mouse-over'} } ($hotspot)
							if $self->{signals}->{'mouse-over'};
				}
			}
		}
	);
	$eventbox->signal_connect ('button-press-event' => 
		sub {
			my ($widget, $event) = @_;
			my ($x, $y) = ($event->x, $event->y);
			my @imageallocatedsize = $self->{graphimage}->allocation->values;
			$x -= ($imageallocatedsize[2] - $self->{imagesize}->[0])/2;
			$y -= ($imageallocatedsize[3] - $self->{imagesize}->[1])/2;
			my $hotspot;
			if ($self->{graphtype} eq 'bars') {
				$hotspot = $self->_check_bars_hotspot($x,$y);
			} elsif ($self->{graphtype} eq 'lines' or $self->{graphtype} eq 'linespoints') {
				$hotspot = $self->_check_lines_hotspot($x,$y);
			}
			&{ $self->{signals}->{'clicked'} } ($hotspot)
					if $self->{signals}->{'clicked'} && $hotspot;
			return FALSE unless $event->button == 3;
			$self->{optionsmenu}->popup(
				undef, # parent menu shell
				undef, # parent menu item
				undef, # menu pos func
				undef, # data
				$event->button,
				$event->time
			);
		}
	);
	return $eventbox;
}

sub set {
	my ($self, %hash) = @_;
	$self->{graphhash} = \%hash;
	$self->{graph}->set(%hash);
}

sub _set_type {
	my ($self, $type) = @_;
	my ($width, $height) = @{$self->{imagesize}};
	$self->{graphtype} = $type;
	my $graph;
	if ($type eq 'bars') {
		$graph = GD::Graph::bars->new($width, $height);
	} elsif ($type eq 'lines') {
		$graph = GD::Graph::lines->new($width, $height);
	} elsif ($type eq 'linespoints') {
		$graph = GD::Graph::linespoints->new($width, $height);
	} elsif ($type eq 'area') {
		$graph = GD::Graph::area->new($width, $height);
	} elsif ($type eq 'pie') {
		$graph = GD::Graph::pie->new($width, $height);
	}
	$self->{graph} = undef;
	$self->{graph} = $graph;
}

sub _refresh {
	my ($self) = @_;
	$self->{graph}->set(%{$self->{graphhash}}) if $self->{graphhash};
	$self->set_legend(@{$self->{graphlegend}}) if $#{@{$self->{graphlegend}}} >= 0;
	$self->get_image($self->{graphdata});
}

sub _init_tooltip {
	my ($self) = @_;
	my $tooltip_label = Gtk2::Label->new;
	my $tooltip = Gtk2::Window->new('popup');
	$tooltip->set_decorated(0);
	$tooltip->set_position('mouse'); # We'll choose this to start with.
	$tooltip->modify_bg ('normal', Gtk2::Gdk::Color->parse('yellow')); # The obligatory yellow
	$tooltip->add($tooltip_label);
	$self->{tooltip}->{window} = $tooltip;
	$self->{tooltip}->{displayed} = FALSE;
	$self->{tooltip}->{label} = $tooltip_label;	
}

sub set_legend {
	my ($self, @legend_keys) = @_;
	return if ($self->{graphtype} eq 'pie');
	$self->{graph}->set_legend(@legend_keys);
	$self->{graphlegend} = \@legend_keys;
}

sub get_image {
	my ($self, $data) = @_;
	$self->{graphdata} = $data;
	my $graph = $self->{graph};
	$graph->plot($data) or warn $graph->error;
	my $loader = Gtk2::Gdk::PixbufLoader->new;
	$loader->write ($graph->gd->png);
	$loader->close;
	my $image = Gtk2::Image->new_from_pixbuf($loader->get_pixbuf);
	$self->{graphimage} = $image;
	my $hotspotlist;
	if ($self->{graphtype} eq 'bars' or
		$self->{graphtype} eq 'lines' or
		$self->{graphtype} eq 'linespoints') {
		foreach my $hotspot ($graph->get_hotspot) {
			push @$hotspotlist, $hotspot if $hotspot;
		}
	}
	$self->{hotspotlist} = $hotspotlist;
	my $eventbox = $self->{eventbox};
	my @children = $eventbox->get_children;
	foreach my $child (@children) {
		$eventbox->remove($child);
	}
	$eventbox->add ($image);

	$eventbox->signal_connect ('button-press-event' => 
		sub {
			my ($widget, $event) = @_;
			return TRUE;
			return FALSE unless $event->button == 3;
			$self->{optionsmenu}->popup(
				undef, # parent menu shell
				undef, # parent menu item
				undef, # menu pos func
				undef, # data
				$event->button,
				$event->time
			);
		}
	);	
	$eventbox->show_all;
	return $eventbox;
}

sub _show_tooltip {
	my ($self, $tooltipstring) = @_;
	$self->{tooltip}->{label}->set_label($tooltipstring);
	if (!$self->{tooltip}->{displayed}) {
		$self->{tooltip}->{window}->show_all;
		my ($thisx, $thisy) = $self->{tooltip}->{window}->window->get_origin;
		# I want the window to be a bit away from the mouse pointer.
		# Just a personal choice
		$self->{tooltip}->{window}->move($thisx, $thisy-20);
		$self->{tooltip}->{displayed} = TRUE;
	}	
}

sub _check_lines_hotspot {
	my ($self, $x, $y) = @_;
	my $i=0;
	my $hotspotlist = $self->{hotspotlist};
	foreach my $datameasure (@$hotspotlist){
		my $j=0;
		foreach my $hotspot (@$datameasure) {
			my ($name, @coords) = @$hotspot;
			if (_on_the_line($x, $y, @coords)) {
				my $xvalue0 = $self->{graphdata}->[0]->[$j-1];
				my $yvalue0 = $self->{graphdata}->[$i+1]->[$j-1];
				my $xvalue1 = $self->{graphdata}->[0]->[$j];
				my $yvalue1 = $self->{graphdata}->[$i+1]->[$j];
				my $measure = $self->{graphlegend}->[$i];
				return [$measure, $xvalue0, $yvalue0, $xvalue1, $yvalue1];
			}
			$j++;
		} 
		$i++;	
	}
	$self->{tooltip}->{window}->hide;
	$self->{tooltip}->{displayed} = FALSE;
}

sub _on_the_line {
	my ($x, $y, @linecoords) = @_;
	if (($x <= $linecoords[0] and  $x <= $linecoords[2]) or
		($x >= $linecoords[0] and  $x >= $linecoords[2]) or
		($y <= $linecoords[1] and  $y <= $linecoords[3]) or
		($y >= $linecoords[1] and  $y >= $linecoords[3]) ){
		return FALSE;
	}
	my $slope_diff = 
		($linecoords[1]-$linecoords[3])/($linecoords[0]-$linecoords[2]) 
		- ($linecoords[3]-$y)/($linecoords[2]-$x);
	if ($slope_diff > -0.1 and $slope_diff < 0.1) {
		return TRUE;
	}
	return FALSE;	
}

sub _check_bars_hotspot {
	my ($self, $x, $y) = @_;
	my $i=0;
	my $hotspotlist = $self->{hotspotlist};
	foreach my $datameasure (@$hotspotlist){
		my $j=0;
		foreach my $hotspot (@$datameasure) {			
			my ($name, @coords) = @$hotspot;
			if ($x >= $coords[0] && $x <= $coords[2] && $y >= $coords[1] && $y <= $coords[3]) {
				my $xvalue = $self->{graphdata}->[0]->[$j];
				my $yvalue = $self->{graphdata}->[$i+1]->[$j];
				my $measure = $self->{graphlegend}->[$i];
				return [$measure, $xvalue, $yvalue];
			} 
			$j++;	
		}
		$i++;
	}
	$self->{tooltip}->{window}->hide;
	$self->{tooltip}->{displayed} = FALSE;
}

sub _create_optionsmenu {
	my ($self) = @_;
	my $menu = Gtk2::Menu->new();

	my $bars = Gtk2::MenuItem->new("bars");
	my $lines = Gtk2::MenuItem->new("lines");
	my $linespoints = Gtk2::MenuItem->new("lines with points");
	my $area = Gtk2::MenuItem->new("area");
	my $pie = Gtk2::MenuItem->new("pie");
	my $cumulate = Gtk2::MenuItem->new("cumulate");

	$bars->signal_connect(activate => 
		sub { 
			$self->_set_type('bars');
			$self->_refresh;
		}
	);
	$lines->signal_connect(activate => 
		sub { 
			$self->_set_type('lines');
			$self->_refresh;
		}
	);
	$linespoints->signal_connect(activate => 
		sub { 
			$self->_set_type('linespoints');
			$self->_refresh;
		}
	);
	$area->signal_connect(activate => 
		sub { 
			$self->_set_type('area');
			$self->_refresh;
		}
	);
	$pie->signal_connect(activate => 
		sub { 
			$self->_set_type('pie');
			$self->_refresh;
		}
	);
	$cumulate->signal_connect(activate => 
		sub {
			if (exists($self->{graphhash}->{cumulate})) {
				$self->{graphhash}->{cumulate} = !$self->{graphhash}->{cumulate};
			} else {
				$self->{graphhash}->{cumulate} = TRUE;
			}
			$self->_set_type($self->{graphtype});
			$self->_refresh;
		}
	);
	
	$bars->show();
	$lines->show();
	$linespoints->show();
	$area->show();
	$pie->show();
	$cumulate->show();

	$menu->append($bars);
	$menu->append($lines);
	$menu->append($linespoints);
	$menu->append($area);
	$menu->append($pie);
	$menu->append($cumulate);
	
	return $menu;
}

1;

__END__

=head1 NAME

Gtk2::Ex::Graph::GD is a thin wrapper around the good-looking GD::Graph module. Wrapping
using Gtk2 allows the GD::Graph object to respond to events such as mouse movements.

This allows functionalities such as mouse-over-tooltip and right-click menus on the Graph.

=head1 SYNOPSIS

	my $graph = Gtk2::Ex::Graph::GD->new(500, 300, 'bars');
	my $data = GD::Graph::Data->new([
		["1st","2nd","3rd","4th","5th","6th","7th", "8th", "9th"],
		[    1,    2,    5,    6,    3,  1.5,    1,     3,     4],
		[    1.4,  4,   15,    6,    13,  1.5,    11,     3,     4],
	]) or die GD::Graph::Data->error;
	my $image = $graph->get_image($data);
	my $window = Gtk2::Window->new;
	$window->signal_connect(destroy => sub { Gtk2->main_quit; });
	$window->set_default_size(700, 500);
	$window->add($image);
	$window->show_all;
	Gtk2->main;

=head1 FUNCTIONS

=head2 $graph = Gtk2::Ex::Graph::GD->new($width, $height, $type)

Creates a new Gtk2::Ex::Graph::GD object with the specified dimensions and type.
The type can be 'bars', 'lines', 'pie'.

	$graph = Gtk2::Ex::Graph::GD->new(500, 300, 'bars');

=head2 $graph->set($attr1 => $value1, $attr2 => $value2,...)

This is just a thin wrapper on the C<GD::Graph->set> method. 
All the properties set here go straight into the GD::Graph::* object created inside.
Therefore, any property acceptable to the GD::Graph::* object can be passed through here

	$graph->set (
		x_label         => 'X Label',
		y_label         => 'Y label',
		title           => 'A Simple Bar Chart',
		bar_spacing     => 1,
		shadowclr       => 'dred',
		transparent     => 0,
	);

=head2 $graph->set_legend(@legend_keys)

This is just a thin wrapper on the C<GD::Graph->set_legend> method. However, this method
extracts the C<@legend_keys> and uses them in the mouse-over tooltip text.

	my @legend_keys = ('First', 'Second');
	$graph->set_legend(@legend_keys);

=head2 $graph->get_image($data)

The C<$data> object used here is a C<GD::Graph::Data> object. This method internally calls
the C<GD::Graph->plot($data)> and then exports the output into a png. The png is then wrapped
into a Gtk2::Image and then into a Gtk2::EventBox and returned here. You can go on and
pack this C<$image> into the window.

	my $image = $graph->get_image($data);

=head2 signal_connect($signal, $callback)

Two signals are supported

	'mouse-over'
	'clicked'
	
You can bind to these signals just like how you would bind to any normal Gtk2 widget signal.

	$graph->signal_connect ('clicked' =>
		sub {
			print Dumper @_;
		}
	);
	
If the graph is of type C<bars> then the return values are

	my ($measure, $xvalue, $yvalue) = @_

If the graph is of type C<lines> then the return values are

	my ($measure, $xvalue0, $yvalue0, $xvalue1, $yvalue1) = @_

These callbacks are not currently supported for other graph types. I may add them later on.
=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Ofey Aikon

This library is free software; you can redistribute it and/or modify it under 
the terms of the GNU Library General Public License as published by the 
Free Software Foundation; 

This library is distributed in the hope that it will be useful, but WITHOUT ANY 
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
PARTICULAR PURPOSE. See the GNU Library General Public License for more details.

You should have received a copy of the GNU Library General Public License along 
with this library; if not, write to the 
Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307 USA.

=head1 ACKNOWLEDGEMENTS

To the wonderful gtk-perl-list.

=head1 SEE ALSO

GD::Graph

=cut
