package Gtk2::Ex::DateRange;

our $VERSION = '0.07';

use strict;
use warnings;
use Glib qw(TRUE FALSE);
use Data::Dumper;
use Gtk2::Ex::PopupWindow;
use Carp;

sub new {
	my ($class, $preselected) = @_;
	my $self  = {};
	bless ($self, $class);
	$self->{widget} = $self->_get_widget;
	return $self;
}

sub get_model {
	my ($self) = @_;
	return $self->{model};
}

sub set_model {
	my ($self, $model) = @_;
	if (!$model) {
		$self->_clear;
		return;
	}
	$self->{freezesignals} = TRUE;
	my $commandchoices = $self->{commandchoices};
	my $joinerchoices  = $self->{joinerchoices};
	my $i = 0;	my $commandhash = 	{ map { $_ => $i++ } @$commandchoices };
	   $i = 0;	my $joinerhash  = 	{ map { $_ => $i++ } @$joinerchoices  };
	_model_error_check($commandhash, $joinerhash, $model);
	
	$self->{commandcombo1}->set_active($commandhash->{$model->[0]});
	_set_calendar_date($self->{calendar1}, $model->[1]);
	_update_date_label($self->{calendar1}, $self->{datelabel1});
	if ($#{@$model} == 1) {
		$self->{freezesignals} = TRUE;
		$self->{joinercombo}->set_active(0);
		$self->{commandcombo2}->set_active(-1);
		$self->{datelabel2}->set_label('(select a date)');
		$self->{freezesignals} = FALSE;
		&{ $self->{signals}->{'changed'} } if $self->{signals}->{'changed'};
		return;
	}
	
	$self->{joinercombo}->set_active($joinerhash->{$model->[2]});
	
	$self->{commandcombo2}->set_active($commandhash->{$model->[3]});
	_set_calendar_date($self->{calendar2}, $model->[4]);
	_update_date_label($self->{calendar2}, $self->{datelabel2});
	
	$self->{freezesignals} = FALSE;
	&{ $self->{signals}->{'changed'} } if $self->{signals}->{'changed'};		
}

sub to_sql_condition {
	my ($self, $fieldname, $model) = @_;
	my $conversion = {
		'before' => ' < ',
		'after' => ' > ',
		'on or before' => ' <= ',
		'on or after' => ' >= ',
	};
	return undef if $#{@$model} < 1;
	if ($#{@$model} >= 1 and $#{@$model} < 4) {
		my $str =
			 $fieldname
			.$conversion->{$model->[0]}
			.'\''
			.$model->[1]
			.'\'';
		return $str;
	}
	if ($#{@$model} == 4) {
		my $str1 =
			 $fieldname
			.$conversion->{$model->[0]}
			.'\''
			.$model->[1]
			.'\'';
		my $str2 = $model->[2];
		my $str3 =
			 $fieldname
			.$conversion->{$model->[3]}
			.'\''
			.$model->[4]
			.'\'';
		my $str = "( $str1 $str2 $str3 )";
		return $str;
	}	
}

sub _clear {
	my ($self) = @_;
	$self->{freezesignals} = TRUE;
	$self->{commandcombo1}->set_active(-1);
	$self->{datelabel1}->set_label('(select a date)');
	$self->{datelabelbox1}->set_sensitive(FALSE);
	$self->{joinercombo}->set_active(0);
	$self->{joinercombo}->set_sensitive(FALSE);
	$self->{commandcombo2}->set_active(-1);
	$self->{datelabel2}->set_label('(select a date)');
	$self->{model} = undef;
	$self->{freezesignals} = FALSE;
	&{ $self->{signals}->{'changed'} } if $self->{signals}->{'changed'};
}

