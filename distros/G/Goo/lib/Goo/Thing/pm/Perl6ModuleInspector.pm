#!/usr/bin/perl

package Goo::Thing::pm::Perl6ModuleInspector;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2003
# All rights reserved
#
# Author:       Nigel Hamilton
# Filename:     Perl6ModuleInspector.pm
# Description:  Generate documentation on a perl file based on documentation
#               standards like this file as an example
#
# Date          Change
# ----------------------------------------------------------------------------
# 22/3/2003     Version 1
#
##############################################################################

use strict;
use Goo::Object;
use Goo::Prompter;
use Goo::FileUtilities;

# use ModuleLocations;

our @ISA = ("Goo::Object");

# generate an inverted index of what programs use what
# our $usesindex = getUsesIndex


##############################################################################
#
# new - constructor
#
##############################################################################

sub new {

    my ($class, $filename) = @_;

    my $this = $class->SUPER::new();

    # append filename to the end if need be
    # if ($filename !~ /\.pm$/) { $filename .= ".pm"; }

    unless (-e $filename) { die("No file found to inspect: $filename"); }

    $this->{filename} = $filename;    # the full filename + path
    $this->{program} = Goo::FileUtilities::get_file_as_string($filename);

    return $this;

}


##############################################################################
#
# get_uses_list - return a list of all the modules that this script uses
#
##############################################################################

sub get_uses_list {

    my ($this) = @_;

    my @modules = $this->{program} =~ m/^use\s+([\w\:]+)/mg;

    # don't include strict or other pragmas
    return grep { $_ !~ /(strict|^[a-z])/ } @modules;

}


##############################################################################
#
# get_signatures - return a list of all the modules that this script uses
#
##############################################################################

sub get_signatures {

    my ($this) = @_;

    my @signatures;

    foreach my $feature qw(submethod method sub) {

        # look for anything after sub, submethod or method
        while ($this->{program} =~ m/$feature(.*?)\{/msg) {

            my $line = $1;

            # Goo::Prompter::trace("found --- $1");

            $line =~ s/\s+$//;    # strip trailing whitespace
            $line =~ s/^\s+//;    # strip leading whitespace
            $line =~ s/\{//;      # remove any opening brace

            my $method = {};

            $method->{type} = $feature;

            if ($line =~ /(.*?)[\s\(]/) {
                $method->{name} = $1;
            }

            # match anything between two parentheses
            if ($line =~ /\((.*?)\)/s) {
                $method->{parameters} = $1;
            }

            if ($line =~ /is\s+(.*)/) {
                $method->{traits} = $1;

                # strip off the is
                $line =~ s/is\s+.*//;
            }

            # match returns
            if ($line =~ /returns\s+(.*)/) {
                $method->{returns} = $1;
            }

            push(@signatures, $method);

        }

    }

    return @signatures;

}


##############################################################################
#
# get_author - return the name of the author
#
##############################################################################

sub get_author {

    my ($this) = @_;

    $this->{program} =~ m/Author:\s+(\w+)\s+(\w+)/;

    return $1 . " " . $2;

}


1;


__END__

=head1 NAME

Goo::Thing::pm::Perl6ModuleInspector - Generate documentation on a perl file based on documentation

=head1 SYNOPSIS

use Goo::Thing::pm::Perl6ModuleInspector;

=head1 DESCRIPTION



=head1 METHODS

=over

=item new

constructor

=item get_uses_list

return a list of all the modules that this script uses

=item get_signatures

return a list of the method/sub/submethod signatures

=item get_author

return the name of the author

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO
