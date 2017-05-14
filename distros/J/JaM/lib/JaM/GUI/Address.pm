# $Id: Address.pm,v 1.2 2001/10/27 15:17:28 joern Exp $

package JaM::GUI::Address;

@ISA = qw ( JaM::GUI::Window );

use strict;
use JaM::GUI::Window;
use JaM::Address;
use File::Basename;

my %fields = (
	email		=> "Email Address",
	name		=> "Name",
	address		=> "Address",
	phone		=> "Phone Number",
	fax		=> "Fax Number",
);

my @field_order = qw(
	email
	name
	address
	phone
	fax
);

sub gtk_win		{ my $s = shift; $s->{gtk_win}
		          = shift if @_; $s->{gtk_win}			}
sub gtk_address_list	{ my $s = shift; $s->{gtk_address_list}
		          = shift if @_; $s->{gtk_address_list}		}
sub gtk_address_table	{ my $s = shift; $s->{gtk_address_table}
		          = shift if @_; $s->{gtk_address_table}	}
sub gtk_field_widgets	{ my $s = shift; $s->{gtk_field_widgets}
		          = shift if @_; $s->{gtk_field_widgets}	}	  
sub address_ids		{ my $s = shift; $s->{address_ids}
		          = shift if @_; $s->{address_ids}		}
sub selected_address	{ my $s = shift; $s->{selected_address}
		          = shift if @_; $s->{selected_address}		}
sub selected_address_row{ my $s = shift; $s->{selected_address_row}
		          = shift if @_; $s->{selected_address_row}	}

sub single_instance_window { 1 }

sub build {
	my $self = shift; $self->trace_in;

	my $win = Gtk::Window->new;
	$win->set_position ("center");
	$win->set_title ("Edit Address Book");
	$win->border_width(5);
	$win->set_default_size (450, 400);
	$win->realize;
	$win->show;

	my $vpane = new Gtk::VPaned();
	$vpane->show();
	$win->add ($vpane);
	$vpane->set_handle_size( 10 );
	$vpane->set_gutter_size( 15 );
	
	my $fr = Gtk::Frame->new ("Address Book Entries");
	$fr->show;

	my $hbox = Gtk::HBox->new(0,5);
	$hbox->show;
	$hbox->set_border_width(5);
	$fr->add($hbox);

	my $sw = new Gtk::ScrolledWindow( undef, undef );
	$sw->set_policy( 'never', 'automatic' );
	$sw->set_usize(250, 150);
	$sw->show();

	my $list = Gtk::CList->new_with_titles ( "Email Address" );
	$list->set_selection_mode( 'browse' );
	$list->set_shadow_type( 'none' );
	$list->set_usize (350, 200);
	$list->signal_connect( "select_row", sub { $self->cb_select_address(@_) } );
	$list->show();

	$sw->add ($list);

	$hbox->pack_start ($sw, 1, 1, 0);
	
	my $vbox = Gtk::VBox->new(0,5);
	$vbox->show;
	
	my $ok_button = Gtk::Button->new( "Ok" );
	$ok_button->show;
	$ok_button->signal_connect('clicked', sub {
		$self->save_selected_address;
		$win->destroy;
	});
	$vbox->pack_start($ok_button, 0, 1, 1);

	my $add_button = Gtk::Button->new( "Add" );
	$add_button->show;
	$add_button->signal_connect('clicked', sub {
		$self->save_selected_address;
		$self->add_address;
	});
	$vbox->pack_start($add_button, 0, 1, 1);

	my $del_button = Gtk::Button->new( "Delete" );
	$del_button->show;
	$del_button->signal_connect('clicked', sub {
		$self->delete_address;
	});
	$vbox->pack_start($del_button, 0, 1, 1);

	$hbox->pack_start ($vbox, 0, 0, 0);

	$vpane->add1 ($fr);
	
	my $address_frame = Gtk::Frame->new ("Edit selected address");
	$address_frame->show;
	
	$vpane->add2 ($address_frame);

	my $table = Gtk::Table->new ( scalar(@field_order), 2, 0 );

	my (%entries, $i);
	foreach my $field ( @field_order ) {
		my $label = Gtk::Label->new ($fields{$field});
		$label->show;
		$label->set_justify ('left');
		my $entry;
		if ( $field eq 'address' ) {
			$entry = Gtk::Text->new;
			$entry->set_usize(undef, 80);
			$entry->signal_connect ( "changed", sub {
				$self->selected_address->$field (
					$entry->get_chars (0, $entry->get_length)
				);
			});
		} else {
			$entry = Gtk::Entry->new;
			if ( $field eq 'email' ) {
				$entry->signal_connect ( "changed", sub {
					$self->selected_address->$field ($entry->get_text);
					$self->gtk_address_list->set_text(
						$self->selected_address_row, 0, $entry->get_text
					);
				});
			} else {
				$entry->signal_connect ( "changed", sub {
					$self->selected_address->$field ($entry->get_text);
				});
			}
		}
		$entry->set_editable(1);
		$entry->show;
		$table->attach_defaults ($label, 0, 1, $i, $i+1);
		$table->attach_defaults ($entry, 1, 2, $i, $i+1);
		$entries{$field} = $entry;
		++$i;
	}

	$table->set_row_spacings ( 2 );
	$table->set_col_spacings ( 2 );

	$address_frame->add ($table);

	$self->gtk_win ($win);
	$self->gtk_window_widget ($win);
	$self->gtk_address_list ($list);
	$self->gtk_address_table ($table);
	$self->gtk_field_widgets (\%entries);

	$self->show;

	1;
}

