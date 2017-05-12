####################################################################
#
#    This file was generated using Parse::Yapp version 1.05.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package HoneyClient::Agent::Integrity::Registry::Parser;
use vars qw ( @ISA );
use strict;

@ISA= qw ( Parse::Yapp::Driver );
use Parse::Yapp::Driver;

#line 1 "Parser.yp"

#######################################################################
# Created on:  Dec 10, 2006
# Package:     HoneyClient::Agent::Integrity::Registry::Parser
# File:        Parser.pm
# Description: Parses static hive dumps of the Windows OS registry.
#
# CVS: $Id: Parser.pm 773 2007-07-26 19:04:55Z kindlund $
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

HoneyClient::Agent::Integrity::Registry::Parser - Perl extension to parse
static hive dumps of the Windows OS registry.

=head1 VERSION

This documentation refers to HoneyClient::Agent::Integrity::Registry::Parser version 0.98.

=head1 SYNOPSIS

  use HoneyClient::Agent::Integrity::Registry::Parser;
  use IO::File;
  use Data::Dumper;

  # Initialize the parser object.
  my $parser = HoneyClient::Agent::Integrity::Registry::Parser->init(
                   input_file => "dump.reg",
               );

  # Print each registry group found, until there are no more left.
  my $registryGroup = $parser->nextGroup();
  while(scalar(keys(%{$registryGroup}))) {
      print Dumper($registryGroup);
      $registryGroup = $parser->nextGroup();
  }

  # $registryGroup refers to hashtable reference, which has the
  # following format:
  #
  # $registryGroup = {
  #     # The registry directory name.
  #     'key' => 'HKEY_LOCAL_MACHINE\Software...',
  #
  #     # An array containing the list of entries within the
  #     # registry directory.
  #     'entries'  => [ {
  #         'name' => "\"string\"",  # A (potentially) quoted string; 
  #                                  # "@" for default
  #         'value' => "data",
  #     }, ],
  # };

=head1 DESCRIPTION

This library allows the Registry module to easily parse and enumerate
each Windows OS registry hive.

=cut

use strict;
use warnings;
use Carp ();

# Include Global Configuration Processing Library 
use HoneyClient::Util::Config qw(getVar);

# Include Logging Library
use Log::Log4perl qw(:easy);

# Use Dumper Library.
use Data::Dumper;

# Use IO File Library.
use IO::File;

# Use Seek Library.
use Fcntl qw(:seek);

# Use Binary Search Library.
use Search::Binary;

# Use Progress Bar Library.
use Term::ProgressBar;

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

# Make sure Search::Binary loads
BEGIN { use_ok('Search::Binary')
        or diag("Can't load Search::Binary package. Check to make sure the package library is correctly listed within the path."); }
require_ok('Search::Binary');
can_ok('Search::Binary', 'binary_search');
use Search::Binary;

# Make sure Term::ProgressBar loads
BEGIN { use_ok('Term::ProgressBar')
        or diag("Can't load Term::ProgressBar package. Check to make sure the package library is correctly listed within the path."); }
require_ok('Term::ProgressBar');
use Term::ProgressBar;

# Make sure HoneyClient::Agent::Integrity::Registry::Parser loads
BEGIN { use_ok('HoneyClient::Agent::Integrity::Registry::Parser')
        or diag("Can't load HoneyClient::Agent::Integrity::Registry::Parser package. Check to make sure the package library is correctly listed within the path."); }
require_ok('HoneyClient::Agent::Integrity::Registry::Parser');
use HoneyClient::Agent::Integrity::Registry::Parser;

=end testing

=cut

#######################################################################
# Global Configuration Variables
#######################################################################

# The global logging object.
our $LOG = get_logger();

# Make Dumper format more terse.
$Data::Dumper::Terse = 1;
$Data::Dumper::Indent = 1;



