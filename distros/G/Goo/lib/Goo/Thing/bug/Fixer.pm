# -*- Mode: cperl; mode: folding; -*-

package Goo::Thing::bug::Fixer;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::Fixer.pm
# Description:  Make a task module
#
# Date          Change
# -----------------------------------------------------------------------------
# 16/10/2005    Auto generated file
# 16/10/2005    Need to create a task object
#
###############################################################################

use strict;

use Goo::Object;
use Goo::Prompter;
use Goo::TeamManager;

use base qw(Goo::Object);


###############################################################################
#
# run - make a bug_fixer
#
###############################################################################

sub run {

    my ($this, $thing) = @_;

    my $dbo = $thing->get_database_object();

    # who was the person who fixed it?
    $dbo->{fixedby} =
        Goo::Prompter::pick_one("Who fixed it?", Goo::TeamManager::get_all_nick_names());
    $dbo->{fixedon} = "now()";

    # remember how we fixed for the future!
    $dbo->{description} .= Goo::Prompter::ask("How did you fix it (how/when/where/why)?");

    if (Goo::Prompter::confirm("Update the bug to fixed?")) {
        $dbo->{status} = "killed";
        $dbo->replace();
        Goo::TeamManager::send_email("Burt the Bug Buster <burt\@thegoo.org>",
                                     "$dbo->{fixedby} fixed: $dbo->{title} [BugID $dbo->{bugid}]",
                                     $dbo->{description}
                                    );

        Goo::Prompter::notify("Bug fixed.");
    } else {
        Goo::Prompter::notify("Bug not fixed.");
    }

}


1;


__END__

=head1 NAME

Goo::Thing::bug::Fixer - Fix a bug

=head1 SYNOPSIS

use Goo::Thing::bug::Fixer;

=head1 DESCRIPTION



=head1 METHODS

=over

=item run

make a bug_fixer


=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

