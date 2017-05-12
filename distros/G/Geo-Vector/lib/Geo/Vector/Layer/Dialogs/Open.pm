package Geo::Vector::Layer::Dialogs::Open;
# @brief 

use strict;
use warnings;
use Carp;
use Encode;
use Glib qw/TRUE FALSE/;
use Gtk2::Ex::Geo::Dialogs qw/:all/;
use Geo::Vector::Layer::Dialogs qw/:all/;
require Win32::DriveInfo if $Config::Config{'osname'} eq 'MSWin32';

## @ignore
sub open {
    my($gui) = @_;
    my $self = { gui => $gui };

    # bootstrap:
    my($dialog, $boot) = Gtk2::Ex::Geo::Layer::bootstrap_dialog
	($self, $gui, 'open_dialog', "Open vector layer",
	 {
	     open_dialog => [delete_event => \&cancel_open_vector, $self],
	     open_vector_delete_datasource_button => [clicked => \&delete_data_source, $self],
	     open_vector_connect_datasource_button => [clicked => \&connect_data_source, $self],
	     open_vector_remove_button => [clicked => \&remove_layer, $self],
	     open_vector_schema_button => [clicked => \&show_schema, $self],
	     open_vector_cancel_button => [clicked => \&cancel_open_vector, $self],
	     open_vector_ok_button => [clicked => \&open_vector, $self],
	     open_vector_auto_update_schema_checkbutton => [toggled => \&show_schema, $self],
	 },
	 [
	  'open_vector_driver_combobox',
	  'filesystem_driver_combobox',
	  'open_vector_datasource_combobox'
	 ]
	);
    
    if ($boot) {
	my $combo = $dialog->get_widget('open_vector_driver_combobox');
	my $model = $combo->get_model();
	for my $driver (Geo::OGR::Drivers()) {
	    my @t = $driver->DataSourceTemplate;
	    next if $t[0] eq '<filename>';
	    my $n = $driver->FormatName;
	    $model->set ($model->append, 0, $n);
	}
	$combo->set_active(0);
	
	$combo = $dialog->get_widget('filesystem_driver_combobox');
	$model = $combo->get_model();
	$model->set ($model->append, 0, 'auto');
	for my $driver (Geo::OGR::Drivers()) {
	    my $n = $driver->GetName;
	    $model->set ($model->append, 0, $n);
	}
	$combo->set_active(0);
	
	$dialog->get_widget('open_vector_datasource_combobox')
	    ->signal_connect(changed => sub { empty_layer_data($_[1]) }, $self);
	
	$dialog->get_widget('open_vector_build_connection_button')
	    ->signal_connect(clicked => \&build_data_source, $self);
	
	fill_named_data_sources_combobox($self);
    
	my $treeview = $dialog->get_widget('open_vector_directory_treeview');
	$treeview->set_model(Gtk2::TreeStore->new('Glib::String'));
	my $cell = Gtk2::CellRendererText->new;
	my $col = Gtk2::TreeViewColumn->new_with_attributes('', $cell, markup => 0);
	$treeview->append_column($col);
	$treeview->signal_connect(
	    button_press_event => sub 
	    {
		my($treeview, $event, $self) = @_;
		select_directory($self, $treeview) if $event->type =~ /^2button/;
		return 0;
	    }, $self);
	
	$treeview->signal_connect(
	    key_press_event => sub
	    {
		my($treeview, $event, $self) = @_;
		select_directory($self, $treeview) if $event->keyval == $Gtk2::Gdk::Keysyms{Return};
		return 0;
	    }, $self);
	
	$treeview = $dialog->get_widget('open_vector_layer_treeview');
	$treeview->set_model(Gtk2::TreeStore->new(qw/Glib::String Glib::String/));
	$treeview->get_selection->set_mode('multiple');
	my $i = 0;
	for my $column ('layer', 'geometry') {
	    my $cell = Gtk2::CellRendererText->new;	    
	    my $col = Gtk2::TreeViewColumn->new_with_attributes($column, $cell, text => $i++);
	    $treeview->append_column($col);
	}
	$treeview->signal_connect(cursor_changed => \&on_layer_treeview_cursor_changed, $self);
	
	$treeview = $dialog->get_widget('open_vector_property_treeview');
	$treeview->set_model(Gtk2::TreeStore->new(qw/Glib::String Glib::String/));
	$i = 0;
	foreach my $column ('property', 'value') {
	    my $cell = Gtk2::CellRendererText->new;
	    if ($column eq 'value') {
		$cell->set(wrap_width => 400);
		$cell->set(wrap_mode => 'word');
	    }
	    my $col = Gtk2::TreeViewColumn->new_with_attributes($column, $cell, text => $i++);
	    $treeview->append_column($col);
	}
	
	$treeview = $dialog->get_widget('open_vector_schema_treeview');
	$treeview->set_model(Gtk2::TreeStore->new(qw/Glib::String Glib::String/));
	$i = 0;
	foreach my $column ('field', 'type') {
	    my $cell = Gtk2::CellRendererText->new;
	    my $col = Gtk2::TreeViewColumn->new_with_attributes($column, $cell, text => $i++);
	    $treeview->append_column($col);
	}
	
	$self->{directory_toolbar} = [];

	my $entry = $dialog->get_widget('open_vector_SQL_entry');
	$entry->signal_connect(key_press_event => sub {
	    my($entry, $event, $history) = @_;
	    my $key = $event->keyval;
	    if ($key == $Gtk2::Gdk::Keysyms{Up}) {
		$entry->set_text($history->arrow_up);
		return 1;
	    } elsif ($key == $Gtk2::Gdk::Keysyms{Down}) {
		$entry->set_text($history->arrow_down);
		return 1;
	    }
			       }, $self->{gui}{history});
	$entry->signal_connect(changed => \&on_SQL_entry_changed, $self);
    }
    
    $self->{path} = $gui->{folder} if $gui->{folder};
    $self->{path} = File::Spec->rel2abs('.') unless $self->{path};

    fill_directory_treeview($self);
    fill_layer_treeview($self);

    $dialog->get_widget('open_vector_update_checkbutton')->set_active(0);

}

