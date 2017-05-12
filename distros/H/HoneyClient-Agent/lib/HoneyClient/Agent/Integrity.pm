################################################################################
# Created on:  June 01, 2006
# Package:     HoneyClient::Agent::Integrity
# File:        Integrity.pm
# Description: Module for checking the system integrity for possible
#              modifications.
#
# CVS: $Id: Integrity.pm 773 2007-07-26 19:04:55Z kindlund $
#
# @author knwang, xkovah, ttruong, kindlund, stephenson
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
################################################################################

=pod

=head1 NAME

HoneyClient::Agent::Integrity - Perl extension to perform configurable 
integrity checks of the Agent VM OS.

=head1 VERSION

This documentation refers to HoneyClient::Agent::Integrity version 0.98.

=head1 SYNOPSIS

  use HoneyClient::Agent::Integrity;
  use Data::Dumper;

  # Create the Integrity object.  Upon creation, the object will
  # be initialized, by performing a baseline of the Agent VM OS.
  my $integrity = HoneyClient::Agent::Integrity->new();

  # ... Some time elapses ...

  # Check the Agent VM, for any violations.
  my $changes = $integrity->check();

  if (!defined($changes)) {
      print "No integrity violations have occurred.\n";
  } else {
      print "System integrity has been compromised:\n";
      print Dumper($changes);
  }

  # $changes refers to an array of hashtable references, where
  # each hashtable has the following format:
  #
  # $changes = {
  #     registry => [ {
  #         # The registry directory name.
  #         'key' => 'HKEY_LOCAL_MACHINE\Software...',
  #
  #         # Indicates if the registry directory was deleted,
  #         # added, or changed.
  #         'status' => 'deleted' | 'added' | 'changed',
  # 
  #         # An array containing the list of entries within the
  #         # registry directory that have been deleted, added, or
  #         # changed.  If this array is empty, then the corresponding
  #         # registry directory in the original and new hives contained
  #         # no entries.
  #         'entries'  => [ {
  #             'name' => "\"string\"",  # A (potentially) quoted string; 
  #                                      # "@" for default
  #             'new_value' => "string", # New string; maybe undef, if deleted
  #             'old_value' => "string", # Old string; maybe undef, if added
  #         }, ],
  #    }, ],
  #
  #    filesystem => [ {
  #         # Indicates if the filesystem entry was deleted,
  #         # added, or changed.
  #         'status' => 'deleted' | 'added' | 'changed',
  #
  #         # If the entry has been added/changed, then this 
  #         # hashtable contains the file/directory's new information.
  #         'new' => {
  #             'name'  => 'C:\WINDOWS\SYSTEM32...',
  #             'size'  => 1263, # in bytes
  #             'mtime' => 1178135092, # modification time, seconds since epoch
  #         },
  #
  #         # If the entry has been deleted/changed, then this
  #         # hashtable contains the file/directory's old information.
  #         'old' => {
  #             'name'  => 'C:\WINDOWS\SYSTEM32...',
  #             'size'  => 802, # in bytes
  #             'mtime' => 1178135028, # modification time, seconds since epoch
  #         },
  #   }, ],
  # }

=head1 DESCRIPTION

# TODO: This text needs to change.

=head2 INITIALIZATION

# TODO: This text needs to change.

In order to properly check the system, a snapshot must be taken of a known-good
state.

For the filesystem this means a listing is created which contains 
cryptographic hashes of files in their start state. The only files what are 
checked are those which are explicitly specified in the checklist file (or are 
found in a specified directory) and are not in the exclusion list will be checked.
Initialization of the filesystem is done with the initFileSystem() function, 
described later.

For the registry a similar logic applies in that the only the specified keys are
checked and only if they are not in the exclusion list. The desired registry keys
are exported to a text file via the command line functionality of regedit. This
is done via initRegistry().


=head2 CHECKING

# TODO: This text needs to change.

Checking the filesystem entails running mostly the same code as the initialization
piece in order to obtain a snapshot of the current state of the filesystem. At that 
point additional checks are performed to look for additions, deletions, and 
modifications to the filesystem. These checks are done with checkFileSystem().

A speed-optimized check of the registry is performed by first dumping the current
state, again with the command line version of regedit. Then the unix "diff"
utility is used to compare the clean registry dump to the current one. The output
from a diff is in a format which shows the minimum possible changes which can be
done to the first file in order to yield the same content as the second file. 
Therefore this format must be parsed in order to determine what specific additions,
deletions, and modifications were made to the clean registry. Further, because 
the output of diff need not exactly reflect changes (for instance when the same
content would be the first line of the previous value and the last line of the new 
value) this requires some cases to re-consult the original and current state in order 
to disambiguate the changes which were made. These tests are done in checkRegistry().

