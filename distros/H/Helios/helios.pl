#!/usr/bin/env perl

use 5.008;
use strict;
use warnings;
use FindBin ();
use File::Basename ();
use File::Spec;
use Getopt::Long;
use POSIX;
use Sys::Hostname;
# [LH] 2013-08-04:  Added Fcntl for better pidfile locking.  [RT81914]
use Fcntl qw(:DEFAULT :flock);

use Helios;
use Helios::Error;
use Helios::LogEntry::Levels qw(:all);
# [LH] [2013-10-04]: Switched to using Helios::TS for virtual jobtypes.
use Helios::TS;
use Helios::Config;

our $VERSION = '2.80';

# FILE CHANGE HISTORY
# [2012-01-08]: Added a check to try to prevent loading code outside of @INC.
# [2012-01-09]: Modified check to prevent loading code outside of @INC.
# [2012-03-25]: Added code to prevent a worker process from changing into a  
# daemon due to odd (and uncommon) database connection instability.
# [2012-03-27]: Changed $DEFAULTS{ZERO_SLEEP_INTERVAL} to 10.  Added code to 
# add "registration_interval" as a configuration parameter.  Added 
# $DEFAULTS{REGISTRATION_INTERVAL} and set to 60.  Changed 
# $REGISTRATION_INTERVAL to 60.
# [2012-04-01]: Changed service module loaded notification to report version 
# only if the module has a $VERSION set.  Changed service initialization to use
# the prep() method instead of getConfigFromIni() and getConfigFromDb() to 
# ensure proper initialization of loggers and Data::ObjectDriver database 
# connection.
# [2012-05-20]: Removed old commented out calls to getConfigFrom*(), 
# clean_shutdown(), and logMsg() (logging a HALT message).  Removed 2 empty
# comments.
# [LH] [2012-07-11]: Switched from using TheSchwartz to using 
# Helios::TheSchwartz.  Added WORKER_BLITZ_FACTOR feature to launch workers 
# faster when there are less than MAX_WORKERS jobs available.  Stopped closing
# STDOUT, STDIN, and STDERR when helios.pl daemonizes because it was causing
# problems with some services.
# [LH] [2012-07-15]: Added to use Helios::Config, and changed configuration 
# update code to use Helios::Config instead of getConfigFromDb().  Added 
# debugging messages for ZERO_SLEEP_INTERVAL and REGISTRATION_INTERVAL.
# [LH] [2012-07-26]: Changed "worker_blitz_factor" config param to 
# "WORKER_BLITZ_FACTOR".  Added new code to better handle database connections
# after a fork() so worker processes do not share or disconnect the daemon's 
# connections.
# [LH] [2012-07-29]: Added DOUBLE_CLUTCH_INTERVAL config parameter to control 
# WORKER_MAX_TTL functionality better than ZERO_LAUNCH_INTERVAL.  Updated 
# copyright info.  
# [LH] [2012-09-05]: Changed DOUBLE_CLUTCH_INTERVAL to 
# WORKER_MAX_TTL_WAIT_INTERVAL.
# [LH] [2012-09-28]: Removed old commented out code.
# [LH] [2012-10-12]: Replaced code attempting to prevent loading of modules
# outside of @INC with new require_module() function.
# [LH] [2012-12-11]: Added code to apply WORKER_MAX_TTL after registration in 
# daemon main loop.  [RT81709]
# [LH] [2013-08-04]: Implemented new PID file locking scheme to fix [RT81914]. 
# Replaced write_pid_file() and mostly rewrote running_process_check() to 
# prevent a PID file race condition.  
# [LH] [2013-08-19]: Added comments for clarification of fix for [RT81914].
# [LH] [2013-09-21]: Added code to enable job prioritization features in 
# Helios::TheSchwartz.  Added code to implement WORKER_LAUNCH_PATTERN feature.
# [LH] [2013-10-04]: Added code to implement "virtual jobtypes."  Switched to 
# using Helios::TS instead of Helios::TheSchwartz.  Changed command line 
# option parsing to accomodate options other than "--clear-halt".  Removed 
# old commented out code for class name sanity checking and class loading.  
# Removed old code to calculate workers to launch, also removed code for 
# WORKER_BLITZ_FACTOR feature (WORKER_LAUNCH_PATTERN replaces it).
# [LH] [2013-10-18]: Replaced most try {} blocks with eval {}.  Changed option 
# handling to better handle --help and fix --version.  Added --debug option.  
# Changed $CLASS to $OPT_CLASS like all the other $OPT_* option variables.  
# Added startup message so user knows which collective db the daemon connected 
# to.  Partially updated POD with new options and mentioned new 
# Helios::Configuration POD; also added mention of zero_sleep_interval option.
# [LH] [2013-11-24]: Removed use of Error module as all use of try {} catch {} 
# blocks have been removed.  Changed command line option handling so jobtypes 
# can be specified with multiple --jobtype options as well as a single comma-
# delimited --jobtypes argument.  Removed old commented out code.  Database
# reconnect code now dumps all cached database connections before attempting 
# a reconnect.
# [LH] [2014-02-28] POD updates.  Updated copyright info.  Changed 
# WORKER_LAUNCH_PATTERN values to "linear","dynamic", and "optimistic".

=head1 NAME

helios.pl - Launch a daemon to service jobs in the Helios job processing system

=head1 SYNOPSIS

 # Make sure HELIOS_INI is set and exported.  Optionally enable debug mode.
 export HELIOS_INI=/path/to/helios.ini
 [export HELIOS_DEBUG=1]
 # Full command line options 
 helios.pl [--service=<service class>] [--jobtypes=<jobtypename,jobtypename>] \
 [--clear-halt] [--version] [--help]

 # Simple cmd line example: start a daemon with the Helios::TestService service.
 helios.pl Helios::TestService
 
 # More complex: start a Helios::TestService daemon, but have it run MyService jobs.
 helios.pl --service=Helios::TestService --jobtypes=MyService

 # Just prints version info.
 helios.pl --version
 
 # Prints this help page.
 helios.pl --help

=head1 DESCRIPTION

The helios.pl program, given a Helios service class, will launch a daemon
to service Helios jobs of that class.  The number of worker processes to run 
concurrently and various other parameters are set via a helios.ini file and the 
Helios collective database (the connection information of which is also defined 
in helios.ini).

Under normal operation, helios.pl will attempt to load the service class 
specified on the command line and read the contents of the helios.ini file.  If
successful, it will attempt to connect to the Helios collective 
database specified in helios.ini and read the configuration parameters relevant
to the loaded service class from there.  If that is successful, helios.pl will
then daemonize and start servicing jobs of the specified class.  If additional
jobtypes are specified with the --jobtypes option, jobs of those additional
types will also be serviced by the loaded service class.

=head1 helios.pl COMMAND LINE OPTIONS

=head2 --service [REQUIRED]

The --service option specifies the name of the Helios service to load and
launch worker processes for.  If you specify the name as the first option on
the command line, you can actually drop the '--service=' part, as helios.pl
will assume the first option is the service class name.

Examples:

 helios.pl --service=MyService
 --OR--
 helios.pl MyService

=head2 --jobtypes

Normally, a Helios service will run jobs belonging to its own jobtype (the
service class name matches the jobtype name).  However, as of Helios 2.80, a
Helios service can run jobs of multiple jobtypes if necessary.  These
additional jobtypes should be specified on the helios.pl command line with the
--jobtypes option.  You can specify multiple jobtypes by separating them with
commas, or specify multiple --jobtype values.  (Thanks to helios.pl's use of
L<Getopt::Long>, '--jobtype' and '--jobtypes' are interchangable.)

