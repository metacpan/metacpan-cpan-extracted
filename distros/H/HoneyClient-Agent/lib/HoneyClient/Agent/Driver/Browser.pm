#######################################################################
# Created on:  November 06, 2006
# Package:     HoneyClient::Agent::Driver::Browser
# File:        Browser.pm
# Description: A generic driver for automating the link visitation
#              behavior of a web browser running inside a
#              HoneyClient VM.
#
# CVS: $Id: Browser.pm 773 2007-07-26 19:04:55Z kindlund $
#
# @author knwang, kindlund, stephenson
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

HoneyClient::Agent::Driver::Browser - Perl extension to drive a
web browser, running inside a HoneyClient VM.

=head1 VERSION

This documentation refers to HoneyClient::Agent::Driver::Browser version 0.98.

=head1 SYNOPSIS

  use HoneyClient::Agent::Driver::Browser;

  # Library used exclusively for debugging complex objects.
  use Data::Dumper;

  # Create a new Browser object, initialized with a collection
  # of URLs to visit.
  my $browser = HoneyClient::Agent::Driver::Browser->new(
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

This library allows the Agent module to drive an instance of any browser,
running inside the HoneyClient VM.  The purpose of this module is to
programmatically navigate the browser to different websites, in order to
become purposefully infected with new malware.

This module is object-oriented in design, retaining all state information
within itself for easy access.  A specific browser implementation, such as
'IE' or 'FF', must inherit from this package.

Fundamentally, the Browser driver is initialized with a set of absolute URLs
for the browser to drive to.  Upon visiting each URL, the driver collects
any B<new> links found and will attempt to drive the browser to each
valid URL upon subsequent iterations of work.

For each top-level URL given, the driver will attempt to process all
corresponding links that are hosted on the same server, in order to
simulate a complete 'spider' of each server.  

URLs are added and removed from hashtables, as keys.  For each URL, a
calculated "priority" (a positive integer) of the URL is assigned the
value.  When the Browser is ready to go to a new link, it will always go
to the next link that has the highest priority.  If two URLs have the same
priority, then the Browser will chose among those two at random.

Furthermore, the Browser driver will try to visit all links shared by a
common server in order before moving on to drive to other,
external links in an ordered fashion.  B<However>, the Browser may end
up re-visiting old sites, if new links were found that the
Browser has not visited yet. 

As the Browser driver navigates the browser to each link, it
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

package HoneyClient::Agent::Driver::Browser;

# XXX: Disabled version check, Honeywall does not have Perl v5.8 installed.
#use 5.008006;
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
    $VERSION = 0.98;

    # Define inherited modules.
    use HoneyClient::Agent::Driver;

    @ISA = qw(Exporter HoneyClient::Agent::Driver);

    # Symbols to export automatically
    # Note: Since this module is object-oriented, we do *NOT* export
    # any functions other than "new" to call statically.  Each function
    # for this module *must* be called as a method from a unique
    # object instance.
    @EXPORT = qw();

    # Items to export into callers namespace by default. Note: do not export
    # names by default without a very good reason. Use EXPORT_OK instead.
    # Do not simply export all your public functions/methods/constants.

    # This allows declaration use HoneyClient::Agent::Driver::Browser ':all';
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

    # XXX: Fix this!
    # Check to make sure our OS is Windows-based.
    #if ($Config{osname} !~ /^MSWin32$/) {
    #    Carp::croak "Error: " . __PACKAGE__ . " will only run on Win32 platforms!\n";
    #}

    $SIG{PIPE} = 'IGNORE'; # Do not exit on broken pipes.
}
our (@EXPORT_OK, $VERSION);

#######################################################################

# Include the Global Configuration Processing Library
use HoneyClient::Util::Config qw(getVar);

# Include the ActiveContent Processing Library
# TODO: Need unit testing.
use HoneyClient::Agent::Driver::ActiveContent;

# Include Temp File Library
# TODO: Need unit testing.
use File::Temp;

# Use ISO 8601 DateTime Libraries
use DateTime::HiRes;

# Use fractional second sleeping.
# TODO: Need unit testing.
use Time::HiRes qw(sleep);

# Use Storable Library
# TODO: Need unit testing.
use Storable qw(dclone);

# Use threads Library
# TODO: Need unit testing.
use threads;
# TODO: Need unit testing.
use threads::shared;

# TODO: Need unit testing.
use HoneyClient::Util::SOAP qw(getClientHandle);

# TODO: Need unit testing.
use LWP::UserAgent;

# TODO: Need unit testing.
use HTTP::Request::Common;

# TODO: Need unit testing.
use HTML::LinkExtor;

# TODO: Need unit testing.
use HTML::TokeParser;

# TODO: Need unit testing.
use URI::URL;

# TODO: Need unit testing.
use Data::Validate::URI qw(is_uri is_web_uri);

# Include Logging Library
use Log::Log4perl qw(:easy);

# The global logging object.
our $LOG = get_logger();

=pod

=head1 DEFAULT PARAMETER LIST

When a Browser B<$object> is instantiated using the B<new()> function,
the following parameters are supplied default values.  Each value
can be overridden by specifying the new (key => value) pair into the
B<new()> function, as arguments.

Furthermore, as each parameter is initialized, each can be individually
retrieved and set at any time, using the following syntax:

  my $value = $object->{key}; # Gets key's value.
  $object->{key} = $value;    # Sets key's value.

=head2 links_to_visit

=over 4

This parameter is a hashtable of fully qualified URLs for the browser
to visit.  Specifically, each 'key' corresponds to an absolute URL
and the 'value' is always 1.

=back

