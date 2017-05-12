package Goo::FileThing::Deleter;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::FileThing::Deleter.pm
# Description:  Very simple program for deleting files from TheGoo
#
# Date          Change
# -----------------------------------------------------------------------------
# 02/08/2005    Version 1
#
###############################################################################

use strict;

use Goo::Object;
use Goo::Header;
use Goo::Prompter;

our @ISA = ("Goo::Object");


###############################################################################
#
# run - create the output file
#
###############################################################################

sub run {

    my ($this, $thing) = @_;

    my $filename = $thing->get_filename();

    # check to see if it exists
    unless (-e $thing->get_full_path()) {
        Goo::Prompter::say("Can't delete $filename. It doesn't exist,");
        exit;
    }

    Goo::Prompter::clear();

    Goo::Header::show("FileThing::Deleter", $thing->get_filename(), $thing->get_location());

    Goo::Prompter::say();

    if (Goo::Prompter::confirm("Delete $filename?", "N")) {

        # do the deletion!
        unlink($thing->get_full_path());
        Goo::Prompter::yell("$filename is deleted.");
    }

}

1;


__END__

=head1 NAME

Goo::FileThing::Deleter - Delete a file

=head1 SYNOPSIS

use Goo::FileThing::Deleter;

=head1 DESCRIPTION



=head1 METHODS

=over

=item run

create the output file


=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

