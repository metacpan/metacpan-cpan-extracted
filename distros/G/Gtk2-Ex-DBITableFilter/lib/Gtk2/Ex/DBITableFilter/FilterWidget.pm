package Gtk2::Ex::DBITableFilter::FilterWidget;

use strict;
use warnings;
use Glib qw(TRUE FALSE);
use Data::Dumper;

sub new {
	my ($class, $parent) = @_;
	my $self  = {};
	bless ($self, $class);
	$self->{parent} = $parent;
	return $self;
}

sub add_search_box {
	my ($self, $columnnumber) = @_;
	my $parent = $self->{parent};
	my $slist = $parent->{slist};
	$slist->set_headers_clickable(TRUE);
	my $col = $slist->get_column($columnnumber);
	my $title = $col->get_title;
	my $label = Gtk2::Label->new ($title);
	my $labelbox = _add_arrow($label);
	$col->set_widget ($labelbox);
	$labelbox->show_all;
	my $button = $col->get_widget; # not a button
	do {
		$button = $button->get_parent;
	} until ($button->isa ('Gtk2::Button'));
	my $popupwindow = Gtk2::Ex::PopupWindow->new($labelbox);
	my $frame = Gtk2::Frame->new;
	my $entry = Gtk2::Entry->new;
	$entry->signal_connect( 'changed' => 
		sub {
			my $pattern_string;
			if ($entry->get_text) {			
				$pattern_string	= '\'%'.$entry->get_text.'%\'';
			} else {
				$pattern_string	= undef;			
			}
			$parent->{params}->{columnfilter}->{$columnnumber} = $pattern_string;			
		}
	);
	$frame->add($entry);
	$frame->set_size_request(0, 0);
	$popupwindow->{window}->add($frame);
	$button->signal_connect ('button-release-event' => 
		sub { 
			my ($self, $event) = @_;
			$popupwindow->show;
		} 
	);
}

sub add_choice {
	my ($self, $columnnumber, $list) = @_;
	my $parent = $self->{parent};
	my $slist = $parent->{slist};
	$slist->set_headers_clickable(TRUE);
	my $col = $slist->get_column($columnnumber);
	my $title = $col->get_title;
	my $label = Gtk2::Label->new ($title);
	my $labelbox = _add_arrow($label);
	$col->set_widget ($labelbox);
	$labelbox->show_all;
	my $button = $col->get_widget; # not a button
	do {
		$button = $button->get_parent;
	} until ($button->isa ('Gtk2::Button'));
	my $combobox = Gtk2::Ex::ComboBox->new($labelbox, 'with-buttons');
	$combobox->set_list_preselected($list);
	$button->signal_connect ('button-release-event' => 
		sub { 
			my ($self, $event) = @_;
			$combobox->show;
		} 
	);
	$parent->{params}->{columnfilter}->{$columnnumber}
		= combine($combobox->get_selected_values->{'selected-values'});
	$combobox->signal_connect( 'changed' => 
		sub {
			$parent->{params}->{columnfilter}->{$columnnumber}
				= combine($combobox->get_selected_values->{'selected-values'});
		}
	);
	$parent->{combobox}->{$columnnumber} = $combobox;	
}

sub combine {
	my ($list) = @_;
	my $str = join '\',\'', @$list;
	$str = '(\''.$str.'\')';
	return $str;
}

