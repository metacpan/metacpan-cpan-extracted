#######################################################################
# Created on:  December 14, 2006
# Package:     HoneyClient::Agent::Driver::ActiveContent::Flash
# File:        Flash.pm
# Description: An module used for extracting URLs from Adobe
#              Flash (SWF) movies.  If the URLs could not be
#              extracted, but the movie appears "interesting,"
#              then it is flagged for analyst review.
#
# CVS: $Id: Flash.pm 766 2007-07-26 02:46:00Z kindlund $
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

HoneyClient::Agent::Driver::ActiveContent::Flash - Perl module that 
extract URLs from Adobe Flash (SWF) movies.  Returns a list of URLs.

=head1 VERSION

This documentation refers to 
HoneyClient::Agent::Driver::ActiveContent::Flash version 0.1.

=head1 SYNOPSIS

  use HoneyClient::Agent::Driver::ActiveContent::Flash;



=head1 DESCRIPTION

=cut

package HoneyClient::Agent::Driver::ActiveContent::Flash;

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

    @ISA = qw(Exporter HoneyClient::Agent::Driver::ActiveContent);

    # Symbols to export by default
    @EXPORT = qw();

    # Items to export into callers namespace by default. Note: do not export
    # names by default without a very good reason. Use EXPORT_OK instead. 
    # Do not simply export all your public functions/methods/constants.
   
    # Symbols to export on request
    @EXPORT_OK = qw(extract);
}
our (@EXPORT_OK, $VERSION);

#######################################################################

# Include Global Configuration Processing Library
use HoneyClient::Util::Config qw(getVar);
use Log::Log4perl qw(:easy);

# Include the Global Configuration Processing Library
use HoneyClient::Util::Config qw(getVar);

# Include URL Parsing Library
use URI::URL;

# Include Data Dumper API
use Data::Dumper;

=pod

=head1 GLOBAL VARIABLES

=head2 flasm_exec

=over 4

Path to the flasm executable (default=./thirdparty/flasm/flasm.exe).

=back

=cut

# Path to the flasm executable.
our $flasm_exec = getVar(name => "flasm_exec");

# Our friendly local logger.
our $LOG = get_logger();

# This variable holds the base URL reference for the SWF movie
# we are currently processing.
our $base_url;


#######################################################################
# Private Methods Implemented                                         #
#######################################################################

=pod

=head1 PRIVATE METHODS

=head2 HoneyClient::Agent::Driver::ActiveContent::Flash->_addURL($url, $urls)

=over 4

Adds the specified URL to the hash of URLs to be returned.  Checks
to see if the URL is relative or absolute, and in the former case
appends the base URL appropriately.

=back

=cut

sub _addURL {
    # Extract arguments.    
    my ($url, $urls) = @_;

    # URL appears to be absolute, or a different protocol
    if ($url =~ /^mailto/ or
        $url =~ /^javascript/ or
        $url =~ /^http/) {
        $urls->{$url} = 1;
    }
    # URL appears to be relative, so add the base
    else {
        $url = url($url, $base_url)->abs;
        $urls->{$url} = 1;
    }
    return $urls;
}


#######################################################################
# Public Methods Implemented                                          #
#######################################################################

=pod

=head1 PUBLIC METHODS

=head2 HoneyClient::Agent::Driver::ActiveContent::Flash->extract()

=over 4

Extracts URLs from an Adobe Flash SWF movie file.  Takes in a file
name and a base URL, and uses the latter to construct relative URLs
to local links found in the movie.  Returns a hash containing the
found URLs as keys, and values of 1 for each of them, where the
values represent the weights used by the link ranking code.

=back

=begin testing