=head2 links_visited

=over 4

This parameter is a hashtable of fully qualified URLs that the
browser has already visited.  Specifically, each 'key' corresponds
to an absolute URL and the 'value' is a string representing the
date and time of when the link was visited.

B<Note>: See internal documentation of _getTimestamp() for the
corresponding date/time format of each value.

=back

=head2 links_ignored

=over 4

This parameter is a hashtable of fully qualified URLs that the browser
has found during its link traversal process, but the browser could not
access the link.

Links could be added to this list if access requires any type of
authentication, or if the link points to a non-HTTP or HTTPS
resource (i.e., "javascript:doNetDetect()").

Specifically, each 'key' corresponds to an absolute URL and the
'value' is a string representing the date and time of when the link
was visited.

B<Note>: See internal documentation of _getTimestamp() for the
corresponding date/time format of each value.

=back

=head2 relative_links_to_visit

=over 4

This parameter is a hashtable of fully qualified URLs, such that each
URL shares a common B<hostname>.  This is an internal hashtable used
by the Browser driver that should be initially empty.  As the Browser
driver extracts and removes new URLs off the B<links_to_visit> hashtable,
driving the browser to each URL, any B<relative> links found are
added into this hashtable; any B<external> links found are added
back into the B<links_to_visit> hashtable.

When driving to the next link, this hashtable is exhausted prior
to the main B<links_to_visit> hashtable.  This allows a
browser to navigate to all links hosted on the same server, prior
to contacting a different server.

Specifically, each 'key' corresponds to an absolute URL and the
'value' is always 1.

=back

=head2 next_link_to_visit

=over 4

This parameter is a scalar that contains the next URL to visit.
It is updated dynamically, any time $object->getNextLink() is called.

When the browser is ready to drive to the next link, B<next_link_to_visit>
is checked first.  If that value is B<undef>, then the B<relative_links_to_visit>
hashtable is checked next.  If that hashtable is empty, then finally the
B<links_to_visit> hashtable is checked last.

=back

=head2 links_timed_out

=over 4

This parameter is a hashtable of fully qualified URLs that the browser
has found during its link traversal process, but the browser
could not access the corresponding resource due to the operation
timing out.

Specifically, each 'key' corresponds to an absolute URL and the
'value' is a string representing the date and time of when access to
the resource was attempted.

B<Note>: See internal documentation of _getTimestamp() for the
corresponding date/time format of each value.

=back

=head2 ignore_timed_out_links

=over 4

If this parameter is set to 1, then the browser will also
never attempt to revisit any links that caused the browser to
time out.

=back

=head2 process_name

=over 4

A string containing the process name of the  browser application,
as it appears in the Task Manager.

=back

=head2 max_relative_links_to_visit

=over 4

An integer, representing the maximum number of relative links that
the browser should visit, before moving onto another website.  If
negative, then the browser will exhaust all possible relative links
found, before moving on.  This functionality is best effort; it's
possible for the browser to visit new links on previously visited
websites.

=back

=head2 positive_words

=over 4

An array of positive words, where a link's probability of being
visited (its score) will increase, if the link contains any of these
words.

=back

=head2 negative_words

=over 4

An array of negative words, where a link's probability of being
visited (its score) will decrease, if the link contains any of these
words.

=back

=head2 parse_active_content

=over 4

If set to 1, then the code will attempt to parse and extract links
within active content (e.g., Flash animations).  Otherwise, the
code will ignore all active content. 

=back

=cut

my %PARAMS = (

    # This is a hashtable of fully qualified URLs
    # to visit by the browser.  Specifically, the 'key' is
    # the absolute URL and the 'value' is always 1.
    links_to_visit          => { },

    # This is a hashtable of fully qualified URLs that the
    # browser has already visited.  Specifically, the
    # 'key' is the absolute URL and the 'value' is a string
    # representing the date and time of when the link was visited.
    #
    # Note: See _getTimestamp() for the corresponding date/time
    # format.
    links_visited           => { },

    # This is a hashtable of URLs that the browser has found
    # during its traversal process, but the browser could not
    # access the link.
    #
    # Links could be added to this list if access requires any type of
    # authentication, or if the link points to a non-HTTP or HTTPS
    # resource (i.e., "javascript:doNetDetect()").
    #
    # The 'key' is the absolute URL and the 'value' is a string
    # representing the date and time of when the link was visited.
    #
    # Note: See _getTimestamp() for the corresponding date/time
    # format.
    links_ignored           => { },

    # This is a hashtable of fully qualified URLs
    # that all share a common *hostname*.  This hashtable should be
    # initially empty.  As the driver extracts and removes new URLs
    # off the 'links_to_visit' hashtable, driving the browser to each URL,
    # any *relative* links found are added into this hashtable; any
    # *external* links found are added back into the 'links_to_visit'
    # hashtable.
    #
    # When navigating to the next link, this hashtable is exhausted prior
    # to the main 'links_to_visit' hashtable.  This allows a
    # browser to navigate to all links hosted on the same server, prior
    # to contacting a different server.
    #
    # Specifically, the 'key' is the absolute URL and the 'value'
    # is always 1.
    relative_links_to_visit => { },

    # This is a scalar that contains the next URL to visit.
    # It is updated dynamically, any time getNextLink() is called.
    # When the browser is ready to drive to the next link,
    # 'next_link_to_visit' is checked.  If that value is undef, then
    # the 'relative_links_to_visit' hashtable is checked next.
    # If that hashtable is empty, then finally the 'links_to_visit'
    # hashtable is checked.
    next_link_to_visit      => undef,

    # This is a hashtable of URLs that the browser has found
    # during its traversal process, but the browser could not
    # access the resource due to the operation timing out.
    #
    # The 'key' is the absolute URL and the 'value' is a string
    # representing the date and time of when the link was visited.
    #
    # Note: See _getTimestamp() for the corresponding date/time
    # format.
    links_timed_out         => { },

    # If this parameter is a defined scalar, then the browser
    # will also never attempt to revisit any links that caused
    # the browser to time out.
    ignore_links_timed_out  => getVar(name => "ignore_links_timed_out"),

    # A string containing the process name of the browser application,
    # as it appears in the Task Manager.
    process_name            => getVar(name => "process_name"),

    # An integer, representing how many relative links the browser
    # should continue to drive to, before moving onto another
    # website.  If negative, then the browser will exhaust all possible
    # relative links, before moving on.  (This internal variable should
    # never be modified externally.)
    _remaining_number_of_relative_links_to_visit => getVar(name => "max_relative_links_to_visit"),

    # An integer, representing the maximum number of relative links that
    # the browser should visit, before moving onto another website.  If
    # negative, then the browser will exhaust all possible relative links
    # found, before moving on.  This functionality is best effort; it's
    # possible for the browser to visit new links on previously visited
    # websites.
    max_relative_links_to_visit => getVar(name => "max_relative_links_to_visit"),

    # An array of positive words, where a link's probability of being
    # visited (its score) will increase, if the link contains any of these
    # words.
    positive_words => getVar(name => "positive_words")->{word},

    # An array of negative words, where a link's probability of being
    # visited (its score) will decrease, if the link contains any of these
    # words.
    negative_words => getVar(name => "negative_words")->{word},

    # If set to 1, then the code will attempt to parse and extract links
    # within active content (e.g., Flash animations).  Otherwise, the
    # code will ignore all active content. 
    parse_active_content => getVar(name      => "enable",
                                   namespace => "HoneyClient::Agent::Driver::ActiveContent"),
);