## @ignore
sub fill_named_data_sources_combobox {
    my($self, $default) = @_;
    $default = '' unless $default;
    my $model = Gtk2::ListStore->new('Glib::String');
    $model->set($model->append, 0, '');
    my $i = 1;
    my $active = 0;
    for my $data_source (sort keys %{$self->{gui}{resources}{datasources}}) {
	$model->set ($model->append, 0, $data_source);
	$active = $i if $data_source eq $default;
	$i++;
    }
    my $combo = $self->{open_dialog}->get_widget('open_vector_datasource_combobox');
    $combo->set_model($model);
    $combo->set_active($active);
}

## @ignore
sub get_data_source {
    my $self = shift;
    my $combo = $self->{open_dialog}->get_widget('open_vector_datasource_combobox');
    my $active = $combo->get_active();
    my $data_source = $self->{path};
    return ('', $data_source) if $active < 0;
    my $model = $combo->get_model;
    my $iter = $model->get_iter_from_string($active);
    my $driver = $model->get($iter, 0);
    if ($driver eq '') {
	my $d = get_value_from_combo($self->{open_dialog}, 'filesystem_driver_combobox');
	$driver = $d unless $d eq 'auto';
	#if ($driver eq 'GeoJSON') { # hack
	#    $data_source = "file:/$data_source";
	#}
	return ($driver, $data_source);
    }
    return @{$self->{gui}{resources}{datasources}{$driver}};
}

