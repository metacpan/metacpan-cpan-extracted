# $Id: GUI.pm,v 1.37 2002/03/03 13:16:05 joern Exp $

package JaM::GUI;

@ISA = qw ( JaM::GUI::Component );

use strict;
use Data::Dumper;

use Gtk;
use Gtk::Keysyms;
use JaM::Mail;
use JaM::Account;
use JaM::Drop;
use JaM::GUI::Component;
use JaM::GUI::Folders;
use JaM::GUI::Subjects;
use JaM::GUI::Mail;
use JaM::GUI::Compose;
use JaM::GUI::MailAsHTML;
use JaM::GUI::HTMLSurface;

use Net::POP3;

sub DESTROY {
	Gtk->exit(0);
}

sub gtk_box		{ my $s = shift; $s->{gtk_box}
		          = shift if @_; $s->{gtk_box}			}
sub gtk_menubar		{ my $s = shift; $s->{gtk_menubar}
		          = shift if @_; $s->{gtk_menubar}		}
sub gtk_toolbar		{ my $s = shift; $s->{gtk_toolbar}
		          = shift if @_; $s->{gtk_toolbar}		}
sub gtk_show_all_radio	{ my $s = shift; $s->{gtk_show_all_radio}
		          = shift if @_; $s->{gtk_show_all_radio}	}
sub gtk_show_limit_radio{ my $s = shift; $s->{gtk_show_limit_radio}
		          = shift if @_; $s->{gtk_show_limit_radio}	}
sub gtk_limit_entry	{ my $s = shift; $s->{gtk_limit_entry}
		          = shift if @_; $s->{gtk_limit_entry}		}

sub getting_messages_state	{ my $s = shift; $s->{getting_messages_state}
		          	  = shift if @_; $s->{getting_messages_state}	}

sub no_subjects_update	{ my $s = shift; $s->{no_subjects_update}
		          = shift if @_; $s->{no_subjects_update}	}

sub start {
	my $self = shift; $self->trace_in;

	Gtk->init;
	Gtk::Widget->set_default_colormap(Gtk::Gdk::Rgb->get_cmap());
	Gtk::Widget->set_default_visual(Gtk::Gdk::Rgb->get_visual());

	$self->load_fonts;
	
	$self->build;

	while (1) {
		eval { Gtk->main };
		if ( $@ ) {
			my $error =
				"An internal exception was thrown!\n".
				"The error message was:\n\n$@";
				
			$self->message_window (
				message => $error
			);
			next;
		} else {
			last;
		}
	}
}

sub load_fonts {
	my $self = shift; $self->trace_in;
	
	my $fonts = $self->config_object->entries_by_type ( 'font' );
	
	my ($font_name, $value, $font);
	while ( ($font_name,$value) = each %{$fonts} ) {
		$font = $font_name;
		$font =~ s/^font_name/font/;
		$self->config_object->set_temporary(
			$font,
			Gtk::Gdk::Font->load ($value->{value})
		);
	}
	
	1;
}

sub build {
	my $self = shift; $self->trace_in;

	my $dbh = $self->dbh;
	
	# create GTK widgets for main application window
	my $win      = $self->create_window;
	my $box      = $self->create_window_box;
	my $menubar  = $self->create_menubar;
	my $toolbar  = $self->create_toolbar;

	# store component
	$self->comp ( gui => $self );

	# create objects for our main GUI components
	my $folders =
		JaM::GUI::Folders->new ( dbh => $dbh, gtk_win => $win )->build;
	$self->comp ( folders  => $folders );

	my $subjects =
		JaM::GUI::Subjects->new ( dbh => $dbh, gtk_win => $win )->build;
	$self->comp ( subjects => $subjects );

	my $mail =
		JaM::GUI::Mail->new ( dbh => $dbh, gtk_win => $win )->build;
	$self->comp ( mail     => $mail );

	# arrange components inside the application window
	my $vpane = new Gtk::VPaned();
	$vpane->set_handle_size( 10 );
	$vpane->set_gutter_size( 15 );
	$vpane->add1 ($subjects->widget);
	$vpane->add2 ($mail->widget);
	$vpane->show();

	my $hpane = new Gtk::HPaned();
	$hpane->set_handle_size( 10 );
	$hpane->set_gutter_size( 15 );
	if ( $self->config('folder_tree_left') ) {
		$hpane->add1 ($folders->widget);
		$hpane->add2 ($vpane);
	} else {
		$hpane->add1 ($vpane);
		$hpane->add2 ($folders->widget);
	}
	$hpane->show();
	
	my $sep = Gtk::HSeparator->new;
	$sep->show;
	
	$box->pack_start($menubar, 0, 1, 0);
	$box->pack_start($toolbar, 0, 1, 0);
	$box->pack_start($sep, 0, 1, 0);
	$box->pack_start($hpane, 1, 1, 0);
	$win->add($box);

	$mail->clear;

	$win->show;
	
	$self->widget($win);

	$folders->gtk_folders_tree->select_row(0,0);

	return;
}

