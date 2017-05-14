# $Id: Folders.pm,v 1.22 2002/03/03 13:16:05 joern Exp $

package JaM::GUI::Folders;

@ISA = qw ( JaM::GUI::Component );

use strict;
use JaM::GUI::Component;
use JaM::GUI::Compose;
use JaM::Folder;

my $DEBUG = 0;

my @closed_xpm = ( "16 16 6 1",
                  "       c None s None",
                  ".      c black",
                  "X      c #a0a0a0",
                  "o      c yellow",
                  "O      c #808080",
                  "#      c white",
                  "                ",
                  "       ..       ",
                  "     ..XX.      ",
                  "   ..XXXXX.     ",
                  " ..XXXXXXXX.    ",
                  ".ooXXXXXXXXX.   ",
                  "..ooXXXXXXXXX.  ",
                  ".X.ooXXXXXXXXX. ",
                  ".XX.ooXXXXXX..  ",
                  " .XX.ooXXX..#O  ",
                  "  .XX.oo..##OO. ",
                  "   .XX..##OO..  ",
                  "    .X.#OO..    ",
                  "     ..O..      ",
                  "      ..        ",
                  "                ");
my @open_xpm = ( "16 16 4 1",
                "       c None s None",
                ".      c black",
                "X      c #808080",
                "o      c white",
                "                ",
                "  ..            ",
                " .Xo.    ...    ",
                " .Xoo. ..oo.    ",
                " .Xooo.Xooo...  ",
                " .Xooo.oooo.X.  ",
                " .Xooo.Xooo.X.  ",
                " .Xooo.oooo.X.  ",
                " .Xooo.Xooo.X.  ",
                " .Xooo.oooo.X.  ",
                "  .Xoo.Xoo..X.  ",
                "   .Xo.o..ooX.  ",
                "    .X..XXXXX.  ",
                "    ..X.......  ",
                "     ..         ",
                "                ");
my @leaf_xpm = ( "16 16 4 1",
                "       c None s None",
                ".      c black",
                "X      c white",
                "o      c #808080",
                "                ",
                "   .......      ",
                "   .XXXXX..     ",
                "   .XoooX.X.    ",
                "   .XXXXX....   ",
                "   .XooooXoo.o  ",
                "   .XXXXXXXX.o  ",
                "   .XooooooX.o  ",
                "   .XXXXXXXX.o  ",
                "   .XooooooX.o  ",
                "   .XXXXXXXX.o  ",
                "   .XooooooX.o  ",
                "   .XXXXXXXX.o  ",
                "   ..........o  ",
                "    oooooooooo  ",
                "                ");

@leaf_xpm = @open_xpm = @closed_xpm;

my ($closed_pix, $closed_mask);
my ($opened_pix, $opened_mask);
my ($leaf_pix,   $leaf_mask);

# get/set selected Folder
sub selected_folder_object	{ my $s = shift; $s->{selected_folder_object	}
		          	  = shift if @_; $s->{selected_folder_object}	}

# get/set selected Folder object on which a Popup is requested
sub popup_folder_object	{ my $s = shift; $s->{popup_folder_object}
		          = shift if @_; $s->{popup_folder_object}		}

# get/set selected row on which a Popup is requested
sub popup_row           { my $s = shift; $s->{popup_row}
		          = shift if @_; $s->{popup_row}			}

# get/set list ref of folder gtk items
sub gtk_folder_items	{ my $s = shift; $s->{gtk_folder_items}
		          = shift if @_; $s->{gtk_folder_items}			}

# get/set gtk object for folder scrollable window
sub gtk_folders		{ my $s = shift; $s->{gtk_folders}
		          = shift if @_; $s->{gtk_folders}			}

# get/set gtk object for folder ctree
sub gtk_folders_tree	{ my $s = shift; $s->{gtk_folders_tree}
		          = shift if @_; $s->{gtk_folders_tree}			}