#######################################################################
# Private Methods Implemented                                         #
#######################################################################

# Helper function designed to retrieve the next link for the browser
# to navigate to.
#
# Note: Calling this function will implicitly remove the next link from
#       any and all applicable hashtables/scalars.
#
# When getting the next link, 'next_link_to_visit' is checked first.
# If that value is undef, then the 'relative_links_to_visit' hashtable
# is checked next.  If that hashtable is empty, then finally the
# 'links_to_visit' hashtable is checked.
#
# Inputs: HoneyClient::Agent::Driver::Browser object
# Outputs: link, or undef if all applicable scalars/hashtables are empty
sub _getNextLink {

    # Get the object state.
    my $self = shift;

    # Set the link to find as undef, initially.
    # We use undef to signify that our URL *_links_to_visit hashtables
    # are empty.  If we were to use the empty string instead, as our
    # signal, then this code would misinterpret an empty link
    # <a href=""></a> as a signal that our URL hashtables were empty.
    my $link = undef;

    while (!defined($link) or ($link eq "")) {
        # Try getting the next link from the next link
        # scalar.
        $link = $self->next_link_to_visit;
        $self->{next_link_to_visit} = undef;

        # If the next link scalar is empty, try
        # getting a link from the relative hashtable.
        unless (defined($link)) {
            $link = _pop($self->relative_links_to_visit);
        }

        # If the relative hashtable is empty, try getting one
        # from the external hashtable.
        unless (defined($link)) {
            $link = _pop($self->links_to_visit);
        }

        # If all hashtables/scalars were empty, immediately return an
        # undef value.
        unless (defined($link)) {
            return $link;
        }

        # Now, make sure the link is valid, before we return
        # it; if it's not valid, we simply move on to the next
        # one in our hashtables.  Invalid links will cause this
        # function to return an empty string.
        $link = $self->_validateLink($link);
    }

    # Return the next link found.
    return $link;
}

# Helper function designed to get a current timestamp from
# the system OS.
#
# Note: This timestamp is in ISO 8601 format.
#
# Inputs: none
# Outputs: timestamp
sub _getTimestamp {
    my $dt = DateTime::HiRes->now();
    return $dt->ymd('-') . " " .
           $dt->hms(':') . "." .
           $dt->nanosecond();
}

# Helper function designed to "pop" a key off a given hashtable.
# When given a hashtable reference, this function will extract a valid key
# from the hashtable and delete the (key, value) pair from the
# hashtable.  The link with the highest score is returned.
#
# Inputs: hashref
# Outputs: valid key, or undef if the hash is empty
sub _pop {

    # Get supplied hash reference.
    my $hash = shift;

    # Get the highest score.
    my @array = sort {$$hash{$b} <=> $$hash{$a}} keys %{$hash};
    my $topkey = $array[0];

    # Delete the key from the hashtable.
    if (defined($topkey)) {
        delete $hash->{$topkey};
    }

    # Return the key found.
    return $topkey;
}

# Helper function, designed to extract the hostname
# (and, if it exists, the port number) from a given
# URL.
#
# For example, if "http://hostname.com:8080/path/index.html"
# is given, then "hostname:8080" would be returned.
#
# Inputs: URL
# Outputs: hostname[:port]
sub _extractHostname {

    # Sanity check.
    my $arg = shift();

    if (!defined($arg)) {
        return "";
    }

    # Get the hostname supplied.
    return URI::URL->new($arg)->authority();
}