Examples:

 # MyService handles jobs of jobtype "MyService" (the default)
 helios.pl MyService
 
 # MyService handles MyService jobs and MyIndexer jobs
 helios.pl MyService --jobtype=MyIndexer
 
 # MyService handles MyService, MyIndexer, and MyMailer jobs
 helios.pl MyService --jobtypes=MyIndexer,MyMailer
 --OR--
 helios.pl MyService --jobtype=MyIndexer --jobtype=MyMailer

For more information about jobtypes and how they relate to jobs and services,
see the L<Helios::JobType> man page.
 
=head2 --clear-halt

If the --clear-halt option is specified, helios.pl will attempt to remove a HALT
parameter specified in the Helios configuration for the specified service on the
current host.  This is helpful if you shutdown your Helios service daemon using 
the Helios::Panoptes Collective Admin view.  Note that it will NOT remove a HALT
specified globally (where host = '*').

=head2 --version

The --version option displays the Helios framework version and the helios.pl
version and then exits.

=head2 --help

The --help option displays this documentation.

=head1 helios.pl ENVIRONMENT VARIABLES

The Helios framework relies directly on two environment variables to function
correctly.  Both should be exported as well as set to ensure the helios.pl
child processes can see them as well as the main helios.pl daemon.

=head2 HELIOS_INI [REQUIRED]

The full path to the helios.ini configuration file.  This should be an absolute
path, not a relative one.  The default is to use a helios.ini in the current
directory if it exists, which will work if you are running in Debug Mode (see
HELIOS_DEBUG below), but will cause problems if helios.pl is running normally.

I<Default:  ./helios.ini>

=head2 HELIOS_DEBUG

Setting HELIOS_DEBUG to 1 causes helios.pl to run in Debug Mode.  In Debug Mode,
helios.pl will not disconnect from the terminal and will output extra debugging
information to the screen and the Helios log.  It will also enable debug mode
on the service class, which may support the output of extra debugging
information if you so choose.

I<Default:  undef>

=head1 HELIOS.INI

The initial parameters for helios.pl are defined in an INI-style configuration 
file typically named "helios.ini".  The file's location is normally specified 
by setting the HELIOS_INI environment variable before helios.pl is started.  

A helios.ini file normally contains a [global] section with the parameters 
necessary to connect to the Helios collective database, and any parameters local
to the host on which the Helios service is currently running.  In addition, 
each service class may have its own section in helios.ini containing 
parameters specfic to that service on that host.

Example helios.ini:

 [global]
 dsn=dbi:mysql:host=10.1.0.21;db=helios_db
 user=helios
 password=password

 [LongRunningJobService]
 master_launch_interval=60
 zero_launch_interval=90

 [AnotherService]
 OVERDRIVE=1
 MAX_WORKERS=3

=head2 Helios.ini Parameters for helios.pl

This section just covers the basic config options for helios.pl.  For a 
complete list of built-in Helios config options, consult the 
L<Helios::Configuration> man page.

=head3 Configuration options to place in the [global] section:

These options will be the same for all Helios services running a host that 
share the same collective database, so these options must be placed in a 
helios.ini section named [global] so they are visible to all running helios.pl 
instances.

=over 4

=item dsn [REQUIRED]

Datasource name for the Helios collective database.  The collective database
houses the data structures for service configuration, jobtypes, job queuing and
history, and the default logging subsystem.

I<Default: none>

=item user [REQUIRED]

Database user for the datasource name described above.

I<Default: none>

=item password [REQUIRED]

Database password for the datasource name described above.

I<Default: none>

=item pid_path

The location where helios.pl should write the PID file for this service 
instance.  The name of the PID file will be a variation on the service class's
name.

I<Default:  /var/run/helios>

=back

=head3 Configuration options to place in individual service sections:

The options listed in this section are available to tune helios.pl to work 
better with your Helios service class and the jobs it needs to service.  These
are read at startup and, unlike some other Helios config options, cannot be 
dynamically changed while helios.pl is running.  If you wish to tune one of 
these parameters, reset the parameter and restart the service daemon.

=over 4

=item master_launch_interval

Set the master_launch_interval to determine how long helios.pl should sleep 
after launching workers before accessing the database to update its 
configuration parameters and check for waiting jobs.  The default is 1 second, 
which should be sufficient for most applications. 

I<Default:  1>

=item zero_launch_interval

Set the zero_launch_interval to determine how long helios.pl should sleep after 
reaching its MAX_WORKERS limit.  The default is 10 sec.  If jobs are running 
long enough that helios.pl is frequently hitting the MAX_WORKERS limit (there 
are waiting jobs but helios.pl can't launch new workers because previously 
launched jobs are still running), increasing the zero_launch_interval will 
reduce needless database traffic.

I<Default:  10>

=item zero_sleep_interval

Set the zero_sleep_interval to adjust the amount of time between checks for 
available jobs in the job queue when the job queue is empty.  If the helios.pl 
daemon determines there are no available jobs for a service, it sleeps 
zero_sleep_interval seconds and then checks for jobs again.  The default is 10 
sec.  If you notice jobs are sitting in the job queue too long before workers 
are launched to service them, reduce this number to cause jobs to be started 
faster.  If you have a small number of jobs and do not care if they sit in the 
job queue for a few seconds before being serviced, increase this number to 
reduce database queries. 

I<Default:  10>

=back

=head1 HELIOS_CONFIG_* AND HELIOS CTRL PANEL (helios_params_tb)

In addition to helios.ini, certain helios.pl configuration options can be set 
via the helios_config_* commands or the Ctrl Panel or Collective Admin views
in the Helios::Panoptes web admin interface.  These configuration options are
read by helios.pl from the HELIOS_PARAMS_TB table in the Helios collective
database.  For more information on configuration parameters available to tune
how a service runs jobs, see the L<Helios::Configuration> man page.  For more
information on the L<helios_config_get>, L<helios_config_set>,
L<helios_config_unset> commands and the L<Helios::Panoptes> web admin
interface, see their respective man pages or Perl POD.

=cut

# for SIGHUP support
our @ORIGINAL_ARGV = @ARGV;
my $basename = File::Basename::basename($0);
our $HELIOS_PL_PATH = File::Spec->catfile($FindBin::Bin, $basename);

# globals settings
our $DEBUG_MODE = $ENV{HELIOS_DEBUG};
our $HELIOS_INI = $ENV{HELIOS_INI};
# BEGIN CODE Copyright (C) 2013 by Logical Helion, LLC.
# [LH] [2013-10-04]: Virtual jobtypes.  We have to parse the cmd line args 
# in a completely different way, but still maintain backward compatibility. 
# if the first cmd line switch starts with '-', then all the options are 
# "proper."  If not, then the first option is the service class, and the 
# remaining options will be proper.
our $OPT_CLASS      = '';
our $OPT_CLEAR_HALT = 0;
our $OPT_DEBUG      = 0;
our $OPT_HELP       = 0;
our @OPT_JOBTYPES   = ();
our $OPT_VERSION    = 0;
if ( defined($ARGV[0]) && $ARGV[0] !~ /^\-/) {
	$OPT_CLASS = shift @ARGV;
}
GetOptions(
	"service=s"  => \$OPT_CLASS,
	"clear-halt" => \$OPT_CLEAR_HALT,
	"help"       => \$OPT_HELP,
	"jobtypes=s" => \@OPT_JOBTYPES,
	"version"    => \$OPT_VERSION,
	"debug"      => \$OPT_DEBUG,
);
our @ALT_JOBTYPES = split(/,/, join(','=>@OPT_JOBTYPES));
$DEBUG_MODE = 1 if $OPT_DEBUG;
# END CODE Copyright (C) 2013 by Logical Helion, LLC.

