#TODO: Synopsis
#TODO: Configuration doc

=head1 NAME

Konstrukt::Plugin::usermanagement::personal::DBI - Konstrukt personal userdata. DBI Backend Driver

=head1 SYNOPSIS
	
	#TODO

=head1 DESCRIPTION

The DBI backend for the personal userdata.

=head1 CONFIGURATION

	#backend
	usermanagement/personal/backend/DBI/source  dbi:mysql:database:host
	usermanagement/personal/backend/DBI/user    username
	usermanagement/personal/backend/DBI/pass    password

If no database settings are set the defaults from L<Konstrukt::DBI/CONFIGURATION> will be used.

You have to create the database table C<user_personal> to use this plugin.
You may turn on the C<install> setting (see L<Konstrukt::Handler/CONFIGURATION>)
or use the C<KonstruktBackendInitialization.pl> script to accomplish this task.

=cut

package Konstrukt::Plugin::usermanagement::personal::DBI;

use strict;
use warnings;

use base 'Konstrukt::Plugin'; #inheritance

=head1 METHODS

=head2 init

Initialization of this class

=cut
sub init {
	my ($self) = @_;
	
	my $db_source = $Konstrukt::Settings->get('usermanagement/personal/backend/DBI/source');
	my $db_user   = $Konstrukt::Settings->get('usermanagement/personal/backend/DBI/user');
	my $db_pass   = $Konstrukt::Settings->get('usermanagement/personal/backend/DBI/pass');
	
	$self->{db_settings} = [$db_source, $db_user, $db_pass];
	
	return 1;
}
#= /init

=head2 install

Installs the backend (e.g. create tables).

B<Parameters:>

none

=cut
sub install {
	my ($self) = @_;
	return $Konstrukt::Lib->plugin_dbi_install_helper($self->{db_settings});
}
# /install

=head2 add_user

Creates a row for a new user with the specified ID.

B<Parameters>:

=over

=item * $uid - The user id

=back

=cut
sub add_user {
	my ($self, $uid, $data) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	#delete user, if already exists
	$self->delete_user($uid);
	
	#create new entry
	return $dbh->do("INSERT INTO user_personal (user) VALUES ($uid)");
}
#= /add_user

=head2 delete_user

Deletes the personal data entry for a specified user.

B<Parameters>:

=over

=item * $uid - The user id

=back

=cut
sub delete_user {
	my ($self, $uid, $data) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	return $dbh->do("DELETE FROM user_personal WHERE user = $uid");
}
#= /delete_user

=head2 get_data

Returns the user data as an hash ref, if uid exists:
	{ firstname => .., lastname => .., nick => .., sex => ..,
	  birth_year => .., birth_month => .., birth_day,
	  email => .., jabber => .., icq => .., aim => .., msn => .., yahoo => .., homepage => ..
	}
Returns an empty hashref if the uid doesn't exist.

B<Parameters>:

=over

=item * $uid - The user id

=back

=cut
sub get_data {
	my ($self, $uid) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return {};
	
	my $query = "SELECT firstname, lastname, nick, sex, YEAR(birthday) AS birth_year, MONTH(birthday) AS birth_month, DAYOFMONTH(birthday) AS birth_day, email, jabber, icq, aim, msn, yahoo, homepage FROM user_personal WHERE user = $uid";
	my $rv = $dbh->selectall_arrayref($query, { Columns=>{} });
	if (@{$rv}) {
		map { $rv->[0]->{$_} = undef if defined $rv->[0]->{$_} and not length $rv->[0]->{$_}; } keys %{$rv->[0]};
		return $rv->[0];
	} else {
		return {};
	}
}
#= /get_data

=head2 set_data

Sets the data specified in the passed hash in the database.

B<Parameters>:

=over

=item * $uid - The user id

=item * $data - Hashreference with the data that should be set:
	{ firstname => .., nick => .., ... }

=back

=cut
sub set_data {
	my ($self, $uid, $data) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	my $birth = '';
	if ($data->{birth_year} and $data->{birth_month} and $data->{birth_day}) {
		$birth = $data->{birth_year}.'-'.$data->{birth_month}.'-'.$data->{birth_day};
		$data->{birthday} = $birth;
	}
	delete($data->{birth_year}); delete($data->{birth_month}); delete($data->{birth_day});
	
	my $set = join(', ', map { $_ . ' = ' . $dbh->quote(length($data->{$_}) ? $data->{$_} : undef) } keys(%{$data}));
	
	if ($set) {
		return $dbh->do("UPDATE user_personal SET $set WHERE user = $uid")
	} else {
		return 1;
	}
}
#= /set_data

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin::usermanagement::personal>, L<Konstrukt::Plugin::usermanagement>, L<Konstrukt>

=cut

__DATA__

-- 8< -- dbi: create -- >8 --

CREATE TABLE IF NOT EXISTS user_personal
(
  id        INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  
  #entry
  user      INT UNSIGNED     NOT NULL,
  firstname VARCHAR(255)     ,
  lastname  VARCHAR(255)     ,
  nick      VARCHAR(255)     ,
  email     VARCHAR(255)     ,
  birthday  DATE             ,
  sex       TINYINT UNSIGNED ,
  jabber    VARCHAR(255)     ,
  icq       VARCHAR(16)      ,
  aim       VARCHAR(255)     ,
  yahoo     VARCHAR(255)     ,
  msn       VARCHAR(255)     ,
  homepage  VARCHAR(255)     ,
  
  PRIMARY KEY(id),
  INDEX (user)
);