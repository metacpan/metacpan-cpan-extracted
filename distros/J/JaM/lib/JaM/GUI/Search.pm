# $Id: Search.pm,v 1.2 2001/09/08 14:33:19 joern Exp $

package JaM::GUI::Search;

@ISA = qw ( JaM::GUI::Window JaM::GUI::Subjects JaM::GUI::IO_Filter );

use strict;
use JaM::GUI::Window;
use JaM::GUI::Subjects;
use JaM::GUI::IO_Filter;

sub multi_instance_window  { 1 }

sub search_rules	{ my $s = shift; $s->{search_rules}
		          = shift if @_; $s->{search_rules}	}
sub search_operation	{ my $s = shift; $s->{search_operation}
		          = shift if @_; $s->{search_operation}	}
sub search_folder_id	{ my $s = shift; $s->{search_folder_id}
		          = shift if @_; $s->{search_folder_id}	}
sub search_recursive	{ my $s = shift; $s->{search_recursive}
		          = shift if @_; $s->{search_recursive}	}

sub build {
	my $self = shift;
	
	# build subjects widget
	$self->SUPER::build (
		without_quick_search => 1,
		without_resize_tracking => 1,
	);
	
	my $win = Gtk::Window->new;
	$win->set_position ("center");
	$win->set_title ("Advanced Search");
	$win->border_width(3);
	$win->set_default_size (530, 500);
	$win->realize;
	$win->show;

	my $vpane = Gtk::VPaned->new();
	$vpane->show();
	$win->add ($vpane);
	$vpane->set_handle_size( 10 );
	$vpane->set_gutter_size( 15 );

	my $folder_hbox = Gtk::HBox->new (0,5);
	$folder_hbox->show;

	my $folder_menu = $self->comp('folders')->build_menu_of_folders (
		callback => sub {
			my ($folder_id) = @_;
			$self->folder_chosen($folder_id);
		}
	);

	my $folder_label = Gtk::Label->new ("Search in folder");
	$folder_label->show;
	
	my $folder_entry = Gtk::Entry->new;
	$folder_entry->show;
	$folder_entry->set_text("Click to select folder");
	$folder_entry->set_editable(0);
	$folder_entry->set_usize(200, 20);
	$folder_entry->signal_connect('button_press_event', sub {
		my ($widget, $event) = @_;
		$folder_menu->popup (undef, undef, undef, $event->{button});
	});

	my $folder_recursive = Gtk::CheckButton->new ("Include subfolders");
	$folder_recursive->show;
	$folder_recursive->set_active(0);
	$folder_recursive->signal_connect ('clicked', sub {
		$self->search_recursive ( $folder_recursive->get_active );
	});
	
	my $search_button = Gtk::Button->new (" Start Query ");
	$search_button->show;
	$search_button->signal_connect ("clicked", sub { $self->start_query } );

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

	$self->search_operation ('and');

	$op_radio_and->signal_connect ('clicked', sub {
		$self->search_operation ('and');
	});
	$op_radio_or->signal_connect ('clicked', sub {
		$self->search_operation ('or');
	});
	
	$folder_hbox->pack_start($folder_label, 0, 0, 0);
	$folder_hbox->pack_start($folder_entry, 0, 0, 0);
	$folder_hbox->pack_start($folder_recursive, 0, 0, 0);
	$folder_hbox->pack_start($search_button, 0, 0, 0);

	$op_hbox->pack_start($op_label, 0, 1, 0);
	$op_hbox->pack_start($op_radio_and, 0, 1, 0);
	$op_hbox->pack_start($op_radio_or, 0, 1, 0);
	$op_hbox->pack_start($rule_add_button, 0, 1, 0);

	my $filter_vbox = Gtk::VBox->new (0,5);
	$filter_vbox->show;

	my $filter_sw = Gtk::ScrolledWindow->new;
	$filter_sw->set_usize (undef, 100);
	$filter_sw->set_policy ('never','automatic');
	$filter_sw->show;
	$filter_sw->add_with_viewport($filter_vbox);

	my $hsep = Gtk::HSeparator->new;
	$hsep->show;

	my $top_vbox = Gtk::VBox->new(0,5);
	$top_vbox->show;
	$top_vbox->pack_start($folder_hbox, 0, 0, 0);
	$top_vbox->pack_start($hsep, 0, 0, 0);
	$top_vbox->pack_start($op_hbox, 0, 0, 0);
	$top_vbox->pack_start($filter_sw, 1, 1, 0);

	$vpane->add1 ($top_vbox);
	$vpane->add2 ($self->gtk_subjects);
	
	# destroy the handlers which track resizing of the widget
	$self->gtk_subjects->signal_handlers_destroy;
#	$self->gtk_subjects_list->signal_handlers_destroy;
	$self->gtk_subjects_list->set_column_width (
		1, $self->config('subjects_column_1') * 0.6
	);
	$self->gtk_subjects_list->signal_connect(
		'button_press_event', sub { $self->cb_click_subjects(@_) }
	);

	$self->gtk_filter_folder ( $folder_entry );
	$self->gtk_window_widget($win);
	$self->gtk_filter_vbox($filter_vbox);
	$self->gtk_folder_menu ($folder_menu);

	$self->search_rules ([]);
	$self->add_new_rule;

	$self->folder_chosen(1);

	return $win;
}