# Helper function, designed to process all links found at a
# given URL, once the browser has been driven to that URL
# and has collected all corresponding links.  The links are
# sorted in increasing order as determined by their score.
#
# When supplied with the array of URL strings,
# this function will categorize the corresponding URLs
# as follows:
#
# (Note: The terms "valid" and "invalid" are defined in
#  the _validateLink() documentation.)
#
# "New" links are those we've never driven the browser to.
# "Old" links are those we've driven the browser to before.
#
# - If a link is new and "invalid", then it gets added to
#   the 'links_ignored' hashtable.
#
# - If a link is old and "invalid", then it gets
#   ignored.
#
# - If a link is old and "valid", then it gets ignored.
#
# - If a link is new and "valid", then we check to see if
#   the referring URL's hostname[:port] and the link's
#   hostname[:port] match.  If they match, then the link
#   is added to the 'relative_links_to_visit' hash.
#   Otherwise, the link is added to the 'links_to_visit'
#   hash.
#
# Inputs: HoneyClient::Agent::Driver::Browser object,
#         hostname[:port] of referring URL,
#         hash of URL strings and scores, the url is the key
# Outputs: HoneyClient::Agent::Driver::Browser object
sub _processLinks {

    # Get the object state.
    my $self = shift;

    # Get the referrer and the corresponding arrays of links and scores.
    my ($referrer, %links) = @_;

    foreach my $url (keys %links) {
        my $score = $links{$url};

        # Skip over any undefined links.
        unless (defined($url)) {
            next;
        }

        # Validate each link.
        $url = $self->_validateLink($url);

        if (!defined($url) or ($url eq "")) {
            # If we get here, then the link is either invalid or
            # already visited.  In either case, skip to the next
            # link.
            next;
        }

        # Link is new and valid; go ahead and add to the appropriate
        # hashtable.

        # Extract the core hostname of the URL to visit.
        # If $url is undef, then this function will return an empty string.
        my $hostname = _extractHostname($url);

        # If the referrer's hostname and the URL's hostname match...
        if ($hostname eq $referrer) {
            # Then add the URL to the 'relative_links_to_visit' hashtable,
            # since we're visiting links that share the same hostname.
            $self->relative_links_to_visit->{$url} = $score;
        } else {
            # Else, add the URL to the 'links_to_visit' hashtable,
            # since we're visiting links that do NOT share the same hostname.
            $self->links_to_visit->{$url} = $score;
        }
    }

    # Return the modified object state.
    return $self;
}

# Helper function designed to validate supplied links.
#
# When a link is provided as an argument:
#
#  - The link is checked to make sure it has a valid
#    HTTP or HTTPS prefix in the URL; any other link
#    types are considered invalid.
#
#  - The 'links_visited' history is checked; if the link
#    already exists within the history, then it is considered
#    invalid.
#
# If the link is valid, then it is returned.  Otherwise, undef
# is returned for all invalid links.  Also, all invalid links
# are added to the 'links_ignored' history -- if they're not
# already in the hashtable.
#
# Inputs: HoneyClient::Agent::Driver::Browser object, url to validate
# Outputs: url if valid, empty string if invalid
sub _validateLink {

    # Get the object state.
    my $self = shift;

    # Get the supplied link.
    my ($link) = @_;

    # Strip off all anchors/fragments/bookmarks from within URLs by default.
    # Note: RFC 3986 Section 3 guarantees that all fragments
    # appear at the end of any URL.  Keep in mind, that this stripping
    # assumes we won't have any wierd corner cases, like:
    # http://www.mitre.org/path/index.html#bookmark?arg=value
    # ... where we would want to strip the bookmark, but keep the
    # arg=value piece (which may not be a valid URL syntax, anyway).
    my $url = URI::URL->new($link);
    $url->fragment(undef);
    # XXX: Do we need to clear the query() part, also?
    $link = $url->canonical()->as_string();

    # First, check to see if the link is either an
    # "http://" or "https://" URL.
    unless (is_uri($link) && is_web_uri($link)) {

        # The link is invalid, so we check to see if it's already
        # in our 'links_ignored' history.

        # Check if the 'links_ignored' history is not empty and
        # already has our invalid link recorded.
        unless (scalar(%{$self->links_ignored}) and
                exists($self->links_ignored->{$link})) {

            # The invalid link is brand new; add it to our list.
            $self->links_ignored->{$link} = _getTimestamp();
        }

        # The link is invalid, return an empty string.
        return "";
    }

    # Next, we check to see if we've already visited or ignored this
    # link.  Check if the 'links_visited' and 'links_ignored' histories
    # are not empty and does not already have this valid link recorded.
    if ((scalar(%{$self->links_visited}) and
         exists($self->links_visited->{$link})) or
        (scalar(%{$self->links_ignored}) and
         exists($self->links_ignored->{$link}))) {

        # Link is valid but already visited, so return undef.
        return;
    }

    # If we haven't returned by now, then the link is considered
    # valid and we need to visit it.
    return $link;
}

# XXX: Is this really needed?
# Helper function designed to kill all instances of the driven
# application.
#
# Inputs: None
# Outputs: None
sub _killProcess {

    # Get the object state.
    my $self = shift;

    # TODO: Make this more robust.

    # This function will croak, if it ever tries to return an undefined
    # object.
    my $stub = getClientHandle(address   => 'localhost',
                               namespace => 'HoneyClient::Agent');

    my $som = $stub->killProcess($self->process_name);

    if (!$som->result) {
        $LOG->warn("Failed to kill process: '" . $self->process_name . "'!");
        Carp::carp "Failed to kill process: '" . $self->process_name . "'!\n";
    }
}

#######################################################################
# Public Methods Implemented                                          #
#######################################################################

=pod

=head1 METHODS IMPLEMENTED

