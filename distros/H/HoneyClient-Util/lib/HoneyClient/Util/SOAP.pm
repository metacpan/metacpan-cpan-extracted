#######################################################################
# Created on:  Apr 20, 2006
# Package:     HoneyClient::Util::SOAP
# File:        SOAP.pm
# Description: Generic interface to server and client SOAP operations.
#
# CVS: $Id: SOAP.pm 773 2007-07-26 19:04:55Z kindlund $
#
# @author ttruong, kindlund
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

HoneyClient::Util::SOAP - Perl extension to provide a generic interface
to all client and server SOAP operations, for any HoneyClient module.

=head1 VERSION

This documentation refers to HoneyClient::Util::SOAP version 0.98.

=head1 SYNOPSIS

=head2 CREATING A SOAP SERVER

  use HoneyClient::Util::SOAP qw(getServerHandle);

  # Create a new SOAP server, using default values.
  my $daemon = getServerHandle();

  # In the previous example, if this code were listed in package
  # "A::B", where the package's global configuration variables
  # for "address" and "port" was "localhost" and "8080" respectively
  # (as listed in etc/honeyclient.conf), then the corresponding
  # SOAP server URL would be:
  #
  # http://localhost:8080/A/B

  # Create a new SOAP server, using specific address/ports.
  my $daemon = getServerHandle(address => "localhost",
                               port    => 9090);

  # Create a new SOAP server, using the specific "A::B::C" namespace.
  my $daemon = getServerHandle(address   => "localhost",
                               port      => 9090,
                               namespace => "A::B::C");

  # When you're ready to start listening for connections, call
  # the handle() function, like:
  $daemon->handle();

  # Note: Remember, this handle() call *will* block.  If you have
  # any other code you want to execute after calling handle(), then
  # it is suggested that you call handle() from within a child
  # process or thread.

=head2 CREATING A SOAP CLIENT

  use HoneyClient::Util::SOAP qw(getClientHandle);

  # Create a new SOAP client, to talk to the HoneyClient::Manager::VM
  # module.
  my $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");

  # Create a new SOAP client, to talk to the HoneyClient::Agent::Driver
  # module
  my $stub = getClientHandle(namespace => "HoneyClient::Agent::Driver");

  # Create a new SOAP client, to talk to the HoneyClient::Manager::VM
  # module on localhost:9090.
  my $stub = getClientHandle(namespace => "HoneyClient::Agent::Driver",
                             address   => "localhost",
                             port      => 9090);
  
  # Create a new SOAP client, to talk to the HoneyClient::Manager::VM
  # module on localhost:9090, using a custom fault handler.
  $faultHandler = sub { die "Something bad happened!"; };
  my $stub = getClientHandle(namespace     => "HoneyClient::Agent::Driver",
                             address       => "localhost",
                             port          => 9090,
                             fault_handler => $faultHandler);

  # Create a new SOAP client, as a callback to this package.
  my $stub = getClientHandle();

=head1 DESCRIPTION

This library allows any HoneyClient module to quickly create new
SOAP servers or interact with existing ones, by using ports and
protocols that are globally defined within a configuration file,
rather than using hard coded values within each module.

This library makes extensive use of the SOAP::Lite module.

=cut