# get/set gtk style for folder without new mails
sub gtk_read_style	{ my $s = shift; $s->{gtk_read_style}
		          = shift if @_; $s->{gtk_read_style}			}

# get/set gtk style for folder with unread mails
sub gtk_unread_style	{ my $s = shift; $s->{gtk_unread_style}
		          = shift if @_; $s->{gtk_unread_style}			}

# get/set gtk style for folder with unread child folders
sub gtk_unread_child_style { my $s = shift; $s->{gtk_unread_child_style}
		             = shift if @_; $s->{gtk_unread_child_style}			}

# popup menu separator for "Create Template"
sub gtk_template_sep	{ my $s = shift; $s->{gtk_template_sep}
		          = shift if @_; $s->{gtk_template_sep}			}

# popup menu item for "Create Template"
sub gtk_template_item	{ my $s = shift; $s->{gtk_template_item}
		          = shift if @_; $s->{gtk_template_item}		}

sub gtk_ignore_reply_to	{ my $s = shift; $s->{gtk_ignore_reply_to}
		          = shift if @_; $s->{gtk_ignore_reply_to}		}

sub gtk_dont_ignore_reply_to
			{ my $s = shift; $s->{gtk_dont_ignore_reply_to}
		          = shift if @_; $s->{gtk_dont_ignore_reply_to}		}

# helper method for setting up pixmaps
sub initialize_pixmap {
	my $self = shift; $self->trace_in;
	my @xpm = @_;

	my ($pixmap, $mask);
	my $win   = $self->gtk_win;
	my $style = $win->get_style()->bg( 'normal' );

	return ($pixmap, $mask) = Gtk::Gdk::Pixmap->create_from_xpm_d (
		$win->window, $style, @xpm
	);
}

