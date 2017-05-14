# $Id: Subjects.pm,v 1.20 2001/11/02 12:31:02 joern Exp $

package JaM::GUI::Subjects;

@ISA = qw ( JaM::GUI::Component );

use strict;
use JaM::Func;
use JaM::GUI::Component;

my $DEBUG = 1;

# get/set currently listed mails
sub mail_ids		{ my $s = shift; $s->{mail_ids}
		          = shift if @_; $s->{mail_ids}			}

# get/set currently mail id where popup opened
sub popup_mail_id	{ my $s = shift; $s->{popup_mail_id}
		          = shift if @_; $s->{popup_mail_id}		}

# get/set currently selected folder
sub folder_object	{ my $s = shift; $s->{folder_object}
		          = shift if @_; $s->{folder_object}		}

# get/set gtk object for subjects scrolled window
sub gtk_subjects	{ my $s = shift; $s->{gtk_subjects}
		          = shift if @_; $s->{gtk_subjects}		}

# get/set gtk object for subjects clist
sub gtk_subjects_list	{ my $s = shift; $s->{gtk_subjects_list}
		          = shift if @_; $s->{gtk_subjects_list}	}

# get/set currently first selected mail id
sub selected_mail_id	{ my $s = shift; $s->trace_in; $s->{selected_mail_id}
		          = shift if @_; $s->{selected_mail_id}		}

sub gtk_folder_menu	{ my $s = shift; $s->{gtk_folder_menu}
		          = shift if @_; $s->{gtk_folder_menu}		}

sub gtk_folder_menu_item{ my $s = shift; $s->{gtk_folder_menu_item}
		          = shift if @_; $s->{gtk_folder_menu_item}	}

# return lref of selected mail ids
sub selected_mail_ids {
	my $self = shift;

	my @rows = $self->gtk_subjects_list->selection;
	my @ids;

	my $mail_ids = $self->mail_ids;

	foreach my $row ( @rows ) {
		push @ids, $mail_ids->[$row];

	}
	return \@ids;
}

