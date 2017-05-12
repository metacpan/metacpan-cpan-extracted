package Geo::Raster::Layer::Dialogs::Polygonize;
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
	($gui, 'polygonize_dialog', "Polygonize ".$self->name,
	 {
	     polygonize_dialog => [delete_event => \&cancel_polygonize, [$self, $gui]],
	     polygonize_cancel_button => [clicked => \&cancel_polygonize, [$self, $gui]],
	     polygonize_ok_button => [clicked => \&do_polygonize, [$self, $gui, 1]],
	 });
    
    if ($boot) {
	$dialog->get_widget('polygonize_datasource_button')
	    ->signal_connect( clicked=> sub {
		my(undef, $self) = @_;
		my $entry = $self->{polygonize_dialog}->get_widget('polygonize_datasource_entry');
		file_chooser('Select folder', 'select_folder', $entry);
			      }, $self);

	my $combo = $dialog->get_widget('polygonize_driver_combobox');
	my $renderer = Gtk2::CellRendererText->new;
	$combo->pack_start($renderer, TRUE);
	$combo->add_attribute($renderer, text => 0);

	$combo = $dialog->get_widget('polygonize_datasource_combobox');
	$renderer = Gtk2::CellRendererText->new;
	$combo->pack_start($renderer, TRUE);
	$combo->add_attribute($renderer, text => 0);
    }

    my $model = Gtk2::ListStore->new('Glib::String');
    for my $layer (@{$gui->{overlay}->{layers}}) {
	my $n = $layer->name();
	next unless $layer->isa('Geo::Vector');
	next unless $layer->{update};
	next if $n eq $self->name();
	$model->set($model->append, 0, $n);
    }
    my $combo = $dialog->get_widget('polygonize_name_comboboxentry');
    $combo->set_model($model);
    $combo->set_text_column(0);
    $combo->get_child->set_text($self->name.'_polygonized');

    $model = Gtk2::ListStore->new('Glib::String');
    $model->set ($model->append, 0, '');
    for my $datasource (sort keys %{$self->{gui}{resources}{datasources}}) {
	$model->set ($model->append, 0, $datasource);
    }
    $combo = $dialog->get_widget('polygonize_datasource_combobox');
    $combo->set_model($model);
    $combo->set_active(0);

    $model = Gtk2::ListStore->new('Glib::String');
    my $i = 1;
    my $active = 0;
    $model->set($model->append, 0, ''); # create into existing data source 
    for my $driver (Geo::OGR::Drivers) {
	next unless $driver->TestCapability('CreateDataSource');
	my $name = $driver->GetName;
	$active = $i if $name eq 'Memory';
	$model->set($model->append, 0, $name);
	$i++;
    }
    $combo = $dialog->get_widget('polygonize_driver_combobox');
    $combo->set_model($model);
    $combo->set_active($active);

    return $dialog->get_widget('polygonize_dialog');
}

##@ignore
sub do_polygonize {
    my($self, $gui, $close) = @{$_[1]};
    my $dialog = $self->{polygonize_dialog};

    my %params;
    my $into = $dialog->get_widget('polygonize_name_comboboxentry')->get_active_text;
    croak "Store into?" unless $into;
    my $into_layer = $gui->layer($into);
    if ($into_layer) {
	croak $into_layer->name." is not a vector layer" unless $into_layer->isa('Geo::Vector');
	$params{schema} = $into_layer->schema;
    } else {
	my $combo = $dialog->get_widget('polygonize_datasource_combobox');
	my $active = $combo->get_active();
	if ($active > 0) {
	    my $model = $combo->get_model;
	    my $iter = $model->get_iter_from_string($active);
	    my $store = $model->get($iter, 0);
	    $params{data_source} = $self->{gui}{resources}{datasources}{$store};
	} else {
	    $params{data_source} = $dialog->get_widget('polygonize_datasource_entry')->get_text;
	    $params{driver} = $dialog->get_widget('polygonize_driver_combobox')->get_active_text;
	}
	$params{create} = $into;
	my $layers;	
	if ($params{driver} ne 'Memory') {
	    eval {
		$layers = Geo::Vector::layers($params{driver}, $params{data_source});
	    };
	}    
	croak "Data source '$params{data_source}' already contains a layer with name '$params{create}'."
	    if ($layers and $layers->{$params{create}});
	$params{schema} = { Fields => [{ Name => 'value', Type => 'Integer' }] };
    }
    if ($dialog->get_widget('connectedness_checkbutton')->get_active) {
	$params{options} = { '8CONNECTED' => 1 };
    } else {
	$params{options} = undef;
    }
    $params{callback} = \&progress;
    $params{callback_date} = $dialog->get_widget('polygonize_progressbar');
    my $vector = $self->polygonize(%params);
    print STDERR "pol res $vector\n";
    if ($vector) {
	$gui->add_layer($vector, $into, 1);
	$gui->{overlay}->render;
    }
    $self->hide_dialog('polygonize_dialog') if $close;
    #$gui->set_layer($self);
    #$gui->{overlay}->render;
}

##@ignore
sub cancel_polygonize {
    my($self, $gui);
    for (@_) {
	next unless ref CORE::eq 'ARRAY';
	($self, $gui) = @{$_};
    }

    $self->hide_dialog('polygonize_dialog');
    $gui->set_layer($self);
    $gui->{overlay}->render;
    1;
}

1;