# build scrolled window for folder ctree
sub build {
	my $self = shift; $self->trace_in;
	
	JaM::Folder->init ( dbh => $self->dbh );
	
	my $folders = new Gtk::ScrolledWindow (undef, undef);
	$folders->set_policy ('automatic', 'automatic');
	$folders->set_usize($self->config('folders_width'), undef);

	$folders->signal_connect("size-allocate",
		sub { $self->config('folders_width', $_[1]->[2]) }
	);

	# Set up Pixmaps
	($closed_pix, $closed_mask) = $self->initialize_pixmap( @closed_xpm );
	($opened_pix, $opened_mask) = $self->initialize_pixmap( @open_xpm );
	($leaf_pix,   $leaf_mask)   = $self->initialize_pixmap( @leaf_xpm );

	my $root_tree = Gtk::CTree->new_with_titles (
		0, 'Name','Unread','Total'
	);

	$root_tree->signal_connect("resize-column",
		sub {
			$self->config('folders_column_'.$_[1], $_[2]);
		}
	);

	$root_tree->set_column_width (0, $self->config('folders_column_0'));
	$root_tree->set_column_width (1, $self->config('folders_column_1'));
	$root_tree->set_column_width (2, $self->config('folders_column_2'));
	$root_tree->set_reorderable(1);
	$root_tree->set_line_style ('dotted');
#	$root_tree->set_user_data ($self);
	$root_tree->signal_connect ('select_row', sub { $self->cb_folder_select(@_) } );
	$root_tree->signal_connect ('tree-expand', sub {
		$self->cb_tree_click ( type => 'expand', tree => $_[0], node => $_[1] ) }
	);
	$root_tree->signal_connect ('tree-collapse', sub {
		$self->cb_tree_click ( type => 'collapse', tree => $_[0], node => $_[1] ) }
	);
	$root_tree->signal_connect ('tree-move', sub {
		$self->cb_tree_move ( @_ ) }
	);

	$root_tree->set_selection_mode( 'browse' );
	$folders->add_with_viewport($root_tree);
	$root_tree->show;

	# build tree
	my $unread_style = $root_tree->style->copy;
	$unread_style->font($self->config('font_folder_unread'));
	my $read_style = $root_tree->style->copy;
	$read_style->font($self->config('font_folder_read'));
	my $unread_child_style = $root_tree->style->copy;
	$unread_child_style->font($self->config('font_folder_unread'));
	$unread_child_style->fg('normal',$self->gdk_color($self->config('folder_unread_child_color')));

	$self->gtk_unread_style ($unread_style);
	$self->gtk_unread_child_style ($unread_child_style);
	$self->gtk_read_style   ($read_style);

	$self->gtk_folder_items ( {} );
	$self->gtk_folders ($folders);
	$self->gtk_folders_tree ($root_tree);

	$self->add_tree (
		tree      => $root_tree,
		parent_id => 1
	);

	$folders->show;

	$root_tree->signal_connect('button_press_event', sub { $self->cb_click_clist(@_) } );

	# now build popup Menu
	my $popup = $root_tree->{popup} = Gtk::Menu->new;
	my $item;

	$item = Gtk::MenuItem->new ("Advanced Search...");
	$popup->append($item);
	$item->signal_connect ("activate", sub {$self->cb_search_in_folder ( @_ ) } );
	$item->show;

	$item = Gtk::MenuItem->new;
	$popup->append($item);
	$item->show;

	$item = Gtk::MenuItem->new ("Rename Folder...");
	$popup->append($item);
	$item->signal_connect ("activate", sub { $self->cb_rename_folder ( @_ ) } );
	$item->show;
	$item = Gtk::MenuItem->new ("Create New Folder...");
	$popup->append($item);
	$item->signal_connect ("activate", sub { $self->cb_create_folder ( @_ ) } );
	$item->show;
	$item = Gtk::MenuItem->new ("Delete Folder...");
	$popup->append($item);
	$item->signal_connect ("activate", sub { $self->cb_delete_folder ( @_ ) } );
	$item->show;
	
	$item = Gtk::MenuItem->new;
	$popup->append($item);
	$item->show;

	$item = Gtk::MenuItem->new ("Add Input Filter...");
	$popup->append($item);
	$item->signal_connect ("activate", sub { $self->cb_add_input_filter ( @_ ) } );
	$item->show;

	$item = Gtk::MenuItem->new;
	$popup->append($item);
	$item->show;

	my $ignore_reply_to_item = Gtk::RadioMenuItem->new_with_label ("Ignore Reply-To Header");
	$popup->append($ignore_reply_to_item);
	$ignore_reply_to_item->signal_connect ("activate", sub { $self->cb_ignore_reply_to ( @_ ) } );
	$ignore_reply_to_item->show;

	$self->gtk_ignore_reply_to  ($ignore_reply_to_item);

	$item = Gtk::RadioMenuItem->new_with_label ("Don't ignore Reply-To Header", $ignore_reply_to_item);
	$popup->append($item);
	$item->signal_connect ("activate", sub { $self->cb_dont_ignore_reply_to ( @_ ) } );
	$item->show;

	$self->gtk_dont_ignore_reply_to  ($item);

	$item = Gtk::MenuItem->new;
	$popup->append($item);

	$self->gtk_template_sep ( $item );

	$item = Gtk::MenuItem->new ("Create New Template...");
	$popup->append($item);
	$item->signal_connect ("activate", sub { $self->cb_create_new_template ( @_ ) } );

	$self->gtk_template_item ( $item );

	$self->widget ($folders);

	$self->update_folder_stati;

	return $self;
}

sub add_tree {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my  ($tree, $parent_id) =
	@par{'tree','parent_id'};

	my $folders_href = JaM::Folder->query ( 
		dbh => $self->dbh,
		where => "parent_id = ?",
		params => [ $parent_id ]
	);

	my $folder_items = $self->gtk_folder_items;
	
	# build sibling hash
	my %sibling;
	for ( keys %{$folders_href} ) {
		$folders_href->{$_}->save; # recalculate path
		$sibling{$folders_href->{$_}->sibling_id} = $folders_href->{$_};
	}

	# we start with the folder, which has no sibling
	my $sibling_id = 99999;
	my $max = scalar(keys(%sibling));

	my ($folder, $sibling_item, $item);
	for (my $i=0; $i < $max; ++$i) {
		$folder = $sibling{$sibling_id};
		$sibling_item = $folder_items->{$sibling_id}
			if $sibling_id != 99999;
		
		$self->insert_folder_item (
			folder_object => $folder,
			sibling_item => $sibling_item,
		);

		$sibling_id = $folder->id;
	}

	1;
}

