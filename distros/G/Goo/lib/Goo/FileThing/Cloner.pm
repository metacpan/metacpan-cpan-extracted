#!/usr/bin/perl

package Goo::FileThing::Cloner;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::FileThing::Cloner.pm
# Description:  Really simple Cloner
#
# Date          Change
# -----------------------------------------------------------------------------
# 01/8/2005     Version 1
#
###############################################################################

use strict;

use Goo::Object;
use Goo::Header;
use Goo::Prompter;

use base qw(Goo::Object);


###############################################################################
#
# run - create the output file
#
###############################################################################

sub run {

    my ($this, $thing) = @_;

    unless ($thing->isa("Goo::FileThing")) {
        Goo::Prompter::say("The FileCloner can only clone a Goo::FileThing.");
        Goo::Prompter::notify("Specify a different action handler in the .goo config file.");
        return;
    }

    # show the header
    Goo::Header::show("Clone", $thing->get_filename(), $thing->get_full_path());
    Goo::Prompter::say();

    my $source_file = $thing->get_filename();

    # find out what we're cloning to ...
    my $destination_file = Goo::Prompter::ask("Clone $source_file to?");

    unless ($destination_file) {
        Goo::Prompter::notify("No Thing to clone $source_file to.");
        return;
    }

    # put the cloned Thing in the same location
    my $destination_path = $thing->get_location() . "/" . $destination_file;

    if (-e $destination_path) {

        # check if some Thing is there already?
        return
            unless (Goo::Prompter::confirm("$destination_file already exists. Continue?", "N"));
    }

    my $file_string = $thing->get_file();

    # I often want to replace the filename - default to this first time around
    my $original_text = $thing->get_prefix();

    # do find and replace
    while ($original_text = Goo::Prompter::ask("Enter text to replace?", $original_text)) {
        my $new_text = Goo::Prompter::ask("Replace $original_text with?");
        $file_string =~ s/$original_text/$new_text/g;
        $original_text = "";
    }

    Goo::Prompter::yell("Finished cloning $thing->{filename} to $destination_file.");

    if (Goo::Prompter::confirm("Save $destination_file?")) {

        # write the cloned Thing
        Goo::FileUtilities::write_file($destination_path, $file_string);
    }

}

1;


__END__

=head1 NAME

Goo::FileThing::Cloner - Simply clone one file to another

=head1 SYNOPSIS

use Goo::FileThing::Cloner;

=head1 DESCRIPTION



=head1 METHODS

=over

=item run

create the output file


=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