The following functions have been implemented by the Browser driver.  Many
of these methods were implementations of the parent Driver interface.

As such, the following code descriptions pertain to this particular
Driver implementation.  For further information about the generic
Driver interface, see the L<HoneyClient::Agent::Driver> documentation.

=head2 HoneyClient::Agent::Driver::Browser->new($param => $value, ...)

=over 4

Creates a new Browser driver object, which contains a hashtable
containing any of the supplied "param => value" arguments.

I<Inputs>:
 B<$param> is an optional parameter variable.
 B<$value> is $param's corresponding value.

Note: If any $param(s) are supplied, then an equal number of
corresponding $value(s) B<must> also be specified.

I<Output>: The instantiated Browser driver B<$object>, fully initialized.

=back

=begin testing

# XXX: Add this.
1;

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
    my %params = %{dclone(\%PARAMS)};
    $self = $class->SUPER::new();
    @{$self}{keys %params} = values %params;

    # Now, overwrite any default parameters that were redefined
    # in the supplied arguments.
    @{$self}{keys %args} = values %args;

    # Now, assign our object the appropriate namespace.
    bless $self, $class;

    # Initialize any internal state variables.
    # Reinitialize '_remaining_number_of_relative_links_to_visit', in case
    # 'max_relative_links_to_visit' was overloaded.
    $self->{_remaining_number_of_relative_links_to_visit} =
        $self->{max_relative_links_to_visit};

    # Finally, return the blessed object.
    return $self;
}

=pod

=head2 $object->drive(url => $url)

=over 4

Drives an instance of the browser for one iteration,
navigating to the next URL and updating the driver's corresponding
internal hashtables accordingly.

For a description of which hashtable is consulted upon each
iteration of drive(), see the L<next_link_to_visit> documentation, in
the "DEFAULT PARAMETER LIST" section.

Once a drive() iteration has completed, the corresponding browser process
is terminated.  Thus, each call to drive() invokes a new instance of the
browser.

I<Inputs>:
 B<$url> is an optional argument, specifying the next immediate URL the browser must drive to.

I<Output>: The updated Browser driver B<$object>, containing state information
from driving the browser for one iteration.

B<Warning>: This method will B<croak> if the Browser driver object is B<unable>
to navigate to a new link, because its list of links to visit is empty and
no new URL was supplied.

=back

=begin testing

# XXX: Test this.
1;

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

    # Sanity check: Make sure our next URL is defined.
    unless (defined($args{'url'})) {
        $LOG->error("Error: Unable to drive browser - no links left to browse!");
        Carp::croak "Error: Unable to drive browser - no links left to browse!\n";
    }

    # Indicates how long we wait for each drive operation to complete,
    # before registering attempt as a failure.
    my $timeout : shared = $self->timeout();

    # Use LWP::UserAgent to get the desired $args{'url'} and associated content
    # TODO: Analyze all the options LWP::UserAgent provides, in case we've
    # missed something useful.
    # Create a new user agent.
    my $ua = LWP::UserAgent->new(
        timeout           => $timeout,            # Fixed timeout.
        #max_redirect      => 0,                   # Ignore redirects.
        protocols_allowed => [ 'http', 'https' ], # Allow only web protocols.
        max_size          => 1*1024*1024,         # Don't get larger than 1MB for testing
    );

    # TODO: Look at the content type "text/html" on the response, to make this
    # a little better.
    # TODO: Set the default headers, to mimic a regular browser (if need be).
    # I'm thinking this could be set by IE/FF and passed via $args{'default_headers'}
    # as a HTTP::Headers object.
    $ua->default_header( 'Accept' => 'text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,application/x-shockwave-flash,*/*;q=0.5' );

    my $response = $ua->request(
                        HTTP::Request->new(
                            GET => $args{'url'},
                            HTTP::Headers->new(
                                # TODO: Add custom headers here?
                                'Accept' => 'text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,application/x-shockwave-flash,*/*;q=0.5',
                            ),
                        )
    );
 
    # Get the base url from the response
    my $base = $response->base;
    my $content = $response->content;
    my $type = $response->header('Content-Type');

    # Get the current time.
    my $timestamp = _getTimestamp();

    # Score the new links based on their surrounding HTML context.
    # If %scored_links is empty upon return, there are no links
    # and we will not perform any of the following code.
    my %scored_links;
    if ($content) {

        # TODO: Need to call ActiveContent::isActiveContent() function.
        # Check to see if the content is Flash-based.
        if (($type eq "application/x-shockwave-flash") &&
            ($self->{parse_active_content})) {

            # Save content to a temp file on disk.
            my $tempFile = new File::Temp(SUFFIX => '.swf');
            print $tempFile $content;
            $tempFile->close();

            %scored_links = HoneyClient::Agent::Driver::ActiveContent::process(
                                file => $tempFile,
                                url  => $args{'url'},
                            );

        # Assume that all other content types are HTML-based.
        } else {
            # Call the link scoring function
            %scored_links = $self->_scoreLinks($base, $content);
        }
    }

    # Check to see if the request timed out.
    # TODO: Need better error detection.
    if (!%scored_links) {
        $self->links_timed_out->{$args{'url'}} = $timestamp;

        # If we ignore any timed out links, then add them to our ignore
        # history as well.
        if ($self->ignore_links_timed_out) {
            $self->links_ignored->{$args{'url'}} = $timestamp;
        }
    } else {
        # If we've gotten this far, then we've successfully visited the URL.
        # Go ahead and add it to our 'links_visited' history.
        $self->links_visited->{$args{'url'}} = $timestamp;

        # Add all links found on this page to our sorted queues.
        # This function modifies the $self object internally and its
        # returned content does not need to be checked.
        $self->_processLinks(_extractHostname($args{'url'}), %scored_links);
    }
    
    # Check our internal relative links counter.
    if ($self->_remaining_number_of_relative_links_to_visit == 1) {

        # XXX: Do we need this message in here?
        $LOG->info("Resetting relative links to visit counter.");

        # The counter has reached one, so drop all other relative links
        # found, to force the driver to go to a new website.
        $self->{relative_links_to_visit} = { };

        # Reset the counter.
        $self->{_remaining_number_of_relative_links_to_visit} =
            $self->max_relative_links_to_visit;
    } elsif ($self->_remaining_number_of_relative_links_to_visit > 1) {

        # The counter is positive, so decrement it.
        $self->{_remaining_number_of_relative_links_to_visit}--;
    }

    # Return the modified object state.
    return $self;
}

