package Geo::Raster::Layer::Dialogs::Properties::GDAL;
# @brief 

use strict;
use warnings;
use Carp;
use Glib qw/TRUE FALSE/;
use Gtk2::Ex::Geo::Dialogs qw/:all/;

## @ignore
sub open {
    my($self, $gui) = @_;

    # bootstrap:
    my($dialog, $boot) = $self->bootstrap_dialog
	($gui, 'gdal_properties_dialog', "Properties of ".$self->name,
	 {
	     gdal_properties_dialog => [delete_event => \&cancel_gdal_properties, [$self, $gui]],
	     gdal_properties_apply_button => [clicked => \&apply_gdal_properties, [$self, $gui, 0]],
	     gdal_properties_cancel_button => [clicked => \&cancel_gdal_properties, [$self, $gui]],
	     gdal_properties_ok_button => [clicked => \&apply_gdal_properties, [$self, $gui, 1]],
	 });
    	
    $self->{backup}->{name} = $self->name;
    $self->{backup}->{alpha} = $self->alpha;
    $self->{backup}->{nodata_value} = $self->nodata_value;

    $dialog->get_widget('gdal_name_entry')->set_text($self->name);
    $dialog->get_widget('gdal_alpha_spinbutton')->set_value($self->alpha);

    my @size = $self->size();
    $dialog->get_widget('gdal_size_label')->set_text("@size");

    @size = $self->world();
    $dialog->get_widget('gdal_min_x_label')->set_text($size[0]);
    $dialog->get_widget('gdal_min_y_label')->set_text($size[1]);
    $dialog->get_widget('gdal_max_x_label')->set_text($size[2]);
    $dialog->get_widget('gdal_max_y_label')->set_text($size[3]);

    @size = $self->cell_size();
    $dialog->get_widget('gdal_cellsize_label')->set_text("@size");

    my $nodata = $self->nodata_value();
    $nodata = '' unless defined $nodata;
    $dialog->get_widget('gdal_nodata_entry')->set_text($nodata);

    @size = $self->value_range();
    my $text = defined $size[0] ? "@size" : "not available";
    $dialog->get_widget('gdal_minmax_label')->set_text($text);
    
    return $dialog->get_widget('gdal_properties_dialog');
}

##@ignore
sub apply_gdal_properties {
    my($self, $gui, $close) = @{$_[1]};
    my $dialog = $self->{gdal_properties_dialog};

    eval {
	my $name = $dialog->get_widget('gdal_name_entry')->get_text;
	$self->name($name);
	my $alpha = $dialog->get_widget('gdal_alpha_spinbutton')->get_value_as_int;
	$self->alpha($alpha);
	
	my $nodata = get_number_from_entry($dialog->get_widget('gdal_nodata_entry'));
	my $band = $self->band();
	$band->SetNoDataValue($nodata) if $nodata ne '';
    };
    $gui->message("$@") if $@;

    $self->hide_dialog('gdal_properties_dialog') if $close;
    $gui->set_layer($self);
    $gui->{overlay}->render;
}

##@ignore
sub cancel_gdal_properties {
    my($self, $gui);
    for (@_) {
	next unless ref CORE::eq 'ARRAY';
	($self, $gui) = @{$_};
    }

    eval {
	$self->alpha($self->{backup}->{alpha});
	$self->name($self->{backup}->{name});
	my $band = $self->band();
	$band->SetNoDataValue($self->{backup}->{nodata}) if $self->{backup}->{nodata} and $self->{backup}->{nodata} ne '';
    };
    $gui->message("$@") if $@;
    $self->hide_dialog('gdal_properties_dialog');
    $gui->set_layer($self);
    $gui->{overlay}->render;
    1;
}
1;
