#######################################################################
# Created on:  May 11, 2006
# Package:     HoneyClient::Agent::Driver::FF
# File:        FF.pm
# Description: A specific driver for automating an instance of
#              the Firefox browser, running inside a
#              HoneyClient VM.
#
# CVS: $Id: FF.pm 773 2007-07-26 19:04:55Z kindlund $
#
# @author knwang, ttruong, kindlund, stephenson
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
#
#######################################################################

=pod

=head1 NAME

HoneyClient::Agent::Driver::Browser::FF - Perl extension to drive Mozilla 
Firefox to a given web page.  This package extends the
HoneyClient::Agent::Driver::Browser package, by overridding the drive() method.

=head1 VERSION

This documentation refers to HoneyClient::Agent::Driver::Browser::FF version 0.98.

=head1 SYNOPSIS

  use HoneyClient::Agent::Driver::Browser::FF;

  # Library used exclusively for debugging complex objects.
  use Data::Dumper;

  # Create a new FF object, initialized with a collection
  # of URLs to visit.
  my $browser = HoneyClient::Agent::Driver::Browser::FF->new(
      links_to_visit => {
          'http://www.google.com'  => 1,
          'http://www.cnn.com'     => 1,
      },
  );

  # If you want to see what type of "state information" is physically
  # inside $browser, try this command at any time.
  print Dumper($browser);

  # Continue to "drive" the driver, until it is finished.
  while (!$browser->isFinished()) {

      # Before we drive the application to a new set of resources,
      # find out where we will be going within the application, first.
      print "About to contact the following resources:\n";
      print Dumper($browser->next());

      # Now, drive browser for one iteration.
      $browser->drive();

      # Get the driver's progress.
      print "Status:\n";
      print Dumper($browser->status());

  }

  # At this stage, the driver has exhausted its collection of links
  # to visit.  Let's say we want to add the URL "http://www.mitre.org"
  # to the driver's list.
  $browser->{links_to_visit}->{'http://www.mitre.org'} = 1;

  # Now, drive the browser for one iteration.
  $browser->drive();
  
  # Or, we can specify the URL as an argument.
  $browser->drive(url => "http://www.mitre.org");

=head1 DESCRIPTION

This library allows the Agent module to drive an instance of Mozilla
Firefox inside the HoneyClient VM.  The purpose of this module is to
programmatically navigate this browser to different websites, in order to
become purposefully infected with new malware.

This module is object-oriented in design, retaining all state information
within itself for easy access.  This specific browser implementation inherits
all code from the HoneyClient::Agent::Driver::Browser package.

Fundamentally, the FF driver is initialized with a set of absolute URLs
for the browser to drive to.  Upon visiting each URL, the driver collects
any B<new> links found and will attempt to drive the browser to each
valid URL upon subsequent iterations of work.

For each top-level URL given, the driver will attempt to process all
corresponding links that are hosted on the same server, in order to
simulate a complete 'spider' of each server.  

URLs are added and removed from hashtables, as keys.  For each URL, a
calculated "priority" (a positive integer) of the URL is assigned the
value.  When the FF driver is ready to go to a new link, it will always go
to the next link that has the highest priority.  If two URLs have the same
priority, then the FF driver will chose among those two at random.

Furthermore, the FF driver will try to visit all links shared by a
common server in order before moving on to drive to other,
external links in an ordered fashion.  B<However>, the FF driver may end
up re-visiting old sites, if new links were found that the
FF driver has not visited yet. 

As the FF driver navigates the browser to each link, it
maintains a set of hashtables that record when valid links were
visited (see L<links_visited>); when invalid links were found
(see L<links_ignored>); and when the browser attempted to visit
a link but the operation timed out (see L<links_timed_out>).
By maintaining this internal history, the driver will B<never>
navigate the browser to the same link twice.

Lastly, it is highly recommended that for each driver B<$object>,
one should call $object->isFinished() prior to making a subsequent
call to $object->drive(), in order to verify that the driver has
not exhausted its set of links to visit.  Otherwise, if
$object->drive() is called with an empty set of links to visit,
the corresponding operation will B<croak>.

=cut

package HoneyClient::Agent::Driver::Browser::FF;

use strict;
use warnings;
use Carp ();

# Traps signals, allowing END: blocks to perform cleanup.
use sigtrap qw(die untrapped normal-signals error-signals);

#######################################################################
# Module Initialization                                               #
#######################################################################