sub create_window {
	my $self = shift; $self->trace_in;
	
	my $win = new Gtk::Window -toplevel;
	$win->set_title($self->config('program_name'));
	$win->signal_connect("destroy" => \&Gtk::main_quit);
	$win->border_width(0);
	$win->set_uposition (10,10);
	$win->set_default_size (
		$self->config('main_window_width'),
		$self->config('main_window_height'),
	);
	$win->realize;

	$win->signal_connect("size-allocate",
		sub {
			$self->config('main_window_width', $_[1]->[2]);
			$self->config('main_window_height', $_[1]->[3]);
		}
	);

	$self->gtk_win ($win);
	
	return $win;
}	

sub create_window_box {
	my $self = shift; $self->trace_in;
	
	my $box = new Gtk::VBox (0, 2);
	$box->show;
	
	$self->gtk_box ($box);
	
	return $box;
}

sub create_menubar {
	my $self = shift; $self->trace_in;
	
	my $win = $self->gtk_win;
	
	my @menu_items = (
		{ path        => '/_File',
                  type        => '<Branch>' },

                { path        => '/File/_Get Messages',
		  accelerator => '<control>G',
                  callback    => sub { $self->cb_get_button } },

		{ path	      => '/File/sep1',
		  type	      => '<Separator>' },
                { path        => '/File/_Netscape Import...',
                  callback    => sub { $self->netscape_import_window } },

		{ path	      => '/File/sep2',
		  type	      => '<Separator>' },
                { path        => '/File/Empty _Trash...',
                  callback    => sub { $self->ask_empty_trash_folder } },

		{ path	      => '/File/sep5',
		  type	      => '<Separator>' },
                { path        => '/File/_Exit',
		  accelerator => '<control>Q',
                  callback    => sub { Gtk->exit( 0 ); } },

                { path        => '/_Edit',
                  type        => '<Branch>' },
                { path        => '/Edit/Input, Output _Filter',
		  accelerator => '<control>I',
                  callback    => sub {
		  	require JaM::GUI::IO_Filter;
		  	my $filter = JaM::GUI::IO_Filter->new (
				dbh => $self->dbh
			);
			$filter->open_window;
		  } },
                { path        => '/Edit/Mail _Account',
		  accelerator => '<control>M',
                  callback    => sub { $self->account_window } },
                { path        => '/Edit/Address _Book',
		  accelerator => '<control>B',
                  callback    => sub {
		  	require JaM::GUI::Address;
		  	my $address = JaM::GUI::Address->new (
				dbh => $self->dbh
			);
			$address->open_window;
		  } },

                { path        => '/Edit/_Database Configuration',
                  callback    => sub {
		  	require JaM::GUI::Database;
		  	my $db = JaM::GUI::Database->new (
				dbh => $self->dbh
			);
			$db->open_window;
		  } },

                { path        => '/Edit/_User Configuration',
		  accelerator => '<control>U',
                  callback    => sub {
		  	require JaM::GUI::Config;
		  	my $conf = JaM::GUI::Config->new (
				dbh => $self->dbh
			);
			$conf->open_window;
		  } },

                { path        => '/_Message',
                  type        => '<Branch>' },
                { path        => '/Message/_New Message',
		  accelerator => '<control>N',
                  callback    => sub { $self->cb_new_button } },
                { path        => '/Message/_Reply Message',
		  accelerator => '<control>R',
                  callback    => sub { $self->cb_reply_button } },
                { path        => '/Message/Reply _All Message',
		  accelerator => '<control>A',
                  callback    => sub { $self->cb_reply_all_button } },
                { path        => '/Message/_Forward Message',
		  accelerator => '<control>O',
                  callback    => sub { $self->cb_forward_button } },
		{ path	      => '/Message/sep2',
		  type	      => '<Separator>' },
                { path        => '/Message/_Print Message',
		  accelerator => '<control>P',
                  callback    => sub { $self->cb_print_button } },
		{ path	      => '/Message/sep3',
		  type	      => '<Separator>' },
                { path        => '/Message/_Delete Message',
		  accelerator => '<control>D',
                  callback    => sub { $self->cb_delete_button } },
		{ path	      => '/Message/sep4',
		  type	      => '<Separator>' },
                { path        => '/Message/Advanced _Search...',
		  accelerator => '<control>F',
                  callback    => sub {
		  	require JaM::GUI::Search;
		  	my $search = JaM::GUI::Search->new (
				dbh => $self->dbh
			);
			$search->open_window;
		  } },

		{ path	      => '/_Help',
		  type	      => '<LastBranch>' },
                { path        => '/Help/_About',
                  callback    => sub { $self->about_window } },
	);

	my $accel_group = Gtk::AccelGroup->new;
	my $item_factory = Gtk::ItemFactory->new (
		'Gtk::MenuBar',
		'<main>',
		$accel_group
	);
	$item_factory->create_items ( @menu_items );
	$win->add_accel_group ( $accel_group );
	my $menubar = $self->gtk_menubar ( $item_factory->get_widget( '<main>' ) );
	$menubar->show;

	return $menubar;
}