# build subjects widget
sub build {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my  ($without_quick_search, $without_resize_tracking) =
	@par{'without_quick_search','without_resize_tracking'};

	# Create a ScrolledWindow for the list
	my $subjects = new Gtk::ScrolledWindow( undef, undef );
	$subjects->set_policy( 'automatic', 'automatic' );
	$subjects->set_usize(undef, $self->config('subjects_height'));
	$subjects->show();

	# Create list box
	my @titles = qw( Status Subject Sender Date );
	my $list = Gtk::CList->new_with_titles ( @titles );
	$subjects->add( $list );
	$list->set_column_width( 0, $self->config('subjects_column_0') );
	$list->set_column_width( 1, $self->config('subjects_column_1') );
	$list->set_column_width( 2, $self->config('subjects_column_2') );
	$list->set_column_width( 3, $self->config('subjects_column_3') );
#	$list->set_selection_mode( 'browse' );
	$list->set_selection_mode( 'extended' );
	$list->set_shadow_type( 'none' );
	$list->set_user_data ( $self );
	$list->signal_connect( "select_row",   sub { $self->cb_select_mail(@_) } );
	$list->signal_connect( "click_column", sub { $self->cb_column_click(@_) } );

	if ( not $without_resize_tracking ) {
		$list->signal_connect( "resize-column",
			sub {
				$self->config('subjects_column_'.$_[1], $_[2]);
			}
		);
		$subjects->signal_connect("size-allocate",
			sub { $self->config('subjects_height', $_[1]->[3]) }
		);
	}

	$list->show();

	# now build popup Menu
	$list->signal_connect('button_press_event', sub { $self->cb_click_subjects(@_) } );
	my $popup = $list->{popup} = Gtk::Menu->new;
	my $item;

#	$item = Gtk::MenuItem->new ("Mark selected mail(s) as read...");
#	$popup->append($item);
#	$item->signal_connect ("activate", sub { $self->cb_mark_mail_as_read ( @_ ) } );
#	$item->show;

	my $folder_menu_item = Gtk::MenuItem->new ("Move selected mail(s) to folder...");
	$popup->append($folder_menu_item);
	$folder_menu_item->show;

	my $folder_menu = $self->comp('folders')->build_menu_of_folders (
		callback => sub { $self->move_selected_mails ( folder_id => $_[0] ); }
	);
	$folder_menu_item->set_submenu($folder_menu);

	$item = Gtk::MenuItem->new;
	$popup->append($item);
	$item->show;

	$item = Gtk::MenuItem->new ("Add Input Filter...");
	$popup->append($item);
	$item->signal_connect ("activate", sub { $self->cb_add_input_filter ( @_ ) } );
	$item->show;

	if ( not $without_quick_search ) {

		$item = Gtk::MenuItem->new;
		$popup->append($item);
		$item->show;

		$item = Gtk::MenuItem->new ("Quick Search Sender...");
		$popup->append($item);
		$item->signal_connect ("activate", sub {
			$self->comp('subjects')->quick_search(
				type => 'sender'
			);
		});
		$item->show;
		$item = Gtk::MenuItem->new ("Quick Search Subject...");
		$popup->append($item);
		$item->signal_connect ("activate", sub {
			$self->comp('subjects')->quick_search(
				type => 'subject'
			);
		});
		$item->show;
		$item = Gtk::MenuItem->new ("Quick Search Body...");
		$popup->append($item);
		$item->signal_connect ("activate", sub {
			$self->comp('subjects')->quick_search(
				type => 'body'
			);
		});
		$item->show;
		$item = Gtk::MenuItem->new ("Quick Search Recipient...");
		$popup->append($item);
		$item->signal_connect ("activate", sub {
			$self->comp('subjects')->quick_search(
				type => 'recipient'
			);
		});
		$item->show;

		$item = Gtk::MenuItem->new;
		$popup->append($item);
		$item->show;

		$item = Gtk::MenuItem->new ("Advanced Search...");
		$popup->append($item);
		$item->signal_connect ("activate", sub {
  			require JaM::GUI::Search;
  			my $search = JaM::GUI::Search->new (
				dbh => $self->dbh
			);
			$search->open_window;
			$search->folder_chosen ($self->folder_object->id);
		});
		$item->show;

	}

	$self->gtk_subjects ($subjects);
	$self->gtk_subjects_list ($list);
	$self->gtk_folder_menu ($folder_menu);
	$self->gtk_folder_menu_item ($folder_menu_item);

	$self->widget ($subjects);

	return $self;
}

sub cb_click_subjects {
	my $self = shift;
	my ($widget, $event) = @_;

	my ( $row, $column ) = $widget->get_selection_info( $event->{x}, $event->{y} );

	if ( $self->mail_ids ) {
		$self->popup_mail_id ( $self->mail_ids->[$row] );
	} else {
		$self->popup_mail_id (undef);
	}

	if ( $event->{button} == 3 and $widget->{'popup'} ) {
		my $folder_menu_item = $self->gtk_folder_menu_item;
		$folder_menu_item->remove_submenu;
		my $folder_menu = $self->comp('folders')->build_menu_of_folders (
			callback => sub { $self->move_selected_mails ( folder_id => $_[0] ); }
		);
		$folder_menu_item->set_submenu($folder_menu);
		$widget->{'popup'}->popup(undef,undef,$event->{button},1);
	}

	1;
}

sub cb_add_input_filter {
	my $self = shift;
	
	my $filter;
	eval { $filter = $self->comp('input_filter') };
	
	if ( not $filter ) {
	  	require JaM::GUI::IO_Filter;
	  	$filter = JaM::GUI::IO_Filter->new (
			dbh => $self->dbh,
		);
		$filter->open_window;
	}
	
	my $mail = JaM::Mail->load ( dbh => $self->dbh, mail_id => $self->popup_mail_id );
	my $folder = JaM::Folder->by_id ($mail->folder_id);
	
	$filter->add_new_filter (
		folder_object => $folder,
		mail_object => $mail
	);
	
	$filter->gtk_win->focus(1);
	
	1;
}

