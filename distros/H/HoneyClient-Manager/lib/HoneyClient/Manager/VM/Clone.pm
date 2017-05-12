#######################################################################
# Created on:  June 15, 2007
# Package:     HoneyClient::Manager::VM::Clone
# File:        Clone.pm
# Description: Generic object model for handling a single HoneyClient
#              cloned VM on the host system.
#
# CVS: $Id: Clone.pm 796 2007-08-07 16:36:16Z kindlund $
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

HoneyClient::Manager::VM::Clone - Perl extension to provide a generic object
model for handling a single HoneyClient cloned VM on the host system.

=head1 VERSION

This documentation refers to HoneyClient::Manager::VM::Clone version 0.99.

=head1 SYNOPSIS

# XXX: FIX THIS

  # NOTE: This package is an INTERFACE specification only!  It is
  # NOT intended to be used directly.  Rather, it is expected that
  # other Driver specific sub-packages will INHERIT and IMPLEMENT
  # these methods.

  # Eventually, change each reference of 'HoneyClient::Agent::Driver'
  # to an implementation-specific 'HoneyClient::Agent::Driver::*' 
  # package name.
  use HoneyClient::Agent::Driver;

  # Library used exclusively for debugging complex objects.
  use Data::Dumper;

  # Eventually, call the new() function on an implementation-specific
  # Driver package name.
  my $driver = HoneyClient::Agent::Driver->new();

  # If you want to see what type of "state information" is physically
  # inside $driver, try this command at any time.
  print Dumper($driver);

  # Continue to "drive" the driver, until it is finished.
  while (!$driver->isFinished()) {

      # Before we drive the application to a new set of resources,
      # find out where we will be going within the application, first.
      print "About to contact the following resources:\n";
      print Dumper($driver->next());

      # Now, drive the application.
      $driver->drive();

      # Get status of current iteration of work.
      print "Status:\n";
      print Dumper($driver->status());
      
  }

=head1 DESCRIPTION

# XXX: FIX THIS

This library allows the Agent module to access any drivers running on the
HoneyClient VM in a consistent fashion.  This module is object-oriented in
design, allowing specific types of drivers to inherit these abstractly
defined interface methods.

Fundamentally, a "Driver" is a programmatic construct, designed to
automate a back-end application that is intended to be exploited by
different types of malware.  As such, the "Agent" interacts with each
B<application-specific> Driver running inside the HoneyClient VM, in
order to programmatically automate the corresponding applications.

When a "Driver" is "driven", this implies that the back-end application
is accessing a B<new> Internet resource, in order to intentionally be exposed
to new malware and thus become exploited.

Example implementation Drivers involve automating certain types and
B<versions> of web browsers (e.g., Microsoft Internet Explorer, Mozilla 
Firefox) or even email applications (e.g., Microsoft Outlook, Mozilla
Thunderbird).

=cut

package HoneyClient::Manager::VM::Clone;

use strict;
use warnings;
use Config;
use Carp ();

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
    # Note: Since this module is object-oriented, we do *NOT* export
    # any functions other than "new" to call statically.  Each function
    # for this module *must* be called as a method from a unique
    # object instance.
    @EXPORT = qw();

    # Items to export into callers namespace by default. Note: do not export
    # names by default without a very good reason. Use EXPORT_OK instead.
    # Do not simply export all your public functions/methods/constants.

    # This allows declaration use HoneyClient::Manager::VM::Clone ':all';
    # If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
    # will save memory.

    # Note: Since this module is object-oriented, we do *NOT* export
    # any functions other than "new" to call statically.  Each function
    # for this module *must* be called as a method from a unique
    # object instance.
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