sub new {
        my($class)=shift;
        ref($class)
    and $class=ref($class);

    my($self)=$class->SUPER::new( yyversion => '1.05',
                                  yystates =>
[
	{#State 0
		ACTIONS => {
			'DIR_NAME' => 2,
			'HEADER' => 5,
			'NEWLINE' => 6
		},
		DEFAULT => -1,
		GOTOS => {
			'group' => 1,
			'registry' => 3,
			'groups' => 4
		}
	},
	{#State 1
		DEFAULT => -4
	},
	{#State 2
		ACTIONS => {
			'KEY_NAME' => 7
		},
		DEFAULT => -9,
		GOTOS => {
			'entry' => 8,
			'entries' => 9
		}
	},
	{#State 3
		ACTIONS => {
			'' => 10
		}
	},
	{#State 4
		DEFAULT => -2
	},
	{#State 5
		ACTIONS => {
			'DIR_NAME' => 2,
			'NEWLINE' => 6
		},
		GOTOS => {
			'group' => 1,
			'groups' => 11
		}
	},
	{#State 6
		ACTIONS => {
			'DIR_NAME' => 2
		},
		GOTOS => {
			'group' => 12
		}
	},
	{#State 7
		ACTIONS => {
			'KEY_VALUE' => 13
		}
	},
	{#State 8
		ACTIONS => {
			'KEY_NAME' => 7
		},
		DEFAULT => -10,
		GOTOS => {
			'entry' => 8,
			'entries' => 14
		}
	},
	{#State 9
		DEFAULT => -8
	},
	{#State 10
		DEFAULT => 0
	},
	{#State 11
		DEFAULT => -3
	},
	{#State 12
		ACTIONS => {
			'DIR_NAME' => 2,
			'NEWLINE' => 16
		},
		DEFAULT => -5,
		GOTOS => {
			'group' => 1,
			'groups' => 15
		}
	},
	{#State 13
		DEFAULT => -12
	},
	{#State 14
		DEFAULT => -11
	},
	{#State 15
		DEFAULT => -7
	},
	{#State 16
		ACTIONS => {
			'DIR_NAME' => 2
		},
		DEFAULT => -6,
		GOTOS => {
			'group' => 12
		}
	}
],
                                  yyrules  =>
[
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'registry', 0,
sub
#line 247 "Parser.yp"
{
            $LOG->debug("Reached end of input stream.");
            # Finished parsing the entire file, return empty hash ref.
            return { };
        }
	],
	[#Rule 2
		 'registry', 1,
sub
#line 252 "Parser.yp"
{
            $LOG->debug("Reached end of input stream.");
            # Finished parsing the entire file, return empty hash ref.
            return { };
        }
	],
	[#Rule 3
		 'registry', 2,
sub
#line 257 "Parser.yp"
{
            $LOG->debug("Reached end of input stream.");
            # Finished parsing the entire file, return empty hash ref.
            return { };
        }
	],
	[#Rule 4
		 'groups', 1, undef
	],
	[#Rule 5
		 'groups', 2, undef
	],
	[#Rule 6
		 'groups', 3, undef
	],
	[#Rule 7
		 'groups', 3, undef
	],
	[#Rule 8
		 'group', 2,
sub
#line 274 "Parser.yp"
{
            my $ret = { };
            $_[0]->YYData->{'latest_group'}->{'key'} = $_[1];
            if (!exists($_[0]->YYData->{'latest_group'}->{'entries'})) {
                # Make sure the 'entries' key exists.
                $_[0]->YYData->{'latest_group'}->{'entries'} = [];
            }
            $ret = $_[0]->YYData->{'latest_group'};
            $_[0]->YYData->{'latest_group'} = { };
            $_[0]->YYData->{'dir_count'}++;
            $_[0]->YYAccept; # Terminate the parse, early.

            return $ret;
        }
	],
	[#Rule 9
		 'group', 1,
sub
#line 288 "Parser.yp"
{
            my $ret = { };
            $_[0]->YYData->{'latest_group'}->{'key'} = $_[1];
            if (!exists($_[0]->YYData->{'latest_group'}->{'entries'})) {
                # Make sure the 'entries' key exists.
                $_[0]->YYData->{'latest_group'}->{'entries'} = [];
            }
            $ret = $_[0]->YYData->{'latest_group'};
            $_[0]->YYData->{'latest_group'} = { };
            $_[0]->YYData->{'dir_count'}++;
            $_[0]->YYAccept; # Terminate the parse, early.

            return $ret;
        }
	],
	[#Rule 10
		 'entries', 1, undef
	],
	[#Rule 11
		 'entries', 2, undef
	],
	[#Rule 12
		 'entry', 2,
sub
#line 312 "Parser.yp"
{
            my $entry = {
                name  => $_[1],
                value => $_[2],
            };
            push(@{$_[0]->YYData->{'latest_group'}->{entries}}, $entry);
            $_[0]->YYData->{'entry_count'}++;
        }
	]
],
                                  @_);
    bless($self,$class);
}

#line 322 "Parser.yp"


#######################################################################
# Private Methods Implemented                                         #
#######################################################################

# Helper function, designed to tokenize specific data from the input stream.
#
# Inputs: parser
# Outputs: (token_id, data) pair 
sub _lexer {
    # Identify NEWLINE token.
    if ($_[0]->YYData->{DATA} =~ m/\G\n/cg) {
        $_[0]->YYData->{'in_group'} = 0;
        $LOG->debug("Found NEWLINE token ending at offset (" . pos($_[0]->YYData->{DATA}) . ").");
        $_[0]->YYData->{'line_count'}++;
        return ("NEWLINE", "\n");
    }

    # Check to see if we're inside a group block...
    if (!$_[0]->YYData->{'in_group'}) {

        $_[0]->YYData->{'input_pos'} = pos($_[0]->YYData->{DATA});
        $_[0]->YYData->{'input_pos'} = $_[0]->YYData->{'input_pos'} ?
                                       $_[0]->YYData->{'input_pos'} : 0;
        $_[0]->YYData->{'input_pos'} = $_[0]->YYData->{'input_pos'} +
                                       $_[0]->YYData->{'abs_offset'};

        # Update progress bar, if defined.
        if (defined($_[0]->YYData->{'progress'}) &&
            ($_[0]->YYData->{'input_pos'} > $_[0]->YYData->{'progress_next_update'})) {
            $_[0]->YYData->{'progress_next_update'} =
                $_[0]->YYData->{'progress'}->update($_[0]->YYData->{'input_pos'});
        }

        # Identify DIR_NAME token.
        if ($_[0]->YYData->{DATA} =~ m/\G\[(.*)\]\n/cg) {
            $_[0]->YYData->{'in_group'} = 1;
            $LOG->debug("Found DIR_NAME token ending at offset (" . pos($_[0]->YYData->{DATA}) . ").");
            $_[0]->YYData->{'last_group_line_number'} = $_[0]->YYData->{'line_count'};
            $_[0]->YYData->{'line_count'}++;
            return ("DIR_NAME", $1);
        }

        # Identify HEADER token. It's always only at the beginning.
        if ($_[0]->YYData->{DATA} =~ m/\GREGEDIT4\n/cg) {
            $LOG->debug("Found HEADER token ending at offset (" . pos($_[0]->YYData->{DATA}) . ").");
            $_[0]->YYData->{'line_count'}++;
            return ("HEADER", "REGEDIT4\n");
        }

    } else {

        # Check to see if we're in a value segment...
        if (!$_[0]->YYData->{'in_value'}) {

            # Identify KEY_NAME token.
            if ($_[0]->YYData->{DATA} =~ m/\G\"(|[^\\]|.*(?:\\[^\\]|\\\\|[^\\][^\\]))\"(?==)/cg) {
                $_[0]->YYData->{'in_value'} = 1;
                $LOG->debug("Found KEY_NAME token ending at offset (" . pos($_[0]->YYData->{DATA}) . ").");
                return ("KEY_NAME", $1);
            }

            # Identify default KEY_NAME token (@).
            if ($_[0]->YYData->{DATA} =~ m/\G\@(?==)/cg) {
                $_[0]->YYData->{'in_value'} = 1;
                $LOG->debug("Found KEY_NAME token ending at offset (" . pos($_[0]->YYData->{DATA}) . ").");
                return ("KEY_NAME", "@");
            }

        } else {

            # Identify string KEY_VALUE token.
            if ($_[0]->YYData->{DATA} =~ m/\G=\"(|[^\\]|.*?(?:\\[^\\]|\\\\|[^\\][^\\]))\"\n/cgs) {
                $_[0]->YYData->{'in_value'} = 0;
                $LOG->debug("Found KEY_VALUE token ending at offset (" . pos($_[0]->YYData->{DATA}) . ").");
                $_[0]->YYData->{'line_count'} += 1 + @{[$1 =~ /\n/g]};
                return ("KEY_VALUE", $1);
            }

            # Identify binary KEY_VALUE token.
            if ($_[0]->YYData->{DATA} =~ m/\G=(|.*?[^\\])\n/cgs) {
                $_[0]->YYData->{'in_value'} = 0;
                $LOG->debug("Found KEY_VALUE token ending at offset (" . pos($_[0]->YYData->{DATA}) . ").");
                $_[0]->YYData->{'line_count'} += 1 + @{[$1 =~ /\n/g]};
                return ("KEY_VALUE", $1);
            }
        }
    }
   
    # Croak if encountered a token error.
    if ($_[0]->YYData->{DATA} =~ m/\G(.*\n)/cg) {
        $_[0]->YYData->{'input_pos'} = pos($_[0]->YYData->{DATA});
        $LOG->fatal("Error: Unknown token (" . $1 . ") at offset (". $_[0]->YYData->{'input_pos'} .")");
        Carp::croak("Error: Unknown token (" . $1 . ") at offset (". $_[0]->YYData->{'input_pos'} .")");
    }
    return ('', undef);
}