sub insert_folder_item {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my  ($folder_object, $sibling_item) =
	@par{'folder_object','sibling_item'};
	
	my $folder_items = $self->gtk_folder_items;
	my $tree = $self->gtk_folders_tree;
	my $parent_id = $folder_object->parent_id;
	
	my $item = $folder_items->{$folder_object->id} = $tree->insert_node (
		$folder_items->{$parent_id},
		$sibling_item,
		[ $folder_object->name,
		  $folder_object->mail_sum -
		  $folder_object->mail_read_sum,
		  $folder_object->mail_sum ],
		5,
		$closed_pix, $closed_mask,
		$opened_pix, $opened_mask,
		0, ($folder_object->leaf ? 1 : $folder_object->opened)
	);

	$self->add_tree (
		tree => $tree,
		parent_id => $folder_object->id
	) if not $folder_object->leaf;

	$item->{folder_id} = $folder_object->id;

	$tree->node_set_row_style(
		$item, ($folder_object->mail_read_sum < $folder_object->mail_sum) ?
		       $self->gtk_unread_style : $self->gtk_read_style
	);
	
	return $item;
}

sub cb_click_clist {
	my $self = shift;
	my ($widget, $event) = @_;

	my ( $row, $column ) = $widget->get_selection_info( $event->{x}, $event->{y} );

	$self->popup_folder_object (
		JaM::Folder->by_id($widget->node_nth( $row )->{folder_id})
	);
	$self->popup_row ($widget->node_nth( $row ));

	if ( $event->{button} == 3 and $widget->{'popup'} ) {
		if ( $self->popup_folder_object->folder_id ==
		     $self->config('templates_folder_id') ) {
			$self->gtk_template_sep->show;
			$self->gtk_template_item->show;
		} else {
			$self->gtk_template_sep->hide;
			$self->gtk_template_item->hide;
		}
		if ( $self->popup_folder_object->ignore_reply_to ) {
			$self->gtk_ignore_reply_to->set_active(1);
		} else {
			$self->gtk_dont_ignore_reply_to->set_active(1);
		}
		$widget->{'popup'}->popup(undef,undef,$event->{button},1);
	}

	1;
}

sub cb_rename_folder {
	my $self = shift;

	my $folder_object = $self->popup_folder_object;
	my $name = $folder_object->name;

	my $dialog;
	$dialog = $self->folder_dialog (
		title => "Rename Folder",
		label => "Enter new name for folder '$name'",
		value => $name,
		cb => sub {
			my ($text) = @_;
			return $self->rename_folder (
				folder_object => $folder_object,
				name => $text->get_text,
			);
		}
	);

	1;
}

sub cb_search_in_folder {
	my $self = shift;

	my $folder_object = $self->popup_folder_object;
	
  	require JaM::GUI::Search;
  	my $search = JaM::GUI::Search->new (
		dbh => $self->dbh
	);
	$search->open_window;
	
	$search->folder_chosen ($folder_object->id);
	
	1;
}

sub cb_create_new_template {
	my $self = shift;
	
	my $compose = JaM::GUI::Compose->new (
		dbh => $self->dbh
	);
	
	$compose->save_as_template(1);

	$compose->build;
	
	1;
}