##@ignore
sub open_vector {
    my($button, $self) = @_;

    my $dialog = $self->{open_dialog};
    $self->{gui}->{folder} = $self->{path};

    my($driver, $data_source) = get_data_source($self);

    my $sql = $dialog->get_widget('open_vector_SQL_entry')->get_text;
    $sql =~ s/^\s+//;
    $sql =~ s/\s+$//;
    $self->{gui}{history}->editing($sql);

    unless ($driver) {
	my $d = get_value_from_combo($dialog, 'filesystem_driver_combobox');
	$driver = $d unless $d eq 'auto';
    }
    my $layers = get_selected_from_selection($dialog->get_widget('open_vector_layer_treeview')->get_selection);

    if ($sql) {
	$self->{gui}{history}->enter();
	$dialog->get_widget('open_vector_SQL_entry')->set_text('');
    }
	
    my $wish = $dialog->get_widget('open_vector_layer_name_entry')->get_text;
    my $update = $dialog->get_widget('open_vector_update_checkbutton')->get_active;
    my $hidden = $dialog->get_widget('open_vector_open_hidden_button')->get_active;
	
    for my $name (keys %$layers) {
	my $layer;
	my $encoding = 'utf8' if $data_source =~ /^Pg:/; # not really the case always but...
	eval {
	    my %params = ( data_source => $data_source,
			   open        => $name,
			   sql         => $sql,
			   update      => $update,
			   encoding    => $encoding );
	    $params{driver} = $driver unless $driver eq 'auto';
	    $layer = Geo::Vector::Layer->new(%params);
	};
	if ($@) {
	    my $err = $@;
	    if ($err) {
		$err =~ s/\n/ /g;
		$err =~ s/\s+$//;
		$err =~ s/\s+/ /g;
		$err =~ s/^\s+$//;
	    } else {
		$err = "data_source=$data_source, layer=$name, sql=$sql, update=$update";
	    }
	    $self->{gui}->message("Could not open layer: $err");
	    return;
	}
	$name = $wish if (keys %$layers) == 1;
	$layer->visible(0) if $hidden;
	$self->{gui}->add_layer($layer, $name, 1);
    }
    $self->{gui}{tree_view}->set_cursor(Gtk2::TreePath->new(0));
    $self->{gui}{overlay}->render;
    delete $self->{directory_toolbar};
    $dialog->get_widget('open_dialog')->destroy;
}

##@ignore
sub cancel_open_vector {
    my $self = pop;
    delete $self->{directory_toolbar};
    $self->{open_dialog}->get_widget('open_dialog')->destroy;
}

##@ignore
sub remove_layer {
    my($button, $self) = @_;
    my($driver, $data_source) = get_data_source($self);
    my $layers = get_selected_from_selection(
	$self->{open_dialog}->get_widget('open_vector_layer_treeview')->get_selection);
    eval {
	my $ds = Geo::OGR::Open($data_source, 1);
	for my $i (0..$ds->GetLayerCount-1) {
	    my $l = $ds->GetLayerByIndex($i);
	    $ds->DeleteLayer($i) if $layers->{$l->GetName()};
	}
    };
    $self->{gui}->message("$@") if $@;
}

