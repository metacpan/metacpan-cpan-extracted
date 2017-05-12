package Gtk2::Ex::Geo::Dialogs::Symbols;
# @brief 

use strict;
use warnings;
use Carp;
use Glib qw/TRUE FALSE/;

## @method open_symbols_dialog($gui)
# @brief Open the symbols dialog for this layer.
sub open {
    my($self, $gui) = @_;

    my $dialog = $self->bootstrap_dialog
	($gui, 'symbols_dialog', "Symbols for ".$self->name,
	 {
	     symbols_dialog => [delete_event => \&cancel_symbols, [$self, $gui]],
	     symbols_scale_button => [clicked => \&fill_symbol_scale_fields, [$self, $gui]],
	     symbols_field_combobox => [changed=>\&symbol_field_changed, [$self, $gui]],
	     symbols_type_combobox => [changed=>\&symbol_field_changed, [$self, $gui]],
	     symbols_apply_button => [clicked => \&apply_symbols, [$self, $gui, 0]],
	     symbols_cancel_button => [clicked => \&cancel_symbols, [$self, $gui]],
	     symbols_ok_button => [clicked => \&apply_symbols, [$self, $gui, 1]],
	 });
    
    my $symbol_type_combo = $dialog->get_widget('symbols_type_combobox');
    my $field_combo = $dialog->get_widget('symbols_field_combobox');
    my $scale_min = $dialog->get_widget('symbols_scale_min_entry');
    my $scale_max = $dialog->get_widget('symbols_scale_max_entry');
    my $size_spin = $dialog->get_widget('symbols_size_spinbutton');

    # back up data

    my $symbol_type = $self->symbol_type();
    my $size = $self->symbol_size();
    my $field = $self->symbol_field();
    my @scale = $self->symbol_scale();
    $self->{backup}->{symbol_type} = $symbol_type;
    $self->{backup}->{symbol_size} = $size;
    $self->{backup}->{symbol_field} = $field;
    $self->{backup}->{symbol_scale} = \@scale;
    
    # set up the controllers

    fill_symbol_type_combo($self, $symbol_type);
    fill_symbol_field_combo($self, $field);
    $scale_min->set_text($scale[0]);
    $scale_max->set_text($scale[1]);
    $size_spin->set_value($size);
    return $self->{symbols_dialog}->get_widget('symbols_dialog');
}

##@ignore
sub apply_symbols {
    my($self, $gui, $close) = @{$_[1]};
    my $dialog = $self->{symbols_dialog};
    
    my $symbol_type = get_selected_symbol_type($self);
    $self->symbol_type($symbol_type);
    my $field_combo = $dialog->get_widget('symbols_field_combobox');
    my $field = $self->{index2symbol_field}{$field_combo->get_active()};
    $self->symbol_field($field) if defined $field;
    my $scale_min = $dialog->get_widget('symbols_scale_min_entry');
    my $scale_max = $dialog->get_widget('symbols_scale_max_entry');
    $self->symbol_scale($scale_min->get_text(), $scale_max->get_text());
    my $size_spin = $dialog->get_widget('symbols_size_spinbutton');
    my $size = $size_spin->get_value();
    $self->symbol_size($size);

    $self->hide_dialog('symbols_dialog') if $close;
    $gui->set_layer($self);
    $gui->{overlay}->render;
}

##@ignore
sub cancel_symbols {
    my($self, $gui);
    for (@_) {
	next unless ref CORE::eq 'ARRAY';
	($self, $gui) = @{$_};
    }
    
    $self->symbol_type($self->{backup}->{symbol_type});
    $self->symbol_field($self->{backup}->{symbol_field}) if $self->{backup}->{symbol_field};
    $self->symbol_scale(@{$self->{backup}->{symbol_scale}});
    $self->symbol_size($self->{backup}->{symbol_size});

    $self->hide_dialog('symbols_dialog');
    $gui->set_layer($self);
    $gui->{overlay}->render;
    1;
}