# other globals
# max workers will default to 1 if not set elsewhere
our %DEFAULTS = (
    MAX_WORKERS => 1,
    HELIOS_INI => File::Spec->catfile(File::Spec->curdir,'helios.ini'),
    PID_PATH => File::Spec->catfile(File::Spec->rootdir, 'var', 'run', 'helios'),
    MASTER_LAUNCH_INTERVAL => 1,
    ZERO_LAUNCH_INTERVAL => 10,
    ZERO_SLEEP_INTERVAL => 10,
    REGISTRATION_INTERVAL => 60,
    WORKER_BLITZ_FACTOR => 1,
    WORKER_MAX_TTL_WAIT_INTERVAL => 20,
    PRIORITIZE_JOBS => 0,
	WORKER_LAUNCH_PATTERN => 'linear',
);
our $CLEAN_SHUTDOWN = 1;				# used to determine if we should remove the PID file or not (at least for now)

our $HOLD_LOG_INTERVAL = 3600;			# to reduce needless log msg in log_tb while HOLDing
our $HOLD_LOG_LAST = 0;

our $MASTER_LAUNCH_INTERVAL;
our $ZERO_LAUNCH_INTERVAL;

our $START_TIME = time();				# used to measure uptime from the registry table
our $REGISTRATION_INTERVAL = 60;		# used to periodically register daemon in database
our $REGISTRATION_LAST = 0;

our $PID_FILE;							# globally accessible PID file location
# [LH] 2013-08-04:  Added $PID_FILE_H as a filehandle for better pidfile locking.  [RT81914]
our $PID_FILE_H; 						# globally accessible PID file handle
our $SAFE_MODE_DELAY = 45;				# SAFE MODE support; number of secs to wait
our $SAFE_MODE_RETRIES = 5;				# SAFE MODE support; number of times to retry 

our $ZERO_SLEEP_INTERVAL;				# to reduce needless checking of the database
our $ZERO_SLEEP_LOG_INTERVAL = 3600;	# to reduce needless log msgs in log_tb
our $ZERO_SLEEP_LOG_LAST = 0;
our $WORKER_MAX_TTL_WAIT_INTERVAL = 20;		# for WORKER_MAX_TTL functionality

our $WORKER_PROCESS = 0;				# used to indicate process has become a worker process
										# this is used in addition to getppid() to prevent workers
										# from becoming daemons in case of database instability

our $WORKER_BLITZ_FACTOR = 1;			# used to determine how many workers to launch
our $HELIOS_DB_CONN;					# database handle to help with DBI+forking issues

# print help if asked
# [LH] [2013-10-04]: New @ARGV parsing for "--help". 
if ( $OPT_HELP ) {
	require Pod::Usage;
	Pod::Usage::pod2usage(-verbose => 2, -exitstatus => 0);
}

# conditionally load module or die in the attempt
my $worker_class = $OPT_CLASS;
print "Helios ",$Helios::VERSION,"\n";
print "helios.pl Service Daemon version $VERSION\n";
# --version support
# BEGIN CODE Copyright (C) 2013 by Logical Helion, LLC.
# [LH] [2013-10-04]: New @ARGV parsing for "--version".
# [LH] [2013-10-18]: New @ARGV parsing for --service.
if ( $OPT_VERSION ) { exit(0); }
unless ($OPT_CLASS) { 
	warn("The name of a service class is required.\n");
	exit(1);
}
# END CODE Copyright (C) 2013 by Logical Helion, LLC.
print "Attempting to load $worker_class...\n"; 
require_module($worker_class);

if ( defined($worker_class->VERSION) ) {
	print $worker_class, ' ', $worker_class->VERSION," loaded.\n";
} else{
	print $worker_class," loaded.\n";
}
if ($DEBUG_MODE) { print "Debug Mode enabled.\n"; }

# instantiate a worker to access the necessary settings
my $worker = new $worker_class;
$worker->setHostname(hostname);
if ( defined($HELIOS_INI) ) {
        $worker->setIniFile( $HELIOS_INI );
} else {
        $worker->setIniFile( $DEFAULTS{HELIOS_INI} );
}
$worker->setJobType($worker_class);
# BEGIN CODE Copyright (C) 2013 by Logical Helion, LLC.
# [LH] [2013-10-04]: Virtual jobtypes set & init.
if (@ALT_JOBTYPES) {
	$worker->setAltJobTypes(@ALT_JOBTYPES); 
	$worker->lookupAltJobtypeids();
	print "Servicing jobtypes: ", join(' ' => ($worker->getJobType(), $worker->getAltJobTypes())),"\n";
}
# END CODE Copyright (C) 2013 by Logical Helion, LLC.
$worker->debug($DEBUG_MODE);
eval {
	$worker->prep();
};
if ($@) {
        die("FAILED to get configuration: $@");
}

my $params = $worker->getConfig();
if ($DEBUG_MODE) {
        print "--INITIAL PARAMS--\n";
        foreach my $param (keys %$params) {
                print $param, ":", $params->{$param},"\n";
        }
}

# SETUP OPERATIONAL PARAMETERS
if ( defined($params->{master_launch_interval}) ) {
	$MASTER_LAUNCH_INTERVAL = $params->{master_launch_interval};
} else {
	$MASTER_LAUNCH_INTERVAL = $DEFAULTS{MASTER_LAUNCH_INTERVAL};
}
if ( defined($params->{zero_launch_interval}) ) {
	$ZERO_LAUNCH_INTERVAL = $params->{zero_launch_interval};
} else {
	$ZERO_LAUNCH_INTERVAL = $DEFAULTS{ZERO_LAUNCH_INTERVAL};
}
if ( defined($params->{zero_sleep_interval}) ) {
	$ZERO_SLEEP_INTERVAL = $params->{zero_sleep_interval};
} else {
	$ZERO_SLEEP_INTERVAL = $DEFAULTS{ZERO_SLEEP_INTERVAL};
}
if ( defined($params->{registration_interval}) ) {
	$REGISTRATION_INTERVAL = $params->{registration_interval};
} else {
	$REGISTRATION_INTERVAL = $DEFAULTS{REGISTRATION_INTERVAL};
}
if ( defined($params->{WORKER_BLITZ_FACTOR}) ) {
	$WORKER_BLITZ_FACTOR = $params->{WORKER_BLITZ_FACTOR};
} else {
	$WORKER_BLITZ_FACTOR = $DEFAULTS{WORKER_BLITZ_FACTOR};
}
if ( defined($params->{WORKER_MAX_TTL_WAIT_INTERVAL}) ) {
	$WORKER_MAX_TTL_WAIT_INTERVAL = $params->{WORKER_MAX_TTL_WAIT_INTERVAL};
} else {
	$WORKER_MAX_TTL_WAIT_INTERVAL = $DEFAULTS{WORKER_MAX_TTL_WAIT_INTERVAL};	
}

# make a globally accessible database handle 
# to make it easier to clean up CachedKids after a fork()
$HELIOS_DB_CONN = $worker->dbConnect();
# [LH] [2013-10-18]: Added startup message so user knows which collective db
# we connected to
print "Connected to collective database: ",$params->{dsn},"\n";