# Helper function, designed to report when any parsing error
# occurs.
#
# Inputs: parser
# Outputs: None
sub _error {

    $LOG->fatal("Error: Malformed input found at offset (" . $_[0]->YYData->{'input_pos'} . ").");
    Carp::croak("Error: Malformed input found at offset (" . $_[0]->YYData->{'input_pos'} . ").");
}

# Helper function, designed to reset the parser's file stream back to the
# beginning, allowing the parser to reparse from the beginning.  Or, if
# specified, the function will seek the parser to the specified offset.
#
# Inputs: parser, absolute offset (optional)
# Outputs: none
sub _reset {
    # Extract arguments.
    my ($self, $offset) = @_;

    $LOG->debug("Resetting parser.");

    $self->YYData->{'file_handle'} = undef;

    my $fh = new IO::File($self->YYData->{'filename'}, "r");
    if (!defined($fh)) {
        $LOG->fatal("Error: Unable to read file '" . $self->YYData->{'filename'} . "'!");
        Carp::croak("Error: Unable to read file '" . $self->YYData->{'filename'} . "'!");
    }

    $self->YYData->{'file_handle'} = $fh;

    # Check the offset.
    if (!defined($offset)) {
        $offset = 0;
    }
    seek($fh, $offset, SEEK_SET);

    undef $/;
    $self->YYData->{DATA} = <$fh>;

    # Strip all CRs.
    $self->YYData->{DATA} =~ s/\r//g;

    # Total size of input file.
    $self->YYData->{'file_size'} = (stat($fh))[7];

    # Reinitialize helper variables.
    # Hashtable, to represent the latest, extracted group chunk.
    $self->YYData->{'latest_group'} = { };

    # Boolean, to indicate when we're parsing inside a group chunk.
    $self->YYData->{'in_group'} = 0;

    # Boolean, to indicate when we're parsing inside a value segment.
    $self->YYData->{'in_value'} = 0;
    
    # Regexp offset, used to record where the parser is within
    # the file (relative position).
    $self->YYData->{'input_pos'} = 0;

    # Absolute offset, recording where the parser initially seeked to.
    $self->YYData->{'abs_offset'} = $offset;

    # Initialize statistics.
    # Total number of directories parsed.
    $self->YYData->{'dir_count'} = 0;

    # Total number of key/value pairs parsed.
    $self->YYData->{'entry_count'} = 0;

    # Total number of lines parsed.
    $self->YYData->{'line_count'} = 0;

    # Last line number that corresponded to a group separation point.
    $self->YYData->{'last_group_line_number'} = 0;

    # Progress bar information.
    if ($self->YYData->{'show_progress'}) {
        $self->YYData->{'progress'} = Term::ProgressBar->new({ name  => 'Progress',
                                                               count => $self->YYData->{'file_size'},
                                                               ETA   => 'linear', });
        $self->YYData->{'progress'}->minor(0);
        $self->YYData->{'progress'}->max_update_rate(1);
        $self->YYData->{'progress_next_update'} = $self->YYData->{'progress'}->update($offset);
    } else {
        $self->YYData->{'progress'} = undef;
    }
}

# Helper function, designed to index all groups, based upon beginning file
# offsets.
#
# Inputs: parser
# Outputs: None
sub _index {
    # Extract arguments.
    my $self = shift;

    $LOG->debug("Starting group index process.");

    $self->YYData->{'group_index_offsets'} = [0, ];
    $self->YYData->{'group_index_linenums'} = [0, ];

    my $registryGroup = $self->nextGroup();
    while(scalar(keys(%{$registryGroup}))) {
        push (@{$self->YYData->{'group_index_offsets'}}, $self->YYData->{'input_pos'});
        push (@{$self->YYData->{'group_index_linenums'}}, $self->YYData->{'last_group_line_number'});
        $registryGroup = $self->nextGroup();
    }

    # Reset the parser.
    $self->_reset();

    $LOG->debug("Finished group index process.");
}