# Do testing here...
my $foo = HoneyClient::Something->blah(...);
dies_ok {$foo->dosomething()} 'dosomething()' or diag("The issomething() call failed.
  Expected dosomething() to throw an exception.");

=end testing

=cut

sub extract {
    # Extract arguments.    
    my %args = @_;

    # Log resolved arguments.
    $LOG->debug(sub {
        # Make Dumper format more terse.
        $Data::Dumper::Terse = 1;
        $Data::Dumper::Indent = 0;
        Dumper(\%args);
    });

    # Put all the relative URLs that were retrieved into a hash as
    # keys, but first turn them into full URLs.  Set the value for
    # each URL key to 1 (this is its score).
    my $urls = {};

    my $filename = $args{'file'}->filename;

    # Extract the base URL. 
    $base_url = URI::URL->new($args{'url'});
    $base_url = $base_url->canonical()->as_string();

    # Must encode all backslashes with double backslashes, since 
    # backtick commands don't like single backslashes.
    if ($^O =~ m/win/i || $ENV{'OS'} =~ m/win/i) {
        require Filesys::CygwinPaths;
        $filename = Filesys::CygwinPaths::fullwin32path($filename);
        $filename =~ s/\\/\\\\/g;
    }

    # Call flasm and store the output bytecode string in an array
    my $code = `$flasm_exec -d $filename`;

    # Check the return value on the flasm call that just happened.
    # We care if the return code was anything other than 0.
    if ($? >> 8) {
        my $signal = ($? & 127);
        $LOG->fatal("Call to flasm exited on signal $signal");
        Carp::croak "Error: Call to flasm exited on signal $signal";
    }

    # Strip out all control characters and place each line as
    # separate entry in an array.
    my @bytecode = split(/[[:cntrl:]]+/, $code);

    # Parse out lines that contain the getURL method (exclude any
    # getURL2 calls from this, as they need to be handled differently)
    my @geturl_calls = grep(/getURL /, @bytecode);

    # Each getURL line has getURL followed by the URL in single 
    # quotes.  Extract the URL, remove the single quotes, and store
    # the URL in a new array.
    my @found_urls;

    foreach (@geturl_calls) {
        $_ =~ s/^\s+//;
        my ($fun, $url) = split(/\s+/);
        $url =~ s/'//g;
        push @found_urls, $url;
    }

    foreach (@found_urls) {
        $urls = _addURL($_, $urls);
    }

    # We can exit here if there are no getURL2 calls
    unless (grep(/getURL2/, @bytecode)) {
        # TODO: Clean this up.
        # Sanity check on the URLs.
        foreach (sort(keys(%{$urls}))) {
            $LOG->info($_);
        }
  
        return %{$urls};
    }
 
    # If we made it here, then at least one getURL2 call was
    # detected.  Proceed with additional processing.
    $LOG->warn("Detected getURL2\n");

    # Before we forget, turn off unlink on destroy for our
    # temporary file handle, so the file is kept around for
    # analysts to look at later.
    $args{'file'}->unlink_on_destroy(0);

    # What we do next is some parsing on the flasm decompilation.
    # We are looking for getURL2 calls, and will then try to piece
    # together the URLs that go into them.
    my $i = 0;
 
    foreach (@bytecode) {
        # First, find a line containing a getURL2 call
        if ($_ =~ /getURL2/) {
            $LOG->info("Got a getURL2 on line " . ($i+1));

            my ($fun, $var, $val);
            my $instr;
            my $haveVar = 0;

            # Next, work backwards from the call.  We start from $i - 2 
            # here because the $i - 1 line always contains the URL's target
            # (e.g., '', '_parent', '_blank').
            for (my $j = $i - 2; $bytecode[$j] !~ /^\s+constants/; $j--) {
                # The first time through, look for a getVariable call, which
                # tells us what variable has the value of the URL.
                if (!$haveVar and $bytecode[$j] =~ /getVariable/) {
                    $LOG->info("Found getVariable on line " . ($j+1));
                    # The line before this one has the name of the
                    # variable that contains the URL
                    $instr = $bytecode[--$j];
                    $instr =~ s/^\s+//;
                    ($fun, $var) = split(/\s+/, $instr);
                    $LOG->info("Name of the URL variable is $var");
                    $haveVar = 1;
                } 
                # Once we have the URL variable, we can look back further
                # for the push call that sets its value.
                elsif ($haveVar and $bytecode[$j] =~ /^\s+push $var/) {
                    $instr = $bytecode[$j];
                    $instr =~ s/^\s+//;
                    ($var, $val) = split(/, /, $instr);
                    # Sanity check.
                    if (defined($val)) {
                        $val =~ s/\s+$//;
                        $LOG->info("Value of the URL is $val");
                        $val =~ s/'//g;
                        $urls = _addURL($val, $urls);
                    }
                    last;
                }
            }
        }

        $i++;
    }

    # TODO: Clean this up.
    # Sanity check on the URLs.
    foreach (sort(keys(%{$urls}))) {
        $LOG->info($_);
    }

    return %{$urls};
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
