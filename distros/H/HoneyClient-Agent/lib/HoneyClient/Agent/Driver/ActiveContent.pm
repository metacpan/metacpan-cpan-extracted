#######################################################################
# Created on:  December 14, 2006
# Package:     HoneyClient::Agent::Driver::ActiveContent
# File:        ActiveContent.pm
# Description: A driver for handling various forms of
#              active content found in web pages.  Calls
#              the appropriate handler based on the type
#              of content that was input, and returns a
#              list of URLs that were contained within
#              the content.
#
# CVS: $Id: ActiveContent.pm 696 2007-07-19 02:21:10Z kindlund $
#
# @author jpuchalski
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

HoneyClient::Agent::Driver::ActiveContent - Perl module that extracts
information from various forms of active content, such as SWF Flash
movies.  Currently the information returned is a list of URLs that
were embedded in the active content.

=head1 VERSION

This documentation refers to HoneyClient::Agent::Driver::ActiveContent
version 0.1.

=head1 SYNOPSIS

  use HoneyClient::Agent::Driver::ActiveContent;



=head1 DESCRIPTION

=cut

package HoneyClient::Agent::Driver::ActiveContent;

use strict;
use warnings;
use Carp ();

#######################################################################
# Module Initialization                                               #
#######################################################################

BEGIN {
    require Exporter;
    our (@ISA, @EXPORT, @EXPORT_OK, $VERSION);

    # Set our package version.
    $VERSION = 0.1;

    @ISA = qw(Exporter HoneyClient::Agent::Driver);

    # Symbols to export by default
    @EXPORT = qw();

    # Items to export into callers namespace by default. Note: do not export
    # names by default without a very good reason. Use EXPORT_OK instead. 
    # Do not simply export all your public functions/methods/constants.
   
    # Symbols to export on request
    @EXPORT_OK = qw(process);
}
our (@EXPORT_OK, $VERSION);

#######################################################################

use Log::Log4perl qw(:easy);

# Include the Flash content processing module
use HoneyClient::Agent::Driver::ActiveContent::Flash qw(extract);

# Include Data Dumper API
use Data::Dumper;

our $LOG = get_logger();


#######################################################################
# Private Methods Implemented                                         #
#######################################################################

=pod

=head1 PRIVATE METHODS

None.

=cut

#######################################################################
# Public Methods Implemented                                          #
#######################################################################

=pod

=head1 PUBLIC METHODS

=head2 HoneyClient::Agent::Driver::ActiveContent->isActiveContent()

=over 4

Checks to see if a particular input file contains a type of active content
that we are interested in processing.

=back

=begin testing

# Do testing here

=end testing

=cut

sub isActiveContent {
    # Extract arguments.    
    my %args = @_;

    # Log resolved arguments.
    $LOG->debug(sub {
        # Make Dumper format more terse.
        $Data::Dumper::Terse = 1;
        $Data::Dumper::Indent = 0;
        Dumper(\%args);
    });

    # Make sure an input file is defined
    unless (defined($args{'file'})) {
        $LOG->fatal("No input file provided!");
        Carp::croak "Error: No input file provided!";
    }

    # Make sure a URL is defined
    unless (defined($args{'url'})) {
        $LOG->fatal("No URL provided!");
        Carp::croak "Error: No URL provided!";
    }

    return ($args{'file'}->filename =~ /\.swf$/);
}

=pod

=head2 HoneyClient::Agent::Driver::ActiveContent->process()

=over 4

Processes the given input file by calling the appropriate extraction
handler.

=back

=begin testing

# Do testing here

=end testing

=cut

sub process {
    # Extract arguments.    
    my %args = @_;

    # Log resolved arguments.
    $LOG->debug(sub {
        # Make Dumper format more terse.
        $Data::Dumper::Terse = 1;
        $Data::Dumper::Indent = 0;
        Dumper(\%args);
    });

    # Make sure an input file is defined
    unless (defined($args{'file'})) {
        $LOG->fatal("No input file provided!");
        Carp::croak "Error: No input file provided!";
    }

    # Make sure a base URL is defined
    unless (defined($args{'url'})) {
        $LOG->fatal("No URL provided!");
        Carp::croak "Error: No URL provided!";
    }

    # Pass the file to the appropriate content type module
    # Note: We need to account for URLs, where there's additional data
    # at the end of the file name.  Like, in the case of video.google.com:
    # http://video.google.com/googleplayer.swf?docid=....
    if ($args{'file'}->filename =~ /\.swf/) {
        return HoneyClient::Agent::Driver::ActiveContent::Flash::extract(%args);
    } else {
        Carp::croak "Error: Input file does not contain a known resource!\n";
    }
}

1;

=pod

=head1 AUTHORS

Jeff Puchalski, E<lt>jpuchalski@mitre.orgE<gt>

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
