# Jared Still
# 2024-05-21
# jkstill@gmail.com
#
# use to fork a process to run a job
# jobrun.pl is the front end
######################################################

=head1 Jobrun.pm

  Jobrun - run an arbitrarily large list of jobs, N jobs in parallel simultaneously

=cut

=head1 VERSION

Version 0.01

=cut

=head1 NAME

Jobrun - A framework for running jobs in parallel

=head1 Synopsis

 The Jobrun module provides a framework for running jobs in a controlled manner.

 See jobrun.pl --help for usage.

 Also see README.md for more details.

=cut

=head1 AUTHOR

Jared Still, C<< <jkstill at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-jobrun at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Jobrun>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Jobrun
    jobrun.pl --help
	 README.md

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Jobrun>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Jobrun>

=item * Search CPAN

L<https://metacpan.org/release/Jobrun>

=back


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by Jared Still.

This is free software, licensed under:

  The MIT License

=cut


package Jobrun;

use 5.006;
use warnings;
use strict;
use Data::Dumper;
use File::Temp qw/ :seekable tmpnam/;
use DBI;
use Carp;
use IO::File;
use POSIX       qw(strftime);
use Time::HiRes qw(time usleep);

use lib '.';

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
	logger childSanityCheck createResumableFile cleanupResumableFile
	getRunningJobPids microSleep getTimeStamp getTableTimeStamp
	status getChildrenCount setControlTable getControlTable init
);
our $VERSION = '0.01';

my $tableDir = './tables';
mkdir $tableDir unless -d $tableDir;
-d $tableDir or croak "table directory $tableDir not created: $!\n";

my $controlTable;

sub setControlTable {
	$controlTable = shift;
	return;
}

sub getControlTable {
	return $controlTable;
}

# call this just once from the driver script jobrun.pl
my $utilDBH;

sub init {
	$utilDBH = createDbConnection();
	createTable();
	truncateTable();
	return;
}

sub createDbConnection {
	my $dbh = DBI->connect(
		"dbi:CSV:",
		undef, undef,
		{
			f_ext      => ".csv",
			f_dir      => $tableDir,
			flock      => 2,
			RaiseError => 1,
		}
		)
		or croak "Cannot connect: $DBI::errstr";

	return $dbh;
}

# add start,end,elapsed time to table

sub createTable {

	# create table if it does not exist
	eval {
		local $utilDBH->{RaiseError} = 1;
		local $utilDBH->{PrintError} = 0;

		$utilDBH->do(
			qq{CREATE TABLE $controlTable (
				name CHAR(50)
				, pid CHAR(12)
				, status CHAR(20)
				, start_time CHAR(30)
				, end_time CHAR(30)
				, elapsed_time CHAR(20)
				, exit_code CHAR(10)
				, cmd CHAR(200))
			}
		);

	};

	#if ($@) {
	#print "Error: $@\n";
	#print "Table most likely already exists\n";
	#}

	return;
}

sub truncateTable {
	$utilDBH = createDbConnection();
	$utilDBH->do("DELETE FROM $controlTable");
	return;
}

sub insertTable {
	my ( $self, $name, $pid, $status, $startTime, $endTime, $elapsedTime, $exit_code, $cmd ) = @_;

	#print 'insertTable SELF: ' . Dumper($self);
	my $dbh = $self->{dbh};
	my $sth = $dbh->prepare("INSERT INTO $controlTable (name,pid,status,start_time,end_time,elapsed_time,exit_code,cmd) VALUES (?,?,?,?,?,?,?,?)");
	$sth->execute( $name, $pid, $status, $startTime, $endTime, $elapsedTime, $exit_code, $cmd );

	# DBD::CSV always autocommits
	# this is here in the event that we use a different DBD
	#$dbh->commit();
	return;
}

sub deleteTable {
	my ( $self, $name ) = @_;
	my $dbh = $self->{dbh};
	my $sth = $dbh->prepare("DELETE FROM $controlTable WHERE name = ?");
	$sth->execute($name);

	#$dbh->commit();
	return;
}