sub attach_popup_to {
	my ($self, $parent) = @_;
	my $popupwindow = Gtk2::Ex::PopupWindow->new($parent);
	$popupwindow->set_move_with_parent(TRUE);
	my $okbutton = Gtk2::Button->new_from_stock('gtk-ok');
	$okbutton->signal_connect ('button-release-event' => 
		sub {
			$popupwindow->hide;
		}
	);
	my $clearbutton = Gtk2::Button->new_from_stock('gtk-clear');
	$clearbutton->signal_connect ('button-release-event' => 
		sub {
			$self->_clear;
		}
	);
	my $hbox = Gtk2::HBox->new(TRUE, 0);
	$hbox->pack_start ($clearbutton, TRUE, TRUE, 0); 	
	$hbox->pack_start ($okbutton, TRUE, TRUE, 0); 	
	my $vbox = Gtk2::VBox->new (FALSE, 0);
	$vbox->pack_start ($self->{widget}, TRUE, TRUE, 0);
	$vbox->pack_start ($hbox, FALSE, FALSE, 0); 	
	my $frame = Gtk2::Frame->new;
	$frame->add($vbox);
	$self->{popup} = $popupwindow;
	$popupwindow->{window}->add($frame);
	return $popupwindow;	
}

sub signal_connect {
	my ($self, $signal, $callback) = @_;
	$self->{signals}->{$signal} = $callback;
}

