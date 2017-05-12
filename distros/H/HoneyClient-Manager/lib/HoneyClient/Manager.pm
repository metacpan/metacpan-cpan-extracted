#######################################################################
# Created on:  May 11, 2006
# Package:     HoneyClient::Manager
# File:        Manager.pm
# Description: Central library used for manager-based operations.
#
# CVS: $Id: Manager.pm 796 2007-08-07 16:36:16Z kindlund $
#
# @author knwang, ttruong, jdurick, kindlund
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

# XXX: Fill this in.

=head1 VERSION

This documentation refers to HoneyClient::Manager version 0.99.

=head1 SYNOPSIS

=head2 CREATING THE SOAP SERVER

# XXX: Fill this in.

=head2 INTERACTING WITH THE SOAP SERVER

# XXX: Fill this in.

=head1 DESCRIPTION

# XXX: Fill this in.

=cut

package HoneyClient::Manager;

# XXX: Disabled version check, Honeywall does not have Perl v5.8 installed.
#use 5.008006;
use strict;
use warnings FATAL => 'all';
use Config;
use Carp ();

#######################################################################
# Module Initialization                                               #
#######################################################################

BEGIN {
    # Defines which functions can be called externally.
    require Exporter;
    our (@ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS, $VERSION, @DRIVERS);

    # Set our package version.
    $VERSION = 0.99;

    @ISA = qw(Exporter);

    # Symbols to export automatically
    @EXPORT = qw(init destroy);

    # Items to export into callers namespace by default. Note: do not export
    # names by default without a very good reason. Use EXPORT_OK instead.
    # Do not simply export all your public functions/methods/constants.

    # This allows declaration use HoneyClient::Manager ':all';
    # If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
    # will save memory.

    %EXPORT_TAGS = (
        'all' => [ qw(init destroy) ],
    );

    # Symbols to autoexport (when qw(:all) tag is used)
    @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

    # Check to see if ithreads are compiled into this version of Perl.
    $Config{useithreads} or Carp::croak "Error: Recompile Perl with ithread support, in order to use this module.\n";

    $SIG{PIPE} = 'IGNORE'; # Do not exit on broken pipes.
}
our (@EXPORT_OK, $VERSION);

=pod

=begin testing

