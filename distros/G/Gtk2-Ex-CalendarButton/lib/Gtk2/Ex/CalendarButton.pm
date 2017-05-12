package Gtk2::Ex::CalendarButton;

our $VERSION = '0.01';

use strict;
use warnings;
use Gtk2 '-init';
use Glib qw /TRUE FALSE/;
use Data::Dumper;

sub new {
	my ($class, $date) = @_;
	my $self  = {};
	bless ($self, $class);
	$self->{button} = Gtk2::Button->new;
	$self->{calendar} = Gtk2::Calendar->new;
    $self->{date} = undef;
    if ($date) {
        $self->set_date($date);
    }
    else {
        $self->_update_button_label;
    }
	my $calwindow = $self->_create_calendar_window();
	$self->{button}->signal_connect('clicked' => 
		sub {
			my ($self, $event) = @_;
			$calwindow->set_position('mouse');
			$calwindow->show_all;
		}
	);
	return $self;
}

sub signal_connect {
    my ($self, $signal, $callback) = @_;
    $self->{$signal} = $callback;
}

sub get_button {
    my ($self) = @_;
    return $self->{button};
}

sub get_calendar {
    my ($self) = @_;
    return $self->{calendar};
}

sub get_date {
    my ($self) = @_;
    return $self->{date};
}

sub set_date {
    my ($self, $date) = @_;
    $self->{date} = $date;
    my ($year, $month, $day) = @$date;
    my $cal = $self->{calendar};
    $cal->select_month($month, $year);
    $cal->select_day($day);
    $self->_update_button_label;
}

sub _update_button_label {
    my ($self) = @_;
	my ($year, $month, $day) = $self->{calendar}->get_date;
	$self->{date} = [$year, $month, $day];
	$month = _month()->[$month];
	$self->{button}->set_label("$month $day\, $year"); 
	&{$self->{'date-changed'}}($self) if $self->{'date-changed'};
}

sub _create_calendar_window {
    my ($self) = @_;
	my $vbox = Gtk2::VBox->new;
	my $ok = Gtk2::Button->new_from_stock('gtk-ok');
	my $cancel= Gtk2::Button->new_from_stock('gtk-cancel');
	my $hbox = Gtk2::HBox->new;
	$hbox->pack_start($ok, TRUE, TRUE, 0);
	$hbox->pack_start($cancel, TRUE, TRUE, 0);
	$vbox->pack_start($self->{calendar}, TRUE, TRUE, 0);
	$vbox->pack_start($hbox, TRUE, TRUE, 0);
	my $calwindow = Gtk2::Window->new('popup');
	$calwindow->add($vbox);
    $ok->signal_connect('clicked' => 
		sub {
			my ($okself, $event) = @_;
            $self->_update_button_label;
			$calwindow->hide;
		}
	);
    $cancel->signal_connect('clicked' => 
		sub {
			my ($self, $event) = @_;
			$calwindow->hide;
		}
	);		
	return $calwindow;   
}

sub _month {
	return [
		'Jan',
		'Feb',
		'Mar',
		'Apr',
		'May',
		'Jun',
		'Jul',
		'Aug',
		'Sep',
		'Oct',
		'Nov',
		'Dec',
	];
}

=head1 NAME

Gtk2::Ex::CalendarButton - I realized that I was constantly re-creating a simple widget that will pop-up
and Gtk2::Calendar when clicked. Just like the datetime display on your desktop taskbar. This package is
my attempt to extract the portion of code required to create a button-click-calender.

=head1 SYNOPSIS

        my $calbutton = Gtk2::Ex::CalendarButton->new([2007,3,14]);
        my $window = Gtk2::Window->new;
        $window->signal_connect(destroy => sub { Gtk2->main_quit; });
        $window->add($calbutton->get_button);

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 get_button

=head2 get_calendar

=head2 get_date

=head2 set_date

=head1 AUTHOR

Ofey Aikon, C<< <ofey.aikon at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Ofey Aikon, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Gtk2::Ex::CalendarButton