sub create_toolbar {
	my $self = shift; $self->trace_in;
	
	my $toolbar = Gtk::Toolbar->new ( 'horizontal', 'text' );
	$toolbar->set_space_size( 0 );
	$toolbar->set_space_style( 'empty' );
	$toolbar->set_button_relief( 'none' ); 
	$toolbar->border_width( 0 );

	$toolbar->append_space;
	my $get_button = $toolbar->append_item (
		"Get Messages", "Fetch new messages", undef, undef
	);
	$toolbar->append_space;
	my $new_button = $toolbar->append_item (
		"New Message", "Compose a new message", undef, undef
	);
	$toolbar->append_space;
	my $reply_button = $toolbar->append_item (
		"Reply", "Reply to this message", undef, undef
	);
	$toolbar->append_space;
	my $reply_grp_button = $toolbar->append_item (
		"Reply Group", "Reply to To: address only, useful for mailing lists", undef, undef
	);
	$toolbar->append_space;
	my $reply_all_button = $toolbar->append_item (
		"Reply All", "Reply to all recipients", undef, undef
	);
	$toolbar->append_space;
	my $forward_button = $toolbar->append_item (
		"Forward", "Forward selected message", undef, undef
	);
	$toolbar->append_space;
	my $print_button = $toolbar->append_item (
		"Print", "Print selected message", undef, undef
	);
	$toolbar->append_space;
	my $delete_button = $toolbar->append_item (
		"Delete", "Delete selected message", undef, undef
	);
	$toolbar->append_space;
	my $mark_all_read_button = $toolbar->append_item (
		"Mark All Read", "Mark all messages in this folder as read", undef, undef
	);

	my $hbox = Gtk::HBox->new (0,0);
	$hbox->show;
	my $show_all_radio = Gtk::RadioButton->new ("Show all");
	$hbox->pack_start ($show_all_radio, 0, 0, 1);
	$show_all_radio->show;
	my $show_limit_radio = Gtk::RadioButton->new ("Limit to", $show_all_radio);
	$hbox->pack_start ($show_limit_radio, 0, 0, 1);
	$show_limit_radio->show;
	my $limit_entry = Gtk::Entry->new (8);
	$limit_entry->set_usize(50, undef);
	$hbox->pack_start ($limit_entry, 0, 0, 1);
	$limit_entry->show;

	$toolbar->append_space;
	$toolbar->append_space;
	$toolbar->append_widget ( $hbox, "Adjust folder display limit",, "");

	$self->gtk_show_all_radio ( $show_all_radio );
	$self->gtk_show_limit_radio ( $show_limit_radio );
	$self->gtk_limit_entry ( $limit_entry );

	$get_button->signal_connect ("clicked", sub { $self->cb_get_button (@_) } );
	$new_button->signal_connect ("clicked", sub { $self->cb_new_button (@_) } );
	$reply_button->signal_connect ("clicked", sub { $self->cb_reply_button (@_) } );
	$reply_all_button->signal_connect ("clicked", sub { $self->cb_reply_all_button (@_) } );
	$reply_grp_button->signal_connect ("clicked", sub { $self->cb_reply_grp_button (@_) } );
	$forward_button->signal_connect ("clicked", sub { $self->cb_forward_button (@_) } );
	$print_button->signal_connect ("clicked", sub { $self->cb_print_button (@_) } );
	$delete_button->signal_connect ("clicked", sub { $self->cb_delete_button (@_) } );
	$mark_all_read_button->signal_connect ("clicked", sub { $self->cb_mark_all_read (@_) } );

	$show_all_radio->signal_connect ("clicked", sub { $self->cb_show_all (1) } );
	$show_limit_radio->signal_connect ("clicked", sub { $self->cb_show_all (0) } );
	$limit_entry->signal_connect_after("activate", sub { $self->cb_limit_entry_activate (@_) });

	$toolbar->show();
	$self->gtk_toolbar ($toolbar);

	return $toolbar;
}

