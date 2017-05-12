#!/usr/bin/perl -w

#
# Copyright (C) 1998 Cesar Miquel, Shawn T. Amundson, Mattias Grönlund
# Copyright (C) 2000 Tony Gale
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

# this was originally gtk-2.2.1/examples/calendar/calendar.c
# ported to gtk2-perl (and perl-ized) by rm

use strict;
use Gtk2;

use Glib ':constants';

use constant DEF_PAD => 10;
use constant DEF_PAD_SMALL => 5;

use constant TM_YEAR_BASE => 1900;

sub calendar_select_font
{
	my $calendar = shift;

	my $fsd = Gtk2::FontSelectionDialog->new ('Font Selection Dialog');
	$fsd->set_position('mouse');

	$fsd->set_font_name ($calendar->get_style->font_desc->to_string);

	$fsd->signal_connect ('response' => sub {
		my (undef, $response) = @_;
		if ($response eq 'ok') {
			my $font_name = $fsd->get_font_name;
			return unless $font_name;
			$calendar->modify_font
				(Gtk2::Pango::FontDescription->from_string
				 	($font_name));
		}
		$fsd->destroy;
	});

	$fsd->show;
}


sub calendar_set_signal_strings
{
	my $sig_ref = shift;
	my $new_sig = shift;

	$sig_ref->{prev2}->set_text($sig_ref->{prev}->get_text);
	$sig_ref->{prev}->set_text($sig_ref->{curr}->get_text);
	$sig_ref->{curr}->set_text($new_sig);
}