sub show {
	my $self = shift; $self->trace_in;

	my $list = $self->gtk_address_list;
	$list->freeze;
	$list->clear;
	
	$self->gtk_address_table->hide;
	
	my $href = JaM::Address->list ( dbh => $self->dbh );
	my @address_ids;
	$self->address_ids(\@address_ids);
	
	foreach my $email ( sort keys %{$href} ) {
		push @address_ids, $href->{$email}->{id};
		$list->append($email);
	}

	if ( @address_ids ) {
		$list->select_row(0,0);
	}
	
	$list->thaw;

	1;
}

sub cb_select_address {
	my $self = shift; $self->trace_in;

	my $row = $self->gtk_address_list->selection;
	return 1 if not defined $row;
	
	$self->save_selected_address;
	
	my $address = $self->selected_address(
		JaM::Address->load (
			dbh => $self->dbh,
			id  => $self->address_ids->[$row]
		)
	);
	$self->selected_address_row($row);

	my $field_widgets = $self->gtk_field_widgets;

	my ($field, $widget);
	while ( ($field, $widget) = each %{$field_widgets} ) {
		if ( $field eq 'address' ) {
			$widget->set_point(0);
			$widget->forward_delete($widget->get_length);
			$widget->insert(undef, undef, undef, $address->address);
			$widget->set_point(0);
		} else {
			$widget->set_text($address->$field);
		}
	}

	$self->gtk_address_table->show;

	1;
}

sub add_address {
	my $self = shift; $self->trace_in;
	
	my $address = JaM::Address->create (
		dbh => $self->dbh
	);
	
	push @{$self->address_ids}, $address->id;
	
	$address->email ("<new entry>");
	$address->save;

	$self->gtk_address_list->append ( $address->email );
	$self->gtk_address_list->select_row (@{$self->address_ids}-1, 0);
	
	1;
}

sub save_selected_address {
	my $self = shift; $self->trace_in;
	
	my $address;
	return 1 if not $address = $self->selected_address;
	
	$address->save;
	
	1;
}

sub delete_address {
	my $self = shift;
	
	my $row = $self->gtk_address_list->selection;
	return 1 if not defined $row;

	my $address_ids = $self->address_ids;
	my $address_id = $address_ids->[$row];

	my $address = $self->selected_address;
	$self->selected_address(undef);

	$self->gtk_address_list->remove ($row);
	splice @{$address_ids}, $row, 1;

	$address->delete;

	if ( @{$address_ids} == 0 ) {
		$self->gtk_address_table->hide;
	} else {
		$row = @{$address_ids}-1 if $row > @{$address_ids}-1;
		$self->gtk_address_list->select_row($row, 0); 
	}

	1;
	
}

1;