sub folder_dialog {
	my $self = shift;
	my %par = @_;
	my ($title, $label_text, $value, $cb) = @par{'title','label','value','cb'};

	my $dialog = Gtk::Dialog->new;
	$dialog->border_width(10);
	$dialog->set_position('mouse');
	$dialog->set_title ($title);

	my $label = Gtk::Label->new ($label_text);
	$dialog->vbox->pack_start ($label, 1, 1, 0);
	$label->show;
	
	my $text = Gtk::Entry->new ( 40 );
	$dialog->vbox->pack_start ($text, 1, 1, 0);
	$text->set_text ( $value );
	$text->show;
	
	my $ok = new Gtk::Button( "Ok" );
	$dialog->action_area->pack_start( $ok, 1, 1, 0 );
	$ok->signal_connect( "clicked", sub {
		&$cb($text) && $dialog->destroy;
	} );
	$ok->show();

	my $cancel = new Gtk::Button( "Cancel" );
	$dialog->action_area->pack_start( $cancel, 1, 1, 0 );
	$cancel->signal_connect( "clicked", sub { $dialog->destroy } );
	$cancel->show();
	
	$dialog->show;
	
	return $dialog;
}

sub rename_folder {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($folder_object, $name) = @par{'folder_object','name'};
	
	$self->debug ("folder_id=".$folder_object->id.", name=$name");
	
	return if not $name;

	my $childs_with_same_name = JaM::Folder->query (
		where => "parent_id = ? and name=?",
		params => [ $folder_object->parent_id, $name ]
	);
	
	if ( keys %{$childs_with_same_name} ) {
		$self->message_window (
			message => "A folder with this name already exists."
		);
		return;
	}
	
	$folder_object->name($name);
	$folder_object->save;
	
	$self->update_folder_item ( folder_object => $folder_object );
	
	1;
}

sub cb_create_folder {
	my $self = shift;

	my $folder_object = $self->popup_folder_object;

	my $dialog;
	$dialog = $self->folder_dialog (
		title => "Create Folder",
		label => "Enter name for the new folder",
		value => "",
		cb => sub {
			my ($text) = @_;
			return $self->create_folder (
				parent_folder_object => $folder_object,
				name => $text->get_text,
			);
		}
	);

	1;
}

sub cb_tree_click {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($type, $tree, $node) = @par{'type','tree','node'};
	
	my $opened = $type eq 'expand' ? 1 : 0;
	my $folder_object = JaM::Folder->by_id($node->{folder_id});
	
	$folder_object->opened($opened);
	$folder_object->save;

	1;
}

# callback for folder selection
sub cb_folder_select {
	my $self = shift; $self->trace_in;
	my ($ctree, $row) = @_;

	my $node = $ctree->node_nth( $row );
	my $folder_object = JaM::Folder->by_id($node->{folder_id});

	$self->selected_folder_object ( $folder_object );

	$self->comp('mail')->no_status_change_on_show(1);
	$self->comp('subjects')->show (
		folder_object => $folder_object,
	);
	$self->comp('mail')->no_status_change_on_show(0);

	my $gui = $self->comp('gui');
	$gui->no_subjects_update (1);
	$gui->update_folder_limit (
		folder_object => $folder_object
	);
	$gui->no_subjects_update (0);
	
	1;
}

# update ctree item for a specific folder from database
sub update_folder_item {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my  ($folder_object, $no_folder_stati) =
	@par{'folder_object','no_folder_stati'};

	$folder_object ||= $self->selected_folder_object;

	$self->debug ("folder_id=".$folder_object->id);

	my $name = $folder_object->name;

	my $item = $self->gtk_folder_items->{$folder_object->id};

	my $widget = $self->gtk_folders_tree;

	my ($text, $spacing, $pixmap, $mask) = $widget->node_get_pixtext( $item, 0 );
	if ( $name ne $text ) {	
		$self->debug ("folder name changed: old=$text new=$name");
		$widget->node_set_pixtext( $item, 0, $name, $spacing, $pixmap, $mask );
	}
	
	my ($mail_sum, $mail_read_sum) = ($folder_object->mail_sum,
					  $folder_object->mail_read_sum);

	$self->debug ("mail_sum=$mail_sum, mail_read_sum=$mail_read_sum");

	$widget->set_text( $item, 1, $mail_sum -
				     $mail_read_sum); 
	$widget->set_text( $item, 2, $mail_sum); 

	$widget->node_set_row_style(
		$item, ($mail_read_sum < $mail_sum) ?
		       $self->gtk_unread_style : $self->gtk_read_style
	);
	
	$self->update_folder_stati
		if not $no_folder_stati;

	1;
}

