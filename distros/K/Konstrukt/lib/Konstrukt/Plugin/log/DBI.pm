=head1 NAME

Konstrukt::Plugin::log::DBI - Konstrukt logging. DBI backend

=head1 SYNOPSIS
	
	#nothing special here

=head1 DESCRIPTION

Konstrukt logging. DBI backend

=head1 CONFIGURATION

	#backend
	log/DBI/source       dbi:driver:db:server
	log/DBI/user         user
	log/DBI/pass         pass

If no database settings are set the defaults from L<Konstrukt::DBI/CONFIGURATION> will be used.

Note that you have to create a table called C<log>.
You may turn on the C<install> setting (see L<Konstrukt::Handler/CONFIGURATION>)
or use the C<KonstruktBackendInitialization.pl> script to accomplish this task.

=cut

package Konstrukt::Plugin::log::DBI;

use strict;
use warnings;

use base 'Konstrukt::Plugin'; #inheritance

=head1 METHODS

=head2 init

Initialization of this class

=cut
sub init {
	my ($self) = @_;
	
	my $db_source = $Konstrukt::Settings->get('log/backend/DBI/source');
	my $db_user   = $Konstrukt::Settings->get('log/backend/DBI/user');
	my $db_pass   = $Konstrukt::Settings->get('log/backend/DBI/pass');
	
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

=head2 put

Adds a new log entry.

B<Parameters>:

=over

=item * $type - The type/source of this entry

=item * $description - A human readable description

=item * $host - The host name/address

=item * ($key1 .. $key5) - Optional additional keys

=back

=cut
sub put {
	my ($self, $type, $description, $host, $key1, $key2, $key3, $key4, $key5) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	#quote all parameters
	map { $_ = $dbh->quote($_) } ($type, $description, $host, $key1, $key2, $key3, $key4, $key5);
	
	#insert log entry
	my $query = "INSERT INTO log (host, type, description, key1, key2, key3, key4, key5) VALUES ($host, $type, $description, $key1, $key2, $key3, $key4, $key5)";
	return $dbh->do($query);
}
#= /put

=head2 get

Returns the requested log entries as an array reference of hash references.

B<Parameters>:

=over

=item * $type - The type/source of this entry

=item * $orderby - The list will be ordered by this expression,
which will be passed as-is to the SQL-query.

=item * $limit - Max. number of returned entries

=back

=cut
sub get {
	my ($self, $type, $orderby, $limit) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	#quoting
	$type = $dbh->quote($type) if defined $type;
	
	my $query = "SELECT id, host, type, description, key1, key2, key3, key4, key5, YEAR(timestamp) AS year, MONTH(timestamp) AS month, DAYOFMONTH(timestamp) AS day, HOUR(timestamp) AS hour, MINUTE(timestamp) AS minute FROM log"
		. (defined $type    ? " WHERE type = $type" : '')
		. (defined $orderby ? " ORDER BY $orderby" : '')
		. (defined $limit   ? " LIMIT $limit" : '');		
	my $rv = $dbh->selectall_arrayref($query, { Columns=>{} });
	return (defined $rv ? $rv : []);
}
#= /get

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin::log>, L<Konstrukt>

=cut

__DATA__

-- 8< -- dbi: create -- >8 --

CREATE TABLE IF NOT EXISTS log
(
  id          INT UNSIGNED  NOT NULL AUTO_INCREMENT,
	
  #entry
  host        VARCHAR(255)  NOT NULL,
  type        VARCHAR(64)   NOT NULL,
  description TEXT          NOT NULL,
  key1        VARCHAR(255)  ,
  key2        VARCHAR(255)  ,
  key3        VARCHAR(255)  ,
  key4        VARCHAR(255)  ,
  key5        VARCHAR(255)  ,
  timestamp   TIMESTAMP(14) NOT NULL,

  PRIMARY KEY(id)
);