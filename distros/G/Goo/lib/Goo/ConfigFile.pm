package Goo::ConfigFile;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::ConfigFile.pm
# Description:  Goo Config - parse .goo files. Based loosely on .ini files.
#               We want # comments and fields = values
#
# Date          Change
# -----------------------------------------------------------------------------
# 30/07/2005    Realised this was not going to be good enough
# 17/10/2005    Added method: getProgram
#
###############################################################################

use strict;

use File::Find;
use Goo::List;
use Goo::Object;
use Data::Dumper;
use Goo::Prompter;
use Goo::FileUtilities;
use base qw(Goo::Object);

my $GOO_ROOT = "$ENV{HOME}/.goo/things";


###############################################################################
#
# new - return a goo_config_file
#
###############################################################################

sub new {

    my ($class, $filename) = @_;

    # strip the path
    $filename =~ s/.*\///;

    my $this = $class->SUPER::new();

    unless ($filename =~ /\.goo$/) {
        die("Invalid Goo config file. $filename must end with .goo.");
    }

    my $full_path = $GOO_ROOT . '/goo/' . $filename;

    unless (-e $full_path) {
        Goo::Prompter::say("No Goo configuration file found for $full_path.");
        Goo::Prompter::say("To make a new type of Thing enter: goo -m $filename.");
        exit;
    }

    $this->parse($full_path);

    return $this;

}


###############################################################################
#
# get_action_handler - return the handler for this command
#
###############################################################################

sub get_action_handler {

    my ($this, $command) = @_;

    # return the action handler for this command
    return $this->{commands}->{$command};

}


###############################################################################
#
# has_locations - does it have any
#
###############################################################################

sub has_locations {

    my ($this) = @_;

    # return the locations for this Thing!
    return ref($this->{locations}) eq "ARRAY";

}


###############################################################################
#
# get_locations - return a list of all the locations of the config file
#
###############################################################################

sub get_locations {

    my ($this) = @_;

    # return the locations for this Thing!
    return @{ $this->{locations} }
        if ($this->has_locations());

    # other return nothing
    return undef;

}


###############################################################################
#
# parse - slurp in a file and parse it
#
###############################################################################

sub parse {

    my $this      = shift;    # ARG1: get object reference
    my $full_path = shift;    # ARG2: get full path to *.goo cfg file

    my @locations;

    my $location_finder = sub {    # define anonymous sub
                                   # for File::Find
        my $subdir = $File::Find::name;    # memoize current file
        push @locations, $subdir if (-d $subdir);    # add if directory

    };

    # parse the config file line by line
    for my $line (Goo::FileUtilities::get_file_as_lines($full_path)) {
        next
            if ($line =~ /^\s*\#/ or                     # skip commented out or
                $line =~ /^\s*$/);                                    # empty lines

        # strip whitespace
        $line =~ s/\s*=\s*/=/;
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;

        # split out key value pairs
        my ($field, $value) = split(/=/, $line);

        if ($field =~ /location/) {

            # field is a location entry
            $value = "$ENV{HOME}/.goo/$value"
                if ($value !~ /^\//);    # prepend ~/.goo if relative path
            $value = "$ENV{HOME}/.goo" if ($value eq '~');    # put in ~/.goo if "tilde" given
            &find($location_finder, $value);              # recursive directory finder

        } elsif ($field =~ /\[(.)\]/) {                   # field is a command
            my $letter = $1;                              # match the command letter

            if ($letter !~ /[A-Z\d]/) {
                die("Invalid command [$letter] in config file: $full_path. Commands must be uppercase."
                   );
            }

            # [E]dit = $this->{actions}->{E}->{command} = "[E]dit";
            $this->{actions}->{$letter}->{command} = $field;

            # [E]dit = $this->{actions}->{E}->{action}  = "ProgramEditor";
            $this->{actions}->{$letter}->{action} = $value;

            # remember the full command string too
            $this->{commands}->{$field} = $value;

        } else {
            $this->{$field} = $value;
        }
    }

    # make sure we only have unique locations
    if (scalar(@locations) > 0) {

        my @unique_list = Goo::List::get_unique(@locations);
        $this->{locations} = \@unique_list;

    }

}


###############################################################################
#
# write_to_file - very simple writer for single key value additions
#
###############################################################################

sub write_to_file {

    my ($filename, $key, $value) = @_;

    my $full_path = $GOO_ROOT . "/" . $filename;

    # get all the lines that don't match the key
    my @lines = grep { $_ !~ /^$key/ } Goo::FileUtilities::get_file_as_lines($full_path);

    # add the new value for the key
    push(@lines, "$key \t = \t $value \n");

    # save the file
    Goo::FileUtilities::write_lines_as_file($full_path, @lines);

}


###############################################################################
#
# get_program - return the program that handles an action
#
###############################################################################

sub get_program {

    my ($this, $letter) = @_;

    return $this->{actions}->{$letter}->{action};

}


###############################################################################
#
# get_commands - return all the commands for this config file
#
###############################################################################

sub get_commands {

    my ($this) = @_;

    return keys %{ $this->{commands} };

}


###############################################################################
#
# has_table - does it have a database "table"
#
###############################################################################

sub has_table {

    my ($this) = @_;

    # has a table field been defined for this Thing?
    return exists $this->{table};

}

1;



__END__

=head1 NAME

Goo::ConfigFile - Parse and load .goo files. Based loosely on .ini files.

=head1 SYNOPSIS

use Goo::ConfigFile;

=head1 DESCRIPTION

All Things have a corresponding ".goo" file based on their file suffix. Perl modules, for example, have the configuration
file "pm.goo", scripts "pl.goo", Javascript files "js.goo", log files "log.goo" and Goo configuration files "goo.goo". 

All .goo files are stored in the user's home directory: ~/.goo/things/goo/.

A .goo configuration file includes a list of actions (e.g., E[X]it) and an action handler (e.g., Exiter.pm). For
file-based Things (see Goo::FileThing) the configuration file includes a "location" field(s) where Things of this type can
be found.

For database Things (see Goo::DatabaseThing) the configuration file includes a "table" field where Things of this type can
be found.

Each action specified in .goo file contain an action letter in square brackets (e.g., [E]dit). This letter can be used 
directly on the command line to invoke the action handler on the Thing (e.g., goo -e Object.pm). 


=head1 METHODS

=over

=item new

constructor

=item get_action_handler

return the action handler for a given command

=item has_locations

does it have any directory locations?

=item get_locations

return a list of all the directory locations found in the config file

=item parse

slurp in a .goo config file and parse it

=item write_to_file

very simplistic writer for single key value additions

=item get_program

return the program that handles an action

=item get_commands

return all the commands for this config file

=item has_table

does it have a database "table"?

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