=pod

=head2 $object->getNextLink()

=over 4

Returns the next URL that the browser will navigate to, upon the next
subsequent call to the B<$object>'s drive() method.

I<Output>: The next URL that the browser will be driven to.  The returned
data may be undef, if the Browser driver is finished and there are no links
left to navigate to.

B<Note>: This function is B<deprecated>.  $object->next() should be used
instead.

=back

=begin testing

# XXX: Test this.
1;

=end testing

=cut

sub getNextLink {

    # Get the object state.
    my $self = shift;

    # Sanity check: Make sure we've been fed an object.
    unless (ref($self)) {
        $LOG->error("Error: Function must be called in reference to a " .
                    __PACKAGE__ . "->new() object!");
        Carp::croak "Error: Function must be called in reference to a " .
                    __PACKAGE__ . "->new() object!\n";
    }

    # Set the link to find as undef, initially.
    my $link = undef;

    # Get the next link.
    $link = $self->_getNextLink();

    # Before returning the link, be sure to set the
    # next link scalar, so that our object consistently
    # returns the same next link via getNextLink().
    $self->{next_link_to_visit} = $link;

    # Return this link found.
    return $link;
}

=pod

=head2 $object->next()

=over 4

Returns the next set of server hostnames and/or IP addresses that the
browser will contact, upon the next subsequent call to the B<$object>'s
drive() method.

Specifically, the returned data is a reference to a hashtable, containing
detailed information about which resources, hostnames, IPs, protocols, and
ports that the browser will contact upon the next drive() iteration.

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

B<Note>: For this implementation of the Driver interface,
unless getNextLink() returns undef, the returned hashtable
from this method will B<always> contain only B<one> hostname
or IP address.  Within this single entry, the protocol type
is B<always guaranteed> to be B<TCP>, specifying a
B<single port>.

I<Output>: The aforementioned B<$hashref> containing the next set of
resources that the back-end application will attempt to contact upon
the next drive() iteration.  Returns undef values for both 'targets'
and 'resources' keys, if getNextLink() also returns undef.

# XXX: Resolve this, per parent Driver description.

=back

=begin testing

# XXX: Test this.
1;

=end testing

=cut

sub next {
    # Get the object state.
    my $self = shift;

    # Sanity check: Make sure we've been fed an object.
    unless (ref($self)) {
        $LOG->error("Error: Function must be called in reference to a " .
                    __PACKAGE__ . "->new() object!");
        Carp::croak "Error: Function must be called in reference to a " .
                    __PACKAGE__ . "->new() object!\n";
    }

    # Okay, get the next URL.
    my $nextURL = $self->getNextLink();

    # First, construct an empty hashtable.
    my $nextSite = {
        targets => undef,
        resources => undef,
    };

    # Sanity check: Make sure our next URL is defined.
    unless(defined($nextURL)) {
        return $nextSite;
    }

    # Now, extract the corresponding hostname[:port]
    my $hostnamePort = _extractHostname($nextURL);

    # Now, find the corresponding hostname or IP address.
    my $hostname = $hostnamePort;
    $hostname =~ s/:.*$//;

    # Check to see if a TCP port number was provided.
    my $port = $hostnamePort;
    $port =~ s/$hostname:?//;

    # If the port was empty, then derive the proper port number
    # to use, based upon whether HTTP or HTTPS was supplied by
    # the URL.
    if ($port eq '') {
        if ($nextURL =~ /^https.*/i) {
            $port = 443;
        } else { # Assume HTTP, since it's a valid URL.
            $port = 80;
        }
    }

    # Finally, construct the corresponding hash reference.
    $nextSite = {
        targets => {
            $hostname => {
                tcp => [ $port ],
            },
        },
        resources => {
            $nextURL => 1,
        },
    };

    return $nextSite;
}

=pod

=head2 _scoreLinks()

=over 4

The _scoreLinks helper function takes a scalar which is the base url for
the web page, a scalar which holds the content of the page (HTML), and a
hash which contain the good and bad words.

This function will calculate the "popularity" scores of the links.
The function returns a hash which is keyed on the _absolute_ url
and contains the value of the score.

I<Output>: The populated %scored_links hash if the page is not empty. An empty
hash otherwise.

For example, if your raw HTML content is $content, and the base url is
$base you would use the following call to this function.

if ($content) {
    # Call the link scoring function
    %scored_links = $self->_scoreLinks($base, $content);
}

=back

=begin testing

# XXX: Test this.
1;

=end testing

=cut

