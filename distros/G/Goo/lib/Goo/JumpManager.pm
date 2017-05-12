package Goo::JumpManager;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::JumpManager.pm
# Description:  Jumping to a specific line in the program
#
# Date          Change
# -----------------------------------------------------------------------------
# 11/03/2005    Auto generated file
# 11/03/2005    Needed to jump quickly between things jumps to the method
#               definition <<< jumps to a list of callers() for the current method
#               Include a ThereDoc ... to jump to there!
# 03/08/2005    Added simple line number jumping and index jumping
# 12/08/2005    Added method: startThis
# 13/08/2005    Added ability to jump to a line number or string
#
###############################################################################

use strict;

use Goo::Object;
use Goo::Loader;
use Goo::Prompter;
use Goo::TypeManager;
use Goo::TextUtilities;

use base qw(Goo::Object);

###############################################################################
#
# jump_to_thing - do the jump to another thing
#
###############################################################################

sub jump_to_thing {

    my ($this, $target) = @_;

    my $new_thing;

    foreach my $type (Goo::TypeManager::get_all_types()) {

        if ($target =~ /\.$type$/) {

            # load a new Thing!
            $new_thing = Goo::Loader::load($target);
            last;
        }
    }

    if ($new_thing) {

        # jump to the profile of this new thing
        $new_thing->do_action("P");

    } else {

        Goo::Prompter::notify("No Thing matches $target. Press a key.");

    }

}

###############################################################################
#
# run - do the jump!
#
###############################################################################

sub run {

    my ($this, $thing, $option) = @_;

    # if the target is already set the user has selected a menu option, used the
    # command line, or inserted a HERE or THEREDOC
    unless ($option) {
        $option = Goo::Prompter::ask("Jump to line number, string or another Thing?");
    }

    my $line_number;

    # is it a number?
    if ($option =~ /^\d+$/) {

        # a jump to a line number in the current thing!
        # go edit it
        $line_number = $option;
        $thing->do_action("E", $line_number);
        return;
    }

    if ($option =~ /\./) {

        # could be a new "Thing"
        $this->jump_to_thing($option);
        return;

    }

    # is it word?
    if ($option =~ /\w+/) {

        # do a regex match on the file and return the matching line number
        $line_number = Goo::TextUtilities::get_matching_line_number($option, $thing->get_file());

        # jump there!
        $thing->do_action("E", $line_number);
        return;
    }

}

1;


__END__

=head1 NAME

Goo::JumpManager - Jump to a specific line, string or another Thing

=head1 SYNOPSIS

use Goo::JumpManager;

=head1 DESCRIPTION

Top level action handler for jumping to a line number, string or another Thing (i.e., [J]ump).

=head1 METHODS

=over

=item jump_to_thing

do the jump to another thing

=item run

handle the jump action

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