sub selectTable {
	my ( $self, $column, $value ) = @_;
	my $dbh = $self->{dbh};
	my $sth = $dbh->prepare("SELECT * FROM $controlTable WHERE ? = ?");
	$sth->execute( $column, $value );
	my $hashRef = $sth->fetchall_hashref;
	return $hashRef;
}

# only updates status and exit_code
sub updateStatus {
	my ( $self, $name, $status, $exit_code, $startTime, $endTime, $elapsedTime ) = @_;
	my $dbh = $self->{dbh};
	my $sth = $dbh->prepare("UPDATE $controlTable SET status = ?, exit_code = ?, start_time = ? , end_time = ?, elapsed_time = ?  WHERE name = ?");
	$sth->execute( $status, $exit_code, $startTime, $endTime, $elapsedTime, $name );

	#$dbh->commit();
	return;
}

# this is a sanity check for the child processes
# validate that the child process is running
# if not then update status as failed and -1 in exit_code
sub childSanityCheck {
	my ( $logFileFH, $verbose ) = @_;
	logger( $logFileFH, $verbose, "childSanityCheck()\n" );
	my $sth = $utilDBH->prepare("SELECT pid FROM $controlTable WHERE status = ?");
	$sth->execute('running');
	while ( my $row = $sth->fetchrow_hashref ) {

		my $pid = $row->{pid};
		logger( $logFileFH, $verbose, "   pid: $pid\n" );

		my $rc = kill 0, $pid;
		logger( $logFileFH, $verbose, "    rc: $rc\n" );

		if ( $rc == 0 ) {
			my $dbh = createDbConnection();
			my $sth = $dbh->prepare("UPDATE $controlTable SET status = ?, exit_code = ? WHERE pid = ?");
			$sth->execute( 'failed', -1, $pid );
		}
	}
	return;
}

sub logger {
	my ( $fh, $verbose, @msg ) = @_;
	while (@msg) {
		my $line = shift @msg;
		$fh->print($line);
		print "$line" if $verbose;
	}
	return;
}

sub new {
	my ( $pkg, %args ) = @_;
	my $class = ref($pkg) || $pkg;

	#print "Class: $class\n";

	$args{dbh} = createDbConnection();

	$args{insert}       = \&insertTable;
	$args{updateStatus} = \&updateStatus;
	$args{delete}       = \&deleteTable;
	$args{select}       = \&selectTable;

	# name,pid,status,start_time,end_time,elapsed_time,exit_code,cmd) VALUES (?,?,?,?,?)");

	$args{columnNamesByName}  = { name => 0,      pid => 1,     cmd => 2,     status => 3,        exit_code => 4 };
	$args{columnNamesByIndex} = { 0    => 'name', 1   => 'pid', 2   => 'cmd', 3      => 'status', 4         => 'exit_code' };
	$args{columnValues}       = [qw/undef undef undef undef undef/];

	my ( $user, $passwd, $uid, $gid, $quota, $comment, $gcos, $dir, $shell, $expire ) = getpwuid($<) or croak "getpwuid: $!";
	print "User: $user, UID: $uid\n";

	my $retval = bless \%args, $class;

	$retval->{insert}(
		$retval,
		$retval->{JOBNAME},    #job name
		$$,                    #pid
		, 'running'            #status
		, 'NA'                 #exit code
		, ''                   #start time
		, ''                   #end time
		, ''                   #elapsed time
		, $retval->{CMD},      #command

	);
	return $retval;
}

sub getChildrenCount {

	# Return current child count
	my $sth = $utilDBH->prepare("SELECT count(*) child_count FROM $controlTable WHERE status = 'running'");
	$sth->execute();
	my $row = $sth->fetchrow_hashref;
	return $row->{child_count} ? $row->{child_count} : 0;
}

