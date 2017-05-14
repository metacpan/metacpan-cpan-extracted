# $Id: IO_Filter.pm,v 1.3 2001/09/02 11:15:26 joern Exp $

package JaM::GUI::IO_Filter;

@ISA = qw ( JaM::GUI::Window );

use strict;
use JaM::GUI::Window;
use JaM::Filter::IO;

my $DEBUG = 1;

# get/set gtk object for subjects clist
sub gtk_win		{ my $s = shift; $s->{gtk_win}
		          = shift if @_; $s->{gtk_win}		}

sub gtk_filter_list	{ my $s = shift; $s->{gtk_filter_list}
		          = shift if @_; $s->{gtk_filter_list}	}

sub gtk_filter_frame	{ my $s = shift; $s->{gtk_filter_frame}
		          = shift if @_; $s->{gtk_filter_frame}	}

sub gtk_folder_menu	{ my $s = shift; $s->{gtk_folder_menu}
		          = shift if @_; $s->{gtk_folder_menu}	}

sub gtk_filter_folder	{ my $s = shift; $s->{gtk_filter_folder}
		          = shift if @_; $s->{gtk_filter_folder} }

sub gtk_filter_vbox	{ my $s = shift; $s->{gtk_filter_vbox}
		          = shift if @_; $s->{gtk_filter_vbox}  }

sub filter_ids		{ my $s = shift; $s->{filter_ids}
		          = shift if @_; $s->{filter_ids}	}

sub selected_filter	{ my $s = shift; $s->{selected_filter}
		          = shift if @_; $s->{selected_filter}	}

sub filter_type		{ my $s = shift; $s->{filter_type}
		          = shift if @_; $s->{filter_type}	}

sub single_instance_window { 1 }

sub build {
	my $self = shift; $self->trace_in;

	my $win = Gtk::Window->new;
	$win->set_position ("center");
	$win->set_title ("Edit Input/Output Filter");
	$win->border_width(3);
	$win->set_default_size (530, 500);
	$win->realize;
	$win->show;

	my $vpane = new Gtk::VPaned();
	$vpane->show();
	$win->add ($vpane);
	$vpane->set_handle_size( 10 );
	$vpane->set_gutter_size( 15 );
	
	my $fr = Gtk::Frame->new ("Select filter");
	$fr->show;

	my $hbox = Gtk::HBox->new(0,5);
	$hbox->show;
	$hbox->set_border_width(5);
	$fr->add($hbox);

	my $sw = new Gtk::ScrolledWindow( undef, undef );
	$sw->set_policy( 'never', 'automatic' );
	$sw->set_usize(250, 200);
	$sw->show();

	my $list = Gtk::CList->new_with_titles ( "" );
	$list->set_selection_mode( 'browse' );
	$list->set_shadow_type( 'none' );
	$list->set_reorderable(1);
	$list->set_usize (350, 200);
	$list->signal_connect ('row-move', sub {
		$self->cb_row_move ( @_ ) }
	);
	$list->signal_connect( "select_row", sub { $self->cb_select_filter(@_) } );
	$list->show();

	$sw->add ($list);

	$hbox->pack_start ($sw, 1, 1, 0);
	
	my $vbox = Gtk::VBox->new(0,5);
	$vbox->show;
	
	my $ok_button = Gtk::Button->new( "Ok" );
	$ok_button->show;
	$ok_button->signal_connect('clicked', sub {
		$self->save_selected_filter;
		$win->destroy;
	});
	$vbox->pack_start($ok_button, 0, 1, 1);

	my $add_button = Gtk::Button->new( "Add" );
	$add_button->show;
	$add_button->signal_connect('clicked', sub {
		$self->add_new_filter;
	});
	$vbox->pack_start($add_button, 0, 1, 1);

	my $del_button = Gtk::Button->new( "Delete" );
	$del_button->show;
	$del_button->signal_connect('clicked', sub { $self->cb_delete (@_) } );
	$vbox->pack_start($del_button, 0, 1, 1);

	my $type_radio_input = Gtk::RadioButton->new ("Edit Input Filters");
	$type_radio_input->show;
	$type_radio_input->set_active(1);
	$type_radio_input->signal_connect (
		"clicked", sub {
			$self->debug("switch2 input");
			$self->show_filters(type => 'input')
		}
	);
	$vbox->pack_start($type_radio_input, 0, 0, 0);
	my $type_radio_output = Gtk::RadioButton->new ("Edit Output Filters", $type_radio_input);
	$type_radio_output->show;
	$type_radio_output->signal_connect (
		"clicked", sub {
			$self->debug("switch2 output");
			$self->show_filters(type => 'output')
		}
	);
	$vbox->pack_start($type_radio_output, 0, 0, 0);

	my $text_label = Gtk::Label->new (
		"Filter order is relevant. The first\n".
		"filter which matches will terminate\n".
		"filter evaluation. You can drag and\n".
		"drop filter rows to manipulate the\n".
		"order."
	);
	$text_label->show;
	$text_label->set_line_wrap(1);

	$vbox->pack_start($text_label, 0, 1, 1);

	$hbox->pack_start ($vbox, 0, 0, 0);

	$vpane->add1 ($fr);
	
	my $filter_frame = Gtk::Frame->new ("Edit selected filter");
	$filter_frame->show;
	
	$vpane->add2 ($filter_frame);

	my $folder_menu = $self->comp('folders')->build_menu_of_folders (
		callback => sub {
			my ($folder_id) = @_;
			$self->drop_folder_chosen($folder_id);
		}
	);
	
	$self->gtk_win ($win);
	$self->gtk_filter_list  ($list);
	$self->gtk_filter_frame ($filter_frame);
	$self->gtk_folder_menu ($folder_menu);

	$self->filter_ids([]);

	$self->show_filters ( type => 'input' );

	$self->gtk_window_widget ($win);

	1;
}