package HoneyClient::Util::SOAP;

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
    @EXPORT = qw(getServerHandle getClientHandle);

    # Items to export into callers namespace by default. Note: do not export
    # names by default without a very good reason. Use EXPORT_OK instead.
    # Do not simply export all your public functions/methods/constants.

    # This allows declaration use HoneyClient::Util::SOAP ':all';
    # If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
    # will save memory.

    %EXPORT_TAGS = (
        'all' => [ qw(getServerHandle getClientHandle) ],
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

# Make sure the module loads properly, with the exportable
# functions shared.
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

# Suppress all logging messages, since we need clean output for unit testing.
Log::Log4perl->init({
    "log4perl.rootLogger"                               => "DEBUG, Buffer",
    "log4perl.appender.Buffer"                          => "Log::Log4perl::Appender::TestBuffer",
    "log4perl.appender.Buffer.min_level"                => "fatal",
    "log4perl.appender.Buffer.layout"                   => "Log::Log4perl::Layout::PatternLayout",
    "log4perl.appender.Buffer.layout.ConversionPattern" => "%d{yyyy-MM-dd HH:mm:ss} %5p [%M] (%F:%L) - %m%n",
});

# Make sure SOAP::Lite loads.
BEGIN { use_ok('SOAP::Lite') or diag("Can't load SOAP::Lite package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('SOAP::Lite');
use SOAP::Lite;

# Make sure SOAP::Transport::HTTP loads.
BEGIN { use_ok('SOAP::Transport::HTTP') or diag("Can't load SOAP::Transport::HTTP package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('SOAP::Transport::HTTP');
use SOAP::Transport::HTTP;

# Make sure Data::Dumper loads.
BEGIN { use_ok('Data::Dumper') or diag("Can't load Data::Dumper package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('Data::Dumper');
use Data::Dumper;

=end testing

=cut

#######################################################################

# Include utility access to global configuration.
use HoneyClient::Util::Config qw(getVar);

# Include the SOAP APIs
use SOAP::Lite 0.67;

# If you want debugging on, use this line instead.
#use SOAP::Lite +trace => 'all';
use SOAP::Transport::HTTP;

# Include Data Dumper API
use Data::Dumper;

# Include Logging Library
use Log::Log4perl qw(:easy);

# The global logging object.
our $LOG = get_logger();

# Make Dumper format more terse.
$Data::Dumper::Terse = 1;
$Data::Dumper::Indent = 0;

#######################################################################
# Private Methods Implemented                                         #
#######################################################################

# Default handler for any faults that are received by any client.
# Inputs: Class, SOAP::SOM
# Outputs: None
sub _handleFault {

	# Extract arguments.
	my ($class, $res) = @_;

	# Construct error message.
	# Figure out if the error occurred in transport or
	# over on the other side.
	my $errMsg = $class->transport->status; # Assume transport error.
	if (ref $res) {
		# Extract base error message.
		$errMsg = $res->faultcode . ": " . $res->faultstring . "\n";

		# Extract error details.
		my $errNo  = undef; 
		my $errStr = undef; 
		my $errDetail = "";
		if (defined($res->faultdetail)) {

            # Since we don't know what the fault detail may look like,
            # we output its contents in a generic fashion.
            # Make Dumper format more terse.
            $Data::Dumper::Terse = 1;
            $Data::Dumper::Indent = 0;
            $errDetail = $res->faultcode . ": " . Dumper($res->faultdetail);

		}

		$errMsg = $errMsg . $errDetail . "\n";
	}

	$LOG->error("Error occurred during processing. " . $errMsg);
	die __PACKAGE__ . "->handleFault(): Error occurred during processing.\n" . $errMsg;
}

#######################################################################
# Public Methods Implemented                                          #
#######################################################################

=pod

=head1 EXPORTS

=head2 getServerHandle(namespace => $caller, address => $localAddr, port => $localPort)

=over 4

Returns a new SOAP::Server object, using the caller's package
namespace as the dispatch location, if not specified.  If neither 
the $localAddr nor $localPort is specified, then the function will attempt 
to retrieve the "address" and "port" global configuration variables, set 
within the caller's namespace.

I<Inputs>: 
 B<$caller> is an optional argument, used to explicitly specify the package 
namespace to be used as the dispatch point.
 B<$localAddr> is an optional argument, specifying the IP address for the 
SOAP server to listen on.
 B<$localPort> is an optional argument, specifying the TCP port for the 
SOAP server to listen on.
 
I<Output>: The corresponding SOAP::Server object if successful, croaks
otherwise.

=back

=begin testing

# Check to make sure we can get a valid handle.
my $daemon = getServerHandle(namespace => "HoneyClient::Manager::VM");
isa_ok($daemon, 'SOAP::Server', "getServerHandle(namespace => 'HoneyClient::Manager::VM')") or diag("The getServerHandle() call failed.");

=end testing

=cut

sub getServerHandle {

    # Extract arguments.
    my (%args) = @_;
    my $argsExist = scalar(%args);

    # Find out who is calling this function.
    if (!$argsExist ||
        !exists($args{'namespace'}) ||
        !defined($args{'namespace'})) {
        $args{'namespace'} = caller();
    }

    if (!$argsExist ||
        !exists($args{'address'}) ||
        !defined($args{'address'})) {
        $args{'address'} = getVar(name      => "address",
                                  namespace => $args{'namespace'});
    }

    if (!$argsExist ||
        !exists($args{'port'}) ||
        !defined($args{'port'})) {
        $args{'port'} = getVar(name      => "port",
                               namespace => $args{'namespace'});
    }

    # Log resolved arguments.
    $LOG->debug(sub {
        # Make Dumper format more terse.
        $Data::Dumper::Terse = 1;
        $Data::Dumper::Indent = 0;
        Dumper(\%args);
    });

    my $daemon = SOAP::Transport::HTTP::Daemon
                    ->new( LocalAddr => $args{'address'},
                           LocalPort => $args{'port'},
                           Reuse => 1 )
                    ->dispatch_to($args{'namespace'})
                    ->options({ compress_threshold => 10000 });

    # Sanity check.
    if (!defined($daemon)) {
        $LOG->fatal("Unable to create SOAP server using namespace " .
                    "'" . $args{'namespace'} . "', listening on " .
                    $args{'address'} . ":" . $args{'port'} . ".");
        Carp::croak "Error: Unable to create SOAP server using namespace " .
                    "'" . $args{'namespace'} . "', listening on " .
                    $args{'address'} . ":" . $args{'port'} . ".\n";
    }

    return $daemon;
}

=pod

=head2 getClientHandle(namespace => $caller, address => $address, port => $port, fault_handler => $faultHandler)

=over 4

Returns a new SOAP::Lite client object, using the caller's package
namespace as the URI, if not specified.  If neither 
the $address nor $port is specified, then the function will attempt 
to retrieve the "address" and "port" global configuration variables, set 
within the caller's namespace.

I<Inputs>: 
 B<$caller> is an optional argument, used to explicitly specify the package 
namespace URI.
 B<$address> is an optional argument, specifying the IP address for the 
SOAP server to listen on.
 B<$port> is an optional argument, specifying the TCP port for the 
SOAP server to listen on.
 B<$faultHandler> is an optional argument, specifying the code reference to 
call if a fault occurs during any subsequent SOAP call using this object.
 
I<Output>: The corresponding SOAP::Lite object if successful, croaks
otherwise.

=back

=begin testing

# Check to make sure we can get a valid handle.
my $stub = getClientHandle(namespace => "HoneyClient::Manager::VM");
isa_ok($stub, 'SOAP::Lite', "getClientHandle(namespace => 'HoneyClient::Manager::VM')") or diag("The getClientHandle() call failed.");

=end testing

=cut

sub getClientHandle {
    
    # Extract arguments.
    my (%args) = @_;
    my $argsExist = scalar(%args);
    #my ($caller, $address, $port, $faultHandler) = @_;

    # Find out who is calling this function.
    if (!$argsExist ||
        !exists($args{'namespace'}) ||
        !defined($args{'namespace'})) {
        $args{'namespace'} = caller();
    }

    if (!$argsExist ||
        !exists($args{'address'}) ||
        !defined($args{'address'})) {
        $args{'address'} = getVar(name      => "address",
                                  namespace => $args{'namespace'});
    }

    if (!$argsExist ||
        !exists($args{'port'}) ||
        !defined($args{'port'})) {
        $args{'port'} = getVar(name      => "port",
                               namespace => $args{'namespace'});
    }
   
    # If no fault handler was supplied, use the default.
    if (!$argsExist ||
        !exists($args{'fault_handler'}) ||
        !defined($args{'fault_handler'})) {
        $args{'fault_handler'} = \&_handleFault;
    }

    # Log resolved arguments.
    $LOG->debug(sub {
        # Make Dumper format more terse.
        $Data::Dumper::Terse = 1;
        $Data::Dumper::Indent = 0;
        Dumper(\%args);
    });

    my $timeout = getVar(name      => "timeout",
                         namespace => $args{'namespace'});
    my $URL_BASE = "http://" . $args{'address'} . ":" . $args{'port'};
    my $URL = $URL_BASE . "/" . join('/', split(/::/, $args{'namespace'}));

    my $stub = SOAP::Lite
                ->default_ns($URL)
                ->proxy($URL_BASE, timeout => $timeout);

    # If we were supplied with a fault handler, register it.
    if (defined($args{'fault_handler'}) and
        (ref($args{'fault_handler'}) eq "CODE")) {
        $stub->on_fault($args{'fault_handler'});
    }
    
    # Sanity check.
    if (!defined($stub)) {
        $LOG->fatal("Unable to connect to SOAP server at: " .
                    "$URL");
        Carp::croak "Error: Unable to connect to SOAP server at: " .
                    "$URL\n";
    }

    return $stub;
}

1;

#######################################################################
# Additional Module Documentation                                     #
#######################################################################

__END__

=head1 HANDLING FAULTS

When talking to any SOAP server, it is B<highly recommended> that you
create a SOAP B<fault handler>, when creating a new client to talk to
the server.  This will ensure that B<all> errors are properly relayed
back to the client, including errors that occur during a failure within
SOAP communications or from errors that occur as a result of a remote call
failure.

=head2 EXAMPLE SERVER-SIDE FAULT CODE

  Q)  So, how do I properly generate SOAP faults in my server code?

  A1) For basic errors that include just an error string, here's what you'd 
      include:

  # Assume you want to generate fault message "Unspecified argument." within
  # function "foo()".

  sub foo {

      # ... do other stuff ...
    
      # Check for some error status condition.
      if ($condition) {
          die SOAP::Fault->faultcode(__PACKAGE__ . "->foo()")
                         ->faultstring("Unspecified argument.");
      }
  }

  A2) For complex errors, where you want to include an error number
      along with an error message of an upstream function call, then
      here's what you'd include:

  # Assume you want to generate fault message "Unspecified argument." within
  # function "foo()", but include an upstream error number and string as well.

  sub foo {

      # ... do other stuff ...
    
      # Check for some error status condition.
      if ($condition) {

          my $errorNumber = ...get the upstream error number...;
          my $errorString = ...get the upstream error string...; 

          die SOAP::Fault->faultcode(__PACKAGE__ . "->foo()")
                         ->faultstring("Unspecified argument.")
                         ->faultdetail(bless { errNo  => $errorNumber,
                                               errStr => $errorString },
                                       'err');
      }
  }

=head2 EXAMPLE CLIENT-SIDE FAULT CODE

  Q) So, now that I'm generating faults in my SOAP server, how do I handle
     them within my SOAP client?

  A) A default fault handler is provided by this library; however, this
     default handler will NOT know how to properly parse any data within
     the faultdetail() segment.  If you don't plan on using the
     faultdetail() field, then the default code will usually suffice.
     Otherwise, continue reading on.
  
     Assume you have faults that look like (A1) and (A2) from the previous
     EXAMPLE SERVER-SIDE FAULT CODE.  Here's example code on how to emit
     proper notification back to the user of the SOAP client:


  # Handle any faults, as they occur.
  # Inputs: Class, SOAP::SOM
  # Outputs: None
  sub handleFault {

      # Extract arguments.
      my ($class, $res) = @_;

      # Construct error message.
      # Figure out if the error occurred in transport or
      # over on the other side.
      my $errMsg = $class->transport->status; # Assume transport error.
      if (ref $res) {
          # Extract base error message.
          $errMsg = $res->faultcode . ": " . $res->faultstring . "\n";

          # Extract error details.
          my $errNo  = undef; 
          my $errStr = undef; 
          my $errDetail = "";
          if (defined($res->faultdetail)) {
              $errNo  = $res->faultdetail->{"err"}->{"errNo"};
              $errStr = $res->faultdetail->{"err"}->{"errStr"};
              $errDetail = $res->faultcode . ": (" . $errNo . ") " . $errStr;
          }

          $errMsg = $errMsg . $errDetail . "\n";
      }

      die __PACKAGE__ . "->handleFault(): Error occurred during processing.\n" . $errMsg;
  }

  Q) Okay, so I've created this "handleFault()" function within my SOAP client
     code.  What's the proper way to use this function within the getClientHandle()
     call?

  A) Here's the proper way to use your fault handler:

  # Assume you want to interact with "HoneyClient::Manager::VM" as a SOAP
  # client, using the default address and port.

  my $stub = getClientHandle(namespace     => "HoneyClient::Manager::VM",
                             fault_handler => \&handleFault);

=head1 BUGS & ASSUMPTIONS

Most likely, you will always want to specify getClientHandle(namespace => "Path::To::Module"),
when creating a new SOAP client to talk to an external module.

If you just use getClientHandle(), without any module specified, then the function
will assume you want a SOAP client to simply talk to yourself (the calling
package).  While this is useful for external callbacks, it's highly
unlikely most people will use this for normal communication.

=head1 SEE ALSO

L<http://www.honeyclient.org/trac>

SOAP::Lite, SOAP::Transport::HTTP

L<http://www.soaplite.com>

=head1 REPORTING BUGS

L<http://www.honeyclient.org/trac/newticket>

=head1 ACKNOWLEDGEMENTS

Paul Kulchenko for developing the SOAP::Lite module.

=head1 AUTHORS

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