sub cb_get_button {
	my $self = shift; $self->trace_in;
	my ($widget, $event) = @_;
	
	return 1 if $self->getting_messages_state;
	
	my $dropper = JaM::Drop->new (
		dbh => $self->dbh,
		type => 'input',
	);
	
	if ( $dropper->filter_error ) {
		$self->message_window (
			title => "Error initializing Input Filter",
			message =>
				"Can't initialize Input Filter\n".
				"Error: ".$dropper->filter_error
		);
		return;
	}
	
	my $account = JaM::Account->load_default ( dbh => $self->dbh )
		or return;
	
	if ( not $account->pop3_server or
	     not $account->pop3_login ) {
		$self->account_window;
		return 1;
	}
	
	my $pop = Net::POP3->new (
		$account->pop3_server,
		Timeout => 60
	);
	
	$self->debug ("pw=".$account->pop3_password);
	my $ok = $pop->login ( $account->pop3_login, $account->pop3_password );
	
	if ( not $ok ) {
		$self->message_window (
			message => "Error logging into pop3 account."
		);
		return 1;
	}
	
	my $last_nr  = $pop->last;
	my ($max_nr) = $pop->popstat;

#	$last_nr = 0;	# TESTING !!!

	if ( $max_nr <= $last_nr ) {
		$self->debug ("no new messages");
		$self->message_window (message => "No new messages.");
		$pop->quit;
		return 1;
	}

	my $progress_win = Gtk::Window->new ("toplevel");
	$progress_win->set_title ("Fetching mail...");
	$progress_win->set_policy (0, 0, 1);
	$progress_win->border_width (10);
	$progress_win->position ("center");
	my $vbox = Gtk::VBox->new (0, 5);
	$vbox->border_width(1);
	$progress_win->add($vbox);
	$vbox->show;
	my $align = Gtk::Alignment->new (0.5, 0.5, 0, 0);
	$vbox->pack_start( $align, 0, 0, 5 );
	$align->show;
	my $adj = Gtk::Adjustment->new ( 0, 1, $max_nr - $last_nr, 0, 0, 0); 
	my $progress = Gtk::ProgressBar->new_with_adjustment ($adj);
	$progress->set_format_string ("%v/%u (%p%%)");
	$progress->set_show_text (1);
	$align->add( $progress );
	$progress->show;
	my $cancel = Gtk::Button->new ("Cancel");
	$vbox->pack_start ( $cancel, 0, 0, 0 );
	$cancel->signal_connect( "clicked", sub { $self->cb_cancel_get_messages (@_) } );
	$cancel->can_default( 1 );
	$cancel->grab_default;
	$cancel->show;
	$progress_win->show;

	$self->getting_messages_state ({
		progress => $progress,
		progress_win => $progress_win,
		dropper => $dropper,
		pop => $pop,
		nr => $last_nr + 1,
		max => $max_nr,
		delete => $account->pop3_delete,
	});
	
	$self->debug ("start time=".time);

	$self->getting_messages_state->{idle} = Gtk->idle_add (
		sub { $self->fetch_next_message } 
	);
	
	1;
}