# Make sure the module loads properly, with the exportable
# functions shared.
BEGIN { use_ok('HoneyClient::Manager', qw(init destroy)) or diag("Can't load HoneyClient::Manager package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('HoneyClient::Manager');
can_ok('HoneyClient::Manager', 'init');
can_ok('HoneyClient::Manager', 'destroy');
use HoneyClient::Manager qw(init destroy);

# Make sure HoneyClient::Util::SOAP loads.
BEGIN { use_ok('HoneyClient::Util::SOAP', qw(getServerHandle getClientHandle)) or diag("Can't load HoneyClient::Util::SOAP package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('HoneyClient::Util::SOAP');
can_ok('HoneyClient::Util::SOAP', 'getServerHandle');
can_ok('HoneyClient::Util::SOAP', 'getClientHandle');
use HoneyClient::Util::SOAP qw(getServerHandle getClientHandle);

# Make sure HoneyClient::Util::Config loads.
BEGIN { use_ok('HoneyClient::Util::Config', qw(getVar)) or diag("Can't load HoneyClient::Util::Config package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('HoneyClient::Util::Config');
can_ok('HoneyClient::Util::Config', 'getVar');
use HoneyClient::Util::Config qw(getVar);

# Make sure Storable loads.
BEGIN { use_ok('Storable', qw(nfreeze thaw)) or diag("Can't load Storable package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('Storable');
can_ok('Storable', 'nfreeze');
can_ok('Storable', 'thaw');
use Storable qw(nfreeze thaw);

# Make sure MIME::Base64 loads.
BEGIN { use_ok('MIME::Base64', qw(encode_base64 decode_base64)) or diag("Can't load MIME::Base64 package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('MIME::Base64');
can_ok('MIME::Base64', 'encode_base64');
can_ok('MIME::Base64', 'decode_base64');
use MIME::Base64 qw(encode_base64 decode_base64);

=end testing

=cut

#######################################################################

# Include the SOAP Utility Library
use HoneyClient::Util::SOAP qw(getClientHandle getServerHandle);

# Include Thread Libraries
use threads;
use threads::shared;
use Thread::Semaphore;
use Thread::Queue;

# Include utility access to global configuration.
use HoneyClient::Util::Config qw(getVar);

# Include the VM Utility Library
# TODO: Include unit tests.
use HoneyClient::Manager::VM qw();

# Check if DB support is enabled. 
our $DB_ENABLE = getVar(name      => "enable",
                        namespace => "HoneyClient::DB");

if ($DB_ENABLE) {
    # Include DB Utility Library
    # TODO: Include unit tests.
    require HoneyClient::DB::Fingerprint;
}

# XXX: Remove this, eventually.
use Data::Dumper;

# Make Dumper format more verbose.
$Data::Dumper::Terse = 0;
$Data::Dumper::Indent = 2;

# Include Hash Serialization Utility Libraries
use Storable qw(nfreeze thaw);

# Include Base64 Libraries
use MIME::Base64 qw(encode_base64 decode_base64);

# Include FW Utility Library
# TODO: Include unit tests.
#use HoneyClient::Manager::FW;

# Include Hash Serialization Utility Libraries
# TODO: Include unit tests.
use Storable qw(nfreeze thaw);

# Include VmPerl Constants.
# TODO: Include unit tests.
use VMware::VmPerl qw(VM_EXECUTION_STATE_ON
                      VM_EXECUTION_STATE_OFF
                      VM_EXECUTION_STATE_STUCK
                      VM_EXECUTION_STATE_SUSPENDED);

# TODO: Include unit tests.
use IO::File;

# TODO: Include unit tests.
# Include Logging Library
use Log::Log4perl qw(:easy);

# The global logging object.
our $LOG = get_logger();

# Complete URL of SOAP server, when initialized.
our $URL_BASE       : shared = undef;
our $URL            : shared = undef;

# The process ID of the SOAP server daemon, once created.
our $DAEMON_PID     : shared = undef;

# XXX: These will be migrated somewhere else, eventually.
our $vmStateTable = { };
our $vmCloneConfig      = undef;
our $stubVM             = undef;
our $stubAgent          = undef;
our $stubFW             = undef;

# This is a temporary, shared variable, used to print out the
# state of the agent, when _cleanup() occurs.
# XXX: This variable and all reference to it will be deleted,
# eventually.
our $globalAgentState   = undef;

# This static variable may contain a filename that the Manager
# would use to dump its entire state information, upon termination.
# XXX: May want to change this format/usage, eventually.
our $STATE_FILE = getVar(name => "manager_state");

# Temporary variable, used to indicate to the fault handler whether
# or not errors/warnings should be suppressed.
our $SUPPRESS_ERRORS = 0;

#######################################################################
# Daemon Initialization / Destruction                                 #
#######################################################################

=pod

=head1 EXPORTED FUNCTIONS

The following init() and destroy() functions are the only direct
calls required to startup and shutdown the SOAP server.

All other interactions with this daemon should be performed as
C<SOAP::Lite> function calls, in order to ensure consistency across
client sessions.  See the L<"EXTERNAL SOAP FUNCTIONS"> section, for
more details.

=head2 HoneyClient::Manager->init()

=over 4

Starts a new SOAP server, within a child process.

I<Inputs>:

# XXX: Finish this.

I<Output>: 

# XXX: Finish this.

=back

=begin testing

# XXX: Test init() method.

=end testing

=cut

sub init {
    # Extract arguments.
    # Hash-based arguments are used, since HoneyClient::Util::SOAP is unable to handle
    # hash references directly.  Thus, flat hashtables are used throughout the code
    # for consistency.
    my ($class, %args) = @_;
    
    # XXX: Finish this.
}

=pod

=head2 HoneyClient::Manager->destroy()

=over 4

Terminates the SOAP server within the child process.

I<Output>: True if successful, false otherwise.

=back

=begin testing

# XXX: Test destroy() method.

# TODO: delete this.
#exit;

=end testing

=cut

sub destroy {
    my $ret = undef;
   
    # XXX: Finish this.
    
    return $ret;
}

#######################################################################
# Private Methods Implemented                                         #
#######################################################################

sub _handleFault {

    # Extract arguments.
    my ($class, $res) = @_;

    # Construct error message.
    # Figure out if the error occurred in transport or over
    # on the other side.
    my $errMsg = $class->transport->status; # Assume transport error.

    if (ref $res) {
        $errMsg = $res->faultcode . ": ".  $res->faultstring . "\n";
    }

    if (!$SUPPRESS_ERRORS) {
        $LOG->warn("Error occurred during processing. " . $errMsg);
        Carp::carp __PACKAGE__ . "->_handleFault(): Error occurred during processing.\n" . $errMsg;
    }
}

sub _handleFaultAndCleanup {

    # Extract arguments.
    my ($class, $res) = @_;

    # Print fault.
    _handleFault($class, $res);
    
    # Cleanup before dying.
    _cleanup();
}

sub _cleanup {

    $LOG->info("Cleaning up.");

    # Mask all possible signals, so that we don't call this function multiple times.
    $SIG{HUP}     = sub { };
    $SIG{INT}     = sub { };
    $SIG{QUIT}    = sub { };
    $SIG{ABRT}    = sub { };
    $SIG{PIPE}    = sub { };
    $SIG{TERM}    = sub { };

    HoneyClient::Manager::VM->destroy();

    # XXX: Need to clean this up.
    my $stubFW = getClientHandle(namespace     => "HoneyClient::Manager::FW");

    # XXX: Change this to fwInit(), eventually.
    # Reset the firewall, to allow everything open.
    $stubFW->testConnect();

    # Check to see if a clone was created...
    if (defined($vmCloneConfig)) {
        # We sleep for a bit, to make sure that the previous VM daemon was
        # properly destroyed and released the previous port that was in use.
        sleep (10);

        # We reinstantiate a new VM daemon, because if the user had hit CTRL-C
        # or called any other signal, then that signal would propagate to all
        # processes, causing the VM daemon's signal handler to self terminate.
        #
        # Hence, rather than fight the VM daemon's natural self termination,
        # we let the daemon die, but the create a new one, for the sole purpose
        # of cleanup up the clones.
        HoneyClient::Manager::VM->init();
        $LOG->info("Calling suspendVM(config => " . $vmCloneConfig . ").");
        my $stubVM = getClientHandle(namespace => "HoneyClient::Manager::VM");
        $stubVM->suspendVM(config => $vmCloneConfig);
        print "Done!\n";
        HoneyClient::Manager::VM->destroy();
    }

    # XXX: May want to change this format/usage, eventually.
    if (length($STATE_FILE) > 0 &&
        defined($globalAgentState)) {
        $LOG->info("Saving state to '" . $STATE_FILE . "'.");
        my $dump_file = new IO::File($STATE_FILE, "a");

        # XXX: Delete this block, eventually.
        $Data::Dumper::Terse = 0;
        $Data::Dumper::Indent = 2;
        print $dump_file Dumper(thaw(decode_base64($globalAgentState)));
    }

    exit;
}

# XXX: Install the cleanup handler, in case the parent process dies
# unexpectedly.
$SIG{HUP}  = sub { _cleanup(); };
$SIG{INT}  = sub { _cleanup(); };
$SIG{QUIT} = sub { _cleanup(); };
$SIG{ABRT} = sub { _cleanup(); };
$SIG{PIPE} = sub { _cleanup(); };
$SIG{TERM} = sub { _cleanup(); };

#######################################################################
# Public Methods Implemented                                          #
#######################################################################

=pod

=head1 EXPORTS

=head2 run()

=over 4

# XXX: Fill this in.

I<Inputs>: 
 B<$arg> is an optional argument.

driver
master_vm_config
start_state
 
I<Output>: XXX: Fill this in.

=back

=begin testing

# XXX: Fill this in.

=end testing

=cut

sub run {
    # Extract arguments.
    # Hash-based arguments are used, since HoneyClient::Util::SOAP is unable to handle
    # hash references directly.  Thus, flat hashtables are used throughout the code
    # for consistency.
    my ($class, %args) = @_;
    my $agentState = undef;

    # Sanity check, make sure the master_vm_config has
    # been specified.
    my $argsExist = scalar(%args);
    if (!$argsExist ||
        !exists($args{'master_vm_config'}) ||
        !defined($args{'master_vm_config'})) {
        # Get the master_vm_config from the configuration file.
        $args{'master_vm_config'} = getVar(name      => "master_vm_config",
                                           namespace => "HoneyClient::Manager::VM");
    }

    for (;;) {
        print "Starting new session...\n";
        $agentState = $class->runSession(%args);
        $args{'agent_state'} = $agentState;

        # XXX: Delete this, eventually.
        $globalAgentState = $agentState;

        #$Data::Dumper::Terse = 0;
        #$Data::Dumper::Indent = 2;
        #print Dumper(thaw(decode_base64($agentState)));
    }
}

sub runSession {

    # Extract arguments.
    # Hash-based arguments are used, since HoneyClient::Util::SOAP is unable to handle
    # hash references directly.  Thus, flat hashtables are used throughout the code
    # for consistency.
    my ($class, %args) = @_;

    my $som       = undef;
    my $ret       = undef;
    my $vmIP      = undef;
    my $vmMAC     = undef;
    my $vmName    = undef;
    my $URL       = undef;
    my $vmState   = undef;
    my $vmCompromised = 0;

    # Get a stub connection to the firewall.
    $stubFW = getClientHandle(namespace     => "HoneyClient::Manager::FW",
                              fault_handler => \&_handleFaultAndCleanup);

    # Open up the firewall initially, to allow the Agent to do an SVN update.
    $stubFW->testConnect();

    $URL = HoneyClient::Manager::VM->init();
    print "VM Daemon Listening On: " . $URL . "\n";
   
    $stubVM = getClientHandle(namespace     => "HoneyClient::Manager::VM",
                              fault_handler => \&_handleFaultAndCleanup);
    
    print "Calling setMasterVM()...\n";
    $som = $stubVM->setMasterVM(config => $args{'master_vm_config'});
    print "Result: " . $som->result() . "\n";

    print "Calling quickCloneVM()...\n";
    $som = $stubVM->quickCloneVM();
    print "Result: " . $som->result() . "\n";
    $vmCloneConfig = $som->result();

    # Make sure the VM is fully cloned, before trying to make any subsequent calls.
    print "Calling isRegisteredVM()...\n";
    $som = $stubVM->isRegisteredVM(config => $vmCloneConfig);
    $ret = $som->result();

    if (defined($ret)) {
        print "Result: " . $ret . "\n";
    }

    while (!defined($ret)) {
        sleep (3);
        print "Calling isRegisteredVM()...\n";
        $som = $stubVM->isRegisteredVM(config => $vmCloneConfig);
        $ret = $som->result();
        if (defined($ret)) {
            print "Result: " . $ret . "\n";
        }
    }

    print "Calling getStateVM()...\n";
    $som = $stubVM->getStateVM(config => $vmCloneConfig);
    $vmState = $som->result();

    if ($vmState == VM_EXECUTION_STATE_ON) {
        print "ON\n";
    } elsif ($vmState == VM_EXECUTION_STATE_OFF) {
        print "OFF\n";
    } elsif ($vmState == VM_EXECUTION_STATE_SUSPENDED) {
        print "SUSPENDED\n";
    } elsif ($vmState == VM_EXECUTION_STATE_STUCK) {
        print "STUCK\n";
    } else {
        print "UNKNOWN\n";
    }

    while ($vmState != VM_EXECUTION_STATE_ON) {
        sleep (3);

        print "Calling getStateVM()...\n";
        $som = $stubVM->getStateVM(config => $vmCloneConfig);
        $vmState = $som->result();

        if ($vmState == VM_EXECUTION_STATE_ON) {
            print "ON\n";
        } elsif ($vmState == VM_EXECUTION_STATE_OFF) {
            print "OFF\n";
        } elsif ($vmState == VM_EXECUTION_STATE_SUSPENDED) {
            print "SUSPENDED\n";
        } elsif ($vmState == VM_EXECUTION_STATE_STUCK) {
            print "STUCK\n";
        } else {
            print "UNKNOWN\n";
        }
    }

    print "Calling getMACaddrVM()...\n";
    $som = $stubVM->getMACaddrVM(config => $vmCloneConfig);
    print "Result: " . $som->result() . "\n";
    $vmMAC = $som->result();

    # Figure out when the Agent on the VM is alive and well.
    $ret = undef;
    my $logMsgPrinted = 0;
    while (!$ret) {
        sleep (3);
        print "Calling getIPaddrVM()...\n";
        $som = $stubVM->getIPaddrVM(config => $vmCloneConfig);
        if (defined($som->result())) {
            print "Result: " . $som->result() . "\n";
        }
        $vmIP = $som->result();

        print "Calling getNameVM()...\n";
        $som = $stubVM->getNameVM(config => $vmCloneConfig);
        print "Result: " . $som->result() . "\n";
        $vmName = $som->result();

        if (defined($vmIP) && defined($vmName)) {
            if (!$logMsgPrinted) {
                $LOG->info("Created clone VM (" . $vmName . ") using IP (" . $vmIP . ") and MAC (" . $vmMAC . ").");
                $logMsgPrinted = 1;
            }

            # Try contacting the Agent; ignore any faults.
            $SUPPRESS_ERRORS = 1;
            $stubAgent = getClientHandle(namespace     => "HoneyClient::Agent",
                                         address       => $vmIP,
                                         fault_handler => \&_handleFault);

            eval {
                print "Calling getStatus()...\n";
                $som = $stubAgent->getStatus();
                $ret = thaw(decode_base64($som->result()));
                print "Result:\n";
                # Make Dumper format more verbose.
                $Data::Dumper::Terse = 0;
                $Data::Dumper::Indent = 2;
                print Dumper($ret);

            };
            # Clear returned state, if any fault occurs.
            if ($@) {
                $ret = undef;
            }
            $SUPPRESS_ERRORS = 0;
        }
    }

    # Build our VM's connection table.
    # Note: We assume our VM has a single MAC address
    # and a single IP address.
    $vmStateTable->{$vmName}->{sources}->{$vmMAC}->{$vmIP} = {
        # XXX: We assume we can't pinpoint what source TCP ports the
        # corresponding driver will need.  (We may want to get this
        # information eventually from the Agent, as part of Driver::next().)
        'tcp' => undef,
    };

    print "VM State Table:\n";
    # Make Dumper format more verbose.
    $Data::Dumper::Terse = 0;
    $Data::Dumper::Indent = 2;
    print Dumper($vmStateTable) . "\n";
  
    # Initialize the firewall.
    $stubFW->fwInit();

    # Add new chain, per cloned VM.
    $stubFW->addChain($vmStateTable);
   
    sleep (2);

    # Recreate the client stub; handle faults.
    $stubAgent = getClientHandle(namespace     => "HoneyClient::Agent",
                                 address       => $vmIP,
                                 fault_handler => \&_handleFaultAndCleanup);

    # Call updateState() first, to seed initial data.
    # TODO: Need to support asynchronous updates (url adding)
    # from user input.
    print "Calling updateState()...\n";
    $som = $stubAgent->updateState($args{'agent_state'});

    # Recreate the client stub; ignore faults.
    $stubAgent = getClientHandle(namespace     => "HoneyClient::Agent",
                                 address       => $vmIP,
                                 fault_handler => \&_handleFault);

    # Recreate the firewall stub; ignore faults.
    $stubFW = getClientHandle(namespace     => "HoneyClient::Manager::FW",
                              fault_handler => \&_handleFault);

    for (my $counter = 1;; $counter++) {

        # From this point on, catch all errors generated and
        # assume that the Agent's watchdog process will recover.
        eval {
            print "Calling getState()...\n";
            $som = $stubAgent->getState();
            $args{'agent_state'} = $som->result();

            # XXX: Delete this, eventually.
            $globalAgentState = $args{'agent_state'};

            print "Calling getStatus()...\n";
            $som = $stubAgent->getStatus();
            print "Result:\n";
            $ret = thaw(decode_base64($som->result()));
            # Make Dumper format more verbose.
            $Data::Dumper::Terse = 0;
            $Data::Dumper::Indent = 2;
            print Dumper($ret->{$args{'driver'}}->{status});
            #print Dumper($ret);

            # Check to see if Agent::run() thread has stopped
            # and that a compromise was detected.
            if (!$ret->{$args{'driver'}}->{status}->{is_running}) {
                if ($ret->{$args{'driver'}}->{status}->{is_compromised}) {
                    # Check to see if the VM has been compromised.
                    print "WARNING: VM HAS BEEN COMPROMISED!\n";
                    $LOG->info("Calling suspendVM(config => " . $vmCloneConfig . ").");
                    $som = $stubVM->suspendVM(config => $vmCloneConfig);
                    HoneyClient::Manager::VM->destroy();
                    $vmCompromised = 1;

                    # Insert Compromised Fingerprint into DB.
                    my $fingerprint = $ret->{$args{'driver'}}->{status}->{fingerprint};
                    $LOG->warn("VM Compromised.  Last Resource (" . $fingerprint->{'last_resource'} . ")");
                    $fingerprint->{'lasturl'} = delete($fingerprint->{'last_resource'});
                    $fingerprint->{vmid} = $vmName;
                    print "Fingerprint:\n";
                    print Dumper($fingerprint) . "\n";
                    if ($DB_ENABLE) {
                        $LOG->info("Inserting Fingerprint Into Database.");
                        my $fp = HoneyClient::DB::Fingerprint->new($fingerprint);
                        $fp->insert(); 
                        $LOG->info("Database Insert Successful.");
                    }
                    return; # Return out of eval block.
                } else {
                    print "VM Integrity Check: OK!\n";

                    # Check to see if any links remain to be processed by the
                    # Agent.
                    if (!$ret->{$args{'driver'}}->{status}->{links_remaining}) {

                        $LOG->info("All URLs exhausted.  Shutting down Manager.");
                        # Get a local copy of the configuration and kill the global copy.
                        my $vmCfg = $vmCloneConfig;
                        $vmCloneConfig = undef;
                        $LOG->info("Calling suspendVM(config => " . $vmCfg . ").");
                        $stubVM->suspendVM(config => $vmCfg);
                        print "Done!\n";
                        _cleanup();

                    } else {
                        # The Agent::run() thread has stopped; we assume
                        # it's because the Agent is waiting for the firewall
                        # to allow access to the new targets.
                
                        # Delete the old firewall rules, based upon existing
                        # targets.
                        $stubFW->deleteRules($vmStateTable);

                        # Get the new targets from the Agent.
                        $vmStateTable->{$vmName}->{targets} = $ret->{$args{'driver'}}->{next}->{targets};

                        print "VM State Table:\n";
                        # Make Dumper format more verbose.
                        $Data::Dumper::Terse = 0;
                        $Data::Dumper::Indent = 2;
                        print Dumper($vmStateTable) . "\n";

                        # Add the new targets from the Agent.
                        $stubFW->addRules($vmStateTable);

                        print "Calling run()...\n";
                        $som = $stubAgent->run(driver_name => $args{'driver'});
                    }
                }
            }
        };
        if ($@) {
            print "Error: $@\n";
            my $resetSuccessful = 0;
            while (!$resetSuccessful) {
                print "Resetting firewall...\n";
                eval {
                    # We assume the error was caused by some sort of communications
                    # problem with the Agent.  Assume the Agent's watchdog will restart
                    # the daemon, in which case, we indefinately try to reset the
                    # firewall accordingly.
                    $stubFW->fwInit();
                    $stubFW->addChain($vmStateTable);
                    $stubFW->addRules($vmStateTable);
                };
                if (!$@) {
                    $resetSuccessful = 1;
                } else {
                    sleep (3);
                }
            }   
        }
        if ($vmCompromised) {
            # Reset the FW state table. 
            $vmStateTable = { };
            return $args{'agent_state'};
        }
        print "Sleeping for 10s...\n";
        sleep (10);
    }
}

#######################################################################

1;

#######################################################################
# Additional Module Documentation                                     #
#######################################################################

__END__

=head1 BUGS & ASSUMPTIONS

# XXX: Fill this in.

=head1 SEE ALSO

L<http://www.honeyclient.org/trac>

=head1 REPORTING BUGS

L<http://www.honeyclient.org/trac/newticket>

=head1 ACKNOWLEDGEMENTS

Paul Kulchenko for developing the SOAP::Lite module.

=head1 AUTHORS

Kathy Wang, E<lt>knwang@mitre.orgE<gt>

Thanh Truong, E<lt>ttruong@mitre.orgE<gt>

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