##@ignore
sub fill_directory_treeview {
    my $self = shift;
    my $treeview = $self->{open_dialog}->get_widget('open_vector_directory_treeview');
    my $model = $treeview->get_model;
    $model->clear;

    my $toolbar = $self->{open_dialog}->get_widget('open_vector_directory_toolbar');
    for (@{$self->{directory_toolbar}}) {
	$toolbar->remove($_);
    }
    $self->{directory_toolbar} = [];

    if ($self->{path} eq '') {
	@{$self->{dir_list}} = ();
	my @d = Win32::DriveInfo::DrivesInUse();

	#my $fso = Win32::OLE->new('Scripting.FileSystemObject');
	#for ( in $fso->Drives ) {
	#    push @d, $_->{DriveLetter}.':';
	#}
	for (@d) {
	    $_ .= ':';
	}

	for (@d) {
	    s/\\$//;
	    push @{$self->{dir_list}},$_;
	}
	@{$self->{dir_list}} = reverse @{$self->{dir_list}} if $self->{dir_list};
	for my $i (0..$#{$self->{dir_list}}) {
	    my $iter = $model->insert (undef, 0);
	    $model->set ($iter, 0, $self->{dir_list}->[$i] );
	}
	$self->{open_dialog}->get_widget('open_vector_directory_treeview')->set_cursor(Gtk2::TreePath->new(0));
	@{$self->{dir_list}} = reverse @{$self->{dir_list}} if $self->{dir_list};
	return;
    }

    my($volume, $directories, $file) = File::Spec->splitpath($self->{path}, 1);
    $self->{volume} = $volume;
    my @dirs = File::Spec->splitdir($directories);
    unshift @dirs, File::Spec->rootdir();
    if ($^O eq 'MSWin32') {
	unshift @dirs, $volume;
    }
    
    for (reverse @dirs) {
	next if /^\s*$/;
	my $filename;
	eval {
	    $filename = Glib->filename_to_unicode($_);
	};
	next if $@;
	#my $label = Gtk2::Label->new($filename) if Gtk2->CHECK_VERSION(2, 18, 0);
	my $label = Gtk2::Label->new($filename) unless $Config::Config{'osname'} eq 'MSWin32';
	my $b = Gtk2::ToolButton->new($label, $filename);
	$b->signal_connect(
	    clicked => sub {
		my($button, $self) = @_;
		$self->{open_dialog}->get_widget('open_vector_datasource_combobox')->set_active(0);
		my $n = $button->get_label;
		if ($n eq $self->{volume}) {
		    $self->{path} = '';
		} else {
		    my @directories;
		    for (reverse @{$self->{directory_toolbar}}) {
			push @directories, $_->get_label;
			last if $_ == $_[0];
		    }
		    if ($^O eq 'MSWin32') {
			shift @directories; # remove volume
		    }
		    my $directory = File::Spec->catdir(@directories);
		    $self->{path} = File::Spec->catpath($self->{volume}, $directory, '');
		}
		fill_directory_treeview($self);
		fill_layer_treeview($self);
	    },
	    $self);
	#$label->show;
	$b->show_all;
	$toolbar->insert($b,0);
	push @{$self->{directory_toolbar}}, $b;
    }
    
    @{$self->{dir_list}} = ();

    my @files;
    eval {
	@files = Geo::GDAL::ReadDir($self->{path});
    };
    @dirs = ();
    my @fs;
    for (sort {$b cmp $a} @files) {
	my $test = File::Spec->catfile($self->{path}, $_);
	my $m;
	eval {
	    ($m) = Geo::GDAL::Stat($test);
	};
	next if $@;
	my $is_dir = $m eq 'd';
	next if (/^\./ and not $_ eq File::Spec->updir);
	next if $_ eq File::Spec->curdir;
	s/&/&amp;/g;
	s/</&lt;/g;
	s/>/&gt;/g;
	if ($is_dir) {
	    push @dirs, "<b>[$_]</b>";
	} else {
	    push @fs, $_;
	}
    }
    for (@fs) {
	push @{$self->{dir_list}}, $_;
    }
    for (@dirs) {
	push @{$self->{dir_list}}, $_;
    }

    # in a file
    push @{$self->{dir_list}},'..' unless @{$self->{dir_list}};
	
    for (@{$self->{dir_list}}) {
	my $iter = $model->insert(undef, 0);
	eval {
	    $_ = Glib->filename_to_unicode($_);
	};
	next if $@;
	$model->set($iter, 0, $_ );
    }
	
    $treeview->set_cursor(Gtk2::TreePath->new(0));

    @{$self->{dir_list}} = reverse @{$self->{dir_list}};
}

## @ignore
sub empty_layer_data {
    my($self) = @_;
    my $model = $self->{open_dialog}->get_widget('open_vector_layer_treeview')->get_model;
    $model->clear if $model;
    $model = $self->{open_dialog}->get_widget('open_vector_property_treeview')->get_model;
    $model->clear if $model;
    $model = $self->{open_dialog}->get_widget('open_vector_schema_treeview')->get_model;
    $model->clear if $model;
}