if ($DEBUG_MODE) { 
	print "MASTER LAUNCH INTERVAL: $MASTER_LAUNCH_INTERVAL\n"; 
	print "ZERO LAUNCH INTERVAL: $ZERO_LAUNCH_INTERVAL\n"; 
	print "ZERO SLEEP_INTERVAL: $ZERO_SLEEP_INTERVAL\n";	
	print "REGISTRATION_INTERVAL: $REGISTRATION_INTERVAL\n";
	print "WORKER BLITZ FACTOR: $WORKER_BLITZ_FACTOR\n";
}

my %workers;
my $pid;

my $waiting_jobs = 0;
my $running_workers = 0;
my $max_workers = $DEFAULTS{MAX_WORKERS};

our $DATABASES_INFO = [
                {       dsn => $params->{dsn},
                        user => $params->{user},
                        pass => $params->{password}
                }
                ];

my $times_thru_loop = 0;
my $times_waiting = 0;
my $times_sleeping = 0;

# attempt to clear a HALT parameter, if specified
# then we'll check to see if HALT is still there
# if it is, we'll have to stop here rather than 
# daemonize and launch the main loop
# [LH] [2013-10-04]: New @ARGV parsing for "--clear-halt". 
if ( $OPT_CLEAR_HALT ) {
	clear_halt();
	$worker->prep();
	$params = $worker->getConfig();
}
if ( defined($params->{HALT}) ) {
	print STDERR "HALT is set for this service class.\n";
	print STDERR "Please clear it and try again.\n";
	print STDERR $worker_class," HALTED.\n";
	exit(1);
}
# final check before we launch:  
# check to make sure a daemon for this service isn't already running
if ( running_process_check($params->{pid_path}) ) {
	print STDERR $worker->errstr(),"\n";
	exit(1);
}

# Daemonize unless we're in debug mode
unless ($DEBUG_MODE) {
	daemonize();
} else {
	# print debug message
	print "Writing pid file...\n";
	write_pid_file($params->{pid_path}) or die($worker->errstr);
	print "Executing main loop...\n";
}

# set up signal handler to reap dead children
$SIG{CHLD} = \&reaper;
$SIG{TERM} = \&terminator;


=head1 HELIOS OPERATION

After initial setup, the helios.pl daemon will enter a main operation loop where configuration 
parameters are refreshed, the job queue is checked, and worker processes are launched and 
cleaned up after.  A HOLD = 1 parameter will temporarily cause the loop to pause processing, while
a HALT parameter will cause the helios.pl daemon to exit the loop, clean up, and exit.

There are several steps in the helios.pl main operation loop:

=over 4

=item 1.

Refresh configuration parameters from database.

=item 2.

Check job queue to see if there are jobs of the correct jobtype(s) available
for processing (if not, sleep for zero_sleep_interval seconds and start again).

=item 3.

If there are jobs available, check to see how many worker processes are currently running.  
If MAX_WORKERS workers are already running, sleep for zero_launch_interval seconds and 
start again.  The zero_launch_interval setting should be long enough to allow at least some of 
the running jobs to complete (the default is 10 secs).

=item 4.

If there are jobs available and the MAX_WORKERS limit has not been reached,
determine the number of additional workers to launch and launch them.  The
number of workers to launch is governed by the WORKER_LAUNCH_PATTERN
configuration parameter; see the L<Helios::Configuration> man page for more
information.

=item 5.

Sleep master_launch_interval seconds and start the operation loop again.

=back

=cut

