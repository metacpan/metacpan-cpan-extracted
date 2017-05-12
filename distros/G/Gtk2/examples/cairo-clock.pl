# This is a Perl port of the EggClockFace code by Davyd Madeley presented in
# <http://gnomejournal.org/article/34/writing-a-widget-using-cairo-and-gtk28>,
# and
# <http://gnomejournal.org/article/36/writing-a-widget-using-cairo-and-gtk28-part-2>.
#
# For the original C code:
#   Copyright (c) 2005-2006, Davyd Madeley <davyd@madeley.id.au>
#
# Unfortunately, I don't remember who wrote the Perl port.

package Egg::ClockFace;

use warnings;
use strict;

use Glib qw/TRUE FALSE/;
use Gtk2;
use Cairo;
use Math::Trig;

use Glib::Object::Subclass
	Gtk2::DrawingArea::,
	signals => {
		expose_event => \&expose,
	};

sub min { return ($_[0] < $_[1] ? $_[0] : $_[1]); }

sub draw
{
	my $self = shift;
	my $cr = $self->{cr};

	return FALSE unless $cr;

	my $width  = $self->allocation->width;
	my $height = $self->allocation->height;
	
	$cr->scale($width, $height);
	$cr->translate(0.5, 0.5);
	$cr->set_line_width($self->{line_width});
	
	$cr->save;
	$cr->set_source_rgba (0.337, 0.612, 0.117, 0.9);
	$cr->paint;
	$cr->restore;
	$cr->arc (0, 0, $self->{radius}, 0, 2 * Math::Trig::pi);
	$cr->save;
	$cr->set_source_rgba (1.0, 1.0, 1.0, 0.8);
	$cr->fill_preserve;
	$cr->restore;
	$cr->stroke_preserve;
	$cr->clip;

	for (1 .. 12) {
		my $inset = 0.05;

		$cr->save;
		$cr->set_line_cap('round');

		if ($_ % 3 != 0) {
			$inset *= 0.8;
			$cr->set_line_width(0.03);
		}

		$cr->move_to(($self->{radius} - $inset) * cos ($_ * Math::Trig::pi / 6),
		             ($self->{radius} - $inset) * sin ($_ * Math::Trig::pi / 6));
		$cr->line_to($self->{radius} * cos ($_ * Math::Trig::pi / 6),
		             $self->{radius} * sin ($_ * Math::Trig::pi / 6));

		$cr->stroke;
		$cr->restore;
	}

	my @time    = localtime;
	my $hours   = $time[2] * Math::Trig::pi / 6;
	my $minutes = $time[1] * Math::Trig::pi / 30;
	my $seconds = $time[0] * Math::Trig::pi / 30;
	
	$cr->save;
	$cr->set_line_cap('round');
	
	# seconds
	$cr->save;
	$cr->set_line_width($self->{line_width} / 3);
	$cr->set_source_rgba(1.0, 0.0, 0.0, 0.8);
	$cr->move_to(0, 0);
	$cr->line_to(     sin($seconds) * ($self->{radius} * .9),
	             -1 * cos($seconds) * ($self->{radius} * .9));
	$cr->stroke;
	$cr->restore;
	
	# minutes;
	$cr->set_source_rgba(0.7, 0.7, 0.7, 0.8);
	$cr->move_to(0, 0);
	$cr->line_to(     sin($minutes + $seconds / 60) * ($self->{radius} * 0.8),
	             -1 * cos($minutes + $seconds / 60) * ($self->{radius} * 0.8));
	$cr->stroke;
	
	# hours
	$cr->set_source_rgba(0.117, 0.337, 0.612, 0.9);
	$cr->move_to(0, 0);
	$cr->line_to(     sin($hours + $minutes / 12.0) * ($self->{radius} * 0.5),
	             -1 * cos($hours + $minutes / 12.0) * ($self->{radius} * 0.5));
	$cr->stroke;
	
	$cr->restore;
	
	# dot
	$cr->arc(0, 0,  $self->{line_width} / 3.0, 0, 2 * Math::Trig::pi);
	$cr->fill;

	return TRUE;
}

sub expose
{
	my ($self, $event) = @_;

	my $cr = Gtk2::Gdk::Cairo::Context->create($self->window);
	$cr->rectangle ($event->area->x,
			$event->area->y,
			$event->area->width,
			$event->area->height);
	$cr->clip;
	$self->{cr} = $cr;
	
	$self->draw;

	$self->{timeout} = Glib::Timeout->add(1000, sub {
			my $self = shift;
			
			my $alloc = $self->allocation;
			my $rect = Gtk2::Gdk::Rectangle->new(0, 0, $alloc->width, $alloc->height);
			$self->window->invalidate_rect($rect, FALSE);

			return TRUE;
		}, $self) unless $self->{timeout};

	return FALSE;
}

sub INIT_INSTANCE
{
	my $self = shift;

	$self->{line_width} = 0.05;
	$self->{radius}     = 0.42;
}

sub FINALIZE_INSTANCE
{
	my $self = shift;

	Glib::Source->remove($self->{timeout}) if $self->{timeout};
}

1;

package main;

use Gtk2 '-init';

my $window = Gtk2::Window->new('toplevel');
my $clock = Egg::ClockFace->new;

$window->add($clock);
$window->signal_connect(destroy => sub { Gtk2->main_quit; });

$window->show_all;

Gtk2->main;

0;