sub create_calendar
{
	my $window;
	my $vbox;
	my $vbox2;
	my $vbox3;
	my $hbox;
	my $hbbox;
	my $calendar;
	my @toggles;
	my $button;
	my $frame;
	my $separator;
	my $label;
	my $bbox;
	my $i;
  
    	my %signals = ();

	$window = Gtk2::Window->new("toplevel");
  	$window->set_title('GtkCalendar Example');
  
	$window->set_border_width(5);
	$window->signal_connect( 'destroy' => sub {
			Gtk2->main_quit;
		} );
	$window->set_resizable(FALSE);

	$vbox = Gtk2::VBox->new(FALSE, DEF_PAD);
	$window->add($vbox);

	#
	# The top part of the window, Calendar, flags and fontsel.
	#

	$hbox = Gtk2::HBox->new(FALSE, DEF_PAD);
	$vbox->pack_start($hbox, TRUE, TRUE, DEF_PAD);
  
	$hbbox = Gtk2::HButtonBox->new;
	$hbox->pack_start($hbbox, FALSE, FALSE, DEF_PAD);
	$hbbox->set_layout('spread');
	$hbbox->set_spacing(5);

	# Calendar widget
	$frame = Gtk2::Frame->new('Calendar');
	$hbbox->pack_start($frame, FALSE, TRUE, DEF_PAD);
	$calendar = Gtk2::Calendar->new;

	$calendar->mark_day(19);
	$frame->add($calendar);
	$calendar->display_options([]);

	$calendar->signal_connect( 'month_changed' => sub {
			my ($year, $month, $day) = $calendar->get_date; 
			calendar_set_signal_strings($_[1], 'month changed: '.
				sprintf("%02d/%d/%d", $month+1, $day, $year) );
		}, \%signals );
	$calendar->signal_connect( 'day_selected' => sub {
			my ($year, $month, $day) = $calendar->get_date; 
			calendar_set_signal_strings($_[1], 'day selected: '.
				sprintf("%02d/%d/%d", $month+1, $day, $year) );
		}, \%signals );
	$calendar->signal_connect( 'day_selected_double_click' => sub {
			my ($year, $month, $day) = $calendar->get_date; 
			calendar_set_signal_strings($_[1], 
				'day selected double click: '.
				sprintf("%02d/%d/%d", $month+1, $day, $year) );
		}, \%signals );
	$calendar->signal_connect( 'prev_month' => sub {
			my ($year, $month, $day) = $calendar->get_date; 
			calendar_set_signal_strings($_[1], 'prev month: '.
				sprintf("%02d/%d/%d", $month+1, $day, $year) );
		}, \%signals );
	$calendar->signal_connect( 'next_month' => sub {
			my ($year, $month, $day) = $calendar->get_date; 
			calendar_set_signal_strings($_[1], 'next month: '.
				sprintf("%02d/%d/%d", $month+1, $day, $year) );
		}, \%signals );
	$calendar->signal_connect( 'prev_year' => sub {
			my ($year, $month, $day) = $calendar->get_date; 
			calendar_set_signal_strings($_[1], 'prev year: '.
				sprintf("%02d/%d/%d", $month+1, $day, $year) );
		}, \%signals );
	$calendar->signal_connect( 'next_year' => sub {
			my ($year, $month, $day) = $calendar->get_date; 
			calendar_set_signal_strings($_[1], 'next year: '.
				sprintf("%02d/%d/%d", $month+1, $day, $year) );
		}, \%signals );

	$separator = Gtk2::VSeparator->new;
	$hbox->pack_start($separator, FALSE, TRUE, 0);

	$vbox2 = Gtk2::VBox->new(FALSE, DEF_PAD);
	$hbox->pack_start($vbox2, FALSE, FALSE, DEF_PAD);
  
	# Build the Right frame with the flags in

	$frame = Gtk2::Frame->new('Flags');
	$vbox2->pack_start($frame, TRUE, TRUE, DEF_PAD);
	$vbox3= Gtk2::VBox->new(TRUE, DEF_PAD_SMALL);
	$frame->add($vbox3);

	my @flags = (
		'Show Heading',
		'Show Day Names',
		'No Month Change',
		'Show Week Numbers',
		'Week Start Monday',
	);
	for( $i = 0; $i < 5; $i++ )
	{
		$toggles[$i] = Gtk2::CheckButton->new($flags[$i]);
		$toggles[$i]->signal_connect( 'toggled' => sub {
				my $j;
				my $opts = [];
				for($j = 0; $j < scalar(@flags); $j++ )
				{
					if( $toggles[$j]->get_active )
					{
						push @$opts, $flags[$j];
					}
				}
				$calendar->display_options($opts);
			});
		$vbox3->pack_start($toggles[$i], TRUE, TRUE, 0);
	}
	foreach (@flags)
	{
		$_ =~ s/\s/-/g;
		$_ = lc($_);
	}
	
	# Build the right font-button
	$button = Gtk2::Button->new('Font...');
	$button->signal_connect( 'clicked' => sub {
			calendar_select_font($_[1]);
		}, $calendar );
	$vbox2->pack_start($button, FALSE, FALSE, 0);

	#
	# Build the Signal-event part.
	#

	$frame = Gtk2::Frame->new('Signal events');
	$vbox->pack_start($frame, TRUE, TRUE, DEF_PAD);

	$vbox2 = Gtk2::VBox->new(TRUE, DEF_PAD_SMALL);
	$frame->add($vbox2);
  
	$hbox = Gtk2::HBox->new(FALSE, 3);
	$vbox2->pack_start($hbox, FALSE, TRUE, 0);
	$label = Gtk2::Label->new('Signal:');
	$hbox->pack_start($label, FALSE, TRUE, 0);
	$signals{curr} = Gtk2::Label->new('');
	$hbox->pack_start($signals{curr}, FALSE, TRUE, 0);

	$hbox = Gtk2::HBox->new(FALSE, 3);
	$vbox2->pack_start($hbox, FALSE, TRUE, 0);
	$label = Gtk2::Label->new('Previous Signal:');
	$hbox->pack_start($label, FALSE, TRUE, 0);
	$signals{prev} = Gtk2::Label->new('');
	$hbox->pack_start($signals{prev}, FALSE, TRUE, 0);

	$hbox = Gtk2::HBox->new(FALSE, 3);
	$vbox2->pack_start($hbox, FALSE, TRUE, 0);
	$label = Gtk2::Label->new('Second Previous Signal:');
	$hbox->pack_start($label, FALSE, TRUE, 0);
	$signals{prev2} = Gtk2::Label->new('');
	$hbox->pack_start($signals{prev2}, FALSE, TRUE, 0);

	$bbox = Gtk2::HButtonBox->new;
	$vbox->pack_start($bbox, FALSE, FALSE, 0);
	$bbox->set_layout('end');

	$button = Gtk2::Button->new('Close');
	$button->signal_connect( 'clicked' => sub {
			Gtk2->main_quit;
		} );
	$bbox->add($button);
	$button->set_flags('can-default');
	$button->grab_default;

	$window->show_all;
}


Gtk2->init;

create_calendar;

Gtk2->main;

exit 0;