sub show_filters {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($type) = @par{'type'};
	
	if ( $self->selected_filter ) {
		$self->save_selected_filter;
	}

	my $list = $self->gtk_filter_list;
	$list->freeze;
	$list->clear;
	$list->set_column_title(
		0,
		$type eq 'input' ? 'Input Filter' : 'Output Filter'
	);

	my $filter_ids = $self->filter_ids([]);

	my $filters = JaM::Filter::IO->list (
		dbh => $self->dbh,
		type => $type,
	);
	foreach my $filter ( @{$filters} ) {
		$list->append($filter->{name});
		push @{$filter_ids}, $filter->{id};
	}

	$list->thaw;

	$self->blank_edit_pane;

	$list->select_row (0, 0);
	
	$self->filter_type($type);

	1;
}

sub cb_row_move {
	my $self = shift; $self->trace_in;
	my ($widget, $from_row, $to_row) = @_;
	
	$self->debug ("from_row=$from_row to_row=$to_row");
	
	my $filter_ids = $self->filter_ids;

	my $from_id = $filter_ids->[$from_row];
	
	if ( $from_row < $to_row ) {
		splice @{$filter_ids}, $to_row+1, 0, $from_id;
		splice @{$filter_ids}, $from_row, 1;
	} else {
		++$from_row;
		splice @{$filter_ids}, $to_row, 0, $from_id;
		splice @{$filter_ids}, $from_row, 1;
	}
	
	JaM::Filter::IO->reorder (
		dbh => $self->dbh,
		filter_ids => $filter_ids
	);
}

sub cb_delete {
	my $self = shift; $self->trace_in;

	my $row = $self->gtk_filter_list->selection;
	return 1 if not defined $row;

	my $filter_ids = $self->filter_ids;
	my $filter_id = $filter_ids->[$row];

	$self->debug("row=$row filter_id=$filter_id");

	my $filter = $self->selected_filter;
	$self->selected_filter(undef);

	$self->gtk_filter_list->remove ($row);
	splice @{$filter_ids}, $row, 1;

	$filter->delete;

	if ( @{$filter_ids} == 0 ) {
		$self->blank_edit_pane;
	} else {
		$row = @{$filter_ids}-1 if $row > @{$filter_ids}-1;
		$self->gtk_filter_list->select_row($row, 0); 
	}

	1;
}

sub blank_edit_pane {
	my $self = shift; $self->trace_in;

	my $frame = $self->gtk_filter_frame;
	my (@children) = $frame->children;
	foreach my $child ( @children ) {
		$frame->remove ($child);
		$child->destroy;
		$child = undef;
	}

	$self->selected_filter(undef);

	1;	
}

sub cb_select_filter {
	my $self = shift; $self->trace_in;
	
	if ( $self->selected_filter ) {
		$self->save_selected_filter;
	}
	
	my $row = $self->gtk_filter_list->selection;
	return 1 if not defined $row;

	my $filter_ids = $self->filter_ids;
	my $filter_id = $filter_ids->[$row];

	return if not defined $filter_id;

	$self->debug("row=$row filter_id=$filter_id");
	
	$self->build_edit_pane ( filter_id => $filter_id );

	1;
}