# update subjects list with content of a selected folder
sub show {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my  ($folder_object, $where, $params, $tables, $sql) =
	@par{'folder_object','where','params','tables','sql'};

	$folder_object ||= $self->folder_object;
	
	my $is_sent_folder;
	if ( $folder_object ) {
		$self->folder_object ( $folder_object );
		$is_sent_folder =
			($folder_object->id == $self->config('sent_folder_id') or
			 $folder_object->id == $self->config('drafts_folder_id') or
			 $folder_object->id == $self->config('templates_folder_id') );

	}

	my $list = $self->gtk_subjects_list;
	my $dbh = $self->dbh;

	$list->clear;
	$list->freeze;

	my $sender_column;
	if ( $is_sent_folder ) {
		$list->set_column_title (2, "To");
		$sender_column = "head_to";
	} else {
		$list->set_column_title (2, "Sender");
		$sender_column = "sender";
	}

	my $column;   
	my $direction;
	if ( $folder_object ) {
		$column = $folder_object->sort_column;
		$direction = $folder_object->sort_direction;
		$direction = $direction eq 'ascending' ? "" : "desc";
	} else {
		$column = 5;
		$direction = "desc";
	}

	foreach my $i (0..3) {
		my $title = $list->get_column_title ($i);
		$title =~ s/[\[\]<> ]//g;
		if ( $i == $column ) {
			$title = "[ $title > ]" if $direction eq 'desc';
			$title = "[ $title < ]" if $direction eq '';
		}
		$list->set_column_title ($i, $title);
	}

	$self->debug ("sort by $column $direction");

	$column += 2;

	my $limit;
	if ( $folder_object and not $folder_object->show_all ) {
		$limit = "limit ".$folder_object->show_max;
	}

	$self->debug ("limit='$limit'");

	if ( $where ) {
		$where = "and $where";
		$params ||= [];
		$tables = ", $tables" if $tables;
	}

	if ( not $sql ) {
	   $sql = "select Mail.id, Mail.status, Mail.subject, Mail.$sender_column,
		          UNIX_TIMESTAMP(Mail.date)
		   from   Mail $tables
		   where  folder_id = ? $where
		   order by $column $direction, 5 $direction
		   $limit";
	}

	my $sth = $dbh->prepare ($sql);

	if ( $folder_object ) {
		$sth->execute ( $folder_object->id, @{$params} );
	} else {
		$sth->execute ( @{$params} );
	}

	my $unread_style = $list->style->copy;
	$unread_style->font($self->config('font_mail_unread'));
	my $read_style = $list->style->copy;
	$read_style->font($self->config('font_mail_read'));

	my @mail_ids;
	my ($id, $status, $subject, $sender, $date);
	my $selected_row = 0;
	my $cnt = 0;
	my $selected_mail_id;
	$selected_mail_id = $folder_object->selected_mail_id if $folder_object;

	$self->mail_ids (undef);

	while ( ($id, $status, $subject, $sender, $date) = $sth->fetchrow_array ) {
		push @mail_ids, $id;

		$sender =~ s/<.*?>// if $sender !~ /^</;
		$sender =~ s/"//g;
		$list->append(
			$status, $subject, $sender,
			JaM::Func->format_date (time => $date, nice => 1)
		);
		$list->set_row_style(
			$cnt, $status eq 'N' ?
			       $unread_style : $read_style
		);

		$selected_row = $cnt if $selected_mail_id == $id;
		++$cnt;
	}
	
	$sth->finish;

	$self->debug ("Mails scanned: ",scalar(@mail_ids));

	$self->mail_ids (\@mail_ids);

	$list->thaw;
	
	if ( $cnt ) {
		# select the correct entry
		$list->select_row( $selected_row, -1 );

		# scroll list to see the selected row
		$list->moveto( $selected_row, 0, 0.5, 0 ); 
	} else {
		$self->comp('mail')->clear;
		$self->selected_mail_id(undef);
	}

	1;
}

