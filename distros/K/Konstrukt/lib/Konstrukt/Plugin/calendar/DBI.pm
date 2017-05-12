#TODO: Use extra columns to store the recurrence of the entries instead of using
#      0-fields in the date
#TODO: Synopsis
#TODO: Configuration doc

=head1 NAME

Konstrukt::Plugin::calendar::DBI - Konstrukt calendar. Backend Driver for the Perl-DBI.

=head1 SYNOPSIS
	
	#TODO

=head1 DESCRIPTION

Konstrukt calendar DBI backend driver.

=head1 CONFIGURATION

	#backend
	calendar/backend/DBI/source       dbi:mysql:database:host
	calendar/backend/DBI/user         user
	calendar/backend/DBI/pass         pass

If no database settings are set the defaults from L<Konstrukt::DBI/CONFIGURATION> will be used.

Note that you have to create the table C<calendar_event>.
You may turn on the C<install> setting (see L<Konstrukt::Handler/CONFIGURATION>)
or use the C<KonstruktBackendInitialization.pl> script to accomplish this task.

=cut

package Konstrukt::Plugin::calendar::DBI;

use strict;
use warnings;

use base 'Konstrukt::Plugin'; #inheritance

=head1 METHODS

=head2 init

Initialization of this class

=cut
sub init {
	my ($self) = @_;
	
	my $db_source = $Konstrukt::Settings->get('calendar/backend/DBI/source');
	my $db_user   = $Konstrukt::Settings->get('calendar/backend/DBI/user');
	my $db_pass   = $Konstrukt::Settings->get('calendar/backend/DBI/pass');
	
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

=head2 add_entry

Adds a new bookmark.

B<Parameters>:

=over

=item * $year, $month, $day - The date of this entry

=item * $start_hour, $start_minute - The start time

=item * $end_hour, $end_minute - The ending time

=item * $description - What's this event about?

=item * $private - Is this entry only visible to the author?

=item * $author - The entry's author

=back

=cut
sub add_entry {
	my ($self, $year, $month, $day, $start_hour, $start_minute, $end_hour, $end_minute, $description, $private, $author) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	#quoting
	$description = $dbh->quote($description || '');
	$private ||= 0;
	
	#insert event
	my $query = "INSERT INTO calendar_event (date, start, end, description, private, author) VALUES ('$year-$month-$day', '$start_hour:$start_minute', '$end_hour:$end_minute', $description, $private, $author)";
	return $dbh->do($query);
}
#= /add_entry

=head2 get_entry

Returns the requested event as an hash reference with the keys id, year, month,
day, start_hour, start_minute, end_hour, end_minute, description, private, author.

B<Parameters>:

=over

=item * $id - The id of the event

=back

=cut
sub get_entry {
	my ($self, $id) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	my $query = "SELECT id, description, author, private, YEAR(date) AS year, MONTH(date) AS month, DAYOFMONTH(date) AS day, HOUR(start) AS start_hour, MINUTE(start) AS start_minute, HOUR(end) AS end_hour, MINUTE(end) AS end_minute FROM calendar_event WHERE id = $id";
	my $rv = $dbh->selectall_arrayref($query, { Columns=>{} });
	if (@{$rv}) {
		return $rv->[0];
	} else {
		return {};
	}
}
#= /get_entry

=head2 get_month

Returns the events within a specified month as an array reference of hash references:

	[ { id => .., year => .., month => .., day => ..,
	    start_hour => .., start_minute => .., end_hour => .., end_minute => ..,
	    description => .., author => .., private => .. },
	  { id => .., ... },
	  ...
	]

B<Parameters>:

=over

=item * $year, $month - The requested month

=back

=cut
sub get_month {
	my ($self, $year, $month) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return [];
	
	my $query = "SELECT id, description, author, private, YEAR(date) AS year, MONTH(date) AS month, DAYOFMONTH(date) AS day, HOUR(start) AS start_hour, MINUTE(start) AS start_minute, HOUR(end) AS end_hour, MINUTE(end) AS end_minute FROM calendar_event WHERE MONTH(date) IN ($month, 0) AND YEAR(date) IN ($year, 0)";
	return $dbh->selectall_arrayref($query, { Columns=>{} }) || [];
}
#= /get_month

=head2 get_day

Returns the events within a specified day as an Array reference of hash references:

	[ { id => .., year => .., month => .., day => ..,
	    start_hour => .., start_minute => .., end_hour => .., end_minute => ..,
	    description => .., author => .., private => .. },
	  { id => .., ... },
	  ...
	]

B<Parameters>:

=over

=item * $year, $month, $day - The requested day

=back

=cut
sub get_day {
	my ($self, $year, $month, $day) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return [];
	
	my $query = "SELECT id, description, author, private, YEAR(date) AS year, MONTH(date) AS month, DAYOFMONTH(date) AS day, HOUR(start) AS start_hour, MINUTE(start) AS start_minute, HOUR(end) AS end_hour, MINUTE(end) AS end_minute FROM calendar_event WHERE MONTH(date) IN ($month, 0) AND YEAR(date) IN ($year, 0) AND DAYOFMONTH(date) IN ($day, 0) ORDER BY start ASC";
	return $dbh->selectall_arrayref($query, { Columns=>{} }) || [];
}
#= /get_day

=head2 get_range

Returns the events within a specified date range as an Array reference of hash references:

	[ { id => .., year => .., month => .., day => ..,
	    start_hour => .., start_minute => .., end_hour => .., end_minute => ..,
	    description => .., author => .., private => .. },
	  { id => .., ... },
	  ...
	]

B<Parameters>:

=over

=item * $start_year, $start_month, $start_day - Start date

=item * $end_year  , $end_month  , $end_day   - End date

=back

=cut
sub get_range {
	my ($self, $start_year, $start_month, $start_day, $end_year, $end_month, $end_day) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return [];
	
	my $query = <<QUERY;
SELECT
  id, description, author, private, YEAR(date) AS year, MONTH(date) AS month, DAYOFMONTH(date) AS day, HOUR(start) AS start_hour, MINUTE(start) AS start_minute, HOUR(end) AS end_hour, MINUTE(end) AS end_minute
 FROM
  calendar_event
 WHERE
  #select every event in the year-range. explicitly allow events, that occur every year.
  ((YEAR(date) BETWEEN $start_year AND $end_year) OR YEAR(date) = 0) AND
  #cut off months not in range. explicitly allow events, that occur every month.
  ((NOT
   (
    (YEAR(date) = $start_year AND MONTH(date) < $start_month) OR (YEAR(date) = $end_year AND MONTH(date) > $end_month) OR
    (YEAR(date) = 0 AND (
     ($start_year = $end_year AND (MONTH(date) < $start_month OR MONTH(date) > $end_month)) OR
     ($start_year + 1 = $end_year AND MONTH(date) BETWEEN $end_month+1 AND $start_month-1)
    ))
   )
  ) OR MONTH(date) = 0) AND
  #cut off days not in range. explicitly allow events, that occur every day.
  ((NOT
   (
    #year and month defined, no wildcard
    (YEAR(date) = $start_year AND MONTH(date) = $start_month AND DAYOFMONTH(date) < $start_day) OR (YEAR(date) = $end_year AND MONTH(date) = $end_month AND DAYOFMONTH(date) > $end_day) OR
    #special case: year = 0 (wildcard) but month defined. range smaller than one year. cut days in start- and endmonth
    (YEAR(date) = 0 AND MONTH(date) > 0 AND ($start_year = $end_year OR ($start_year + 1 = $end_year AND $start_month > $end_month)) AND ((MONTH(date) = $start_month AND DAYOFMONTH(date) < $start_day) OR (MONTH(date) = $end_month AND DAYOFMONTH(date) > $end_day))) OR
    #special case: month = 0 (wildcard)
    (MONTH(date) = 0 AND (
     #range only within one month
     ($start_year = $end_year AND $start_month = $end_month AND (DAYOFMONTH(date) < $start_day OR DAYOFMONTH(date) > $end_day)) OR
     #exctly 2 months. within one year or at the turn of the year, when year = 0 (wildcard)
     ((($start_year = $end_year AND $start_month + 1 = $end_month) OR ($start_year + 1 = $end_year AND YEAR(date) = 0 AND $start_month = 12 AND $end_month = 1)) AND DAYOFMONTH(date) BETWEEN $end_day + 1 AND $start_day - 1) OR
     #range over 2 years, but at most one full month per year, when year > 0. so either the start- or endmonth is directly at the year turn
     ($start_year + 1 = $end_year AND YEAR(date) > 0 AND (($start_year = YEAR(date) AND $start_month = 12 AND DAYOFMONTH(date) < $start_day) OR ($end_year = YEAR(date) AND $end_month = 1 AND DAYOFMONTH(date) > $end_day)))
    ))
   )
  ) OR DAYOFMONTH(date) = 0)
 ORDER BY
  date, start ASC
QUERY

	#warn $query;
	return $dbh->selectall_arrayref($query, { Columns=>{} });
}
#= /get_range

=head2 get_all

Returns all events as an Array reference of hash references:

	[ { id => .., year => .., month => .., day => ..,
	    start_hour => .., start_minute => .., end_hour => .., end_minute => ..,
	    description => .., author => .., private => .. },
	  { id => .., ... },
	  ...
	]

=cut
sub get_all {
	my ($self) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return [];
	
	my $query = "SELECT id, description, author, private, YEAR(date) AS year, MONTH(date) AS month, DAYOFMONTH(date) AS day, HOUR(start) AS start_hour, MINUTE(start) AS start_minute, HOUR(end) AS end_hour, MINUTE(end) AS end_minute FROM calendar_event ORDER BY date ASC";
	return $dbh->selectall_arrayref($query, { Columns=>{} });
}
#= /get_all

=head2 update_entry

Updates an existing event.

B<Parameters>:

=over

=item * $id - The id of the event, which should be updated

=item * $year, $month, $day - The date of this entry

=item * $start_hour, $start_minute - The start time

=item * $end_hour, $end_minute - The ending time

=item * $description - What's this event about?

=item * $private - Is this entry only visible to the author?

=back

=cut
sub update_entry {
	my ($self, $id, $year, $month, $day, $start_hour, $start_minute, $end_hour, $end_minute, $description, $private) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	#quoting
	$description = $dbh->quote($description || '');
	$private ||= 0;
	
	#update event
	my $query = "UPDATE calendar_event SET date = '$year-$month-$day', start = '$start_hour:$start_minute', end = '$end_hour:$end_minute', description = $description, private = $private WHERE id = $id";
	warn $query;
	return $dbh->do($query);
}
#= /update_entry

=head2 delete_entry

Removes an existing entry.

B<Parameters>:

=over

=item * $id - The id of the entry, which should be removed

=back

=cut
sub delete_entry {
	my ($self, $id) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	return $dbh->do("DELETE FROM calendar_event WHERE id = $id");
}
#= /delete_entry

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt>

=cut

__DATA__

-- 8< -- dbi: create -- >8 --

CREATE TABLE IF NOT EXISTS calendar_event
(
  id          INT UNSIGNED     NOT NULL AUTO_INCREMENT,
	
  #entry
  date        DATE             NOT NULL,
  start       TIME             NOT NULL,
  end         TIME             NOT NULL,
  description TEXT             NOT NULL,
  author      INT UNSIGNED     NOT NULL,
  private     TINYINT UNSIGNED NOT NULL,
  
  PRIMARY KEY(id),
  INDEX(date)
);