##@ignore
sub fill_symbol_type_combo {
    my($self, $symbol_type) = @_;
    $symbol_type = '' unless defined $symbol_type;
    my $combo = $self->{symbols_dialog}->get_widget('symbols_type_combobox');
    my $model = $combo->get_model;
    $model->clear;
    my @symbol_types = $self->supported_symbol_types();
    my $i = 0;
    my $active = 0;
    for (@symbol_types) {
	$model->set ($model->append, 0, $_);
	$self->{index2symbol_type}{$i} = $_;
	$self->{symbol_type2index}{$_} = $i;
	$active = $i if $_ eq $symbol_type;
	$i++;
    }
    $combo->set_active($active);
}

##@ignore
sub get_selected_symbol_type {
    my $self = shift;
    my $combo = $self->{symbols_dialog}->get_widget('symbols_type_combobox');
    ($self->{index2symbol_type}{$combo->get_active()} or '');
}

##@ignore
sub fill_symbol_field_combo {
    my($self, $symbol_field) = @_;
    my $combo = $self->{symbols_dialog}->get_widget('symbols_field_combobox');
    my $model = $combo->get_model;
    $model->clear;
    delete $self->{index2symbol_field};
    my $active = 0;
    my $i = 0;

    my $name = 'Fixed size';
    $model->set($model->append, 0, $name);
    $active = $i if $name eq $self->symbol_field();
    $self->{index2symbol_field}{$i} = $name;
    $i++;
    for my $field ($self->schema()->fields) {
	next unless $field->{Type};
	next unless $field->{Type} eq 'Integer' or $field->{Type} eq 'Real';
	$model->set($model->append, 0, $field->{Name});
	$active = $i if $field->{Name} eq $symbol_field;
	$self->{index2symbol_field}{$i} = $field->{Name};
	$i++;
    }
    $combo->set_active($active);
}

##@ignore
sub get_selected_symbol_field {
    my $self = shift;
    my $combo = $self->{symbols_dialog}->get_widget('symbols_field_combobox');
    ($self->{index2symbol_field}{$combo->get_active()} or '');
}

##@ignore
sub fill_symbol_scale_fields {
    my($self, $gui) = @{$_[1]};
    my @range;
    my $field = get_selected_symbol_field($self);
    return if $field eq 'Fixed size';
    my @r = $gui->{overlay}->get_viewport_of_selection;
    @r = $gui->{overlay}->get_viewport unless @r;
    eval {
	@range = $self->value_range(field_name => $field, filter_rect => \@r);
    };
    if ($@) {
	$gui->message("$@");
	return;
    }
    $self->{symbols_dialog}->get_widget('symbols_scale_min_entry')->set_text($range[0]);
    $self->{symbols_dialog}->get_widget('symbols_scale_max_entry')->set_text($range[1]);
}

##@ignore
sub symbol_field_changed {
    my($self, $gui) = @{$_[1]};
    my $type = get_selected_symbol_type($self);
    my $field = get_selected_symbol_field($self);
    my $dialog = $self->{symbols_dialog};
    if ($type eq 'No symbol') {
	$dialog->get_widget('symbols_size_spinbutton')->set_sensitive(0);
	$dialog->get_widget('symbols_field_combobox')->set_sensitive(0);
    } else {
	$dialog->get_widget('symbols_size_spinbutton')->set_sensitive(1);
	$dialog->get_widget('symbols_field_combobox')->set_sensitive(1);
    }
    if (!$field or $field eq 'Fixed size') {
	$dialog->get_widget('symbols_scale_min_entry')->set_sensitive(0);
	$dialog->get_widget('symbols_scale_max_entry')->set_sensitive(0);
	$dialog->get_widget('symbols_size_label')->set_text('Size: ');
    } else {
	$dialog->get_widget('symbols_scale_min_entry')->set_sensitive(1);
	$dialog->get_widget('symbols_scale_max_entry')->set_sensitive(1);
	$dialog->get_widget('symbols_size_label')->set_text('Maximum size: ');
    }
}

1;
