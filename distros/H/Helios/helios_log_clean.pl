#!/usr/bin/env perl

use strict;
use warnings;
use Error qw(:try);
use Getopt::Long;

use Helios::Service;
use Helios::Error;

our $VERSION = '2.80';

# CHANGES:
# [LH] 2013-08-04: Changed service instantiation to use new Helios::Config API.
# [LH] [2014-02-28]:  Changed shebang line to use env instead of /usr/bin/perl

=head1 NAME

helios_log_clean.pl - Clean old log and history entries from the Helios database

=head1 SYNOPSIS

helios_log_clean.pl [--days=<days>] [--silent]

=head1 DESCRIPTION

Use helios_log_clean.pl to delete old entries from the log and job history in the Helios database 
(helios_log_tb and helios_job_history_tb, respectively).  

=head1 COMMAND OPTIONS

=head2 --days

Specify the number of days of logs you wish to keep using the --days option.  If not specified, 
logs and job history from the past 7 days are kept.  Older entries will be deleted.

=head2 --silent

In silent mode, helios_log_clean.pl will only print output if an error occurs.  Useful for running 
from cron.

=head2 --help

Print this help.

=cut

our $SECONDS_IN_DAY = 86400;
our $DEBUG_MODE = 0;
our $DAYS = 0;
our $HELP_MODE = 0;
our $SILENT_MODE = 0;
GetOptions ("days=i" => \$DAYS,
	"silent" => \$SILENT_MODE,
	"help"   => \$HELP_MODE,
	"debug"  => \$DEBUG_MODE
);

# print help if asked
if ( $HELP_MODE ) {
	require Pod::Usage;
	Pod::Usage::pod2usage(-verbose => 2, -exitstatus => 0);
}

# honor HELIOS_DEBUG env var
if ( defined($ENV{HELIOS_DEBUG}) && $ENV{HELIOS_DEBUG} == 1 ) {
	$DEBUG_MODE = 1;
}

# DEBUG overrides SILENT
if ($DEBUG_MODE) { $SILENT_MODE = 0; }

# default to 7 days if --days wasn't specified
unless ($DAYS) { $DAYS = 7; }

# instantiate the base worker class just to get the [global] INI params
# (we need to know where the Helios db is)
our $WORKER = new Helios::Service;
# BEGIN [LH] 2012-08-04: Changed old service init to use new Helios::Config API
$WORKER->prep();
my $params = $WORKER->getConfig();
# END [LH] 2012-08-04
my $sql;
my $epoch_horizon = time() - ($DAYS * $SECONDS_IN_DAY);

# connect to the Helios database
unless ($params->{dsn}) { throw Helios::Error::Fatal("Helios dsn not defined!"); }
my $dbh = $WORKER->dbConnect($params->{dsn}, $params->{user}, $params->{password});
if ($DBI::errstr) { throw Helios::Error::DatabaseError($DBI::errstr); }	
if ($DEBUG_MODE) { print "Connected to Helios database.\n"; }

# clean the log table
unless ($SILENT_MODE) { print "Deleting log entries older than $DAYS days...\n"; }
$sql = "DELETE FROM helios_log_tb WHERE log_time <= $epoch_horizon";
if ($DEBUG_MODE) { print $sql,"\n"; }
$dbh->do($sql);
print "...done.\n";


# clean the job history table
unless ($SILENT_MODE) { print "Deleting job history older than $DAYS days...\n"; }
$sql = "DELETE FROM helios_job_history_tb WHERE complete_time <= $epoch_horizon";
if ($DEBUG_MODE) { print $sql,"\n"; }
$dbh->do($sql);
unless ($SILENT_MODE) { print "...done.\n"; }



=head1 AUTHOR

Andrew Johnson, E<lt>lajandy at cpan dotorgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-9 by CEB Toolbox, Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 WARRANTY

This software comes with no warranty of any kind.

=cut

