#######################################################################
# Created on:  Dec 03, 2006
# Package:     HoneyClient::Agent::Integrity::Registry
# File:        Registry.pm
# Description: Performs static checks of the Windows OS registry.
#
# CVS: $Id: Registry.pm 773 2007-07-26 19:04:55Z kindlund $
#
# @author kindlund, xkovah
#
# Copyright (C) 1998 Memorial University of Newfoundland.
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

HoneyClient::Agent::Integrity::Registry - Perl extension to perform
static checks of the Windows OS registry.

=head1 VERSION

This documentation refers to HoneyClient::Agent::Integrity::Registry version 0.98.

=head1 SYNOPSIS

  use HoneyClient::Agent::Integrity::Registry;
  use Data::Dumper;

  # Create the registry object.  Upon creation, the object
  # will be initialized, by collecting a baseline of the registry.
  my $registry = HoneyClient::Agent::Integrity::Registry->new();

  # ... Some time elapses ... 

  # Check the registry, for any changes.
  my $changes = $registry->check();

  if (!defined($changes)) {
      print "No registry changes have occurred.\n";
  } else {
      print "Registry has changed:\n";
      print Dumper($changes);
  }

  # $changes refers to an array of hashtable references, where
  # each hashtable has the following format:
  #
  # $changes = [ {
  #     # The registry directory name.
  #     'key_name' => 'HKEY_LOCAL_MACHINE\Software...',
  #
  #     # Indicates if the registry directory was deleted (0),
  #     # added (1), or changed (2).
  #     'status' => 0 | 1 | 2,
  #
  #     # An array containing the list of entries within the
  #     # registry directory that have been deleted, added, or
  #     # changed.  If this array is empty, then the corresponding
  #     # registry directory in the original and new hives contained
  #     # no entries.
  #     'entries'  => [ {
  #         'name' => "\"string\"",  # A (potentially) quoted string; 
  #                                  # "@" for default
  #         'new_value' => "string", # New string; maybe undef, if deleted
  #         'old_value' => "string", # Old string; maybe undef, if added
  #     }, ],
  # }, ]

=head1 DESCRIPTION

This library allows the Integrity module to easily baseline and check
the Windows OS registry hives for any changes that may occur, while
instrumenting a target application.

This library uses modified code from the 'regutils' library by 
John Rochester and Michael Rendell. 
See L<http://www.cs.mun.ca/~michael/regutils/> for more information.

=cut

package HoneyClient::Agent::Integrity::Registry;

use strict;
use warnings;
use Carp ();

# Include Global Configuration Processing Library
use HoneyClient::Util::Config qw(getVar);

# Include Registry Parsing Library
use HoneyClient::Agent::Integrity::Registry::Parser;

# Use Dumper Library
use Data::Dumper;

# Use Storable Library
use Storable qw(dclone);

# Include Logging Library
use Log::Log4perl qw(:easy);

# Include File IO Libraries.
use IO::Handle;
use IO::File;
use Fcntl qw(:seek);

# Include Temporary File Libraries.
use File::Temp qw(tmpnam unlink0);

# Include Cygwin Path Conversion Library.
use Filesys::CygwinPaths qw(:all);

