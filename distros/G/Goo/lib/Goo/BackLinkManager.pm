package Goo::BackLinkManager;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::BackLinkManager.pm
# Description:  Traverse the backlinks for a given "Thing"
#
# Date          Change
# -----------------------------------------------------------------------------
# 01/07/2005    Auto generated file
# 01/07/2005    Need to find backlinks easily!
# 24/08/2005    Added method: generateBackLinks
# 24/08/2005    Added method: showHeader
# 27/08/2005    Added method: getBackLinksTable
# 28/08/2005    Added method: run
# 28/08/2005    Added method: showProfile
#
###############################################################################

use strict;

use Goo::Object;
use Goo::Loader;
use Goo::Profile;
use Goo::BackLinkFinder;

use base qw(Goo::Object);

# use Smart::Comments;


###############################################################################
#
# run - do the thing
#
###############################################################################

sub run {

    my ($this, $thing) = @_;

    ### get the commands for the backlinkviewer
    my $profile = Goo::Profile->new(Goo::Loader::load("blv.goo"));

    my $filename = $thing->get_filename();

    while (1) {

        $profile->clear();

        # scanning for backlinks
        Goo::Prompter::say("Scanning for back links to $filename ...");

        my @things = Goo::BackLinkFinder::get_back_links($filename);

        $profile->clear();

        $profile->show_header("Back Links Viewer", $filename, $thing->get_location());

        if (@things) {
            $profile->add_options_table("Back Links to $filename", 4,
                                        "Goo::ThingProfileOption", @things);
        } else {
            $profile->show_message("Nothing links back to " . $thing->get_filename());
        }

        $profile->display();
        $profile->get_command();

    }

}


1;


__END__

=head1 NAME

Goo::BackLinkManager - Display the backlinks for a given "Thing"

=head1 SYNOPSIS

use Goo::BackLinkManager;

=head1 DESCRIPTION

A generic action handler for showing Back [L]inks.

Uses the BackLinkFinder to extracts the backlinks for a given "Thing" 
then displays a profile of the results.

=head1 METHODS

=over

=item run

Call the BackLinkFinder and display the results.

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