sub update_folder_stati {
	my $self = shift; $self->trace_in;
	
	$self->debug ("updating folder read/unread stati");
	
	JaM::Folder->recalculate_folder_stati ( dbh => $self->dbh );

	my $folder_items = $self->gtk_folder_items;
	my $folders_tree = $self->gtk_folders_tree;

	my $all_folders = JaM::Folder->all_folders;

	my ($folder_id, $folder, $status, $style);
	while ( ($folder_id, $folder) = each %{$all_folders} ) {
		next if $folder_id == 1;
		$status = $folder->status;
		if ( $folder_items->{$folder_id}->{status} ne $status ) {
			$style = $self->gtk_read_style;
			$style = $self->gtk_unread_style if $status eq 'N';
			$style = $self->gtk_unread_child_style if $status eq 'NC';
			$folders_tree->node_set_row_style(
				$folder_items->{$folder_id}, $style
			);
			$folder_items->{$folder_id}->{status} = $status;
		}
	}
	
	1;
}

sub create_folder {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my  ($parent_folder_object, $name) =
	@par{'parent_folder_object','name'};
	
	my $parent_id = $parent_folder_object->id;
	
	$self->debug ("parent_id=$parent_id name=$name");
	
	# check if name clashes
	my $childs_with_same_name = JaM::Folder->query (
		where => "parent_id = ? and name=?",
		params => [ $parent_folder_object->id, $name ]
	);
	
	if ( keys %{$childs_with_same_name} ) {
		$self->message_window (
			message => "A folder with this name already exists."
		);
		return;
	}
	
	my $folder_items = $self->gtk_folder_items;
	my $folders_tree = $self->gtk_folders_tree;
	
	my $parent_item = $folder_items->{$parent_folder_object->id};
	my $sibling_item;
	my $sibling_folder_object;

	if ( $parent_folder_object->leaf ) {
		$parent_folder_object->leaf (0); 
		$parent_folder_object->save;

	} else {
		my $sibling_id = $parent_folder_object->get_first_child_folder_id;
		$self->debug("sibling_id=$sibling_id");
		if ( $sibling_id ) {
			$sibling_item = $folder_items->{$sibling_id};
			$sibling_folder_object = JaM::Folder->by_id($sibling_id);
		}
	}
	
	my $new_folder = JaM::Folder->create (
		dbh => $self->dbh,
		name => $name,
		parent => $parent_folder_object,
		sibling => $sibling_folder_object
	);

	my $item = $self->insert_folder_item (
		folder_object => $new_folder,
		sibling_item => $sibling_item,
	);

	1;
}

sub cb_tree_move {
	my $self = shift;
	my ($ctree, $moved, $parent, $sibling) = @_;

	my $moved_object  = JaM::Folder->by_id($moved->{folder_id});

	my $sibling_object;
	$sibling_object   = JaM::Folder->by_id($sibling->{folder_id}) if $sibling;

	my $parent_object;
	$parent_object = JaM::Folder->by_id($parent->{folder_id}) if $parent;
	$parent_object = JaM::Folder->by_id(1) if not $parent;

	$self->move_tree (
		moved_object   => $moved_object,
		parent_object  => $parent_object,
		sibling_object => $sibling_object,
	);
	
	1;
}

