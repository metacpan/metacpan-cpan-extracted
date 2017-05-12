#######################################################################
# Created on:  Dec 29, 2005
# Package:     HoneyClient::Manager::VM
# File:        VM.pm
# Description: A SOAP server that provides programmatic access to all
#              VM clients.
#
# CVS: $Id: VM.pm 796 2007-08-07 16:36:16Z kindlund $
#
# @author kindlund
#
# Copyright (C) 2007 The MITRE Corporation.  All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation, using version 2
# of the License.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301, USA.
#
#######################################################################

=pod

=head1 NAME

HoneyClient::Manager::VM - Perl extension to instantiate a SOAP server
that provides programmmatic access to all VM clients within the locally
running VMware Server / GSX server.

=head1 VERSION

This documentation refers to HoneyClient::Manager:VM version 0.99.

=head1 SYNOPSIS

=head2 CREATING THE SOAP SERVER

  use HoneyClient::Manager::VM;

  # Handle SOAP requests on the default address:port.
  my $URL = HoneyClient::Manager::VM->init();

  # Handle SOAP requests on TCP port localhost:9090
  my $URL = HoneyClient::Manager::VM->init(address => "localhost", 
                                           port    => 9090);

  print "Server URL: " . $URL . "\n";

  # Create a cleanup function, to execute whenever
  # the SOAP server needs to be destroyed.
  sub cleanup {
      HoneyClient::Manager::VM->destroy();
      exit;
  }

  # Install the cleanup handler, in case parent process
  # dies unexpectedly.
  $SIG{HUP}       = \&cleanup;
  $SIG{INT}       = \&cleanup;
  $SIG{QUIT}      = \&cleanup;
  $SIG{ABRT}      = \&cleanup;
  $SIG{PIPE}      = \&cleanup;
  $SIG{TERM}      = \&cleanup;

  # Catch all parent code errors, in order to perform cleanup
  # on all child processes before exiting.
  eval {
      # Do rest of the parent processing here...
  };

  # We assume you still want to still want to "die" on
  # any errors found within the eval block.
  if ($@) {
      HoneyClient::Manager::VM->destroy();
      die $@; 
  }

  # Even if no errors occurred, initiate cleanup.
  cleanup();

=head2 INTERACTING WITH THE SOAP SERVER 

  use HoneyClient::Util::SOAP qw(getClientHandle);

  # Create a new SOAP client, to talk to the HoneyClient::Manager::VM
  # module.
  my $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");
  my $som;

  # Enumerate all registered VMs.
  $som = $stub->enumerate();
  my @list = $som->paramsall;
  print "\t$_\n" foreach (@list);
  print "\n";

  # Assume we have a particular VM.
  my $vmConfig = "/path/to/vm.vmx";

  # See if a particular VM is registered.
  $som = $stub->isRegisteredVM(config => $vmConfig);
  if ($som->result) {
      print "Yes, the VM is registered.";
  } else {
      print "No, the VM is not registered.";
  }

  # Register a particular VM.
  $som = $stub->registerVM(config => $vmConfig);
  if ($som->result) {
      print "Success!\n";
  } else {
      print "Failed!\n";
  }

  # Unregister a particular VM.
  $som = $stub->unregisterVM(config => $vmConfig);
  if ($som->result) {
      print "Success!\n";
  } else {
      print "Failed!\n";
  }

  # Get the state of a particular VM.
  use VMware::VmPerl qw(VM_EXECUTION_STATE_ON
                        VM_EXECUTION_STATE_OFF
                        VM_EXECUTION_STATE_STUCK
                        VM_EXECUTION_STATE_SUSPENDED);
  $som = $stub->getStateVM(config => $vmConfig);
  if ($som->result == VM_EXECUTION_STATE_ON) {
      print "ON\n";
  } elsif ($som->result == VM_EXECUTION_STATE_OFF) {
      print "OFF\n";
  } elsif ($som->result == VM_EXECUTION_STATE_SUSPENDED) {
      print "SUSPENDED\n";
  } elsif ($som->result == VM_EXECUTION_STATE_STUCK) {
      print "STUCK\n";
  } else {
      print "UNKNOWN\n";
  }

  # Start a particular VM.
  $som = $stub->startVM(config => $vmConfig);
  if ($som->result) {
      print "Success!\n";
  } else {
      print "Failed!\n";
  }
  
  # Stop a particular VM.
  $som = $stub->stopVM(config => $vmConfig);
  if ($som->result) {
      print "Success!\n";
  } else {
      print "Failed!\n";
  }
  
  # Reboot a particular VM.
  $som = $stub->rebootVM(config => $vmConfig);
  if ($som->result) {
      print "Success!\n";
  } else {
      print "Failed!\n";
  }
  
  # Suspend a particular VM.
  $som = $stub->suspendVM(config => $vmConfig);
  if ($som->result) {
      print "Success!\n";
  } else {
      print "Failed!\n";
  }

  # After starting a particular VM, if the VM's
  # state is STUCK, we can try automatically answering
  # any pending questions that the VMware Server / GSX
  # daemon is waiting for.
  #
  # Note: In most cases, this call doesn't need to
  # be made, since startVM() will try this call
  # automatically, if needed.
  $som = $stub->answerVM(config => $vmConfig);
  if ($som->result) {
      print "Success!\n";
  } else {
      print "Failed!\n";
  }

  # Create a new full clone from a particular VM 
  # and put the clone in the "/vm/TEST" directory.
  my $destDir = "/vm/TEST";
  $som = $stub->fullCloneVM(src_config => $vmConfig, dest_dir => $destDir);
  my $cloneConfig = $som->result;
  if ($som->result) {
      print "Successfully created clone VM at ($cloneConfig)!\n";
  } else {
      print "Failed to create clone!\n";
  }
  
  # Create a new quick clone from a particular VM
  # and put the clone in the "/vm/TEST" directory.
  my $destDir = "/vm/TEST";
  $som = $stub->quickCloneVM(src_config => $vmConfig, dest_dir => $destDir);
  my $cloneConfig = $som->result;
  if ($som->result) {
      print "Successfully created clone VM at ($cloneConfig)!\n";
  } else {
      print "Failed to create clone!\n";
  }
  
  # Set a particular VM to be a master image,
  # allowing us to call quickCloneVM() without
  # any arguments.
  $som = $stub->setMasterVM(config => $vmConfig);
  if ($som->result) {
      print "Success!\n";
  } else {
      print "Failed!\n";
  }

  # Get the name of a particular VM.
  $som = $stub->getNameVM(config => $vmConfig);
  my $dispName = $som->result;
  if ($som->result) {
      print "VM Name: \"$dispName\"\n";
  } else {
      print "Failed to get VM name!\n";
  }

  # Set the name of a particular VM to "BLAH".
  $som = $stub->setNameVM(config => $vmConfig, name => "BLAH");
  my $dispName = $som->result;
  if ($som->result) {
      print "VM Renamed To: \"$dispName\"\n";
  } else {
      print "Failed to rename VM!\n";
  }

  # Get the MAC address of a particular VM's first NIC.
  $som = $stub->getMACaddrVM(config => $vmConfig);
  my $macAddress = $som->result;
  if ($som->result) {
      print "VM MAC Address: \"$macAddress\"\n";
  } else {
      print "Failed to get VM MAC address!\n";
  }
  
  # Get the IP address of a particular VM's first NIC.
  $som = $stub->getIPaddrVM(config => $vmConfig);
  my $ipAddress = $som->result;
  if ($som->result) {
      print "VM IP Address: \"$ipAddress\"\n";
  } else {
      print "Failed to get VM IP address!\n";
  }

  # Destroy a particular VM.
  $som = $stub->destroyVM(config => $vmConfig);
  if ($som->result) {
      print "Success!\n";
  } else {
      print "Failed!\n";
  }

  # Save a snapshot of a particular VM, saving the
  # snapshot to "/path/to/snapshot.tar.gz".
  $som = $stub->snapshotVM(config => $vmConfig, snapshot_file => "/path/to/snapshot.tar.gz");
  my $destSnapshot = $som->result;
  if ($som->result) {
      print "Successfully snapshotted VM at ($destSnapshot)!\n";
  } else {
      print "Failed to snapshot VM!\n";
  }

  # Revert a particular VM back to a previous snapshot,
  # where the snapshot file is located at
  # "/path/to/snapshot.tar.gz".
  $som = $stub->revertVM(config => $vmConfig, snapshot_file => "/path/to/snapshot.tar.gz");
  my $revertConfig = $som->result;
  if ($som->result) {
      print "Successfully reverted VM at ($revertConfig)!\n";
  } else {
      print "Failed to revert VM!\n";
  }

=head1 DESCRIPTION

Once created, the daemon acts as a stand-alone SOAP server,
processing individual requests and manipulating VMs on the 
locally running VMware Server / GSX server.

=cut

package HoneyClient::Manager::VM;

use strict;
use warnings;
use Config;
use Carp ();

# Traps signals, allowing END: blocks to perform cleanup.
use sigtrap qw(die untrapped normal-signals error-signals);

#######################################################################
# Module Initialization                                               #
#######################################################################

BEGIN {
    # Defines which functions can be called externally.
    require Exporter;
    our (@ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS, $VERSION);

    # Set our package version.
    $VERSION = 0.99;

    @ISA = qw(Exporter);

    # Symbols to export automatically
    @EXPORT = qw();

    # Items to export into callers namespace by default. Note: do not export
    # names by default without a very good reason. Use EXPORT_OK instead.
    # Do not simply export all your public functions/methods/constants.

    # This allows declaration use HoneyClient::Manager::VM ':all';
    # If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
    # will save memory.

    %EXPORT_TAGS = ( 
        'all' => [ qw() ],
    );

    # Symbols to autoexport (when qw(:all) tag is used)
    @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

    # Check to see if ithreads are compiled into this version of Perl.
    if (!$Config{useithreads}) {
        Carp::croak "Error: Recompile Perl with ithread support, in order to use this module.\n";
    }

    $SIG{PIPE} = 'IGNORE'; # Do not exit on broken pipes.
}
our (@EXPORT_OK, $VERSION);

=pod

=begin testing