# status is called as a separate process
# and will have not knowledge of the Jobrun object
# so we need to pass the controlTable name
sub status {
	my ( $controlTable, $statusType, %config ) = @_;
	my $dbh = createDbConnection();
	my $sql;
	-r "$tableDir/${controlTable}.csv" or croak "table $tableDir/$controlTable.csv does not exist: $!\n";
	if ( $statusType eq 'all' ) {
		$sql = "SELECT * FROM $controlTable order by start_time asc";
	}
	else {
		$sql = "SELECT * FROM $controlTable WHERE status = '$statusType' order by start_time asc";
	}

	print "table: $controlTable\n";

	my $sth = $dbh->prepare($sql);
	$sth->execute();

	# %-$config{colLenSTART_TIME}s %-$config{colLenEND_TIME}s %-$config{colLenELAPSED_TIME}s
	printf "%-$config{colLenNAME}s %-$config{colLenPID}s %-$config{colLenSTATUS}s %-$config{colLenEXIT_CODE}s %-$config{colLenSTART_TIME}s %-$config{colLenEND_TIME}s %-$config{colLenELAPSED_TIME}s %-$config{colLenCMD}s\n", 'name', 'pid', 'status', 'exit_code', 'start_time', 'end_time', 'elapsed', 'cmd';

	printf "%-$config{colLenNAME}s %-$config{colLenPID}s %-$config{colLenSTATUS}s %-$config{colLenEXIT_CODE}s %-$config{colLenSTART_TIME}s %-$config{colLenEND_TIME}s %-$config{colLenELAPSED_TIME}s %-$config{colLenCMD}s\n", '-' x $config{colLenNAME}, '-' x $config{colLenPID}, '-' x $config{colLenSTATUS}, '-' x $config{colLenEXIT_CODE}, '-' x $config{colLenSTART_TIME}, '-' x $config{colLenEND_TIME}, '-' x $config{colLenELAPSED_TIME}, '-' x $config{colLenCMD};
	while ( my $row = $sth->fetchrow_hashref ) {
		my $rowlen = length( $row->{cmd} ) + 0;

		#warn "rowlen: $rowlen\n";
		printf "%-$config{colLenNAME}s %-$config{colLenPID}s %-$config{colLenSTATUS}s %-$config{colLenEXIT_CODE}s %-$config{colLenSTART_TIME}s %-$config{colLenEND_TIME}s %$config{colLenELAPSED_TIME}s %-$config{colLenCMD}s\n", $row->{name}, $row->{pid}, $row->{status}, $row->{exit_code}, $row->{start_time}, $row->{end_time}, sprintf( '%6.6f', $row->{elapsed_time} ? $row->{elapsed_time} : 0 ),
			substr(
			  $row->{cmd}, defined( $config{colCmdStartPos} ) ? $config{colCmdStartPos} : 0, defined( $config{colCmdEndPos} )
			? $config{colCmdEndPos}
			: ( $rowlen - 1 ),
			);
	}
	return;
}

sub createResumableFile {
	my ( $resumableFileName, $jobsHashRef ) = @_;

	my $fh = IO::File->new();
	$fh->open( $resumableFileName, '>' ) or croak "could not create resumable file - $resumableFileName: $!\n";

	my $dbh = createDbConnection();

	# cannot figure  out use to get '!=' or 'not in' to work with DBD::CSV
	# in DBD::CSV  :
	#    '!=' is not supported
	#    '<>' is not supported
	#    'NOT IN' must be capitalized - not sure if this is a bug or by design
	my $sql = "SELECT name,status FROM $controlTable WHERE status NOT IN ('complete')";
	my $sth = $dbh->prepare($sql);
	$sth->execute();
	while ( my @row = $sth->fetchrow_array ) {
		$fh->print( "$row[0]" . ':' . "$jobsHashRef->{$row[0]}\n" );
	}
	return;
}

# remove the file if empty
sub cleanupResumableFile {
	my ($resumableFileName) = @_;
	-z $resumableFileName && unlink $resumableFileName;
	return;
}

# this may be called with --kill, so we need to create a connection
sub getRunningJobPids {
	my $dbh = createDbConnection();
	my $sth = $dbh->prepare("SELECT pid FROM $controlTable WHERE status = 'running'");
	$sth->execute();
	my @jobPids;
	while ( my $row = $sth->fetchrow_hashref ) {
		push @jobPids, $row->{pid};
	}
	return @jobPids;
}

sub microSleep {
	my $microseconds = shift;
	usleep( ( $microseconds / 1000000 ) * 1000000 );
	return;
}

