# $Id: NetscapeImport.pm,v 1.3 2001/08/15 20:25:33 joern Exp $

package JaM::GUI::NetscapeImport;

@ISA = qw ( JaM::GUI::Component );

use strict;
use Carp;
use JaM::GUI::Component;
use JaM::Import::Netscape;
use FileHandle;

sub gtk_dialog		{ my $s = shift; $s->{gtk_dialog}
		          = shift if @_; $s->{gtk_dialog}	}

sub gtk_status		{ my $s = shift; $s->{gtk_status}
		          = shift if @_; $s->{gtk_status}	}

sub gtk_ok_button	{ my $s = shift; $s->{gtk_ok_button}
		          = shift if @_; $s->{gtk_ok_button}	}

sub gtk_radio_folders	{ my $s = shift; $s->{gtk_radio_folders}
		          = shift if @_; $s->{gtk_radio_folders}}

sub gtk_radio_mails	{ my $s = shift; $s->{gtk_radio_mails}
		          = shift if @_; $s->{gtk_radio_mails}	}

sub import_successful	{ my $s = shift; $s->{import_successful}
		          = shift if @_; $s->{import_successful}}
		  
sub import_in_progress	{ my $s = shift; $s->{import_in_progress}
		          = shift if @_; $s->{import_in_progress}}
		  
sub import_idle_id	{ my $s = shift; $s->{import_idle_id}
		          = shift if @_; $s->{import_idle_id}}

sub import_pipe_fh	{ my $s = shift; $s->{import_pipe_fh}
		          = shift if @_; $s->{import_pipe_fh}}

sub import_abort_file	{ my $s = shift; $s->{import_abort_file}
		          = shift if @_; $s->{import_abort_file}}

sub build {
	my $self = shift;
	my %par = @_;
	my ($db) = @par{'db'};
	
	my $dialog = Gtk::Dialog->new;
	$dialog->border_width(10);
	$dialog->set_position('center');
	$dialog->set_title ("JaM Netscape Import");
	$dialog->set_default_size (400, 180);
	$dialog->set_modal(1);
	$dialog->action_area->set_homogeneous (1);

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

	my $hbox = Gtk::HBox->new(0, 5);
	$hbox->show;
	
	my $label = Gtk::Label->new ("Import");
	$label->show;
	my $radio_folders = Gtk::RadioButton->new ("Folders only");
	$radio_folders->show;
	my $radio_mails   = Gtk::RadioButton->new ("Folders and mails", $radio_folders);
	$radio_mails->show;
	$radio_mails->set_active(1);

	$hbox->pack_start($label, 0, 1, 0);
	$hbox->pack_start($radio_folders, 0, 1, 0);
	$hbox->pack_start($radio_mails, 0, 1, 0);

	$dialog->vbox->pack_start($hbox, 1, 1, 0);

	my $cancel = new Gtk::Button( "Cancel" );
	$dialog->action_area->pack_start( $cancel, 0, 1, 0 );
	$cancel->signal_connect( "clicked", sub { $self->cancel } );
	$cancel->show();

	my $ok = new Gtk::Button( "Import" );
	$dialog->action_area->pack_start( $ok, 0, 1, 0 );
	$ok->signal_connect( "clicked", sub { $self->import_mails } );
	$ok->show();

	$dialog->show;

	$self->gtk_dialog ( $dialog );
	$self->gtk_status ( $text );
	$self->gtk_ok_button ( $ok );
	$self->gtk_radio_folders ( $radio_folders );
	$self->gtk_radio_mails ( $radio_mails );

	return $dialog;
}

sub cancel {
	my $self = shift;

	if ( $self->import_successful ) {
		$self->restart_program;
	}

	if ( $self->import_in_progress ) {
		Gtk->idle_remove ($self->import_idle_id);
		my $abort_file = $self->import_abort_file;
		open (TOUCH, "> $abort_file") or confess "can't write $abort_file";
		close TOUCH;
		my $fh = $self->import_pipe_fh;
		close $fh or warn "can't execute bin/jam_nsmail_import.pl";
		unlink $abort_file;
		$self->restart_program;
	}

	$self->gtk_dialog->destroy;

	1;
}

sub import_mails {
	my $self = shift;
	
	if ( $self->import_successful ) {
		$self->restart_program;
	}
	
	return if $self->import_in_progress;
	$self->import_in_progress(1);
	
	my $status = $self->gtk_status;
	$status->backward_delete ($status->get_length);

	my $dbh = $self->dbh;

	my $radio_mails = $self->gtk_radio_mails;
	my $mails_too   = $radio_mails->get_active ? 1 : 0;

	$status->insert (undef, undef, undef,
		"Starting Netscape import...\n\n"
	);

	my $abort_filename = "/tmp/jam_import_abort_$$";
	$self->import_abort_file($abort_filename);

	my $fh = new FileHandle;
	open ($fh, "bin/jam_nsmail_import.pl $mails_too $abort_filename|")
		or confess "can't fork bin/jam_nsmail_import.pl";

	my $idle_id;
	$idle_id = Gtk->idle_add ( sub {
		my $line = <$fh>;
		if ( eof($fh) or $line eq "END\n" ) {
			Gtk->idle_remove ($idle_id);
			close $fh or warn "can't execute bin/jam_nsmail_import.pl";
			$self->import_successful (1);
			$self->gtk_ok_button->child->set ("Ok");
			$status->insert (undef, undef, undef, "Finished!");
		} else {
			$status->insert (undef, undef, undef, $line);
		}
		
		return 1;
	});

	$self->import_idle_id($idle_id);
	$self->import_pipe_fh($fh);

	1;
}

1;
