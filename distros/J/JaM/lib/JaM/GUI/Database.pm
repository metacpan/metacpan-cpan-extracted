# $Id: Database.pm,v 1.4 2001/08/29 19:49:29 joern Exp $

package JaM::GUI::Database;

@ISA = qw ( JaM::GUI::Window );

use strict;
use JaM::GUI::Window;
use JaM::Database;

my $DEBUG = 1;

my %fields = (
	dbi_source	=> "DBI Data Source",
	dbi_username	=> "Username",
	dbi_password	=> "Password",
);

my @field_order = qw(
	dbi_source
	dbi_username
	dbi_password
);

sub gtk_entries		{ my $s = shift; $s->{gtk_entries}
		          = shift if @_; $s->{gtk_entries}	}

sub gtk_dialog		{ my $s = shift; $s->{gtk_dialog}
		          = shift if @_; $s->{gtk_dialog}	}

sub gtk_status		{ my $s = shift; $s->{gtk_status}
		          = shift if @_; $s->{gtk_status}	}

sub gtk_ok_button	{ my $s = shift; $s->{gtk_ok_button}
		          = shift if @_; $s->{gtk_ok_button}	}

sub database		{ my $s = shift; $s->{database}
		          = shift if @_; $s->{database}		}

sub in_initialization	{ my $s = shift; $s->{in_initialization}
		          = shift if @_; $s->{in_initialization}	}

sub update_successful	{ my $s = shift; $s->{update_successful}
		          = shift if @_; $s->{update_successful}	}

sub single_instance_window { 1 }

sub build {
	my $self = shift; $self->trace_in;

	my $dialog = Gtk::Dialog->new;
	$dialog->border_width(10);
	$dialog->set_position('center');
	$dialog->set_title ("Edit Database Information");
	$dialog->set_default_size (400, 180);
	$dialog->action_area->set_homogeneous (1);

	$dialog->signal_connect("destroy" => sub { Gtk->exit(0) } )
		if $self->in_initialization;

	my $table = Gtk::Table->new ( scalar(@field_order), 2, 0 );
	$table->show;

	my (%entries, $i);
	foreach my $field ( @field_order ) {
		my $label = Gtk::Label->new ($fields{$field});
		$label->show;
		$label->set_justify ('left');
		my $entry;
		$entry = Gtk::Entry->new;
		$entry->set_visibility (0) if $field =~ /password/;
		$entry->show;
		$table->attach_defaults ($label, 0, 1, $i, $i+1);
		$table->attach_defaults ($entry, 1, 2, $i, $i+1);
		$entries{$field} = $entry;
		++$i;
	}

	$table->set_row_spacings ( 2 );
	$table->set_col_spacings ( 2 );

	$dialog->vbox->pack_start ($table, 1, 1, 0);

	my $text_table = new Gtk::Table( 2, 2, 0 );
	$text_table->set_row_spacing( 0, 2 );
	$text_table->set_col_spacing( 0, 2 );
	$text_table->show();

	my $text = new Gtk::Text( undef, undef );
	$text->show;
	$text->set_usize (undef, 100);
	$text->set_editable( 0 );
	$text->set_word_wrap ( 1 );
	$text_table->attach( $text, 0, 1, 0, 1,
        	       [ 'expand', 'shrink', 'fill' ],
        	       [ 'expand', 'shrink', 'fill' ],
        	       0, 0 );

	my $vscrollbar = new Gtk::VScrollbar( $text->vadj );
	$text_table->attach( $vscrollbar, 1, 2, 0, 1, 'fill',
        	       [ 'expand', 'shrink', 'fill' ], 0, 0 );
	$vscrollbar->show();

	my $frame = Gtk::Frame->new ("Status");
	$frame->show;
	$frame->add ($text_table);

	my $hbox = Gtk::HBox->new (0, 5);
	$hbox->show;
	$hbox->pack_start ($frame, 1, 1, 0);
	
	my $button_box = Gtk::VBox->new (0,5);
	$button_box->show;

	my $button_frame = Gtk::Frame->new ("Functions");
	$button_frame->show;
	$button_frame->add($button_box);

	$hbox->pack_start ($button_frame, 1, 1, 0);
	$dialog->vbox->pack_start ($hbox, 1, 1, 0);
	

	my $test = new Gtk::Button( "Test" );
	$button_box->pack_start( $test, 0, 1, 0 );
	$test->signal_connect( "clicked", sub { $self->test } );
	$test->show();

	my $create = new Gtk::Button( "Create DB" );
	$button_box->pack_start( $create, 0, 1, 0 );
	$create->signal_connect( "clicked", sub { $self->create } );
	$create->show();

	my $create_tables = new Gtk::Button( "Create Tables" );
	$button_box->pack_start( $create_tables, 0, 1, 0 );
	$create_tables->signal_connect( "clicked", sub { $self->create_tables } );
	$create_tables->show();


	my $help = new Gtk::Button( "Help" );
	$dialog->action_area->pack_start( $help, 0, 1, 0 );
	$help->signal_connect( "clicked", sub { $self->help_config } );
	$help->show();

	my $cancel = new Gtk::Button( "Cancel" );
	$dialog->action_area->pack_start( $cancel, 0, 1, 0 );
	$cancel->signal_connect( "clicked", sub { $self->cancel } );
	$cancel->show();

	my $ok = new Gtk::Button( "Ok" );
	$dialog->action_area->pack_start( $ok, 0, 1, 0 );
	$ok->signal_connect( "clicked", sub { $self->save } );
	$ok->show();

	$dialog->show;

	my $database = JaM::Database->load;

	$self->database($database);
	$self->gtk_entries ( \%entries );
	$self->gtk_dialog ( $dialog );
	$self->gtk_status ( $text );
	$self->gtk_window_widget ( $dialog );

	$self->show;

	$self->test;

	return $dialog;
}

