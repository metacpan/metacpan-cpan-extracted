package Geo::Vector::Layer::Dialogs::Rasterize;
# @brief 

use strict;
use warnings;
use Carp;
use Glib qw/TRUE FALSE/;
use Gtk2::Ex::Geo::Dialogs qw/:all/;

## @method open_rasterize_dialog($gui)
# @brief present a rasterize dialog for the user
sub open {
    my($self, $gui) = @_;

    # bootstrap:
    my($dialog, $boot) = $self->bootstrap_dialog
	($gui, 'rasterize_dialog', "Rasterize ".$self->name,
	 {
	     rasterize_dialog => [delete_event => \&cancel_rasterize, [$self, $gui]],
	     rasterize_dialog => [delete_event => \&cancel_rasterize, [$self, $gui]],
	     rasterize_cancel_button => [clicked => \&cancel_rasterize, [$self, $gui]],
	     rasterize_ok_button => [clicked => \&apply_rasterize, [$self, $gui, 1]],
	 },
	[
	 'rasterize_value_field_combobox',
	 'rasterize_like_combobox',
	]);
    
    if ($boot) {
	Geo::Vector::Layer::Dialogs::fill_render_as_combobox(
	    $dialog->get_widget('rasterize_render_as_combobox') );

	my $combobox = $dialog->get_widget('rasterize_value_field_combobox');
	my $model = $combobox->get_model();
	$model->set ($model->append, 0, 'Draw with value 1');
	if ($self->{OGR}->{Layer}) {
	    my $schema = $self->{OGR}->{Layer}->GetLayerDefn();
	    for my $i (0..$schema->GetFieldCount-1) {
		my $column = $schema->GetFieldDefn($i);
		my $type = $column->GetFieldTypeName($column->GetType);
		if ($type eq 'Integer' or $type eq 'Real') {
		    $model->set($model->append, 0, $column->GetName);
		}
	    }
	}
	$combobox->set_active(0);

	$combobox = $dialog->get_widget('rasterize_like_combobox');
	$model = $combobox->get_model();
	$model->set($model->append, 0, "Use current view");
	for my $layer (@{$gui->{overlay}->{layers}}) {
	    next unless $layer->isa('Geo::Raster');
	    $model->set($model->append, 0, $layer->name);
	}
	$combobox->set_active(0);
    }
	
    $dialog->get_widget('rasterize_name_entry')->set_text('r');
    $dialog->get_widget('rasterize_like_combobox')->set_active(0);

    my $a = $self->render_as;
    $a = defined $a ? $Geo::Vector::RENDER_AS{$a} : 0;
    $dialog->get_widget('rasterize_render_as_combobox')->set_active($a);
    $dialog->get_widget('rasterize_value_field_combobox')->set_active(0);
    $dialog->get_widget('rasterize_nodata_value_entry')->set_text(-9999);

}

##@ignore
sub apply_rasterize {
    my($self, $gui, $close) = @{$_[1]};
    my $dialog = $self->{rasterize_dialog};
    
    my %ret = (name => $dialog->get_widget('rasterize_name_entry')->get_text());
    my $model = get_value_from_combo($dialog, 'rasterize_like_combobox');
    
    if ($model eq "Use current view") {
	# need M (height), N (width), world
	($ret{M}, $ret{N}) = $gui->{overlay}->size;
	$ret{world} = [$gui->{overlay}->get_viewport];
    } else {
	$ret{like} = $gui->{overlay}->get_layer_by_name($model);
    }

    $ret{render_as} = get_value_from_combo($dialog, 'rasterize_render_as_combobox');

    $ret{feature} = $dialog->get_widget('rasterize_fid_entry')->get_text;
    $ret{feature} = -1 unless $ret{feature} =~ /^\d+$/;

    my $field = get_value_from_combo($dialog, 'rasterize_value_field_combobox');
    
    if ($field ne 'Draw with value 1') {
	$ret{value_field} = $field;
    }

    $ret{nodata_value} = $dialog->get_widget('rasterize_nodata_value_entry')->get_text();

    my $g = $self->rasterize(%ret);
    if ($g) {
	$gui->add_layer($g, $ret{name}, 1);
	$gui->{overlay}->render;
    }
    $self->hide_dialog('rasterize_dialog') if $close;
    $gui->set_layer($self);
    $gui->{overlay}->render;
}

##@ignore
sub cancel_rasterize {
    my($self, $gui);
    for (@_) {
	next unless ref CORE::eq 'ARRAY';
	($self, $gui) = @{$_};
    }
    $self->hide_dialog('rasterize_dialog');
    $gui->set_layer($self);
    1;
}

1;
