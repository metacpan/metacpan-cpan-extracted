# $Id: Account.pm,v 1.4 2001/08/20 20:37:30 joern Exp $

package JaM::GUI::Account;

@ISA = qw ( JaM::GUI::Window );

use strict;
use JaM::GUI::Window;
use JaM::Account;

my $DEBUG = 1;

my %fields = (
	from_name	=> "Name",
	from_adress	=> "Email",
	pop3_server	=> "POP3 Server",
	pop3_login	=> "POP3 Username",
	pop3_password	=> "POP3 Password",
	pop3_delete	=> "Delete messages on server",
	smtp_server	=> "SMTP Server",
	default_account	=> "Default Account",
);

my @field_order = qw(
	from_name
	from_adress
	smtp_server
	pop3_server
	pop3_login
	pop3_password
	pop3_delete
);
#	default_account


sub gtk_entries		{ my $s = shift; $s->{gtk_entries}
		          = shift if @_; $s->{gtk_entries}	}

sub gtk_dialog		{ my $s = shift; $s->{gtk_dialog}
		          = shift if @_; $s->{gtk_dialog}	}

sub account		{ my $s = shift; $s->{account}
		          = shift if @_; $s->{account}		}

sub single_instance_window { 1 }

sub build {
	my $self = shift; $self->trace_in;

	my $dialog = Gtk::Dialog->new;
	$dialog->border_width(10);
	$dialog->set_position('center');
	$dialog->set_title ("Edit Account Information");
	$dialog->set_default_size (280, 260);

	my $table = Gtk::Table->new ( scalar(@field_order), 2, 0 );
	$table->show;

	my (%entries, $i);
	foreach my $field ( @field_order ) {
		my $label = Gtk::Label->new ($fields{$field});
		$label->show;
		$label->set_justify ('left');
		my $entry;
		if ( $field eq 'default_account' ) {
			$entry = Gtk::CheckButton->new;
		} elsif ( $field eq 'pop3_delete' ) {
			$entry = Gtk::CheckButton->new;
		} else {
			$entry = Gtk::Entry->new;
			$entry->set_visibility (0) if $field =~ /password/;
		}
		$entry->show;
		$table->attach_defaults ($label, 0, 1, $i, $i+1);
		$table->attach_defaults ($entry, 1, 2, $i, $i+1);
		$entries{$field} = $entry;
		++$i;
	}

	$table->set_row_spacings ( 2 );
	$table->set_col_spacings ( 2 );

	$dialog->vbox->pack_start ($table, 1, 1, 0);

	my $cancel = new Gtk::Button( "Cancel" );
	$dialog->action_area->pack_start( $cancel, 0, 1, 0 );
	$cancel->signal_connect( "clicked", sub { $dialog->destroy } );
	$cancel->show();

	my $ok = new Gtk::Button( "Ok" );
	$dialog->action_area->pack_start( $ok, 0, 1, 0 );
	$ok->signal_connect( "clicked", sub { $self->save } );
	$ok->show();

	$dialog->show;

	my $account = JaM::Account->load_default ( dbh => $self->dbh );

	$self->account($account);
	$self->gtk_entries ( \%entries );
	$self->gtk_dialog ( $dialog );
	$self->gtk_window_widget ( $dialog );

	$self->show;

	return $dialog;
}

sub show {
	my $self = shift;
	my $account = $self->account;
	return if not $account;
	
	my $value;
	my $entries = $self->gtk_entries;
	foreach my $field ( keys %{$entries} ) {
		$value = $account->$field();
		if ( $field eq 'pop3_delete' ) {
			$entries->{$field}->set_active($value);
		} else {
			$entries->{$field}->set_text($value);
		}
	}
	
	1;
}

sub save {
	my $self = shift;
	my $account = $self->account;
	
	if ( not $account ) {
		$account = JaM::Account->create ( dbh => $self->dbh );
		$self->account($account);
	}
	
	my $value;
	my $entries = $self->gtk_entries;
	foreach my $field ( keys %{$entries} ) {
		if ( $field eq 'pop3_delete' ) {
			$value = $entries->{$field}->get_active;
		} else {
			$value = $entries->{$field}->get_text;
		}
		$account->$field($value);
	}
	
	$account->save;

	$self->gtk_dialog->destroy;
	
	1;
}

1;