NOTE: Because these are simple, static, user-space checks, they can fail in the 
presense of even user-space rootkits. Therefore these checks should not be taken as 
definitive proof of the absense of malicious software until they are integrated more
tightly with the system.

=cut

package HoneyClient::Agent::Integrity;

use strict;
use warnings;
use Carp ();


# Include Global Configuration Processing Library
use HoneyClient::Util::Config qw(getVar);

# Include the Registry Checking Library
use HoneyClient::Agent::Integrity::Registry;

# Include the Filesystem Checking Library
use HoneyClient::Agent::Integrity::Filesystem;

# Use Storable Library
use Storable qw(nfreeze thaw dclone);
$Storable::Deparse = 1;
$Storable::Eval = 1;

# Use Dumper Library
use Data::Dumper;

# Include Logging Library
use Log::Log4perl qw(:easy);

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

    # This allows declaration use HoneyClient::Agent::Integrity ':all';
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
BEGIN { use_ok('Storable', qw(nfreeze thaw dclone))
        or diag("Can't load Storable package. Check to make sure the package library is correctly listed within the path."); }
require_ok('Storable');
can_ok('Storable', 'nfreeze');
can_ok('Storable', 'thaw');
can_ok('Storable', 'dclone');
use Storable qw(nfreeze thaw dclone);

# Make sure HoneyClient::Agent::Integrity::Registry loads
BEGIN { use_ok('HoneyClient::Agent::Integrity::Registry')
        or diag("Can't load HoneyClient::Agent::Integrity::Registry package. Check to make sure the package library is correctly listed within the path."); }
require_ok('HoneyClient::Agent::Integrity::Registry');
use HoneyClient::Agent::Integrity::Registry;

# Make sure HoneyClient::Agent::Integrity::Filesystem loads
BEGIN { use_ok('HoneyClient::Agent::Integrity::Filesystem')
        or diag("Can't load HoneyClient::Agent::Integrity::Filesystem package. Check to make sure the package library is correctly listed within the path."); }
require_ok('HoneyClient::Agent::Integrity::Filesystem');
use HoneyClient::Agent::Integrity::Filesystem;