sub getTimeStamp {
	my @t = [Time::HiRes::gettimeofday]->@*;
	return strftime( "%Y-%m-%d %H:%M:%S", localtime $t[0] ) . "." . $t[1];
}

sub getTableTimeStamp {
	my @t = [Time::HiRes::gettimeofday]->@*;
	return strftime( "%Y_%m_%d_%H_%M_%S", localtime $t[0] );
}

sub child {
	my ( $self, $jobName, $cmd ) = @_;

	#print 'SELF: ' . Dumper($self);
	my $grantParentPID = $$;

	my $child = fork();

	#croak("Can't fork: $!") unless defined ($child = fork());
	croak("Can't fork #1: $!") unless defined($child);

	if ($child) {
		logger( $self->{LOGFH}, $self->{VERBOSE}, "child:$$  cmd:$self->{CMD}\n" );

	}
	else {
		my $parentPID  = $$;
		my $grandChild = fork();
		croak("Can't fork #2: $!") unless defined($grandChild);

		if ( $grandChild == 0 ) {

			# use system() here
			#qx/$cmd/;
			my $pid = $$;
			logger( $self->{LOGFH}, $self->{VERBOSE}, "#######################################\n" );
			logger( $self->{LOGFH}, $self->{VERBOSE}, "## job name: $self->{JOBNAME} child pid: $pid\n" );
			logger( $self->{LOGFH}, $self->{VERBOSE}, "#######################################\n" );
			my $dbh = $self->{dbh};
			my $sth = $dbh->prepare("UPDATE $controlTable SET pid = ? WHERE name = ?");
			$sth->execute( $pid, $self->{JOBNAME} );

			#$dbh->commit();

			#$jobPids{$self->{JOBNAME}} = "$pid:running";

			#logger($self->{LOGFH},$self->{VERBOSE}, "grandChild:$pid:running\n");
			##
			#logger($self->{LOGFH} ,$self->{VERBOSE}, "grancChild:$pid running job $self->{JOBNAME}\n");
			# run the command here
			my $startTime = getTimeStamp();
			my @t0        = [Time::HiRes::gettimeofday]->@*;
			$self->{updateStatus}( $self, $self->{JOBNAME}, 'running', '', $startTime, '', '' );
			system( $self->{CMD} );
			my $rc      = $? >> 8;
			my @t1      = [Time::HiRes::gettimeofday]->@*;
			my $endTime = getTimeStamp();

			my $elapsedTime = sprintf( "%.6f", Time::HiRes::tv_interval( \@t0, \@t1 ) );

			if ( $rc != 0 ) {
				logger( $self->{LOGFH}, $self->{VERBOSE}, "#######################################\n" );
				logger( $self->{LOGFH}, $self->{VERBOSE}, "## error with $self->{JOBNAME}\n" );
				logger( $self->{LOGFH}, $self->{VERBOSE}, "## CMD: $self->{CMD}\n" );
				logger( $self->{LOGFH}, $self->{VERBOSE}, "#######################################\n" );
			}

			my $jobStatus = 'complete';
			if ( $rc == -1 ) {
				$jobStatus = 'failed';
				logger( $self->{LOGFH}, $self->{VERBOSE}, "!!failed to execute: $!\n" );
			}
			elsif ( $rc & 127 ) {
				$jobStatus = 'error';
				logger( $self->{LOGFH}, $self->{VERBOSE}, sprintf "!!child $pid died with signal %d, %s coredump\n", ( $rc & 127 ), ( $rc & 128 ) ? 'with' : 'without' );
			}
			else {
				logger( $self->{LOGFH}, $self->{VERBOSE}, sprintf "!!child $pid exited with value %d\n", $? >> 8 );
			}

			# it should not be necessary to pass $self here, not sure yet why it is necessary
			$self->{updateStatus}( $self, $self->{JOBNAME}, $jobStatus, $rc, $startTime, $endTime, $elapsedTime );
			exit $rc;

		}
		else {
			exit 0;
		}

	}

	waitpid( $child, 0 );
	return;
}

1;