sub move_tree {
	my $self = shift;
	my %par = @_;

	my  ($moved_object, $parent_object, $sibling_object) =
	@par{'moved_object','parent_object','sibling_object'};
	
	$self->debug("moved_object");$self->dump ($moved_object);
	$self->debug("parent_object");$self->dump ($parent_object);
	$self->debug("sibling_object");$self->dump ($sibling_object);
	
	
	# rename folder if name clashes with siblings in the new folder
	while (1) {
		my $childs_with_same_name = JaM::Folder->query (
			where => "parent_id = ? and name=? and id != ?",
			params => [ $parent_object->id, $moved_object->name,
				    $moved_object->id ]
		);
		if  ( keys %{$childs_with_same_name} ) {
			my $name = $moved_object->name;
			$name =~ s/(\d+)?$/$1+1/e;
			$moved_object->name($name);			
		} else {
			last;
		}
	}
	
	my $folder_items  = $self->gtk_folder_items;
	
	# is the parent_object a leaf? change that!
	if ( $parent_object->leaf ) {
		$parent_object->leaf(0);
		$parent_object->save;
	}
	
	# if we was the last child, tell our parent,
	# that now it is a leaf
	$self->debug ("sibling_id=".$moved_object->sibling_id." sibling_of_id=",$moved_object->sibling_of_id);
	if ( $moved_object->sibling_id == 99999 and not $moved_object->sibling_of_id ) {
		my $my_parent_object = JaM::Folder->by_id($moved_object->parent_id);
		$my_parent_object->leaf(1);
		$my_parent_object->save;
	}

	# First remove the moved item
	# We have to handle two cases:
	# - it has a sibling
	# - it has no sibling
	if ( $moved_object->sibling_id == 99999 ) {
		# no sibling - now the object we are sibling of
		# will have no sibling anymore
		my $sibling_of_id = $moved_object->sibling_of_id;
		if ( $sibling_of_id ) {
			my $sibling_of = JaM::Folder->by_id($sibling_of_id);
			$sibling_of->sibling_id(99999);
			$sibling_of->save;
		}
	} else {
		# ok, we have a sibling. connect it to the object,
		# we are sibling of
		my $sibling_of_id = $moved_object->sibling_of_id;
		if ( $sibling_of_id ) {
			my $sibling_of = JaM::Folder->by_id($sibling_of_id);
			my $my_sibling = JaM::Folder->by_id($moved_object->sibling_id);
			$sibling_of->sibling_id($my_sibling->id);
			$sibling_of->save;
		}
	}

	# Now place the moved item
	# Again we have two cases:
	# - we'll have a sibling
	# - we'll have no sibling
	if ( $sibling_object ) {
		# ok, we'll have a sibling
		my $sibling_of_id = $sibling_object->sibling_of_id;
		if ( $sibling_of_id ) {
			my $sibling_of = JaM::Folder->by_id($sibling_of_id);
			$sibling_of->sibling_id ($moved_object->id);
			$sibling_of->save;
		}
		$moved_object->sibling_id($sibling_object->id);
	} else {
		# we'll have no sibling
		my $last_folder_id = $parent_object->get_last_child_folder_id;
		$self->debug("last_folder_id=$last_folder_id");
		if ( $last_folder_id ) {
			my $sibling_of = JaM::Folder->by_id($last_folder_id);
			$sibling_of->sibling_id($moved_object->id);
			$sibling_of->save;
		}
		$moved_object->sibling_id(99999);
	}

	# set parent_id (this computes the new path also)
	$moved_object->parent_id ($parent_object->id);
	
	# save
	$moved_object->save;

	# update item (may be it has been renamed)
	$self->update_folder_item ( folder_object => $moved_object );

	1;
}