# Use Binary Search Library.
use Search::Binary;

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
    @EXPORT = qw( );

    # Items to export into callers namespace by default. Note: do not export
    # names by default without a very good reason. Use EXPORT_OK instead.
    # Do not simply export all your public functions/methods/constants.

    # This allows declaration use HoneyClient::Agent::Integrity::Registry ':all';
    # If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
    # will save memory.

    %EXPORT_TAGS = (
        'all' => [ qw( ) ],
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
BEGIN { use_ok('HoneyClient::Util::Config', qw(getVar setVar)) 
        or diag("Can't load HoneyClient::Util::Config package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('HoneyClient::Util::Config');
can_ok('HoneyClient::Util::Config', 'getVar');
can_ok('HoneyClient::Util::Config', 'setVar');
use HoneyClient::Util::Config qw(getVar setVar);

# Suppress all logging messages, since we need clean output for unit testing.
Log::Log4perl->init({
    "log4perl.rootLogger"                               => "DEBUG, Buffer",
    "log4perl.appender.Buffer"                          => "Log::Log4perl::Appender::TestBuffer",
    "log4perl.appender.Buffer.min_level"                => "fatal",
    "log4perl.appender.Buffer.layout"                   => "Log::Log4perl::Layout::PatternLayout",
    "log4perl.appender.Buffer.layout.ConversionPattern" => "%d{yyyy-MM-dd HH:mm:ss} %5p [%M] (%F:%L) - %m%n",
});

# Make sure Data::Dumper loads
BEGIN { use_ok('Data::Dumper')
        or diag("Can't load Data::Dumper package. Check to make sure the package library is correctly listed within the path."); }
require_ok('Data::Dumper');
use Data::Dumper;

# Make sure Storable loads
BEGIN { use_ok('Storable', qw(dclone))
        or diag("Can't load Storable package. Check to make sure the package library is correctly listed within the path."); }
require_ok('Storable');
can_ok('Storable', 'dclone');
use Storable qw(dclone);

# Make sure IO::Handle loads
BEGIN { use_ok('IO::Handle')
        or diag("Can't load IO::Handle package. Check to make sure the package library is correctly listed within the path."); }
require_ok('IO::Handle');
use IO::Handle;

# Make sure IO::File loads
BEGIN { use_ok('IO::File')
        or diag("Can't load IO::File package. Check to make sure the package library is correctly listed within the path."); }
require_ok('IO::File');
use IO::File;

# Make sure Fcntl loads
BEGIN { use_ok('Fcntl')
        or diag("Can't load Fcntl package. Check to make sure the package library is correctly listed within the path."); }
require_ok('Fcntl');
use Fcntl qw(:seek);

# Make sure File::Temp loads
BEGIN { use_ok('File::Temp')
        or diag("Can't load File::Temp package. Check to make sure the package library is correctly listed within the path."); }
require_ok('File::Temp');
can_ok('File::Temp', 'tmpnam');
can_ok('File::Temp', 'unlink0');
use File::Temp qw(tmpnam unlink0);

# Make sure Filesys::CygwinPaths loads
BEGIN { use_ok('Filesys::CygwinPaths')
        or diag("Can't load Filesys::CygwinPaths package. Check to make sure the package library is correctly listed within the path."); }
require_ok('Filesys::CygwinPaths');
use Filesys::CygwinPaths qw(:all);

# Make sure Search::Binary loads
BEGIN { use_ok('Search::Binary')
        or diag("Can't load Search::Binary package. Check to make sure the package library is correctly listed within the path."); }
require_ok('Search::Binary');
can_ok('Search::Binary', 'binary_search');
use Search::Binary;

# Make sure HoneyClient::Agent::Integrity::Registry::Parser loads
BEGIN { use_ok('HoneyClient::Agent::Integrity::Registry::Parser')
        or diag("Can't load HoneyClient::Agent::Integrity::Registry::Parser package. Check to make sure the package library is correctly listed within the path."); }
require_ok('HoneyClient::Agent::Integrity::Registry::Parser');
use HoneyClient::Agent::Integrity::Registry::Parser;

# Make sure HoneyClient::Agent::Integrity::Registry loads
BEGIN { use_ok('HoneyClient::Agent::Integrity::Registry')
        or diag("Can't load HoneyClient::Agent::Integrity::Registry package. Check to make sure the package library is correctly listed within the path."); }
require_ok('HoneyClient::Agent::Integrity::Registry');
use HoneyClient::Agent::Integrity::Registry;

# Make sure File::Basename loads.
BEGIN { use_ok('File::Basename', qw(dirname basename fileparse)) or diag("Can't load File::Basename package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('File::Basename');
can_ok('File::Basename', 'dirname');
can_ok('File::Basename', 'basename');
can_ok('File::Basename', 'fileparse');
use File::Basename qw(dirname basename fileparse);

=end testing

=cut

#######################################################################
# Global Configuration Variables
#######################################################################

# Registry Status Identifiers
our $STATUS_DELETED  = 0;
our $STATUS_ADDED    = 1;
our $STATUS_MODIFIED = 2;

# The global logging object.
our $LOG = get_logger();

# Make Dumper format more terse.
$Data::Dumper::Terse = 1;
$Data::Dumper::Indent = 0;

=pod

=head1 DEFAULT PARAMETER LIST

When a Registry B<$object> is instantiated using the B<new()> function,
the following parameters are supplied default values.  Each value
can be overridden by specifying the new (key => value) pair into the
B<new()> function, as arguments.

=head2 hives_to_check 

=over 4

This parameter indicates the default array of registry hive names
to monitor for changes.

=back

=head2 key_dirnames_to_ignore 

=over 4

This parameter indicates the default array of regular expressions
that each registry directory will be checked against.  Any matching
key directory names will be ignored and any subsequent additions,
deletions, or changes to all content in these matches will also
be ignored.

Each $entry will be used via the syntax /$entry/.  Thus,
it is recommended to specify the ^ prefix and $ suffix, when
possible.

A single backslash (\) must be represented using triple
backslashes (\\\) and each $entry must not end with any
backslash character.

=back

=head2 bypass_baseline 

=over 4

When set to 1, the object will forgo any type of initial baselining
process, upon initialization.  Otherwise, baselining will occur
as normal, upon initialization.

=back

=cut

my %PARAMS = (

    # An array, specifying which registry hives to
    # analyze.
    hives_to_check => getVar(name => 'hives_to_check')->{name}, 

    # An array of regular expressions that each registry directory
    # will be checked against.  Any matching key directory names will
    # be ignored and any subsequent additions, deletions, or changes
    # to all content in these matches will also be ignored.
    #
    # Each $entry will be used via the syntax /$entry/.  Thus,
    # it is recommended to specify the ^ prefix and $ suffix, when
    # possible.
    #
    # A single backslash (\) must be represented using triple
    # backslashes (\\\) and each $entry must not end with any
    # backslash character.
    key_dirnames_to_ignore => getVar(name => 'exclude_list')->{regex},

    # When set to 1, the object will forgo any type of initial baselining
    # process, upon initialization.  Otherwise, baselining will occur
    # as normal, upon initialization.
    bypass_baseline => 0,

    # Baseline File Collection
    # A hashtable of file parsers, one parser per hive name.
    # (For internal use only.)
    _baseline_parsers => { },

    # Checkpoint File Collection
    # A hashtable of file parsers, one parser per hive name.
    # (For internal use only.)
    _checkpoint_parsers => { }, 

    # A hashtable of current key info objects, where the hash key is the
    # file parser and the hash value is the info object.
    # (For internal use only.)
    _currentKeys => { },

    # A hashtable of counters, where each counter keeps track of
    # which entry was last read in from the current key.  The hash key
    # is the file parser, and the hash value is the entry counter.
    _currentEntryIndex => { },

    # A helper variable, used to keep track of the last search index,
    # used by the _search() function. 
    _last_search_index => undef,

    # A helper variable, used to set the array of known line numbers,
    # where each array entry is a line number, which separates a different
    # group block.    
    _group_index_linenums => [ ],
);

#######################################################################
# Private Methods Implemented                                         #
#######################################################################

# TODO: Move down to public area, document, and update unit tests.
# Base destructor function.
sub destroy {
    # Extract arguments.
    my $self = shift;

    # Sanity check: Make sure we've been fed an object.
    unless (ref($self)) {
        $LOG->error("Error: Function must be called in reference to a " .
                    __PACKAGE__ . "->new() object!");
        Carp::croak "Error: Function must be called in reference to a " .
                    __PACKAGE__ . "->new() object!\n";
    }

    # Delete any temporary files created by the baseline
    # and checkpoint parsers.
    $self->_cleanupParsers($self->{_baseline_parsers});
    $self->_cleanupParsers($self->{_checkpoint_parsers});
}

# Helper function, designed to cleanup temporary files created
# by specified parsers.
#
# Inputs: HoneyClient::Agent::Integrity::Registry object,
#         the hashtable collection of specified parsers
#
# Outputs: None.
sub _cleanupParsers {
    # Extract arguments.
    my ($self, $parser_collection) = @_;

    # Delete any temporary files created.
    my $parser = undef;
    my $fname = undef;
    foreach my $hive (@{$self->{hives_to_check}}) {
        $parser = $parser_collection->{$hive};
        if (defined($parser)) {
            $fname = $parser->getFilename();
            if (defined($fname) && (-f $fname)) {
                $LOG->debug("Deleting temporary '" . $hive . "' hive data in '" .
                            $fname . "'.");
                if (!unlink($fname)) {
                    $LOG->fatal("Error: Unable to unlink '" . $hive . "' hive data in '" . $fname ."'.");
                    Carp::croak("Error: Unable to unlink '" . $hive . "' hive data in '" . $fname ."'.");
                }
            }
            delete($parser_collection->{$hive});
        }
    }
}

# Helper function, designed to update the Registry object by
# taking snapshots of all specified hives and saving these
# to temporary files.
#
# Inputs: HoneyClient::Agent::Integrity::Registry object,
#         the hashtable collection of files to snapshot
#
# Outputs: None.
sub _snapshot {
    # Extract arguments.
    my ($self, $parser_collection) = @_;
    my $parser = undef;
    my $fname = undef;
    my $fname_tmp = undef;
    foreach my $hive (@{$self->{hives_to_check}}) {
        # Check to see if we can reuse temporary files from
        # past checkpoint operations.
        if (exists($parser_collection->{$hive}) &&
            defined($parser_collection->{$hive})) {
            $parser = $parser_collection->{$hive};
            $fname = $parser->getFilename();
        } else {
            $fname = tmpnam();
        }

        $fname_tmp = tmpnam();
        $LOG->debug("Storing snapshot of hive '" . $hive . "' into '" . $fname . "'.");
        $LOG->debug("Creating temporary file '" . $fname_tmp . "' to perform data conversion.");

        # Make sure the registry tools aren't disabled.
        if (system('reg.exe add HKCU\\\Software\\\Microsoft\\\Windows\\\CurrentVersion\\\Policies\\\System /f > /dev/null 2>&1')) {
            $LOG->fatal("Error: Unable to enable registry tools in policy.");
            Carp::croak("Error: Unable to enable registry tools in policy.");
        }
        if (system('reg.exe add HKCU\\\Software\\\Microsoft\\\Windows\\\CurrentVersion\\\Policies\\\System /v DisableRegistryTools /t REG_DWORD /d 0 /f > /dev/null 2>&1')) {
            $LOG->fatal("Error: Unable to enable registry tools in policy.");
            Carp::croak("Error: Unable to enable registry tools in policy.");
        }

        # Dump registry.  Strip all '\r' characters.
        if (system("regedit.exe /a \"" . fullwin32path($fname_tmp) . "\" \"$hive\" &&
                   cat " . $fname_tmp . " | sed -e 's/\r//g' > " . $fname) != 0) {
            $LOG->fatal("Error: Unable to write '" . $hive . "' hive data to '" . $fname ."'.");
            Carp::croak("Error: Unable to write '" . $hive . "' hive data to '" . $fname ."'.");
        }

        # Delete the unconverted temporary file.
        _cleanup($fname_tmp);

        $parser = HoneyClient::Agent::Integrity::Registry::Parser->init(input_file    => $fname,
                                                                        index_groups  => 1,
                                                                        show_progress => 0);

        $parser_collection->{$hive} = $parser;
    }
}

# Helper function, designed to compare two registry key directory
# names.  This comparison is case insensitive and handles any strings
# that may contain '\\' correctly.
#
# Inputs: HoneyClient::Agent::Integrity::Registry object,
#         x directory name, y directory name
#         
# Outputs: -1 if x is alphabetically less than y,
#           0 if x and y are equal,
#           1 if x is alphabetically greater than y
sub _cmpGroup {
    my ($self, $x, $y) = @_;
    $x =~ tr/A-Z/a-z/;
    $x =~ s/\\/\001/g;    # \001 instead of \0 due to perl 5.003 bug
    $y =~ tr/A-Z/a-z/;
    $y =~ s/\\/\001/g;
    return $x cmp $y;
}

# Helper function, designed to compare two registry key entry 
# names.  This comparison is case insensitive, handles default entry
# names correctly (@), and strips any quotes.
#
# Inputs: HoneyClient::Agent::Integrity::Registry object,
#         x entry name, y entry name
#
# Outputs: -1 if x is alphabetically less than y,
#           0 if x and y are equal,
#           1 if x is alphabetically greater than y
sub _cmpEntryName {
    my ($self, $x, $y) = @_;

    if ($x eq '@') {
        $x = '';
    } else {
        $x =~ s/^"//;
        $x =~ s/"$//;
        $x =~ tr/A-Z/a-z/;
    }

    if ($y eq '@') {
        $y = '';
    } else {
        $y =~ s/^"//;
        $y =~ s/"$//;
        $y =~ tr/A-Z/a-z/;
    }

    return $x cmp $y;
}

# Helper function, designed to get the next registry key directory
# name out of the specified file.
#
# Inputs: HoneyClient::Agent::Integrity::Registry object, file parser to read
#
# Outputs: next registry key directory name; undef if no key directory names
#          are left to read
sub _nextGroup {
    my ($self, $parser) = @_;

    # Read the next key from the specified file.
    $self->{_currentKeys}->{$parser} = $parser->nextGroup();

    # Check to make sure read was successful.
    if (!defined($self->{_currentKeys}->{$parser})) {
        $LOG->fatal("Error: Unable to read registry keys from '" .
                    $parser->getFilename() . "'.");
        Carp::croak("Error: Unable to read registry keys from '" .
                    $parser->getFilename() . "'.");
    }

    # Encountered empty hash ref, thus we are at
    # the end of the file.
    if (!%{$self->{_currentKeys}->{$parser}}) {
        return undef;
    }

    # Key read was successful, reset the entry index
    # for this file.
    $self->{_currentEntryIndex}->{$parser} = 0;

    # Return the corresponding key directory name.
    return $self->{_currentKeys}->{$parser}->{'key'};
}

# Helper function, designed to get the next entry (name, value) pair within
# the last key directory that was fetched by _nextGroup().
#
# Inputs: HoneyClient::Agent::Integrity::Registry object, file parser to read
#
# Outputs: next entry (name, value) pair; undef if no entries were found that
#          correspond to the last key directory fetched by _nextGroup()
sub _nextVal {
    my ($self, $parser) = @_;

    # Read the last key object read from the specified file.
    my ($k) = $self->{_currentKeys}->{$parser};

    # Get the latest entry index associated with the latest key.
    my ($i) = $self->{_currentEntryIndex}->{$parser};

    # If the index is past our array of known entries, then return undef.
    if ($i >= @{$k->{'entries'}}) {
        return undef;
    }

    # There is an entry to be read, so increment the entry index.
    $self->{_currentEntryIndex}->{$parser} = $i + 1;

    # Return the corresponding entry (name, value) pair.
    return (${$k->{'entries'}}[$i]->{'name'},
            ${$k->{'entries'}}[$i]->{'value'});
}

# Helper function, designed to perform a binary diff on two files,
# providing two arrays of line numbers, corresponding to where changes
# have occurred in either source or target registry hive dumps, along
# with an array of corresponding characters ('a', 'c', or 'd'),
# signifying what type of change was made.
#
# Inputs: HoneyClient::Agent::Integrity::Registry object, 
#         source parser, target parser
#
# Outputs: source line number array ref, target line number array ref,
#          diff type char array ref
sub _diff {
    # Extract arguments.
    my ($self, $src_parser, $tgt_parser) = @_;

    my $src_linenums = [];
    my $tgt_linenums = [];
    my $diff_types = [];

    # Get the corresponding file names.
    my $src_filename = $src_parser->getFilename();
    my $tgt_filename = $tgt_parser->getFilename();

    my $fname_tmp = tmpnam();
    $LOG->debug("Creating temporary file '" . $fname_tmp . "' to perform differential analysis.");

    # Perform diff operation.
    # Because we're chaining together multiple system operations, we have to check the file output
    # directly, to see if any failures occurred.
    system("((diff --speed-large-files \"" . $src_filename . "\" \"" . $tgt_filename . "\" && " .
             "echo \"0NOCHANGES\") | " . 
            "grep -e '^[0-9].*' || echo \"FAILURE\") > " . $fname_tmp . " 2>/dev/null");

    my $fh = new IO::File($fname_tmp, "r");
    if (!defined($fh)) {
        $LOG->fatal("Error: Unable to read file '" . $fname_tmp . "'!");
        Carp::croak("Error: Unable to read file '" . $fname_tmp . "'!");
    }

    # Read in the first line.
    $/ = "\n";
    $_ = <$fh>;

    if (defined($_)) {
        if ($_ eq "0NOCHANGES\n") {
            $LOG->debug("No changes detected in specified data.");
            _cleanup($fname_tmp);
            return ($src_linenums, $tgt_linenums, $diff_types);
        }
        if ($_ eq "FAILURE\n") {
            # Check if diff operation failed.
            _cleanup($fname_tmp);
            $LOG->fatal("Error: Unable to diff '" . $src_filename . "' against '" . $tgt_filename ."'.");
            Carp::croak("Error: Unable to diff '" . $src_filename . "' against '" . $tgt_filename ."'.");
        }
    }

    do {
        if (/([0-9]+)(?:|,[0-9]+)([a-z])([0-9]+)/) {
            push (@{$src_linenums}, $1);
            push (@{$diff_types}, $2);
            push (@{$tgt_linenums}, $3);
        }
    } while (<$fh>);

    _cleanup($fname_tmp);
    return ($src_linenums, $tgt_linenums, $diff_types);
}

# Helper function, to delete a specified temporary file.
#
# Inputs: tmpfile
# Outputs: None
sub _cleanup {
    my $tmpfile = shift;
    undef $/;
    if (!unlink($tmpfile)) {
        $LOG->fatal("Error: Unable to delete temporary file '" . $tmpfile ."'.");
        Carp::croak("Error: Unable to delete temporary file '" . $tmpfile ."'.");
    }
}

# Helper function, designed to filter a given array reference of
# registry changes and return a new list that does not contain
# any of the excluded directory names.
#
# Inputs: self, arrayref of changes
# Outpus: arrayref of filtered changes
sub _filter {
    # Extract arguments
    my ($self, $changes) = @_;

    # Array reference of filtered changes.
    my $filteredChanges = [ ];

    # Indicates if the change should be filtered out.
    my $changeFiltered = 0;

    foreach my $change (@{$changes}) {
        $changeFiltered = 0;
        foreach my $criteria (@{$self->{'key_dirnames_to_ignore'}}) {
            if ($change->{'key_name'} =~ /$criteria/) {
                $changeFiltered = 1;
                last;
            }
        }
        if (!$changeFiltered) {
            push (@{$filteredChanges}, $change); 
        }
    }

    return $filteredChanges;
}

# Helper function, designed to be called from within the
# Search::Binary::binary_search() function, in order to allow
# the binary_search to properly read in group line number data from
# the default Registry object reference.
#
# For more information about how this function operates, please
# see the Search::Binary POD documentation.
#
# Inputs: self, value_to_compare, current_array_index
# Outputs: comparison, last_valid_array_index
sub _search {
    # Extract arguments.
    my ($self, $value_to_compare, $current_array_index) = @_;

    # Increment the search index, if the current one is undef.
    if (defined($current_array_index)) {
        $self->{'_last_search_index'} = $current_array_index;
    } else {
        $self->{'_last_search_index'}++;
    }

    # Perform a comparison, if the array entry is defined.
    if (defined(@{$self->{'_group_index_linenums'}}[$self->{'_last_search_index'}])) {
        return($value_to_compare <=> @{$self->{'_group_index_linenums'}}[$self->{'_last_search_index'}],
               $self->{'_last_search_index'});
    }

    # Array entry not found, return undef with this position.
    return (undef, $self->{'_last_search_index'});
}

# Helper function, designed to compare the contents of two registry dumps,
# where each dump is represented by a Parser object.
#
# Inputs: before_parser => bparser, after_parser => aparser
# Outputs: an arrayref of registry changes
sub _compare {

    # Extract arguments.
    my ($self, %args) = @_;

    my $before_parser = $args{'before_parser'};
    my $after_parser  = $args{'after_parser'};

    # A hashtable reference, containing the latest change found.
    my $currentChange = { };

    # Indicates if the $currentChange hashtable is not empty.
    my $currentChangeExists = 0;

    # Array reference, containing hashtables, where each
    # hashtable represents a change between the before and
    # after parsers.
    my $changes = []; 

    # State variable:
    # - Positive value: Keep comparing groups, linearly.
    # - Zero or Negative value: Stop comparing groups, seek to
    #                           next diff.
    #
    # Note: When a comparison is different, then this variable's
    # value remains the same.  When a comparison is the same, then
    # this variable's value is decremented by 1.
    my $changeState = 1;
    
    # Array references, reflecting collection of line numbers
    # found, where differences occur between before and
    # after the specified files, along with an array reference of
    # characters ('a', 'd', or 'c') indicating the type of diffs.
    my ($before_linenums, $after_linenums, $diff_types) = $self->_diff($before_parser, $after_parser);

    # Helper variable, used to indirectly locate the corresponding
    # diff type of the current group block.
    my $found_index = undef;

    # Helper variables, to extract the latest line number from the diff
    # operation, along with the latest diff type.
    my $before_linenum = undef;
    my $after_linenum = undef;
    my $diff_type = undef;

    # Helper variables, to contain the latest parsed group.
    my $before_group = undef;
    my $after_group = undef;

    # Helper variables, to contain the latest parsed key/value pair.
    my ($before_entry_name, $before_entry_value) = (undef, undef);
    my ($after_entry_name, $after_entry_value)   = (undef, undef);

    # Helper variables, to keep track of how many total lines
    # that the parser has actually parsed.
    my $before_total_linenums = $before_parser->getCurrentLineCount();
    my $after_total_linenums = $after_parser->getCurrentLineCount();

    # Helper variables, to indicate whether the before or after group parser
    # needs to go back more than by more than one group (if the diff type
    # was an addition or deletion).
    my $before_adjust_index = 0;
    my $after_adjust_index = 0;

    while (1) {

        if (($changeState <= 0) ||
            (!defined($before_group) && !defined($after_group))) {

            # Get the next set of offsets and type.
            $before_linenum = shift(@{$before_linenums});
            $after_linenum  = shift(@{$after_linenums});
            $diff_type      = shift(@{$diff_types});

            # Return early, if no changes were found.
            if (!defined($before_linenum) && !defined($after_linenum)) {
                return $changes;
            }

            # Figure out how many lines we've parsed so far. 
            $before_total_linenums += $before_parser->getCurrentLineCount();
            $after_total_linenums += $after_parser->getCurrentLineCount();

            # Seek to nearest common group, that we haven't already parsed.
            if (($before_linenum >= $before_total_linenums) &&
                ($after_linenum >= $after_total_linenums)) {

                $before_adjust_index = 0;
                $after_adjust_index = 0;

                # We need to differentiate between 'a' and 'd' diff types that involve
                # whole directories, and those that involve only a directory's contents.
                #
                # If an 'a' or 'd' diff type is localized to within a directory, then
                # we know that the directory has simply changed (as it exists in both the
                # before and after files).
                #
                # However, if an 'a' or 'd' diff type includes the directory name, then
                # we know that the directory itself has been added or deleted respectively. 
                #
                # In order to determine whether we need to alter our diff type accordingly,
                # we need to see if the starting diff line number matches the line number
                # containing the directory name.  If it does, then we know that the diff
                # type does not need to be changed.  However, if the diff line number is
                # PAST the line number of the directory name, then we need to change the
                # diff type to 'c'.

                # 1) Figure out which before and after group block represents the specified
                # line number.
                # 2) Then seek to the PREVIOUS group block in both cases.
                # 3) The output of the seekToNearestGroup() call should give you an absolute
                # line number (call it "x").
                # 4) Then, (x + 1) should be the starting line number containing the directory
                # name.  This assumes that there's always one and only one newline between
                # each directory group.
                # 5) If the starting diff line number is GREATER than (x + 1), then change the
                # diff type to 'c'.  Otherwise, do nothing.
                
                if ($diff_type eq 'a') {
                    # Seek to the previous group block
                    $after_total_linenums = $after_parser->seekToNearestGroup(absolute_linenum => $after_linenum,
                                                                              adjust_index => 0);
                    # This is the line number of the directory name.
                    my $directory_name_linenum = $after_total_linenums + 1;
                    
                    if ($after_linenum != $directory_name_linenum) {
                        $diff_type = 'c';
                    }
                } elsif ($diff_type eq 'd') {
                
                    $before_total_linenums = $before_parser->seekToNearestGroup(absolute_linenum => $before_linenum,
                                                                                adjust_index => 0);
                    # This is the line number of the directory name.
                    my $directory_name_linenum = $before_total_linenums + 1;
                
                    if ($before_linenum != $directory_name_linenum) {
                        $diff_type = 'c';
                    }
                }

                if ($diff_type eq 'a') {
                    $after_adjust_index = -1;
                    # Be sure to perform comparisons before (-1), during (0), and after (-1) the diff block.
                    $changeState = 2;
                } elsif ($diff_type eq 'd') {
                    $before_adjust_index = -1;
                    # Be sure to perform comparisons before (-1), during (0), and after (-1) the diff block.
                    $changeState = 2;
                } else {
                    # Be sure to perform comparisons during (0) and after (-1) the diff block.
                    $changeState = 2;
                }

                $before_total_linenums = $before_parser->seekToNearestGroup(absolute_linenum => $before_linenum,
                                                                            adjust_index => $before_adjust_index);
                $after_total_linenums = $after_parser->seekToNearestGroup(absolute_linenum => $after_linenum,
                                                                          adjust_index => $after_adjust_index);
            }
        }

        # Get the next registry group from both files.
        $before_group = $self->_nextGroup($before_parser);
        $after_group  = $self->_nextGroup($after_parser);

        # While we are able to read the next key from either file...
        while (($changeState > 0) && (defined($before_group) || defined($after_group))) {

            # Update the total line count.
            $before_total_linenums += $before_parser->getCurrentLineCount();
            $after_total_linenums += $after_parser->getCurrentLineCount();

            # Specify the array of line numbers to search in.
            $self->{'_group_index_linenums'} = $before_linenums;

            if (defined(@{$before_linenums}[0]) &&
                ($before_total_linenums >= @{$before_linenums}[0])) {

                # Find the group after the corresponding matched line number.
                $found_index = binary_search(0, scalar(@{$before_linenums}) - 1, $before_total_linenums, \&_search, $self);

                # Find the group before the corresponding matched line number.
                if ($found_index > 0) {
                    $found_index--;
                }
 
                # Fetch the corresponding $diff_type
                $diff_type = @{$diff_types}[$found_index];
            }

            # Sanity check.
            if (!defined($diff_type)) {
                $diff_type = '';
            }

            # Reset the current change hashref.
            $currentChange = { };

            # If the next group name extracted from both files is identical... 
            if (defined($before_group) && defined($after_group) &&
                ($self->_cmpGroup($before_group, $after_group) == 0)) {

                # Extract the next key/value pair corresponding to this group from
                # both files.
                ($before_entry_name, $before_entry_value) = $self->_nextVal($before_parser);
                ($after_entry_name, $after_entry_value)   = $self->_nextVal($after_parser);

                # While this key name exists in either file...
                while (defined($before_entry_name) || defined($after_entry_name)) {

                    # If the key name matches in both files...
                    if (defined($before_entry_name) && defined($after_entry_name) &&
                        $self->_cmpEntryName($before_entry_name, $after_entry_name) == 0) {

                        # If the corresponding values in both files are
                        # DIFFERENT...
                        if ($before_entry_value ne $after_entry_value) {

                            # Scenario:
                            # Same directory name, same entry key name,
                            # but different entry values.

                            # Save the change.
                            $currentChange->{'key_name'} = $before_group;
                            $currentChange->{'status'} = $STATUS_MODIFIED;
                            $currentChange->{'entries'}->{$before_entry_name} = {
                                old_value => $before_entry_value,
                                new_value => $after_entry_value,
                            };
                        }

                        # Get the next corresponding key/value pair from this group.
                        ($before_entry_name, $before_entry_value) = $self->_nextVal($before_parser);
                        ($after_entry_name, $after_entry_value)   = $self->_nextVal($after_parser);

                        # Else, the key names are different in both files...
                    } else {

                        # Scenario:
                        # Same directory name, different entry key names.

                        # Save the change.
                        $currentChange->{'key_name'} = $before_group;
                        $currentChange->{'status'} = $STATUS_MODIFIED;

                        # If the after key name doesn't exist, or if the before key 
                        # name exists and the before name is alphabetically earlier
                        # than the after key name...
                        if (!defined($after_entry_name) || defined($before_entry_name) &&
                            $self->_cmpEntryName($before_entry_name, $after_entry_name) < 0) {

                            # Then we know that the before key name got deleted
                            # in the after file.
                            # Check to see if some of this change data already exists...
                            if (exists($currentChange->{'entries'}->{$before_entry_name})) {

                                # Sanity check: Looks like an earlier iteration populated
                                # this change entry with a 'new_value'.  Let's make sure
                                # the our 'old_value' and 'new_value' are truly different.
                                if (defined($currentChange->{'entries'}->{$before_entry_name}->{'new_value'}) &&
                                    ($currentChange->{'entries'}->{$before_entry_name}->{'new_value'} ne
                                        $before_entry_value)) {

                                    # Okay, looks like they're different, so only update the old_value.
                                    $currentChange->{'entries'}->{$before_entry_name}->{'old_value'} = $before_entry_value;
                                } else {
                                    # Looks like they're the same value, so delete the entry completely.
                                    delete($currentChange->{'entries'}->{$before_entry_name});
                                }
                            } else {
                                # If not, then update both old_value and new_value.
                                $currentChange->{'entries'}->{$before_entry_name} = {
                                    old_value => $before_entry_value,
                                    new_value => undef,
                                };
                            }

                            # And get the next corresponding key/value pair from the before group.
                            ($before_entry_name, $before_entry_value) = $self->_nextVal($before_parser);

                            # Else, the after key name exists but the corresponding before key name 
                            # did not exist -- which means that this is a new key/value pair.
                        } else {

                            # Check to see if some of this change data already exists...
                            if (exists($currentChange->{'entries'}->{$after_entry_name})) {
                                # Sanity check: Looks like an earlier iteration populated
                                # this change entry with an 'old_value'.  Let's make sure
                                # the our 'old_value' and 'new_value' are truly different.
                                if (defined($currentChange->{'entries'}->{$after_entry_name}->{'old_value'}) &&
                                    ($currentChange->{'entries'}->{$after_entry_name}->{'old_value'} ne
                                        $after_entry_value)) {

                                    # Okay, looks like they're different, so only update the new_value.
                                    $currentChange->{'entries'}->{$after_entry_name}->{'new_value'} = $after_entry_value;
                                } else {
                                    # Looks like they're the same value, so delete the entry completely.
                                    delete($currentChange->{'entries'}->{$after_entry_name});
                                }
                            } else {
                                # If not, then update both old_value and new_value.
                                $currentChange->{'entries'}->{$after_entry_name} = {
                                    old_value => undef,
                                    new_value => $after_entry_value,
                                };
                            }

                            # And get the next corresponding key/value pair from the after group.
                            ($after_entry_name, $after_entry_value) = $self->_nextVal($after_parser);
                        }
                    }
                }

                # Once we're out of the previous loop, then we are finished enumerating
                # all key/value pairs corresponding to the identical group in either files.

                # And get the next group to compare from both files.
                $before_group = $self->_nextGroup($before_parser);
                $after_group  = $self->_nextGroup($after_parser);

                # Else, if the after group doesn't exist, or if the before group exists and the
                # before group name is alphabetically earlier than the after group name...
                # but verify that our $diff_type signifies a deletion or change (otherwise, the groups
                # may not be sorted alphabetically).
            } elsif (!defined($after_group) || (defined($before_group) &&
                     ((($diff_type eq 'd') || ($diff_type eq 'c')) &&
                      ($self->_cmpGroup($before_group, $after_group) < 0)))) {

                # Scenario:
                # Directory was deleted.

                # Save the change.
                $currentChange->{'key_name'} = $before_group;
                $currentChange->{'status'} = $STATUS_DELETED;
                $currentChange->{'entries'} = { };

                # Get the first key/value pair from this before group.
                ($before_entry_name, $before_entry_value) = $self->_nextVal($before_parser);

                # While there are key/values within this before group.
                while (defined($before_entry_name)) {
                    $currentChange->{'entries'}->{$before_entry_name} = {
                        old_value => $before_entry_value,
                        new_value => undef,
                    };

                    # And get the next corresponding key/value pair from the before group.
                    ($before_entry_name, $before_entry_value) = $self->_nextVal($before_parser);
                }

                # Get the next group from the before file.
                $before_group = $self->_nextGroup($before_parser);

                # Else, the after group exists but the corresponding before group
                # did not exist -- which means that this is a new group.
            } else {

                # Scenario:
                # Directory was added.

                # Save the change.
                $currentChange->{'key_name'} = $after_group;
                $currentChange->{'status'} = $STATUS_ADDED;
                $currentChange->{'entries'} = { };

                # Get the first key/value pair from this after group.
                ($after_entry_name, $after_entry_value) = $self->_nextVal($after_parser);

                # While there are key/values within this after group.
                while (defined($after_entry_name)) {

                    $currentChange->{'entries'}->{$after_entry_name} = {
                        old_value => undef,
                        new_value => $after_entry_value,
                    };

                    # Get the next key/value pair from the after group.
                    ($after_entry_name, $after_entry_value) = $self->_nextVal($after_parser);
                }

                # Get the next group from the after file.
                $after_group = $self->_nextGroup($after_parser);
            }

            # Transform the 'entries' sub-key from a nested hash structure,
            # into an array of separate hashtables.
            if (exists($currentChange->{'entries'})) {
                my $entries = [ ];
                while (my ($key, $value) = each(%{$currentChange->{'entries'}})) {
                    push (@{$entries}, {
                            name      => $key,
                            old_value => $value->{'old_value'},
                            new_value => $value->{'new_value'},
                        });
                }
                $currentChange->{'entries'} = $entries;
            }

            # Determine if $currentChange is empty.
            $currentChangeExists = scalar(keys(%{$currentChange}));

            # Push the change onto our array of changes.
            if ($currentChangeExists) {
                push(@{$changes}, $currentChange);
            } else {
                $changeState--;
            }
        }
    }
}

#######################################################################
# Public Methods Implemented                                          #
#######################################################################

=pod

=head1 METHODS IMPLEMENTED

The following functions have been implemented by any Registry object.

=head2 HoneyClient::Agent::Integrity::Registry->new($param => $value, ...)

=over 4

Creates a new Registry object, which contains a hashtable
containing any of the supplied "param => value" arguments.  Upon
creation, the Registry object performs a baseline of the Windows
registry.

I<Inputs>:
 B<$param> is an optional parameter variable.
 B<$value> is $param's corresponding value.
 
Note: If any $param(s) are supplied, then an equal number of
corresponding $value(s) B<must> also be specified.

I<Output>: The instantiated Registry B<$object>, fully initialized.

=back

=begin testing

diag("These tests will create temporary files in /tmp.  Be sure to cleanup this directory, if any of these tests fail.");

# Create a generic Registry object, with test state data.
my $registry = HoneyClient::Agent::Integrity::Registry->new(test => 1, bypass_baseline => 1);
is($registry->{test}, 1, "new(test => 1, bypass_baseline => 1)") or diag("The new() call failed.");
isa_ok($registry, 'HoneyClient::Agent::Integrity::Registry', "new(test => 1, bypass_baseline => 1)") or diag("The new() call failed.");

diag("Performing baseline check of 'HKEY_CURRENT_USER' hive; this may take some time...");

# Perform Registry baseline on HKEY_CURRENT_USER.
$registry = HoneyClient::Agent::Integrity::Registry->new(hives_to_check => [ 'HKEY_CURRENT_USER' ]);
isa_ok($registry, 'HoneyClient::Agent::Integrity::Registry', "new(hives_to_check => [ 'HKEY_CURRENT_USER' ])") or diag("The new() call failed.");

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

    # Log resolved arguments.
    $LOG->debug(sub {
        # Make Dumper format more terse.
        $Data::Dumper::Terse = 1;
        $Data::Dumper::Indent = 0;
        Dumper(\%args);
    });

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

    # Perform registry baselining, if not bypassed.
    if (!$self->{'bypass_baseline'}) {
        $LOG->info("Baselining registry hives.");
        $self->_snapshot($self->{_baseline_parsers});
    }

    # Finally, return the blessed object.
    return $self;
}

=pod

=head2 $object->check(before_file => $before_filename, after_file => $after_filename)

=over 4

Checks the registry for any changes, based upon the baseline snapshot
of the registry, when the new() method was invoked.

I<Inputs>:
 B<$before_filename> is an optional parameter, specifying the registry dump to use
as the baseline, rather than using any baseline that was performed during the
$object->new() operation.
 B<$after_filename> is an optional parameter, specifying the registry dump to use
as the checkpoint, rather than creating new a registry checkpoint to compare against.

I<Output>:
 B<$changes>, which is an array of hashtable references, where each
hashtable has the following format:
 
  $changes = [ {
      # The registry directory name.
      'key_name' => 'HKEY_LOCAL_MACHINE\Software...',

      # Indicates if the registry directory was deleted (0),
      # added (1), or changed (2).
      'status' => 0 | 1 | 2,
 
      # An array containing the list of entries within the
      # registry directory that have been deleted, added, or
      # changed.  If this array is empty, then the corresponding
      # registry directory in the original and new hives contained
      # no entries.
      'entries'  => [ {
          'name' => "\"string\"",  # A (potentially) quoted string; 
                                   # "@" for default
          'new_value' => "string", # New string; maybe undef, if deleted
          'old_value' => "string", # Old string; maybe undef, if added
      }, ],
  }, ]

I<Notes>: If B<$before_filename> is specified, then B<$after_filename> must be 
specified as well.

=back

=begin testing

my ($foundChanges, $expectedChanges);
my $before_registry_file = $ENV{PWD} . "/" . getVar(name      => "before_registry_file",
                                                    namespace => "HoneyClient::Agent::Integrity::Registry::Test");
my $after_registry_file = $ENV{PWD} . "/" . getVar(name      => "after_registry_file",
                                                   namespace => "HoneyClient::Agent::Integrity::Registry::Test");


# Create a generic Registry object, with test state data.
my $registry = HoneyClient::Agent::Integrity::Registry->new(bypass_baseline => 1);

# Verify Changes
$foundChanges = $registry->check(before_file => $before_registry_file,
                                 after_file  => $after_registry_file);
$expectedChanges = [
  {
    'entries' => [
      {
        'new_value' => undef,
        'name' => 'Test_Bin_1',
        'old_value' => 'hex:f4,ff,ff,ff,00,00,00,00,00,00,00,00,00,00,00,00,bc,02,00,00,00,\\
  00,00,00,00,00,00,00,54,00,61,00,68,00,6f,00,6d,00,61,00,00,00,f0,77,3f,00,\\
  3f,00,3f,00,3f,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,78,00,1c,10,fc,\\
  7f,22,14,fc,7f,b0,fe,12,00,00,00,00,00,00,00,00,00,98,23,eb,77',
      },
      {
        'new_value' => 'hex:f4,ff,ff,ff,00,00,00,00,00,00,00,00,00,00,00,00,bc,02,00,00,00,\\
  00,00,00,00,00,00,00,54,00,61,00,68,00,6f,00,6d,00,61,00,00,00,f0,77,3f,00,\\
  3f,00,3f,00,3f,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,78,00,1c,10,fc,\\
  7f,22,14,fc,7f,b0,fe,12,00,00,00,00,00,00,00,00,00,98,23,eb,77',
        'name' => 'Test_Bon_1',
        'old_value' => undef,
      }
    ],
    'status' => $HoneyClient::Agent::Integrity::Registry::STATUS_MODIFIED,
    'key_name' => 'HKEY_CURRENT_USER\\Testing Group 3',
  },
  {
    'entries' => [],
    'status' => $HoneyClient::Agent::Integrity::Registry::STATUS_DELETED,
    'key_name' => 'HKEY_CURRENT_USER\\Testing Group 4',
  },
  {
    'entries' => [
      {
        'new_value' => 'new value',
        'name' => '@',
        'old_value' => '',
      }
    ],
    'status' => $HoneyClient::Agent::Integrity::Registry::STATUS_MODIFIED,
    'key_name' => 'HKEY_CURRENT_USER\\Testing Group 5',
  },
  {
    'entries' => [
      {
        'new_value' => 'hex:f5,ff,ff,ff,00,00,00,00,00,00,00,00,00,00,00,00,90,01,00,00,00,\\
  00,00,00,00,00,00,00,4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,\\
  20,00,53,00,61,00,6e,00,73,00,20,00,53,00,65,00,72,00,69,00,66,00,00,00,f0,\\
  77,00,20,14,00,00,00,00,10,80,05,14,00,f0,1f,14,00,00,00,14,00',
        'name' => 'Test_Bin_3',
        'old_value' => undef,
      }
    ],
    'status' => $HoneyClient::Agent::Integrity::Registry::STATUS_ADDED,
    'key_name' => 'HKEY_CURRENT_USER\\Testing Group 6',
  },
  {
    'entries' => [
      {
        'new_value' => 'C:\\\\WINDOWSsystem32\\\\',
        'name' => 'InstallerLocation',
        'old_value' => 'C:\\\\WINDOWS\\\\system32\\\\',
      }
    ],
    'status' => $HoneyClient::Agent::Integrity::Registry::STATUS_MODIFIED,
    'key_name' => 'HKEY_CURRENT_USER\\Testing Group 6\\With\\Really\\Deep\\Nested\\Directory\\Structure',
  },
  {
    'entries' => [
      {
        'new_value' => '',
        'name' => 'C:\\\\WINDOWS\\\\Installer\\\\{6855XXXX-BDF9-48E4-B80A-80DFB96FE36C}\\\\',
        'old_value' => undef,
      },
      {
        'new_value' => undef,
        'name' => 'C:\\\\WINDOWS\\\\Installer\\\\{6855CCDD-BDF9-48E4-B80A-80DFB96FE36C}\\\\',
        'old_value' => '',
      }
    ],
    'status' => $HoneyClient::Agent::Integrity::Registry::STATUS_MODIFIED,
    'key_name' => 'HKEY_CURRENT_USER\\Testing Group 7',
  },
  {
    'entries' => [
      {
        'new_value' => undef,
        'name' => '000',
        'old_value' => 'String Value',
      }
    ],
    'status' => $HoneyClient::Agent::Integrity::Registry::STATUS_DELETED,
    'key_name' => 'HKEY_CURRENT_USER\\Testing Group 8\\{00021492-0000-0000-C000-000000000046}',
  },
  {
    'entries' => [
      {
        'new_value' => 'String Value',
        'name' => '000',
        'old_value' => undef,
      }
    ],
    'status' => $HoneyClient::Agent::Integrity::Registry::STATUS_ADDED,
    'key_name' => 'HKEY_CURRENT_USER\\Testing Group 8\\{01021492-0000-0000-C000-000000000046}',
  },
  {
    'entries' => [
      {
        'new_value' => 'newvalue',
        'name' => 'newkey',
        'old_value' => undef,
      }
    ],
    'status' => $HoneyClient::Agent::Integrity::Registry::STATUS_ADDED,
    'key_name' => 'HKEY_CURRENT_USER\\Tsting Group 9',
  }
];

is_deeply($foundChanges, $expectedChanges, "check(before_file => '" . $before_registry_file . "', after_file => '" . $after_registry_file . "')") or diag("The check() call failed.");

=end testing

=cut

sub check {

    # Extract arguments.
    my ($self, %args) = @_;

    # Sanity check: Make sure we've been fed an object.
    unless (ref($self)) {
        $LOG->error("Error: Function must be called in reference to a " .
                    __PACKAGE__ . "->new() object!");
        Carp::croak "Error: Function must be called in reference to a " .
                    __PACKAGE__ . "->new() object!\n";
    }

    # Log resolved arguments.
    $LOG->debug(sub {
        # Make Dumper format more terse.
        $Data::Dumper::Terse = 1;
        $Data::Dumper::Indent = 0;
        Dumper(\%args);
    });

    # Define before/after parsers.
    my ($before_parser, $after_parser);

    # Sanity checks; check if any args were specified.
    my $argsExist = scalar(%args);
    if ($argsExist && 
        exists($args{'before_file'}) &&
        defined($args{'before_file'})) {
        $LOG->info("Before file '" . $args{'before_file'} . "' manually specified; " .
                   "using this file as basis, instead of any previous registry snapshot.");
        $before_parser = HoneyClient::Agent::Integrity::Registry::Parser->init(input_file   => $args{'before_file'},
                                                                               index_groups => 1);
    }

    if ($argsExist && 
        exists($args{'after_file'}) &&
        defined($args{'after_file'})) {
        $LOG->info("After file '" . $args{'after_file'} . "' manually specified; " .
                   "using this file for comparison, instead of snapshotting the registry.");
        $after_parser = HoneyClient::Agent::Integrity::Registry::Parser->init(input_file   => $args{'after_file'},
                                                                              index_groups => 1);
    }

    # Array references, containing hashtables, where each
    # hashtable represents a change between the registry hives.
    my $changes = [];
    my $local_changes = [];

    # Check to see if a before and after file were specified.
    if (defined($before_parser) && defined($after_parser)) {

        $changes = $self->_compare(before_parser => $before_parser,
                                   after_parser  => $after_parser);

    } else {
        # Checkpoint the registry.
        $LOG->info("Analyzing registry.");
        $self->_snapshot($self->{_checkpoint_parsers});

        $LOG->info("Checking for registry changes.");
        # Iterate through each hive...
        foreach my $hive (@{$self->{hives_to_check}}) {

            $LOG->debug("Checking '" . $hive . "' hive.");

            $before_parser = $self->{_baseline_parsers}->{$hive};
            $after_parser  = $self->{_checkpoint_parsers}->{$hive};

            # Obtain local changes per hive.
            $local_changes = $self->_compare(before_parser => $before_parser,
                                             after_parser  => $after_parser);
            # Concatinate these changes, to obtain a complete picture.
            $changes = [ @{$changes}, @{$local_changes}, ];

            $LOG->debug("Finished checking '" . $hive . "' hive.");
        }

        # Cleanup temporary files created by checkpointing.
        $self->_cleanupParsers($self->{_checkpoint_parsers});
    }

    # Finally, return the array of detected (but filtered) changes.
    $changes = $self->_filter($changes);
    if (scalar(@{$changes})) {
        $LOG->warn("Registry changes found.");
    } else {
        $LOG->info("No registry changes found.");
    }
    return $changes;
}        

=pod

=head2 $object->getFilesCreated()

=over 4

Returns a list of temporary filenames that have been created by the
Registry B<$object>.

I<Output>: Returns a list of filenames.

=back

=begin testing

# Perform Registry baseline on HKEY_CURRENT_CONFIG.
diag("Performing baseline check of 'HKEY_CURRENT_CONFIG' hive; this may take some time...");
my $registry = HoneyClient::Agent::Integrity::Registry->new(hives_to_check => [ 'HKEY_CURRENT_CONFIG' ]);
my @files_created = $registry->getFilesCreated();
use Data::Dumper;
my $tmpfile = tmpnam();
unlink($tmpfile); 
my $tmpdir = dirname($tmpfile);
foreach my $file (@files_created) {
    like($file, qr/$tmpdir/, "getFilesCreated()") or diag("The getFilesCreated() call failed.");
}

=end testing

=cut

sub getFilesCreated {
    # Extract arguments.
    my ($self, %args) = @_;

    # Sanity check: Make sure we've been fed an object.
    unless (ref($self)) {
        $LOG->error("Error: Function must be called in reference to a " .
                    __PACKAGE__ . "->new() object!");
        Carp::croak "Error: Function must be called in reference to a " .
                    __PACKAGE__ . "->new() object!\n";
    }

    # Log resolved arguments.
    $LOG->debug(sub {
        # Make Dumper format more terse.
        $Data::Dumper::Terse = 1;
        $Data::Dumper::Indent = 0;
        Dumper(\%args);
    });

    my @parsers = values(%{$self->{_baseline_parsers}});
    push (@parsers, values(%{$self->{_checkpoint_parsers}}));

    my @files;
    foreach my $parser (@parsers) {
        push (@files, $parser->getFilename());
    }

    return @files;
}

=pod

=head2 $object->closeFiles()

=over 4

Closes any temporary files that have been created by the
Registry B<$object>.  By performing this operation, the 
Registry B<$object> can become serializable.

=back

=begin testing

# Perform Registry baseline on HKEY_CURRENT_CONFIG.
diag("Performing baseline check of 'HKEY_CURRENT_CONFIG' hive; this may take some time...");
my $registry = HoneyClient::Agent::Integrity::Registry->new(hives_to_check => [ 'HKEY_CURRENT_CONFIG' ]);
$registry->closeFiles();
my @files_created = $registry->getFilesCreated();
use Data::Dumper;
my $tmpfile = tmpnam();
unlink($tmpfile); 
my $tmpdir = dirname($tmpfile);
foreach my $file (@files_created) {
    like($file, qr/$tmpdir/, "closeFiles()") or diag("The closeFiles() call failed.");
}

=end testing

=cut

sub closeFiles {
    # Extract arguments.
    my ($self, %args) = @_;

    # Sanity check: Make sure we've been fed an object.
    unless (ref($self)) {
        $LOG->error("Error: Function must be called in reference to a " .
                    __PACKAGE__ . "->new() object!");
        Carp::croak "Error: Function must be called in reference to a " .
                    __PACKAGE__ . "->new() object!\n";
    }

    # Log resolved arguments.
    $LOG->debug(sub {
        # Make Dumper format more terse.
        $Data::Dumper::Terse = 1;
        $Data::Dumper::Indent = 0;
        Dumper(\%args);
    });

    # Close any temporary files created.
    my $parser = undef;
    foreach my $hive (@{$self->{hives_to_check}}) {
        $parser = $self->{_baseline_parsers}->{$hive};
        if (defined($parser)) {
            $parser->closeFileHandle();
        }
        $parser = $self->{_checkpoint_parsers}->{$hive};
        if (defined($parser)) {
            $parser->closeFileHandle();
        }
    }
}

1;

#######################################################################
# Additional Module Documentation                                     #
#######################################################################

__END__

=head1 BUGS & ASSUMPTIONS

By default, this module performs a baseline integrity check on the
Windows OS registry during the $object->new() call.  The $object->check()
call will return any B<visible> changes found in the registry, between
these two calls.

Any changes that occur to the Windows registry that are performed and
then undone between these integrity checks B<WILL NOT BE DISCOVERED> by
the $object->check() operation.

This module relies on the REGEDIT.EXE utility program that is standard
on all Windows OS installations.  Because REGEDIT.EXE does not expose
null-encoded registry directory keys, this module will B<NOT> be able
to identify any adds, deletions, and/or changes to these types of
directory keys.

The $object->new() and $object->check() calls may generate a large
number of temporary files on disk.  If any of this code fails prematurely,
then it's likely these temporary files will still exist upon abnormal
termination.  As such, manual cleanup of these files in /tmp may be
required.

For more information about the limitations of this module, please see:

L<http://www.honeyclient.org/trac/wiki/ParsingRegistry>

=head1 SEE ALSO

L<http://www.cs.mun.ca/~michael/regutils/>

L<http://www.honeyclient.org/trac>

=head1 REPORTING BUGS

L<http://www.honeyclient.org/trac/newticket>

=head1 ACKNOWLEDGEMENTS

John Rochester E<lt>jr@cs.mun.caE<gt> and Michael Rendell 
E<lt>michael@cs.mun.caE<gt> from the Memorial University of
Newfoundland, for using core code from their regutils package,
in order to perform diff operations on registry hives.

=head1 AUTHORS

Darien Kindlund, E<lt>kindlund@mitre.orgE<gt>

Xeno Kovah, E<lt>xkovah@mitre.orgE<gt>

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