sub cb_cancel_get_messages {
	my $self = shift;

	my $state = $self->getting_messages_state;
	my $folders = $self->comp('folders');
	my $pop = $state->{pop};

	Gtk->idle_remove ($state->{idle});
	$pop->reset;
	$pop->quit;
	$state->{progress_win}->destroy;
	$self->getting_messages_state(undef);
	$folders->update_folder_stati;

	return 1;
}

my $idle_nr = 0;
sub fetch_next_message {
	my $self = shift;

	return 1 if ++$idle_nr % 1000;

	my $state = $self->getting_messages_state;

	my ($data, $mail_id, $folder_id);
	my $subjects = $self->comp('subjects');
	my $folders = $self->comp('folders');
	my $selected_folder_object = $folders->selected_folder_object;

	$self->debug ("getting message no. $state->{nr}");

	my $pop = $state->{pop};

	$state->{progress}->set_value ($state->{progress}->get_value + 1);
	
	$data = $pop->get($state->{nr});
	#! todo: error window
	$self->cb_cancel_get_messages if not $data;

	$pop->delete($state->{nr}) if $state->{delete};
	
	$state->{nr}++;
	($mail_id, $folder_id) = $state->{dropper}->drop_mail ( data => $data );

	$subjects->prepend_new_mail ( mail_id => $mail_id )
		if $selected_folder_object and
		   $folder_id == $selected_folder_object->id;

	my $folder_object = JaM::Folder->by_id($folder_id);

	$folders->update_folder_item (
		folder_object => $folder_object,
		no_folder_stati => 1,
	);

	if ( $state->{nr} > $state->{max} ) {
		$pop->quit;
		$state->{progress_win}->destroy;
		$self->getting_messages_state(undef);
		$folders->update_folder_stati;
		$self->debug ("end time=".time);
		return;
	}
	
	1;
}

sub cb_new_button {
	my $self = shift; $self->trace_in;
	my ($widget, $event) = @_;
	
	my $account = JaM::Account->load_default ( dbh => $self->dbh );
	if ( not $account->smtp_server or
	     not $account->from_name or
	     not $account->from_adress ) {
		$self->account_window;
		return 1;
	}
	
	my $compose = JaM::GUI::Compose->new (
		dbh => $self->dbh
	);
	
	$compose->build;
	
	return $compose;
}

sub cb_reply_button {
	my $self = shift; $self->trace_in;
	my ($widget, $event) = @_;

	my $account = JaM::Account->load_default ( dbh => $self->dbh );
	if ( not $account->smtp_server or
	     not $account->from_name or
	     not $account->from_adress ) {
		$self->account_window;
		return 1;
	}
	
	return 1 if not $self->comp('mail')->mail;

	my $compose = JaM::GUI::Compose->new (
		dbh => $self->dbh
	);
	
	$compose->build;
	$compose->insert_reply_message (
		mail => $self->comp('mail')->mail
	);
	
	1;
}