## @ignore
sub fill_layer_treeview {
    my($self) = @_;

    empty_layer_data($self);

    my $treeview = $self->{open_dialog}->get_widget('open_vector_layer_treeview');
    my $model = $treeview->get_model;

    my($driver, $data_source) = get_data_source($self);
    return unless $data_source;

    $self->{_open_data_source} = $data_source;
    my $layers;
    eval {
	$driver = '' unless $driver;
	#print STDERR "layers: $driver, $data_source\n";
        $layers = Geo::Vector::layers($driver, $data_source);
    };
    my @layers = sort {$b cmp $a} keys %$layers;
    if (@layers) {
        for my $name (@layers) {
            my $iter = $model->insert (undef, 0);
	    my $u;
	    eval {
		$u = Glib->filename_to_unicode($name);
	    };
	    next if $@;
            $model->set ($iter, 0, $u, 1, $layers->{$name});
        }
        $treeview->set_cursor(Gtk2::TreePath->new(0));
    } 
    else {
        my $iter = $model->insert (undef, 0);
        $model->set ($iter, 0, "no layers found", 1, "");
        unless ($@ =~ /no reason given/) {
            $@ =~ s/RuntimeError\s+//;
            $@ =~ s/FATAL:\s+(\w)/uc($1)/e;
            $@ =~ s/\s+at\s+\w+\.\w+\s+line\s+\d+\s+//;
            $model->set ($model->append(undef), 0, $@, 1, "");
        }
    }
    on_layer_treeview_cursor_changed($treeview, $self);
    return @layers > 0;
}

## @ignore
sub on_SQL_entry_changed {
    my($entry, $self) = @_;
    my $sql = $entry->get_text;
    $sql =~ s/^\s+//;
    $sql =~ s/\s+$//;
    $self->{open_dialog}->get_widget('open_vector_layer_name_entry')->set_text('SQL') if $sql;
}

## @ignore
sub on_layer_treeview_cursor_changed {
    my($treeview, $self) = @_;
    my($path, $focus_column) = $treeview->get_cursor;
    if ($path) {
	my $model = $treeview->get_model;
	my $iter = $model->get_iter($path);
	my $layer_name = $model->get($iter, 0);
	$self->{open_dialog}->get_widget('open_vector_layer_name_entry')->set_text($layer_name);
    }
    if ($self->{open_dialog}->get_widget('open_vector_auto_update_schema_checkbutton')->get_active()) {
	show_schema(undef, $self);
    } else {
	$self->{open_dialog}->get_widget('open_vector_property_treeview')->get_model->clear;
	$self->{open_dialog}->get_widget('open_vector_schema_treeview')->get_model->clear;
	$self->{open_dialog}->get_widget('open_vector_schema_label')->set_label('');
    }
    $self->{gui}{history}->editing('');
    $self->{open_dialog}->get_widget('open_vector_SQL_entry')->set_text('');
}