MAIN_LOOP:{
	# [LH] [2013-11-24]: Replaced try {} otherwise {} block with eval {} or do {}. 
	eval {
	
		# while not halted
		while (!defined($params->{HALT}) ) {
		
				$times_thru_loop++;
		
				# recheck db parameters
				$params = undef;
				$params = Helios::Config->parseConfig();
				
				# DAEMON REGISTRATION
				# every $REGISTRATION_INTERVAL seconds, (re)register this daemon in the database
				if ( ($REGISTRATION_LAST + $REGISTRATION_INTERVAL) < time() ) {
					register();
					$REGISTRATION_LAST = time();
					# [LH] 2012-12-11: Copied WORKER_MAX_TTL/double_clutch() call from HOLD code below 
					# to enable WORKER_MAX_TTL in Normal Mode as well as Hold Mode.  [RT81709]
					if ( defined($params->{WORKER_MAX_TTL}) && $params->{WORKER_MAX_TTL} > 0 
					       && scalar(keys %workers) ) {
					    double_clutch();
					}
				}
		
				# HOLDING JOB PROCESSING
				# hold launching jobs temporarily
				if ( defined($params->{HOLD}) && ($params->{HOLD} == 1) ) {
					if ( $HOLD_LOG_LAST + $HOLD_LOG_INTERVAL < time() ) {
						$worker->logMsg(LOG_NOTICE, "$0 $worker_class HOLDING"); 
						$HOLD_LOG_LAST = time();
					}
					if ($DEBUG_MODE) { print "$0 $worker_class HOLDING\n"; }
					sleep 60; 
					# after the first cycle through HOLD, the workers had BETTER be dead 
					if ( defined($params->{WORKER_MAX_TTL}) && $params->{WORKER_MAX_TTL} > 0 
					       && scalar(keys %workers) ) {
					    double_clutch();
					}
					next; 
				}
				# once we're not holding anymore, we'll want to log the next time we enter HOLD mode
				$HOLD_LOG_LAST = 0;
		

				# DETERMINING WORKERS TO LAUNCH
				$waiting_jobs = $worker->jobsWaiting();	
				$running_workers = scalar(keys %workers);
				$max_workers = defined($params->{MAX_WORKERS}) ? $params->{MAX_WORKERS} : $DEFAULTS{MAX_WORKERS};
				if ($DEBUG_MODE) { $worker->logMsg(LOG_DEBUG, "MAX WORKERS: $max_workers"); }
				if ($DEBUG_MODE) { $worker->logMsg(LOG_DEBUG, "RUNNING WORKERS: $running_workers"); }
		
				# if no waiting jobs, sleep
				if ($DEBUG_MODE) { 
					print $waiting_jobs, " waiting ",$worker_class, " jobs.\n"; 
					$worker->logMsg(LOG_DEBUG, $waiting_jobs . " waiting " . $worker_class . " jobs.");
				}
				unless ( $waiting_jobs ) {
						$times_sleeping++;	  
						# only log the "0 workers running, 0 workers in queue.  SLEEPING" message every $ZERO_SLEEP_LOG_INTERVAL seconds
						# (necessary to prevent overwhelming database logging with messages we don't care about)
						if ( ($running_workers == 0) && (($ZERO_SLEEP_LOG_LAST + $ZERO_SLEEP_LOG_INTERVAL ) < time()) ) {
							$worker->logMsg(LOG_NOTICE, $running_workers." workers running, ".$waiting_jobs." in queue.  SLEEPING");
							$ZERO_SLEEP_LOG_LAST = time();
						}
						sleep $ZERO_SLEEP_INTERVAL;
						next;
				}
				# once we're not zero sleeping ("0 workers running, 0 workers in queue") 
				# we'll want to log the next time we go into zero sleep
				$ZERO_SLEEP_LOG_LAST = 0;
		

				# LAUNCHING WORKERS
				# if we've got to this part of the loop, we have jobs that need workers to launch
				# (though we still may not do it if we've already reached our limit)
				# [LH] [2013-09-21]: Added code to implement WORKER_LAUNCH_PATTERN feature.
				my $workers_to_launch = workers_to_launch($waiting_jobs, $running_workers, $max_workers);				
				$worker->logMsg(LOG_NOTICE, "$waiting_jobs jobs waiting; $running_workers workers running; launching $workers_to_launch workers");
				for (my $i = 0; $i < $workers_to_launch; $i++) {
		
						FORK: {
							if ($pid = fork) {
										# I'm the parent!
										$workers{$pid} = time();
										if ($DEBUG_MODE) { $worker->logMsg(LOG_NOTICE, $worker->getJobType()." process $pid launched");	}
										sleep 1;
								} elsif (defined $pid) { # $pid is zero here if defined
										# I'm the child!
										$WORKER_PROCESS = 1;
										
# BEGIN CODE Copyright (C) 2012 by Logical Helion, LLC.
										# BEFORE WE LAUNCH THE WORKER,
										# clean up the database connections from the parent
										# we'll set InactiveDestroy on the existing connections
										# then we'll clear them, leaving the parent connections
										# free of any influence of the children
										# NOTE:  with DBI >= 1.614, all we'd have to do is
										# set AutoInactiveDestroy on all the connections
										# but to support the DBI (1.52) bundled with RHEL & CentOS 5,
										# we have to make do with what we have
										my $ck = $HELIOS_DB_CONN->{Driver}->{CachedKids};
										foreach (keys %$ck) {
											$ck->{$_}->{InactiveDestroy} = 1;
										}
										%$ck = ();
# END CODE Copyright (C) 2012 by Logical Helion, LLC.

										# NOW, launch the worker
										launch_worker();
							} elsif ($! == EAGAIN) {
								# EAGAIN is the supposedly recoverable fork error
									sleep 2;
								redo FORK;
							} else {
								# weird fork error
									die "Can't fork: $!\n";
							}
						}
		
				}


				# SLEEP INTERVAL AFTER LAUNCHING
				# depending on the worker type, we may need to wait before we go back to the top of the loop
				# (pull new parameters and waiting job count from the database)
				# This can help reduce needless database traffic

				# if there are running jobs but we didn't launch any 
				# (max workers has been reached) sleep for a short while
				# to reduce needless "spinning" (and db access)
				if ( $workers_to_launch <= 0 ) { 
					if ( $DEBUG_MODE ) { $worker->logMsg(LOG_DEBUG, "MAX WORKERS REACHED, SLEEPING"); }
					sleep $ZERO_LAUNCH_INTERVAL; 
					if ( defined($params->{WORKER_MAX_TTL}) && $params->{WORKER_MAX_TTL} > 0 ) {
					    double_clutch();
					}
					next;
				}

				# if we did launch jobs, depending on the type of worker we may not want to re-check the database yet
				# longer-running jobs (eg Helios::BatchWorker) don't need to have the db checked immediately after launch
				# shorter-running jobs (eg IndexWorker) have likely already completed in the time it took to launch them
				# and we want to launch as many as possible as quickly as possible (esp. if there's a Mass Index operation)
				if ($MASTER_LAUNCH_INTERVAL) {
					if ( $DEBUG_MODE ) { $worker->logMsg(LOG_DEBUG, "MASTER LAUNCH INTERVAL $MASTER_LAUNCH_INTERVAL, SLEEPING"); }
					sleep $MASTER_LAUNCH_INTERVAL;
				}
		}
		# [LH] [2013-11-24]: Replaced try {} otherwise {} block with eval {} or do {}. 
		1;
	} or do {
		my $e = shift;
		# if we're a worker process and we ended up here
		# it's a fluke caused by the database instability
		# we have to bail out and hope the service daemon survives
		# since the default logger will also be affected by this error, we can't log anything either :(
		if ( (getppid() > 1) || ($WORKER_PROCESS == 1) ) { exit(42); }
		if ($DEBUG_MODE) { 
			print "EXCEPTION THROWN: ",$e->text,"\n"; 
			print "ATTEMPTING TO RECONNECT...\n";
		}
# BEGIN CODE Copyright (C) 2013 by Logical Helion, LLC.
		#[] dump all the database connections
		# [LH] [2013-11-24]: Dump all the cached db connections so we can make
		# sure we're starting over.
		my $ck = $HELIOS_DB_CONN->{Driver}->{CachedKids};
		%$ck = ();
		$HELIOS_DB_CONN->disconnect() if ( ref($HELIOS_DB_CONN) && $HELIOS_DB_CONN->isa('DBI'));
# END CODE Copyright (C) 2013 by Logical Helion, LLC.

		my $retry;
		my $return_code = 0;
		for($retry = 1; $retry <= $SAFE_MODE_RETRIES; $retry++) {
			my $success = 0;
			# [LH] [2013-11-24]: Replaced try {} otherwise {} block with eval {} or do {}. 
			eval {
				$success = $worker->dbConnect();
				1;
			} or do {
				# actually, if we fail, we do nothing
			};
			if ($success) {
				$return_code = 1;
				last;
			}
			sleep $SAFE_MODE_DELAY;
		}
		if ($DEBUG_MODE && $return_code) {
			print "DATABASE CONNECTION REESTABLISHED!\n";
		} elsif ($DEBUG_MODE) {
			print "DATABASE RECONNECTION ATTEMPTS FAILED!\n";
		}
		if ($return_code) {
# BEGIN CODE Copyright (C) 2013 by Logical Helion, LLC.
			# [LH] [2013-11-24]: Reconnect the main db connection variable before
			# we go back to the main loop.
			$HELIOS_DB_CONN = $worker->dbConnect();
# END CODE Copyright (C) 2013 by Logical Helion, LLC.
			$worker->logMsg(LOG_CRIT, "Exiting SAFE MODE; Reestablished connection to database after exception: ".$e->text);
			$worker->errstr(undef);
			redo MAIN_LOOP;
		} else {
			$worker->errstr("Unable to reconnect to ".$params->{dsn}.": ".$e->text);
			$CLEAN_SHUTDOWN = 0;
			last MAIN_LOOP;
		}
	};
	
} # end of MAIN_LOOP

# shutdown procedures
if ($CLEAN_SHUTDOWN) {
	# if we're cleanly shutting down (we were told to via helios_params_tb)
	# unregister from Helios database
	# remove our PID
    terminator();
} else {
	# if we've had a db error, this will throw an exception when it tries to log to the database
	# BUT BEFORE it does that, the error will have been logged to the local syslog daemon
	$worker->logMsg(LOG_ERR,"$0 $worker_class HALTED on error: ".$worker->errstr);
}

if ($DEBUG_MODE) { print "$0 $worker_class HALTED!\n"; }

exit();


=head1 SUBROUTINES

The helios.pl program calls several of its own functions at various times
during startup, shutdown, and during main loop operation.  These are probably
only of limited interest, but are documented here for those wanting to
understand better the guts of the helios.pl daemon. 

=head1 PROCESS CONTROL FUNCTIONS

=head2 daemonize() 

The daemonize() function is called to turn the Helios program into a daemon 
servicing jobs of a particular class.  It forks a new process, which disconnects
from the launching terminal.

Normally, daemonization would also include setting up signal handling, but the 
daemonize() function isn't called in debug mode, so signal traps are actually 
set up in the main program.

=cut

