#TODO: Synopsis

=head1 NAME

Konstrukt::Plugin::browserstats::DBI - Browser statistics. DBI backend

=head1 SYNOPSIS
	
	#TODO

=head1 DESCRIPTION

Browser statistics. DBI backend

=head1 CONFIGURATION

Note that you have to create a table called C<browserstats>.
You may turn on the C<install> setting (see L<Konstrukt::Handler/CONFIGURATION>)
or use the C<KonstruktBackendInitialization.pl> script to accomplish this task.

You have to define those settings to use this backend:

	#backend
	browserstats/backend                  DBI
	browserstats/backend/DBI/source       dbi:mysql:database:host
	browserstats/backend/DBI/user         user
	browserstats/backend/DBI/pass         pass

If no database settings are set the defaults from L<Konstrukt::DBI/CONFIGURATION> will be used.

=cut

package Konstrukt::Plugin::browserstats::DBI;

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
	
	my $db_source = $Konstrukt::Settings->get('browserstats/backend/DBI/source');
	my $db_user   = $Konstrukt::Settings->get('browserstats/backend/DBI/user');
	my $db_pass   = $Konstrukt::Settings->get('browserstats/backend/DBI/pass');
	
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

Adds a new browserstat entry.

B<Parameters>:

=over

=item * $class - The class of the browser

=item * $aggregate - The range over which the hits should be aggregated. May be all, year, month and day.

=back

=cut
sub hit {
	my ($self, $class, $aggregate) = @_;
	
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
	$class = $dbh->quote($class);
	$date  = $dbh->quote($date);
	
	#insert entry if not exists
	$dbh->do("INSERT IGNORE INTO browserstats (class, date, count) VALUES ($class, $date, 0)") or return;
	#update entry
	$dbh->do("UPDATE browserstats SET count = count + 1 WHERE class = $class AND date = $date") or return;
	
	return 1;
}
#= /hit

=head2 get

Returns the statistics as an array reference of hash references:
	[
		{ class => <value>, date => <value>, count => <value> },
		...
	]

B<Parameters>:

=over

=item * $aggregate - The range over which the hits should be aggregated. May be all, year, month and day.

=back

=cut
sub get {
	my ($self, $aggregate) = @_;
	
	my $dbh = $Konstrukt::DBI->get_connection(@{$self->{db_settings}}) or return undef;
	
	#generate GROUP BY statement
	my $group_by = "class";
	if ($aggregate eq 'year') {
		$group_by .= ", YEAR(date) DESC";
	} elsif ($aggregate eq 'month') {
		$group_by .= ", YEAR(date) DESC, MONTH(date) DESC";
	} elsif ($aggregate eq 'day') {
		$group_by .= ", YEAR(date) DESC, MONTH(date) DESC, DAYOFMONTH(date) DESC";
	}
	
	my $query = "SELECT class, date, SUM(count) as count FROM browserstats GROUP BY $group_by ORDER BY date DESC, count DESC";
	my $rv = $dbh->selectall_arrayref($query, { Columns=>{} });
	return (@{$rv} ? $rv : []);
}
#= /get

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin::browserstats>, L<Konstrukt>

=cut

__DATA__

-- 8< -- dbi: create -- >8 --

CREATE TABLE IF NOT EXISTS browserstats
(
	#entry
	class       VARCHAR(255)  NOT NULL,
	count       INT UNSIGNED  NOT NULL,
	date        DATE          NOT NULL,
	
	PRIMARY KEY(class, date),
	INDEX(class), INDEX(date)
);