# Helper function, designed to be called from within the
# Search::Binary::binary_search() function, in order to allow
# the binary_search to properly read in group index data from
# the default parser reference.
#
# For more information about how this function operates, please
# see the Search::Binary POD documentation.
#
# Inputs: parser, value_to_compare, current_array_index
# Outputs: comparison, last_valid_array_index
sub _search {
    # Extract arguments.
    my ($parser, $value_to_compare, $current_array_index) = @_;

    # Increment the search index, if the current one is undef.
    if (defined($current_array_index)) {
        $parser->YYData->{'last_search_index'} = $current_array_index;
    } else {
        $parser->YYData->{'last_search_index'}++;
    }

    # Perform a comparison, if the array entry is defined.
    # Check to see if the search is for line numbers or offsets.
    if ($parser->YYData->{'search_is_linenum'}) {
        if (defined(@{$parser->YYData->{'group_index_linenums'}}[$parser->YYData->{'last_search_index'}])) {
            return($value_to_compare <=> @{$parser->YYData->{'group_index_linenums'}}[$parser->YYData->{'last_search_index'}],
                   $parser->YYData->{'last_search_index'});
        }
    } else {
        if (defined(@{$parser->YYData->{'group_index_offsets'}}[$parser->YYData->{'last_search_index'}])) {
            return($value_to_compare <=> @{$parser->YYData->{'group_index_offsets'}}[$parser->YYData->{'last_search_index'}],
                   $parser->YYData->{'last_search_index'});
        }
    }

    # Array entry not found, return undef with this position.
    return (undef, $parser->YYData->{'last_search_index'});
}

#######################################################################
# Public Methods Implemented                                          #
#######################################################################

=pod

=head1 METHODS IMPLEMENTED

The following functions have been implemented by any Parser object.

=head2 HoneyClient::Agent::Integrity::Registry::Parser->init(input_file => $filename,
                                                             index_groups => $perform_index,
                                                             show_progress => $progress)

=over 4

Creates a new Parser object, using the specified input file as its data
source.

I<Inputs>:
 B<$filename> is an required parameter, specifying the file to open for parsing.
 B<$perform_index> is an optional parameter.  1 specifies that the parser should go
ahead and scan the entire file, indexing the file offsets of where groups start and
end.  Otherwise, this indexing process is not performed.
 B<$progress> is an optional parameter.  1 specifies that the parser should display
a progress bar, as it scans through a specified file.  Otherwise, a progress bar
is not displayed.
 
I<Output>: The instantiated Parser B<$object>, fully initialized.

=back

=begin testing

my $test_registry_file = $ENV{PWD} . "/" . getVar(name      => "registry_file",
                                                  namespace => "HoneyClient::Agent::Integrity::Registry::Parser::Test");

# Create a generic Parser object, with test state data.
my $parser = HoneyClient::Agent::Integrity::Registry::Parser->init(input_file => $test_registry_file);
isa_ok($parser, 'HoneyClient::Agent::Integrity::Registry::Parser', "init(input_file => $test_registry_file)") or diag("The init() call failed.");

=end testing

=cut

sub init {

    # Extract arguments.
    my ($self, %args) = @_;

    # Log resolved arguments.
    $LOG->debug(sub {
        # Make Dumper format more terse.
        $Data::Dumper::Terse = 1;
        $Data::Dumper::Indent = 0;
        Dumper(\%args);
    });

    # Sanity check, don't initialize, unless input_file_handle
    # was provided.
    my $argsExist = scalar(%args);
    if (!$argsExist ||
        !exists($args{'input_file'}) ||
        !defined($args{'input_file'})) {
        $LOG->fatal("Error: Unable to create parser - no 'input_file' specified!");
        Carp::croak("Error: Unable to create parser - no 'input_file' specified!");
    }

    my $parser = HoneyClient::Agent::Integrity::Registry::Parser->new();
    my $fh = new IO::File($args{'input_file'}, "r");
    if (!defined($fh)) {
        $LOG->fatal("Error: Unable to read file '" . $args{'input_file'} . "'!");
        Carp::croak("Error: Unable to read file '" . $args{'input_file'} . "'!");
    }
    
    # Check if show progress was specified.
    if ($argsExist && 
        exists($args{'show_progress'}) && 
        defined($args{'show_progress'}) &&
        $args{'show_progress'}) {
        $parser->YYData->{'show_progress'} = 1;
    } else {
        $parser->YYData->{'show_progress'} = 0;
    }

    # Save the file name.
    $parser->YYData->{'filename'} = $args{'input_file'};

    # Save the file handle.
    $parser->YYData->{'file_handle'} = $fh;

    # Reset the parser.
    $parser->_reset();

    # Perform group indexing, if specified.
    if ($argsExist && 
        exists($args{'index_groups'}) && 
        defined($args{'index_groups'}) &&
        $args{'index_groups'}) {
        $parser->_index();
    } else {
        $parser->YYData->{'group_index_offsets'} = [0, ];
        $parser->YYData->{'group_index_linenums'} = [0, ];
    }

    # Return parser object.
    return $parser;
}

=pod

=head2 $object->nextGroup()

=over 4

Provides the next registry group, in the form of a hashtable reference.
This hashtable has the following format:

  {
      # The registry directory name.
      'key' => 'HKEY_LOCAL_MACHINE\Software...',
  
      # An array containing the list of entries within the
      # registry directory.
      'entries'  => [ {
          'name' => "\"string\"",  # A (potentially) quoted string; 
                                   # "@" for default
          'value' => "data",
      }, ],
  };

I<Output>: A hashtable reference if the next group was parsed successfully;
returns an empty hash ref, if the Parser B<$object> has reached the end of
the input stream.

=back

=begin testing

my ($nextGroup, $expectedGroup);
my $test_registry_file = $ENV{PWD} . "/" . getVar(name      => "registry_file",
                                                  namespace => "HoneyClient::Agent::Integrity::Registry::Parser::Test");

# Create a generic Parser object, with test state data.
my $parser = HoneyClient::Agent::Integrity::Registry::Parser->init(input_file => $test_registry_file, index_groups => 1);

# Verify Test Group #1
$nextGroup = $parser->nextGroup();
$expectedGroup = {
    key     => 'HKEY_CURRENT_USER\]Testing Group 1[',
    entries => [ {
        name  => '@',
        value => 'Default',
    }, {
        name  => 'Foo',
        value => 'Bar',
    }, ],
};
is_deeply($nextGroup, $expectedGroup, "nextGroup() - 1") or diag("The nextGroup() call failed.");

