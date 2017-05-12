package Helios::Panoptes::Helper;

use 5.008000;
use strict;
use warnings;
use Data::Dumper;
use DBI;
use Helios::Service;

our $VERSION = '1.40';
our $dbh;
our %config;

my $inifile;
if (defined($ENV{HELIOS_INI}) ) {
    $inifile = $ENV{HELIOS_INI};
} else {
    $inifile = './helios.ini';
}
my $worker = new Helios::Service;
%config = $worker->getConfigFromIni($inifile);

$dbh = DBI->connect($config{dsn}, $config{user}, $config{password});

=head1 NAME

Helios::Panoptes::Helper - helper methods used by Helios::Panoptes::ErrorLog and Helios::Panoptes::JobLog

=head1 DESCRIPTION

This module contains helper functions for the ErrorLog and JobLog run mode modules.

=head1 FUNCTIONS

=head2 splitEpochDate($epoch_seconds)

=cut

sub splitEpochDate {
	my $epoch_secs = shift;

	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($epoch_secs);

	my $return_date;

	$return_date->{YYYY} = sprintf("%04d", $year + 1900);
	$return_date->{MM} = sprintf("%02d", $mon+1);
	$return_date->{DD} = sprintf("%02d", $mday);
	$return_date->{MI} = sprintf("%02d", $min);
	$return_date->{SS} = sprintf("%02d", $sec);

	# hours
	if ($hour == 12) {
		$return_date->{AMPM} = 'PM';
		$return_date->{HH12} = '12';
		$return_date->{HH24} = '12';
		$return_date->{HH} = '12';
	} elsif ($hour == 0) {
		$return_date->{AMPM} = 'AM';
		$return_date->{HH12} = '12';
		$return_date->{HH24} = '00';
		$return_date->{HH} = '12';
	} elsif ($hour > 12) {
		$return_date->{AMPM} = 'PM';
		$return_date->{HH12} = sprintf("%02d", $hour - 12);
		$return_date->{HH24} = sprintf("%02d", $hour);
		$return_date->{HH} = sprintf("%02d", $hour);
	} else {
		# hour is AM
		$return_date->{AMPM} = 'AM';
		$return_date->{HH12} = sprintf("%02d", $hour);
		$return_date->{HH24} = sprintf("%02d", $hour);
		$return_date->{HH} = sprintf("%02d", $hour);
	}

	return $return_date;
}


=head2 db_fetch_all($sql, @params)

=cut

sub db_fetch_all
{
	my $sql = shift;
	my @params = @_;
	
	my @result;

	my $sth = $dbh->prepare($sql);
	unless($sth) { throw Error::Simple($dbh->errstr); }

	$sth->execute(@params) or throw Error::Simple($dbh->errstr());
	
	while ( my $result = $sth->fetchrow_hashref() ) 
	{
		push @result, $result;
	}
	
	return @result;
}


=head2 db_fetch_row($sql, @params)

=cut

sub db_fetch_row
{
	my $sql = shift;
	my @params = @_;
	
	my @result;

	my $sth = $dbh->prepare($sql);
	unless($sth) { throw Error::Simple($dbh->errstr); }

	$sth->execute(@params) or throw Error::Simple($dbh->errstr());
	
	return $sth->fetchrow_hashref();
}


=head2 option_function_map()

=cut

sub option_function_map {
	my $funcmap;

	my $sql = "
		SELECT 
			funcid, 
			funcname 
		FROM 
			funcmap 
		ORDER BY 
			LOWER(funcname) ASC
		";

	return db_fetch_all($sql);
}


=head2 pagination($current_page, $number_per_page, $total_entries, $q, $max_pages)

=cut

sub pagination
{
	my $cur_page = shift;
	my $per_page = shift;
	my $total_entries = shift;
	my $q = shift;
	my $max_pages = shift;
	
	$max_pages ||= 10;

	return "" if($total_entries <= $per_page);
	
	my $num_pages = int($total_entries / $per_page);
	
	my $start_page = $cur_page - int($max_pages / 2);
	my $end_page = $cur_page + int($max_pages / 2);

	$end_page -= $start_page if($start_page < 0);
	$start_page -= $end_page - $num_pages if $end_page > $num_pages;
	
	$start_page = 0 if $start_page < 0;
	$end_page = $num_pages if $end_page > $num_pages;
	
	my $short_back = $cur_page - $max_pages;
	$short_back = 0 if $short_back < 0;

	my $short_forward = $cur_page + $max_pages;
	$short_forward = $num_pages - 1 if $short_forward > $num_pages;
	
	my $j=0;

	my $html = "<div class='pagination'><ul>";
	
	if($start_page > 0)
	{
		$html .= "<li class='page'><a href='$q&page=0'>&lt;&lt;</a></li>";
		$html .= "<li class='page'><a href='$q&page=$short_back'>&lt;</a></li>";
	}
	
	for($j=$start_page;$j<$end_page;$j++)
	{
		if($j != $cur_page)
		{
			$html .= "<li class='page'><a href='$q&page=$j'>" . ($j+1) . "</a></li>";
		}
		else
		{
			$html .= "<li class='page_sel'>" . ($j+1) . "</li>";
		}
	}
	
	if($end_page < $num_pages-1)
	{
		$html .= "<li class='page'><a href='$q&page=$short_forward'>&gt;</a></li>";
		$html .= "<li class='page'><a href='$q&page=" . ($num_pages-1) . "'>&gt;&gt;</a></li>";
	}
	
	$html .= "</ul></div>";
	
	return $html;
	
	
}


=head2 option_priority()

Returns a list of available log priorities and their associated text labels.

=cut

sub option_priority
{
	return (
		-1 => 'All',
		0 => 'Emergency',
		1 => 'Alert',
		2 => 'Critical',
		3 => 'Error',
		4 => 'Warning',
		5 => 'Notice',
		6 => 'Information',
		7 => 'Debug',
	);
}

=head2 option_time_horizon()

Returns a list of time horizon options, with associated text labels.

=cut

sub option_time_horizon
{
	return (
		    60 => '1 Minute',
		   300 => '5 Minutes',
		   900 => '15 Minutes',
		  1800 => '30 Minutes',
		  3600 => '1 Hour',
		  7200 => '2 Hours',
		 14400 => '4 Hours',
		 28800 => '8 Hours',
		 57600 => '16 Hours',
		 86400 => '1 Day',
		172800 => '2 Days',
		259200 => '3 Days',
		604800 => '1 Week',
	);
}


=head2 option_limit()

Returns a list of entry limits for each Error Log page.

=cut

sub option_limit
{
	return (
		  25 => '25',
		  50 => '50',
		 100 => '100',
		 200 => '200',
		1000 => '1000'
	);
}


=head2 option_search()

Returns a list of optional search fields in the database, with associated labels.

=cut

sub option_search
{
	return (
		message => 'Message',
		jobid => 'Job ID',
		host => 'Host',
		process_id => 'Process ID',
	);
}


=head2 hash_to_pair($hash, $mode)

=cut

sub hash_to_pair
{
	my $hash = shift;
	my $mode = shift;
	
	$mode ||= 'num';
	
	my $key;
	my $value;
	
	my %hash = %$hash;
	
	my @options = ();
	
	if($mode eq 'num')
	{
		foreach(sort { $a <=> $b } keys %hash)
		{	
			$key = $_;
			$value = $hash{$_};
			push @options,{key => $key, value => $value};
		}
	}
	else
	{
		foreach(sort { $a cmp $b } keys %hash)
		{	
			$key = $_;
			$value = $hash{$_};
			push @options,{key => $key, value => $value};
		}
	}
    
	return \@options;

}
1;
__END__

=head1 SEE ALSO

L<Helios::Panoptes>, L<Helios::Service>, L<helios.pl>, <CGI::Application>, L<HTML::Template>

=head1 AUTHOR 

Andrew Johnson, <lajandy at cpan dotorg>
Ben Kucenski, <bkucenski at toolbox dotcom>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-9 by CEB Toolbox, Inc.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.8.0 or, at your option, any later version of Perl 5 you may have available.

=head1 WARRANTY 

This software comes with no warranty of any kind.

=cut