## @ignore
sub build_data_source {
    my($button, $self) = @_;
    my $combo = $self->{open_dialog}->get_widget('open_vector_driver_combobox');
    my $index = $combo->get_active;
    my $code = '';
    my $format;
    my $template = '';
    my $help = '';
    my $i = -1;
    for my $driver (Geo::OGR::Drivers()) {
	($template, $help) = $driver->DataSourceTemplate;
	next if $template eq '<filename>';
	$i++;
	next unless $i == $index;
	$code = $driver->GetName;
	$format = $driver->FormatName;
	last;
    }
    my @template = split(/[\[\]]/, $template);
    #print STDERR "build $code data source, t = $template\n";

    # ask from user the name for the new data source, and things defined by the template
    my $data_source_name;
    my %input;
    my @ask;
    $i = 0;
    for my $c (@template) {
	my @c = $c =~ /\<(\w+)\>/;
	if ($i % 2 == 1) { # optional
	} else {
	    for (@c) {
		$_ .= '*';
	    }
	}
	push @ask, @c;
	$i++;
    }

    my $dialog = Gtk2::Dialog->new('Build a non-file data source', 
				   $self->{open_dialog}->get_widget('open_dialog'),
				   'destroy-with-parent',
				   'gtk-cancel' => 'reject',
				   'gtk-ok' => 'ok');
    
    my $vbox = Gtk2::VBox->new(FALSE, 0);
    $vbox->pack_start(Gtk2::Label->new("Define a connection to a $format data source"), FALSE, FALSE, 0);

    my $table = Gtk2::Table->new(1+@ask, 2, TRUE);
    $table->attach(Gtk2::Label->new("Unique name for the data source*:"), 0, 1, 0, 1, 'fill', 'fill', 0, 0);
    my $e = Gtk2::Entry->new();
    $e->set_name('data_source_name');
    $table->attach($e, 1, 2, 0, 1, 'fill', 'fill', 0, 0);
    $i = 1;
    for my $a (@ask) {
	my $l = Gtk2::Label->new($a.":");
	$l->set_justify('left');
	$table->attach($l, 0, 1, $i, $i+1, 'expand', 'fill', 0, 0);
	$e = Gtk2::Entry->new();
	$a =~ s/\*$//;
	$e->set_name($a);
	$table->attach($e, 1, 2, $i, $i+1, 'fill', 'fill', 0, 0);
	$i++;
    }
    $vbox->pack_start($table, FALSE, TRUE, 0);

    my $l = Gtk2::Label->new("* denotes a required entry");
    $l->set_justify('left');
    $vbox->pack_start($l, FALSE, TRUE, 0);
    $l = Gtk2::Label->new($help);
    $l->set_justify('left');
    $vbox->pack_start($l, FALSE, TRUE, 0);

    $dialog->get_content_area()->add($vbox);
 
    $dialog->signal_connect(response => \&add_data_source, [$self, $template, $code]);
    $dialog->show_all;
}

## @ignore
sub get_entries {
    my($widget, $entries) = @_;
    if ($widget->isa('Gtk2::Container')) {
	$widget->foreach(\&get_entries, $entries);
    } elsif ($widget->isa('Gtk2::Entry')) {
	my $n = $widget->get_name;
	my $t = $widget->get_text;
	if ($n and $t) {
	    $entries->{$n} = $t;
	}
    }
}

## @ignore
sub add_data_source {
    my($dialog, $response, $x) = @_;

    unless ($response eq 'ok') {
	$dialog->destroy;
	return;
    }

    my($self, $template, $driver) = @$x;

    my %input;

    get_entries($dialog, \%input);

    my @template = split(/[\[\]]/, $template);
    # build connection string;
    my $connection_string = '';
    # at indexes 1,3,.. the contents are optional
    my $i = 0;
    for my $c (@template) {
	my @c = $c =~ /\<(\w+)\>/;
	my $got_input = 0;
	for my $k (keys %input) {
	    for my $p (@c) {
		$got_input = 1 if $k eq $p;
	    }
	    $c =~ s/\<$k\>/$input{$k}/;
	}
	if ($i % 2 == 1) { # optional
	    if ($got_input) {
		$connection_string .= $c;
	    }
	} else {
	    $connection_string .= $c;
	}
	$i++;
    }

    #print STDERR "connection string: $connection_string\n";
    $self->{gui}{resources}{datasources}{$input{data_source_name}} = [$driver, $connection_string];
    fill_named_data_sources_combobox($self, $input{data_source_name});

    # Ensure that the dialog box is destroyed when the user responds.
    $dialog->destroy;
}

## @ignore
sub delete_data_source {
    my($button, $self) = @_;
    my $combo = $self->{open_dialog}->get_widget('open_vector_datasource_combobox');
    my $active = $combo->get_active();
    return if $active < 0;

    my $model = $combo->get_model;
    my $iter = $model->get_iter_from_string($active);
    my $name = $model->get($iter, 0);
    return if $name eq '';

    $model->remove($iter);
    delete $self->{gui}{resources}{datasources}{$name};
}