sub _scoreLinks {
    # Extract arguments.
    my ($self, $base, $content) = @_;
    my %links = ();
    my $url = undef;

    # If the page is blank, there is no point trying to parse it
    if (!$content) {
        return %links;
    }

    # Begin to scour the HTML content for tags, parsing attributes and text.
    # Find any tags which could potentially have URLs of interest, either for
    # scoring or for punching corresponding holes in the firewall.

    # Create a new parser.
    my $parser = HTML::TokeParser->new(\$content);

    # Don't try to textify anything.
    $parser->{textify} = { };

    # List of HTML tags to look for.
    # TODO: Expose this list to the global configuration file.
    # TODO: Make sure all entries are lowercase.
    my $tags = {
        'iframe' => 1,
        'a'      => 1,
        'link'   => 1,
        'img'    => 1,
        'object' => 1,
        'embed'  => 1,
        'script' => 1,
    };

    # List of HTML attributes to look for.
    # TODO: Expose this list to the global configuration file.
    # TODO: Make sure all entries are lowercase.
    my $attrs = {
        'href'    => 1,
        'src'     => 1,
        'usemap'  => 1,
        'classid' => 1,
        'data'    => 1,
    };

    # Helper stack (an array), used to determine the URL of the
    # currently encapsulated <A></A> block.
    my @link_stack = ();

    while (my $token = $parser->get_token()) {

        # The type of tag found ("S" = starting, "E" = ending).
        my $tag_type = $token->[0];

        # The tag name found.
        my $tag = $token->[1];

        # The hashtable of attributes found in this tag.
        my $attrib_hash = $token->[2];

        # We're only interested in the start and end HTML tags.
        # Ignore all others.
        unless (($tag_type eq "S") || ($tag_type eq "E")) {
            next; 
        }

        # We're only interested in the specified HTML tags.
        # Ignore all others.
        unless (exists($tags->{$tag})) {
            next;
        }

        # Check if we have an ending tag.
        if ($tag_type eq "E") {

            # If it's an ending </A> tag, then pop the last
            # url off the link_stack.
            if ($tag eq "a") {
                pop(@link_stack);
            }

            # Don't bother parsing ending tags any further.
            next;
        }

        # We only pay attention to starting <IMG> tags, if we're inside
        # a nested link.
        if (($tag eq "img") && (scalar(@link_stack) <= 0)) {
            next;
        }

        # Set the score to zero.
        my $score = 0;

        # Try to extract any possible URL from any attribute.
        # Stop when we first encounter one.
        my $counter = 0;
        my @attrs_list = keys(%{$attrs});
        while (!defined($url) && ($counter < scalar(@attrs_list))) {
            if (exists($attrib_hash->{$attrs_list[$counter]})) {
                $url = $attrib_hash->{$attrs_list[$counter]};
            }
            $counter++;
        }

        # If it's a starting <A> tag, then push the URL onto the
        # link_stack.
        # Also, don't increment, when tag is atomic, like:
        #     <a href="http://www.foo.com" />
        if (($tag_type eq "S") && ($tag eq "a") &&
            !exists($attrib_hash->{'/'})) {
            push(@link_stack, $url);
        }

        # Skip if no URL was found.
        unless (defined($url)) {
            next;
        }

        # TODO: Expose these values as global options.
        # Some programmatic values
        my $min_text_length = 6;
        my $max_text_length = 20;
        my $image_bonus = 50;
        my $default_display_size = 1024 * 768;
        my $word_value = 6;

        # We have to make this an absolute url (if it's not)
        # before using it as a key in the %links hash.
        $url = url($url, $base)->abs;

        # Begin scoring the link based on surrounding context
        # This can be improved/customized in many different ways.
        # Our implementation is only one possible way to assign
        # values to the context elements.

        my $width = undef;
        my $height = undef;

        # Score the size of an object/image based on width and height.
        if (exists($attrib_hash->{width})) {
            $width = int($attrib_hash->{width});
        }
        if (exists($attrib_hash->{height})) {
            $height = int($attrib_hash->{height});
        }
        if (defined($width) && defined($height)) {
            $score += int(($width*$height)/($default_display_size)*100);
        } elsif (defined($width)) {
            $score += int($width/10);
        } elsif (defined($height)) {
            $score += int($height/10);
        }

        # Extract any link text.
        my $text = $parser->get_trimmed_text();

        # Score length of link text. These are arbitrary lengths, but
        # the reasoning is that really short text links are not too
        # visible (we are excluding image links from this criteria),
        # and really long text would be weird or abnormal to the human
        # web surfer.
        if (($tag ne "img") &&
            (length($text) > $min_text_length) &&
            (length($text) < $max_text_length)) {
            $score += length($text);
        }

        # Score the image content, if it exists
        # We score the size proportional to a 1024 X 768 display
        # Image bonus
        if ($tag eq "img") {
            $score += $image_bonus;
        }

        # Good word bonus
        foreach (@{$self->{'positive_words'}}) {
            if ($text =~ /$_/i) {
                $score += $word_value;
            }
        }

        # Bad word penalty
        foreach (@{$self->{'negative_words'}}) {
            if ($text =~ /$_/i) {
                $score -= $word_value;
            }
        }

        # Put it in the return value hash and zero the score.
        $links{$url} = $score;

        # If we're dealing with an <IMG> tag, then we must
        # be within a <A></A> tag block.  If so, then our
        # score should also modify the value of the previously
        # found <A HREF="this link">.

        # Get the enclosed link's URL.
        if (($tag eq "img") && (scalar(@link_stack) > 0)) {
            my $parent_url = $link_stack[-1];
            # If defined, then adjust the parent URL's score, too.
            if (defined($parent_url)) {
                $links{$parent_url} += $score;
            }
        }

        $url = undef;
    }

    return %links;
}

=pod

=head2 $object->isFinished()