sub daemonize {
    # prep system interaction stuff
    # attempt to be a good daemon (unlike in the past) 
    chdir File::Spec->rootdir();
    # don't think I need these w/close()ing them below, 
    # but I'll put them in for perlipc's sake anyway
    open STDIN, '/dev/null';
    open STDOUT, '>/dev/null';
    open STDERR, '>/dev/null';
    
	my $pid = fork;   
	# make sure fork was successful
	unless ( defined($pid) ) {
		die "Cannot daemonize: $!";
	}

	# we forked, but are we parent or child?
	if ($pid) {
		# we got a PID, so we're the parent ("shell-called process")
		# print a nice message about daemonizing and exit
		print "$worker_class daemon launched.\n";
		exit();
	} 

	# we got 0, so we're the "child", or the parent daemon
	# we need to write our PID out to a file 
	# and then disconnect completely from the shell
	write_pid_file($params->{pid_path}) or die($worker->errstr);

	# Detach from the shell entirely by setting our own
	# session and making our own process group
	# as well as closing any standard open filehandles.
	POSIX::setsid();
#	close (STDIN); 
#	close (STDOUT); 
#	close (STDERR);

	# set up signal handling in main process 
}


=head2 double_clutch() 

The double_clutch() function implements the WORKER_MAX_TTL functionality.  If 
the WORKER_MAX_TTL parameter is set for a service, the service daemon 
periodically calls double_clutch() to check the workers and clean up any that 
have run too long.  The double_clutch() function waits a certain amount of time 
(WORKER_MAX_TTL_WAIT_INTERVAL secs), then checks the amount of time each of the 
running workers has been active.  If a worker has been running longer than the 
service's WORKER_MAX_TTL, the worker is killed (by sending it a SIGKILL signal).

=cut

sub double_clutch {
# BEGIN CODE Copyright (C) 2012 by Logical Helion, LLC.
	# check each running worker to see if it has been running too long
	# (too long:  WORKER_MAX_TTL seconds + WORKER_MAX_TTL_WAIT_INTERVAL "fudge factor")
# END CODE Copyright (C) 2012 by Logical Helion, LLC.
    foreach my $pid (keys %workers) {
# BEGIN CODE Copyright (C) 2012 by Logical Helion, LLC.
        my $time_to_die = $workers{$pid} + $params->{WORKER_MAX_TTL} + $WORKER_MAX_TTL_WAIT_INTERVAL;
# END CODE Copyright (C) 2012 by Logical Helion, LLC.
        if ( time() > $time_to_die ) {
            kill 9, $pid;
            delete $workers{$pid};
            $worker->logMsg(LOG_ERR, "Killed process $pid (exceeded WORKER_MAX_TTL)");
        }
    }
    return 1;
}


=head2 launch_worker()

The launch_worker() function launches a new worker process.  
After the fork() from the main process, the new child process will call 
launch_worker() to instantiate and configure a new L<Helios::TS> job queuing
system object and start the worker on its way by calling the object's work() 
method.  If the OVERDRIVE run mode is enabled for the service, the 
work_until_done() method is called instead.  See L<Helios::Configuration> for
information about running workers in OVERDRIVE vs. Normal Mode.

=cut

sub launch_worker {
    # just in case this would cause a problem in worker process
    $SIG{CHLD} = 'DEFAULT';
    $SIG{TERM} = 'DEFAULT';
 
# BEGIN CODE Copyright (C) 2012-3 by Logical Helion, LLC.
	# [LH] [2013-09-21]: Added code to enable job prioritization features in Helios::TheSchwartz.
	# [LH] [2013-10-04]: Virtual jobtypes:  switched to using Helios::TS.
	my Helios::TS $client = Helios::TS->new(
		databases  => $DATABASES_INFO,
		prioritize => defined($params->{PRIORITIZE_JOBS}) ? $params->{PRIORITIZE_JOBS} : $DEFAULTS{PRIORITIZE_JOBS}
	);
# END CODE Copyright (C) 2012-3 by Logical Helion, LLC.
	$client->can_do($worker_class);
# BEGIN CODE Copyright (C) 2013 by Logical Helion, LLC.
	# [LH] [2013-10-04]: Virtual jobtypes:  Set up Helios::TS object with 
	# alt jobtypes and designate the "Active Worker Class" (the service class
	# that is actually running the jobs).
	if ($worker->getAltJobTypes) {
		$client->set_active_worker_class($worker_class);
		for ($worker->getAltJobTypes) {
			$client->can_do($_);
		}
	}
# END CODE Copyright (C) 2013 by Logical Helion, LLC.
	my $return;
	if ( defined($params->{OVERDRIVE}) && $params->{OVERDRIVE} == 1 ) {
		$return = $client->work_until_done();			
	} else {
		$return = $client->work_once();
	}
	exit($return);
}


=head1 SIGNAL HANDLERS

=head2 reaper()

The reaper() function is responsible for cleaning up after dead child processes.  It's called when 
helios.pl receives a SIG_CHLD signal.  The function reaps any children with waitpid(), removes the 
children's PID from the $workers hash of running workers, and re-establishes itself as the signal 
handler for the next SIG_CHLD signal.

=cut

sub reaper {
	my $pid;
	if ($DEBUG_MODE) { print "REAPING!\n"; }
	while (($pid = waitpid(-1, &WNOHANG)) > 0) {
		if ($pid == -1) {
			if ($DEBUG_MODE) { print "REAPED IGNORING\n"; }
			# no child waiting.  Ignore it.
		} elsif (WIFEXITED($?)) {
			delete $workers{$pid};
			if ($DEBUG_MODE) { print "REAPED Process $pid exited.\n"; }
			if ($DEBUG_MODE) { print "REAPED $pid: $?\n"; }
		} else {
			if ($DEBUG_MODE) { print "REAPED False alarm on $pid.\n" }
		}
	}
	if ($DEBUG_MODE) { print "FINISHED REAPING\n"; }
	$SIG{CHLD} = \&reaper;
	if ($DEBUG_MODE) { print "EXIT REAPER!\n"; }
}


=head2 terminator()

The terminator() function is responsible for shutting down a Helios service 
instance when helios.pl receives a SIGTERM signal.  The shutdown process 
performs several steps:

=over 4

=item * 

Sets HALT in the Helios config params for the loaded service, so the 
worker processes know to exit at the end of their current job

=item * 

Sleeps a certain amount of time (zero_launch_interval x 2 secs) to 
allow worker processes to complete the jobs they are processing and exit

=item * 

Reaps any ended worker processes, and forcably kills any that are still 
running.  After zero_launch_interval seconds, workers for a particular service 
should have exited if HALT is set.  If you use this method of shutting down 
Helios services and repeatedly see a particular service's workers not exiting 
properly, increase the value of the zero_launch_interval configuration 
parameter for that service in your helios.ini or Helios::Panoptes Ctrl Panel. 

=item * 

Clears the HALT parameter set earlier, since all of the workers are now 
shut down (one way or the other).

=item * 

Removes the service's PID file written in the pid_path set in 
helios.ini

=item * 

Unregister's with the Helios collective's registry table in the Helios
database

=item * 

Issues a final log message indicating the loaded service has shut down 
on the current host

=back

Once all these steps are complete, the helios.pl program exits.


=cut

