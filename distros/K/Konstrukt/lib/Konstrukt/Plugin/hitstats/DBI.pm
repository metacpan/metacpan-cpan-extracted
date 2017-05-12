#TODO: Synopsis

=head1 NAME

Konstrukt::Plugin::hitstats::DBI - Konstrukt page hit logging. DBI backend

=head1 SYNOPSIS
	
	#TODO

=head1 DESCRIPTION

Konstrukt page hit logging. DBI backend

=head1 CONFIGURATION

Note that you have to create a table called C<hitstats>.
You may turn on the C<install> setting (see L<Konstrukt::Handler/CONFIGURATION>)
or use the C<KonstruktBackendInitialization.pl> script to accomplish this task.

You have to define those settings to use this backend:

	#backend
	hitstats/backend                  DBI
	hitstats/backend/DBI/source       dbi:mysql:database:host
	hitstats/backend/DBI/user         user
	hitstats/backend/DBI/pass         pass

If no database settings are set the defaults from L<Konstrukt::DBI/CONFIGURATION> will be used.

=cut

package Konstrukt::Plugin::hitstats::DBI;

use strict;
use warnings;

use base 'Konstrukt::Plugin'; #inheritance

=head1 METHODS

=head2 init

Initialization of this class

B<Parameters>: none

=cut
sub init {
	my ($self) = @_;
	
	my $db_source = $Konstrukt::Settings->get('hitstats/backend/DBI/source');
	my $db_user   = $Konstrukt::Settings->get('hitstats/backend/DBI/user');
	my $db_pass   = $Konstrukt::Settings->get('hitstats/backend/DBI/pass');
	
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

=head2 hit

Adds a new hitstat entry.

B<Parameters>:

=over

=item * $title - The title of the page to log

=item * $aggregate - The range over which the hits should be aggregated. May be all, year, month and day.

=back

=cut
sub hit {
	my ($self, $title, $aggregate) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	#get current date
	my ($day, $month, $year) = (localtime(time))[3 .. 5];
	$year += 1900;
	$month++;
	
	#adjust date to aggregate the hits
	if ($aggregate eq 'all') {
		($year, $month, $day) = (1, 1, 1);
	} elsif ($aggregate eq 'year') {
		($month, $day) = (1, 1);
	} elsif ($aggregate eq 'month') {
		$day = 1;
	}
	
	my $date = sprintf "%04d-%02d-%02d", $year, $month, $day;
	
	#quote
	$title = $dbh->quote($title);
	$date  = $dbh->quote($date);
	
	#insert hit entry if not exists
	$dbh->do("INSERT IGNORE INTO hitstats (title, date, count) VALUES ($title, $date, 0)") or return;
	#update hit entry
	$dbh->do("UPDATE hitstats SET count = count + 1 WHERE title = $title AND date = $date") or return;
	
	return 1;
}
#= /hit

=head2 get

Returns the statistics as an array reference of hash references:
	[
		{ title => <value>, date => <value>, count => <value> },
		...
	]

B<Parameters>:

=over

=item * $aggregate - The range over which the hits should be aggregated. May be all, year, month and day.

=item * $limit - Max. number of returned entries.

=back

=cut
sub get {
	my ($self, $aggregate, $limit) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	#generate GROUP BY statement
	my $group_by = "title";
	if ($aggregate eq 'year') {
		$group_by .= ", YEAR(date) DESC";
	} elsif ($aggregate eq 'month') {
		$group_by .= ", YEAR(date) DESC, MONTH(date) DESC";
	} elsif ($aggregate eq 'day') {
		$group_by .= ", YEAR(date) DESC, MONTH(date) DESC, DAYOFMONTH(date) DESC";
	}
	
	$limit += 0; #force number
	my $query = "SELECT title, date, SUM(count) as count FROM hitstats GROUP BY $group_by ORDER BY date DESC, count DESC" . ($limit > 0 ? " LIMIT $limit" : "");
	my $rv = $dbh->selectall_arrayref($query, { Columns=>{} });
	return (@{$rv} ? $rv : []);
}
#= /get

=head2 get_count

Returns the overall hit count for a given page

B<Parameters>:

=over

=item * $title - The title of the page

=back

=cut
sub get_count {
	my ($self, $title) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;

	my $query = "SELECT SUM(count) as count FROM hitstats WHERE title = " . $dbh->quote($title);
	my ($count) = $dbh->selectrow_array($query);
	$count = 0 unless defined $count; #no hits for this page if no row exists
	
	return $count;
}
#= /get_count

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin::hitstats>, L<Konstrukt>

=cut

__DATA__

-- 8< -- dbi: create -- >8 --

CREATE TABLE IF NOT EXISTS hitstats
(
  #entry
  title       VARCHAR(255)  NOT NULL,
  count       INT UNSIGNED  NOT NULL,
  date        DATE          NOT NULL,

  PRIMARY KEY(title, date),
  INDEX(count), INDEX(date)
);