# Verify Test Group #2
$nextGroup = $parser->nextGroup();
$expectedGroup = {
    key     => 'HKEY_CURRENT_USER\Testing Group 2',
    entries => [ {
        name  => '@',
        value => '\\"Annoying=Value\\"',
    }, {
        name  => '\\"Annoying=Key\\"',
        value => 'Bar',
    }, {
        name  => 'Multiline',
        value => 'This
value spans
multiple lines
',
    }, {
        name  => 'Sane_Key',
        value => '\\"Wierd=\\"Value',
    }, ],
};
is_deeply($nextGroup, $expectedGroup, "nextGroup() - 2") or diag("The nextGroup() call failed.");

# Verify Test Group #3
$nextGroup = $parser->nextGroup();
$expectedGroup = {
    key     => 'HKEY_CURRENT_USER\Testing Group 3',
    entries => [ {
        name  => 'Test_Bin_1',
        value => 'hex:f4,ff,ff,ff,00,00,00,00,00,00,00,00,00,00,00,00,bc,02,00,00,00,\
  00,00,00,00,00,00,00,54,00,61,00,68,00,6f,00,6d,00,61,00,00,00,f0,77,3f,00,\
  3f,00,3f,00,3f,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,78,00,1c,10,fc,\
  7f,22,14,fc,7f,b0,fe,12,00,00,00,00,00,00,00,00,00,98,23,eb,77'
    }, {
        name  => 'Test_Bin_2',
        value => 'hex:f5,ff,ff,ff,00,00,00,00,00,00,00,00,00,00,00,00,90,01,00,00,00,\
  00,00,00,00,00,00,00,4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,\
  20,00,53,00,61,00,6e,00,73,00,20,00,53,00,65,00,72,00,69,00,66,00,00,00,f0,\
  77,00,20,14,00,00,00,00,10,80,05,14,00,f0,1f,14,00,00,00,14,00'
    }, ],
};
is_deeply($nextGroup, $expectedGroup, "nextGroup() - 3") or diag("The nextGroup() call failed.");

# Verify Test Group #4
$nextGroup = $parser->nextGroup();
$expectedGroup = {
    key     => 'HKEY_CURRENT_USER\Testing Group 4',
    entries => [],
};
is_deeply($nextGroup, $expectedGroup, "nextGroup() - 4") or diag("The nextGroup() call failed.");

# Verify Test Group #5
$nextGroup = $parser->nextGroup();
$expectedGroup = {
    key     => 'HKEY_CURRENT_USER\Testing Group 5',
    entries => [ {
        name  => '@',
        value => '',
    }, ],
};
is_deeply($nextGroup, $expectedGroup, "nextGroup() - 5") or diag("The nextGroup() call failed.");

# Verify Test Group #6
$nextGroup = $parser->nextGroup();
$expectedGroup = {
    key     => 'HKEY_CURRENT_USER\Testing Group 6\With\Really\Deep\Nested\Directory\Structure',
    entries => [ {
        name  => 'InstallerLocation',
        value => 'C:\\\\WINDOWS\\\\system32\\\\',
    }, ],
};
is_deeply($nextGroup, $expectedGroup, "nextGroup() - 6") or diag("The nextGroup() call failed.");

# Verify Test Group #7
$nextGroup = $parser->nextGroup();
$expectedGroup = {
    key     => 'HKEY_CURRENT_USER\Testing Group 7',
    entries => [ {
        name  => 'C:\\\\Program Files\\\\Common Files\\\\Microsoft Shared\\\\Web Folders\\\\',
        value => '',
    }, {
        name  => 'C:\\\\WINDOWS\\\\Installer\\\\{350C97B0-3D7C-4EE8-BAA9-00BCB3D54227}\\\\',
        value => '',
    }, {
        name  => 'C:\\\\Program Files\\\\Support Tools\\\\',
        value => '',
    }, {
        name  => 'C:\\\\Documents and Settings\\\\All Users\\\\Start Menu\\\\Programs\\\\Windows Support Tools\\\\',
        value => '',
    }, {
        name  => 'C:\\\\WINDOWS\\\\Installer\\\\{6855CCDD-BDF9-48E4-B80A-80DFB96FE36C}\\\\',
        value => '',
    }, {
        name  => 'C:\\\\WINDOWS\\\\Installer\\\\{F251B999-08A9-4704-999C-9962F0DFD88E}\\\\',
        value => '',
    }, {
        name  => 'C:\\\\WINDOWS\\\\Installer\\\\{1CB92574-96F2-467B-B793-5CEB35C40C29}\\\\',
        value => '',
    }, {
        name  => 'C:\\\\WINDOWS\\\\Installer\\\\{B37C842A-B624-46B8-A727-654E72F1C91A}\\\\',
        value => '',
    }, ],
};
is_deeply($nextGroup, $expectedGroup, "nextGroup() - 7") or diag("The nextGroup() call failed.");

# Verify Test Group #8
$nextGroup = $parser->nextGroup();
$expectedGroup = {
    key     => 'HKEY_CURRENT_USER\Testing Group 8\{00021492-0000-0000-C000-000000000046}',
    entries => [ {
        name  => '000',
        value => 'String Value',
    }, ],
};
is_deeply($nextGroup, $expectedGroup, "nextGroup() - 8") or diag("The nextGroup() call failed.");

# Verify Test Group #9
$nextGroup = $parser->nextGroup();
is_deeply($nextGroup, { }, "nextGroup() - 9") or diag("The nextGroup() call failed.");

=end testing

=cut

sub nextGroup {
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

    # Reopen the file_handle, if it's been closed.
    if (!defined($self->YYData->{'file_handle'})) {
        $self->_reset();   
    }

    if ($self->YYData->{'input_pos'} == 0) {
        $LOG->debug("Beginning parse of input stream.");
    }

    # Update progress bar, if defined.
    if (defined($_[0]->YYData->{'progress'}) &&
        ($_[0]->YYData->{'file_size'} <= $_[0]->YYData->{'progress_next_update'})) {

        $_[0]->YYData->{'progress'}->update($_[0]->YYData->{'file_size'});
    }

    # Return the next group parsed.
    return $self->YYParse(yylex   => \&_lexer,
                          yyerror => \&_error);
}