sub show {
	my $self = shift;
	my $database = $self->database;
	
	my $value;
	my $entries = $self->gtk_entries;
	foreach my $field ( keys %{$entries} ) {
		$value = $database->$field();
		$entries->{$field}->set_text($value);
	}
	
	1;
}

sub copy_form_values_to_object {
	my $self = shift;

	my $database = $self->database;

	my $value;
	my $entries = $self->gtk_entries;
	foreach my $field ( keys %{$entries} ) {
		$value = $entries->{$field}->get_text;
		$database->$field($value);
	}

	1;
}

sub save {
	my $self = shift;
	
	my $database = $self->database;

	$self->copy_form_values_to_object;
	$database->save;

	$self->restart_program if $self->in_initialization;

	$self->gtk_dialog->destroy;

	1;
}

sub cancel {
	my $self = shift;

	Gtk->exit(0) if $self->in_initialization;

	$self->gtk_dialog->destroy;

	1;
}

sub test {
	my $self = shift;

	my $database = $self->database;

	$self->copy_form_values_to_object;

	my $message = $database->test;

	my $status = $self->gtk_status;
	$status->freeze;
	$status->backward_delete ($status->get_length);
	$status->insert (undef, undef, undef, $message);
	$status->thaw;
	
	1;
}

sub create {
	my $self = shift;

	my $database = $self->database;
	
	$self->copy_form_values_to_object;
	my $message = $database->create;
	
	my $status = $self->gtk_status;
	$status->freeze;
	$status->backward_delete ($status->get_length);
	$status->insert (undef, undef, undef, $message);
	$status->thaw;
	
}

sub create_tables {
	my $self = shift;

	my $database = $self->database;
	
	$self->copy_form_values_to_object;
	my $error = $database->create_tables;
	
	$error ||= "Tables successfully created.\n";
	
	my $status = $self->gtk_status;
	$status->freeze;
	$status->backward_delete ($status->get_length);
	$status->insert (undef, undef, undef, $error);
	$status->thaw;
	
}

sub help_config {
	my $self = shift;
	
	$self->help_window (
		title => "Database Configuration",
		file => "database.html",
	);
	
	1;
}

sub build_schema_update_window {
	my $self = shift;
	my %par = @_;
	my ($db) = @par{'db'};
	
	my $dialog = Gtk::Dialog->new;
	$dialog->border_width(10);
	$dialog->set_position('center');
	$dialog->set_title ("JaM Database Schema Update");
	$dialog->set_default_size (400, 180);
	$dialog->action_area->set_homogeneous (1);

	$dialog->signal_connect("destroy" => sub { Gtk->exit(0) } )
		if $self->in_initialization;

	my $text_table = new Gtk::Table( 2, 2, 0 );
	$text_table->show();
	$text_table->set_row_spacing( 0, 2 );
	$text_table->set_col_spacing( 0, 2 );

	my $text = new Gtk::Text( undef, undef );
	$text->show;
	$text->set_usize (undef, 100);
	$text->set_editable( 0 );
	$text->set_word_wrap ( 1 );
	$text_table->attach( $text, 0, 1, 0, 1,
        	       [ 'expand', 'shrink', 'fill' ],
        	       [ 'expand', 'shrink', 'fill' ],
        	       0, 0 );

	my $vscrollbar = new Gtk::VScrollbar( $text->vadj );
	$vscrollbar->show();
	$text_table->attach( $vscrollbar, 1, 2, 0, 1, 'fill',
        	       [ 'expand', 'shrink', 'fill' ], 0, 0 );

	my $frame = Gtk::Frame->new ("Status");
	$frame->show;
	$frame->add ($text_table);

	$dialog->vbox->pack_start($frame, 1, 1, 0);

	my $help = new Gtk::Button( "Help" );
	$dialog->action_area->pack_start( $help, 0, 1, 0 );
	$help->signal_connect( "clicked", sub { $self->help_update } );
	$help->show();

	my $cancel = new Gtk::Button( "Cancel" );
	$dialog->action_area->pack_start( $cancel, 0, 1, 0 );
	$cancel->signal_connect( "clicked", sub { $self->cancel } );
	$cancel->show();

	my $ok = new Gtk::Button( "Update" );
	$dialog->action_area->pack_start( $ok, 0, 1, 0 );
	$ok->signal_connect( "clicked", sub { $self->update } );
	$ok->show();

	$dialog->show;

	$self->database($db);
	$self->gtk_dialog ( $dialog );
	$self->gtk_status ( $text );
	$self->gtk_ok_button ( $ok );

	$text->insert (undef, undef, undef,
		"JaM detected an old database schema version.\n".
		"It can update the database schema for you. Please\n".
		"click on 'Update' to proceed. See the 'Help' page\n".
		"for detailed information about schema updates,\n".
		"e.g. it is recommended that you backup your data first.\n"
	);

	return $dialog;
}

sub help_update {
	my $self = shift;
	
	$self->help_window (
		title => "Database Schema Update",
		file => "schema_update.html",
	);
	
	1;
}

sub update {
	my $self = shift;
	
	if ( $self->update_successful ) {
		$self->restart_program;
	}
	
	my $status = $self->gtk_status;
	$status->backward_delete ($status->get_length);

	my $dbh = $self->dbh;
	my $database = $self->database;

	my $db_version   = $database->database_version;
	my $init_version = $database->init_version;

	my $error;
	for ( my $i = $db_version + 1; $i <= $init_version; ++$i ) {
		$status->insert (undef, undef, undef,
			"Updating tables from version ".($i-1)." to $i... "
		);
		$error = $database->execute_sql (
			dbh     => $dbh,
			section => "version$i",
		);
		if ( $error ) {
			$status->insert (undef, undef, undef,
				"Error!\n\n$error\n"
			);
			last;
		} else {
			$status->insert (undef, undef, undef, "Ok\n");
		}
		
		my $update_method = "db_update_version_$i";

		if ( $database->can($update_method) ) {
			$status->insert (undef, undef, undef,
				"Executing update code for version $i... "
			);

			eval {
				$database->$update_method( dbh => $dbh );
			};

			if ( $@ ) {
				$error = $@;
				$status->insert (undef, undef, undef,
					"Error!\n\n$error\n"
				);
				last;
			} else {
				$status->insert (undef, undef, undef, "Ok\n");
			}
		}

		$database->set_schema_version (
			version => $i,
			dbh => $dbh
		);
	}
	
	if ( not $error ) {
		$status->insert (undef, undef, undef,
			"\nUpdate was successful. Press 'Ok' to continue."
		);
		$self->update_successful(1);
		$self->gtk_ok_button->child->set ("Ok");
	}

	1;
}

1;
