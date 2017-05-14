# $Id: Account.pm,v 1.4 2001/08/15 19:48:46 joern Exp $

package JaM::Account;

use strict;
use Data::Dumper;

sub dbh 		{ shift->{dbh}				}

sub account_id		{ my $s = shift; $s->{account_id}
		          = shift if @_; $s->{account_id}	}
sub from_name		{ my $s = shift; $s->{from_name}
		          = shift if @_; $s->{from_name}	}
sub from_adress		{ my $s = shift; $s->{from_adress}
		          = shift if @_; $s->{from_adress}	}
sub pop3_server		{ my $s = shift; $s->{pop3_server}
		          = shift if @_; $s->{pop3_server}	}
sub pop3_login		{ my $s = shift; $s->{pop3_login}
		          = shift if @_; $s->{pop3_login}	}
sub pop3_password	{ my $s = shift; $s->{pop3_password}
		          = shift if @_; $s->{pop3_password}	}
sub pop3_delete		{ my $s = shift; $s->{pop3_delete}
		          = shift if @_; $s->{pop3_delete}	}
sub smtp_server		{ my $s = shift; $s->{smtp_server}
		          = shift if @_; $s->{smtp_server}	}
sub default_account	{ my $s = shift; $s->{default_account}
		          = shift if @_; $s->{default_account}	}

sub scramble {
	my $self = shift;
	my ($text) = @_;
	$text =~  tr/n-za-mN-ZA-M0-45-9/a-zA-Z5-90-4/;
	return $text;
}

sub load {
	my $type = shift;
	my %par = @_;
	my  ($dbh, $account_id) = @par{'dbh','account_id'};

	my ($id, $from_name, $from_adress, $pop3_server, $pop3_login,
	    $pop3_password, $pop3_delete, $smtp_server, $default_account) =
	    	$dbh->selectrow_array (
		"select id, from_name, from_adress, pop3_server,
			pop3_login, pop3_password, pop3_delete,
	    		smtp_server, default_account
		 from   Account
		 where  id=?", {}, $account_id
	);

	if ( not $id ) {
		confess ("account id $account_id not found");
		return undef;
	}
	
	my $self = {
		dbh    		=> $dbh,
		account_id	=> $account_id,
		from_name	=> $from_name,
		from_adress	=> $from_adress,
		pop3_server	=> $pop3_server,
		pop3_login	=> $pop3_login,
		pop3_password	=> $type->scramble($pop3_password),
		pop3_delete	=> $pop3_delete,
	    	smtp_server	=> $smtp_server,
		default_account	=> $default_account,
	};
	
	return bless $self, $type;
}

sub load_default {
	my $type = shift;
	my %par = @_;
	my ($dbh) = @par{'dbh'};
	
	
	my ($id) = $dbh->selectrow_array (
		"select id
		 from   Account
		 where  default_account=1"
	);
	
	return if not $id;

	return $type->load ( dbh => $dbh, account_id => $id );
}

sub create {
	my $type = shift;
	my %par = @_;
	my ($dbh) = @par{'dbh'};
	
	$dbh->do (
		"insert into Account values ()"
	);
	
	my $self = {
		id => $dbh->{'mysql_insertid'},
	};
	
	return bless $self, $type;
}

sub save {
	my $self = shift;
	
	$self->dbh->do (
		"update Account set
			from_name = ?, from_adress = ?,
			pop3_server = ?, pop3_login = ?,
			pop3_password = ?, pop3_delete = ?,
			smtp_server = ?, default_account = ?
		 where id = ?", {},
		$self->{from_name}, $self->{from_adress},
		$self->{pop3_server}, $self->{pop3_login},
		$self->scramble($self->{pop3_password}),
		$self->{pop3_delete}, $self->{smtp_server}, 
		$self->{default_account},
		$self->{account_id},
	);

	1;
}

1;