sub _model_error_check {
	my ($commandhash, $joinerhash, $model) = @_;
	return warn "Model should contain 2 or 5 parameters" 
		unless ($#{@$model} == 1 or $#{@$model} == 4);		
	return warn "Unknown command in model [@$model]"
		unless exists($commandhash->{$model->[0]});
	return if ($#{@$model} == 1);
	return warn "Unknown joiner command in model [@$model]"
		unless exists($joinerhash->{$model->[2]});		
}

sub _get_widget {
	my ($self) = @_;
	
	my $commandchoices = ['before', 'after', 'on or after', 'on or before'];
	my $joinerchoices  = ['', 'and', 'or'];
	
	my $commandcombo1 = Gtk2::ComboBox->new_text;	
	my $datelabel1 = Gtk2::Label->new('(select a date)');
	my $calendar1 = Gtk2::Calendar->new;
	my $datelabelbox1 = $self->_calendar_popup($datelabel1, $calendar1, 1);
	foreach my $x (@$commandchoices) {
		$commandcombo1->append_text($x);
	}
	$commandcombo1->signal_connect ( 'changed' =>
		sub {
			$self->{model}->[0] = $commandchoices->[$commandcombo1->get_active()]
				unless $commandcombo1->get_active() < 0;
			$self->{datelabelbox1}->set_sensitive(TRUE);
			&{ $self->{signals}->{'changed'} } 
				if $self->{signals}->{'changed'} and !$self->{freezesignals};
		}
	);

	my $commandcombo2 = Gtk2::ComboBox->new_text;	
	my $datelabel2 = Gtk2::Label->new('(select a date)');
	my $calendar2 = Gtk2::Calendar->new;
	my $datelabelbox2 = $self->_calendar_popup($datelabel2, $calendar2, 4);
	foreach my $x (@$commandchoices) {
		$commandcombo2->append_text($x);
	}
	$commandcombo2->signal_connect ( 'changed' =>
		sub {
			$self->{model}->[3] = $commandchoices->[$commandcombo2->get_active()]
				unless $commandcombo2->get_active() < 0;
			$self->{datelabelbox2}->set_sensitive(TRUE);
			&{ $self->{signals}->{'changed'} } 
				if $self->{signals}->{'changed'} and !$self->{freezesignals};
		}
	);

	my $joinercombo = Gtk2::ComboBox->new_text;
	foreach my $x (@$joinerchoices) {
		$joinercombo->append_text($x);
	}
	$commandcombo2->set_no_show_all(TRUE);
	$datelabelbox2->set_no_show_all(TRUE);
	$joinercombo->signal_connect ( 'changed' =>
		sub {
			if ($joinercombo->get_active() == 0) {
				$commandcombo2->hide_all;
				$datelabelbox2->hide_all;
				$commandcombo2->set_no_show_all(TRUE);
				$datelabelbox2->set_no_show_all(TRUE);
				$self->{model} = [$self->{model}->[0], $self->{model}->[1]];
				$commandcombo2->set_active(-1);
				$datelabel2->set_label('(select a date)');
			} else {
				$commandcombo2->set_no_show_all(FALSE);
				$datelabelbox2->set_no_show_all(FALSE);
				$commandcombo2->show_all;
				$datelabelbox2->show_all;
				$self->{model}->[2] = $joinerchoices->[$joinercombo->get_active()];		
				&{ $self->{signals}->{'changed'} } 
					if $self->{signals}->{'changed'} and !$self->{freezesignals};
			}
		}
	);

	$self->{commandchoices}= $commandchoices;
	$self->{joinerchoices} = $joinerchoices;
	
	$self->{commandcombo1} = $commandcombo1;
	$self->{datelabel1}    = $datelabel1;
	$self->{calendar1}     = $calendar1;
	$self->{datelabelbox1} = $datelabelbox1;

	$self->{commandcombo2} = $commandcombo2;
	$self->{datelabel2}    = $datelabel2;
	$self->{calendar2}     = $calendar2;
	$self->{datelabelbox2} = $datelabelbox2;

	$self->{joinercombo}   = $joinercombo;	

	$self->{datelabelbox1}->set_sensitive(FALSE);
	$self->{joinercombo}->set_sensitive(FALSE);
	$self->{datelabelbox2}->set_sensitive(FALSE);
	
	$commandcombo1->set_wrap_width(1);
	$joinercombo->set_wrap_width(1);
	$commandcombo2->set_wrap_width(1);

	my $table = Gtk2::Table->new(3,3,FALSE);
	$table->set_col_spacings(5);
	$table->attach($commandcombo1,0,1,0,1, 'expand', 'expand', 0, 0);
	$table->attach($datelabelbox1,1,2,0,1, 'expand', 'expand', 0, 0);
	$table->attach($joinercombo  ,2,3,0,1, 'expand', 'expand', 0, 0);
	$table->attach($commandcombo2,0,1,1,2, 'expand', 'expand', 0, 0);
	$table->attach($datelabelbox2,1,2,1,2, 'expand', 'expand', 0, 0);
	return $table;	
}

sub _get_date_string {
	my ($calendar) = @_;
	my ($year, $month, $day) = $calendar->get_date();
	$month += 1;
	$day   = "0$day" if $day < 10;
	$month = "0$month" if $month < 10;
	return "$year-$month-$day";
}

sub _set_calendar_date {
	my ($calendar, $datestr) = @_;
	my ($year, $month, $day) = split '-', $datestr;
	$calendar->select_month($month-1, $year);
	$calendar->select_day($day);	
}

sub _update_date_label {
	my ($calendar, $datelabel) = @_;
	my ($year, $month, $day) = $calendar->get_date();
	$month = _month()->[$month];
	my $date_str = "$month $day \, $year";
	$datelabel->set_text($date_str);	
}

sub _calendar_popup {
	my ($self, $datelabel, $calendar, $num) = @_;
	my $datelabelbox = _add_button_press(_add_arrow($datelabel));
	my $datepopup = Gtk2::Ex::PopupWindow->new($datelabel);
	my $okbutton = Gtk2::Button->new_from_stock('gtk-ok');
	$okbutton->signal_connect ('button-release-event' => 
		sub {
			_update_date_label($calendar, $datelabel);
			$self->{model}->[$num] = _get_date_string($calendar);
			$self->{joinercombo}->set_sensitive(TRUE) if ($num == 1);
			$datepopup->hide;
			&{ $self->{signals}->{'changed'} } 
				if $self->{signals}->{'changed'} and !$self->{freezesignals};
		}
	);
	$calendar->signal_connect ( 'day-selected' =>
		sub {
			_update_date_label($calendar, $datelabel);
			$self->{model}->[$num] = _get_date_string($calendar);
			$self->{joinercombo}->set_sensitive(TRUE) if ($num == 1);
		}
	);	
	my $hbox = Gtk2::HBox->new (TRUE, 0);
	$hbox->pack_start ($okbutton, TRUE, TRUE, 0); 	
	my $vbox = Gtk2::VBox->new (FALSE, 0);
	$vbox->pack_start ($calendar, TRUE, TRUE, 0); 
	$vbox->pack_start ($hbox, FALSE, FALSE, 0); 	
	$datepopup->{window}->add($vbox);
	$datelabelbox->signal_connect ('button-release-event' => 
		sub { 
			$datepopup->show;
		}
	);
	
	$datepopup->signal_connect('show' => 
		sub {
			return unless $self->{popup};
			if ($^O =~ /Win32/) {
				$self->{popup}->set_move_with_parent(TRUE);
				$self->{popup}->show;
			}
		}
	);
	$datepopup->signal_connect('hide' => 
		sub {
			return unless $self->{popup};
			if ($^O =~ /Win32/) {
				$self->{popup}->set_move_with_parent(FALSE);
			}
		}
	);
	if ($self->{popup}) {
	$self->{popup}->signal_connect('hide' => 
		sub {
			$datepopup->hide;
		}
	);
	}
	return $datelabelbox;
}

sub _month {
	return [
		'January',
		'February',
		'March',
		'April',
		'May',
		'June',
		'July',
		'August',
		'September',
		'October',
		'November',
		'December',
	];
}

sub _add_button_press {
	my ($widget) = @_;
	my $eventbox = Gtk2::EventBox->new;
	$eventbox->add ($widget);
	$eventbox->add_events (['button-release-mask']);
	return $eventbox;
}

sub _add_arrow {
	my ($label) = @_;
	my $arrow = Gtk2::Arrow -> new('down', 'none');
	my $labelbox = Gtk2::HBox->new (FALSE, 0);
	$labelbox->pack_start ($label, FALSE, FALSE, 0);    
	$labelbox->pack_start ($arrow, FALSE, FALSE, 0);    
	return $labelbox;
}

1;

__END__

=head1 NAME

Gtk2::Ex::DateRange - A simple widget for specifying a range of dates.
(For example, "before date1 and after date2")

=head1 DESCRIPTION

A simple widget for specifying a range of dates.
(For example, B<after '1965-03-12' and before '1989-02-14'>)

=head1 SYNOPSIS

	use Gtk2::Ex::DateRange;
	my $daterange = Gtk2::Ex::DateRange->new;
	$daterange->set_model([ 'after', '1965-03-12', 'and', 'before', '1989-02-14' ]);
	$daterange->signal_connect('changed' =>
		sub {
			print Dumper $daterange->get_model;
		}
	);

=head1 METHODS

=head2 new;

=head2 set_model($model);

The C<$model> is a ref to a list with 5 parameters;

	$daterange->set_model([ 'before', '1965-03-12', 'or', 'after', '1989-02-14' ]);

=head2 get_model;

=head2 attach_popup_to($parent);

This method returns a C<Gtk2::Ex::PopupWindow>. The popup window will contain
a C<Gtk2::Ex::DateRange> widget and two buttons.

=head2 to_sql_condition($datefieldname, $model);

Converts the C<$model> into an SQL condition so that it can be used directly in
and SQL statement. C<$datefieldname> is the fieldname that will be used inside
the SQL condition.

=head2 signal_connect($signal, $callback);

See the SIGNALS section to see the supported signals.

=head1 SIGNALS

=head2 changed;

=head1 SEE ALSO

Gtk2::Ex::PopupWindow

=head1 COPYRIGHT & LICENSE

Copyright 2005 Ofey Aikon, All Rights Reserved.

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Library General Public License as published by the Free
Software Foundation; either version 2.1 of the License, or (at your option) any
later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU Library General Public License for more
details.

You should have received a copy of the GNU Library General Public License along
with this library; if not, write to the Free Software Foundation, Inc., 59
Temple Place - Suite 330, Boston, MA  02111-1307  USA.

=cut
