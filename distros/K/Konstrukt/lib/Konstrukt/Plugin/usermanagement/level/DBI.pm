#TODO: Synopsis
#TODO: Configuration doc

=head1 NAME

Konstrukt::Plugin::usermanagement::level::DBI - Konstrukt level userdata. DBI Backend Driver

=head1 SYNOPSIS
	
	#TODO

=head1 DESCRIPTION

The DBI backend for the administration level.

=head1 CONFIGURATION

	#backend
	usermanagement/level/backend/DBI/source  dbi:mysql:database:host
	usermanagement/level/backend/DBI/user    username
	usermanagement/level/backend/DBI/pass    password

If no database settings are set the defaults from L<Konstrukt::DBI/CONFIGURATION> will be used.

You have to create the database table C<user_level> to use this plugin.
You may turn on the C<install> setting (see L<Konstrukt::Handler/CONFIGURATION>)
or use the C<KonstruktBackendInitialization.pl> script to accomplish this task.

=cut

package Konstrukt::Plugin::usermanagement::level::DBI;

use strict;
use warnings;

use base 'Konstrukt::Plugin'; #inheritance

=head1 METHODS

=head2 init

Initialization of this class

=cut
sub init {
	my ($self) = @_;
	
	my $db_source = $Konstrukt::Settings->get('usermanagement/level/backend/DBI/source');
	my $db_user   = $Konstrukt::Settings->get('usermanagement/level/backend/DBI/user');
	my $db_pass   = $Konstrukt::Settings->get('usermanagement/level/backend/DBI/pass');
	
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

=item * $uid - User id

=back

=cut
sub add_user {
	my ($self, $uid) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	#delete user, if already exists
	$self->delete_user($uid);
	
	#create new entry
	return $dbh->do("INSERT INTO user_level (user, level) VALUES ($uid, 1)");
}
#= /add_user

=head2 delete_user

Deletes the level entry for a specified user.

B<Parameters>:

=over

=item * $uid - User id

=back

=cut
sub delete_user {
	my ($self, $uid, $data) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	return $dbh->do("DELETE FROM user_level WHERE user = $uid");
}
#= /delete_user

=head2 get_data

Returns an hash reference, if the uid exists:
	{ level => <number> }
Returns an emty hash ref if the uid doesn't exist.

B<Parameters>:

=over

=item * $uid - User id

=back

=cut
sub get_data {
	my ($self, $uid) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return {};
	
	my $query = "SELECT level FROM user_level WHERE user = $uid";
	my $rv = $dbh->selectall_arrayref($query, { Columns=>{} });
	if (@{$rv}) {
		return $rv->[0];
	} else {
		return {};
	}
}
#= /get_data

=head2 set_data

Sets the data specified in the passed hash in the database.
	{ level => <number> }
Returns an emty hash ref if the uid doesn't exist.

B<Parameters>:

=over

=item * $uid - User id

=item * $data - Hash reference with the data that should be set:
	{ level => <number> }

=back

=cut
sub set_data {
	my ($self, $uid, $data) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	my $set = join(', ', map { $_ . ' = ' . $dbh->quote($data->{$_}) } keys(%{$data}));
	
	if ($set) {
		return $dbh->do("UPDATE user_level SET $set WHERE user = $uid");
	} else {
		return 1;
	}
}
#= /set_data

=head2 set_level

Sets the user level for the specified uid.

B<Parameters>:

=over

=item * $uid - User id

=item * $level - The user level (integer).

=back

=cut
sub set_level {
	return $_[0]->set_data($_[1], {level => $_[2]});
}
#= /ser_level

=head2 get_all

Returns all registered users(/admins) as an array ref of hash references:
	[ { user => <ID>, level => 123 },
	  { user => <ID>, level => 456 }, ... ]

Should be ordered by user level.

=cut
sub get_all {
	my ($self) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return [];
	
	my $query = "SELECT user, level FROM user_level ORDER BY level DESC";
	return $dbh->selectall_arrayref($query, { Columns=>{} });
}
#= /get_all

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin::usermanagement::level>, L<Konstrukt::Plugin::usermanagement>, L<Konstrukt>

=cut

__DATA__

-- 8< -- dbi: create -- >8 --

CREATE TABLE IF NOT EXISTS user_level
(
  id        INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  
  #entry
  user      INT UNSIGNED     NOT NULL,
  level     INT UNSIGNED     NOT NULL,
  
  PRIMARY KEY(id),
  INDEX (user)
);