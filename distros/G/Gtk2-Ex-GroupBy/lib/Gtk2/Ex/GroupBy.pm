package Gtk2::Ex::GroupBy;

our $VERSION = '0.02';

use warnings;
use strict;
use Gtk2 -init;
use Glib ':constants';
use Gtk2::Ex::Simple::List;
use Data::Dumper;

use constant ORDER_COLUMN => 0;
use constant MODEL_COLUMN => 1;
use constant NAME__COLUMN => 2;

sub new {
	my ($class, $slist) = @_;
	my $self  = {};
	bless ($self, $class);
	$self->{widget} = $self->_create_widget();
	return $self;
}

sub signal_connect {
	my ($self, $signal, $callback) = @_;
	$self->{signals}->{$signal} = $callback;
}

sub set_model {
	my ($self, $data) = @_;
	# Add explicitly or else TiedRows are gonna bite you
	foreach my $x (@{$data->{'groupby'}->[0]}) {
		push @{$self->{groupby_list1}->{data}}, [$x];
	}
	foreach my $x (@{$data->{'groupby'}->[1]}) {
		push @{$self->{groupby_list2}->{data}}, [$x];
	}
	_populate($self->{formula_treeview1}, $self->{formula_model1}, $data->{'formula'}->[0]);
	_populate($self->{formula_treeview2}, $self->{formula_model2}, $data->{'formula'}->[1]);
	$self->_check_visibility;
}

sub get_model {
	my ($self) = @_;
	$self->_update_model;
	return $self->{model};
}

sub get_widget {
	my ($self) = @_;
	return $self->{widget};
}

