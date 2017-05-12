package Gtk2::Ex::NumberRange;

our $VERSION = '0.02';

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
	$self->{entry1}->set_text($model->[1]);
	if ($#{@$model} == 1) {
		$self->{freezesignals} = TRUE;
		$self->{joinercombo}->set_active(0);
		$self->{commandcombo2}->set_active(-1);
		$self->{freezesignals} = FALSE;
		&{ $self->{signals}->{'changed'} } if $self->{signals}->{'changed'};
		return;
	}
	
	$self->{joinercombo}->set_active($joinerhash->{$model->[2]});	
	$self->{commandcombo2}->set_active($commandhash->{$model->[3]});
	$self->{entry2}->set_text($model->[4]);
	
	$self->{freezesignals} = FALSE;
	&{ $self->{signals}->{'changed'} } if $self->{signals}->{'changed'};		
}

sub to_sql_condition {
	my ($self, $fieldname, $model) = @_;
	return undef if $#{@$model} < 1;
	if ($#{@$model} >= 1 and $#{@$model} < 4) {
		my $str =
			 $fieldname
			.' '.$model->[0]
			.' '.$model->[1];
		return $str;
	}
	if ($#{@$model} == 4) {
		my $str1 =
			 $fieldname
			.' '.$model->[0]
			.' '.$model->[1];
		my $str2 = $model->[2];
		my $str3 =
			 $fieldname
			.' '.$model->[3]
			.' '.$model->[4];
		my $str = "( $str1 $str2 $str3 )";
		return $str;
	}	
}