# Make sure HoneyClient::Util::SOAP loads.
BEGIN { use_ok('HoneyClient::Util::SOAP', qw(getClientHandle)) or diag("Can't load HoneyClient::Util::SOAP package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('HoneyClient::Util::SOAP');
can_ok('HoneyClient::Util::SOAP', 'getClientHandle');
use HoneyClient::Util::SOAP qw(getClientHandle);

# Make sure HoneyClient::Manager::VM loads.
BEGIN { use_ok('HoneyClient::Manager::VM') or diag("Can't load HoneyClient::Manager:VM package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('HoneyClient::Manager::VM');
use HoneyClient::Manager::VM;

# Make sure VMware::VmPerl loads.
BEGIN { use_ok('VMware::VmPerl', qw(VM_EXECUTION_STATE_ON VM_EXECUTION_STATE_OFF VM_EXECUTION_STATE_STUCK VM_EXECUTION_STATE_SUSPENDED)) or diag("Can't load VMware::VmPerl package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('VMware::VmPerl');
use VMware::VmPerl qw(VM_EXECUTION_STATE_ON VM_EXECUTION_STATE_OFF VM_EXECUTION_STATE_STUCK VM_EXECUTION_STATE_SUSPENDED);

# Make sure the module loads properly, with the exportable
# functions shared.
BEGIN { use_ok('HoneyClient::Manager::VM::Clone') or diag("Can't load HoneyClient::Manager::VM::Clone package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('HoneyClient::Manager::VM::Clone');
use HoneyClient::Manager::VM::Clone;

# Suppress all logging messages, since we need clean output for unit testing.
Log::Log4perl->init({
    "log4perl.rootLogger"                               => "DEBUG, Buffer",
    "log4perl.appender.Buffer"                          => "Log::Log4perl::Appender::TestBuffer",
    "log4perl.appender.Buffer.min_level"                => "fatal",
    "log4perl.appender.Buffer.layout"                   => "Log::Log4perl::Layout::PatternLayout",
    "log4perl.appender.Buffer.layout.ConversionPattern" => "%d{yyyy-MM-dd HH:mm:ss} %5p [%M] (%F:%L) - %m%n",
});

# Make sure Storable loads.
BEGIN { use_ok('Storable', qw(dclone)) or diag("Can't load Storable package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('Storable');
can_ok('Storable', 'dclone');
use Storable qw(dclone);

# Make sure threads loads.
BEGIN { use_ok('threads') or diag("Can't load threads package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('threads');
use threads;

# Make sure threads::shared loads.
BEGIN { use_ok('threads::shared') or diag("Can't load threads::shared package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('threads::shared');
use threads::shared;

# Make sure File::Basename loads.
BEGIN { use_ok('File::Basename', qw(dirname basename)) or diag("Can't load File::Basename package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('File::Basename');
can_ok('File::Basename', 'dirname');
can_ok('File::Basename', 'basename');
use File::Basename qw(dirname basename);

=end testing

=cut

#######################################################################

# Include Threading Library
use threads;
use threads::shared;

# Include Global Configuration Processing Library
use HoneyClient::Util::Config qw(getVar);

# Include SOAP Library
use HoneyClient::Util::SOAP qw(getClientHandle);

# Include VM Libraries
use VMware::VmPerl qw(VM_EXECUTION_STATE_ON
                      VM_EXECUTION_STATE_OFF
                      VM_EXECUTION_STATE_STUCK
                      VM_EXECUTION_STATE_SUSPENDED);
use HoneyClient::Manager::VM;

# Use Storable Library
use Storable qw(dclone);

# Package Global Variable
our $AUTOLOAD;

# Include Logging Library
use Log::Log4perl qw(:easy);

# The global logging object.
our $LOG = get_logger();

# The global variable, used to count the number of
# Clone objects that have been created.
our $OBJECT_COUNT : shared = 0;

=pod

=head1 DEFAULT PARAMETER LIST

When a Clone B<$object> is instantiated using the B<new()> function,
the following parameters are supplied default values.  Each value
can be overridden by specifying the new (key => value) pair into the
B<new()> function, as arguments.

Furthermore, as each parameter is initialized, each can be individually 
retrieved and set at any time, using the following syntax:

  my $value = $object->{key}; # Gets key's value.
  $object->{key} = $value;    # Sets key's value.

=head2 master_vm_config

=over 4

The full absolute path to the master VM's configuration file, whose
contents will be the basis for each subsequently cloned VM.

=back

=cut

my %PARAMS = (
    # The full absolute path to the master VM's configuration file, whose
    # contents will be the basis for each subsequently cloned VM.
    master_vm_config => getVar(name => "master_vm_config"),

    # A SOAP handle to the VM manager daemon.  (This internal variable
    # should never be modified externally.)
    _vm_handle => undef,

    # A variable containing the absolute path to the cloned VM.  (This
    # internal variable should never be modified externally.)
    _clone_vm_config => undef,

    # A variable containing the MAC address of the cloned VM's primary
    # interface.  (This internal variable should never be modified
    # externally.)
    _clone_vm_mac => undef,
    
    # A variable containing the IP address of the cloned VM's primary
    # interface.  (This internal variable should never be modified
    # externally.)
    _clone_vm_ip => undef,
    
    # A variable containing the name the cloned VM.
    # (This internal variable should never be modified
    # externally.)
    _clone_vm_name => undef,

    # A variable indicated how long the object should wait for
    # between subsequent retries to the HoneyClient::Manager::VM
    # daemon (in seconds).  (This internal variable should never
    # be modified externally.)
    _retry_period => 2,
);

#######################################################################
# Private Methods Implemented                                         #
#######################################################################

# Helper function designed to programmatically get or set parameters
# within this object, through indirect use of the AUTOLOAD function.
#
# It's best to explain by example:
# Assume we have defined a driver object, like the following.
#
# use HoneyClient::Manager::VM::Clone;
# my $clone = HoneyClient::Manager::VM::Clone->new(someVar => 'someValue');
#
# What this function allows us to do, is programmatically, get or set
# the 'someVar' parameter, like:
#
# my $value = $clone->someVar();    # Gets the value of 'someVar'.
# my $value = $clone->someVar('2'); # Sets the value of 'someVar' to '2'
#                                   # and returns '2'.
#
# Rather than creating getter/setter functions for every possible parameter,
# the AUTOLOAD function allows us to create these operations in a generic,
# reusable fashion.
#
# See "Autoloaded Data Methods" in perltoot for more details.
# 
# Inputs: set a new value (optional)
# Outputs: the currently set value
sub AUTOLOAD {
    # Get the object.
    my $self = shift;

    # Sanity check: Make sure the supplied value is an object.
    my $type = ref($self) or Carp::croak "Error: $self is not an object!\n";

    # Now, get the name of the function.
    my $name = $AUTOLOAD;

    # Strip the fully-qualified portion of the function name.
    $name =~ s/.*://;

    # Make sure the parameter exists in the object, before we try
    # to get or set it.
    unless (exists $self->{$name}) {
        $LOG->error("Can't access '$name' parameter in class $type!");
        Carp::croak "Error: Can't access '$name' parameter in class $type!\n";
    }

    if (@_) {
        # If we were given an argument, then set the parameter's value.
        return $self->{$name} = shift;
    } else {
        # Else, just return the existing value.
        return $self->{$name};
    }
}

# Base destructor function.
# Since none of our state data ever contains circular references,
# we can simply leave the garbage collection up to Perl's internal
# mechanism.
sub DESTROY {
    # Get the object.
    my $self = shift;

    if (defined($self->{'_clone_vm_config'})) {
        my $som = $self->{'_vm_handle'}->getMACaddrVM(config => $self->{'_clone_vm_config'});
        if (!$som->result()) {
            $LOG->error("Unable to suspend VM (" . $self->{'_clone_vm_config'} . ").");
        }
    }

    # Decrement our global object count.
    $OBJECT_COUNT--;

    # Upon last use, destroy the global instance of the VM manager.
    if ($OBJECT_COUNT <= 0) {
        HoneyClient::Manager::VM->destroy();
    }
}

#######################################################################
# Public Methods Implemented                                          #
#######################################################################

=pod

=head1 METHODS IMPLEMENTED 

The following functions have been implemented by any Clone object.

=head2 HoneyClient::Manager::VM::Clone->new($param => $value, ...)

=over 4

Creates a new Clone object, which contains a hashtable
containing any of the supplied "param => value" arguments.

I<Inputs>:
 B<$param> is an optional parameter variable.
 B<$value> is $param's corresponding value.
 
Note: If any $param(s) are supplied, then an equal number of
corresponding $value(s) B<must> also be specified.

I<Output>: The instantiated Clone B<$object>, fully initialized.

=back

=begin testing

# Shared test variables.
my ($stub, $som, $URL);
my $testVM = $ENV{PWD} . "/" . getVar(name      => "test_vm_config",
                                      namespace => "HoneyClient::Manager::VM::Test");

# Catch all errors, in order to make sure child processes are
# properly killed.
eval {

    $URL = HoneyClient::Manager::VM->init();

    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");

    # In order to test setMasterVM(), we're going to fully clone
    # the testVM, then set the newly created clone as a master VM.

    # Get the test VM's parent directory,
    # in order to create a temporary master VM.
    my $testVMDir = dirname($testVM);
    my $masterVMDir = dirname($testVMDir) . "/test_vm_master";
    my $masterVM = $masterVMDir . "/" . basename($testVM);

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

    HoneyClient::Manager::VM->destroy();
    sleep (1);

    # Create a generic clone, with test state data.
    my $clone = HoneyClient::Manager::VM::Clone->new(test => 1, master_vm_config => $masterVM);
    is($clone->{test}, 1, "new(test => 1, master_vm_config => '$masterVM')") or diag("The new() call failed.");
    isa_ok($clone, 'HoneyClient::Manager::VM::Clone', "new(test => 1, master_vm_config => '$masterVM')") or diag("The new() call failed.");

    # Destroy the master VM.
    $som = $stub->destroyVM(config => $masterVM);
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

sub new {
    # - This function takes in an optional hashtable,
    #   that contains various key => 'value' configuration
    #   parameters.
    #
    # - For each parameter given, it overwrites any corresponding
    #   parameters specified within the default hashtable, %PARAMS, 
    #   with custom entries that were given as parameters.
    #
    # - Finally, it returns a blessed instance of the
    #   merged hashtable, as an 'object'.

    # Get the class name.
    my $self = shift;

    # Get the rest of the arguments, as a hashtable.
    # Hash-based arguments are used, since HoneyClient::Util::SOAP is unable to handle
    # hash references directly.  Thus, flat hashtables are used throughout the code
    # for consistency.
    my %args = @_;

    # Check to see if the class name is inherited or defined.
    my $class = ref($self) || $self;

    # Initialize default parameters.
    $self = { };
    my %params = %{dclone(\%PARAMS)};
    @{$self}{keys %params} = values %params;

    # Now, overwrite any default parameters that were redefined
    # in the supplied arguments.
    @{$self}{keys %args} = values %args;

    # Now, assign our object the appropriate namespace.
    bless $self, $class;

    # Upon first use, start up a global instance of the VM manager.
    if ($OBJECT_COUNT <= 0) {
        HoneyClient::Manager::VM->init();
    }

    # Set a valid handle for the VM daemon.
    $self->{'_vm_handle'} = getClientHandle(namespace => "HoneyClient::Manager::VM");

    # Set the master VM.
    $LOG->info("Setting VM (" . $self->{'master_vm_config'} . ") as master.");
    my $som = $self->{'_vm_handle'}->setMasterVM(config => $self->{'master_vm_config'});
    if (!$som->result()) {
        $LOG->fatal("Unable to set VM (" . $self->{'master_vm_config'} . ") as a master VM.");
        Carp::croak "Unable to set VM (" . $self->{'master_vm_config'} . ") as a master VM.";
    }

    # Update our global object count.
    $OBJECT_COUNT++;

    # Finally, return the blessed object.
    return $self;
}

=pod

=head2 $object->start()

=over 4

If not previously called, this method creates a new clone VM
from the supplied master VM.  Furthermore, this method will power
on the clone, and wait until the clone VM has fully booted and
has an operational Agent daemon running on it.

During this power on process, the name, MAC address, and 
IP address of the running clone are recorded in the object.

I<Output>: The updated Clone B<$object>, containing state information
from starting the clone VM.  Will croak if this operation fails.

=back

# XXX: FINISH THIS
#=begin testing
#
# Create a generic driver, with test state data.
#my $driver = HoneyClient::Agent::Driver->new(test => 1);
#dies_ok {$driver->drive()} 'drive()' or diag("The drive() call failed.  Expected drive() to throw an exception.");
#
#=end testing

=cut

sub start {

    # Extract arguments.
    my ($self, %args) = @_;

    # Sanity check: Make sure we've been fed an object.
    unless (ref($self)) {
        $LOG->error("Error: Function must be called in reference to a " .
                    __PACKAGE__ . "->new() object!");
        Carp::croak "Error: Function must be called in reference to a " .
                    __PACKAGE__ . "->new() object!";
    }
    
    # Temporary variable to hold SOAP Object Message.
    my $som = undef;

    # Temporary variable to hold return message data.
    my $ret = undef;

    # Perform the quick clone operation.
    $LOG->info("Quick cloning master VM (" . $self->{'master_vm_config'} . ").");
    $som = $self->{'_vm_handle'}->quickCloneVM(src_config => $self->{'master_vm_config'});
    $ret = $som->result();
    if (!$ret) {
        $LOG->fatal("Unable to quick clone master VM (" . $self->{'master_vm_config'} . ").");
        Carp::croak "Unable to quick clone master VM (" . $self->{'master_vm_config'} . ").";
    }
    # Set the cloned VM configuration.
    $self->{'_clone_vm_config'} = $ret;

    # Wait until the VM gets registered, before proceeding.
    $LOG->info("Checking if clone VM (" . $self->{'_clone_vm_config'} . ") is registered.");
    $ret = undef;
    while (!defined($ret) or !$ret) {
        $som = $self->{'_vm_handle'}->isRegisteredVM(config => $self->{'_clone_vm_config'});
        $ret = $som->result();

        # If the VM isn't registered yet, wait before trying again.
        if (!defined($ret) or !$ret) {
            sleep ($self->{'_retry_period'});
        }
    }

    # Once registered, check if the VM is ON yet.
    $ret = undef;
    while (!defined($ret) or ($ret != VM_EXECUTION_STATE_ON)) {
        $som = $self->{'_vm_handle'}->getStateVM(config => $self->{'_clone_vm_config'});
        $ret = $som->result();

        # If the VM isn't ON yet, wait before trying again.
        if (!defined($ret) or ($ret != VM_EXECUTION_STATE_ON)) {
            sleep ($self->{'_retry_period'});
        }
    }

    # Now, get the VM's MAC address.
    $som = $self->{'_vm_handle'}->getMACaddrVM(config => $self->{'_clone_vm_config'});
    $self->{'_clone_vm_mac'} = $som->result();

    # Now, get the VM's name.
    $som = $self->{'_vm_handle'}->getNameVM(config => $self->{'_clone_vm_config'});
    $self->{'_clone_vm_name'} = $som->result();

    # Now, get the VM's IP address.
    $ret = undef;
    my $stubAgent = undef;
    my $logMsgPrinted = 0;
    while (!defined($self->{'_clone_vm_ip'}) or !defined($ret)) {
        $som = $self->{'_vm_handle'}->getIPaddrVM(config => $self->{'_clone_vm_config'});
        $self->{'_clone_vm_ip'} = $som->result();

        # If the VM isn't booted yet, wait before trying again.
        if (!defined($self->{'_clone_vm_ip'})) {
            sleep ($self->{'_retry_period'});
            next; # skip further processing
        } elsif (!$logMsgPrinted) {
            $LOG->info("Created clone VM (" . $self->{'_clone_vm_name'} . ") using IP (" .
                       $self->{'_clone_vm_ip'} . ") and MAC (" . $self->{'_clone_vm_mac'} . ".");
            $logMsgPrinted = 1;
        }
        
        # Now, try contacting the Agent.
        $stubAgent = getClientHandle(namespace     => "HoneyClient::Agent",
                                     address       => $self->{'_clone_vm_ip'},
                                     fault_handler => undef);

        eval {
            $som = $stubAgent->getStatus();
            $ret = $som->result();
        };
        # Clear returned state, if any fault occurs.
        if ($@) {
            $ret = undef;
        }

        # If the Agent daemon isn't responding yet, wait before trying again.
        if (!defined($ret)) {
            sleep ($self->{'_retry_period'});
        }
    }

    return $self;
}

=pod

=head2 $object->isFinished()

=over 4

Indicates if the Driver B<$object> has driven the back-end application
through the Driver's entire state and is unable to drive the application
further without additional input.

I<Output>: True if the Driver B<$object> is finished, false otherwise.

=back

#=begin testing
#
# Create a generic driver, with test state data.
#my $driver = HoneyClient::Agent::Driver->new(test => 1);
#dies_ok {$driver->isFinished()} 'isFinished()' or diag("The isFinished() call failed.  Expected isFinished() to throw an exception.");
#
#=end testing

=cut

sub isFinished {
    # Get the class name.
    my $self = shift;
    
    # Check to see if the class name is inherited or defined.
    my $class = ref($self) || $self;
    
    # Sanity check: Make sure we've been fed an object.
    unless (ref($self)) {
        $LOG->error("Error: Function must be called in reference to a " .
                    __PACKAGE__ . "->new() object!");
        Carp::croak "Error: Function must be called in reference to a " .
                    __PACKAGE__ . "->new() object!";
    }

    # Emit generic "not implemented" error message.
    $LOG->error($class . "->isFinished() is not implemented!");
    Carp::croak "Error: " . $class . "->isFinished() is not implemented!\n";
}

=pod

=head2 $object->next()

=over 4

Returns the next set of server hostnames and/or IP addresses that the
back-end application will contact, upon the next subsequent call to
the B<$object>'s drive() method.

Specifically, the returned data is a reference to a hashtable, containing
detailed information about which resources, hostnames, IPs, protocols, and 
ports that the application will contact upon the next iteration.

Here is an example of such returned data:

  $hashref = {
  
      # The set of servers that the driver will contact upon
      # the next drive() operation.
      targets => {
          # The application will contact 'site.com' using
          # TCP ports 80 and 81.
          'site.com' => {
              'tcp' => [ 80, 81 ],
          },

          # The application will contact '192.168.1.1' using
          # UDP ports 53 and 123.
          '192.168.1.1' => {
              'udp' => [ 53, 123 ],
          },
 
          # Or, more generically:
          'hostname_or_IP' => {
              'protocol_type' => [ portnumbers_as_list ],
          },
      },

      # The set of resources that the driver will operate upon
      # the next drive() operation.
      resources => {
          'http://www.mitre.org/' => 1,
      },
  };

B<Note>: For each hostname or IP address specified, if B<no>
corresponding protocol/port sub-hastables are given, then it
must be B<assumed> that the back-end application may contact
the hostname or IP address using B<ANY> protocol/port.

I<Output>: The aforementioned B<$hashref> containing the next set of
resources that the back-end application will attempt to contact upon
the next drive() iteration.

# XXX: Resolve this.

B<Note>: Eventually this B<$hashref> will become a structured object,
created via a HoneyClient::Util::* package.  However, the underlying
structure of this hashtable is not expected to change. 

=back

#=begin testing
#
# Create a generic driver, with test state data.
#my $driver = HoneyClient::Agent::Driver->new(test => 1);
#dies_ok {$driver->next()} 'next()' or diag("The next() call failed.  Expected next() to throw an exception.");
#
#=end testing

=cut

sub next {
    # Get the class name.
    my $self = shift;
    
    # Check to see if the class name is inherited or defined.
    my $class = ref($self) || $self;
    
    # Sanity check: Make sure we've been fed an object.
    unless (ref($self)) {
        $LOG->error("Error: Function must be called in reference to a " .
                    __PACKAGE__ . "->new() object!");
        Carp::croak "Error: Function must be called in reference to a " .
                    __PACKAGE__ . "->new() object!";
    }

    # Emit generic "not implemented" error message.
    $LOG->error($class . "->next() is not implemented!");
    Carp::croak "Error: " . $class . "->next() is not implemented!\n";
}

=pod

=head2 $object->status()

=over 4

Returns the current status of the Driver B<$object>, as it's state
exists, between subsequent calls to $object->driver().

Specifically, the data returned is a reference to a hashtable,
containing specific statistical information about the status
of the Driver's progress during back-end application automation.

As such, the exact structure of this returned hashtable is not strictly
defined.  Instead, it is left up to each specific Driver implementation
to return useful, statistical information back to the Agent that
makes sense for the driven application.

For example, if an Internet Explorer specific Driver were implemented,
then the corresponding status hashtable reference returned may look
something like:

  $hashref = {
      'links_remaining'  =>       56, # Number of URLs left to process.
      'links_processed'  =>       44, # Number of URLs processed.
      'links_total'      =>      100, # Total number of URLs given.
      'percent_complete' => '44.00%', # Percent complete.
  };

For another example, if an Outlook specific Driver were implemented,
then the corresponding status hashtable reference returned may look
something like:

  $hashref = {
      'mail_remaining'   =>       56, # Number of messages left to process.
      'mail_processed'   =>       44, # Number of messages processed.
      'mail_total'       =>      100, # Total number of messages given.
      'percent_complete' => '44.00%', # Percent complete.
  };

I<Output>: A corresponding B<$hashref>, containing statistical information
about the Driver's progress, as previously mentioned.

# XXX: Resolve this.

B<Note>: The exact structure of this status hashtable may become more
concrete, as we define a generic concept of a "unit of work" per every
iteration of the $object->drive() method.  For example, it may be
likely that each Driver will attempt to contact a series of resources
per every "unit of work" iteration.  As such, we may generically
record how many "work units" are remaining, processed, and total --
rather than specifically state "links" or "mail" within the hashtable
key names, accordingly.

At the least, it can be assumed that even if a generic structure were
defined, we would leave room available in the status hashtable to
capture additional, implementation-specific statistics that are not
generic among every Driver implementation.

=back

#=begin testing
#
# Create a generic driver, with test state data.
#my $driver = HoneyClient::Agent::Driver->new(test => 1);
#dies_ok {$driver->status()} 'status()' or diag("The status() call failed.  Expected status() to throw an exception.");
#
#=end testing

=cut

sub status {
    # Get the class name.
    my $self = shift;
    
    # Check to see if the class name is inherited or defined.
    my $class = ref($self) || $self;
    
    # Sanity check: Make sure we've been fed an object.
    unless (ref($self)) {
        $LOG->error("Error: Function must be called in reference to a " .
                    __PACKAGE__ . "->new() object!");
        Carp::croak "Error: Function must be called in reference to a " .
                    __PACKAGE__ . "->new() object!";
    }

    # Emit generic "not implemented" error message.
    $LOG->error($class . "->next() is not implemented!");
    Carp::croak "Error: " . $class . "->next() is not implemented!\n";
}


#######################################################################

1;

#######################################################################
# Additional Module Documentation                                     #
#######################################################################

__END__

=head1 BUGS & ASSUMPTIONS

This package has been designed in an object-oriented fashion, as a
simple B<INTERFACE> for other, more robust fully-implemented 
HoneyClient::Agent::Driver::* sub-packages to inherit.

Specifically, B<ONLY> the new() function is implemented in this package.
While this allows any user to create Driver B<$object>s by explicitly
calling the HoneyClient::Agent::Driver->new() function, any subsequent
calls to any other method (i.e., $object->drive()) will B<FAIL>, as it is
expected that fully defined Driver sub-packages would implement these
capabilities.

In a nutshell, this object is nothing more than a blessed anonymous
reference to a hashtable, where (key => value) pairs are defined in
the L<DEFAULT PARAMETER LIST>, as well as fed via the new() function
during object initialization.  As such, this package does B<not>
perform any rigorous B<data validation> prior to accepting any new
or overriding (key => value) pairs.

=head1 SEE ALSO

L<perltoot/"Autoloaded Data Methods">

L<http://www.honeyclient.org/trac>

=head1 REPORTING BUGS

L<http://www.honeyclient.org/trac/newticket>

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