sub add_new_rule {
	my $self = shift;
	
	my $rule = JaM::Filter::Search::Rule->create (
		dbh => $self->dbh,
                field => 'tofromcc',
                operation => 'contains',
                value => "",
	);
	
	push @{$self->search_rules}, $rule;

	$self->add_rule ( rule => $rule );
	
	1;
}

sub del_rule {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($rule, $hbox, $filter) = @par{'rule','hbox','filter'};
	
	my $i=0;
	foreach my $r ( @{$self->search_rules} ) {
		last if ( $r eq $rule );
		++$i;
	}
	
	splice @{$self->search_rules}, $i, 1;
	
	$self->gtk_filter_vbox->remove($hbox);
	
	1;
}

sub folder_chosen {
	my $self = shift; $self->trace_in;
	my ($folder_id) = @_;
	
	my $text = $self->gtk_filter_folder;
	$text->set_text ( JaM::Folder->by_id($folder_id)->path );
	
	$self->search_folder_id ( $folder_id);

	1;
}

sub start_query {
	my $self = shift;

	return 1 if not @{$self->search_rules};

	my $operation = $self->search_operation;
	my $folder_id = $self->search_folder_id;
	my $recursive = $self->search_recursive;

	my @where;
	my @tables = ("Mail M");

	if ( $folder_id and $recursive) {
		if ( $folder_id != 1 ) {
			push @tables, "Folder F";
			push @where,
				"(F.path like '".
				 JaM::Folder->by_id($folder_id)->path.'/%'.
				 "' or M.folder_id=$folder_id) and M.folder_id = F.id ";
		}
	} elsif ( $folder_id ) {
		push @where, "M.folder_id=$folder_id";
	}
	
	my $code;
	my @op_where;
	my $with_entity;
	foreach my $rule ( @{$self->search_rules} ) {
		$code = $rule->code;
		push @op_where, "($code)";
		$with_entity = 1 if $code =~ /E\./;
	}
	
	if ( $with_entity ) {
		push @tables, "Entity E";
		push @where, "M.id = E.mail_id";
	}
	
	my $where = join (" and ", @where)." and " if @where;
	my $sql = "
		   select M.id, M.status, M.subject, M.sender,
		 	  UNIX_TIMESTAMP(M.date)
		   from   ".join (", ", @tables)."
		   where  $where
		   	  (".join (" $operation ", @op_where).")
		   order by 5 desc\n";

print STDERR "$sql\n";

	$self->show ( sql => $sql );
	
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
	return 1 if $self->selected_mail_id == $mail_id;

	if ( $self->selected_mail_id != $mail_id ) {
		$self->selected_mail_id ( $mail_id );
		$self->comp('mail')->show ( mail_id => $mail_id );
	}

	1;
}

package JaM::Filter::Search::Rule;

use vars qw (@ISA);
@ISA = qw ( JaM::Filter::IO::Rule );

my %operations = (
	"contains"  	     =>    "Contains",
	"contains!" 	     =>    "Does'n contain",
);

sub dbh { shift->{dbh}	}

sub create {
	my $type = shift;
	my %par = @_;
	my ($dbh) = @par{'dbh'};
	
	my $self = $type->SUPER::create (@_);

	$self->{dbh} = $dbh;
	
	$self->calculate_code;
	
	return bless $self, $type;
}

sub possible_operations {
	return \%operations;
}

sub calculate_code {
	my $self = shift;

	my $field     = $self->field;
	my $op        = $self->operation;
	my $value     = $self->value;

	# in construction phase our $dbh is not set
	return if not $self->dbh;

	$op = $op eq 'contains' ? "like" : "not like";
	$value = $self->dbh->quote('%'.$value.'%');

	my @fields;
	push @fields, "M.head_to" if $field =~ /to/;
	push @fields, "M.sender"  if $field =~ /from/;
	push @fields, "M.head_cc" if $field =~ /cc/;
	push @fields, "M.subject" if $field eq 'subject';
	push @fields, "E.data"    if $field eq 'body';

	my $code;
	foreach my $f ( @fields ) {
		$code .= "$f $op $value or ";
	}
	
	$code =~ s/or $//;
	
	return $self->code($code);	
}

1;