sub build_edit_pane {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($filter_id) = @par{'filter_id'};

	$self->blank_edit_pane;

	my $filter = JaM::Filter::IO->load (
		dbh => $self->dbh,
		filter_id => $filter_id
	);

	$self->dump($filter);

	$self->selected_filter($filter);

	my $vbox = Gtk::VBox->new(0, 5);
	$vbox->set_border_width(5);
	$vbox->show;
	$self->gtk_filter_frame->add($vbox);
	$self->gtk_filter_vbox ($vbox);

	# Name and action of the filter

	my $table = Gtk::Table->new ( 2, 2, 0 );
	$table->show;
	$table->set_row_spacings ( 2 );
	$table->set_col_spacings ( 2 );
	$table->set_border_width ( 0 );

	my $label = Gtk::Label->new ("Name");
	$label->show;
	my $entry = Gtk::Entry->new;
	$entry->show;
	$table->attach_defaults ($label, 0, 1, 0, 1);
	$table->attach_defaults ($entry, 1, 2, 0, 1);

	$label = Gtk::Label->new ("Action");
	$label->show;

	my $radio_vbox = Gtk::VBox->new (0, 0);
	$radio_vbox->show;
	my $radio1_hbox = Gtk::HBox->new (0, 0);
	$radio1_hbox->show;
	my $radio1 = Gtk::RadioButton->new ("Drop in folder");
	$radio1->show;
	my $radio2 = Gtk::RadioButton->new ("Delete", $radio1);
# currently we support only the drop operation
#	$radio2->show;
	my $folder_entry = Gtk::Entry->new;
	$folder_entry->show;
	$folder_entry->set_text("Click to select folder");
	$folder_entry->set_editable(0);

	$self->gtk_filter_folder ( $folder_entry );

	my $folder_menu = $self->gtk_folder_menu;
	
	$folder_entry->signal_connect('button_press_event', sub {
		my ($widget, $event) = @_;
		$folder_menu->popup (undef, undef, undef, $event->{button});
	});

	$radio1_hbox->pack_start($radio1, 0, 1, 0);
	$radio1_hbox->pack_start($folder_entry, 1, 1, 0);
	$radio_vbox->pack_start($radio1_hbox, 0, 1, 0);
	$radio_vbox->pack_start($radio2, 0, 1, 0);

	$table->attach_defaults ($label, 0, 1, 1, 2);
	$table->attach_defaults ($radio_vbox, 1, 2, 1, 2);

	my $sep = Gtk::HSeparator->new;
	$sep->show;

	my $op_hbox = Gtk::HBox->new (0, 5);
	$op_hbox->show;
	my $op_label = Gtk::Label->new("  Rules are combined with... ");
	$op_label->show;

	my $op_radio_and = Gtk::RadioButton->new ("and");
	$op_radio_and->show;
	my $op_radio_or = Gtk::RadioButton->new ("or", $op_radio_and);
	$op_radio_or->show;
	my $rule_add_button = Gtk::Button->new ("Add new rule");
	$rule_add_button->show;
	$rule_add_button->signal_connect ("clicked", sub { $self->add_new_rule } );
	
	$op_hbox->pack_start($rule_add_button, 0, 1, 0);
	$op_hbox->pack_start($op_label, 0, 1, 0);
	$op_hbox->pack_start($op_radio_and, 0, 1, 0);
	$op_hbox->pack_start($op_radio_or, 0, 1, 0);
	
	$vbox->pack_start($table, 0, 1, 0);
	$vbox->pack_start($sep, 0, 1, 0);
	$vbox->pack_start($op_hbox, 0, 1, 0);

	# fill values
	$entry->set_text ($filter->name);
	if ( $filter->action eq 'drop' ) {
		$radio1->set_active(1);
	} else {
		$radio2->set_active(1);
	}
	if ( $filter->operation eq 'and' ) {
		$op_radio_and->set_active(1);
	} else {
		$op_radio_or->set_active(1);
	}

	if ( $filter->folder_id ) {
		$folder_entry->set_text (
			JaM::Folder->by_id($filter->folder_id)->path
		);
	}

	# connect signals
	$entry->signal_connect ('changed', sub {
		$filter->name($entry->get_text);
		my $list = $self->gtk_filter_list;
		my $row = $list->selection;
		$list->set_text ($row, 0, $filter->name);
	});
	$radio1->signal_connect ('clicked', sub {
		$filter->action ('drop');
	});
	$radio2->signal_connect ('clicked', sub {
		$filter->action ('delete');
	});
	$op_radio_and->signal_connect ('clicked', sub {
		$filter->operation ('and');
	});
	$op_radio_or->signal_connect ('clicked', sub {
		$filter->operation ('or');
	});

	# now the rules
	my $rules = $filter->rules || [];
	foreach my $rule ( @{$rules} ) {
		$self->add_rule ( rule => $rule );
	}

	1;
}