sub cb_reply_all_button {
	my $self = shift; $self->trace_in;
	my ($widget, $event) = @_;

	my $account = JaM::Account->load_default ( dbh => $self->dbh );
	if ( not $account->smtp_server or
	     not $account->from_name or
	     not $account->from_adress ) {
		$self->account_window;
		return 1;
	}
	
	return 1 if not $self->comp('mail')->mail;

	my $compose = JaM::GUI::Compose->new (
		dbh => $self->dbh
	);
	
	$compose->build;
	$compose->insert_reply_message (
		mail => $self->comp('mail')->mail,
		reply_all => 1,
	);
	
	1;
}

sub cb_reply_grp_button {
	my $self = shift; $self->trace_in;
	my ($widget, $event) = @_;

	my $account = JaM::Account->load_default ( dbh => $self->dbh );
	if ( not $account->smtp_server or
	     not $account->from_name or
	     not $account->from_adress ) {
		$self->account_window;
		return 1;
	}
	
	return 1 if not $self->comp('mail')->mail;

	my $compose = JaM::GUI::Compose->new (
		dbh => $self->dbh
	);
	
	$compose->build;
	$compose->insert_reply_message (
		mail => $self->comp('mail')->mail,
		reply_group => 1,
	);
	
	1;
}

sub cb_forward_button {
	my $self = shift; $self->trace_in;
	my ($widget, $event) = @_;

	my $account = JaM::Account->load_default ( dbh => $self->dbh );
	if ( not $account->smtp_server or
	     not $account->from_name or
	     not $account->from_adress ) {
		$self->account_window;
		return 1;
	}
	
	my $selected_mail_ids = $self->comp('subjects')->selected_mail_ids;
	return if not @{$selected_mail_ids};

	my $compose = JaM::GUI::Compose->new (
		dbh => $self->dbh
	);
	
	my $first_mail = JaM::Mail->load (
		mail_id => shift @{$selected_mail_ids},
		dbh     => $self->dbh
	);
	
	$compose->build;

	$compose->forwarded_message (
		mail => $first_mail
	);

	$compose->add_attachment (
		mail => $first_mail
	);

	foreach my $mail_id ( @{$selected_mail_ids} ) {
		$compose->add_attachment (
			mail => JaM::Mail->load (
				mail_id => $mail_id,
				dbh => $self->dbh
			)
		);
	}

	1;
}

sub cb_print_button {
	my $self = shift; $self->trace_in;
	my ($widget, $event) = @_;

	my $selected_mail_ids = $self->comp('subjects')->selected_mail_ids;
	return if not @{$selected_mail_ids};

	my $mail;
	my $mail_comp = $self->comp('mail');

	foreach my $mail_id ( @{$selected_mail_ids} ) {
		$self->debug ("printing mail id=$mail_id...");
		$mail = JaM::Mail->load (
			mail_id => $mail_id,
			dbh => $self->dbh
		);

		my $mail_as_html = JaM::GUI::MailAsHTML->new;

		$mail_as_html->begin;

		$mail_comp->print_entity_head (
			widget => $mail_as_html,
			entity => $mail
		);

		if ( $mail->body ) {
			$mail_comp->put_mail_text (
				widget => $mail_as_html,
				data => $mail->body->as_string,
				no_table => 1,
				wrap_length => $self->config('wrap_line_length_show'),
			);
		}
		$mail_comp->print_child_entities (
			first_time => 1,
			widget => $mail_as_html,
			entity => $mail,
			wrap_length => $self->config('wrap_line_length_show'),
		);

		$mail_as_html->end;

		my $html2ps = $self->config('html2ps_prog');
		my $lpr     = $self->config('lpr_prog');
		my $lp      = $self->config('printer_name');

		$self->debug ("execute $html2ps | $lpr -P$lp");

		if ( not open (PRINT, "| $html2ps | $lpr -P$lp") ) {
			warn ("can't fork $html2ps | $lpr -P$lp");
			return 1;
		}
		print PRINT $mail_as_html->html;
		close PRINT or
			warn ("can't execute $html2ps | $lpr -P$lp");
	}

	1;
}