sub terminator {
    my $TERM = 0;
    # did we receive a SIGTERM, or was the HALT config param set?
    if ( defined($params->{HALT}) ) {
        $worker->logMsg(LOG_NOTICE, "HALTING $OPT_CLASS on host ".$worker->getHostname());
    } else {
        # tell the workers they need exit
        $TERM = 1;
        $worker->logMsg(LOG_NOTICE, "Received TERM signal; HALTING $OPT_CLASS on host ".$worker->getHostname());
        $worker->logMsg(LOG_NOTICE, "Setting HALT for $OPT_CLASS on host ".$worker->getHostname());
        set_halt();
    }

    # sleep long enough for the workers to shutdown on their own
    $SIG{CHLD} = 'DEFAULT';
    sleep $ZERO_LAUNCH_INTERVAL;
    sleep $ZERO_LAUNCH_INTERVAL;
    # reap any processes that ended while we were sleeping
    $worker->logMsg(LOG_NOTICE, "Reaping $OPT_CLASS workers on host ".$worker->getHostname());
    reaper();
    
    # kill any workers still running (they've had plenty of time to end on their own)
    foreach my $pid (keys %workers) {
        if ( kill 0 => $pid ) {
            # it's still alive, kill it
            kill 9, $pid;
            $worker->logMsg(LOG_ERR, "Killed process $pid (shutdown $OPT_CLASS instance)");
        }
        delete $workers{$pid};
    }
       
    # workers are all taken care of, shutdown ourself
    # only clear the HALT if we received a SIGTERM (we set the halt ourselves)
    if ($TERM) { 
        clear_halt(); 
        $worker->logMsg(LOG_NOTICE, "Cleared HALT for $OPT_CLASS on host ".$worker->getHostname());
    }
    clean_shutdown();
    $worker->logMsg(LOG_NOTICE, "$OPT_CLASS on host ".$worker->getHostname().' HALTED.');
    exit(1);
}


# [LH] 2013-08-04:  Added 2nd paragraph to write_pid_file() documentation to 
# help explain how new running_process_check()/write_pid_file() works.

=head1 PID FILE FUNCTIONS

=head2 write_pid_file($pid_path)

Writes a PID file to a location (defaults to /var/run/helios) to track which daemons are 
running.  The file will be named after the service class running, all lowercase, with colons 
replaced by underscores.  For example, the PID file for a service class named 
'SearchIndex::LoadTestWorker' will be named "searchindex__loadtestworker.pid".  To change the 
location where the PID file is created, set the pid_path option in helios.ini.

The running_process_check() function should be run before this function to 
exclusively lock the PID file.

=cut

sub write_pid_file {
# BEGIN CODE Copyright (C) 2013 Logical Helion, LLC.	
	# [LH] 2013-08-04:  Rewrote write_pid_file() to take advantage of the 
	# exclusive lock on the pidfile created by running_process_check().
	# [RT81914]

	# Rewind the PID file handle opened by running_process_check(),
	# write our own PID in the file, and 
	# signal to the calling routine it's OK to finish start up.
	seek($PID_FILE_H, 0, 0) or do {
		$worker->errstr("Cannot rewind $PID_FILE: ".$!);
		close($PID_FILE_H);
		return 0;
	};
	print $PID_FILE_H $$,"\n";
	truncate($PID_FILE_H, tell($PID_FILE_H)) or do {
		$worker->errstr("Cannot truncate $PID_FILE after writing PID: ".$!);
		close($PID_FILE_H);
		return 0;
	};
	close($PID_FILE_H);
# END CODE Copyright (C) 2013 Logical Helion, LLC

	return 1;
}


=head2 remove_pid_file($pid_file)

During a clean shutdown, remove_pid_file() is called to delete the PID file 
associated with the service daemon.

=cut

sub remove_pid_file {
	my $pid_file = shift;
	unless ( defined($pid_file) ) {
		$pid_file = $PID_FILE;
	}
	unlink $pid_file or do { $worker->errstr("Cannot remove PID file $pid_file: ".$!); return undef; };
	return 1;
}


# [LH] 2013-08-04: Added 2nd paragraph below to explain how new running_process_check() works.

=head2 running_process_check($pid_path)

Given the pid_path, check to see if a $pid_file for the loaded service class exists and, if it does,
check to see if that process is still running.  If the file doesn't exist or it does but isn't 
running, this function returns 0.  If the process is still running, record the error and return the 
running process's pid to signal that service startup should halt. 

If the PID file does not exist, running_process_check() creates it.  The PID 
file is then exclusively locked to prevent other daemons for the same service 
from writing to it.  This helps ensure multiple Helios daemons for same 
service will not start up at the same time.

=cut

sub running_process_check {
	my $pid_path = shift;
	# Determine where the PID file should be
	unless (defined($pid_path) ) { $pid_path = $DEFAULTS{PID_PATH}; }

	# Determine PID filename
	my $filename = lc($worker_class);
	$filename =~ s/\:/\_/g;
	$PID_FILE = File::Spec->catfile($pid_path, $filename.'.pid');
	if ($DEBUG_MODE) { print "Checking $PID_FILE\n"; }

	# check if this file exists
	# if it does, check if that process is still running
	# bail if it is
# BEGIN CODE Copyright (C) 2013 Logical Helion, LLC.
	# [LH] 2013-08-04:  Rewrote this piece of running_process_check() to put 
	# an exclusive lock on the pidfile (also creating it if it doesn't exist).
	# Also switched to using the relatively portable Perl kill() instead of 
	# grep-ing shell output to determine whether the process in the pidfile
	# is still running.  [RT81914]
	sysopen($PID_FILE_H, $PID_FILE, O_RDWR | O_CREAT) or do {
		$worker->errstr("Cannot open $PID_FILE: ".$!);
		return 1;		
	};
	flock($PID_FILE_H, LOCK_EX | LOCK_NB) or do {
		$worker->errstr("Cannot lock $PID_FILE (another daemon already starting for this service?): ".$!);
		close($PID_FILE_H);
		return 1;
	};
	
	my $pid_in_file = <$PID_FILE_H>;
	chomp $pid_in_file if defined($pid_in_file);
	# if there's an actual, valid pid in the file, 
	# check to see if that process is still running
	if ( defined($pid_in_file) && $pid_in_file !~ /\D/ && $pid_in_file > 1) {
		my $proc_count = kill 0, $pid_in_file;
		if ($proc_count > 0) {
			$worker->errstr($worker->getJobType()." service daemon already running (process ".$pid_in_file.").");
			close($PID_FILE_H);
			return $pid_in_file;
		}
	}
	
# END CODE Copyright (C) 2013 Logical Helion, LLC.
	
	return 0;
}


=head1 OTHER FUNCTIONS

=head2 clean_shutdown()

The clean_shutdown function is called when helios.pl is intentionally shutdown 
(setting a HALT parameter in the Helios::Panoptes Ctrl Panel or sending the 
helios.pl process a TERM signal).  It removes the PID file created on 
startup and unregisters the service instance from the collective database.

=cut 

sub clean_shutdown {
	remove_pid_file() or $worker->logMsg(LOG_CRIT, $worker->errstr);
	unregister() or $worker->logMsg(LOG_CRIT, $worker->errstr);
	return 1;
}


=head2 register()

The register() function records information about the currently running worker daemon in the 
database.  The register() function is designed to be run every $REGISTRATION_INTERVAL seconds.  
That way, if a service daemon dies off unexpectedly (without calling unregister()), it can be 
determined that something has happened to the daemon and it possibly needs to be restarted.

(In reality, register() and unregister() are only necessary to provide a display for Panoptes, 
to more easily assess system status and facilitate the HALTing of service daemons or HOLDing of 
job processing.)

=cut