sub prepend_new_mail {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($mail_id) = @par{'mail_id'};
	
	my $list = $self->gtk_subjects_list;
	my $dbh = $self->dbh;
	my $folder_object = $self->folder_object;

	my $is_sent_folder =
		($folder_object->id == $self->config('sent_folder_id') or
		 $folder_object->id == $self->config('drafts_folder_id') or
		 $folder_object->id == $self->config('templates_folder_id') );

	my $sender_column;
	if ( $is_sent_folder ) {
		$list->set_column_title (2, "To");
		$sender_column = "head_to";
	} else {
		$list->set_column_title (2, "Sender");
		$sender_column = "sender";
	}

	$list->freeze;

	my $sth = $dbh->prepare (
		"select id, status, subject, $sender_column, UNIX_TIMESTAMP(date)
		 from   Mail
		 where  id = ?"
	);
	$sth->execute ( $mail_id );

	my $unread_style = $list->style->copy;
	$unread_style->font($self->config('font_mail_unread'));
	my $read_style = $list->style->copy;
	$read_style->font($self->config('font_mail_read'));

	my $item;
	my ($id, $status, $subject, $sender, $date) = $sth->fetchrow_array;
	$sth->finish;
	
	$sender =~ s/<.*?>// if $sender !~ /^</;
	$sender =~ s/"//g;
	$item = $list->prepend(
		$status, $subject, $sender,
		JaM::Func->format_date (time => $date, nice => 1)
	);
	$list->set_row_style(
		0, $status eq 'N' ?
		       $unread_style : $read_style
	);
	
	$list->thaw;

	my $mail_ids = $self->mail_ids;
	unshift @{$mail_ids}, $mail_id;
	
	1;
}

sub remove_selected {
	my $self = shift;

	my $clist = $self->gtk_subjects_list;
	my @rows  = $clist->selection;

	$self->remove_rows (
		rows => \@rows
	);

	1;
}

sub remove_rows {
	my $self = shift;
	my %par = @_;
	my ($rows) = @par{'rows'};

	my $clist    = $self->gtk_subjects_list;
	my $mail_ids = $self->mail_ids;

	$clist->freeze;

	@{$rows} = sort { $b <=> $a } @{$rows};
	my $selected = $rows->[@{$rows}-1];

	foreach my $row ( @{$rows} ) {
		splice (@{$mail_ids}, $row, 1);
		$clist->remove ( $row );
	}

	if ( @{$mail_ids} == 0 ) {
		$self->comp('mail')->clear;
	} else {
		--$selected if $selected >= @{$mail_ids};
		$clist->select_row ( $selected, 1 );
	}

	$clist->thaw;
	
	1;
}

sub cb_select_mail {
	my $self = shift; $self->trace_in;
	my ($clist, $row, $column, $event) = @_;

	return 1 if not defined $self->mail_ids;
	my @sel = $self->gtk_subjects_list->selection;
	return if @sel > 1;

	# determine selected mail id
	my $mail_id = $self->mail_ids->[$row];
	
	$self->debug ("column=$column mail_id=$mail_id selected_id=".$self->selected_mail_id);
	
	# nothing todo if this mail is already selected
	# (and we don't have a double click)
	return 1 if $self->selected_mail_id == $mail_id and $event->{type} ne '2button_press';

	if ( $column == 0 ) {
		# status click, only changes status of mail
		$self->change_mail_status ( mail_id => $mail_id, row => $row );
		return 1;
	}

	if ( $self->selected_mail_id != $mail_id ) {
		$self->selected_mail_id ( $mail_id );

		$self->debug ("mail_id=$mail_id selected_id=".$self->selected_mail_id);

		$self->folder_object->selected_mail_id ( $mail_id );
		$self->folder_object->save;
		$self->comp('mail')->show ( mail_id => $mail_id );
		$self->comp('folders')->update_folder_item;

		$self->show_mail_status (
			row => $row,
			status => $self->comp('mail')->mail->status
		);
	}

	if ( $event->{type} eq '2button_press' and
	     ( $self->folder_object->id == $self->config('drafts_folder_id') or
	       $self->folder_object->id == $self->config('templates_folder_id') ) ) {
	     
		my $compose = $self->comp('mail')->open_compose_window;
		$compose->delete_mail_after_send ($self->comp('mail')->mail)
			if $self->folder_object->id == $self->config('drafts_folder_id');
	
		return 1;
	}
	
	1;
}