sub _create_widget {
	my ($self) = @_;
	my $groupby_list1 = Gtk2::Ex::Simple::List->new (
		'Group By Fields'    => 'text',
	);
	my $groupby_list2 = Gtk2::Ex::Simple::List->new (
		'Choose Group By Fields from'    => 'text',
	);	

	my @column_types;
	$column_types[0] = 'Glib::String';
	$column_types[NAME__COLUMN] = 'Glib::String';
	$column_types[ORDER_COLUMN] = 'Glib::String';
	$column_types[MODEL_COLUMN] = 'Gtk2::ListStore';

	my $formula_model1 = Gtk2::ListStore->new (@column_types);   
	my $formula_treeview1= Gtk2::TreeView->new($formula_model1);
	$self->_add_combo($formula_treeview1, $formula_model1, 'Fields', 'Aggregation Formula');

	my $formula_model2 = Gtk2::ListStore->new (@column_types);   
	my $formula_treeview2= Gtk2::TreeView->new($formula_model2);
	$self->_add_combo($formula_treeview2, $formula_model2, 'Choose Fields from', 'Choose Formula from');

	$self->{groupby_list1} = $groupby_list1;
	$self->{groupby_list2} = $groupby_list2;
	$self->{formula_treeview1} = $formula_treeview1;
	$self->{formula_treeview2} = $formula_treeview2;	
	$self->{formula_model1} = $formula_model1;
	$self->{formula_model2} = $formula_model2;	
	
	($groupby_list1->get_column(0)->get_cell_renderers)[0]->set(xalign => 0.5);
	($groupby_list2->get_column(0)->get_cell_renderers)[0]->set(xalign => 0.5);

	$groupby_list1->get_column(0)->set_expand(TRUE);
	$groupby_list2->get_column(0)->set_expand(TRUE);

	$groupby_list1->get_column(0)->set_alignment(0.5);
	$groupby_list2->get_column(0)->set_alignment(0.5);

	($formula_treeview1->get_column(0)->get_cell_renderers)[0]->set(xalign => 0.5);
	($formula_treeview2->get_column(0)->get_cell_renderers)[0]->set(xalign => 0.5);
	($formula_treeview1->get_column(1)->get_cell_renderers)[0]->set(xalign => 0.5);
	($formula_treeview2->get_column(1)->get_cell_renderers)[0]->set(xalign => 0.5);

	$formula_treeview1->get_column(0)->set_expand(TRUE);
	$formula_treeview2->get_column(0)->set_expand(TRUE);
	$formula_treeview1->get_column(1)->set_expand(TRUE);
	$formula_treeview2->get_column(1)->set_expand(TRUE);

	$formula_treeview1->get_column(0)->set_alignment(0.5);
	$formula_treeview2->get_column(0)->set_alignment(0.5);
	$formula_treeview1->get_column(1)->set_alignment(0.5);
	$formula_treeview2->get_column(1)->set_alignment(0.5);

	# $formula_treeview2->get_column(0)->set_visible(FALSE);

	$groupby_list1->set_reorderable(TRUE);
	$formula_treeview1->set_reorderable(TRUE);
		
	$groupby_list1->get_selection->set_mode('multiple');
	$formula_treeview1->get_selection->set_mode('multiple');
	$groupby_list2->get_selection->set_mode('multiple');
	$formula_treeview2->get_selection->set_mode('multiple');

	_populate($formula_treeview1, $formula_model1, $self->{model}->{'formula'}->[0]);
	_populate($formula_treeview2, $formula_model2, $self->{model}->{'formula'}->[1]);
		
	my $buttonbox = $self->_pack_buttons;

	my $groupby_list1_none_label = Gtk2::Label->new;
	$groupby_list1_none_label->set_line_wrap(TRUE);

	$groupby_list1_none_label->set_markup('<span foreground="red">(Please add from the list Below)</span>');
	$self->{groupby_list1_none_label} = $groupby_list1_none_label;

	my $vbox11 = Gtk2::VBox->new(FALSE);
	$vbox11->pack_start ($groupby_list1, TRUE, TRUE, 0);
	$vbox11->pack_start ($groupby_list1_none_label, FALSE, FALSE, 0);
		
	my $groupby_list2_none_label = Gtk2::Label->new;
	$groupby_list2_none_label->set_markup('<span foreground="red">(Please add from the list Below)</span>');
	$self->{groupby_list2_none_label} = $groupby_list2_none_label;

	my $vbox12 = Gtk2::VBox->new(FALSE);
	$vbox12->pack_start ($formula_treeview1, TRUE, TRUE, 0);
	$vbox12->pack_start ($groupby_list2_none_label, FALSE, FALSE, 0);

	my $vbox21 = Gtk2::VBox->new(FALSE);
	$vbox21->pack_start ($groupby_list2, TRUE, TRUE, 0);
	
	my $vbox22 = Gtk2::VBox->new(FALSE);
	$vbox22->pack_start ($formula_treeview2, TRUE, TRUE, 0);	
	
	my $hbox1 = Gtk2::HBox->new(TRUE);
	$hbox1->pack_start ($vbox11, TRUE, TRUE, 0);	
	$hbox1->pack_start ($vbox12, TRUE, TRUE, 0);	

	my $hbox2 = Gtk2::HBox->new(TRUE);
	$hbox2->pack_start ($vbox21, TRUE, TRUE, 0);	
	$hbox2->pack_start ($vbox22, TRUE, TRUE, 0);	

	my $vbox = Gtk2::VBox->new(FALSE);
	$vbox->pack_start ($hbox1, TRUE, TRUE, 0);	
	$vbox->pack_start ($buttonbox, FALSE, TRUE, 0);	
	$vbox->pack_start (_frame_it($hbox2), TRUE, TRUE, 0);	
	
	return $vbox;
}

sub _frame_it {
	my ($widget) = @_;
	my $frame = Gtk2::Frame->new;
	$frame->add($widget);
	return $frame;
}