sub drop_folder_chosen {
	my $self = shift; $self->trace_in;
	my ($folder_id) = @_;
	
	my $filter = $self->selected_filter;
	$filter->folder_id($folder_id);
	
	my $text = $self->gtk_filter_folder;
	$text->set_text ( JaM::Folder->by_id($folder_id)->path );
	
	1;
}

sub save_selected_filter {
	my $self = shift; $self->trace_in;
	return if not $self->selected_filter;
	$self->selected_filter->save;
	1;
}

sub add_new_filter {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($folder_object, $mail_object) = @par{'folder_object','mail_object'};
	
	my $name;
	$name = $folder_object->name if $folder_object;
	$name ||= "<New Filter>";

	my $filter = JaM::Filter::IO->create (
		dbh => $self->dbh,
		name => $name,
		type => $self->filter_type,
	);
	
	if ( $folder_object ) {
		$filter->folder_id ( $folder_object->folder_id );
		$filter->save;
	}
	
	my $list = $self->gtk_filter_list;
	$list->append($filter->name);
	push @{$self->filter_ids}, $filter->id;
	
	my $row = scalar(@{$self->filter_ids})-1;
	$list->select_row($row, 0);
	
	$list->moveto( $row, 0, 0.5, 0 ); 
	
	my $value;
	$value = $mail_object->head_get_decoded("to") if $mail_object;

	my $rule = $self->add_new_rule ( value => $value );

	1;
}

sub add_new_rule {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($value) = @par{'value'};

	my $rule = JaM::Filter::IO::Rule->create (
                field => 'tofromcc',
                operation => 'contains',
                value => $value,
	);
	
	$self->selected_filter->append_rule ( rule => $rule )->save;
	
	$self->add_rule ( rule => $rule );
	
	return $rule;
}

sub add_rule {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($rule) = @par{'rule'};

	my $hbox = Gtk::HBox->new (0, 5);
	$hbox->show;
	
	my $possible_fields = $rule->possible_fields;
	my $possible_ops    = $rule->possible_operations;

	my ($value, $name);
	my $i = 0;
	my $selected = 0;
	my $selected_value = $rule->field;
	my $fields_menu = Gtk::Menu->new;
	foreach $value ( sort keys %{$possible_fields} ) {
		$name = $possible_fields->{$value};
		my $item = Gtk::MenuItem->new ($name);
		$item->show;
		$item->signal_connect ("activate", sub { $rule->field($_[1]) }, $value);
		$fields_menu->append ($item);
		$selected = $i if $selected_value eq $value;
		++$i;
	}
	my $fields_options = Gtk::OptionMenu->new;
	$fields_options->set_menu($fields_menu);
	$fields_options->show;
	$fields_options->set_history ($selected);

	$hbox->pack_start($fields_options, 0, 0, 0);

	$i = 0;
	$selected = 0;
	$selected_value = $rule->operation;
	my $ops_menu = Gtk::Menu->new;
	foreach $value ( sort keys %{$possible_ops} ) {
		$name = $possible_ops->{$value};
		my $item = Gtk::MenuItem->new ($name);
		$item->show;
		$item->signal_connect ("activate", sub { $rule->operation($_[1]) }, $value);
		$ops_menu->append ($item);
		$selected = $i if $selected_value eq $value;
		++$i;
	}
	my $ops_options = Gtk::OptionMenu->new;
	$ops_options->set_menu($ops_menu);
	$ops_options->show;
	$ops_options->set_history ($selected);

	$hbox->pack_start($ops_options, 0, 0, 0);

	my $value_entry = Gtk::Entry->new;
	$value_entry->show;
	$value_entry->set_text ( $rule->value );
	$value_entry->signal_connect ('changed', sub { $rule->value($_[0]->get_text) } );

	$hbox->pack_start($value_entry, 1, 1, 0);

	my $del_button = Gtk::Button->new (" Del ");
	$del_button->show;
	$del_button->signal_connect ( "clicked", sub {
		$self->del_rule (
			filter => $self->selected_filter,
			rule => $rule,
			hbox => $hbox
		);
	} );
	$hbox->pack_start($del_button, 0, 0, 0);

	$self->gtk_filter_vbox->pack_start($hbox, 0, 0, 0);

	1;
}

sub del_rule {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($rule, $hbox, $filter) = @par{'rule','hbox','filter'};
	
	$self->gtk_filter_vbox->remove($hbox);
	$filter->remove_rule ( rule => $rule );
	
	1;
}

1;