## @ignore
sub connect_data_source {
    my($button, $self) = @_;
    unless (fill_layer_treeview($self)) {
	# No layers found in data source
	fill_directory_treeview($self);
    }
}

## @ignore
sub select_directory {
    my($self, $treeview) = @_;

    my $combo = $self->{open_dialog}->get_widget('open_vector_driver_combobox');
    $combo->set_active(0) if $combo->get_active;
    $self->{open_dialog}->get_widget('open_vector_layer_treeview')->get_model->clear;

    my($path, $focus_column) = $treeview->get_cursor;
    my $index = $path->to_string if $path;
    if (defined $index) {
	my $dir = $self->{dir_list}->[$index];
	$dir =~ s/^<b>\[//;
	$dir =~ s/\]<\/b>$//;
	my $directory;
	if ($self->{path} eq '') {
	    $self->{volume} = $dir;
	    $directory = File::Spec->rootdir();
	} else {
	    my @directories;
	    for (reverse @{$self->{directory_toolbar}}) {
		push @directories, $_->get_label;
	    }
	    if ($^O eq 'MSWin32') {
		shift @directories; # remove volume
	    }
	    if ($dir eq File::Spec->updir) {
		pop @directories;
	    } else {
		push @directories, $dir;
	    }
	    $directory = File::Spec->catdir(@directories);
	}
	$self->{path} = File::Spec->catpath($self->{volume}, $directory, '');
	fill_directory_treeview($self);
	fill_layer_treeview($self);
    }
}

## @ignore
sub show_schema {
    my($button, $self) = @_ == 2 ? @_ : (undef, $_[0]);
    
    my $property_model = $self->{open_dialog}->get_widget('open_vector_property_treeview')->get_model;
    $property_model->clear;
    my $schema_model = $self->{open_dialog}->get_widget('open_vector_schema_treeview')->get_model;
    $schema_model->clear;
    my $label = '';
    my $sql = $self->{open_dialog}->get_widget('open_vector_SQL_entry')->get_text;

    my $vector;
    if ($sql) {

	eval {
	    $vector = Geo::Vector->new( data_source => $self->{_open_data_source}, 
					sql => $sql );
	};
	croak("$@ Is the SQL statement correct?") if $@;
	$label = 'Schema of the SQL query';
	
    } else {

	my $treeview = $self->{open_dialog}->get_widget('open_vector_layer_treeview');
	my($path, $focus_column) = $treeview->get_cursor;
	return unless $path;
	my $model = $treeview->get_model;
	my $iter = $model->get_iter($path);
	my $name = $model->get($iter, 0);
	if (defined $name) {
	    $vector = Geo::Vector->new( data_source => $self->{_open_data_source}, 
					open => $name );
	    $label = "Schema of $name";
	}

    }

    $self->{open_dialog}->get_widget('open_vector_schema_label')->set_label($label);
    
    my $iter = $property_model->insert (undef, 0);
    $property_model->set ($iter,
			  0, 'Features',
			  1, $vector->feature_count()
			  );
    
    my @world = $vector->world;
    @world = ('undef','undef','undef','undef') unless @world;
    $iter = $property_model->insert (undef, 0);
    $property_model->set ($iter,
			  0, 'Bounding box',
			  1, "minX = $world[0], minY = $world[1], maxX = $world[2], maxY = $world[3]"
			  );
    
    $iter = $property_model->insert (undef, 0);
    my $srs = $vector->srs(format=>'Wkt');
    $srs = 'undefined' unless $srs;
    $property_model->set ($iter,
			  0, 'SpatialRef',
			  1, $srs
			  );
    
    my $schema = $vector->schema();
    for my $field (@{$schema->{Fields}}) {
	my $iter = $schema_model->insert(undef, 0);
	$schema_model->set ($iter,
			    0, $field->{Name},
			    1, $field->{Type}
	    );
    }
    
}

1;
