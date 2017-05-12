#TODO: Synopsis
#TODO: Configuration doc

=head1 NAME

Konstrukt::Plugin::guestbook::DBI - Konstrukt guestbook. Backend Driver for the Perl-DBI.

=head1 SYNOPSIS
	
	#TODO

=head1 DESCRIPTION

Konstrukt guestbook DBI backend driver.

=head1 CONFIGURATION

Note that you have to create the table C<guest>.
You may turn on the C<install> setting (see L<Konstrukt::Handler/CONFIGURATION>)
or use the C<KonstruktBackendInitialization.pl> script to accomplish this task.

You have to define those settings to use this backend:

	#backend
	guestbook/backend/DBI/source       dbi:mysql:database:host
	guestbook/backend/DBI/user         user
	guestbook/backend/DBI/pass         pass

If no database settings are set the defaults from L<Konstrukt::DBI/CONFIGURATION> will be used.

=cut

package Konstrukt::Plugin::guestbook::DBI;

use strict;
use warnings;

use base 'Konstrukt::Plugin'; #inheritance

=head1 METHODS

=head2 init

Initialization of this class

=cut
sub init {
	my ($self) = @_;
	
	my $db_source = $Konstrukt::Settings->get('guestbook/backend/DBI/source');
	my $db_user   = $Konstrukt::Settings->get('guestbook/backend/DBI/user');
	my $db_pass   = $Konstrukt::Settings->get('guestbook/backend/DBI/pass');
	
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

=head2 get_entries_count

Returns the count of the entries in the guestbook.

=cut
sub get_entries_count {
	my ($self) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return -1;
	return $dbh->selectrow_array('SELECT COUNT(id) FROM guest');
}
#= /get_entries_count

=head2 get_entries

Returns the requested entries in the database as an arrayreference of hashreferences:

	[
		{id => <value>, title => <value>, ...},
		{id => <value>, title => <value>, ...},
		...
	]

B<Parameters>: 

=over

=item * $start - The first entry to display. starts with 0

=item * $count - The number of entries to display

=back

=cut
sub get_entries {
	my ($self, $start, $count) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return [];
	
	my $query = "SELECT id, name, email, icq, aim, yahoo, jabber, msn, homepage, text, host, YEAR(timestamp) AS year, MONTH(timestamp) AS month, DAYOFMONTH(timestamp) AS day, HOUR(timestamp) AS hour, MINUTE(timestamp) AS minute FROM guest ORDER BY timestamp DESC LIMIT $start, $count";
	return $dbh->selectall_arrayref($query, { Columns=>{} }) || [];
}
#= /get_entries

=head2 get_entry

Returns one single entry specified by it's ID as an hashreference:
	
	{id => <value>, title => <value>, ...}

B<Parameters>: 

=over

=item * $id - The entry's id

=back

=cut
sub get_entry {
	my ($self, $id) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return {};
	
	my $query = "SELECT id, name, email, icq, aim, yahoo, jabber, msn, homepage, text, host, YEAR(timestamp) AS year, MONTH(timestamp) AS month, DAYOFMONTH(timestamp) AS day, HOUR(timestamp) AS hour, MINUTE(timestamp) AS minute FROM guest WHERE id = $id";
	my $rv = $dbh->selectall_arrayref($query, { Columns=>{} });
	return (@{$rv} ? $rv->[0] : {});
}
#= /get_entry

=head2 add_entry

Creates a guestbook entry.
	
B<Parameters>: 

=over

=item * $name - Author

=item * $email - Author's e-mail address

=item * $icq - ICQ IM account

=item * $aim - AIM account

=item * $yahoo - Yahoo! IM account

=item * $jabber - Jabber IM account

=item * $msn - MSN IM account

=item * $homepage - The authors website

=item * $text - The entry's text

=item * $host - Client Computer's IP/Hostname

=back

=cut
sub add_entry {
	my ($self, $name, $email, $icq, $aim, $yahoo, $jabber, $msn, $homepage, $text, $host) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return 0;
	
	#quote all parameters
	map { $_ = $dbh->quote($_) } ($name, $email, $icq, $aim, $yahoo, $jabber, $msn, $homepage, $text, $host);
	
	my $query = "INSERT INTO guest (name, email, icq, aim, yahoo, jabber, msn, homepage, text, host) VALUES ($name, $email, $icq, $aim, $yahoo, $jabber, $msn, $homepage, $text, $host)";
	return $dbh->do($query);
}
#= /add_entry

=head2 delete_entry

Removes a guestbook entry

B<Parameters>: 

=over

=item * $id - The entry's id

=back

=cut
sub delete_entry {
	my ($self, $id) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return 0;
	$id = $dbh->quote($id);
	return $dbh->do("DELETE FROM guest WHERE id = $id");
}
#= /delete_entry

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin::guestbook>, L<Konstrukt>

=cut

__DATA__

-- 8< -- dbi: create -- >8 --

CREATE TABLE IF NOT EXISTS guest
(
  id        INT UNSIGNED  NOT NULL AUTO_INCREMENT,
	
  #entry
  timestamp TIMESTAMP(14) NOT NULL,
  name      VARCHAR(255)  NOT NULL,
  email     VARCHAR(255)  NOT NULL,
  icq       VARCHAR(16)   NOT NULL,
  aim       VARCHAR(32)   NOT NULL,
  yahoo     VARCHAR(32)   NOT NULL,
  jabber    VARCHAR(64)   NOT NULL,
  msn       VARCHAR(32)   NOT NULL,
  homepage  VARCHAR(255)  NOT NULL,
  host      VARCHAR(255)  NOT NULL,
  text      TEXT          NOT NULL,
  
  PRIMARY KEY(id)
);