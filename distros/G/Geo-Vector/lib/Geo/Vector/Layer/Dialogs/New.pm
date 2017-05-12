package Geo::Vector::Layer::Dialogs::New;
# @brief 

use strict;
use warnings;
use Carp;
use Glib qw/TRUE FALSE/;
use Gtk2::Ex::Geo::Dialogs qw/:all/;
use Geo::GDAL;

## @ignore
sub open {
    my($gui) = @_;
    my $self = { gui => $gui };

    # bootstrap:
    my($dialog, $boot) = Gtk2::Ex::Geo::Layer::bootstrap_dialog
	($self, $gui, 'new_dialog', "Create new vector",
	 {
	     new_dialog => [delete_event => \&cancel_new_copy, $self],
	     new_vector_add_button => [clicked=>\&add_field_to_schema, $self],
	     new_vector_delete_button => [clicked=>\&delete_field_from_schema, $self],
	     new_vector_cancel_button => [clicked => \&cancel_new_vector, $self],
	     new_vector_ok_button => [clicked => \&ok_new_vector, $self],
	 },
	 [
	  'new_vector_class_combobox',
	  'new_vector_driver_combobox',
	  'new_vector_data_source_combobox',
	  'new_vector_geometry_type_combobox'
	 ]
	);

    if ($boot) {
	my $combo = $dialog->get_widget('new_vector_class_combobox');
	my $model = $combo->get_model();
	for my $n ('OGR Layer', 'Feature collection') {
	    $model->set ($model->append, 0, $n);
	}
	$combo->set_active(0);

	$combo = $dialog->get_widget('new_vector_driver_combobox');
	$model = $combo->get_model();
	$model->set ($model->append, 0, '');
	for my $driver (Geo::OGR::Drivers()) {
	    my $n = $driver->FormatName;
	    $n = $driver->GetName unless $n;
	    $self->{drivers}{$n} = $driver->GetName;
	    $model->set ($model->append, 0, $n);
	}
	$combo->set_active(0);

	$combo = $dialog->get_widget('new_vector_data_source_combobox');
	$model = $combo->get_model();
	$model->set ($model->append, 0, '');
	for my $data_source (sort keys %{$gui->{resources}{datasources}}) {
	    $model->set ($model->append, 0, $data_source);
	}
	$combo->set_active(0);

	# replace with @Geo::OGR::Geometry::GEOMETRY_TYPES
	# when new GDAL comes out

	my @GEOMETRY_TYPES = qw/Unknown 
			Point LineString Polygon
			MultiPoint MultiLineString MultiPolygon GeometryCollection
			None LinearRing
			Point25D LineString25D Polygon25D
			MultiPoint25D MultiLineString25D MultiPolygon25D GeometryCollection25D/;

	$combo = $dialog->get_widget('new_vector_geometry_type_combobox');
	$model = $combo->get_model();
	for my $type (@GEOMETRY_TYPES) {
	    $model->set ($model->append, 0, $type);
	}
	$combo->set_active(0);
    }
    
    $dialog->get_widget('new_vector_open_button')
	->signal_connect( clicked => sub {
	    my(undef, $self) = @_;
	    my $entry = $self->{new_dialog}->get_widget('new_vector_folder_entry');
	    file_chooser('Select folder', 'select_folder', $entry);
			  }, $self );
    
    my $name = 'a';
    for my $n ('a'..'z') {
	$name = $n, last unless $gui->layer($n);
    }
    $dialog->get_widget('new_vector_layer_entry')->set_text($name);
    $self->{schema} = schema_to_treeview($self, $dialog->get_widget('new_vector_schema_treeview'), 1);
    return $dialog->get_widget('new_dialog');
}

sub schema_to_treeview {
    my($self, $treeview, $editable, $schema) = @_;

    # remove existing columns from treeview first
    my $column;
    while ($column = $treeview->get_column(0)) {
	$treeview->remove_column($column);
    }

    my $model = Gtk2::TreeStore->new(qw/Glib::String Glib::String Glib::String Glib::Int Glib::Int/);
    $treeview->set_model($model);

    my $i = 0;
    my $cell = Gtk2::CellRendererText->new;
    $cell->set(editable => $editable);
    $cell->signal_connect(edited => \&schema_changed, [$self, $i]);
    $column = Gtk2::TreeViewColumn->new_with_attributes('Name', $cell, text => $i++);
    $treeview->append_column($column);

    # replace with @Geo::OGR::FieldDefn::FIELD_TYPES
    # and @Geo::OGR::FieldDefn::JUSTIFY_TYPES
    # when new GDAL comes out

    my @FIELD_TYPES = qw/Integer IntegerList Real RealList String StringList
		         WideString WideStringList Binary Date Time DateTime/;
    my @JUSTIFY_TYPES = qw/Undefined Left Right/;

    $cell = Gtk2::CellRendererCombo->new;
    $cell->set(editable => $editable);
    $cell->set(text_column => 0);
    $cell->set(has_entry => 0);
    $cell->signal_connect(edited => \&schema_changed, [$self, $i]);
    my $m = Gtk2::ListStore->new('Glib::String');
    for my $type (@FIELD_TYPES) {
	$m->set($m->append, 0, $type);
    }
    $cell->set(model=>$m);
    $column = Gtk2::TreeViewColumn->new_with_attributes('Type', $cell, text => $i++);
    $treeview->append_column($column);

    $cell = Gtk2::CellRendererCombo->new;
    $cell->set(editable => $editable);
    $cell->set(text_column => 0);
    $cell->set(has_entry => 0);
    $cell->signal_connect(edited => \&schema_changed, [$self, $i]);
    $m = Gtk2::ListStore->new('Glib::String');
    for my $type (@JUSTIFY_TYPES) {
	$m->set($m->append, 0, $type);
    }
    $cell->set(model=>$m);
    $column = Gtk2::TreeViewColumn->new_with_attributes('Justify', $cell, text => $i++);
    $treeview->append_column($column);

    $cell = Gtk2::CellRendererText->new;
    $cell->set(editable => $editable);
    $cell->signal_connect(edited => \&schema_changed, [$self, $i]);
    $column = Gtk2::TreeViewColumn->new_with_attributes('Width', $cell, text => $i++);
    $treeview->append_column($column);

    $cell = Gtk2::CellRendererText->new;
    $cell->set(editable => $editable);
    $cell->signal_connect(edited => \&schema_changed, [$self, $i]);
    $column = Gtk2::TreeViewColumn->new_with_attributes('Precision', $cell, text => $i++);
    $treeview->append_column($column);

    if ($schema) {
	for my $field ( $schema->fields ) {
	    next if $field->{Name} =~ /^\./;
	    my $iter = $model->append(undef);
	    my @set = ($iter);
	    my $i = 0;
	    push @set, ($i++, $field->{Name});
	    push @set, ($i++, $field->{Type});
	    push @set, ($i++, $field->{Justify});
	    push @set, ($i++, $field->{Width});
	    push @set, ($i++, $field->{Precision});
	    $model->set(@set);
	}
    }

    return $model;
}