sub add_date_filter {
	my ($self, $columnnumber, $preselected) = @_;
	my ($command1, $date1, $joiner1, $command2, $date2) = ('', '', '', '', '');

	($command1, $date1, $joiner1, $command2, $date2) = @$preselected if $preselected;
	#print "$date1, $command1, $joiner1, $date2, $command2\n";
	
	my $parent = $self->{parent};
	my $button = $self->_get_column_header_button($columnnumber);
	my $popupwindow = Gtk2::Ex::PopupWindow->new($button);
	$popupwindow->set_move_with_parent(TRUE);
	
	my $choices = ['before', 'after'];
	my $joiner  = [ '', 'and', 'or'];
	
	my $datelabel1 = Gtk2::Label->new;
	my $datelabelbox1 = _calendar_popup($datelabel1, $date1);
	my $combobox1 = Gtk2::ComboBox->new_text;	
	$combobox1->append_text($choices->[0]);
	$combobox1->append_text($choices->[1]);
	my $index1 = 1;
	if ($command1) {
		my $i = 0;
		$index1 = { map { $_ => $i++ } @$choices }->{$command1};
	}
	$combobox1->set_active($index1);
	
	my $datelabel2 = Gtk2::Label->new;
	my $datelabelbox2 = _calendar_popup($datelabel2, $date2);
	my $combobox2 = Gtk2::ComboBox->new_text;	
	$combobox2->append_text($choices->[0]);
	$combobox2->append_text($choices->[1]);
	my $index2 = 0;
	if ($command1) {
		my $i = 0;
		$index2 = { map { $_ => $i++ } @$choices }->{$command2};
	}
	$combobox2->set_active($index2);

	my $and_or_combobox = Gtk2::ComboBox->new_text;
	$and_or_combobox->append_text($joiner->[0]);
	$and_or_combobox->append_text($joiner->[1]);
	$and_or_combobox->append_text($joiner->[2]);
	my $index = 0;
	if ($joiner1) {
		my $i = 0;
		$index = { map { $_ => $i++ } @$joiner }->{$joiner1};
	}
	$and_or_combobox->set_active($index);
	$and_or_combobox->signal_connect ( 'changed' =>
		sub {
			my $choice = $and_or_combobox->get_active();
			if ($choice == 0) {
				$combobox2->hide_all;
				$datelabelbox2->hide_all;
			} else {
				$combobox2->show;
				$datelabelbox2->show_all;
			}
		}
	);
	
	my $refreshparams = sub {
		my $params;
		$params->[0]->{command} = $choices->[$combobox1->get_active()];
		$params->[0]->{date} = $datelabel1->get_text();
		return $params unless $and_or_combobox->get_active();;
		$params->[1]->{joiner} = $joiner->[$and_or_combobox->get_active()];
		$params->[1]->{command} = $choices->[$combobox2->get_active()];
		$params->[1]->{date} = $datelabel2->get_text();
		return $params;
	};

	my $table = Gtk2::Table->new(3,3,FALSE);
	$table->attach($combobox1,0,1,0,1, 'expand', 'expand', 0, 0);
	$table->attach($datelabelbox1,1,2,0,1, 'expand', 'expand', 0, 0);
	$table->attach($and_or_combobox,2,3,0,1, 'expand', 'expand', 0, 0);
	$table->attach($combobox2,0,1,1,2, 'expand', 'expand', 0, 0);
	$table->attach($datelabelbox2,1,2,1,2, 'expand', 'expand', 0, 0);
	my $apply = Gtk2::Button->new_from_stock('gtk-apply');
	$parent->{params}->{columnfilter}->{$columnnumber} = &$refreshparams if $preselected;
	$apply->signal_connect ('button-release-event' => 
		sub {
			$parent->{params}->{columnfilter}->{$columnnumber}
				= &$refreshparams;
			$popupwindow->hide;
		}
	);
	my $clear = Gtk2::Button->new_from_stock('gtk-clear');
	$clear->signal_connect ('button-release-event' => 
		sub {
			$parent->{params}->{columnfilter}->{$columnnumber} = undef;
			$and_or_combobox->set_active(0);
			$datelabel1->set_text('none');
			$popupwindow->hide;
		}
	);
	my $hbox = Gtk2::HBox->new (TRUE, 0);
	$hbox->pack_start ($apply, TRUE, TRUE, 0); 	
	$hbox->pack_start ($clear, TRUE, TRUE, 0); 	
	my $vbox = Gtk2::VBox->new (FALSE, 0);
	$vbox->pack_start ($table, TRUE, TRUE, 0); 
	$vbox->pack_start ($hbox, FALSE, FALSE, 0); 	
	$popupwindow->{window}->add($vbox);
	$button->signal_connect ('button-release-event' => 
		sub { 
			my ($self, $event) = @_;
			$popupwindow->show;
			unless ($and_or_combobox->get_active()) {
				$combobox2->hide;
				$datelabelbox2->hide;			
			}
		} 
	);
}