sub cb_delete_button {
	my $self = shift; $self->trace_in;
	my ($widget, $event) = @_;

	my $trash_folder_id = $self->config('trash_folder_id');

	$self->comp('subjects')->move_selected_mails (
		folder_id => $trash_folder_id
	);

	1;
}

sub cb_mark_all_read {
	my $self = shift; $self->trace_in;
	my ($widget, $event) = @_;

	my $folder_object = $self->comp('subjects')->folder_object;
	return 1 if not $folder_object;
	
	$folder_object->mark_all_read;

	$self->comp('subjects')->show,
	$self->comp('folders')->update_folder_item (
		folder_object => $folder_object
	);
	
	1;
}

sub update_folder_limit {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($folder_object) = @par{'folder_object'};
	
	if ( not $folder_object ) {
		$self->gtk_show_all_radio->set_active (0);
		$self->gtk_show_limit_radio->set_active (0);
		$self->gtk_limit_entry->set_text("");
		return 1;
	}
	
	if ( $folder_object->show_all ) {
		$self->debug ("show all activated");
		$self->gtk_show_all_radio->set_active (1);
		$self->gtk_show_limit_radio->set_active (0);
	} else {
		$self->debug ("show all deactivated");
		$self->gtk_show_all_radio->set_active (0);
		$self->gtk_show_limit_radio->set_active (1);
	}

	$self->gtk_limit_entry->set_text ( $folder_object->show_max );
	
	1;
}

sub cb_show_all {
	my $self = shift;
	my ($show_all) = @_;
	
	my $folder_object = $self->comp('folders')->selected_folder_object;
	return 1 if not $folder_object;
	return 1 if $folder_object->show_all eq $show_all;
	
	$folder_object->show_all($show_all);
	$folder_object->save;
	
	$self->comp('subjects')->show if not $self->no_subjects_update;

	1;
}

sub cb_limit_entry_activate {
	my $self = shift;
	my ($widget, $event) = @_;

	my $folder_object = $self->comp('folders')->selected_folder_object;
	return 1 if not $folder_object;
	
	$folder_object->show_max($widget->get_text);
	$folder_object->show_all(0);
	$folder_object->save;
	$self->update_folder_limit;
	$self->comp('subjects')->show if not $self->no_subjects_update;
	$widget->set_text($folder_object->show_max);

	return 1;
}

sub about_window {
	my $self = shift;
	
	my $win = new Gtk::Window;
	$win->set_title( "About: ".$self->config('program_name') );
	$win->set_usize ( 420, 350 );
	$win->set_policy ( 0, 0, 1);
	$win->border_width(0);
	$win->position ('center');
	$win->signal_connect("destroy", sub { $win->destroy } );

	my $vbox = Gtk::VBox->new (0,0);
	$vbox->show;	

	my $sw = new Gtk::ScrolledWindow(undef, undef);
	$sw->set_policy('automatic', 'automatic');

	my $html = JaM::GUI::HTMLSurface->new (
		image_dir => $self->htdocs_dir,
	);

	$html->show_eval (
		file => "about.html"
	);

	my $widget = $html->widget;
	$sw->show;
	$sw->add($widget);

	$vbox->pack_start($sw, 1, 1, 0);

	$win->add ($vbox);
	$win->show;

	1;	
}

sub account_window {
	my $self = shift;
	
	require JaM::GUI::Account;
	my $account = JaM::GUI::Account->new (
		dbh => $self->dbh
	);
	$account->open_window;
	
	1;
}

sub netscape_import_window{
	my $self = shift;
	
	require JaM::GUI::NetscapeImport;
	my $import = JaM::GUI::NetscapeImport->new (
		dbh => $self->dbh
	);
	$import->build;
	
	1;
}

sub ask_empty_trash_folder {
	my $self = shift;
	
	$self->confirm_window (
		message => "Do you want to empty the trash folder?",
		position => 'center',
		yes_callback => sub { $self->comp('folders')->empty_trash_folder }
	);
}

1;