sub _clear {
	my ($self) = @_;
	$self->{freezesignals} = TRUE;
	$self->{commandcombo1}->set_active(-1);
	$self->{entry1}->set_text('');
	$self->{entry1}->set_sensitive(FALSE);
	$self->{joinercombo}->set_active(0);
	$self->{joinercombo}->set_sensitive(FALSE);
	$self->{commandcombo2}->set_active(-1);
	$self->{entry2}->set_text('');
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
	
	my $commandchoices = ['>', '>=', '=', '<=', '<'];
	my $joinerchoices  = ['', 'and', 'or'];
	
	my $commandcombo1 = Gtk2::ComboBox->new_text;	
	my $entry1 = Gtk2::Entry->new;
	my $joinercombo = Gtk2::ComboBox->new_text;
	my $commandcombo2 = Gtk2::ComboBox->new_text;	
	my $entry2 = Gtk2::Entry->new;

	foreach my $x (@$commandchoices) {
		$commandcombo1->append_text($x);
	}
	foreach my $x (@$joinerchoices) {
		$joinercombo->append_text($x);
	}
	foreach my $x (@$commandchoices) {
		$commandcombo2->append_text($x);
	}
	$commandcombo1->signal_connect ( 'changed' =>
		sub {
			$self->{model}->[0] = $commandchoices->[$commandcombo1->get_active()]
				unless $commandcombo1->get_active() < 0;
			$entry1->set_sensitive(TRUE);
			&{ $self->{signals}->{'changed'} } 
				if $self->{signals}->{'changed'} and !$self->{freezesignals};
		}
	);
	$entry1->signal_connect ( 'changed' =>
		sub {
			if ($entry1->get_text) {			
				$self->{model}->[1] = $entry1->get_text;
				$joinercombo->set_sensitive(TRUE);
			} else {
				$self->{model}->[1] = undef;
				$joinercombo->set_sensitive(FALSE);			
			}
			&{ $self->{signals}->{'changed'} } 
				if $self->{signals}->{'changed'} and !$self->{freezesignals};
		}
	);	
	$commandcombo2->signal_connect ( 'changed' =>
		sub {
			$self->{model}->[3] = $commandchoices->[$commandcombo2->get_active()]
				unless $commandcombo2->get_active() < 0;
			$entry2->set_sensitive(TRUE);
			&{ $self->{signals}->{'changed'} } 
				if $self->{signals}->{'changed'} and !$self->{freezesignals};
		}
	);
	$entry2->signal_connect ( 'changed' =>
		sub {
			if ($entry2->get_text) {			
				$self->{model}->[4] = $entry2->get_text;
				$joinercombo->set_sensitive(TRUE);
			} else {
				$self->{model}->[4] = undef;
				$joinercombo->set_sensitive(FALSE);			
			}
			&{ $self->{signals}->{'changed'} } 
				if $self->{signals}->{'changed'} and !$self->{freezesignals};
		}
	);	
	$commandcombo2->set_no_show_all(TRUE);
	$entry2->set_no_show_all(TRUE);
	$joinercombo->signal_connect ( 'changed' =>
		sub {
			if ($joinercombo->get_active == 0) {
				$commandcombo2->hide_all;
				$entry2->hide_all;
				$commandcombo2->set_no_show_all(TRUE);
				$entry2->set_no_show_all(TRUE);
				$self->{model} = [$self->{model}->[0], $self->{model}->[1]];
			} else {
				$commandcombo2->set_no_show_all(FALSE);
				$entry2->set_no_show_all(FALSE);
				$commandcombo2->show_all;
				$entry2->show_all;
				$self->{model}->[2] = $joinerchoices->[$joinercombo->get_active()];
				if ($commandcombo2->get_active > 0) {
					$self->{model}->[4] = $entry2->get_text if $entry2->get_text;
					$self->{model}->[3] = $commandchoices->[$commandcombo2->get_active()]
				}
			}
			&{ $self->{signals}->{'changed'} } 
				if $self->{signals}->{'changed'} and !$self->{freezesignals};
		}
	);

	$self->{commandchoices}= $commandchoices;
	$self->{joinerchoices} = $joinerchoices;
	
	$self->{commandcombo1} = $commandcombo1;
	$self->{entry1}    = $entry1;

	$self->{commandcombo2} = $commandcombo2;
	$self->{entry2}    = $entry2;

	$self->{joinercombo}   = $joinercombo;	

	$self->{entry1}->set_sensitive(FALSE);
	$self->{joinercombo}->set_sensitive(FALSE);
	$self->{entry2}->set_sensitive(FALSE);
	
	$commandcombo1->set_wrap_width(1);
	$joinercombo->set_wrap_width(1);
	$commandcombo2->set_wrap_width(1);

	my $table = Gtk2::Table->new(3,3,FALSE);
	$table->set_col_spacings(5);
	$table->attach($commandcombo1,0,1,0,1, 'expand', 'expand', 0, 0);
	$table->attach($entry1,1,2,0,1, 'expand', 'expand', 0, 0);
	$table->attach($joinercombo  ,2,3,0,1, 'expand', 'expand', 0, 0);
	$table->attach($commandcombo2,0,1,1,2, 'expand', 'expand', 0, 0);
	$table->attach($entry2,1,2,1,2, 'expand', 'expand', 0, 0);
	return $table;	
}

1;

__END__

=head1 NAME

Gtk2::Ex::NumberRange - A simple widget for specifying a number range.
(For example, "> 10 and <= 20")

=head1 DESCRIPTION

A simple widget for specifying a number range.
(For example, "> 10 and <= 20")

=head1 SYNOPSIS

	use Gtk2::Ex::NumberRange;
	my $numberrange = Gtk2::Ex::NumberRange->new;
	$numberrange->set_model(['>', 10, 'and', '<=', 20]);
	$numberrange->signal_connect('changed' =>
		sub {
			print Dumper $numberrange->get_model;
		}
	);

=head1 METHODS

=head2 new;

=head2 set_model($model);

The C<$model> is a ref to a list with 5 parameters;

	$numberrange->set_model(['>', 10, 'and', '<=', 20]);

Will also accept a list with 2 parameters.

	$numberrange->set_model(['>', 10]);

=head2 get_model;

Returns the model.

=head2 attach_popup_to($parent);

This method returns a C<Gtk2::Ex::PopupWindow>. The popup window will contain
a C<Gtk2::Ex::NumberRange> widget and two buttons.

=head2 to_sql_condition($numberfieldname, $model);

Converts the C<$model> into an SQL condition so that it can be used directly in
and SQL statement. C<$numberfieldname> is the fieldname that will be used inside
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
