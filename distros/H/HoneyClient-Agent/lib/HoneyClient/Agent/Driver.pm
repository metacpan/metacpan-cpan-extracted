#######################################################################
# Created on:  May 11, 2006
# Package:     HoneyClient::Agent::Driver
# File:        Driver.pm
# Description: Generic driver model for all drivers running inside a
#              HoneyClient VM.
#
# CVS: $Id: Driver.pm 773 2007-07-26 19:04:55Z kindlund $
#
# @author knwang, ttruong, kindlund
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

HoneyClient::Agent::Driver - Perl extension to provide a generic driver
interface for all drivers resident within any HoneyClient VM.

=head1 VERSION

This documentation refers to HoneyClient::Agent::Driver version 0.98.

=head1 SYNOPSIS

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

package HoneyClient::Agent::Driver;

use strict;
use warnings;
use Carp ();

#######################################################################
# Module Initialization                                               #
#######################################################################

BEGIN {
    # Defines which functions can be called externally.
    require Exporter;
    our (@ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS, $VERSION);

    # Set our package version.
    $VERSION = 0.98;

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

    # This allows declaration use HoneyClient::Agent::Driver ':all';
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

# Make sure the module loads properly, with the exportable
# functions shared.
BEGIN { use_ok('HoneyClient::Agent::Driver') or diag("Can't load HoneyClient::Agent::Driver package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('HoneyClient::Agent::Driver');
can_ok('HoneyClient::Agent::Driver', 'new');
can_ok('HoneyClient::Agent::Driver', 'drive');
can_ok('HoneyClient::Agent::Driver', 'isFinished');
can_ok('HoneyClient::Agent::Driver', 'next');
can_ok('HoneyClient::Agent::Driver', 'status');
use HoneyClient::Agent::Driver;

# Suppress all logging messages, since we need clean output for unit testing.
Log::Log4perl->init({
    "log4perl.rootLogger"                               => "DEBUG, Buffer",
    "log4perl.appender.Buffer"                          => "Log::Log4perl::Appender::TestBuffer",
    "log4perl.appender.Buffer.min_level"                => "fatal",
    "log4perl.appender.Buffer.layout"                   => "Log::Log4perl::Layout::PatternLayout",
    "log4perl.appender.Buffer.layout.ConversionPattern" => "%d{yyyy-MM-dd HH:mm:ss} %5p [%M] (%F:%L) - %m%n",
});

# Make sure we use the exception testing library.
require_ok('Test::Exception');
can_ok('Test::Exception', 'dies_ok');
use Test::Exception;

# Make sure Storable loads.
BEGIN { use_ok('Storable', qw(dclone)) or diag("Can't load Storable package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('Storable');
can_ok('Storable', 'dclone');
use Storable qw(dclone);

=end testing

=cut

#######################################################################

# Include Global Configuration Processing Library
use HoneyClient::Util::Config qw(getVar);

# Use Storable Library
use Storable qw(dclone);

# Package Global Variable
our $AUTOLOAD;

# Include Logging Library
use Log::Log4perl qw(:easy);

# The global logging object.
our $LOG = get_logger();

=pod

=head1 DEFAULT PARAMETER LIST

When a Driver B<$object> is instantiated using the B<new()> function,
the following parameters are supplied default values.  Each value
can be overridden by specifying the new (key => value) pair into the
B<new()> function, as arguments.

Furthermore, as each parameter is initialized, each can be individually 
retrieved and set at any time, using the following syntax:

  my $value = $object->{key}; # Gets key's value.
  $object->{key} = $value;    # Sets key's value.

=head2 timeout

=over 4

This parameter indicates how long (in seconds) the Driver should wait 
for an application response, once driven for one iteration. 
The default value is any valid "timeout" setting located within the
global configuration file that matches any portion of this package's
namespace.  See L<HoneyClient::Util::Config> for more information.

=back

=cut

#######################################################################
# Private Methods Implemented                                         #
#######################################################################

# Helper function designed to programmatically get or set parameters
# within this object, through indirect use of the AUTOLOAD function.
#
# It's best to explain by example:
# Assume we have defined a driver object, like the following.
#
# use HoneyClient::Agent::Driver;
# my $driver = HoneyClient::Agent::Driver->new(someVar => 'someValue');
#
# What this function allows us to do, is programmatically, get or set
# the 'someVar' parameter, like:
#
# my $value = $driver->someVar();    # Gets the value of 'someVar'.
# my $value = $driver->someVar('2'); # Sets the value of 'someVar' to '2'
#                                    # and returns '2'.
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
    my $type = ref($self);
    unless(defined($type)) {
        $LOG->error("Error: $self is not an object!");
        Carp::croak "Error: $self is not an object!\n";
    }

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
}

#######################################################################
# Public Methods Implemented                                          #
#######################################################################

=pod

=head1 METHOD INTERFACES

The following functions B<must> be implemented be each driver
implementation, upon inheriting this package interface.

=head2 HoneyClient::Agent::Driver->new($param => $value, ...)

=over 4

Creates a new Driver object, which contains a hashtable
containing any of the supplied "param => value" arguments.

I<Inputs>:
 B<$param> is an optional parameter variable.
 B<$value> is $param's corresponding value.
 
Note: If any $param(s) are supplied, then an equal number of
corresponding $value(s) B<must> also be specified.

I<Output>: The instantiated Driver B<$object>, fully initialized.

=back

=begin testing

# Create a generic driver, with test state data.
my $driver = HoneyClient::Agent::Driver->new(test => 1);
is($driver->{test}, 1, "new(test => 1)") or diag("The new() call failed.");
isa_ok($driver, 'HoneyClient::Agent::Driver', "new(test => 1)") or diag("The new() call failed.");

=end testing

=cut

sub new {
    # - This function takes in an optional hashtable,
    #   that contains various key => 'value' configuration
    #   parameters.
    #
    # - For each parameter given, it overwrites any corresponding
    #   parameters specified within the default hashtable, %params, 
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
    my %params = (
        timeout     => getVar(name => "timeout"), # Timeout (in seconds).
    );

    @{$self}{keys %params} = values %params;

    # Now, overwrite any default parameters that were redefined
    # in the supplied arguments.
    @{$self}{keys %args} = values %args;

    # Now, assign our object the appropriate namespace.
    bless $self, $class;

    # Finally, return the blessed object.
    return $self;
}

=pod

=head2 $object->drive()

=over 4

Drives the back-end application for one iteration, updating the
corresponding internal object state with information obtained
from driving this application for one iteration.

I<Output>: The updated Driver B<$object>, containing state information
from driving the application for one iteration.  Will croak if
operation fails.

=back

=begin testing

# Create a generic driver, with test state data.
my $driver = HoneyClient::Agent::Driver->new(test => 1);
dies_ok {$driver->drive()} 'drive()' or diag("The drive() call failed.  Expected drive() to throw an exception.");

=end testing

=cut

sub drive {
    # Get the class name.
    my $self = shift;
    
    # Check to see if the class name is inherited or defined.
    my $class = ref($self) || $self;

    # Emit generic "not implemented" error message.
    $LOG->error($class . "->drive() is not implemented!");
    Carp::croak "Error: " . $class . "->drive() is not implemented!\n";
}

=pod

=head2 $object->isFinished()

=over 4

Indicates if the Driver B<$object> has driven the back-end application
through the Driver's entire state and is unable to drive the application
further without additional input.

I<Output>: True if the Driver B<$object> is finished, false otherwise.

=back

=begin testing

# Create a generic driver, with test state data.
my $driver = HoneyClient::Agent::Driver->new(test => 1);
dies_ok {$driver->isFinished()} 'isFinished()' or diag("The isFinished() call failed.  Expected isFinished() to throw an exception.");

=end testing

=cut

sub isFinished {
    # Get the class name.
    my $self = shift;
    
    # Check to see if the class name is inherited or defined.
    my $class = ref($self) || $self;

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

=begin testing

# Create a generic driver, with test state data.
my $driver = HoneyClient::Agent::Driver->new(test => 1);
dies_ok {$driver->next()} 'next()' or diag("The next() call failed.  Expected next() to throw an exception.");

=end testing

=cut

sub next {
    # Get the class name.
    my $self = shift;
    
    # Check to see if the class name is inherited or defined.
    my $class = ref($self) || $self;

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

=begin testing

# Create a generic driver, with test state data.
my $driver = HoneyClient::Agent::Driver->new(test => 1);
dies_ok {$driver->status()} 'status()' or diag("The status() call failed.  Expected status() to throw an exception.");

=end testing

=cut

sub status {
    # Get the class name.
    my $self = shift;
    
    # Check to see if the class name is inherited or defined.
    my $class = ref($self) || $self;

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