=over 4

Indicates if the Browser driver B<$object> has driven the browser
process to all possible links it has found within its hashtables
and is unable to navigate the browser further without additional, external
input.

I<Output>: True if the Browser driver B<$object> is finished, false otherwise.

B<Note>: Additional links can be fed to this Browser driver at any time, by
simply adding new hashtable entries to the B<links_to_visit> hashtable
within the B<$object>.

For example, if you wanted to add the URL "http://www.mitre.org"
to the Browser driver B<$object>, simply use the following code:

  $object->{links_to_visit}->{'http://www.mitre.org'} = 1;

=back

=begin testing

# XXX: Test this.
1;

=end testing

=cut

sub isFinished {

    # Get the object state.
    my $self = shift;

    # Sanity check: Make sure we've been fed an object.
    unless (ref($self)) {
        $LOG->error("Error: Function must be called in reference to a " .
                    __PACKAGE__ . "->new() object!");
        Carp::croak "Error: Function must be called in reference to a " .
                    __PACKAGE__ . "->new() object!\n";
    }

    # Return whether or not all '*_to_visit' variables/hashtables are
    # empty.
    return (!(defined($self->next_link_to_visit) or
              scalar(%{$self->relative_links_to_visit}) or
              scalar(%{$self->links_to_visit})))

}

=pod

=head2 $object->status()

=over 4

Returns the current status of the Browser driver B<$object>, as it's state
exists, between subsequent calls to $object->driver().

Specifically, the data returned is a reference to a hashtable,
containing specific statistical information about the status
of the Browser driver's progress, between iterations of driving the
browser process.

The following is an example hashtable, containing all the
(key => value) pairs that would exist in the output.

  $hashref = {
      'relative_links_remaining' =>       10, # Number of URLs left to
                                              # process, at a given site.
      'links_remaining'          =>       56, # Number of URLs left to
                                              # process, for all sites.
      'links_processed'          =>       44, # Number of URLs processed.
      'links_total'              =>      100, # Total number of URLs given.
      'percent_complete'         => '44.00%', # Percent complete,
                                              #  (processed / total).
  };

I<Output>: A corresponding B<$hashref>, containing statistical information
about the Browser driver's progress, as previously mentioned.

# XXX: Resolve this, per parent Driver description.

=back

=begin testing

# XXX: Test this.
1;

=end testing

=cut

sub status {

    # Get the object state.
    my $self = shift;

    # Sanity check: Make sure we've been fed an object.
    unless (ref($self)) {
        $LOG->error("Error: Function must be called in reference to a " .
                    __PACKAGE__ . "->new() object!");
        Carp::croak "Error: Function must be called in reference to a " .
                    __PACKAGE__ . "->new() object!\n";
    }

    # Construct a new status hashtable.
    my $status = { };

    # Set the total number of links processed.
    $status->{links_processed} = scalar(keys(%{$self->links_visited})) +
                                 scalar(keys(%{$self->links_timed_out})) +
                                 scalar(keys(%{$self->links_ignored}));

    # Figure out if the next_link_to_visit is set.
    my $next_link_is_set = 0;
    if (defined($self->next_link_to_visit)) {
        $next_link_is_set = 1;
    }

    # Set the number of relative links to process.
    $status->{relative_links_remaining} = scalar(keys(%{$self->relative_links_to_visit})) +
                                          $next_link_is_set;

    # Figure out how many total links are left to process.
    $status->{links_remaining} = $status->{relative_links_remaining} +
                                 scalar(keys(%{$self->links_to_visit}));
 
    # Set the total number of links in the object's state.
    $status->{links_total} = $status->{links_processed} +
                             $status->{links_remaining};

    # Get the percentage of links complete.
    # Sanity check: Avoid divide by zero.
    if ($status->{links_total} <= 0) {
        $status->{links_total} = 1;
    }
    $status->{percent_complete} = sprintf("%.2f%%", (($status->{links_processed} + 0.00) /
                                                     ($status->{links_total} + 0.00)) * 100.00);

    # Return status.
    return $status;
}

#######################################################################

1;

#######################################################################
# Additional Module Documentation                                     #
#######################################################################

__END__

=head1 BUGS & ASSUMPTIONS

In a nutshell, this object is nothing more than a blessed anonymous
reference to a hashtable, where (key => value) pairs are defined in
the L<DEFAULT PARAMETER LIST>, as well as fed via the new() function
during object initialization.  As such, this package does B<not>
perform any rigorous B<data validation> prior to accepting any new
or overriding (key => value) pairs.

However, additional links can be fed to any Browser driver at any time, by
simply adding new hashtable entries to the B<links_to_visit> hashtable
within the B<$object>.

For example, if you wanted to add the URL "http://www.mitre.org"
to the Browser driver B<$object>, simply use the following code:

  $object->{links_to_visit}->{'http://www.mitre.org'} = 1;

In general, the Browser driver does B<not> know how many links it will
ultimately end up browsing to, until it conducts an exhaustive
spider of all initial URLs supplied.  As such, expect the output
of $object->status() to change significantly, upon each
$object->drive() iteration.

For example, if at one given point, the status of B<percent_complete>
is 30% and then this value drops to 15% upon another iteration, then
this means that the total number of links to drive to has greatly
increased.

Lastly, we assume the driven browser has been preconfigured to
B<not cache any data>.  This ensures the browser will render the most
recent version of the content hosted at each URL.

=head1 SEE ALSO

L<HoneyClient::Agent::Driver>

L<HoneyClient::Agent::Driver::Browser::IE>

L<HoneyClient::Agent::Driver::Browser::FF>

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