# Make sure HoneyClient::Agent::Integrity loads.
BEGIN { use_ok('HoneyClient::Agent::Integrity') or diag("Can't load HoneyClient::Agent::Integrity package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('HoneyClient::Agent::Integrity');
use HoneyClient::Agent::Integrity;

=end testing

=cut

#######################################################################
# Global Configuration Variables                                      #
#######################################################################

# The global logging object.
our $LOG = get_logger();

=pod

=head1 DEFAULT PARAMETER LIST

When an Integrity B<$object> is instantiated using the B<new()> function,
the following parameters are supplied default values.  Each value
can be overridden by specifying the new (key => value) pair into the
B<new()> function, as arguments.

=head2 bypass_baseline 

=over 4

When set to 1, the object will forgo any type of initial baselining
process, upon initialization.  Otherwise, baselining will occur
as normal, upon initialization.

=back

=cut

my %PARAMS = (
    # When set to 1, the object will forgo any type of initial baselining
    # process, upon initialization.  Otherwise, baselining will occur
    # as normal, upon initialization.
    bypass_baseline => 0,

    # Contains the Registry object, once initialized.
    # (For internal use only.)
    _registry => undef,

    # Contains the Filesystem object, once initialized.
    # (For internal use only.)
    _filesystem => undef,

    # XXX: comment this
    _changes_found_file => getVar(name => 'changes_found_file'),
);

#######################################################################
# Private Methods Implemented                                         #
#######################################################################

# Helper function, designed to baseline the system.
# 
# Inputs: None.
# Outputs: None.
sub _baseline {
    my $self = shift;
    # XXX: The Registry object MUST be created before the Filesystem object, since
    # the Registry object creates new files that must exist to be added to the
    # Filesystem's baseline list of files that exist on the system.
	$self->{'_registry'} = HoneyClient::Agent::Integrity::Registry->new();
    $self->{'_filesystem'} = HoneyClient::Agent::Integrity::Filesystem->new();
}

#######################################################################
# Public Methods Implemented                                          #
#######################################################################

=pod

=head1 METHODS IMPLEMENTED

The following functions have been implemented by any Integrity object.

=head2 HoneyClient::Agent::Integrity->new($param => $value, ...)

=over 4

Creates a new Integrity object, which contains a hashtable
containing any of the supplied "param => value" arguments.  Upon
creation, the Integrity object initializes all of its sub-modules,
by creating a baseline of the operating system.

I<Inputs>:
 B<$param> is an optional parameter variable.
 B<$value> is $param's corresponding value.
 
Note: If any $param(s) are supplied, then an equal number of
corresponding $value(s) B<must> also be specified.

I<Output>: The instantiated Integrity B<$object>, fully initialized.

=back

=begin testing

diag("These tests will create temporary files in /tmp.  Be sure to cleanup this directory, if any of these tests fail.");

# Create a generic Integrity object, with test state data.
my $integrity = HoneyClient::Agent::Integrity->new(test => 1, bypass_baseline => 1);
is($integrity->{test}, 1, "new(test => 1, bypass_baseline => 1)") or diag("The new() call failed.");
isa_ok($integrity, 'HoneyClient::Agent::Integrity', "new(test => 1, bypass_baseline => 1)") or diag("The new() call failed.");

diag("Performing baseline check of the system; this may take some time...");

# XXX: Uncomment this next check, eventually.  (It's commented out right now, in order to save some time).
# Perform baseline.
$integrity = HoneyClient::Agent::Integrity->new();
isa_ok($integrity, 'HoneyClient::Agent::Integrity', "new()") or diag("The new() call failed.");

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

    # Perform baselining, if not bypassed.
    if (!$self->{'bypass_baseline'}) {
        $LOG->info("Baselining system.");
        $self->_baseline();
    }

    # Finally, return the blessed object.
    return $self;
}


=pod

=head2 $object->check()

=over 4

Checks the operating system for various changes, based upon
the baseline snapshot of the system, when the new() method
was invoked.

I<Output>:
 B<$changes>, which is an array of hashtable references, where each
hashtable has the following format:
 
  $changes = {
      registry => [ {
          # The registry directory name.
          'key' => 'HKEY_LOCAL_MACHINE\Software...',

          # Indicates if the registry directory was deleted,
          # added, or changed.
          'status' => 'deleted' | 'added' | 'changed',
 
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
      }, ],

      filesystem => [ {
          # Indicates if the filesystem entry was deleted,
          # added, or changed.
          'status' => 'deleted' | 'added' | 'changed',

          # If the entry has been added/changed, then this 
          # hashtable contains the file/directory's new information.
          'new' => {
              'name'  => 'C:\WINDOWS\SYSTEM32...',
              'size'  => 1263, # in bytes
              'mtime' => 1178135092, # modification time, seconds since epoch
          },

          # If the entry has been deleted/changed, then this
          # hashtable contains the file/directory's old information.
          'old' => {
              'name'  => 'C:\WINDOWS\SYSTEM32...',
              'size'  => 802, # in bytes
              'mtime' => 1178135028, # modification time, seconds since epoch
          },
      }, ],
  }

I<Notes>:

=back

#=begin testing
#
# TODO:
#
#=end testing

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

	my $changes = {
        'registry' => $self->{'_registry'}->check(),
        'filesystem' => $self->{'_filesystem'}->check(),
    };

    # If any changes were found, write them out to the
    # filesystem.
    if (scalar(@{$changes->{registry}}) ||
        scalar(@{$changes->{filesystem}})) {
        if (!open(CHANGE_FILE, ">>" . $self->{_changes_found_file})) {
            $LOG->error("Unable to write changes to file '" . $self->{_changes_found_file} . "'.");
        } else {
            $Data::Dumper::Terse = 1;
            $Data::Dumper::Indent = 1;
            print CHANGE_FILE Dumper($changes);
            close CHANGE_FILE;
        }
    }

	return $changes;
}

# TODO: Comment this.
sub closeFiles {
    my $self = shift;

    # Sanity check: Make sure we've been fed an object.
    unless (ref($self)) {
        $LOG->error("Error: Function must be called in reference to a " .
                    __PACKAGE__ . "->new() object!");
        Carp::croak "Error: Function must be called in reference to a " .
                    __PACKAGE__ . "->new() object!\n";
    }

    if (defined($self->{'_registry'})) {
        $self->{'_registry'}->closeFiles();
    }
}

# TODO: Comment this.
sub destroy {
    my $self = shift;

    # Sanity check: Make sure we've been fed an object.
    unless (ref($self)) {
        $LOG->error("Error: Function must be called in reference to a " .
                    __PACKAGE__ . "->new() object!");
        Carp::croak "Error: Function must be called in reference to a " .
                    __PACKAGE__ . "->new() object!\n";
    }

    if (defined($self->{'_registry'})) {
        $self->{'_registry'}->destroy();
    }
}

1;

=pod

=head1 BUGS & ASSUMPTIONS

# XXX: Fill this in.

=head1 TODO

Need to add sub-modules that support the following capabilities:

=over 4

=item *

Static or real-time rogue process detection.

=item *

Static or real-time memory alteration detection.

=back

=head1 SEE ALSO

L<http://www.honeyclient.org/trac>

=head1 REPORTING BUGS

L<http://www.honeyclient.org/trac/newticket>

=head1 ACKNOWLEDGEMENTS

XXX: Fill this in.

=head1 AUTHORS

Kathy Wang, E<lt>knwang@mitre.orgE<gt>

Xeno Kovah, E<lt>xkovah@mitre.orgE<gt>

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