sub show_mail_status{
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($status, $row) = @par{'status','row'};
	
	my $widget = $self->gtk_subjects_list;
	my $read_style = $widget->style->copy;
	my $font = $status eq 'R' ? 'font_mail_read' : 'font_mail_unread';

	$read_style->font($self->config($font));
	$widget->set_row_style(	$row, $read_style );
	$widget->set_text( $row, 0, $status ); 

	1;
}

sub change_mail_status {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($mail_id, $row) = @par{'mail_id','row'};

	my $mail = JaM::Mail->load ( dbh => $self->dbh, mail_id => $mail_id );

	my $status = $mail->status;
	$status = ( $status eq 'R' ) ? 'N' : 'R';

	$mail->status ( $status );
	$self->show_mail_status ( status => $status, row => $row );
	$self->comp('folders')->update_folder_item;

	1;
}

sub cb_column_click {
	my $self = shift;
	my ($clist, $clicked_column) = @_;
	
	my $folder_object = $self->folder_object;

	return 1 if not $folder_object;

	my $folders = $self->comp('folders');

	my $column    = $folder_object->sort_column;
	my $direction = $folder_object->sort_direction;

	if ( $column == $clicked_column ) {
		$direction = $direction eq 'ascending' ? 'descending' : 'ascending';
	}
	
	$self->debug ("set sort info: $column, $direction");

	$folder_object->sort_column ($clicked_column);
	$folder_object->sort_direction ($direction);
	$folder_object->save;

	$self->show;

	1;
}

sub quick_search {
	my $self = shift;
	my %par = @_;
	my ($type) = @par{'type'};
	
	my $dialog = Gtk::Dialog->new;
	$dialog->border_width(10);
	$dialog->set_position('mouse');
	$dialog->set_modal ( 1 );
	$dialog->set_title ("Quicksearch: '$type'");

	my $label = Gtk::Label->new ("Quicksearch: '$type'");
	$dialog->vbox->pack_start ($label, 1, 1, 0);
	$label->show;
	
	my $text = Gtk::Entry->new ( 40 );
	$dialog->vbox->pack_start ($text, 1, 1, 0);
	$text->show;
	$text->grab_focus;
	
	my $ok = new Gtk::Button( "Ok" );
	$ok->show;

	$dialog->action_area->pack_start( $ok, 1, 1, 0 );

	if ( $type eq 'body' ) {
		$ok->signal_connect( "clicked", sub {
			$self->show ( 
				where => "Entity.data like '%".$text->get_text."%' and ".
					 "Entity.mail_id = Mail.id",
				tables => "Entity",
			);
			$dialog->destroy;
		} );
	} else {
		$type = "head_to" if $type eq 'recipient';
		$ok->signal_connect( "clicked", sub {
			$self->show ( 
				where => "$type like '%".$text->get_text."%'"
			);
			$dialog->destroy;
		} );
	}

	my $cancel = new Gtk::Button( "Cancel" );
	$dialog->action_area->pack_start( $cancel, 1, 1, 0 );
	$cancel->signal_connect( "clicked", sub { $dialog->destroy } );
	$cancel->show();
	
	$dialog->show;
	
	return $dialog;
}

sub move_selected_mails {
	my $self = shift;
	my %par = @_;
	my ($folder_id) = @par{'folder_id'};

	my $selected_mail_ids = $self->selected_mail_ids;
	return if not @{$selected_mail_ids};

	my $folder_object = JaM::Folder->by_id ($folder_id);

	$self->comp('mail')->move_to_folder (
		folder_object => $folder_object,
		mail_ids      => $selected_mail_ids
	);

	$self->remove_selected;
	
	1;
}

1;