sub cb_delete_folder {
	my $self = shift;
	
	my $folder_object = $self->popup_folder_object;
	
	my $trash_id = $self->config('trash_folder_id');
	my $trash_object = JaM::Folder->by_id($trash_id);

	# check if this *is* the trash folder itself
	if ( $trash_id == $folder_object->id ) {
		$self->message_window (
			 message => "You can't trash trash."
		);
		return 1;
	}
	
	# check if this folder is already in trash
	my $trash_path = $trash_object->path;
	my $path = $folder_object->path;

	if ( $path =~ m!^$trash_path! ) {
		$self->message_window (
			message => "Folder is already in trash."
		);
		return 1;
	}

	# check if the trash folder is a descendant of this folder
	my $desc = $folder_object->descendants;
	if ( defined $desc->{$trash_id} ) {
		$self->message_window (
			message => "The trash folder is a descendant of this folder."
		);
		return 1;
	}

	# check if this folder is undeletable
	if ( $folder_object->undeletable ) {
		$self->message_window (
			message => "You can't delete this folder."
		);
		return 1;
	}

	# update database
	$self->move_tree (
		moved_object => $folder_object,
		parent_object => $trash_object,
	);
	
	# update gui: remove item
	my $folder_item = $self->gtk_folder_items->{$folder_object->id};
	$self->gtk_folders_tree->remove ($folder_item);
	
	# update gui: insert into trash
	$self->insert_folder_item (
		folder_object => $folder_object,
		sibling_item => undef,
	);

	1;
}

sub build_menu_of_folders {
	my $self= shift;
	my %par = @_;
	my ($callback) = @par{'callback'};

	my $root_folder = JaM::Folder->by_id(1);

	my $menu = $self->build_submenu (
		parent   => $root_folder,
		callback => $callback,
	);

#	my $menu = Gtk::Menu->new;
#	$menu->append($submenu);
#	$menu->show;
	
	return $menu;
}

sub build_submenu {
	my $self = shift;
	my %par = @_;
	my ($parent, $callback) = @par{'parent','callback'};
	
	my $menu;
	
	if ( not $parent->leaf ) {
		my $childs = JaM::Folder->query (
			where => "parent_id=?",
			params => [ $parent->id ]
		);

		$menu = Gtk::Menu->new;
		$menu->show;

		if ( $parent->id != 1 ) {
			my $drop_here = Gtk::MenuItem->new ("[Drop here]");
			$drop_here->signal_connect ("activate", sub { &$callback($parent->id) } );
			$drop_here->show;
			$menu->append($drop_here);
		}

		foreach my $folder ( sort { $a->path cmp $b->path} values %{$childs} ) {
			my $item = Gtk::MenuItem->new ($folder->name);
			$item->show;
			if ( $folder->leaf ) {
				$item->signal_connect ("activate", sub { &$callback($folder->id) } );
			}
			$menu->append($item);
	
			my $submenu = $self->build_submenu (
				parent => $folder,
				callback => $callback,
			);
			
			$item->set_submenu($submenu) if $submenu;
		}

	}
	
	return $menu;
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
	
	$filter->add_new_filter (
		folder_object => $self->popup_folder_object
	);
	
	$filter->gtk_win->focus(1);
	
	1;
}

sub empty_trash_folder {
	my $self = shift;
	
	my $trash_folder_id = $self->config('trash_folder_id');
	
	my $folder = JaM::Folder->by_id($trash_folder_id);

	my $folder_item = $self->gtk_folder_items->{$trash_folder_id};
	my $sibling_id = $folder->sibling_id;

	my $sibling_item;
	if ( $sibling_id ) {
		$sibling_item = $self->gtk_folder_items->{$sibling_id};
	}

	$folder->delete_content;

	$self->gtk_folders_tree->remove($folder_item);

	$self->insert_folder_item (
		folder_object => $folder,
		sibling_item  => $sibling_item,
	);

	$self->comp('folders')->update_folder_item (
		folder_object => $folder
	);
	
	1;
}

sub cb_ignore_reply_to {
	my $self = shift;
	
	my $folder_object = $self->popup_folder_object;
	
	$folder_object->ignore_reply_to (1);
	$folder_object->save;
	
	1;
}

sub cb_dont_ignore_reply_to {
	my $self = shift;
	
	my $folder_object = $self->popup_folder_object;
	
	$folder_object->ignore_reply_to (0);
	$folder_object->save;
	
	1;
}

1;
