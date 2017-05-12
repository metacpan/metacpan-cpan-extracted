package Goo::ThereDocManager;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::ThereDocManager.pm
# Description:  Process very simple ThereDocs --- looking for Things!
#
# Date          Change
# -----------------------------------------------------------------------------
# 16/08/2005    Auto generated file
# 16/08/2005    Needed a way to jump from Here to There
# 23/10/2005    Created test file: ThereDocManagerTest.tpm
#
###############################################################################

use strict;

use Goo::Object;
use Goo::Loader;
use Goo::Prompter;
use Goo::ThingFinder;
use Goo::FileUtilities;

use base qw(Goo::Object);

# what is a there doc?
my $default_mode = "E";


###############################################################################
#
# find_there_doc - find the line where the there_doc is found
#
###############################################################################

sub find_there_doc {

    my ($this, $filename) = @_;

    my $line_count  = 0;
    my $target_line = 0;     # which line has a ThereDoc
    my $target      = "";    # the string to target
    my $mode        = "";    # the action mode

    my @new_lines;

    # go through each line looking for ThereDocs
    foreach my $line (Goo::FileUtilities::get_file_as_lines($filename)) {

        $line_count++;

        # match the ThereDoc   a <<a
        if ($line =~ /([a-zA-Z\>])\>\>(.*)$/) {

            # what is the ThereDoc \>\>\> pointing to?
            $mode        = uc($1);
            $target      = $2;
            $target_line = $line_count;

            # default to edit mode
            if ($mode eq ">") { $mode = "E"; }

            # remove the theredoc from the line
            $line =~ s/[a-zA-Z\>]\>\>//;

        }

        # keep all the lines
        push(@new_lines, $line);

    }

    # the lines should no longer contain ThereDocs
    Goo::FileUtilities::write_lines_as_file($filename, @new_lines);

    # return the line_count and target of the last ThereDoc
    return ($mode, $target, $target_line);

}


###############################################################################
#
# process - given a string, look for there_docs and then do things if you
#           find one!
#
###############################################################################

sub process {

    my ($this, $full_path) = @_;

    # find the ThereDoc in the document
    my ($mode, $target_string, $theredoc_line_number) = $this->find_there_doc($full_path);

    # look for any Things in the  target
    my @things = Goo::ThingFinder::get_things($target_string);

    if (scalar(@things) > 1) {

        # we found some Things - pick one
        @things = Goo::Prompter::pick_one("Which Thing?", @things);
    }

    # if we found something
    if (scalar(@things) == 1) {
        return ($theredoc_line_number, Goo::Loader::load(pop(@things)), $mode);
    }

    #else {
    #    # assume we're talking about the current Thing
    #    return ($theredoc_line_number, Goo::Loader::load($full_path), $mode);
    #}

}

1;


__END__

=head1 NAME

Goo::ThereDocManager - Process very simple ThereDocs --- looking for Things!

=head1 SYNOPSIS

use Goo::ThereDocManager;

=head1 DESCRIPTION

ThereDocs enable you to jump quickly from one Thing to another Thing while editing.
Use a ThereDoc when you want to jump to "There".

=head1 METHODS

=over

=item find_there_doc

find the line where the ThereDoc is found

=item process

given a string, look for ThereDocs and then do the appropriate action

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

