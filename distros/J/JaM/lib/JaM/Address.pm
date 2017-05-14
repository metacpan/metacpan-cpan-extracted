# $Id: Address.pm,v 1.2 2001/10/27 15:17:28 joern Exp $

package JaM::Address;

use strict;
use Data::Dumper;

sub dbh 		{ shift->{dbh}				}

sub id			{ my $s = shift; $s->{id}
		          = shift if @_; $s->{id}		}
sub email		{ my $s = shift; $s->{email}
		          = shift if @_; $s->{email}		}
sub name		{ my $s = shift; $s->{name}
		          = shift if @_; $s->{name}		}
sub address		{ my $s = shift; $s->{address}
		          = shift if @_; $s->{address}		}
sub phone		{ my $s = shift; $s->{phone}
		          = shift if @_; $s->{phone}		}
sub fax			{ my $s = shift; $s->{fax}
		          = shift if @_; $s->{fax}		}

sub load {
	my $type = shift;
	my %par = @_;
	my  ($dbh, $id) = @par{'dbh','id'};

	my ($exists, $email, $name, $address, $phone, $fax) =
	    	$dbh->selectrow_array (
		"select id, email, name, address, phone, fax
		 from   Address
		 where  id=?", {}, $id
	);

	if ( not $exists ) {
		confess ("address id $id not found");
		return undef;
	}
	
	my $self = {
		dbh    		=> $dbh,
		id		=> $id,
		email		=> $email,
		name		=> $name,
		address		=> $address,
		phone		=> $phone,
		fax		=> $fax,
	};
	
	return bless $self, $type;
}

sub create {
	my $type = shift;
	my %par = @_;
	my ($dbh) = @par{'dbh'};
	
	$dbh->do (
		"insert into Address values ()"
	);
	
	my $self = {
		id => $dbh->{'mysql_insertid'},
		dbh => $dbh,
	};
	
	return bless $self, $type;
}

sub save {
	my $self = shift;
	
	$self->dbh->do (
		"update Address set
			email = ?, name = ?,
			address = ?, phone = ?,
			fax = ?
		 where id = ?", {},
		$self->{email}, $self->{name},
		$self->{address}, $self->{phone},
		$self->{fax},
		$self->{id},
	);

	1;
}

sub lookup {
	my $type = shift;
	my %par = @_;
	my ($dbh, $string) = @par{'dbh','string'};
	
	my $ar = $dbh->selectcol_arrayref (
		"select id
		 from   Address
		 where  email like concat('%',?,'%') or
		 	name  like concat('%',?,'%')", {},
		$string, $string
	);
	
	return if @{$ar} != 1;
	
	return $type->load (
		dbh => $dbh,
		id  => $ar->[0]
	);
}

sub list {
	my $type = shift;
	my %par = @_;
	my ($dbh) = @par{'dbh'};
	
	my $href = $dbh->selectall_hashref (
		"select id, email
		 from   Address",
		 "email"
	);
	
	return $href;
}

sub delete {
	my $self = shift;
	
	$self->dbh->do (
		"delete from Address where id=?", {},
		$self->id
	);
	
	1;
}

1;