BEGIN {

    # Defines which functions can be called externally.
    require Exporter;
    our ( @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS, $VERSION );

    # Set our package version.
    $VERSION = 0.98;

    # Define inherited modules.
    use HoneyClient::Agent::Driver::Browser;

    @ISA = qw(Exporter HoneyClient::Agent::Driver::Browser);

    # Symbols to export automatically
    # Note: Since this module is object-oriented, we do *NOT* export
    # any functions other than "new" to call statically.  Each function
    # for this module *must* be called as a method from a unique
    # object instance.
    @EXPORT = qw();

    # Items to export into callers namespace by default. Note: do not export
    # names by default without a very good reason. Use EXPORT_OK instead.
    # Do not simply export all your public functions/methods/constants.

    # This allows declaration use HoneyClient::Agent::Driver::Browser::FF ':all';
    # If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
    # will save memory.

    # Note: Since this module is object-oriented, we do *NOT* export
    # any functions other than "new" to call statically.  Each function
    # for this module *must* be called as a method from a unique
    # object instance.
    %EXPORT_TAGS = ( 'all' => [qw()], );

    # Symbols to autoexport (when qw(:all) tag is used)
    @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

    $SIG{PIPE} = 'IGNORE';    # Do not exit on broken pipes.
}
our ( @EXPORT_OK, $VERSION );

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
BEGIN { use_ok('HoneyClient::Agent::Driver::Browser::FF') or diag("Can't load HoneyClient::Agent::Driver::Browser::FF package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('HoneyClient::Agent::Driver::Browser::FF');
can_ok('HoneyClient::Agent::Driver::Browser::FF', 'new');
can_ok('HoneyClient::Agent::Driver::Browser::FF', 'drive');
can_ok('HoneyClient::Agent::Driver::Browser::FF', 'isFinished');
can_ok('HoneyClient::Agent::Driver::Browser::FF', 'next');
can_ok('HoneyClient::Agent::Driver::Browser::FF', 'status');
can_ok('HoneyClient::Agent::Driver::Browser::FF', 'getNextLink');
use HoneyClient::Agent::Driver::Browser::FF;

# Suppress all logging messages, since we need clean output for unit testing.
Log::Log4perl->init({
    "log4perl.rootLogger"                               => "DEBUG, Buffer",
    "log4perl.appender.Buffer"                          => "Log::Log4perl::Appender::TestBuffer",
    "log4perl.appender.Buffer.min_level"                => "fatal",
    "log4perl.appender.Buffer.layout"                   => "Log::Log4perl::Layout::PatternLayout",
    "log4perl.appender.Buffer.layout.ConversionPattern" => "%d{yyyy-MM-dd HH:mm:ss} %5p [%M] (%F:%L) - %m%n",
});

# Make sure Win32::Job loads.
BEGIN { use_ok('Win32::Job') or diag("Can't load Win32::Job package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('Win32::Job');
use Win32::Job;

# Make sure ExtUtils::MakeMaker loads.
BEGIN { use_ok('ExtUtils::MakeMaker', qw(prompt)) or diag("Can't load ExtUtils::MakeMaker package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('ExtUtils::MakeMaker');
can_ok('ExtUtils::MakeMaker', 'prompt');
use ExtUtils::MakeMaker qw(prompt);

=end testing

=cut

#######################################################################

# Include the Global Configuration Processing Library
use HoneyClient::Util::Config qw(getVar);

# Include Win32 Job Library
use Win32::Job;

# Include Logging Library
use Log::Log4perl qw(:easy);

# The global logging object.
our $LOG = get_logger();

#######################################################################
# Public Methods Implemented                                          #
#######################################################################

=pod

=head1 METHODS OVERRIDDEN

The following functions have been overridden by the FF driver.  All other
methods were implemented by the generic Browser driver.  For further
information about the Browser driver, see the L<HoneyClient::Agent::Driver::Browser>
documentation.

=head2 $object->drive(url => $url)

=over 4

Drives an instance of Mozilla Firefox for one iteration,
navigating either to the specified URL or to the next URL computed within
the Browser driver's internal hashtables.

For a description of which hashtable is consulted upon each iteration of
drive(), see the B<next_link_to_visit> description of the 
L<HoneyClient::Agent::Driver::Browser> documentation, in the
"DEFAULT PARAMETER LIST" section.

Once a drive() iternation has completed, the corresponding browser process
is terminated.  Thus, each call to drive() invokes a new instance of the
browser.

I<Inputs>:
 B<$url> is an optional argument, specifying the next immediate URL the browser
must drive to.

I<Output>: The updated FF driver B<$object>, containing state information from driving the
browser for one iteration.

B<Warning>: This method will B<croak>, if the FF driver object is B<unable>
to navigate to a new link, because its list of links to vist is empty and no new
URL was supplied.

=back

=begin testing

# Generate a notice, to clarify our assumptions.
diag("");
diag("About to run basic FF-specific browser tests.");
diag("Note: These tests *require* network connectivity and");
diag("*expect* FF to be installed at the following location.");
diag("");

my $processExec = getVar(name      => "process_exec",
                         namespace => "HoneyClient::Agent::Driver::Browser::FF");
my $processName = getVar(name      => "process_name",
                         namespace => "HoneyClient::Agent::Driver::Browser::FF");

diag("Process Name:\t\t'" . $processName . "'");
diag("Process Location:\t'" . $processExec . "'");
diag("");
diag("If FF is installed in a different location or has a different executable name,");
diag("then please answer *NO* to the next question and update your etc/honeyclient.xml");
diag("file, changing the 'process_name' and 'process_exec' elements in the");
diag("<HoneyClient/><Agent/><Driver/><Browser/><FF/> section.");
diag("");
diag("Then, once updated, re-run these tests.");
diag("");

my $question;
$question = prompt("# Do you want to run these tests?", "yes");
if ($question !~ /^y.*/i) {
    exit;
}

my $ie = HoneyClient::Agent::Driver::Browser::FF->new(test => 1);
is($ie->{test}, 1, "new(test => 1)") or diag("The new() call failed.");
isa_ok($ie, 'HoneyClient::Agent::Driver::Browser::FF', "new(test => 1)") or diag("The new() call failed.");

diag("");
diag("About to drive FF to a specific website for *exactly* " . $ie->{timeout} . " seconds.");
diag("Note: Please do *NOT* close the browser manually; the test code should close it automatically.");
diag("");

$question = prompt("# Which website should FF browse to?", "http://www.google.com");
$ie->drive(url => $question);

diag("");
$question = prompt("# Did FF properly render the page and automatically exit?", "yes");
diag("");
if ($question !~ /^y.*/i) {
    diag("Check your network connectivity and verify that you can manually browse this page in FF.");
    diag("Then, re-run these tests.");
    diag("");
    diag("If the tests still do not work, please submit a ticket to:");
    diag("http://www.honeyclient.org/trac/newticket");
    diag("");
    fail("The drive() call failed.");
}

diag("About to restart FF.  Please check if the \"Restore Previous Session\" dialog box appears.");
diag("");
$question = prompt("# Pick another website for FF to browse to:", "http://www.mitre.org");
$ie->drive(url => $question);

diag("");
$question = prompt("# Did the \"Restore Previous Session\" dialog box appear?", "yes");
diag("");
if ($question !~ /^n.*/i) {
    diag("You will need to disable the \"Restore Previous Session\" dialog box manually in Firefox.");
    diag("Here's how:");
    diag("1) Start up Firefox manually.");
    diag("2) Go to 'about:config'.");
    diag("3) Change the 'browser.sessionstore.resume_from_crash' value to 'false'.");
    diag("");
    diag("Then, re-run these tests.");
    diag("");
    diag("If the tests still do not work, please submit a ticket to:");
    diag("http://www.honeyclient.org/trac/newticket");
    diag("");
    fail("The drive() call failed.");
}

=end testing

=cut

sub drive {

    # Extract arguments.
    my ($self, %args) = @_;

    # Sanity check: Make sure we've been fed an object.
    unless (ref($self)) {
        $LOG->error("Error: Function must be called in reference to a " .
                    __PACKAGE__ . "->new() object!");
        Carp::croak "Error: Function must be called in reference to a " .
                    __PACKAGE__ . "->new() object!\n";
    }

    # Sanity check, don't get the next link, if
    # we've been fed a url.
    my $argsExist = scalar(%args);
    if (!$argsExist ||
        !exists($args{'url'}) ||
        !defined($args{'url'})) {
        # Get the next URL from our hashtables.
        $args{'url'} = $self->_getNextLink();
    }

    # Drive the generic browser before opening with FF
    $self = $self->SUPER::drive(%args);
    
    # Sanity check: Make sure our next URL is defined.
    unless (defined($args{'url'})) {
        $LOG->error("Error: Unable to drive browser - no links left to browse!");
        Carp::croak "Error: Unable to drive browser - no links left to browse!\n";
    }

    # Indicates how long we wait for each drive operation to complete,
    # before registering attempt as a failure.
    my $timeout : shared = $self->timeout();

    # Create a new Job.
    my $job = Win32::Job->new();

    # Sanity check.
    if (!defined($job)) {
        $LOG->error("Error: Unable to spawn a new process - " . $^E . ".");
        Carp::croak "Error: Unable to spawn a new process - " . $^E . ".\n";
    }

    # Spawn the job.
    my $processExec = getVar(name => "process_exec");
    my $processName = getVar(name => "process_name");
    my $status = $job->spawn($processExec, $processName . " " . $args{'url'});

    # Sanity check.
    if (!defined($status)) {
        $LOG->error("Error: Unable to spawn a new browser - " . $^E . ".");
        Carp::croak "Error: Unable to spawn a new browser - " . $^E . ".\n";
    }

    # Run the job.
    $job->run($timeout);

    # Check to see if run fails.
    $status = $job->status();

    # Sanity check.
    if (!defined($status) ||
        !scalar(%{$status})) {
        $LOG->error("Error: Unable to retrieve job status from spawned process.");
        Carp::croak "Error: Unable to retrieve job status from spawned process.\n";
    }

    # Figure out the correct Process ID.
    my @keys = keys(%{$status});
    my $processID = pop(@keys);

    # Sanity checks.
    if (!defined($processID) ||
        !exists($status->{$processID}->{'exitcode'}) ||
        !defined($status->{$processID}->{'exitcode'})) {
        $LOG->error("Error: Unable to retrieve job status from spawned process.");
        Carp::croak "Error: Unable to retrieve job status from spawned process.\n";
    }

    # TODO: We may want to report this suspicious activity back to the Agent;
    # perhaps force the Agent to do an early integrity check, to make sure nothing
    # sketchy is going on.

    # Check to make sure the exitcode is '293', meaning, that the
    # application didn't unexpectedly die early.
    if ($status->{$processID}->{'exitcode'} != 293) {
        $LOG->warn("Unexpected: '" . $processName . "' process (ID = " . $processID . ") terminated early!");
    }

    # Return the modified object state.
    return $self;
}

#######################################################################

1;

#######################################################################
# Additional Module Documentation                                     #
#######################################################################

__END__

=head1 BUGS & ASSUMPTIONS

This package will only run on Win32 platforms.  Furthermore, it has
only been tested to work reliably within a Cygwin environment.

In a nutshell, this object is nothing more than a blessed anonymous
reference to a hashtable, where (key => value) pairs are defined in
the L<DEFAULT PARAMETER LIST>, as well as fed via the new() function
during object initialization.  As such, this package does B<not>
perform any rigorous B<data validation> prior to accepting any new
or overriding (key => value) pairs.

However, additional links can be fed to any FF driver at any time, by
simply adding new hashtable entries to the B<links_to_visit> hashtable
within the B<$object>.

For example, if you wanted to add the URL "http://www.mitre.org"
to the FF driver B<$object>, simply use the following code:

  $object->{links_to_visit}->{'http://www.mitre.org'} = 1;

In general, the FF driver does B<not> know how many links it will
ultimately end up browsing to, until it conducts an exhaustive
spider of all initial URLs supplied.  As such, expect the output
of $object->status() to change significantly, upon each
$object->drive() iteration.

For example, if at one given point, the status of B<percent_complete>
is 30% and then this value drops to 15% upon another iteration, then
this means that the total number of links to drive to has greatly
increased.

Lastly, we assume that the Mozilla Firefox browser has
been preconfigured to B<not cache any data>.  This ensures the browser
will render the most recent version of the content hosted at each URL.

=head1 SEE ALSO

L<HoneyClient::Agent::Driver>

L<HoneyClient::Agent::Driver::Browser>

L<HoneyClient::Agent::Driver::Browser::IE>

L<http://www.honeyclient.org/trac>

=head1 REPORTING BUGS

L<http://www.honeyclient.org/trac/newticket>

=head1 AUTHORS

Kathy Wang, E<lt>knwang@mitre.orgE<gt>

Thanh Truong, E<lt>ttruong@mitre.orgE<gt>

Darien Kindlund, E<lt>kindlund@mitre.orgE<gt>

Brad Stephenson, E<lt>stephenson@mitre.orgE<gt>

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

