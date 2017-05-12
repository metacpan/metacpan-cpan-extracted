#TODO: Synopsis
#TODO: Configuration doc

=head1 NAME

Konstrukt::Plugin::usermanagement::basic::DBI - Konstrukt basic userdata. DBI Backend Driver

=head1 SYNOPSIS
	
	#TODO

=head1 DESCRIPTION

The DBI backend for the basic usermanagement.

=head1 CONFIGURATION

	#backend
	usermanagement/basic/backend/DBI/source  dbi:mysql:database:host
	usermanagement/basic/backend/DBI/user    username
	usermanagement/basic/backend/DBI/pass    password

If no database settings are set the defaults from L<Konstrukt::DBI/CONFIGURATION> will be used.

You have to create the database table C<user_basic> to use this plugin.
As this plugin depends on the log-plugin, you also have to create a table C<log>
(See L<Konstrukt::Plugin::log/CONFIGURATION>).

You may turn on the C<autoinstall> setting (see L<Konstrukt::Handler/CONFIGURATION>)
or use the C<KonstruktBackendInitialization.pl> script to accomplish this task.

=cut

package Konstrukt::Plugin::usermanagement::basic::DBI;

use strict;
use warnings;

use base 'Konstrukt::Plugin'; #inheritance

=head1 METHODS

=head2 init

Initialization of this class

=cut
sub init {
	my ($self) = @_;
	
	my $db_source = $Konstrukt::Settings->get('usermanagement/basic/backend/DBI/source');
	my $db_user   = $Konstrukt::Settings->get('usermanagement/basic/backend/DBI/user');
	my $db_pass   = $Konstrukt::Settings->get('usermanagement/basic/backend/DBI/pass');
	
	$self->{db_settings} = [$db_source, $db_user, $db_pass];
	
	return 1;
}
#= /init

=head2 install

Installs the backend (e.g. delete/create tables).

B<Parameters:>

none

=cut
sub install {
	my ($self) = @_;
	return $Konstrukt::Lib->plugin_dbi_install_helper($self->{db_settings});
}
# /install

=head2 check_login

Checks, if a email/password combination exists in the database

Returns the user id of this user in the database if the combination is valid,
0 otherwise.

B<Parameters>:

=over

=item * $email - The email address of the user

=item * $pass - The users password

=back

=cut
sub check_login {
	my ($self, $email, $pass) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	#quoting
	$email = $dbh->quote($email);
	$pass  = $dbh->quote($pass);
	
	my $query = "SELECT id FROM user_basic WHERE email = $email AND password = $pass";
	my @rv = $dbh->selectrow_array($query);
	return ($rv[0] || 0);
}
#= /check_login

=head2 register

Adds an user.

Returns the id of the added user if operation was successful, -1 if the user
already exists and undef otherwise.

B<Parameters>:

=over

=item * $email - The email address of the user

=back

=cut
sub register {
	my ($self, $email) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	#quoting
	$email = $dbh->quote($email);
	
	my ($query, $rv, @rv_id, @rv_ex, $uid);
	#check, whether this email address is already registered in the database
	$query = "SELECT 1 FROM user_basic WHERE email = $email";
	@rv_ex = $dbh->selectrow_array($query);
	if ($rv_ex[0]) {
		return -1; #email already exists!
	}
	
	#insert new user
	$dbh->do("INSERT INTO user_basic (email) VALUES ($email)") or return;
	
	#uid of added user
	return $dbh->last_insert_id(undef, undef, undef, undef) || undef;
}
#= /register

=head2 deregister

Removes an user

Returns the id of the added user if operation was successful, undef otherwise.

B<Parameters>:

=over

=item * $uid - The ID of the user to remove.

=back

=cut
sub deregister {
	my ($self, $uid) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	return $dbh->do("DELETE FROM user_basic WHERE id = $uid");
}
#= /deregister

=head2 get_data

Returns the user data as an hash reference, if the uid exists:
	{ email => 'a@b.c', pass  => '<hash>' }
Returns an empty hash reference if the user doesn't exist.

B<Parameters>:

=over

=item * $uid - The ID of the user

=back

=cut
sub get_data {
	my ($self, $uid) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return {};
	
	my $query = "SELECT email, password FROM user_basic WHERE id = $uid";
	my $rv = $dbh->selectall_arrayref($query, { Columns=>{} });
	if (@{$rv}) {
		return $rv->[0];
	} else {
		return {};
	}
}
#= /get_data

=head2 get_id_from_email

Returns the user id coresponding to a given email address, if the email address
exists, undef otherwise.

B<Parameters>:

=over

=item * $email - The email address of the user

=back

=cut
sub get_id_from_email {
	my ($self, $email) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	$email = $dbh->quote($email);
	
	my $query = "SELECT id FROM user_basic WHERE email = $email";
	return ($dbh->selectrow_array($query))[0] || undef;
}
#= /get_id_from_email

=head2 set_data

Sets the data specified in the passed hash in the database

B<Parameters>:

=over

=item * $uid - The ID of the user

=item * $data - Hashreference with the data that should be set:
	{ email => .., password => .. }

=back

=cut
sub set_data {
	my ($self, $uid, $data) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	my $set = join(', ', map { $_ . ' = ' . $dbh->quote($data->{$_}) } keys(%{$data}));
	
	if ($set) {
		return $dbh->do("UPDATE user_basic SET $set WHERE id = $uid");
	} else {
		return 1;
	}
}
#= /set_data

=head2 set_password

Sets the password for the specified user.

B<Parameters>:

=over

=item * $uid - The ID of the user

=item * $password - The new password

=back

=cut
sub set_password {
	return $_[0]->set_data($_[1], {password => $_[2]});
}
#= /set_password

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin::usermanagement::basic>, L<Konstrukt::Plugin::usermanagement>, L<Konstrukt>

=cut

__DATA__

-- 8< -- dbi: create -- >8 --

CREATE TABLE IF NOT EXISTS user_basic
(
  id        INT UNSIGNED NOT NULL AUTO_INCREMENT,
	
  #entry
  email     VARCHAR(255) NOT NULL,
  password  CHAR(64)     NOT NULL,

  PRIMARY KEY(id)
);