sub schema_changed {
    my($cell, $path, $new_value, $data) = @_;
    my($self, $column) = @$data;
    my $iter = $self->{schema}->get_iter_from_string($path);
    my @set = ($iter, $column, $new_value);
    $self->{schema}->set(@set);
}

## @ignore
sub cancel_new_vector {
    my $self = pop;
    $self->{new_dialog}->get_widget('new_dialog')->destroy;
}

## @ignore
sub ok_new_vector {
    my $self = pop;
    my $d = $self->{new_dialog};
    my $layer;
    my $class = get_value_from_combo($d, 'new_vector_class_combobox');
    my $name = $d->get_widget('new_vector_layer_entry')->get_text;
    $name = 'x' unless $name;
    if ($class eq 'Feature collection') {
	$self->{gui}->add_layer(Geo::Vector->new(features=>[]), $name, 1);
	$self->{new_dialog}->get_widget('new_dialog')->destroy;
	return;
    }
    my $driver = get_value_from_combo($d, 'new_vector_driver_combobox');
    $driver = $self->{drivers}{$driver};
    my $create_options = $d->get_widget('new_vector_create_options_entry')->get_text;
    $create_options = {split(/[(=>),]/,$create_options)};
    my $data_source = get_value_from_combo($d, 'new_vector_data_source_combobox');
    $data_source = $d->get_widget('new_vector_folder_entry')->get_text unless $data_source;
    my $layer_options = $d->get_widget('new_vector_layer_options_entry')->get_text;
    my $geometry_type = get_value_from_combo($d, 'new_vector_geometry_type_combobox');
    my $encoding = $d->get_widget('new_vector_encoding_entry')->get_text;
    my $srs = $d->get_widget('new_vector_srs_entry')->get_text;
    my %schema = ( Fields => [] );
    $self->{schema}->foreach(sub {
	my($model, $path, $iter) = @_;
	my @row = $model->get($iter);
	push @{$schema{Fields}},
	{ Name => $row[0],
	  Type => $row[1],
	  Justify => $row[2],
	  Width => $row[3],
	  Precision => $row[4]
	};
	0;
			     });
    eval {
	$layer = Geo::Vector::Layer->new
	    ( driver => $driver,
	      create_options => $create_options,
	      data_source => $data_source, 
	      create => $name,
	      layer_options => $layer_options,
	      geometry_type => $geometry_type,
	      encoding => $encoding,
	      srs => $srs,
	      schema => \%schema
	    );
    };
    if ($@) {
	my $err = $@;
	if ($err) {
	    $err =~ s/\n/ /g;
	    $err =~ s/\s+$//;
	    $err =~ s/\s+/ /g;
	    $err =~ s/^\s+$//;
	} else {
	    $err = "unknown error";
	}
	$self->{gui}->message("Could not create a vector layer: $err");
	return;
    }
    $self->{gui}->add_layer($layer, $name, 1);
    $self->{new_dialog}->get_widget('new_dialog')->destroy;
}

## @ignore
sub add_field_to_schema {
    my $self = pop;
    my $iter = $self->{schema}->append(undef);
    my @set = ($iter);
    my $i = 0;
    push @set, ($i++, 'name');
    push @set, ($i++, 'Integer');
    push @set, ($i++, 'Undefined');
    push @set, ($i++, 8);
    push @set, ($i++, 0);
    $self->{schema}->set(@set);
}

## @ignore
sub delete_field_from_schema {
    my $self = pop;
    my $treeview = $self->{new_dialog}->get_widget('new_vector_schema_treeview');
    my($path, $focus_column) = $treeview->get_cursor;
    return unless $path;
    my $iter = $self->{schema}->get_iter($path);
    $self->{schema}->remove($iter);
}

1;