# Make sure ExtUtils::MakeMaker loads.
BEGIN { use_ok('ExtUtils::MakeMaker', qw(prompt)) or diag("Can't load ExtUtils::MakeMaker package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('ExtUtils::MakeMaker');
can_ok('ExtUtils::MakeMaker', 'prompt');
use ExtUtils::MakeMaker qw(prompt);

# Generate a notice, to clarify our assumptions.
diag("About to run basic unit tests.");
diag("Note: These tests *expect* VMware Server or VMware GSX to be installed and running on this system beforehand.");

my $question;
$question = prompt("# Do you want to run basic tests?", "yes");
if ($question !~ /^y.*/i) {
    exit;
}

# Make sure Log::Log4perl loads
BEGIN { use_ok('Log::Log4perl', qw(:nowarn))
        or diag("Can't load Log::Log4perl package. Check to make sure the package library is correctly listed within the path.");
       
        # Suppress all logging messages, since we need clean output for unit testing.
        Log::Log4perl->init({
            "log4perl.rootLogger"                               => "DEBUG, Buffer",
            "log4perl.appender.Buffer"                          => "Log::Log4perl::Appender::TestBuffer",
            "log4perl.appender.Buffer.min_level"                => "fatal",
            "log4perl.appender.Buffer.layout"                   => "Log::Log4perl::Layout::PatternLayout",
            "log4perl.appender.Buffer.layout.ConversionPattern" => "%d{yyyy-MM-dd HH:mm:ss} %5p [%M] (%F:%L) - %m%n",
        });
}
require_ok('Log::Log4perl');
use Log::Log4perl qw(:easy);

# Make sure HoneyClient::Util::Config loads.
BEGIN { use_ok('HoneyClient::Util::Config', qw(getVar))
        or diag("Can't load HoneyClient::Util::Config package.  Check to make sure the package library is correctly listed within the path.");

        # Suppress all logging messages, since we need clean output for unit testing.
        Log::Log4perl->init({
            "log4perl.rootLogger"                               => "DEBUG, Buffer",
            "log4perl.appender.Buffer"                          => "Log::Log4perl::Appender::TestBuffer",
            "log4perl.appender.Buffer.min_level"                => "fatal",
            "log4perl.appender.Buffer.layout"                   => "Log::Log4perl::Layout::PatternLayout",
            "log4perl.appender.Buffer.layout.ConversionPattern" => "%d{yyyy-MM-dd HH:mm:ss} %5p [%M] (%F:%L) - %m%n",
        });
}
require_ok('HoneyClient::Util::Config');
can_ok('HoneyClient::Util::Config', 'getVar');
use HoneyClient::Util::Config qw(getVar);

# Suppress all logging messages, since we need clean output for unit testing.
Log::Log4perl->init({
    "log4perl.rootLogger"                               => "DEBUG, Buffer",
    "log4perl.appender.Buffer"                          => "Log::Log4perl::Appender::TestBuffer",
    "log4perl.appender.Buffer.min_level"                => "fatal",
    "log4perl.appender.Buffer.layout"                   => "Log::Log4perl::Layout::PatternLayout",
    "log4perl.appender.Buffer.layout.ConversionPattern" => "%d{yyyy-MM-dd HH:mm:ss} %5p [%M] (%F:%L) - %m%n",
});

# Make sure the module loads properly, with the exportable
# functions shared.
BEGIN { use_ok('HoneyClient::Manager::VM') or diag("Can't load HoneyClient::Manager:VM package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('HoneyClient::Manager::VM');
can_ok('HoneyClient::Manager::VM', 'init');
can_ok('HoneyClient::Manager::VM', 'destroy');
use HoneyClient::Manager::VM;

# Make sure HoneyClient::Util::SOAP loads.
BEGIN { use_ok('HoneyClient::Util::SOAP', qw(getServerHandle getClientHandle)) or diag("Can't load HoneyClient::Util::SOAP package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('HoneyClient::Util::SOAP');
can_ok('HoneyClient::Util::SOAP', 'getServerHandle');
can_ok('HoneyClient::Util::SOAP', 'getClientHandle');
use HoneyClient::Util::SOAP qw(getServerHandle getClientHandle);

# Make sure File::Basename loads.
BEGIN { use_ok('File::Basename', qw(dirname basename)) or diag("Can't load File::Basename package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('File::Basename');
can_ok('File::Basename', 'dirname');
can_ok('File::Basename', 'basename');
use File::Basename qw(dirname basename);

# Make sure File::Copy::Recursive loads.
BEGIN { use_ok('File::Copy::Recursive', qw(dircopy pathrmdir)) or diag("Can't load File::Copy::Recursive package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('File::Copy::Recursive');
can_ok('File::Copy::Recursive', 'dircopy');
can_ok('File::Copy::Recursive', 'pathrmdir');
use File::Copy::Recursive qw(dircopy pathrmdir);

# Make sure Data::Dumper loads.
BEGIN { use_ok('Data::Dumper') or diag("Can't load Data::Dumper package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('Data::Dumper');
use Data::Dumper;

# Make sure File::stat loads.
BEGIN { use_ok('File::stat') or diag("Can't load File::stat package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('File::stat');
use File::stat;

# Make sure Digest::MD5 loads.
BEGIN { use_ok('Digest::MD5', qw(md5_hex)) or diag("Can't load Digest::MD5 package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('Digest::MD5');
can_ok('Digest::MD5', 'md5_hex');
use Digest::MD5 qw(md5_hex);

# Make sure DateTime::HiRes loads.
BEGIN { use_ok('DateTime::HiRes') or diag("Can't load DateTime::HiRes package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('DateTime::HiRes');
use DateTime::HiRes;

# Make sure Fcntl loads.
BEGIN { use_ok('Fcntl', qw(O_RDONLY)) or diag("Can't load Fcntl package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('Fcntl');
use Fcntl qw(O_RDONLY);

# Make sure VMware::VmPerl loads.
BEGIN { use_ok('VMware::VmPerl', qw(VM_EXECUTION_STATE_ON VM_EXECUTION_STATE_OFF VM_EXECUTION_STATE_STUCK VM_EXECUTION_STATE_SUSPENDED)) or diag("Can't load VMware::VmPerl package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('VMware::VmPerl');
use VMware::VmPerl qw(VM_EXECUTION_STATE_ON VM_EXECUTION_STATE_OFF VM_EXECUTION_STATE_STUCK VM_EXECUTION_STATE_SUSPENDED);

# Make sure VMware::VmPerl::Server loads.
BEGIN { use_ok('VMware::VmPerl::Server') or diag("Can't load VMware::VmPerl::Server package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('VMware::VmPerl::Server');
use VMware::VmPerl::Server;

# Make sure VMware::VmPerl::ConnectParams loads.
BEGIN { use_ok('VMware::VmPerl::ConnectParams') or diag("Can't load VMware::VmPerl::ConnectParams package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('VMware::VmPerl::ConnectParams');
use VMware::VmPerl::ConnectParams;

# Make sure VMware::VmPerl::VM loads.
BEGIN { use_ok('VMware::VmPerl::VM') or diag("Can't load VMware::VmPerl::VM package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('VMware::VmPerl::VM');
use VMware::VmPerl::VM;

# Make sure VMware::VmPerl::VM loads.
BEGIN { use_ok('VMware::VmPerl::Question') or diag("Can't load VMware::VmPerl::Question package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('VMware::VmPerl::Question');
use VMware::VmPerl::Question;

# Make sure threads loads.
BEGIN { use_ok('threads') or diag("Can't load threads package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('threads');
use threads;

# Make sure threads::shared loads.
BEGIN { use_ok('threads::shared') or diag("Can't load threads::shared package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('threads::shared');
use threads::shared;

# Make sure Thread::Queue loads.
BEGIN { use_ok('Thread::Queue') or diag("Can't load Thread::Queue package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('Thread::Queue');
use Thread::Queue;

# Make sure Thread::Semaphore loads.
BEGIN { use_ok('Thread::Semaphore') or diag("Can't load Thread::Semaphore package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('Thread::Semaphore');
use Thread::Semaphore;

diag("About to run extended tests.");
# Generate a notice, to inform the tester that these tests are not
# exactly quick.
diag("Note: These extended tests will take *significant* time to complete (10-30 minutes).");

$question = prompt("# Do you want to run extended tests?", "no");
if ($question !~ /^y.*/i) {
    exit;
}

=end testing

=cut

#######################################################################
# Path Variables                                                      #
#######################################################################

# Include Global Configuration Processing Library
use HoneyClient::Util::Config qw(getVar);

# Include Data Dumper API
use Data::Dumper;

# Include Logging Library
use Log::Log4perl qw(:easy);

# The global logging object.
our $LOG = get_logger();

# Make Dumper format more terse.
$Data::Dumper::Terse = 1;
$Data::Dumper::Indent = 0;

# Default absolute path to use when cloning new VMs.
our $DATASTORE_PATH = getVar(name => "datastore_path");

# Default absolute path to use when storing snapshots.
our $SNAPSHOT_PATH = getVar(name => "snapshot_path");

# Make sure the $DATASTORE_PATH is a valid directory and exists.
if (!-d $DATASTORE_PATH) {
    $LOG->fatal("Current datastore path ($DATASTORE_PATH) does not exist!");
    Carp::croak "Error: Current datastore path ($DATASTORE_PATH) does not exist!\n";
}

# Make sure the $SNAPSHOT_PATH is a valid directory and exists.
if (!-d $SNAPSHOT_PATH) {
    $LOG->fatal("Error: Current datastore path ($SNAPSHOT_PATH) does not exist!");
    Carp::croak "Error: Current datastore path ($SNAPSHOT_PATH) does not exist!\n";
}
#######################################################################

# Include the SOAP Utility Library
use HoneyClient::Util::SOAP qw(getServerHandle getClientHandle);

# Include the VMware APIs
use VMware::VmPerl;
use VMware::VmPerl::Server;
use VMware::VmPerl::ConnectParams;
use VMware::VmPerl::VM;
use VMware::VmPerl::Question;

# Include POSIX Libraries
use POSIX qw(strftime);

# Include File/Directory Manipulation Libraries
use File::Copy;
use File::Copy::Recursive qw(dircopy pathrmdir);
use File::Basename qw(dirname basename);
use Tie::File;
use Fcntl qw(O_RDONLY);

# Include Thread Libraries
use threads;
use threads::shared;
use Thread::Queue;
use Thread::Semaphore;

# Include MD5 Libraries
use Digest::MD5 qw(md5_hex);

# Include ISO8601 Date/Time Library
use DateTime::HiRes;

# Global fault queue.
# Used to convey faults that have occurred within
# asynchronous threads back to synchronous, external
# function calls.
our $faultQueue = Thread::Queue->new();

# Global semaphore, designed to limit the maximum
# number of child threads that run.
#
# By default, we limit the number of children to 5.
# If more than 5 child threads are created, subsequent 
# ones will block, until one of the running threads
# finishes.
our $maxThreadSemaphore = Thread::Semaphore->new(5);

# Hashtable used to contain VM-specific semaphores,
# used to guarantee only one operation per VM is performed
# at any given time.
our %vmSemaphoreHash;

# Global semaphore, designed to limit exclusive access
# to the %vmSemaphoreHash object. This lock is designed
# to prevent multiple threads from creating/deleting entries
# simultaneously, which would cause nasty race conditions.
our $hashSemaphore = Thread::Semaphore->new(1);

# Global semaphore, designed to guarantee only one thread
# may set the master VM configuration file at any given
# time.
our $masterVMSemaphore = Thread::Semaphore->new(1);

# Global semaphore, designed to allow only 1 thread
# at a time to perform chdir operations.
our $chdirSemaphore = Thread::Semaphore->new(1);

# Constants used to authenticate with the VMware Server / 
# GSX server.
# If username and password are left undefined,
# the process owner's credentials will be used.
our $serverName     : shared = undef;
our $tcpPort        : shared = getVar(name => "vmware_port");
our $username       : shared = undef;
our $passwd         : shared = undef;

# VmPerl Objects used only by the parent thread.
our $server         = undef;
our $connectParams  = undef;
our $vm             = undef;

# Path to master config file, for eventual cloning.
our $vmMasterConfig : shared = undef;

# Complete URL of SOAP server, when initialized.
our $URL_BASE       : shared = undef;
our $URL            : shared = undef;

# If connectivity to the VMware Server / GSX server is 
# ever lost, this indicates how may reconnection attempts 
# will be made before failing completely.
our $MAX_RETRIES    : shared = 5;

# The process ID of the SOAP server daemon, once created.
our $DAEMON_PID     : shared = undef;

# The maximum length of any VMID generated.
our $VM_ID_LENGTH   : shared = getVar(name => "vm_id_length");

# The log file that contains DHCP lease log entries.
our $DHCP_LOGFILE   : shared = getVar(name => "dhcp_log");

#######################################################################
# Daemon Initialization / Destruction                                 #
#######################################################################

=pod

=head1 LOCAL FUNCTIONS

The following init() and destroy() functions are the only direct
calls required to startup and shutdown the SOAP server.

All other interactions with this daemon should be performed as
C<SOAP::Lite> function calls, in order to ensure consistency across
client sessions.  See the L<"EXTERNAL SOAP FUNCTIONS"> section, for
more details.

=head2 HoneyClient::Manager::VM->init(address => $localAddr, port => $localPort)

=over 4

Starts a new SOAP server, within a child process.

I<Inputs>:
 B<$localAddr> is an optional argument, specifying the IP address for the SOAP server to listen on.
 B<$localPort> is an optional argument, specifying the TCP port for the SOAP server to listen on.

I<Output>: The full URL of the web service provided by the SOAP server.

=back

=begin testing

# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Test init() method.
$URL = HoneyClient::Manager::VM->init();
is($URL, "http://localhost:$PORT/HoneyClient/Manager/VM", "init()") or diag("Failed to start up the VM SOAP server.  Check to see if any other daemon is listening on TCP port $PORT.");

=end testing

=cut

sub init {
    # Extract arguments.
    my ($class, %args) = @_;

    # Sanity check.  Make sure the daemon isn't already running.
    if (defined($DAEMON_PID)) {
        $LOG->fatal( __PACKAGE__ . " daemon is already running (PID = $DAEMON_PID)!");
        Carp::croak "Error: " . __PACKAGE__ . " daemon is already running (PID = $DAEMON_PID)!\n";
    }

    my $argsExist = scalar(%args);

    if (!($argsExist &&
          exists($args{'address'}) &&
          defined($args{'address'}))) {
        $args{'address'} = getVar(name => "address");
    }

    if (!($argsExist &&
          exists($args{'port'}) &&
          defined($args{'port'}))) {
        $args{'port'} = getVar(name => "port");
    }


    $URL_BASE = "http://" . $args{'address'} . ":" . $args{'port'};
    $URL = $URL_BASE . "/" . join('/', split(/::/, __PACKAGE__));

    my $pid = undef;
    if ($pid = fork()) {

        # Wait at least a second, in order to initialize the daemon.
        sleep (1);
        $DAEMON_PID = $pid;
        return ($URL);

    } else {

        # Make sure the fork was successful.
        if (!defined($pid)) {
            $LOG->fatal("Error: Unable to fork child process. $!");
            Carp::croak "Error: Unable to fork child process.\n$!";
        }

        # Do not attempt to rejoin parent process tree,
        # if any type of termination signal is received.
        local $SIG{HUP} = sub { exit; };
        local $SIG{INT} = sub { exit; };
        local $SIG{QUIT} = sub { exit; };
        local $SIG{ABRT} = sub { exit; };
        local $SIG{PIPE} = sub { exit; };
        local $SIG{TERM} = sub { exit; };

        my $daemon = getServerHandle(address => $args{'address'},
                                     port    => $args{'port'});

        for (;;) {
            $daemon->handle();
        }
    }
}

=pod

=head2 HoneyClient::Manager::VM->destroy()

=over 4

Terminates the SOAP server within the child process.

I<Output>: True if successful, false otherwise.

=back

=begin testing

# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Test destroy() method.
is(HoneyClient::Manager::VM->destroy(), 1, "destroy()") or diag("Unable to terminate VM SOAP server.  Be sure to check for any stale or lingering processes.");

=end testing

=cut

sub destroy {
    my $ret = undef;
    # Make sure the PID is defined and not
    # the parent process...
    if (defined($DAEMON_PID) && $DAEMON_PID) {
        $ret = kill("QUIT", $DAEMON_PID);
    }
    if ($ret) {
        $DAEMON_PID = undef;
    }
    return ($ret);
}

#######################################################################
# Private Methods Implemented                                         #
#######################################################################

# Helper function designed to connect to a specified VM.
# Requires specifying the full, absolute
# path to the VM's local configuration file.
#
# Inputs: config
# Outputs: None
sub _connectVM {
    # Extract arguments.
    my ($class, $config) = @_;

    # Sanity check. Make sure we're connected.
    if (!defined($server) || !defined($server->is_connected())) {
        _connect();
    }

    # If possible, reuse the preexisting VM connection.
    if (defined($vm) && 
        $vm->is_connected() && 
        ($vm->get_config_file_name() eq $config)) {
        return;
    }

    # If we're trying to connect up to an unregistered VM, go ahead
    # and register it...
    if (!isRegisteredVM($class, (config => $config))) {
        registerVM($class, (config => $config));
    }

    $vm = VMware::VmPerl::VM::new();

    # Connect to the VM, using the same ConnectParams object.
    # Throttle repeat connections to the VMware Server / GSX server.
    my $count    = 0;
    my $status = undef;
    do {
        sleep (2);
        $status = $vm->connect($connectParams, $config);
        $count++;
    } while (!$status && $count < $MAX_RETRIES);
    if ($count >= $MAX_RETRIES) {
        my ($errorNumber, $errorString) = $server->get_last_error();
        $LOG->warn("Could not connect to VM (" . $config . "). (" .
                   $errorNumber . ": " . $errorString . ")");
        die SOAP::Fault->faultcode(__PACKAGE__ . "->_connectVM()")
                       ->faultstring("Could not connect to VM ($config).")
                       ->faultdetail(bless { errNo  => $errorNumber,
                                             errStr => $errorString },
                                     'err');
    }
}

# Helper function designed to disconnect from a previously specified VM.
#
# Inputs: None
# Outputs: None
sub _disconnectVM {
    undef $vm;
}

# Helper function designed to emit the first queued fault.
# If any exist, automatically die with the earliest queued fault.
#
# Inputs: None
# Outputs: None
sub _emitQueuedFault {

    my $fault = $faultQueue->dequeue_nb();
    if (defined($fault)) {
        my $deserializer = SOAP::Deserializer->new();
        my $som = $deserializer->deserialize($fault);
        if (defined($som->faultdetail)) {
            die SOAP::Fault->faultcode($som->faultcode)
                           ->faultstring($som->faultstring)
                           ->faultdetail(bless { errNo  => $som->faultdetail->{"err"}->{"errNo"},
                                                 errStr => $som->faultdetail->{"err"}->{"errStr"} },
                                         'err');
        } else {
            die SOAP::Fault->faultcode($som->faultcode)
                           ->faultstring($som->faultstring);
        }
    }
}

# Helper function designed to store faults in a globally shared queue.A
# Faults are serialized into XML form, then stored in the queue.
#
# Inputs: SOAP::Fault
# Outputs: None
sub _queueFault {

    my $fault = shift;
    my $serializer = SOAP::Serializer->new();
    my $xml = $serializer->fault($fault->faultcode, 
                                 $fault->faultstring, 
                                 $fault->faultdetail, 
                                 $fault->faultactor);
    $faultQueue->enqueue($xml);
}

# Helper function designed to return true if the "$serverName"
# is local; useful for functions that are designed to perform
# filesystem operations that can only be performed on a local
# server.
#
# Inputs: None
# Outputs: True if server is local, false otherwise. 
sub _isServerLocal {
    
    return (!defined($serverName) || 
            $serverName eq "localhost" ||
            $serverName =~ /^127\.\d{1,3}\.\d{1,3}\.\d{1,3}$/);
}

# Helper function used by child threads to handle faults that
# occur during callbacks made to the parent SOAP server.
#
# When a fault is handled, it is converted back into a SOAP::Fault
# object and subsequently queued for final emission by the
# parent upon subsequent remote calls.
#
# Inputs: SOAP::SOM
# Outputs: None
sub _callbackFaultHandler {

    # Extract arguments.
    my ($class, $res) = @_;

    # Reconstruct the SOAP::Fault.
    # Figure out if the error occurred in transport or
    # over on the other side.
    my $errMsg = $class->transport->status; # Assume transport error.
    if (ref $res) {
        
        if (defined($res->faultdetail)) {
            # Detailed fault occurred.
            die SOAP::Fault->faultcode($res->faultcode)
                           ->faultstring($res->faultstring)
                           ->faultdetail(bless { errNo  => $res->faultdetail->{"err"}->{"errNo"},
                                                 errStr => $res->faultdetail->{"err"}->{"errStr"} },
                                         'err');
        } else {
            # Basic fault occurred.
            die SOAP::Fault->faultcode($res->faultcode)
                           ->faultstring($res->faultstring);
        }    
    } else {
        # Transport error occurred.
        # Queue a generic transport fault.
        $LOG->warn($errMsg);
        die SOAP::Fault->faultcode(__PACKAGE__ . "->_callbackFaultHandler()")
                       ->faultstring($errMsg);

    }
}

# Helper function designed to allow asynchronous child threads to perform
# callbacks to the parent thread using atomic SOAP requests.
#
# It is assumed that the callback is successful, if and only if no faults
# are generated.
#
# Note: Beware, recursive loops can occur, if a child thread calls another 
# function that creates more children!  Specifically, beware of calling
# the filesystem-intensive functions listed within the POD documentation.
#
# Input: funcName, args
# Output: None
sub _callback {
    
    # Extract arguments.
    my $class = shift;
    my $funcName = shift;

    # Create the client object.
    my $stub = getClientHandle(fault_handler => \&_callbackFaultHandler);

    # Initiate SOAP command.
    my $som = $stub->$funcName(@_);

    threads->yield();
}

# Helper function designed to retrieve the semaphore lock for
# a specific VM, in order to perform exclusive operations on
# the specified VM.  This function blocks the calling thread,
# whenever semaphore retrieval cannot be guaranteed.
#
# If the VM is brand new, this function will create a new
# semaphore and add it to our global hashtable for easy
# access.
#
# Input: config
# Output: vmSemaphore 
sub _getVMlock {

    # Extract arguments.
    my ($class, $config) = @_;
    my $vmSemaphore = undef;

    $hashSemaphore->down();

    # Check to see if the hash key exists...
    if (!exists($vmSemaphoreHash{$config})) {
        # Semaphore does not exist, create it.
        $vmSemaphoreHash{$config} = Thread::Semaphore->new(1);
    }
        
    $vmSemaphore = $vmSemaphoreHash{$config};

    $hashSemaphore->up();

    return ($vmSemaphore);
}

# Helper function designed to retrieve the semaphore lock for
# a specific VM, in order to perform exclusive operations on
# the specified VM.  This function blocks the calling thread,
# whenever semaphore retrieval cannot be guaranteed.
#
# If the VM's semaphore was found, it will be removed from the
# global hashtable, prior to returning the extracted semaphore.
#
# If the VM's semaphore does not exist in the global hashtable,
# then undef will be returned.
#
# Input: config
# Output: None
sub _destroyVMlock {
    
    # Extract arguments.
    my ($class, $config) = @_;
    my $vmSemaphore = undef;
    
    $hashSemaphore->down();

    # Check to see if the hash key exists...
    if (exists($vmSemaphoreHash{$config})) {
        $vmSemaphore = $vmSemaphoreHash{$config};
        delete $vmSemaphoreHash{$config};
    }

    $hashSemaphore->up();
    
    return ($vmSemaphore);
}

# Connects to the specified host.
#
# Inputs: serverName, tcpPort, username, passwd 
# Outputs: None
sub _connect {

    # Extract arguments.
    my $class = shift;
    ($serverName, $tcpPort, $username, $passwd) = @_;
    
    # Sanity check.  Make sure there are no queued faults.
    _emitQueuedFault();
    

    # Define the parameters used to connect to the VMware Server / GSX server.
    # If any of these parameters are undefined, defaults will be used.
    # For example, the process owner's credentials will be used
    # for username/passwd if undefined.
    $connectParams = VMware::VmPerl::ConnectParams::new($serverName, $tcpPort, $username, $passwd);
    
    # Establish a persistent connection with server.
    $server = VMware::VmPerl::Server::new();
    
    # Check to make sure we're connected.
    if (!$server->connect($connectParams)) {
        my ($errorNumber, $errorString) = $server->get_last_error();
        $LOG->warn("Could not connect to host system \"" . $serverName .
                   "\". (" . $errorNumber . ": " . $errorString . ")");
        die SOAP::Fault->faultcode(__PACKAGE__ . "->_connect()")
                       ->faultstring("Could not connect to host system \"" . $serverName . "\".")
                       ->faultdetail(bless { errNo  => $errorNumber,
                                             errStr => $errorString },
                                     'err');
    }
}

# Disconnects from the host.
#
# Inputs: None
# Outputs: None
sub _disconnect {
    # Disconnect from any connected VMs.
    _disconnectVM();

    # Destroys the server object, thus disconnecting from the server.
    undef $server;
    
    # Sanity check.  Make sure there are no queued faults.
    _emitQueuedFault();
}

# Helper function, designed to generate a new unique VM ID that persists
# across snapshot operations and any other VM migrations.
#
# Note: This code was taken from the Apache::SessionX::Generate::MD5
# package.  It was replicated here, to avoid unwanted dependencies.
#
# The resultant VMID is a hexadecimal string of length $VM_ID_LENGTH
# (where this length is between 1 and 32, inclusive).  These VMIDs
# are supposed to be unique, so it is recommended that $VM_ID_LENGTH
# be as large as possible.
#
# The VMIDs are generated using a two-round MD5 of a random number,
# the time since the epoch, the process ID, and the address of an
# anonymous hash.  The resultant VMID string is highly entropic on
# Linux and other platforms that have good random number generators.
#
# Inputs: None
# Outputs: vmID
sub _generateVMID {

    return (substr(md5_hex(md5_hex(time(), {}, rand(), $$)), 0, $VM_ID_LENGTH));

}

#######################################################################
# Public Methods Implemented                                          #
#######################################################################

=pod

=head1 EXTERNAL SOAP FUNCTIONS

=head2 isRegisteredVM(config => $config)

=over 4

Indicates if a specified VM is already registered.

I<Inputs>:
 B<$config> is the full, absolute path to the VM's
configuration file, as it sits on the host VMware Server / GSX server's
disk.

I<Output>: True if already registered, false otherwise.

=back

=begin testing

# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Catch all errors, in order to make sure child processes are
# properly killed.
eval {

    $URL = HoneyClient::Manager::VM->init();
   
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");

    # Make sure the test VM is stopped.
    $som = $stub->stopVM(config => $testVM);
    
    # Test isRegisteredVM() method.
    $som = $stub->isRegisteredVM(config => $testVM);
    
    # The test VM should be registered.
    ok($som->result, "isRegisteredVM(config => '$testVM')") or diag("The isRegisteredVM() call failed.  If ($testVM) is still registered, be sure to unregister it manually.");

    # Make sure the test VM is unregistered.
    $som = $stub->unregisterVM(config => $testVM);

    # Test isRegisteredVM() method.
    $som = $stub->isRegisteredVM(config => $testVM);

    # The test VM should not be registered.
    ok(!$som->result, "isRegisteredVM(config => '$testVM')") or diag("The isRegisteredVM() call failed.  If ($testVM) is still registered, be sure to unregister it manually.");
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::VM->destroy();
sleep (1);

# Report any failure found.
if ($@) {
    fail($@);
}

=end testing

=cut

sub isRegisteredVM {
    # Extract arguments.    
    my ($class, %args) = @_;

    # Log resolved arguments.
    $LOG->debug(sub {
        # Make Dumper format more terse.
        $Data::Dumper::Terse = 1;
        $Data::Dumper::Indent = 0;
        Dumper(\%args);
    });
    
    # Sanity check.  Make sure there are no queued faults.
    _emitQueuedFault();

    # Sanity check. Make sure we're connected.
    if (!defined($server) || !defined($server->is_connected())) {
        _connect();
    }

    # Sanity check.  Make sure we get a valid argument.
    my $argsExist = scalar(%args);
    if (!$argsExist || 
        !exists($args{'config'}) ||
        !defined($args{'config'})) {

        # Return false, if no valid argument is supplied.
        return (0);
    }

    return (grep(/$args{'config'}/, enumerate()));
}

=pod

=head2 enumerate()

=over 4

Returns an enumeration of all registered VMs.

I<Output>: An array containing the configuration files for
each registered VM.

=back

=begin testing

# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Catch all errors, in order to make sure child processes are
# properly killed.
eval {

    $URL = HoneyClient::Manager::VM->init();
    
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");

    # Register the test VM.
    $som = $stub->registerVM(config => $testVM);

    # Test enumerate() method.
    $som = $stub->enumerate();

    # The test VM should be listed in the output.
    my @list = $som->paramsall;
    like(join(' ', @list), "/$testVM/", "enumerate()") or diag("The enumerate() call failed.  Attempted to register VM ($testVM), but the VM was not listed in the output of enumerate().");
    
    # Unregister the test VM.
    $som = $stub->unregisterVM(config => $testVM);
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::VM->destroy();
sleep (1);

# Report any failure found.
if ($@) {
    fail($@);
}

=end testing

=cut

sub enumerate {

    # Log resolved arguments.
    $LOG->debug("{}");

    # Sanity check.  Make sure there are no queued faults.
    _emitQueuedFault();

    # Sanity check. Make sure we're connected.
    if (!defined($server) || !defined($server->is_connected())) {
        _connect();
    }

    # Obtain a list containing every config file path registered with the host.
    my @list = $server->registered_vm_names();
    my ($errorNumber, $errorString) = $server->get_last_error();
    if ($errorNumber != 0) {
        $LOG->warn("Could not enumerate clients on host system. " .
                   "(" . $errorNumber . ": " . $errorString . ")");
        die SOAP::Fault->faultcode(__PACKAGE__ . "->enumerate()")
                       ->faultstring("Could not enumerate clients on host system.")
                       ->faultdetail(bless { errNo  => $errorNumber,
                                             errStr => $errorString },
                                     'err');
    }

    return (@list);
}

=pod

=head2 getStateVM(config => $config)

=over 4

Gets the powered state of a specified VM.

I<Inputs>:
 B<$config> is the full, absolute path to the VM's
configuration file, as it sits on the host VMware Server / GSX server's
disk.

I<Output>: One of the following B<VMware::VmPerl> constants:
 VM_EXECUTION_STATE_ON
 VM_EXECUTION_STATE_OFF
 VM_EXECUTION_STATE_SUSPENDED
 VM_EXECUTION_STATE_STUCK
 VM_EXECUTION_STATE_UNKNOWN

=back

=begin testing

# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Catch all errors, in order to make sure child processes are
# properly killed.
eval {

    $URL = HoneyClient::Manager::VM->init();
    
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");

    # Register the test VM.
    $som = $stub->registerVM(config => $testVM);

    # Test getStateVM() method.
    $som = $stub->getStateVM(config => $testVM);

    # The test VM should be off.
    is($som->result, VM_EXECUTION_STATE_OFF, "getStateVM(config => '$testVM')") or diag("The getStateVM() call failed.  Attempted to register VM ($testVM), but the VM state was not reported as OFF.");
    
    # Unregister the test VM.
    $som = $stub->unregisterVM(config => $testVM);
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::VM->destroy();
sleep (1);

# Report any failure found.
if ($@) {
    fail($@);
}

=end testing

=cut

sub getStateVM {
    
    # Extract arguments.
    my ($class, %args) = @_;

    # Log resolved arguments.
    $LOG->debug(sub {
        # Make Dumper format more terse.
        $Data::Dumper::Terse = 1;
        $Data::Dumper::Indent = 0;
        Dumper(\%args);
    });
    
    # Sanity check.  Make sure there are no queued faults.
    _emitQueuedFault();
    
    # Sanity check.  Make sure we get a valid argument.
    my $argsExist = scalar(%args);
    if (!$argsExist || 
        !exists($args{'config'}) ||
        !defined($args{'config'})) {

        # Die if no valid argument is supplied.
        $LOG->warn("No VM configuration file supplied.");
        die SOAP::Fault->faultcode(__PACKAGE__ . "->getStateVM()")
                       ->faultstring("No VM configuration file supplied.");
    }

    _connectVM($class, $args{'config'});

    # Obtain the VM's lock.
    my $vmSemaphore = _getVMlock($class, $args{'config'});

    # Lock the VM.
    $vmSemaphore->down();

    # Get current VM state.
    my $powerState = $vm->get_execution_state();
    
    # Unlock the VM.
    $vmSemaphore->up();

    # Check if state retrieval was successful.
    if (!defined($powerState)) {
        my ($errorNumber, $errorString) = $vm->get_last_error();
        $LOG->warn("Could not get execution state of VM ($args{'config'}). " .
                   "(" . $errorNumber . ": " . $errorString . ")");
        die SOAP::Fault->faultcode(__PACKAGE__ . "->getStateVM()")
                       ->faultstring("Could not get execution state of VM ($args{'config'}).")
                       ->faultdetail(bless { errNo  => $errorNumber,
                                             errStr => $errorString },
                                     'err');
    }

    return ($powerState);
}

=pod

=head2 startVM(config => $config)

=over 4

Powers on a specified VM.

I<Inputs>:
 B<$config> is the full, absolute path to the VM's
configuration file, as it sits on the host VMware Server / GSX server's
disk.

I<Output>: True if power on was successful, false otherwise.

=back

=begin testing

# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Catch all errors, in order to make sure child processes are
# properly killed.
eval {

    $URL = HoneyClient::Manager::VM->init();
    
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");

    # Register the test VM.
    $som = $stub->registerVM(config => $testVM);

    # Test startVM() method.
    $som = $stub->startVM(config => $testVM);
    ok($som->result, "startVM(config => '$testVM')");

    # The test VM should be on.
    $som = $stub->getStateVM(config => $testVM);

    # Since the test VM doesn't have an OS installed on it,
    # the VM may be considered stuck.  Go ahead and answer
    # this question, if need be.
    if ($som->result == VM_EXECUTION_STATE_STUCK) {
        $som = $stub->answerVM(config => $testVM);
        # Fetch the state again, to see if it's now ON.
        $som = $stub->getStateVM(config => $testVM);
    }
    is($som->result, VM_EXECUTION_STATE_ON, "startVM(config => '$testVM')") or diag("The startVM() call failed.  Attempted to start VM ($testVM), but the VM state was not reported as ON.");
    
    # Stop and unregister the test VM.
    $som = $stub->stopVM(config => $testVM);
    $som = $stub->unregisterVM(config => $testVM);
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::VM->destroy();
sleep (1);

# Report any failure found.
if ($@) {
    fail($@);
}

=end testing

=cut

sub startVM {

    # Extract arguments.    
    my ($class, %args) = @_;

    # Log resolved arguments.
    $LOG->debug(sub {
        # Make Dumper format more terse.
        $Data::Dumper::Terse = 1;
        $Data::Dumper::Indent = 0;
        Dumper(\%args);
    });
    
    # Sanity check.  Make sure there are no queued faults.
    _emitQueuedFault();
    
    # Sanity check.  Make sure we get a valid argument.
    my $argsExist = scalar(%args);
    if (!$argsExist || 
        !exists($args{'config'}) ||
        !defined($args{'config'})) {

        # Die if no valid argument is supplied.
        $LOG->warn("No VM configuration file supplied.");
        die SOAP::Fault->faultcode(__PACKAGE__ . "->startVM()")
                       ->faultstring("No VM configuration file supplied.");
    }

    _connectVM($class, $args{'config'});

    # Only start VMs that are powered off or suspended.
    my $powerState = getStateVM($class, %args); 

    if ($powerState == VM_EXECUTION_STATE_ON) {
        # The VM is already powered on.
        _disconnectVM();
        return (1);
    } elsif ($powerState == VM_EXECUTION_STATE_OFF ||
             $powerState == VM_EXECUTION_STATE_SUSPENDED) {

        # Obtain the VM's lock.
        my $vmSemaphore = _getVMlock($class, $args{'config'});

        # Lock the VM.
        $vmSemaphore->down();

        # Start VM, get status.
        my $status = $vm->start(VM_POWEROP_MODE_TRYSOFT);
        
        # Unlock the VM.
        $vmSemaphore->up();

        if (!$status) {
            # Okay, it's possible the VM is simply stuck on a question.
            # If so, try and answer it before failing outright...
            $powerState = getStateVM($class, %args);
            if ($powerState == VM_EXECUTION_STATE_STUCK) {

                # Try answering the question...
                if (defined(answerVM($class, %args))) {
                    _disconnectVM();
                    return (1);
                }
            }

            # Looks like the VM is in a wierd state, fail accordingly...
            my ($errorNumber, $errorString) = $vm->get_last_error();
            $LOG->warn("Could not power on VM ($args{'config'}). " .
                       "(" . $errorNumber . ": " . $errorString . ")");
            die SOAP::Fault->faultcode(__PACKAGE__ . "->startVM()")
                           ->faultstring("Could not power on VM ($args{'config'}).")
                           ->faultdetail(bless { errNo  => $errorNumber,
                                                 errStr => $errorString },
                                         'err');
        }
        
        # Wait 5 seconds, so that the start completely finishes...
        sleep (5);

    } else {
        # The VM is in a state that cannot be powered on.
        _disconnectVM();
        return (0);
    }

    _disconnectVM();
    return (1);
}

=pod

=head2 stopVM(config => $config)

=over 4

Powers off a specified VM.

I<Inputs>:
 B<$config> is the full, absolute path to the VM's
configuration file, as it sits on the host VMware Server / GSX server's
disk.

I<Output>: True if power off was successful, false otherwise.

=back

=begin testing

# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Catch all errors, in order to make sure child processes are
# properly killed.
eval {

    $URL = HoneyClient::Manager::VM->init();
    
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");

    # Register and start the test VM.
    $som = $stub->registerVM(config => $testVM);
    $som = $stub->startVM(config => $testVM);

    # Test stopVM() method.
    $som = $stub->stopVM(config => $testVM);
    ok($som->result, "stopVM(config => '$testVM')");

    # The test VM should be on.
    $som = $stub->getStateVM(config => $testVM);
    is($som->result, VM_EXECUTION_STATE_OFF, "stopVM(config => '$testVM')") or diag("The stopVM() call failed.  Attempted to stop VM ($testVM), but the VM state was not reported as OFF.");
    
    # Unregister the test VM.
    $som = $stub->unregisterVM(config => $testVM);
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::VM->destroy();
sleep (1);

# Report any failure found.
if ($@) {
    fail($@);
}

=end testing

=cut

sub stopVM {

    # Extract arguments.    
    my ($class, %args) = @_;

    # Log resolved arguments.
    $LOG->debug(sub {
        # Make Dumper format more terse.
        $Data::Dumper::Terse = 1;
        $Data::Dumper::Indent = 0;
        Dumper(\%args);
    });
    
    # Sanity check.  Make sure there are no queued faults.
    _emitQueuedFault();
    
    # Sanity check.  Make sure we get a valid argument.
    my $argsExist = scalar(%args);
    if (!$argsExist || 
        !exists($args{'config'}) ||
        !defined($args{'config'})) {

        # Die if no valid argument is supplied.
        $LOG->warn("No VM configuration file supplied.");
        die SOAP::Fault->faultcode(__PACKAGE__ . "->stopVM()")
                       ->faultstring("No VM configuration file supplied.");
    }

    _connectVM($class, $args{'config'});

    # Only stop VMs that are not off or suspended already.
    my $powerState = getStateVM($class, %args);

    # Check to see if the VM is stuck, first...
    if ($powerState == VM_EXECUTION_STATE_STUCK) {
        # If so, try answering the question...
        answerVM($class, %args);
    }
    
    if ($powerState == VM_EXECUTION_STATE_OFF) {
        # The VM is already powered off.
        _disconnectVM();
        return (1);

    } elsif ($powerState != VM_EXECUTION_STATE_OFF && 
             $powerState != VM_EXECUTION_STATE_SUSPENDED) {

        # Obtain the VM's lock.
        my $vmSemaphore = _getVMlock($class, $args{'config'});

        # Lock the VM.
        $vmSemaphore->down();

        # Stop VM, get status.
        my $status = $vm->stop(VM_POWEROP_MODE_HARD);

        # Unlock the VM.
        $vmSemaphore->up();

        if (!$status) {
            my ($errorNumber, $errorString) = $vm->get_last_error();
            $LOG->warn("Could not power off VM ($args{'config'}). " .
                       "(" . $errorNumber . ": " . $errorString . ")");
            die SOAP::Fault->faultcode(__PACKAGE__ . "->stopVM()")
                           ->faultstring("Could not power off VM ($args{'config'}).")
                           ->faultdetail(bless { errNo  => $errorNumber,
                                                 errStr => $errorString },
                                         'err');
        }
        
        # Wait 5 seconds, so that the stop completely finishes...
        sleep (5);

    } else {
        # The VM is in a state that cannot be powered off.
        _disconnectVM();
        return (0);
    }

    _disconnectVM();
    return (1);
}

=pod

=head2 rebootVM(config => $config)

=over 4

Reboots a specified VM.

I<Inputs>:
 B<$config> is the full, absolute path to the VM's
configuration file, as it sits on the host VMware Server / GSX server's
disk.

I<Output>: True if reboot was successful, false otherwise.

=back

=begin testing

# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Catch all errors, in order to make sure child processes are
# properly killed.
eval {

    $URL = HoneyClient::Manager::VM->init();
    
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");

    # Register and start the test VM.
    $som = $stub->registerVM(config => $testVM);
    $som = $stub->startVM(config => $testVM);

    # Test rebootVM() method.
    $som = $stub->rebootVM(config => $testVM);
    ok($som->result, "rebootVM(config => '$testVM')");

    # The test VM should be on.
    $som = $stub->getStateVM(config => $testVM);

    # Since the test VM doesn't have an OS installed on it,
    # the VM may be considered stuck.  Go ahead and answer
    # this question, if need be.
    if ($som->result == VM_EXECUTION_STATE_STUCK) {
        $som = $stub->answerVM(config => $testVM);
        # Fetch the state again, to see if it's now ON.
        $som = $stub->getStateVM(config => $testVM);
    }
    is($som->result, VM_EXECUTION_STATE_ON, "rebootVM(config => '$testVM')") or diag("The rebootVM() call failed.  Attempted to reboot VM ($testVM), but the VM state was not reported as ON.");
    
    # Stop and unregister the test VM.
    $som = $stub->stopVM(config => $testVM);
    $som = $stub->unregisterVM(config => $testVM);
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::VM->destroy();
sleep (1);

# Report any failure found.
if ($@) {
    fail($@);
}

=end testing

=cut

sub rebootVM {

    # Extract arguments.    
    my ($class, %args) = @_;

    # Log resolved arguments.
    $LOG->debug(sub {
        # Make Dumper format more terse.
        $Data::Dumper::Terse = 1;
        $Data::Dumper::Indent = 0;
        Dumper(\%args);
    });
    
    # Sanity check.  Make sure there are no queued faults.
    _emitQueuedFault();
    
    # Sanity check.  Make sure we get a valid argument.
    my $argsExist = scalar(%args);
    if (!$argsExist || 
        !exists($args{'config'}) ||
        !defined($args{'config'})) {

        # Die if no valid argument is supplied.
        $LOG->warn("No VM configuration file supplied.");
        die SOAP::Fault->faultcode(__PACKAGE__ . "->rebootVM()")
                       ->faultstring("No VM configuration file supplied.");
    }

    _connectVM($class, $args{'config'});

    # Only reboot VMs that are not suspended already.
    my $powerState = getStateVM($class, %args);
    
    # Check to see if the VM is stuck, first...
    if ($powerState == VM_EXECUTION_STATE_STUCK) {
        # If so, try answering the question...
        answerVM($class, %args);
    }

    if ($powerState != VM_EXECUTION_STATE_SUSPENDED) {

        # Obtain the VM's lock.
        my $vmSemaphore = _getVMlock($class, $args{'config'});

        # Lock the VM.
        $vmSemaphore->down();

        # Reset VM, get status.
        my $status = $vm->reset(VM_POWEROP_MODE_HARD);

        # Unlock the VM.
        $vmSemaphore->up();

        if (!$status) {
            my ($errorNumber, $errorString) = $vm->get_last_error();
            $LOG->warn("Could not reboot VM ($args{'config'}). " .
                       "(" . $errorNumber . ": " . $errorString . ")");
            die SOAP::Fault->faultcode(__PACKAGE__ . "->rebootVM()")
                           ->faultstring("Could not reboot VM ($args{'config'}).")
                           ->faultdetail(bless { errNo  => $errorNumber,
                                                 errStr => $errorString },
                                         'err');
        }
        
        # Wait 5 seconds, so that the reboot completely finishes...
        sleep (5);

    } else {
        # The VM is in a state that cannot be rebooted.
        _disconnectVM();
        return (0);
    }

    _disconnectVM();
    return (1);
}

=pod

=head2 suspendVM(config => $config)

=over 4

Suspends a specified VM.

I<Inputs>:
 B<$config> is the full, absolute path to the VM's
configuration file, as it sits on the host VMware Server / GSX server's
disk.

I<Output>: True if suspend was successful, false otherwise.

=back

=begin testing

# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Catch all errors, in order to make sure child processes are
# properly killed.
eval {

    $URL = HoneyClient::Manager::VM->init();
    
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");

    # Register and start the test VM.
    $som = $stub->registerVM(config => $testVM);
    $som = $stub->startVM(config => $testVM);

    # Test suspendVM() method.
    $som = $stub->suspendVM(config => $testVM);
    ok($som->result, "suspendVM(config => '$testVM')");

    # The test VM should be suspended.
    $som = $stub->getStateVM(config => $testVM);
    is($som->result, VM_EXECUTION_STATE_SUSPENDED, "suspendVM(config => '$testVM')") or diag("The suspendVM() call failed.  Attempted to suspend VM ($testVM), but the VM state was not reported as SUSPENDED.");

    # Wake, stop, and unregister the test VM.
    $som = $stub->startVM(config => $testVM);
    $som = $stub->stopVM(config => $testVM);
    $som = $stub->unregisterVM(config => $testVM);
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::VM->destroy();
sleep (1);

# Report any failure found.
if ($@) {
    fail($@);
}

=end testing

=cut

sub suspendVM {

    # Extract arguments.
    my ($class, %args) = @_;

    # Log resolved arguments.
    $LOG->debug(sub {
        # Make Dumper format more terse.
        $Data::Dumper::Terse = 1;
        $Data::Dumper::Indent = 0;
        Dumper(\%args);
    });
    
    # Sanity check.  Make sure there are no queued faults.
    _emitQueuedFault();
    
    # Sanity check.  Make sure we get a valid argument.
    my $argsExist = scalar(%args);
    if (!$argsExist || 
        !exists($args{'config'}) ||
        !defined($args{'config'})) {

        # Die if no valid argument is supplied.
        $LOG->warn("No VM configuration file supplied.");
        die SOAP::Fault->faultcode(__PACKAGE__ . "->suspendVM()")
                       ->faultstring("No VM configuration file supplied.");
    }

    _connectVM($class, $args{'config'});

    # Only suspend VMs that are not suspended already.
    my $powerState = getStateVM($class, %args);
    
    # Check to see if the VM is stuck, first...
    if ($powerState == VM_EXECUTION_STATE_STUCK) {
        # If so, try answering the question...
        answerVM($class, %args);
    }

    if ($powerState != VM_EXECUTION_STATE_SUSPENDED) {

        # Obtain the VM's lock.
        my $vmSemaphore = _getVMlock($class, $args{'config'});

        # Lock the VM.
        $vmSemaphore->down();

        # Suspend VM, get status.
        my $status = $vm->suspend(VM_POWEROP_MODE_HARD);

        # Unlock the VM.
        $vmSemaphore->up();

        if (!$status) {
            my ($errorNumber, $errorString) = $vm->get_last_error();
            $LOG->warn("Could not suspend VM ($args{'config'}). " .
                       "(" . $errorNumber . ": " . $errorString . ")");
            die SOAP::Fault->faultcode(__PACKAGE__ . "->suspendVM()")
                           ->faultstring("Could not suspend VM ($args{'config'}).")
                           ->faultdetail(bless { errNo  => $errorNumber,
                                                 errStr => $errorString },
                                         'err');
        }

        # Wait 5 seconds, so that the suspend completely finishes...
        sleep (5);

    } else {
        # The VM is in a state that cannot be suspended.
        _disconnectVM();
        return (0);
    }

    _disconnectVM();
    return (1);
}

=pod

=head2 fullCloneVM(src_config => $srcConfig, dest_dir => $destDir)

=over 4

Completely clones a specified VM.

I<Inputs>:
 B<$srcConfig> is the full, absolute path to the source VM's
configuration file, as it sits on the host VMware Server / GSX server's
disk.
 B<$destDir> is an optional argument, containing the absolute
path where the cloned VM contents will reside.

I<Output>: Absolute path of the cloned VM's configuration file,
if successful.

I<Notes>:
If B<$destDir> is not specified, then the cloned VM 
will reside in a subdirectory within the main directory
specified by the global B<$DATASTORE_PATH> variable.

The format of this automatically generated subdirectory will
be a randomly generated hexadecimal string of the length
$VM_ID_LENGTH.

Cloning VMs can be a time consuming operation, 
depending on how big the VM is.  This is because the entire
VM data is cloned, including all hard disks.  As such,
the web service call completes while these filesystem-intensive
operations are performed in the background within a
child thread.

Once cloned, the new VM will be automatically
started, in order to update the VM's unique UUID and
the VM's network MAC address.

Thus, it is recommended that once a fullCloneVM() operation
is performed, you call getStateVM() on the cloned VM's
configuration file to make sure the VM is powered on,
B<prior> to performing B<any additional operations> on
the cloned VM.

=back

=begin testing

# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Catch all errors, in order to make sure child processes are
# properly killed.
eval {

    $URL = HoneyClient::Manager::VM->init();
    
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");

    # Register the test VM.
    $som = $stub->registerVM(config => $testVM);

    # Get the test VM's parent directory,
    # in order to create a temporary clone VM.
    my $testVMDir = dirname($testVM);
    my $cloneVMDir = dirname($testVMDir) . "/test_vm_clone";
    my $cloneVM = $cloneVMDir . "/" . basename($testVM);

    # Test fullCloneVM() method.
    $som = $stub->fullCloneVM(src_config => $testVM, dest_dir => $cloneVMDir);
    # Check to see if the clone's absolute file path is returned.
    is($som->result, $cloneVM, "fullCloneVM(src_config => '$testVM', dest_dir => '$cloneVMDir')");

    # Wait a small amount of time for the asynchronous clone
    # to complete.
    sleep (15);

    # The clone VM should be on.
    $som = $stub->getStateVM(config => $cloneVM);

    # Since the clone VM doesn't have an OS installed on it,
    # the VM may be considered stuck.  Go ahead and answer
    # this question, if need be.
    if ($som->result == VM_EXECUTION_STATE_STUCK) {
        $som = $stub->answerVM(config => $cloneVM);
        # Fetch the state again, to see if it's now ON.
        $som = $stub->getStateVM(config => $cloneVM);
    }
    is($som->result, VM_EXECUTION_STATE_ON, "fullCloneVM(src_config => '$testVM', dest_dir => '$cloneVMDir')") or diag("The fullCloneVM() call failed.  Attempted to fully clone VM ($testVM) at ($cloneVM), but the cloned VM state was not reported as ON.");
  
    # Destroy the clone VM.
    $som = $stub->destroyVM(config => $cloneVM);

    # Stop and unregister the test VM.
    $som = $stub->stopVM(config => $testVM);
    $som = $stub->unregisterVM(config => $testVM);
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::VM->destroy();
sleep (1);

# Report any failure found.
if ($@) {
    fail($@);
}

=end testing

=cut

sub fullCloneVM {

    # Extract arguments.
    my ($class, %args) = @_;

    # Log resolved arguments.
    $LOG->debug(sub {
        # Make Dumper format more terse.
        $Data::Dumper::Terse = 1;
        $Data::Dumper::Indent = 0;
        Dumper(\%args);
    });
    
    # Sanity check.  Make sure there are no queued faults.
    _emitQueuedFault();
    
    # Sanity check.  Make sure we get a valid argument.
    my $argsExist = scalar(%args);
    if (!$argsExist || 
        !exists($args{'src_config'}) ||
        !defined($args{'src_config'})) {

        # Die if no valid argument is supplied.
        $LOG->warn("No source VM configuration file supplied.");
        die SOAP::Fault->faultcode(__PACKAGE__ . "->fullCloneVM()")
                       ->faultstring("No source VM configuration file supplied.");
    }

    # Sanity check: Make sure the referenced server is local;
    # otherwise, fail outright.
    if (!_isServerLocal()) {
        my $errorString = "Unable to perform operation on remote server ($serverName).";
        $LOG->warn($errorString);
        die SOAP::Fault->faultcode(__PACKAGE__ . "->fullCloneVM()")
                       ->faultstring($errorString);
    }
    
    _connectVM($class, $args{'src_config'});
    
    # Make sure the source VM is either suspended or turned off.
    my $powerState = getStateVM($class, (config => $args{'src_config'}));

    if ($powerState != VM_EXECUTION_STATE_SUSPENDED &&
        $powerState != VM_EXECUTION_STATE_OFF) {
        
        # Okay, the VM is alive; so suspend it...
        suspendVM($class, (config => $args{'src_config'}));
    }
    unregisterVM($class, (config => $args{'src_config'}));

    # Pick a new destDir, if need be.
    my $dirName = undef;
    if (!$argsExist ||
        !exists($args{'dest_dir'}) ||
        !defined($args{'dest_dir'})) {
        do {
            $dirName = _generateVMID();
            $args{'dest_dir'} = $DATASTORE_PATH . "/" . $dirName;
            # Loop until we've found a non-existant dir.
        } while (-d $args{'dest_dir'});
    } else {
        $dirName = basename($args{'dest_dir'});
    }

    my $srcDir = dirname($args{'src_config'});
    my $configFile = basename($args{'src_config'});
    my $destConfig = $args{'dest_dir'} . "/" . $configFile;

    # Perform the copy operation...
    # Since this usually takes awhile, we perform the remaining operations in a child thread.
    my $thread = async {

        # Register a kill signal handler.
        # This handler is designed to kill this thread upon overall module
        # destruction.  This handler should never be used for normal program
        # operations, since it will NOT release any locks/semaphores properly.
        local $SIG{USR1} = sub { threads->exit(); };

        $maxThreadSemaphore->down();
        threads->yield();
            
        # Obtain the source VM's lock.
        my $vmSemaphore = _getVMlock($class, $args{'src_config'});

        local $SIG{INT} = sub { 
            my $LOG = get_logger();
            $LOG->warn("Asynchronous clone of ($srcDir) interrupted!");
            # Release any acquired locks.
            $vmSemaphore->up();
            $maxThreadSemaphore->up();
            return;
        };

        # Trap all faults that may occur from these asynchronous operations.
        eval {

            # Lock the source VM.
            $vmSemaphore->down();

            # Copy the srcDir to the new destDir.
            my $status = dircopy($srcDir, $args{'dest_dir'});

            # Unlock the source VM.
            $vmSemaphore->up();

            if (!$status) {
                my $errorString = "Could not create new directory ($args{'dest_dir'}).";
                $LOG->warn($errorString);
                die SOAP::Fault->faultcode(__PACKAGE__ . "->fullCloneVM()")
                               ->faultstring($errorString);
            }
            
            # Update clone VM data permissions...
            chmod(oct(700), glob($args{'dest_dir'} . "/" . $configFile));
            chmod(oct(700), glob($args{'dest_dir'} . "/*.nvram"));
            chmod(oct(600), glob($args{'dest_dir'} . "/*.vms*"));
            chmod(oct(600), glob($args{'dest_dir'} . "/*REDO*"));

            # None of the VmPerl objects are thread-safe, so in order to perform the following
            # commands, we must do callbacks to the main thread over SOAP.
            # Yes, this is annoying and ugly.

            # Register the clone...
            _callback($class, "registerVM", (config => $destConfig));

            # Update the cloned VM's displayName...
            _callback($class, "setNameVM", (config => $destConfig, name => $dirName));
            
            # Now start the VM to update the identifier...    
            _callback($class, "startVM", (config => $destConfig));
            
            # If the source VM was suspended, then this clone
            # will awake from a suspended state.  We'll still
            # need to issue a full reboot, in order for the
            # clone to get assigned a new network MAC address.
            if ($powerState == VM_EXECUTION_STATE_SUSPENDED) {
                _callback($class, "rebootVM", (config => $destConfig));
            }
        };

        # For any faults that did occur from the previous operations, be sure
        # to report them back via the fault queue.
        if ($@) {
            _queueFault($@);
        }
        
        $maxThreadSemaphore->up();
        return;
    };

    return ($destConfig);
}

=pod

=head2 getNameVM(config => $config)

=over 4

Gets the display name of a specified VM.

I<Inputs>:
 B<$config> is the full, absolute path to the VM's
configuration file, as it sits on the host VMware Server / GSX server's
disk.

I<Output>: The display name of the VM.

=back

=begin testing

# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Catch all errors, in order to make sure child processes are
# properly killed.
eval {

    $URL = HoneyClient::Manager::VM->init();
   
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");

    # Make sure the test VM is registered.
    $som = $stub->registerVM(config => $testVM);

    # Test getNameVM() method.
    $som = $stub->getNameVM(config => $testVM);

    # The test VM should not be registered.
    is($som->result, "testVM", "getNameVM(config => '$testVM')") or diag("The getNameVM() call failed.  Expected VM ($testVM) to have the name \"testVM\".");
    
    # Unregister the test VM. 
    $som = $stub->unregisterVM(config => $testVM);
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::VM->destroy();
sleep (1);

# Report any failure found.
if ($@) {
    fail($@);
}

=end testing

=cut

sub getNameVM {

    # Extract arguments.    
    my ($class, %args) = @_;

    # Log resolved arguments.
    $LOG->debug(sub {
        # Make Dumper format more terse.
        $Data::Dumper::Terse = 1;
        $Data::Dumper::Indent = 0;
        Dumper(\%args);
    });
    
    # Sanity check.  Make sure there are no queued faults.
    _emitQueuedFault();
    
    # Sanity check.  Make sure we get a valid argument.
    my $argsExist = scalar(%args);
    if (!$argsExist || 
        !exists($args{'config'}) ||
        !defined($args{'config'})) {

        # Die if no valid argument is supplied.
        $LOG->warn("No VM configuration file supplied.");
        die SOAP::Fault->faultcode(__PACKAGE__ . "->getNameVM()")
                       ->faultstring("No VM configuration file supplied.");
    }

    _connectVM($class, $args{'config'});

    # Obtain the VM's lock.
    my $vmSemaphore = _getVMlock($class, $args{'config'});

    # Lock the VM.
    $vmSemaphore->down();

    # Get VM's display name.
    my $displayName = $vm->get_config("displayName");

    # Unlock the VM.
    $vmSemaphore->up();

    if (!defined($displayName)) {
        my ($errorNumber, $errorString) = $vm->get_last_error();
        $LOG->warn("Could not get display name of VM ($args{'config'}). " .
                   "(" . $errorNumber . ": " . $errorString . ")");
        die SOAP::Fault->faultcode(__PACKAGE__ . "->getNameVM()")
                       ->faultstring("Could not get display name of VM ($args{'config'}).")
                       ->faultdetail(bless { errNo  => $errorNumber,
                                             errStr => $errorString },
                                     'err');
    }

    _disconnectVM();
    return ($displayName);
}

=pod

=head2 setNameVM(config => $config, name => $name)

=over 4

Sets the display name of a specified VM.

I<Inputs>:
 B<$config> is the full, absolute path to the VM's
configuration file, as it sits on the host VMware Server / GSX server's
disk.
 B<$name> is the new display name to assign the VM.

I<Output>: The new display name of the VM, if successful.

=back

=begin testing

# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Catch all errors, in order to make sure child processes are
# properly killed.
eval {

    $URL = HoneyClient::Manager::VM->init();
    
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");

    # Register the test VM.
    $som = $stub->registerVM(config => $testVM);

    # Get the current name of the test VM.
    $som = $stub->getNameVM(config => $testVM);
    my $oldName = $som->result;

    # Set the new name of the test VM.
    my $newName = "newVM";
    # Test setNameVM() method.
    $som = $stub->setNameVM(config => $testVM, name => $newName);
    is($som->result, $newName, "setNameVM(config => '$testVM', name => '$newName')") or diag("The setNameVM() call failed.  Attempted to change the test VM ($testVM) name of \"$oldName\" to \"$newName\".");

    # Check to make sure the new name is set.
    $som = $stub->getNameVM(config => $testVM);
    is($som->result, $newName, "setNameVM(config => '$testVM', name => '$newName')") or diag("The setNameVM() call failed.  Attempted to change the test VM ($testVM) name of \"$oldName\" to \"$newName\".");

    # Restore the old test VM name and unregister the test VM.
    $som = $stub->setNameVM(config => $testVM, name => $oldName);
    $som = $stub->unregisterVM(config => $testVM);
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::VM->destroy();
sleep (1);

# Report any failure found.
if ($@) {
    fail($@);
}

=end testing

=cut

sub setNameVM {
    
    # Extract arguments.    
    my ($class, %args) = @_;

    # Log resolved arguments.
    $LOG->debug(sub {
        # Make Dumper format more terse.
        $Data::Dumper::Terse = 1;
        $Data::Dumper::Indent = 0;
        Dumper(\%args);
    });
    
    # Sanity check.  Make sure there are no queued faults.
    _emitQueuedFault();
    
    # Sanity check.  Make sure we get a valid argument.
    my $argsExist = scalar(%args);
    if (!$argsExist || 
        !exists($args{'config'}) ||
        !defined($args{'config'})) {

        # Die if no valid argument is supplied.
        $LOG->warn("No VM configuration file supplied.");
        die SOAP::Fault->faultcode(__PACKAGE__ . "->setNameVM()")
                       ->faultstring("No VM configuration file supplied.");
    }
    
    # Sanity check: Make sure the referenced server is local;
    # otherwise, fail outright.
    if (!_isServerLocal()) {
        my $errorString = "Unable to perform operation on remote server ($serverName).";
        $LOG->warn($errorString);
        die SOAP::Fault->faultcode(__PACKAGE__ . "->setNameVM()")
                       ->faultstring($errorString);
    }

    # Check to make sure a valid name is given.
    if (!$argsExist ||
        !exists($args{'name'}) ||
        !defined($args{'name'}) || 
        ($args{'name'} eq "")) {
        $LOG->warn("Invalid name given; could not set name of VM ($args{'config'}).");
        die SOAP::Fault->faultcode(__PACKAGE__ . "->setNameVM()")
                       ->faultstring("Invalid name given; could not set name of VM ($args{'config'}).");
    }

    _connectVM($class, $args{'config'});

    my @configArray = undef;

    # Obtain the VM's lock.
    my $vmSemaphore = _getVMlock($class, $args{'config'});

    # Lock the VM.
    $vmSemaphore->down();

    # Set the displayName within the config file on disk...
    if (!tie(@configArray, 'Tie::File', $args{'config'})) {
        # Unlock VM early, if failed.
        $vmSemaphore->up();
        $LOG->warn("Could not set name of VM ($args{'config'}).");
        die SOAP::Fault->faultcode(__PACKAGE__ . "->setNameVM()")
                       ->faultstring("Could not set name of VM ($args{'config'}).");
    }

    for (@configArray) {
        s/^displayName =.*$/displayName = "$args{'name'}"/g;
    }
    untie @configArray;
    
    # Unlock the VM.
    $vmSemaphore->up();

    # Also, if the VM is on, change the displayName stored in memory...
    my $powerState = getStateVM($class, %args);
    if ($powerState == VM_EXECUTION_STATE_ON) {

        # Lock the VM.
        $vmSemaphore->down();

        # If the VM is already on, update the name stored in memory...
        my $displayName = $vm->set_config("displayName", $args{'name'});

        # Unlock the VM.
        $vmSemaphore->up();

        if (!defined($displayName)) {
            my ($errorNumber, $errorString) = $vm->get_last_error();
            $LOG->warn("Could not set name of VM ($args{'config'}). " .
                       "(" . $errorNumber . ": " . $errorString . ")");
            die SOAP::Fault->faultcode(__PACKAGE__ . "->setNameVM()")
                           ->faultstring("Could not set name of VM ($args{'config'}).")
                           ->faultdetail(bless { errNo  => $errorNumber,
                                                 errStr => $errorString },
                                         'err');
        }
    }

    _disconnectVM();
    return ($args{'name'});
}

=pod

=head2 getMACaddrVM(config => $config)

=over 4

Gets the MAC address of a specified VM.

I<Inputs>:
 B<$config> is the full, absolute path to the VM's
configuration file, as it sits on the host VMware Server / GSX server's
disk.

I<Output>: The MAC address of the VM, if successful.

I<Notes>:
This function will only return the MAC address of the VM's first 
ethernet interface.

By default upon powering on a VM, VMware Server / GSX will generate a new
MAC address for any VM, if the VM's on-disk location has changed.

Thus, if you manually migrate a VM to a new location on disk
and proceed to call this function prior to powering on the VM,
then you'll get a bogus MAC address that will immediately change
once the VM is powered on.

This is precisely why the provided *CloneVM() functions power on
the cloned VM immediately after cloning -- in order to initialize 
a new UUID and MAC address for the cloned VM.

=back

=begin testing

# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Catch all errors, in order to make sure child processes are
# properly killed.
eval {

    $URL = HoneyClient::Manager::VM->init();
    
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");

    # Register the test VM.
    $som = $stub->registerVM(config => $testVM);

    # Get the MAC address of the test VM.
    # Test getMACaddrVM() method.
    $som = $stub->getMACaddrVM(config => $testVM);

    # The exact MAC address of the VM will change from system to system,
    # so we check to make sure the result looks like a valid MAC address.
    like($som->result, "/[0-9a-f][0-9a-f]\:[0-9a-f][0-9a-f]\:[0-9a-f][0-9a-f]\:[0-9a-f][0-9a-f]\:[0-9a-f][0-9a-f]\:[0-9a-f][0-9a-f]/", "getMACaddrVM(config => '$testVM')") or diag("The getMACaddrVM() call failed.  Attempted to retrieve the MAC address of test VM ($testVM).");

    # Unregister the test VM.
    $som = $stub->unregisterVM(config => $testVM);
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::VM->destroy();
sleep (1);

# Report any failure found.
if ($@) {
    fail($@);
}

=end testing

=cut

sub getMACaddrVM {

    # Extract arguments.    
    my ($class, %args) = @_;

    # Log resolved arguments.
    $LOG->debug(sub {
        # Make Dumper format more terse.
        $Data::Dumper::Terse = 1;
        $Data::Dumper::Indent = 0;
        Dumper(\%args);
    });
    
    # Sanity check.  Make sure there are no queued faults.
    _emitQueuedFault();
    
    # Sanity check.  Make sure we get a valid argument.
    my $argsExist = scalar(%args);
    if (!$argsExist || 
        !exists($args{'config'}) ||
        !defined($args{'config'})) {

        # Die if no valid argument is supplied.
        $LOG->warn("No VM configuration file supplied.");
        die SOAP::Fault->faultcode(__PACKAGE__ . "->getMACaddrVM()")
                       ->faultstring("No VM configuration file supplied.");
    }

    _connectVM($class, $args{'config'});

    # Obtain the VM's lock.
    my $vmSemaphore = _getVMlock($class, $args{'config'});

    # Lock the VM.
    $vmSemaphore->down();

    # Get VM's MAC address of its primary interface.
    my $macAddress = $vm->get_config("ethernet0.generatedaddress");

    # Unlock the VM.
    $vmSemaphore->up();

    if (!defined($macAddress)) {
        my ($errorNumber, $errorString) = $vm->get_last_error();
        $LOG->warn("Could not get MAC address of VM ($args{'config'}). " .
                   "(" . $errorNumber . ": " . $errorString . ")");
        die SOAP::Fault->faultcode(__PACKAGE__ . "->getMACaddrVM()")
                       ->faultstring("Could not get MAC address of VM ($args{'config'}).")
                       ->faultdetail(bless { errNo  => $errorNumber,
                                             errStr => $errorString },
                                     'err');
    }

    _disconnectVM();
           
    return ($macAddress);
}

=pod

=head2 getIPaddrVM(config => $config, mac_address => $macAddress)

=over 4

Gets the IP address of a specified VM.

I<Inputs>:
 B<$config> is the full, absolute path to the VM's
configuration file, as it sits on the host VMware Server / GSX server's
disk.
 B<$macAddress> is the MAC address of the specified VM.

I<Output>: The IP address of the VM, if successful.

I<Notes>:
This function will only return the IP address of the VM's first 
ethernet interface.

This function can return a result if either a $config or a
$macAddress is specified.  However, at least one parameter
must be present.

=back

=begin testing

# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Catch all errors, in order to make sure child processes are
# properly killed.
eval {

    $URL = HoneyClient::Manager::VM->init();
    
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");

    # Register and start the test VM.
    $som = $stub->registerVM(config => $testVM);
    $som = $stub->startVM(config => $testVM);

    # Wait 10 seconds, for the DHCP server to give the testVM
    # a DHCP lease.
    sleep (10);

    # Get the IP address of the test VM.
    # Test getIPaddrVM() method.
    $som = $stub->getIPaddrVM(config => $testVM);

    # The exact IP address of the VM will change from system to system,
    # so we check to make sure the result looks like a valid IP address.
    like($som->result, "/[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/", "getIPaddrVM(config => '$testVM')") or diag("The getIPaddrVM() call failed.  Attempted to retrieve the IP address of test VM ($testVM).");

    # Stop and unregister the test VM.
    $som = $stub->stopVM(config => $testVM);
    $som = $stub->unregisterVM(config => $testVM);
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::VM->destroy();
sleep (1);

# Report any failure found.
if ($@) {
    fail($@);
}

=end testing

=cut

sub getIPaddrVM {

    # Extract arguments.    
    my ($class, %args) = @_;

    # Log resolved arguments.
    $LOG->debug(sub {
        # Make Dumper format more terse.
        $Data::Dumper::Terse = 1;
        $Data::Dumper::Indent = 0;
        Dumper(\%args);
    });

    # Sanity check.  Make sure there are no queued faults.
    _emitQueuedFault();
    
    # Sanity check.  Make sure we get a valid argument.
    my $argsExist = scalar(%args);
    if (!$argsExist || 
        !exists($args{'config'}) ||
        !defined($args{'config'})) {

        $args{'config'} = undef;
    }

    # Sanity check.  Make sure we get a valid argument.
    if (!$argsExist || 
        !exists($args{'mac_address'}) ||
        !defined($args{'mac_address'})) {

        $args{'mac_address'} = undef;
    }

    # We need at least a MAC address or VM configuration file.
    if (!defined($args{'mac_address'}) &&
        !defined($args{'config'})) {

        # If we have neither, fail completely.
        $LOG->warn("No VM configuration file or MAC address supplied.");
        die SOAP::Fault->faultcode(__PACKAGE__ . "->getIPaddrVM()")
                       ->faultstring("No VM configuration file or MAC address supplied.");
    }

    # At this point, we assume we have at least a MAC or VM configuration file.
    # If we don't have the MAC address, then we assume we need to get it from
    # getMACaddrVM().
    if (!defined($args{'mac_address'})) {
        $args{'mac_address'} = getMACaddrVM($class, %args);
    }

    my @logArray = undef;
    my $match = undef;
    my $IP = undef;

    if (!tie(@logArray, 'Tie::File', $DHCP_LOGFILE, mode => O_RDONLY)) {
        $LOG->warn("Could not open DHCP log file ($DHCP_LOGFILE).");
        die SOAP::Fault->faultcode(__PACKAGE__ . "->getIPaddrVM()")
                       ->faultstring("Could not open DHCP log file ($DHCP_LOGFILE).");
    }

    for (@logArray) {
        # Look for all lines that have the VM's MAC address and the keyword
        # DHCPACK or DHCPOFFER on it.
        if ((/DHCPACK/ || /DHCPOFFER/) && /$args{'mac_address'}/) {
            $match = $_;
            $match =~ s/^.*?(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}).*$/$1/;
            if (defined($match) and ($match ne "")) {
                $IP = $match;
            }
        }
    }
    untie @logArray;

    return ($IP);
}


=pod

=head2 registerVM(config => $config)

=over 4

Registers a specified VM.

I<Inputs>:
 B<$config> is the full, absolute path to the VM's
configuration file, as it sits on the host VMware Server / GSX server's
disk.

I<Output>: True if successful, false otherwise.

=back

=begin testing

# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Catch all errors, in order to make sure child processes are
# properly killed.
eval {

    $URL = HoneyClient::Manager::VM->init();
   
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");

    # Make sure the test VM is stopped and unregistered.
    $som = $stub->stopVM(config => $testVM);
    $som = $stub->unregisterVM(config => $testVM);

    # Test registerVM() method.
    $som = $stub->registerVM(config => $testVM);
    ok($som->result, "registerVM(config => '$testVM')") or diag("The registerVM() call failed.");

    # The test VM should be registered.
    $som = $stub->isRegisteredVM(config => $testVM);
    ok($som->result, "registerVM(config => '$testVM')") or diag("The registerVM() call failed.  If ($testVM) is still registered, be sure to unregister it manually.");

    # Unregister the test VM.
    $som = $stub->unregisterVM(config => $testVM);
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::VM->destroy();
sleep (1);

# Report any failure found.
if ($@) {
    fail($@);
}

=end testing

=cut

sub registerVM {

    # Extract arguments.    
    my ($class, %args) = @_;

    # Log resolved arguments.
    $LOG->debug(sub {
        # Make Dumper format more terse.
        $Data::Dumper::Terse = 1;
        $Data::Dumper::Indent = 0;
        Dumper(\%args);
    });
    
    # Sanity check.  Make sure there are no queued faults.
    _emitQueuedFault();
    
    # Sanity check.  Make sure we get a valid argument.
    my $argsExist = scalar(%args);
    if (!$argsExist || 
        !exists($args{'config'}) ||
        !defined($args{'config'})) {

        # Die if no valid argument is supplied.
        $LOG->warn("No VM configuration file supplied.");
        die SOAP::Fault->faultcode(__PACKAGE__ . "->registerVM()")
                       ->faultstring("No VM configuration file supplied.");
    }
    
    # Sanity check. Make sure we're connected.
    if (!defined($server) || !defined($server->is_connected())) {
        _connect();
    }
    
    # Obtain the VM's lock.
    my $vmSemaphore = _getVMlock($class, $args{'config'});

    # Lock the VM.
    $vmSemaphore->down();

    # Register the VM...
    my $status = $server->register_vm($args{'config'});
    
    # Unlock the VM.
    $vmSemaphore->up();
    
    if (!defined($status)) {
        my ($errorNumber, $errorString) = $server->get_last_error();
        if ($errorString =~ /Virtual machine already exists/) {
            # Ignore errors where the VM is already registered...
            return (1);
        }
        $LOG->warn("Could not register VM ($args{'config'}). " .
                   "(" . $errorNumber . ": " . $errorString . ")");
        die SOAP::Fault->faultcode(__PACKAGE__ . "->registerVM()")
                       ->faultstring("Could not register VM ($args{'config'}).")
                       ->faultdetail(bless { errNo  => $errorNumber,
                                             errStr => $errorString },
                                     'err');
    }
    
    # Wait 5 seconds, so that the register completely finishes...
    sleep (5);
    
    return ($status);
}

=pod

=head2 unregisterVM(config => $config)

=over 4

Unregisters a specified VM.

I<Inputs>:
 B<$config> is the full, absolute path to the VM's
configuration file, as it sits on the host VMware Server / GSX server's
disk.

I<Output>: True if successful, false otherwise.

=back

=begin testing

# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Catch all errors, in order to make sure child processes are
# properly killed.
eval {

    $URL = HoneyClient::Manager::VM->init();
   
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");

    # Make sure the test VM is stopped and registered.
    $som = $stub->stopVM(config => $testVM);
    $som = $stub->registerVM(config => $testVM);

    # Test unregisterVM() method.
    $som = $stub->unregisterVM(config => $testVM);
    ok($som->result, "unregisterVM(config => '$testVM')") or diag("The unregisterVM() call failed.");

    # The test VM should be registered.
    $som = $stub->isRegisteredVM(config => $testVM);
    ok(!$som->result, "unregisterVM(config => '$testVM')") or diag("The unregisterVM() call failed.  If ($testVM) is still registered, be sure to unregister it manually.");
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::VM->destroy();
sleep (1);

# Report any failure found.
if ($@) {
    fail($@);
}

=end testing

=cut

sub unregisterVM {

    # Extract arguments.
    my ($class, %args) = @_;

    # Log resolved arguments.
    $LOG->debug(sub {
        # Make Dumper format more terse.
        $Data::Dumper::Terse = 1;
        $Data::Dumper::Indent = 0;
        Dumper(\%args);
    });
    
    # Sanity check.  Make sure there are no queued faults.
    _emitQueuedFault();
    
    # Sanity check.  Make sure we get a valid argument.
    my $argsExist = scalar(%args);
    if (!$argsExist || 
        !exists($args{'config'}) ||
        !defined($args{'config'})) {

        # Die if no valid argument is supplied.
        $LOG->warn("No VM configuration file supplied.");
        die SOAP::Fault->faultcode(__PACKAGE__ . "->unregisterVM()")
                       ->faultstring("No VM configuration file supplied.");
    }

    # Sanity check. Make sure we're connected.
    if (!defined($server) || !defined($server->is_connected())) {
        _connect();
    }
    
    # Disconnect from the VM...
    _disconnectVM();

    # Obtain the VM's lock.
    my $vmSemaphore = _getVMlock($class, $args{'config'});

    # Lock the VM.
    $vmSemaphore->down();
    
    # Unregister the VM...
    my $status = $server->unregister_vm($args{'config'});
    
    # Unlock the VM.
    $vmSemaphore->up();

    if (!defined($status)) {
        my ($errorNumber, $errorString) = $server->get_last_error();
        if ($errorString =~ /No such virtual machine/) {
            # Ignore errors where the VM is already unregistered...
            return (1);
        }
        $LOG->warn("Could not unregister VM ($args{'config'}). " .
                   "(" . $errorNumber . ": " . $errorString . ")");
        die SOAP::Fault->faultcode(__PACKAGE__ . "->unregisterVM()")
                       ->faultstring("Could not unregister VM ($args{'config'}).")
                       ->faultdetail(bless { errNo  => $errorNumber,
                                             errStr => $errorString },
                                     'err');
    }
    
    # Wait 5 seconds, so that the register completely finishes...
    sleep (5);
    
    return ($status);
}

=pod

=head2 answerVM(config => $config)

=over 4

Automatically answer any normal, pending questions for a specified VM.

I<Inputs>:
 B<$config> is the full, absolute path to the VM's
configuration file, as it sits on the host VMware Server / GSX server's
disk.

I<Output>: True if successful, false otherwise.

I<Notes>: This function attempts to answer (sanely) most of the 
normal questions that a VMware Server / GSX server usually asks
when powering on cloned or faulty VMs.

=back

=begin testing

# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Catch all errors, in order to make sure child processes are
# properly killed.
eval {

    $URL = HoneyClient::Manager::VM->init();
   
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");

    # Make sure the test VM is stopped and unregistered.
    $som = $stub->stopVM(config => $testVM);
    $som = $stub->unregisterVM(config => $testVM);

    # The only consistent way to get a VM into a stuck state,
    # is to manually copy a VM into a new directory, register it,
    # and then proceed to start it.  VMware Server / GSX will immediately
    # ask if we'd like to create a new identifier before
    # moving on.

    # Get the test VM's parent directory,
    # in order to create a temporary clone VM.
    my $testVMDir = dirname($testVM);
    my $cloneVMDir = dirname($testVMDir) . "/test_vm_clone";
    my $cloneVM = $cloneVMDir . "/" . basename($testVM);

    # Make the destDir.
    if (!dircopy($testVMDir, $cloneVMDir)) {
        fail("answerVM()");
        diag("Could not copy test VM directory ($testVMDir) for testing answerVM() method.");
    } else {
        # Update clone VM data permissions...
        chmod(oct(700), $cloneVM);
        chmod(oct(700), glob($cloneVMDir . "/*.nvram"));
        chmod(oct(600), glob($cloneVMDir . "/*.vms*"));
        chmod(oct(600), glob($cloneVMDir . "/*REDO*"));
    }

    # Register the clone VM.
    $som = $stub->registerVM(config => $cloneVM);

    # Start the clone VM.
    # Test answerVM() method.
    $som = $stub->startVM(config => $cloneVM);
    ok($som->result, "answerVM(config => '$cloneVM')") or diag("The answerVM() call failed.");

    # Destroy the clone VM.
    $som = $stub->destroyVM(config => $cloneVM);
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::VM->destroy();
sleep (1);

# Report any failure found.
if ($@) {
    fail($@);
}

=end testing

=cut

sub answerVM {
    
    # Extract arguments.    
    my ($class, %args) = @_;

    # Log resolved arguments.
    $LOG->debug(sub {
        # Make Dumper format more terse.
        $Data::Dumper::Terse = 1;
        $Data::Dumper::Indent = 0;
        Dumper(\%args);
    });
    
    # Sanity check.  Make sure there are no queued faults.
    _emitQueuedFault();
    
    # Sanity check.  Make sure we get a valid argument.
    my $argsExist = scalar(%args);
    if (!$argsExist || 
        !exists($args{'config'}) ||
        !defined($args{'config'})) {

        # Die if no valid argument is supplied.
        $LOG->warn("No VM configuration file supplied.");
        die SOAP::Fault->faultcode(__PACKAGE__ . "->answerVM()")
                       ->faultstring("No VM configuration file supplied.");
    }

    _connectVM($class, $args{'config'});
    
    # Make sure the VM is stuck.
    my $powerState = getStateVM($class, %args);

    if ($powerState != VM_EXECUTION_STATE_STUCK) {
        return (1);
    }

    # Obtain the VM's lock.
    my $vmSemaphore = _getVMlock($class, $args{'config'});

    # Lock the VM.
    $vmSemaphore->down();
    
    # Okay, get the pending question...
    my $question = $vm->get_pending_question();
    
    # Unlock the VM.
    $vmSemaphore->up();

    if (!defined($question)) {
        my ($errorNumber, $errorString) = $vm->get_last_error();
        $LOG->warn("Could not obtain question for VM ($args{'config'}). " .
                   "(" . $errorNumber . ": " . $errorString . ")");
        die SOAP::Fault->faultcode(__PACKAGE__ . "->answerVM()")
                       ->faultstring("Could not obtain question for VM ($args{'config'}).")
                       ->faultdetail(bless { errNo  => $errorNumber,
                                             errStr => $errorString },
                                     'err');
    }

    my $choice = undef;
    my $question_text = $question->get_text();
    $question_text =~ s/\n/ /g;
    SWITCH: for ($question_text) {
        # The location of this VM's configuration has changed since it was last
        # powered on.
        /The location of this virtual machine's configuration file has changed/ && 
            do { $choice = 1; last; }; # Choice 1: Create a new identifier.
    
        # The snapshot file may be corrupted; go ahead and ignore.
        /The snapshot file \".*\" may be corrupted and could not be restored./ && 
            do { $choice = 0; last; }; # Choice 0: OK.
        
        # No bootable media was found; go ahead and ignore.
        /No bootable CD, floppy or hard disk was detected./ && 
            do { $choice = 0; last; }; # Choice 0: OK.

        # Bad suspended image (vmss); go ahead and discard.
        /A file encapsulating the state of a virtual machine was discovered/ &&
            do { $choice = 0; last; }; # Choice 0: Discard.

        $LOG->warn("Encountered unknown question for VM ($args{'config'}). " .
                   "(" . $question->get_id() . ": " . $question_text . ")");
        die SOAP::Fault->faultcode(__PACKAGE__ . "->answerVM()")
                       ->faultstring("Encountered unknown question for VM ($args{'config'}).")
                       ->faultdetail(bless { errNo  => $question->get_id(),
                                             errStr => $question_text },
                                     'err');
    }

    # Now, answer the question accordingly...
    my $result = $vm->answer_question($question, $choice);
    if (!defined($result)) {
        my ($errorNumber, $errorString) = $vm->get_last_error();
        $LOG->warn("Could not answer known question for VM ($args{'config'}). " .
                   "(" . $errorNumber . ": " . $errorString . ")");
        die SOAP::Fault->faultcode(__PACKAGE__ . "->answerVM()")
                       ->faultstring("Could not answer known question for VM ($args{'config'}).")
                       ->faultdetail(bless { errNo  => $errorNumber,
                                             errStr => $errorString },
                                     'err');
    }

    return ($result);
}

=pod

=head2 destroyVM(config => $config)

=over 4

Destroys a specified VM.

I<Inputs>:
 B<$config> is the full, absolute path to the VM's
configuration file, as it sits on the host VMware Server / GSX server's
disk.

I<Output>: True if successful, false otherwise.

=back

=begin testing

# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Catch all errors, in order to make sure child processes are
# properly killed.
eval {

    $URL = HoneyClient::Manager::VM->init();
    
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");

    # Register the test VM.
    $som = $stub->registerVM(config => $testVM);

    # Get the test VM's parent directory,
    # in order to create a temporary clone VM.
    my $testVMDir = dirname($testVM);
    my $cloneVMDir = dirname($testVMDir) . "/test_vm_clone";
    my $cloneVM = $cloneVMDir . "/" . basename($testVM);

    # Clone the test VM.
    $som = $stub->fullCloneVM(src_config => $testVM, dest_dir => $cloneVMDir);

    # Wait a small amount of time for the asynchronous clone
    # to complete.
    sleep (15);

    # The clone VM should be on.
    $som = $stub->getStateVM(config => $cloneVM);

    # Since the clone VM doesn't have an OS installed on it,
    # the VM may be considered stuck.  Go ahead and answer
    # this question, if need be.
    if ($som->result == VM_EXECUTION_STATE_STUCK) {
        $som = $stub->answerVM(config => $cloneVM);
    }

    # Destroy the clone VM.
    $som = $stub->destroyVM(config => $cloneVM);

    # Test destroyVM() method.
    ok($som->result, "destroyVM(config => '$cloneVM')") or diag("The destroyVM() call failed.");

    # Check to make sure the clone VM is unregistered.
    $som = $stub->isRegisteredVM(config => $cloneVM);
    ok(!$som->result, "destroyVM(config => '$cloneVM')") or diag("The destroyVM() call failed.  If ($cloneVM) is still registered, be sure to unregister it manually.");

    # Stop and unregister the test VM.
    $som = $stub->stopVM(config => $testVM);
    $som = $stub->unregisterVM(config => $testVM);
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::VM->destroy();
sleep (1);

# Report any failure found.
if ($@) {
    fail($@);
}

=end testing

=cut

sub destroyVM {

    # Extract arguments.
    my ($class, %args) = @_;

    # Log resolved arguments.
    $LOG->debug(sub {
        # Make Dumper format more terse.
        $Data::Dumper::Terse = 1;
        $Data::Dumper::Indent = 0;
        Dumper(\%args);
    });
    
    # Sanity check.  Make sure there are no queued faults.
    _emitQueuedFault();
    
    # Sanity check.  Make sure we get a valid argument.
    my $argsExist = scalar(%args);
    if (!$argsExist || 
        !exists($args{'config'}) ||
        !defined($args{'config'})) {

        # Die if no valid argument is supplied.
        $LOG->warn("No VM configuration file supplied.");
        die SOAP::Fault->faultcode(__PACKAGE__ . "->destroyVM()")
                       ->faultstring("No VM configuration file supplied.");
    }
    
    # Sanity check: Make sure the referenced server is local;
    # otherwise, fail outright.
    if (!_isServerLocal()) {
        my $errorString = "Unable to perform operation on remote server ($serverName).";
        $LOG->warn($errorString);
        die SOAP::Fault->faultcode(__PACKAGE__ . "->destroyVM()")
                       ->faultstring($errorString);
    }
    
    # Sanity check. Make sure we're connected.
    if (!defined($server) || !defined($server->is_connected())) {
        _connect();
    }

    _connectVM($class, $args{'config'});
    
    # Make sure the VM is either suspended or turned off.
    my $powerState = getStateVM($class, %args);

    if ($powerState != VM_EXECUTION_STATE_SUSPENDED &&
        $powerState != VM_EXECUTION_STATE_OFF) {
        
        # Okay, the VM is alive; so stop it...
        stopVM($class, %args);
    }

    # Unregister the VM...
    unregisterVM($class, %args);
    
    # Find out the directory to delete...
    my $srcDir = dirname($args{'config'});

    # Obtain the VM's lock, if it exists.
    # If it exists, make sure to remove it from the global hashtable.
    # If it does not exist, then that means the VM is already destroyed.
    my $vmSemaphore = _destroyVMlock($class, $args{'config'});
    if (defined($vmSemaphore)) {
        # Lock the VM.
        $vmSemaphore->down();
    
        # Delete the VM from disk...
        unless (pathrmdir($srcDir)) {
            $LOG->warn("Could not destroy VM ($args{'config'}).");
            die SOAP::Fault->faultcode(__PACKAGE__ . "->destroyVM()")
                           ->faultstring("Could not destroy VM ($args{'config'}).");
        } 
        # Unlock the VM.
        $vmSemaphore->up();
    }

    return (1);
}

=pod

=head2 setMasterVM(config => $config, dont_register => $dontUnregister)

=over 4

Prepares a specified VM as a "Master VM image", to be used
for creating multiple subsequent "quick clone VMs".

I<Inputs>:
 B<$config> is the full, absolute path to the VM's
configuration file, as it sits on the host VMware Server / GSX server's
disk.
 B<$dontUnregister> is an optional argument, indicating if
the Master VM should be unregistered once set.  By default,
the Master VM is unregistered (to prevent the master VMs
contents from changing).  If this argument is defined, then
the Master VM will remain registered.

I<Output>: True if successful, false otherwise.

I<Notes>:
Once a Master VM is prepared, clone VMs can be quickly 
created, whose unique data is recorded as journalled
differences against the Master VM's image.

By default, the Master VM will automatically be unregistered,
since its hard disks must never change while quick clone
VMs are actively using them.

=back

=begin testing

# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Catch all errors, in order to make sure child processes are
# properly killed.
eval {

    $URL = HoneyClient::Manager::VM->init();
    
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");

    # Register the test VM.
    $som = $stub->registerVM(config => $testVM);

    # In order to test the setMasterVM() method,
    # we're going to clone the test VM, then set the clone
    # as a master VM, and finally, check to make sure
    # the corresponding permissions were set in the
    # clone, as per master VM specification.

    # Get the test VM's parent directory,
    # in order to create a temporary clone VM.
    my $testVMDir = dirname($testVM);
    my $cloneVMDir = dirname($testVMDir) . "/test_vm_clone";
    my $cloneVM = $cloneVMDir . "/" . basename($testVM);

    # Create the clone VM.
    $som = $stub->fullCloneVM(src_config => $testVM, dest_dir => $cloneVMDir);

    # Wait a small amount of time for the asynchronous clone
    # to complete.
    sleep (15);

    # The clone VM should be on.
    $som = $stub->getStateVM(config => $cloneVM);

    # Since the clone VM doesn't have an OS installed on it,
    # the VM may be considered stuck.  Go ahead and answer
    # this question, if need be.
    if ($som->result == VM_EXECUTION_STATE_STUCK) {
        $som = $stub->answerVM(config => $cloneVM);
    }

    # Set the clone as a master VM.
    $som = $stub->setMasterVM(config => $cloneVM);

    # Test setMasterVM() method.
    ok($som->result, "setMasterVM(config => '$cloneVM')") or diag("The setMasterVM() call failed.");

    my $mode = undef;
    foreach (glob($cloneVMDir . "/*.vmdk*"),
             glob($cloneVMDir . "/*.vms*"),
             glob($cloneVMDir . "/*.vme*")) {
        $mode = sprintf("%04o", stat($_)->mode & 07777);
        is($mode, "0440", "setMasterVM(config => '$cloneVM')") or diag("The setMasterVM() call failed.  Expected file ($_) to be mode 0440, but it was mode $mode instead.");
    }

    # Destroy the clone VM.
    $som = $stub->destroyVM(config => $cloneVM);

    # Stop and unregister the test VM.
    $som = $stub->stopVM(config => $testVM);
    $som = $stub->unregisterVM(config => $testVM);
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::VM->destroy();
sleep (1);

# Report any failure found.
if ($@) {
    fail($@);
}

=end testing

=cut

sub setMasterVM {

    # Extract arguments.
    my ($class, %args) = @_;

    # Log resolved arguments.
    $LOG->debug(sub {
        # Make Dumper format more terse.
        $Data::Dumper::Terse = 1;
        $Data::Dumper::Indent = 0;
        Dumper(\%args);
    });
    
    # Sanity check.  Make sure there are no queued faults.
    _emitQueuedFault();
    
    # Sanity check.  Make sure we get a valid argument.
    my $argsExist = scalar(%args);
    if (!$argsExist || 
        !exists($args{'config'}) ||
        !defined($args{'config'})) {

        # Die if no valid argument is supplied.
        $LOG->warn("No VM configuration file supplied.");
        die SOAP::Fault->faultcode(__PACKAGE__ . "->setMasterVM()")
                       ->faultstring("No VM configuration file supplied.");
    }
    
    # Sanity check: Make sure the referenced server is local;
    # otherwise, fail outright.
    if (!_isServerLocal()) {
        my $errorString = "Unable to perform operation on remote server ($serverName).";
        $LOG->warn($errorString);
        die SOAP::Fault->faultcode(__PACKAGE__ . "->setMasterVM()")
                       ->faultstring($errorString);
    }

    # Sanity check. Make sure we're connected.
    if (!defined($server) || !defined($server->is_connected())) {
        _connect();
    }
    
    _connectVM($class, $args{'config'});
    
    # Get the source directory that contains the VM data.
    my $srcDir = dirname($args{'config'});

    # Sanity check. Make sure the source VM does NOT have any
    # *REDO* files.  This implies that the source VM was
    # already in undoable mode and has uncommitted changes
    # that need to be committed back to the main VMDK, prior
    # to being used as a "master" VM.
    #
    # We can't perform this commit operation programmatically
    # using either VMware GSX or VMware Server.  We could, if
    # we were using ESX, but we arn't.  As such, we ask the user
    # to do this manually in the fault message.

    if (defined(glob($srcDir . "/*REDO*"))) {
        my $errorString = "Unable to set VM ($args{'config'}) as master.  Source directory contains *REDO* files that need to be committed back to the main VMDK disk.  Commit or discard these changes manually and try again.";
        $LOG->warn($errorString);
        die SOAP::Fault->faultcode(__PACKAGE__ . "->setMasterVM()")
                       ->faultstring($errorString);
    }
    
    # Make sure the VM is either suspended or turned off.
    my $powerState = getStateVM($class, %args);

    if ($powerState != VM_EXECUTION_STATE_SUSPENDED &&
        $powerState != VM_EXECUTION_STATE_OFF) {
        
        # Okay, the VM is alive; so suspend it...
        suspendVM($class, %args);
    }

    # Disconnect from the VM...
    _disconnectVM();
    
    # Unregister the VM...
    if (!$argsExist || 
        !exists($args{'dont_unregister'}) ||
        !defined($args{'dont_unregister'})) {
        unregisterVM($class, %args);
    }

    # Modify the permissions of all Master *.vmdk*, *.vms*, and *.vme* files
    # to 0440, in order to prevent any accidental overwrites by a quick
    # clone VM...
    chmod(oct(440), glob($srcDir . "/*.vmdk*"));
    chmod(oct(440), glob($srcDir . "/*.vms*"));
    chmod(oct(440), glob($srcDir . "/*.vme*"));
    chmod(oct(660), glob($srcDir . "/*.vmdk.READLOCK"));
    
    # Now, edit the Master configuration file in order to support
    # quick clones...
    my @configArray = undef;

    # Obtain the VM's lock.
    my $vmSemaphore = _getVMlock($class, $args{'config'});

    # Lock the VM.
    $vmSemaphore->down();

    if (!tie(@configArray, 'Tie::File', $args{'config'})) {
        # Unlock VM early, if failed.
        $vmSemaphore->up();
        $LOG->warn("Could not set Master VM ($args{'config'}).");
        die SOAP::Fault->faultcode(__PACKAGE__ . "->setMasterVM()")
                       ->faultstring("Could not set Master VM ($args{'config'}).");
    }

    for (@configArray) {
        # Make sure the master VM configuration version is "7", since
        # versions 8 and higher have marked the undoable mode operation
        # as deprecated, as it's implemented differently.
        s/^config.version.*$/config.version = "7"/g;
        # Switch all virtual disks to undoable mode...
        s/^(.*)\.mode = "persistent"$/$1\.mode = "undoable"/g;
        # Make sure all *.vmdk files are specified with absolute paths...
        s/^(.*)\.fileName = "(.*\/)*(.*\.vmdk)"$/$1\.fileName = \"$srcDir\/$3\"/g;
    }
    untie @configArray;
    
    # Unlock the VM.
    $vmSemaphore->up();

    # Lock access to the master VM variable.
    $masterVMSemaphore->down();

    # Set this Master VM's config to be our global master config...
    $vmMasterConfig = $args{'config'};
    
    # Unlock access to the master VM variable.
    $masterVMSemaphore->up();

    return (1);
}

=pod

=head2 quickCloneVM(src_config => $config, dest_dir => $destDir)

=over 4

Creates a differential clone, using a specified master VM
as a basis.

I<Inputs>:
 B<$config> is an optional argument, specifying the full, 
absolute path to the source Master VM's configuration file, 
as it sits on the host VMware Server / GSX server's disk.
 B<$destDir> is an optional argument, containing the absolute
path where the quick clone VM's contents will reside.

I<Output>: Absolute path of the cloned VM's configuration file,
if successful.

I<Notes>:
If B<$config> is not specified, then this function will 
attempt to use the last Master VM configuration that was 
specified via the setMasterVM() function.  Otherwise, if a 
Master VM configuration was passed to this function, then it 
will become the global Master VM and this function will 
create a corresponding quick clone.

If B<$config> is not specified and no Master VM was set
via a previous setMasterVM() call, then this function will
fail.

If B<$destDir> is not specified, then the cloned VM 
will reside in a subdirectory within the main directory
specified by the global B<$DATASTORE_PATH> variable.

The format of this automatically generated subdirectory will
be a randomly generated hexadecimal string of the length
$VM_ID_LENGTH.

Quick cloning VMs can be a time consuming operation, 
depending on how big the VM is.  This is because the most
VM data is copied, including all *REDO data.  As such,
the web service call completes while these filesystem-intensive
operations are performed in the background within a
child thread.

Once cloned, the new VM will be automatically
started, in order to update the VM's unique UUID and
the VM's network MAC address.

Thus, it is recommended that once a quickCloneVM() operation
is performed, you call getStateVM() on the cloned VM's
configuration file to make sure the VM is powered on,
B<prior> to performing B<any additional operations> on
the cloned VM.

=back

=begin testing

# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Catch all errors, in order to make sure child processes are
# properly killed.
eval {

    $URL = HoneyClient::Manager::VM->init();
    
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");

    # Register the test VM.
    $som = $stub->registerVM(config => $testVM);

    # In order to test the quickCloneVM() method,
    # we're going to fully clone the test VM, then set the 
    # newly created clone as a master VM, and finally, 
    # create a secondary quick clone from the master VM.

    # Get the test VM's parent directory,
    # in order to create a temporary master and clone VM.
    my $testVMDir = dirname($testVM);
    my $masterVMDir = dirname($testVMDir) . "/test_vm_master";
    my $cloneVMDir = dirname($testVMDir) . "/test_vm_clone";
    my $masterVM = $masterVMDir . "/" . basename($testVM);
    my $cloneVM = $cloneVMDir . "/" . basename($testVM);

    # Create the master VM.
    $som = $stub->fullCloneVM(src_config => $testVM, dest_dir => $masterVMDir);

    # Wait a small amount of time for the asynchronous clone
    # to complete.
    sleep (60);

    # The master VM should be on.
    $som = $stub->getStateVM(config => $masterVM);

    # Since the master VM doesn't have an OS installed on it,
    # the VM may be considered stuck.  Go ahead and answer
    # this question, if need be.
    if ($som->result == VM_EXECUTION_STATE_STUCK) {
        $som = $stub->answerVM(config => $masterVM);
    }

    # Set the master VM as a true master.
    $som = $stub->quickCloneVM(src_config => $masterVM, dest_dir => $cloneVMDir);
   
    # Test quickCloneVM() method.
    is($som->result, $cloneVM, "quickCloneVM(src_config => '$masterVM', dest_dir => '$cloneVMDir')") or diag("The quickCloneVM() call failed.");
    
    # Wait a small amount of time for the asynchronous clone
    # to complete.
    sleep (60);
    
    # The clone VM should be on.
    $som = $stub->getStateVM(config => $cloneVM);

    # Since the clone VM doesn't have an OS installed on it,
    # the VM may be considered stuck.  Go ahead and answer
    # this question, if need be.
    if ($som->result == VM_EXECUTION_STATE_STUCK) {
        $som = $stub->answerVM(config => $cloneVM);
        # Fetch the state again, to see if it's now ON.
        $som = $stub->getStateVM(config => $cloneVM);
    }
    is($som->result, VM_EXECUTION_STATE_ON, "quickCloneVM(src_config => '$masterVM', dest_dir => '$cloneVMDir')") or diag("The quickCloneVM() call failed.  Attempted to quick clone VM ($masterVM) at ($cloneVM), but the cloned VM state was not reported as ON.");

    # Destroy the clone and master VM.
    $som = $stub->destroyVM(config => $cloneVM);
    $som = $stub->destroyVM(config => $masterVM);

    # Stop and unregister the test VM.
    $som = $stub->stopVM(config => $testVM);
    $som = $stub->unregisterVM(config => $testVM);
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::VM->destroy();
sleep (1);

# Report any failure found.
if ($@) {
    fail($@);
}

=end testing

=cut

sub quickCloneVM {

    # Extract arguments.
    my ($class, %args) = @_;

    # Log resolved arguments.
    $LOG->debug(sub {
        # Make Dumper format more terse.
        $Data::Dumper::Terse = 1;
        $Data::Dumper::Indent = 0;
        Dumper(\%args);
    });
    
    # Sanity check.  Make sure there are no queued faults.
    _emitQueuedFault();
    
    # Sanity check: Make sure the referenced server is local;
    # otherwise, fail outright.
    if (!_isServerLocal()) {
        my $errorString = "Unable to perform operation on remote server ($serverName).";
        $LOG->warn($errorString);
        die SOAP::Fault->faultcode(__PACKAGE__ . "->quickCloneVM()")
                       ->faultstring($errorString);
    }
    
    # Sanity check. Make sure we're connected.
    if (!defined($server) || !defined($server->is_connected())) {
        _connect();
    }

    my $argsExist = scalar(%args);
    if ($argsExist && 
        exists($args{'src_config'}) &&
        defined($args{'src_config'})) {

        setMasterVM($class, (config => $args{'src_config'}, dont_register => 1));
    } else {

        # Lock access to the master VM variable.
        $masterVMSemaphore->down();

        # Extract current master VM.
        $args{'src_config'} = $vmMasterConfig;
        
        # Unlock master VM config.
        $masterVMSemaphore->up();
    }
    
    my $errorString = undef;
    if (!defined($args{'src_config'})) {
        $errorString = "No Master VM specified; could not make Clone VM.";
        $LOG->warn($errorString);
        die SOAP::Fault->faultcode(__PACKAGE__ . "->quickCloneVM()")
                       ->faultstring($errorString);
    }
    
    _connectVM($class, $args{'src_config'});
    
    # Make sure the source VM is either suspended or turned off.
    my $powerState = getStateVM($class, (config => $args{'src_config'}));

    if ($powerState != VM_EXECUTION_STATE_SUSPENDED &&
        $powerState != VM_EXECUTION_STATE_OFF) {
        
        # Okay, the VM is alive; so suspend it...
        suspendVM($class, (config => $args{'src_config'}));
    }
    unregisterVM($class, (config => $args{'src_config'}));

    # Pick a new destDir, if need be.
    my $dirName = undef;
    if (!$argsExist || 
        !exists($args{'dest_dir'}) ||
        !defined($args{'dest_dir'})) {
        do {
            $dirName = _generateVMID();
            $args{'dest_dir'} = $DATASTORE_PATH . "/" . $dirName;
            # Loop until we've found a non-existant dir.
        } while (-d $args{'dest_dir'});
    } else {
        $dirName = basename($args{'dest_dir'});
    }

    # Make the destDir.
    if (!mkdir($args{'dest_dir'}, oct(700))) {
        $errorString = "Could not make Clone VM directory ($args{'dest_dir'}).";
        $LOG->warn($errorString);
        die SOAP::Fault->faultcode(__PACKAGE__ . "->quickCloneVM()")
                       ->faultstring($errorString);
    }

    my $srcDir = dirname($args{'src_config'});
    my $configFile = basename($args{'src_config'});
    my $destConfig = $args{'dest_dir'} . "/" . $configFile;
        
    # Perform the copy operation...
    # Since this may take awhile, we perform the remaining operations in a child thread.
    my $thread = async {

        # Register a kill signal handler.
        # This handler is designed to kill this thread upon overall module
        # destruction.  This handler should never be used for normal program
        # operations, since it will NOT release any locks/semaphores properly.
        local $SIG{USR1} = sub { threads->exit(); };

        $maxThreadSemaphore->down();
        threads->yield();
            
        # Obtain the source VM's lock.
        my $vmSemaphore = _getVMlock($class, $args{'src_config'});
        
        local $SIG{INT} = sub { 
            my $LOG = get_logger();
            $LOG->warn("Asynchronous clone of ($srcDir) interrupted!");
            # Release any acquired locks.
            $vmSemaphore->up();
            $maxThreadSemaphore->up();
            return;
        };

        # Trap all faults that may occur from these asynchronous operations.
        # None of the VmPerl objects are thread-safe, so in order to perform the following
        # commands, we must do callbacks to the main thread over SOAP.
        # Yes, this is annoying and ugly.
        eval {

            # Lock the source VM.
            $vmSemaphore->down();
    
            # Copy the Master VM files to the clone VM directory...
            foreach (glob($srcDir . "/" . $configFile),
                     glob($srcDir . "/*.nvram"),
                     glob($srcDir . "/*.vmss"),
                     glob($srcDir . "/*REDO*"),
                     glob($srcDir . "/*.vme*")) {
                if (!copy($_, $args{'dest_dir'})) {
                    # Unlock the source VM, if fail.
                    $vmSemaphore->up();

                    $errorString = "Could not copy Master VM files to directory ($args{'dest_dir'}).";
                    $LOG->warn($errorString);
                    die SOAP::Fault->faultcode(__PACKAGE__ . "->quickCloneVM()")
                                   ->faultstring($errorString);
                }
            }
            
            # Unlock the source VM.
            $vmSemaphore->up();

            # Update clone VM data permissions...
            chmod(oct(700), glob($args{'dest_dir'} . "/" . $configFile));
            chmod(oct(700), glob($args{'dest_dir'} . "/*.nvram"));
            chmod(oct(600), glob($args{'dest_dir'} . "/*.vmss"));
            chmod(oct(600), glob($args{'dest_dir'} . "/*REDO*"));
            chmod(oct(600), glob($args{'dest_dir'} . "/*.vme*"));
            
            # Register the clone...
            _callback($class, "registerVM", (config => $destConfig));

            # Update the cloned VM's displayName...
            _callback($class, "setNameVM", (config => $destConfig, name => $dirName));

            # Now start the VM to update the identifier...    
            _callback($class, "startVM", (config => $destConfig));

            # If the Master VM was suspended, then this clone
            # will awake from a suspended state.  We'll still
            # need to issue a full reboot, in order for the
            # clone to get assigned a new network MAC address.
            if ($powerState == VM_EXECUTION_STATE_SUSPENDED) {
                _callback($class, "rebootVM", (config => $destConfig));
            }
        };

        # For any faults that did occur from the previous operations, be sure
        # to report them back via the fault queue.
        if ($@) {
            _queueFault($@);
        }

        $maxThreadSemaphore->up();
        return;
    };

    return ($destConfig);
}

=pod

=head2 snapshotVM(config => $config, snapshot_file => $snapshotFile)

=over 4

Creates a snapshot of a specified VM.

I<Inputs>:
 B<$config> is the full, absolute path to the VM's
configuration file, as it sits on the host VMware Server / GSX server's
disk.
 B<$snapshotFile> is an optional argument, indicating the
full, absolute path and filename of where the snapshot
file should be stored.

I<Output>: Absolute path to the snapshot file, if successful.

I<Notes>:
If B<$snapshotFile> is not specified, all snapshots
will be stored within the directory specified by the 
global variable B<$SNAPSHOT_PATH>, by default.

The format of this destination directory is:
S<"$SNAPSHOT_PATH/$VMDIRNAME-YYYYMMDDThhmmss.tar.gz">, 
using ISO8601 date format variables.

Once executed, the function will attempt to:
 - Suspend the VM, if it's running.
 - Package and compress all data within the VM's subdirectory, where
   the archive resides at the snapshot location.
 - Start the VM back up, if it was on previously.

=back

=begin testing

# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Catch all errors, in order to make sure child processes are
# properly killed.
eval {

    $URL = HoneyClient::Manager::VM->init();
    
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");

    # Register the test VM.
    $som = $stub->registerVM(config => $testVM);

    # Get the test VM's parent directory,
    # in order to create a temporary clone VM.
    my $testVMDir = dirname($testVM);
    my $cloneVMDir = dirname($testVMDir) . "/test_vm_clone";
    my $cloneVM = $cloneVMDir . "/" . basename($testVM);

    # Specify where the snapshot should be created.
    my $snapshot = dirname($testVMDir) . "/test_vm_clone.tar.gz";

    # In order to test the snapshotVM() method, we create
    # a full clone VM, power it on, create a snapshot, and
    # then revert the clone back to the snapshot.

    # Create the clone VM.
    $som = $stub->fullCloneVM(src_config => $testVM, dest_dir => $cloneVMDir);

    # Wait a small amount of time for the asynchronous clone
    # to complete.
    sleep (30);

    # The clone VM should be on.
    $som = $stub->getStateVM(config => $cloneVM);

    # Since the clone VM doesn't have an OS installed on it,
    # the VM may be considered stuck.  Go ahead and answer
    # this question, if need be.
    if ($som->result == VM_EXECUTION_STATE_STUCK) {
        $som = $stub->answerVM(config => $cloneVM);
    }
 
    # Snapshot the running clone.
    $som = $stub->snapshotVM(config => $cloneVM, snapshot_file => $snapshot);

    # Test snapshotVM() method.
    is($som->result, $snapshot, "snapshotVM(config => '$cloneVM', snapshot_file => '$snapshot')") or diag("The snapshotVM() call failed.");

    # Wait a small amount of time for the asynchronous snapshot
    # to complete.
    sleep (45);

    # Now, revert the VM using the snapshot.
    $som = $stub->revertVM(config => $cloneVM, snapshot_file => $snapshot);
    is($som->result, $cloneVM, "snapshotVM(config => '$cloneVM', snapshot_file => '$snapshot')") or diag("The snapshotVM() call failed.");
    
    # Wait a small amount of time for the asynchronous revert
    # to complete.
    sleep (60);

    # Make sure the clone VM is started.
    $som = $stub->getStateVM(config => $cloneVM);
    $som = $stub->startVM(config => $cloneVM);

    # Wait for the clone VM to be started.
    sleep (60);

    # The clone VM should be on.
    $som = $stub->getStateVM(config => $cloneVM);

    # Since the clone VM doesn't have an OS installed on it,
    # the VM may be considered stuck.  Go ahead and answer
    # this question, if need be.
    if ($som->result == VM_EXECUTION_STATE_STUCK) {
        $som = $stub->answerVM(config => $cloneVM);
        # Fetch the state again, to see if it's now ON.
        $som = $stub->getStateVM(config => $cloneVM);
    }
    is($som->result, VM_EXECUTION_STATE_ON, "snapshotVM(config => '$cloneVM', snapshot_file => '$snapshot')") or diag("The snapshotVM() call failed.  Attempted to snapshot VM ($cloneVM), but the VM state was not reported as ON.");

    # Destroy the clone VM.
    $som = $stub->destroyVM(config => $cloneVM);

    # Destroy the snapshot.
    unlink $snapshot;

    # Stop and unregister the test VM.
    $som = $stub->stopVM(config => $testVM);
    $som = $stub->unregisterVM(config => $testVM);
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::VM->destroy();
sleep (1);

# Report any failure found.
if ($@) {
    fail($@);
}

=end testing

=cut

sub snapshotVM {

    # Extract arguments.    
    my ($class, %args) = @_;

    # Log resolved arguments.
    $LOG->debug(sub {
        # Make Dumper format more terse.
        $Data::Dumper::Terse = 1;
        $Data::Dumper::Indent = 0;
        Dumper(\%args);
    });
    
    # Sanity check.  Make sure there are no queued faults.
    _emitQueuedFault();
    
    # Sanity check.  Make sure we get a valid argument.
    my $argsExist = scalar(%args);
    if (!$argsExist || 
        !exists($args{'config'}) ||
        !defined($args{'config'})) {

        # Die if no valid argument is supplied.
        $LOG->warn("No VM configuration file supplied.");
        die SOAP::Fault->faultcode(__PACKAGE__ . "->snapshotVM()")
                       ->faultstring("No VM configuration file supplied.");
    }

    # Sanity check: Make sure the referenced server is local;
    # otherwise, fail outright.
    if (!_isServerLocal()) {
        my $errorString = "Unable to perform operation on remote server ($serverName).";
        $LOG->warn($errorString);
        die SOAP::Fault->faultcode(__PACKAGE__ . "->snapshotVM()")
                       ->faultstring($errorString);
    }
    _connectVM($class, $args{'config'});

    # Make sure the source VM is either suspended or turned off.
    my $powerState = getStateVM($class, %args);

    # Identify where the VM and snapshot data are located...
    my $vmDir = dirname($args{'config'});
    my $dirName = basename($vmDir);
    if (!$argsExist || 
        !exists($args{'snapshot_file'}) ||
        !defined($args{'snapshot_file'})) {
        my $dt = DateTime::HiRes->now();
        my $date = $dt->ymd('') . 'T' . $dt->hms('');
        $args{'snapshot_file'} = "$SNAPSHOT_PATH/$dirName-$date.tar.bz2";
    }

    # Perform the snapshot operations...
    # Since this usually takes awhile, we perform the remaining operations in a child thread.
    my $thread = async {

        # Register a kill signal handler.
        # This handler is designed to kill this thread upon overall module
        # destruction.  This handler should never be used for normal program
        # operations, since it will NOT release any locks/semaphores properly.
        local $SIG{USR1} = sub { threads->exit(); };

        $maxThreadSemaphore->down();
        threads->yield();
            
        # Obtain the VM's lock.
        my $vmSemaphore = _getVMlock($class, $args{'config'});
        
        local $SIG{INT} = sub { 
            my $LOG = get_logger();
            $LOG->warn("Asynchronous snapshot of ($vmDir) interrupted!");
            # Release any acquired locks.
            $vmSemaphore->up();
            $maxThreadSemaphore->up();
            return;
        };

        # Trap all faults that may occur from these asynchronous operations.
        # None of the VmPerl objects are thread-safe, so in order to perform the following
        # commands, we must do callbacks to the main thread over SOAP.
        # Yes, this is annoying and ugly.
        eval {

            if ($powerState != VM_EXECUTION_STATE_SUSPENDED &&
                $powerState != VM_EXECUTION_STATE_OFF) {
        
                # Okay, the VM is alive; so suspend it...
                _callback($class, "suspendVM", %args);
            }

            # Now, temporarily unregister the VM, in order to ensure
            # it doesn't get used while we snapshot it.
            _callback($class, "unregisterVM", %args);

            # Lock the VM.
            $vmSemaphore->down();

            # Lock chdirSemaphore.
            $chdirSemaphore->down();
            
            # Change directories, in order to archive with relative paths...
            my $pwd = $ENV{PWD};
            my $parentDir = dirname($vmDir);
            chdir $parentDir;
            my @fileList = glob($dirName . "/*");
            chdir $pwd;

            # Unlock chdirSemaphore.
            $chdirSemaphore->up();

            if (system(getVar(name => "bin_tar"), '-C', $parentDir, '-jcpf', $args{'snapshot_file'}, @fileList) != 0) {
                # Unlock VM, if fail.
                $vmSemaphore->up();
                $LOG->warn("Could not snapshot VM to ($args{'snapshot_file'}). " .
                           "(" . $? . ": " . $! . ")");
                die SOAP::Fault->faultcode(__PACKAGE__ . "->snapshotVM()")
                               ->faultstring("Could not snapshot VM to ($args{'snapshot_file'}).")
                               ->faultdetail(bless { errNo  => $?,
                                                     errStr => $!},
                                             'err');
            }
            
            # Unlock the VM.
            $vmSemaphore->up();
        
            # Now, reregister the VM...
            _callback($class, "registerVM", %args);

            # Turn the VM back on, if it was on previously...
            if ($powerState == VM_EXECUTION_STATE_ON) {
                _callback($class, "startVM", %args);
            }
        };

        # For any faults that did occur from the previous operations, be sure
        # to report them back via the fault queue.
        if ($@) {
            _queueFault($@);
        }
        $maxThreadSemaphore->up();
        return;
    };

    return ($args{'snapshot_file'});
}

=pod

=head2 revertVM(config => $config, snapshot_file => $snapshotFile)

=over 4

Reverts a specified VM back to a previous snapshot.

I<Inputs>:
 B<$config> is the full, absolute path to the VM's
configuration file, as it sits on the host VMware Server / GSX server's
disk.
 B<$snapshotFile> is an optional argument, indicating the
full, absolute path and filename of where the snapshot
file is stored.

I<Output>: Absolute path to the VM's configuration file,
if successful.

I<Notes>:
If B<$snapshotFile> is not specified, it will be assumed
that the VM should be re-quickCloned from the Master VM.
If the specified VM is not a quick clone, then this operation will fail.

Once executed, the function will attempt to:
 - Stop the VM, if it's running.
 - Destroy the VM contents.
 - Extract snapshot or re-quickClone from Master VM.
 - Start the VM back up, if it was on previously.

=back

=begin testing

# Shared test variables.
my $PORT = getVar(name      => "port",
                  namespace => "HoneyClient::Manager::VM");
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Catch all errors, in order to make sure child processes are
# properly killed.
eval {

    $URL = HoneyClient::Manager::VM->init();
    
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");

    # Register the test VM.
    $som = $stub->registerVM(config => $testVM);

    # Get the test VM's parent directory,
    # in order to create a temporary clone VM.
    my $testVMDir = dirname($testVM);
    my $cloneVMDir = dirname($testVMDir) . "/test_vm_clone";
    my $cloneVM = $cloneVMDir . "/" . basename($testVM);

    # Specify where the snapshot should be created.
    my $snapshot = dirname($testVMDir) . "/test_vm_clone.tar.gz";

    # In order to test the revertVM() method, we create
    # a full clone VM, power it on, create a snapshot, and
    # then revert the clone back to the snapshot.

    # Create the clone VM.
    $som = $stub->fullCloneVM(src_config => $testVM, dest_dir => $cloneVMDir);

    # Wait a small amount of time for the asynchronous clone
    # to complete.
    sleep (30);

    # The clone VM should be on.
    $som = $stub->getStateVM(config => $cloneVM);

    # Since the clone VM doesn't have an OS installed on it,
    # the VM may be considered stuck.  Go ahead and answer
    # this question, if need be.
    if ($som->result == VM_EXECUTION_STATE_STUCK) {
        $som = $stub->answerVM(config => $cloneVM);
    }
 
    # Snapshot the running clone.
    $som = $stub->snapshotVM(config => $cloneVM, snapshot_file => $snapshot);

    # Wait a small amount of time for the asynchronous snapshot
    # to complete.
    sleep (60);

    # Now, revert the VM using the snapshot.
    $som = $stub->revertVM(config => $cloneVM, snapshot_file => $snapshot);

    # Test revertVM() method.
    is($som->result, $cloneVM, "revertVM(config => '$cloneVM', snapshot_file => '$snapshot')") or diag("The revertVM() call failed.");
    
    # Wait a small amount of time for the asynchronous revert
    # to complete.
    sleep (60);

    # Make sure the clone VM is started.
    $som = $stub->getStateVM(config => $cloneVM);
    $som = $stub->startVM(config => $cloneVM);

    # Wait a small amount of time for the start to occur.
    sleep (60);

    # The clone VM should be on.
    $som = $stub->getStateVM(config => $cloneVM);

    # Since the clone VM doesn't have an OS installed on it,
    # the VM may be considered stuck.  Go ahead and answer
    # this question, if need be.
    if ($som->result == VM_EXECUTION_STATE_STUCK) {
        $som = $stub->answerVM(config => $cloneVM);
        # Fetch the state again, to see if it's now ON.
        $som = $stub->getStateVM(config => $cloneVM);
    }
    is($som->result, VM_EXECUTION_STATE_ON, "revertVM(config => '$cloneVM', snapshot_file => '$snapshot')") or diag("The revertVM() call failed.  Attempted to revert VM ($cloneVM) using snapshot file ($snapshot), but the VM state was not reported as ON.");

    # Destroy the clone VM.
    $som = $stub->destroyVM(config => $cloneVM);

    # Destroy the snapshot.
    unlink $snapshot;

    # Stop and unregister the test VM.
    $som = $stub->stopVM(config => $testVM);
    $som = $stub->unregisterVM(config => $testVM);
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::VM->destroy();
sleep (1);

# Report any failure found.
if ($@) {
    fail($@);
}

=end testing

=cut

sub revertVM {

    # Extract arguments.    
    my ($class, %args) = @_;

    # Log resolved arguments.
    $LOG->debug(sub {
        # Make Dumper format more terse.
        $Data::Dumper::Terse = 1;
        $Data::Dumper::Indent = 0;
        Dumper(\%args);
    });
    
    # Sanity check.  Make sure there are no queued faults.
    _emitQueuedFault();
    
    # Sanity check.  Make sure we get a valid argument.
    my $argsExist = scalar(%args);
    if (!$argsExist || 
        !exists($args{'config'}) ||
        !defined($args{'config'})) {

        # Die if no valid argument is supplied.
        $LOG->warn("No VM configuration file supplied.");
        die SOAP::Fault->faultcode(__PACKAGE__ . "->revertVM()")
                       ->faultstring("No VM configuration file supplied.");
    }
    
    # Sanity check: Make sure the referenced server is local;
    # otherwise, fail outright.
    if (!_isServerLocal()) {
        my $errorString = "Unable to perform operation on remote server ($serverName).";
        $LOG->warn($errorString);
        die SOAP::Fault->faultcode(__PACKAGE__ . "->revertVM()")
                       ->faultstring($errorString);
    }

    _connectVM($class, $args{'config'});

    my $vmDir = dirname($args{'config'});
    my $configFile = basename($args{'config'});
    my $masterConfig = undef;

    # Sanity check: If no snapshot was provided, make sure a
    # quick clone was specified, before we do anything drastic...
    if (!$argsExist || 
        !exists($args{'snapshot_file'}) ||
        !defined($args{'snapshot_file'})) {
        my @configArray = undef;
        unless (tie(@configArray, 'Tie::File', $args{'config'})) { 
            $LOG->warn("Could not read VM configuration ($args{'config'}).");
            die SOAP::Fault->faultcode(__PACKAGE__ . "->revertVM()")
                           ->faultstring("Could not read VM configuration ($args{'config'}).");
        }
        for (@configArray) {
            # Make sure all *.vmdk files are specified with absolute paths
            # to a Master VM...
            if (/^(.*)\.fileName = "(.*\/)*(.*\.vmdk)"$/) {
                $masterConfig = "$2$configFile";
                if ((!-d $2) || (dirname("$2/x") eq dirname("$vmDir/x"))) { 
                    $LOG->warn("Could not revert; specified VM is not a quick clone ($2$3).");
                    die SOAP::Fault->faultcode(__PACKAGE__ . "->revertVM()")
                                   ->faultstring("Could not revert; specified VM is not a quick clone ($2$3).");
                }
            }
        }
        untie @configArray;
    }

    # If we've gotten this far, then we're ready to start the revert process.
    # Recored whether or not the VM is on...
    my $powerState = getStateVM($class, %args);

    # Perform the revert operation...
    # Since this may take awhile, we perform the remaining operations in a child thread.
    my $thread = async {

        # Register a kill signal handler.
        # This handler is designed to kill this thread upon overall module
        # destruction.  This handler should never be used for normal program
        # operations, since it will NOT release any locks/semaphores properly.
        local $SIG{USR1} = sub { threads->exit(); };

        $maxThreadSemaphore->down();
        threads->yield();
        
        # Obtain the VM's lock.
        my $vmSemaphore = _getVMlock($class, $args{'config'});
        
        local $SIG{INT} = sub { 
            my $LOG = get_logger();
            $LOG->warn("Asynchronous revert of ($vmDir) interrupted!");
            $maxThreadSemaphore->up();
            return;
        };

        # Trap all faults that may occur from these asynchronous operations.
        # None of the VmPerl objects are thread-safe, so in order to perform the following
        # commands, we must do callbacks to the main thread over SOAP.
        # Yes, this is annoying and ugly.
        eval {

            # Okay, now destroy the VM...
            _callback($class, "destroyVM", %args);

            if (!$argsExist || 
                !exists($args{'snapshot_file'}) ||
                !defined($args{'snapshot_file'})) {
                # We're reverting a quick clone with no snapshot.
                # Proceed as normal.
                _callback($class, "quickCloneVM", (src_config => $masterConfig, dest_dir => $vmDir));

            } else {
                # We're reverting, using a snapshot...
                my $parentDir = dirname($vmDir);
                
                # Lock the VM.
                $vmSemaphore->down();

                if (system(getVar(name => "bin_tar"), '-C', $parentDir, '-jxpf', $args{'snapshot_file'}) != 0) {
                    # Unlock VM, if fail.
                    $vmSemaphore->up();

                    $LOG->warn("Could not revert VM from snapshot ($args{'snapshot_file'}). " .
                               "(" . $? . ": " . $! . ")");
                    die SOAP::Fault->faultcode(__PACKAGE__ . "->revertVM()")
                                   ->faultstring("Could not revert VM from snapshot ($args{'snapshot_file'}).")
                                   ->faultdetail(bless { errNo  => $?,
                                                         errStr => $!},
                                                 'err');
                }    
                # Unlock VM.
                $vmSemaphore->up();

                # Now, reregister the VM...
                _callback($class, "registerVM", %args);

                # Turn the VM back on, if it was on previously...
                if ($powerState == VM_EXECUTION_STATE_ON) {
                    _callback($class, "startVM", %args);
                }
            }
        };

        # For any faults that did occur from the previous operations, be sure
        # to report them back via the fault queue.
        if ($@) {
            _queueFault($@);
        }
        $maxThreadSemaphore->up();
        return;
    };

    return ($args{'config'});
}

#######################################################################
# Module Shutdown                                                     #
#######################################################################

END {

    # Verify all sub threads are finished, prior to shutting down.
    my $thread;
    foreach $thread (threads->list()) {
        # Don't kill/detach the main thread or ourselves.
        if ($thread->tid() && !threads::equal($thread, threads->self())) {
            # Kill the child thread, if it's running.
            if ($thread->is_running()) {
                $thread->kill('USR1');
            }
            # Detach the child thread.
            # We actually do not do this, since it's been found
            # that VmPerl causes malloc errors, due to the fact
            # that the library is not threadsafe.  Instead,
            # we rely on perl internal garbage collector
            # and accept the warnings.
            #$thread->detach();
        }
    }

    # Disconnect from the VMware Server / GSX host.
    _disconnect();
}

1;

#######################################################################
# Additional Module Documentation                                     #
#######################################################################

__END__

=head1 FAULT REPORTING & IMPLEMENTATION DETAILS

For any filesystem intensive operation, the daemon spawns a
child thread to perform the actual I/O operations, allowing the
web service call to finish before any timeouts occur.

As a result, if any errors occur within the child threads, the
corresponding C<SOAP::Fault> object(s) created will be queued 
and transmitted back to the next client who makes the next
SOAP request -- one fault dequeued and transmitted back
per subsequent SOAP request.

The following functions spawn asynchronous child threads:

=over 4

=item *

quickCloneVM()

=item *

fullCloneVM()

=item *

snapshotVM()

=item *

revertVM()

=back

=head1 BUGS & ASSUMPTIONS

This daemon assumes the VMware Server / GSX server to control is running
locally. Furthermore, do NOT run this daemon as root.  The daemon
will use whatever user/group permissions it was run under, in order
to automatically authenticate with the VMware Server / GSX server.

If this daemon is executed on a system to control a VMware Server / GSX server 
remotely, then any filesystem-specific operations (i.e., cloning)
will fail, as those operations cannot be performed on remote
VMware Server / GSX servers without direct access to the server's filesystem.

This code relies heavily upon the B<VMware::VmPerl> APIs.  The VmPerl
APIs are not I<thread-safe>.  As such, all VmPerl operations are
centralized in the master thread.  If a child thread ever needs
to perform VmPerl-specific functions, then the child I<must> perform
a local callback to the SOAP server, instead of calling VmPerl
directly.

=head1 SEE ALSO

L<http://www.honeyclient.org/trac>

SOAP::Lite

L<http://www.soaplite.com>

VMware::VmPerl, VMware::VmPerl::Server, VMware::VmPerl::ConnectParams,
VMware::VmPerl::VM, VMware::VmPerl::Question

L<http://www.vmware.com/support/developer/>

threads, threads::shared, Thread::Queue, Thread::Semaphore, perlthrtut

POSIX, File::Copy, File::Copy::Recursive, File::Basename, Tie::File

Apache::SessionX::General::MD5

=head1 REPORTING BUGS

L<http://www.honeyclient.org/trac/newticket>

=head1 ACKNOWLEDGEMENTS

VMware, for providing their VMware::VmPerl API code and offering their
VMware Server product as freeware.

Jeffrey William Baker E<lt>jwbaker@acm.orgE<gt> and Gerald Richter
E<lt>richter@dev.ecos.deE<gt>, for using core code from their
Apache::Session::Generate::MD5 package to create unique VMIDs.

=head1 AUTHORS

Darien Kindlund, E<lt>kindlund@mitre.orgE<gt>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2007 The MITRE Corporation.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation, using version 2
of the License.
 
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
 
You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
02110-1301, USA.


=cut