=pod

=head2 $object->dirsParsed()

=over 4

Indicates how many registry directories the Parser B<$object> has
parsed within the specified file, so far.

I<Output>: Returns the number of directory groups parsed so far;
returns 0, if none parsed yet.

=back

=begin testing

my ($nextGroup);
my $test_registry_file = $ENV{PWD} . "/" . getVar(name      => "registry_file",
                                                  namespace => "HoneyClient::Agent::Integrity::Registry::Parser::Test");

# Create a generic Parser object, with test state data.
my $parser = HoneyClient::Agent::Integrity::Registry::Parser->init(input_file => $test_registry_file);

$nextGroup = $parser->nextGroup();
while(scalar(keys(%{$nextGroup}))) {
    $nextGroup = $parser->nextGroup();
}

is($parser->dirsParsed(), 8, "dirsParsed()") or diag("The dirsParsed() call failed.");

=end testing

=cut

sub dirsParsed {
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

    return $self->YYData->{'dir_count'}; 
}

=pod

=head2 $object->entriesParsed()

=over 4

Indicates how many registry key/value pairs the Parser B<$object> has
parsed within the specified file, so far.

I<Output>: Returns the number of key/value pairs parsed so far;
returns 0, if none parsed yet.

=back

=begin testing

my ($nextGroup);
my $test_registry_file = $ENV{PWD} . "/" . getVar(name      => "registry_file",
                                                  namespace => "HoneyClient::Agent::Integrity::Registry::Parser::Test");

# Create a generic Parser object, with test state data.
my $parser = HoneyClient::Agent::Integrity::Registry::Parser->init(input_file => $test_registry_file);

$nextGroup = $parser->nextGroup();
while(scalar(keys(%{$nextGroup}))) {
    $nextGroup = $parser->nextGroup();
}

is($parser->entriesParsed(), 19, "entriesParsed()") or diag("The entriesParsed() call failed.");

=end testing

=cut

sub entriesParsed {
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

    return $self->YYData->{'entry_count'}; 
}

=pod

=head2 $object->getFileHandle()

=over 4

Returns the file handle associated with the current Parser B<$object>.

I<Output>: Returns the file handle in use.

=back

=begin testing

my ($handle);
my $test_registry_file = $ENV{PWD} . "/" . getVar(name      => "registry_file",
                                                  namespace => "HoneyClient::Agent::Integrity::Registry::Parser::Test");

# Create a generic Parser object, with test state data.
my $parser = HoneyClient::Agent::Integrity::Registry::Parser->init(input_file => $test_registry_file);

$handle = $parser->getFileHandle();

isa_ok($handle, 'IO::File', "getFileHandle()") or diag("The getFileHandle() call failed.");

=end testing

=cut

sub getFileHandle {
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

    return $self->YYData->{'file_handle'}; 
}

=pod

=head2 $object->getFilename()

=over 4

Returns the file name associated with the current Parser B<$object>.

I<Output>: Returns the file name in use.

=back

=begin testing

my ($filename);
my $test_registry_file = $ENV{PWD} . "/" . getVar(name      => "registry_file",
                                                  namespace => "HoneyClient::Agent::Integrity::Registry::Parser::Test");

# Create a generic Parser object, with test state data.
my $parser = HoneyClient::Agent::Integrity::Registry::Parser->init(input_file => $test_registry_file);

$filename = $parser->getFilename();

is($filename, $test_registry_file, "getFilename()") or diag("The getFilename() call failed.");

=end testing

=cut

sub getFilename {
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

    return $self->YYData->{'filename'}; 
}

=pod

=head2 $object->closeFileHandle()

=over 4

Closes the file handle associated with the current Parser B<$object>.

=back

=begin testing

my ($handle);
my $test_registry_file = $ENV{PWD} . "/" . getVar(name      => "registry_file",
                                                  namespace => "HoneyClient::Agent::Integrity::Registry::Parser::Test");

# Create a generic Parser object, with test state data.
my $parser = HoneyClient::Agent::Integrity::Registry::Parser->init(input_file => $test_registry_file);
$parser->closeFileHandle();

# Verify Test Group #1
my $nextGroup = $parser->nextGroup();
my $expectedGroup = {
    key     => 'HKEY_CURRENT_USER\]Testing Group 1[',
    entries => [ {
        name  => '@',
        value => 'Default',
    }, {
        name  => 'Foo',
        value => 'Bar',
    }, ],
};
is_deeply($nextGroup, $expectedGroup, "closeFileHandle()") or diag("The closeFileHandle() call failed.");

=end testing

=cut

sub closeFileHandle {
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

    $self->YYData->{'file_handle'} = undef; 
}

=pod

=head2 $object->getCurrentLineCount()

=over 4

Returns the number of lines parsed by the Parser B<$object> 
within the specified file and resets the counter back to
zero.

I<Output>: Returns the current line count of the parser.

B<Note>: Calling this function will reset the parser's
line count.

=back

=begin testing

my ($handle);
my $test_registry_file = $ENV{PWD} . "/" . getVar(name      => "registry_file",
                                                  namespace => "HoneyClient::Agent::Integrity::Registry::Parser::Test");

# Create a generic Parser object, with test state data.
my $parser = HoneyClient::Agent::Integrity::Registry::Parser->init(input_file => $test_registry_file, index_groups => 1);

$parser->seekToNearestGroup(absolute_offset => 84);
my $nextGroup = $parser->nextGroup();

is($parser->getCurrentLineCount(), 9, "getCurrentLineCount()") or diag("The getCurrentLineCount() call failed.");

=end testing

=cut

sub getCurrentLineCount {
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

    my $ret = $self->YYData->{'line_count'};
    $self->YYData->{'line_count'} = 0;
    return $ret;
}