sub process_dates {
	my ($self, $fieldname, $list) = @_;
	print Dumper $list;
	my $str = '';
	return $str unless $list;
	return $str unless $list->[0];
	if ($list->[0]->{command} eq 'after') {
		$str .= ' '.$fieldname.' > \''.$list->[0]->{date}.'\'';
	} elsif ($list->[0]->{command} eq 'before') {
		$str .= ' '.$fieldname.' < \''.$list->[0]->{date}.'\'';
	}
	return ' and '.$str unless $list->[1]->{joiner};
	$str .=' '.$list->[1]->{joiner}.' ';
	if ($list->[1]->{command} eq 'after') {
		$str .= ''.$fieldname.' > \''.$list->[1]->{date}.'\'';
	} elsif ($list->[1]->{command} eq 'before') {
		$str .= ''.$fieldname.' < \''.$list->[1]->{date}.'\'';
	}
	$str = ' and ( '.$str.' ) ';
	return $str;
}

sub _get_column_header_button {
	my ($self, $columnnumber) = @_;
	my $parent = $self->{parent};
	my $slist = $parent->{slist};
	$slist->set_headers_clickable(TRUE);
	my $col = $slist->get_column($columnnumber);
	my $title = $col->get_title;
	my $label = Gtk2::Label->new ($title);
	my $labelbox = _add_arrow($label);
	$col->set_widget ($labelbox);
	$labelbox->show_all;
	my $button = $col->get_widget; # not a button
	do {
		$button = $button->get_parent;
	} until ($button->isa ('Gtk2::Button'));
	return $button;
}

sub _calendar_popup {
	my ($datelabel, $datestr) = @_;
	my $datelabelbox = _add_button_press(_add_arrow($datelabel));
	my $datepopup = Gtk2::Ex::PopupWindow->new($datelabelbox);
	my $date = Gtk2::Calendar->new;
	if ($datestr) {
		my ($year, $mon, $day) = split '-', $datestr;
		$date->select_month($mon-1, $year);
		$date->select_day($day);
		$datelabel->set_text("$year-$mon-$day");
	}
	my $apply = Gtk2::Button->new_from_stock('gtk-apply');
	my $vbox = Gtk2::VBox->new (FALSE, 0);
	$vbox->pack_start ($date, FALSE, FALSE, 0); 
	$vbox->pack_start ($apply, FALSE, FALSE, 0); 	
	$apply->signal_connect ('button-release-event' => 
		sub {
			my ($year, $mon, $day) = $date->get_date();
			$datelabel->set_text("$year-$mon-$day");
			$datepopup->hide;
		}
	);
	$datepopup->{window}->add($vbox);
	$datelabelbox->signal_connect ('button-release-event' => 
		sub { 
			$datepopup->show;
		}
	);
	return $datelabelbox;
}	

sub month {
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

sub _add_arrow {
	my ($label) = @_;
	my $arrow = Gtk2::Arrow -> new('down', 'none');
	my $labelbox = Gtk2::HBox->new (FALSE, 0);
	$labelbox->pack_start ($label, FALSE, FALSE, 0);    
	$labelbox->pack_start ($arrow, FALSE, FALSE, 0);    
	return $labelbox;
}

sub _add_button_press {
	my ($widget) = @_;
	my $eventbox = Gtk2::EventBox->new;
	$eventbox->add ($widget);
	$eventbox->add_events (['button-release-mask']);
	return $eventbox;
}

1;

__END__

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
