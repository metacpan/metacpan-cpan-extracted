# $Id: View.pm,v 1.2 2001/08/10 20:12:26 joern Exp $

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
sub smtp_server		{ my $s = shift; $s->{smtp_server}
		          = shift if @_; $s->{smtp_server}	}
sub default_account	{ my $s = shift; $s->{default_account}
		          = shift if @_; $s->{default_account}	}

sub load {
	my $type = shift;
	my %par = @_;
	my  ($dbh, $account_id) = @par{'dbh','account_id'};

	my ($id, $from_name, $from_adress, $pop3_server, $pop3_login,
	    $pop3_password, $smtp_server, $default_account) =
	    	$dbh->selectrow_array (
		"select id, from_name, from_adress, pop3_server,
			pop3_login, pop3_password,
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
		pop3_password	=> $pop3_password,
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
	
	if ( not $id ) {
		warn ("no default account defined");
		return;
	}

	return $type->load ( dbh => $dbh, account_id => $id );
}

1;