=pod

=head2 $object->seekToNearestGroup(absolute_offset => $offset, absolute_linenum => $linenum, adjust_index => $index)

=over 4

Given an absolute offset or line number within the file, this function
will seek the parser to the nearest group found B<before>
the specified offset.

I<Inputs>:
 B<$offset> is an required parameter, specifying the absolute offset
within the file to seek to.
 B<$linenum> is a required parameter, specifying the absolute line
number within the file to seek to.
 B<$index> is an optional parameter, specifying to seek to a group
before or after the target group.  If unspecified, $index = 0.

I<Outputs>: None.

B<Notes>: Either B<$offset> or B<$linnum> must be specified.  To seek to the
target group, specify $index = 0 or leave undefined.  To seek to the previous
group before the target group, specify $index = -1.  To seek to the next
group after the target group, specify $index = 1.

Once called, B<all> corresponding statistical counters will be reset.  This means,
that the output from $object->dirsParsed() and $object->entriesParsed() will be
zero, if called immediately after this function.

=back

=begin testing

my ($nextGroup, $expectedGroup);
my $test_registry_file = $ENV{PWD} . "/" . getVar(name      => "registry_file",
                                                  namespace => "HoneyClient::Agent::Integrity::Registry::Parser::Test");

# Create a generic Parser object, with test state data.
my $parser = HoneyClient::Agent::Integrity::Registry::Parser->init(input_file => $test_registry_file, index_groups => 1);

# Verify Test Group #2
$expectedGroup = {
    key     => 'HKEY_CURRENT_USER\Testing Group 2',
    entries => [ {
        name  => '@',
        value => '\\"Annoying=Value\\"',
    }, {
        name  => '\\"Annoying=Key\\"',
        value => 'Bar',
    }, {
        name  => 'Multiline',
        value => 'This
value spans
multiple lines
',
    }, {
        name  => 'Sane_Key',
        value => '\\"Wierd=\\"Value',
    }, ],
};
is($parser->seekToNearestGroup(absolute_offset => 84), 73, "seekToNearestGroup(absolute_offset => 84)") or diag("The seekToNearestGroup() call failed.");
$nextGroup = $parser->nextGroup();
is_deeply($nextGroup, $expectedGroup, "seekToNearestGroup(absolute_offset => 84)") or diag("The seekToNearestGroup() call failed.");

is($parser->seekToNearestGroup(absolute_linenum => 7), 6, "seekToNearestGroup(absolute_linenum => 7)") or diag("The seekToNearestGroup() call failed.");
$nextGroup = $parser->nextGroup();
is_deeply($nextGroup, $expectedGroup, "seekToNearestGroup(absolute_linenum => 7)") or diag("The seekToNearestGroup() call failed.");

# Verify Test Group #3
$expectedGroup = {
    key     => 'HKEY_CURRENT_USER\Testing Group 3',
    entries => [ {
        name  => 'Test_Bin_1',
        value => 'hex:f4,ff,ff,ff,00,00,00,00,00,00,00,00,00,00,00,00,bc,02,00,00,00,\
  00,00,00,00,00,00,00,54,00,61,00,68,00,6f,00,6d,00,61,00,00,00,f0,77,3f,00,\
  3f,00,3f,00,3f,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,78,00,1c,10,fc,\
  7f,22,14,fc,7f,b0,fe,12,00,00,00,00,00,00,00,00,00,98,23,eb,77'
    }, {
        name  => 'Test_Bin_2',
        value => 'hex:f5,ff,ff,ff,00,00,00,00,00,00,00,00,00,00,00,00,90,01,00,00,00,\
  00,00,00,00,00,00,00,4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,\
  20,00,53,00,61,00,6e,00,73,00,20,00,53,00,65,00,72,00,69,00,66,00,00,00,f0,\
  77,00,20,14,00,00,00,00,10,80,05,14,00,f0,1f,14,00,00,00,14,00'
    }, ],
};

is($parser->seekToNearestGroup(absolute_offset => 301), 234, "seekToNearestGroup(absolute_offset => 301)") or diag("The seekToNearestGroup() call failed.");
$nextGroup = $parser->nextGroup();
is_deeply($nextGroup, $expectedGroup, "seekToNearestGroup(absolute_offset => 301)") or diag("The seekToNearestGroup() call failed.");

is($parser->seekToNearestGroup(absolute_linenum => 16), 15, "seekToNearestGroup(absolute_linenum => 16)") or diag("The seekToNearestGroup() call failed.");
$nextGroup = $parser->nextGroup();
is_deeply($nextGroup, $expectedGroup, "seekToNearestGroup(absolute_linenum => 16)") or diag("The seekToNearestGroup() call failed.");

is($parser->seekToNearestGroup(absolute_linenum => 26, adjust_index => -1), 15, "seekToNearestGroup(absolute_linenum => 26, adjust_index => -1)") or diag("The seekToNearestGroup() call failed.");
$nextGroup = $parser->nextGroup();
is_deeply($nextGroup, $expectedGroup, "seekToNearestGroup(absolute_linenum => 26, adjust_index => -1)") or diag("The seekToNearestGroup() call failed.");

# Verify Test Group #4
$expectedGroup = {
    key     => 'HKEY_CURRENT_USER\Testing Group 4',
    entries => [],
};

is($parser->seekToNearestGroup(absolute_offset => 898), 881, "seekToNearestGroup(absolute_offset => 898)") or diag("The seekToNearestGroup() call failed.");
$nextGroup = $parser->nextGroup();
is_deeply($nextGroup, $expectedGroup, "seekToNearestGroup(absolute_offset => 898)") or diag("The seekToNearestGroup() call failed.");

is($parser->seekToNearestGroup(absolute_linenum => 26), 25, "seekToNearestGroup(absolute_linenum => 26)") or diag("The seekToNearestGroup() call failed.");
$nextGroup = $parser->nextGroup();
is_deeply($nextGroup, $expectedGroup, "seekToNearestGroup(absolute_linenum => 26)") or diag("The seekToNearestGroup() call failed.");