sub register {
	# [LH] [2013-10-18]: Replaced try {} block with eval {}.
	eval {
		my $dbh = $worker->dbConnect();
		$dbh->do("DELETE FROM helios_worker_registry_tb WHERE worker_class = ? AND host = ?", undef, 
					$worker->getJobType(), $worker->getHostname) or die;
		$dbh->do("INSERT INTO helios_worker_registry_tb (register_time, start_time, worker_class, worker_version, host, process_id) VALUES (?,?,?,?,?,?)", undef,
					time(), $START_TIME, $worker->getJobType(), $worker->VERSION, $worker->getHostname, $$) or die;
		1;
	} or do {
		throw Helios::Error::DatabaseError($DBI::errstr);
	};
	return 1;
}


=head2 unregister()

The unregister() function removes any record of the currently running daemon from the database.  
It is called whenever there is a clean shutdown.

=cut

sub unregister {
	# [LH] [2013-10-18]: Replaced try {} block with eval {}.
	eval {
		my $dbh = $worker->dbConnect();
		$dbh->do("DELETE FROM helios_worker_registry_tb WHERE worker_class = ? AND host = ?", undef, 
					$worker->getJobType(), $worker->getHostname) or die;
		$dbh->disconnect();
		1;
	} or do {
		throw Helios::Error::DatabaseError($DBI::errstr);
	};
	return 1;
}


=head2 set_halt()

Set a HALT parameter for the currently loaded service on the current host to 
signal to all of the worker processes that they need to exit.  This function is 
used by the terminator() function to safely signal to workers they need to exit
when the current job is completed.

=cut

sub set_halt {
	# [LH] [2013-10-18]: Replaced try {} block with eval {}.
	eval {
		if ($DEBUG_MODE) { 
			print "Attempting to set HALT for ",$worker->getJobType()," on ",$worker->getHostname(),"\n"; 
		}
		my $dbh = $worker->dbConnect();
		$dbh->do("INSERT INTO helios_params_tb (worker_class, host, param, value) VALUES (?,?,?,?)", undef, 
					$worker->getJobType(), $worker->getHostname, 'HALT', '1');
		1;
	} or do {
		throw Helios::Error::DatabaseError($DBI::errstr);
	};
	return 1;	
}


=head2 clear_halt()

If the --clear-halt option is specified on the command line, clear_halt() is called to attempt to 
clear the HALT parameter in the HELIOS_PARAMS_TB.  For safety reasons, it only clears a HALT for 
the loaded service class AND the specific host helios.pl is running on; it will not clear a global
HALT parameter (where the host is specified as '*').

=cut

sub clear_halt {
	# [LH] [2013-10-18]: Replaced try {} block with eval {}.
	eval {
		if ($DEBUG_MODE) { 
			print "Attempting to delete HALT for ",$worker->getJobType()," on ",$worker->getHostname(),"\n"; 
		}
		my $dbh = $worker->dbConnect();
		$dbh->do("DELETE FROM helios_params_tb WHERE worker_class = ? AND host = ? AND param = ?", undef, 
					$worker->getJobType(), $worker->getHostname, 'HALT');
		1;
	} or do {
		throw Helios::Error::DatabaseError($DBI::errstr);
	};
	return 1;	
}

# BEGIN CODE Copyright (C) 2012 by Logical Helion, LLC.
# [LH] 2012-10-12: Added this method to more securely load module code at runtime.

sub require_module {
	my $service_class = shift;
	
	if ( $service_class !~ /^[A-Za-z]([A-Za-z0-9_\-]|:{2})*[A-Za-z0-9_\-]$/ ) {
		print STDERR "Sorry, requested name is invalid: $service_class\n";
		exit(1);
	}
	unless ( $service_class->can('new') ) {
        eval {
        	my $class_file = $service_class;
        	$class_file .= '.pm';
        	$class_file =~ s/::/\//g;
			require $class_file;
			1;
		} or do {
			my $E = $@;
			print STDERR "Perl module $service_class could not be loaded: $E\n";
			exit(1);			
		};
	}
	unless ($service_class->isa('Helios::Service')) {
		print STDERR "$service_class is not a subclass of Helios::Service.\n";
		exit(1);
	}
	return 1;
}

# END CODE Copyright (C) 2012 by Logical Helion, LLC.

# BEGIN CODE Copyright (C) 2012-4 by Logical Helion, LLC.
# [LH] [2013-09-21]: Code to implement WORKER_LAUNCH_PATTERN feature.
# [LH] [2014-02-28]: Changed algorithm names to:  linear, dynamic, optimistic.
# Wrote documentation for function.

=head2 workers_to_launch($waiting_jobs, $running_workers, $max_workers)

Given the number of waiting jobs, currently running workers, and maximum
workers to launch, workers_to_launch() returns the number of worker processes
helios.pl should launch to correctly handle the current job workload.  There
are several different algorithms helios.pl can use to determine this number,
which is dependent on the environment, available resources, and type of
application.  See L<Helios::Configuration> for the list of possible values and
an explanation of the worker launching algorithms.

=cut

sub workers_to_launch {
	my $waiting_jobs = shift;
	my $running_workers = shift;
	my $max_workers = shift;
	my $wlp = defined($params->{WORKER_LAUNCH_PATTERN}) ? $params->{WORKER_LAUNCH_PATTERN} : $DEFAULTS{WORKER_LAUNCH_PATTERN};

	# how many workers are we able to launch?
	my $available_workers = $max_workers - $running_workers;
	
	# if we cannot launch any more workers, then we cannot launch any workers
	if ( $available_workers <= 0 ) {
		return 0;
	}

	# if the waiting jobs >= max_workers, forget all the launcher patterns and blitz
	if ( $waiting_jobs >= $max_workers ) {
		return $available_workers;
	}

	# ok, we might be able to launch some workers
	SWITCH: {
		# optimistic
		# for big, fast collective databases with lots of short running jobs
		if ( $wlp eq 'optimistic') {
			# launch a worker for each waiting job, 
			# or all available workers
			# whichever is less
			if ( $available_workers < $waiting_jobs ) {
				return $available_workers;
			} else {
				return $waiting_jobs;
			}
		}
		# dynamic
		# for fast collectives that need to launch workers more slowly
		# e.g. an app with a slow or limited shared resource
		# this will be the the Helios 3.x default
		if ( $wlp eq 'dynamic') {
			# launch the difference between running workers and waiting jobs
			# e.g. 14 waiting jobs, 10 workers running, launch 4
			# if waiting jobs exceed available workers, just launch available workers
			my $diff = $waiting_jobs - $running_workers;
			if ( $diff <= 0  ) { $diff = 1; }
			if ( $available_workers < $diff ) {
				return $available_workers;
			} else {
				return $diff;
			}
		}
		# linear
		# for slow collective databases, or apps that only run a 
		# smaller number of jobs, or longer running jobs
		# this was the Helios 2.x default
		if ( $wlp eq 'linear') {
			return 1;
		}
		# the default is actually 'linear'
		return 1;
	}


}

# END CODE Copyright (C) 2012-4 by Logical Helion, LLC.


=head1 SEE ALSO

L<Helios>, L<Helios::Tutorial>, L<Helios::Service>, L<Helios::Configuration>

=head1 AUTHOR

Andrew Johnson, E<lt>lajandy at cpan dotorgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-9 by CEB Toolbox, Inc.

Portions of this software, where noted, are
Copyright (C) 2012-2014 by Logical Helion, LLC.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 WARRANTY

This software comes with no warranty of any kind.

=cut