sub _pack_buttons {
	my ($self) = @_;
	
	my $removebutton = Gtk2::Button->new;
	my $removebuttonlabel = Gtk2::HBox->new (FALSE, 0);
	$removebuttonlabel->pack_start (Gtk2::Label->new(' Remove '), TRUE, TRUE, 0);
	$removebuttonlabel->pack_start (Gtk2::Image->new_from_stock('gtk-go-down', 'GTK_ICON_SIZE_BUTTON'), FALSE, FALSE, 0);
	$removebutton->add($removebuttonlabel);

	my $okbutton = Gtk2::Button->new_from_stock('gtk-ok');

	my $addbutton = Gtk2::Button->new;
	my $addbuttonlabel = Gtk2::HBox->new (FALSE, 0);
	$addbuttonlabel->pack_start (Gtk2::Label->new(' Add '), TRUE, TRUE, 0);
	$addbuttonlabel->pack_start (Gtk2::Image->new_from_stock('gtk-go-up', 'GTK_ICON_SIZE_BUTTON'), FALSE, FALSE, 0);
	$addbutton->add($addbuttonlabel);

	my $clearbutton = Gtk2::Button->new_from_stock('gtk-clear');

	$removebuttonlabel->set_sensitive(FALSE);
	$addbuttonlabel->set_sensitive(FALSE);
	$removebutton->set_sensitive(FALSE);
	$addbutton->set_sensitive(FALSE);
	
	my $triggered = FALSE;
	
	$self->{groupby_list1}->get_selection->signal_connect ('changed' =>
		sub {
			return if $triggered;
			$triggered = TRUE;
			$removebuttonlabel->set_sensitive(TRUE);
			$addbuttonlabel->set_sensitive(FALSE);
			$removebutton->set_sensitive(TRUE);
			$addbutton->set_sensitive(FALSE);
			$self->{groupby_list2}->get_selection->unselect_all;
			$self->{formula_treeview1}->get_selection->unselect_all;
			$self->{formula_treeview2}->get_selection->unselect_all;
			$triggered = FALSE;
		}
	);

	$self->{groupby_list2}->get_selection->signal_connect ('changed' =>
		sub {
			return if $triggered;
			$triggered = TRUE;
			$removebuttonlabel->set_sensitive(FALSE);
			$addbuttonlabel->set_sensitive(TRUE);
			$removebutton->set_sensitive(FALSE);
			$addbutton->set_sensitive(TRUE);
			$self->{groupby_list1}->get_selection->unselect_all;
			$self->{formula_treeview1}->get_selection->unselect_all;
			$self->{formula_treeview2}->get_selection->unselect_all;
			$triggered = FALSE;
		}
	);

	$self->{formula_treeview1}->get_selection->signal_connect ('changed' =>
		sub {
			return if $triggered;
			$triggered = TRUE;
			$removebuttonlabel->set_sensitive(TRUE);
			$addbuttonlabel->set_sensitive(FALSE);
			$removebutton->set_sensitive(TRUE);
			$addbutton->set_sensitive(FALSE);
			$self->{groupby_list1}->get_selection->unselect_all;
			$self->{groupby_list2}->get_selection->unselect_all;
			$self->{formula_treeview2}->get_selection->unselect_all;
			$triggered = FALSE;
		}
	);

	$self->{formula_treeview2}->get_selection->signal_connect ('changed' =>
		sub {
			return if $triggered;
			$triggered = TRUE;
			$removebuttonlabel->set_sensitive(FALSE);			
			$removebutton->set_sensitive(FALSE);
			if ($#{@{$self->{groupby_list1}->{data}}} >= 0) {
				$addbuttonlabel->set_sensitive(TRUE);
				$addbutton->set_sensitive(TRUE);
			} else {
				$addbuttonlabel->set_sensitive(FALSE);
				$addbutton->set_sensitive(FALSE);			
			}
			$self->{groupby_list1}->get_selection->unselect_all;
			$self->{groupby_list2}->get_selection->unselect_all;
			$self->{formula_treeview1}->get_selection->unselect_all;
			$triggered = FALSE;
		}
	);	

	$addbutton->signal_connect ('button-release-event' => 
		sub {
			my $indices = _get_selected_indices($self->{formula_treeview2});
			if ($indices) {
				my @removeorder = reverse sort @$indices;
				my $data1 = _get_data($self->{formula_treeview1});
				my $data2 = _get_data($self->{formula_treeview2});
				foreach my $x (@removeorder) {
					push @$data1, splice (@$data2, $x, 1);
				}
				$self->{formula_treeview1}->set_no_show_all(FALSE);
				$self->{formula_treeview1}->show_all;
				_populate($self->{formula_treeview1}, $self->{formula_model1}, $data1);
				_populate($self->{formula_treeview2}, $self->{formula_model2}, $data2);
			} else {
				my @selected = $self->{groupby_list2}->get_selected_indices;
				my @removeorder = reverse sort @selected;
				foreach my $x (@removeorder) {
					push @{$self->{groupby_list1}->{data}}, 
						splice (@{$self->{groupby_list2}->{data}}, $x, 1);
				}
			}
			$self->_update_model;
			&{ $self->{signals}->{'changed'} } if $self->{signals}->{'changed'};
			$removebuttonlabel->set_sensitive(FALSE);
			$addbuttonlabel->set_sensitive(FALSE);
			$removebutton->set_sensitive(FALSE);
			$addbutton->set_sensitive(FALSE);
			return FALSE;
		}
	);  

	$clearbutton->signal_connect ('clicked' => 
		sub {
			my $removeorder = [0..$#{@{$self->{groupby_list1}->{data}}}];
			foreach my $x (reverse sort @$removeorder) {
				push @{$self->{groupby_list2}->{data}}, 
					splice (@{$self->{groupby_list1}->{data}}, $x, 1);
			}
			if ($#{@{$self->{groupby_list1}->{data}}} < 0) {
				my $data1 = _get_data($self->{formula_treeview1});
				my $data2 = _get_data($self->{formula_treeview2});
				push @$data2, @$data1 if $data1;
				$data1 = undef;
				_populate($self->{formula_treeview1}, $self->{formula_model1}, $data1);
				_populate($self->{formula_treeview2}, $self->{formula_model2}, $data2);
			}
			$self->_update_model;
			&{ $self->{signals}->{'changed'} } if $self->{signals}->{'changed'};
			return FALSE;
		}
	);
	
	$removebutton->signal_connect ('clicked' => 
		sub {
			my $indices = _get_selected_indices($self->{formula_treeview1});
			if ($indices) {
				my @removeorder = reverse sort @$indices;
				my $data1 = _get_data($self->{formula_treeview1});
				my $data2 = _get_data($self->{formula_treeview2});
				foreach my $x (@removeorder) {
					push @$data2, splice (@$data1, $x, 1);
				}
				_populate($self->{formula_treeview1}, $self->{formula_model1}, $data1);
				_populate($self->{formula_treeview2}, $self->{formula_model2}, $data2);
			} else {
				my @selected = $self->{groupby_list1}->get_selected_indices;
				my @removeorder = reverse sort @selected;
				foreach my $x (@removeorder) {
					push @{$self->{groupby_list2}->{data}}, 
						splice (@{$self->{groupby_list1}->{data}}, $x, 1);
				}
				if ($#{@{$self->{groupby_list1}->{data}}} < 0) {
					my $data1 = _get_data($self->{formula_treeview1});
					my $data2 = _get_data($self->{formula_treeview2});
					push @$data2, @$data1 if $data1;
					$data1 = undef;
					_populate($self->{formula_treeview1}, $self->{formula_model1}, $data1);
					_populate($self->{formula_treeview2}, $self->{formula_model2}, $data2);
				}
			}
			$self->_update_model;
			&{ $self->{signals}->{'changed'} } if $self->{signals}->{'changed'};
			$removebuttonlabel->set_sensitive(FALSE);
			$addbuttonlabel->set_sensitive(FALSE);
			$removebutton->set_sensitive(FALSE);
			$addbutton->set_sensitive(FALSE);
			return FALSE;
		}
	);

	$okbutton->signal_connect ('clicked' => 
		sub {
			&{ $self->{signals}->{'closed'} } if $self->{signals}->{'closed'};
		}
	);

	$self->{addbutton}    = $addbutton;
	$self->{removebutton} = $removebutton;
	$self->{okbutton}  = $okbutton;
	$self->{addbuttonlabel}    = $addbuttonlabel;
	$self->{removebuttonlabel} = $removebuttonlabel;
	
	my $hbox = Gtk2::HBox->new (TRUE, 0);
	$hbox->pack_start ($addbutton, TRUE, TRUE, 0);   
	$hbox->pack_start ($okbutton, TRUE, TRUE, 0);	
	$hbox->pack_start ($clearbutton, TRUE, TRUE, 0);	
	$hbox->pack_start ($removebutton, TRUE, TRUE, 0);	
	
	return $hbox;
}

sub _update_model {
	my ($self) = @_;
	my @data1;
	my @data2;
	foreach my $x (@{$self->{groupby_list1}->{data}}) {
		push @data1, $x->[0];
	}
	foreach my $x (@{$self->{groupby_list2}->{data}}) {
		push @data2, $x->[0];
	}
	$self->{model}->{'groupby'}->[0] = $#data1 >= 0 ? \@data1 : undef;
	$self->{model}->{'groupby'}->[1] = $#data2 >= 0 ? \@data2 : undef;
	$self->{model}->{'formula'}->[0] = _get_data($self->{formula_treeview1});
	$self->{model}->{'formula'}->[1] = _get_data($self->{formula_treeview2});
	$self->_check_visibility;
}

sub _get_selected_indices {
	my ($treeview) = @_;
	my @indices;
	my (@paths) = $treeview->get_selection->get_selected_rows;
	foreach my $path (@paths) {
		push @indices, $path->to_string;
	}
	return undef if $#indices < 0;
	return \@indices;
}

sub _get_data {
	my ($treeview) = @_;
	my $model = $treeview->get_model;
	my @data;
	for my $i(0..$model->iter_n_children-1) {
		my $col0 = $model->get($model->get_iter_from_string($i), 0);
		my $col1 = $model->get($model->get_iter_from_string($i), 2);
		push @data, { formula => $col0, field => $col1 };
	}
	return undef if $#data < 0;
	return \@data;
}

sub _add_combo {
	my ($self, $treeview, $model, $groupby_header, $formula_header) = @_;
	
	my $combo_renderer = Gtk2::CellRendererCombo->new;
	$combo_renderer->set (
		text_column => 0, # col in combo model with text to display
		editable => TRUE, # without this, it's just a text renderer
	); 
	$combo_renderer->signal_connect (edited => 
		sub {
			my ($cell, $text_path, $new_text) = @_;
			$model->set (
				$model->get_iter_from_string($text_path),
				ORDER_COLUMN, 
				$new_text
			);
			&{ $self->{signals}->{'changed'} } if $self->{signals}->{'changed'};
		}
	);
	$treeview->insert_column_with_attributes(
		-1, $formula_header, 
		$combo_renderer,
		text  => ORDER_COLUMN, 
		model => MODEL_COLUMN
	);
	$treeview->insert_column_with_attributes(
		-1, $groupby_header, 
		Gtk2::CellRendererText->new, 
		text => NAME__COLUMN
	);
}

sub _check_visibility {
	my ($self) = @_;
	if ($#{@{$self->{groupby_list1}->{data}}} >= 0) {
		$self->{groupby_list1_none_label}->hide;
		$self->{groupby_list1_none_label}->set_no_show_all(TRUE);
	} else {
		$self->{groupby_list1_none_label}->set_no_show_all(FALSE);
		$self->{groupby_list1_none_label}->show;	
	}
	if ($self->{formula_treeview1}->get_model->iter_n_children > 0) {
		$self->{groupby_list2_none_label}->hide;
		$self->{groupby_list2_none_label}->set_no_show_all(TRUE);
	} else {
		$self->{groupby_list2_none_label}->set_no_show_all(FALSE);
		$self->{groupby_list2_none_label}->show;	
	}
}

sub _populate{
	my ($treeview, $model, $temp) = @_;
	my $lookup_hash = { 
		'COUNT of' 	=> 0,
		'MAX of' 	=> 1,
		'MIN of' 	=> 2,
		'SUM of' 	=> 3, 
		'AVG of' 	=> 4,
		'STDDEV of' => 5,		
	};
	my $combomodel = Gtk2::ListStore->new('Glib::String');
	$combomodel->set($combomodel->append, 0, 'COUNT of');
	$combomodel->set($combomodel->append, 0, 'MAX of');
	$combomodel->set($combomodel->append, 0, 'MIN of');
	$combomodel->set($combomodel->append, 0, 'SUM of');
	$combomodel->set($combomodel->append, 0, 'AVG of');
	$combomodel->set($combomodel->append, 0, 'STDDEV of');
	$model->clear();
	my $i = 0;
	foreach my $data (@$temp) {
		$data->{formula} = $lookup_hash->{$data->{formula}};
		$data->{formula} = $combomodel->get(
			$combomodel->iter_nth_child (undef, $data->{formula})
			, 0
		);
		$model->set (
			$model->append,
			NAME__COLUMN, $data->{field},
			ORDER_COLUMN, $data->{formula},
			MODEL_COLUMN, $combomodel 
		);
	}
}

1;

__END__

=head1 NAME

Gtk2::Ex::GroupBy - A simple widget for specifying a I<Group By> and I<Aggregation>
on a relational table.

=head1 DESCRIPTION

A simple widget for specifying a I<Group By> and I<Aggregation>
on a relational table. Mainly for using with a SQL data source.

=head1 METHODS

=head2 new;

=head2 get_widget;

=head2 get_model;

=head2 set_model;

=head2 signal_connect;

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