# Verify Test Group #8
$expectedGroup = {
    key     => 'HKEY_CURRENT_USER\Testing Group 8\{00021492-0000-0000-C000-000000000046}',
    entries => [ {
        name  => '000',
        value => 'String Value',
    }, ],
};
is($parser->seekToNearestGroup(absolute_offset => 898, adjust_index => 99), 1674, "seekToNearestGroup(absolute_offset => 898, adjust_index => 99)") or diag("The seekToNearestGroup() call failed.");
$nextGroup = $parser->nextGroup();
is_deeply($nextGroup, $expectedGroup, "seekToNearestGroup(absolute_offset => 898, adjust_index => 99)") or diag("The seekToNearestGroup() call failed.");

# Verify Test Group #1
$expectedGroup = {
    key     => 'HKEY_CURRENT_USER\]Testing Group 1[',
    entries => [ {
        name  => '@',
        value => 'Default',
    }, {
        name  => 'Foo',
        value => 'Bar',
    }, ],
};
is($parser->seekToNearestGroup(absolute_offset => 898, adjust_index => -99), 0, "seekToNearestGroup(absolute_offset => 898, adjust_index => -99)") or diag("The seekToNearestGroup() call failed.");
$nextGroup = $parser->nextGroup();
is_deeply($nextGroup, $expectedGroup, "seekToNearestGroup(absolute_offset => 898, adjust_index => -99)") or diag("The seekToNearestGroup() call failed.");

=end testing

=cut

sub seekToNearestGroup {
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

    # Sanity check, don't continue, unless absolute_offset or absolute_linennum
    # was provided.
    my $argsExist = scalar(%args);
    if (!$argsExist) {
        $LOG->fatal("Error: Unable to seek parser - no 'absolute_offset' or 'absolute_linenum' specified!");
        Carp::croak("Error: Unable to seek parser - no 'absolute_offset' or 'absolute_linenum' specified!");
    }

    # Check if adjust_index was provided.
    my $adjust_index = 0;
    if (exists($args{'adjust_index'})) {
        if(!defined($args{'adjust_index'})) {
            $LOG->fatal("Error: Unable to seek parser - invalid 'adjust_index' specified!");
            Carp::croak("Error: Unable to seek parser - invalid 'adjust_index' specified!");
        } else {
            $adjust_index = $args{'adjust_index'};
        }
    }
 
    # Define helper variables. 
    my $search_arrayref = undef;
    my $search_target = undef;

    # Specify the search type.
    $self->YYData->{'search_is_linenum'} = 0;

    # Check if absolute_offset was provided. 
    if (exists($args{'absolute_offset'})) { 
        if (!defined($args{'absolute_offset'})) {
            $LOG->fatal("Error: Unable to seek parser - no 'absolute_offset' or 'absolute_linenum' specified!");
            Carp::croak("Error: Unable to seek parser - no 'absolute_offset' or 'absolute_linenum' specified!");
        }
        $search_arrayref = $self->YYData->{'group_index_offsets'};
        $search_target = $args{'absolute_offset'};
    } else {
    # Check if absolute_linenum was provided.
        if (!defined($args{'absolute_linenum'})) {
            $LOG->fatal("Error: Unable to seek parser - no 'absolute_offset' or 'absolute_linenum' specified!");
            Carp::croak("Error: Unable to seek parser - no 'absolute_offset' or 'absolute_linenum' specified!");
        }
        $search_arrayref = $self->YYData->{'group_index_linenums'};
        $search_target = $args{'absolute_linenum'};
        $self->YYData->{'search_is_linenum'} = 1;
    }

    # Final sanity check.
    if (!defined($search_target)) {
        $LOG->fatal("Error: Unable to seek parser - no 'absolute_offset' or 'absolute_linenum' specified!");
        Carp::croak("Error: Unable to seek parser - no 'absolute_offset' or 'absolute_linenum' specified!");
    }

    # Check to see if the $search_arrayref has been initialized.
    # We assume that if it has [0, ], then this has not been
    # done.
    my $numIndices = scalar(@{$search_arrayref});
    if ($numIndices < 2) {
        $self->_index();
    }
    $numIndices = scalar(@{$search_arrayref});

    # Find the nearest index after the offset.
    my $found_index = binary_search(0, $numIndices - 1, $search_target, \&_search, $self);

    # Now, find the nearest index before the offset.
    if ($found_index > 0) {
        $found_index--;
        # Adjust the index, if specified.
        if ($found_index > 0) {
            my $test_index = ($found_index + $adjust_index);
            # Make sure the adjustment doesn't exceed the min or max.
            if ($test_index >= $numIndices) {
                $found_index = $numIndices - 1;
            } elsif ($test_index < 0) {
                $found_index = 0;
            } else {
                $found_index = $test_index;
            }
        }
    }

    my $found_offset = @{$self->YYData->{'group_index_offsets'}}[$found_index];

    # Seek the parser, to the specified offset.
    $self->_reset($found_offset);
   
    if($self->YYData->{'search_is_linenum'}) {
        my $found_linenum = @{$self->YYData->{'group_index_linenums'}}[$found_index];
        $LOG->debug("Seeking parser to nearest earlier group line number (" . $found_linenum . ").");
        return $found_linenum;
    } else {
        $LOG->debug("Seeking parser to nearest earlier group offset (" . $found_offset . ").");
        return $found_offset;
    }
}

#######################################################################
# Additional Module Documentation                                     #
#######################################################################

=head1 BUGS & ASSUMPTIONS

The Parser B<$object> expects to scan the specified file as an input stream.
Subsequent calls to $object->nextGroup() will advance the parser through
the input stream.

=head1 SEE ALSO

L<http://www.honeyclient.org/trac>

=head1 REPORTING BUGS

L<http://www.honeyclient.org/trac/newticket>

=head1 ACKNOWLEDGEMENTS

Francois Desarmenien E<lt>francois@fdesar.netE<gt> for his
work in developing the Parse::Yapp module.

=head1 AUTHORS

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

1;
