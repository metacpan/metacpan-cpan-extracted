# -*- Mode: cperl; mode: folding; -*-

package Goo::Thing::task::Finisher;

###############################################################################
# Turbo10.com
#
# Copyright Turbo10.com 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::Thing::task::Finisher.pm
# Description:  Finish a task
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
    $dbo->{finishedby} = Goo::Prompter::pick_one("who finished it?", qw(sven nigel rena megan));
    $dbo->{finishedon} = "now()";
    $dbo->{status}     = "finished";

    # remember how we fixed for the future!
    $dbo->{comments} .= Goo::Prompter::ask("How did you finish it (how/when/where/why)?");

    if (Goo::Prompter::confirm("Update the task to finished?")) {
        $dbo->replace();
        Goo::TeamManager::send_email("Tara the Task Manager <tara\@thegoo.org>",
                                "$dbo->{finishedby} finished: $dbo->{title} [$dbo->{taskid}]",
                                $dbo->{description});
        Goo::Prompter::notify("Task finished.");
    } else {
        Goo::Prompter::notify("Task not finished.");
    }

}


1;


__END__

=head1 NAME

Goo::Thing::task::Finisher - Finish a task

=head1 SYNOPSIS

use Goo::Thing::task::Finisher;

=head1 DESCRIPTION



=head1 METHODS

=over

=item run

make a bug_fixer


=back

=head1 AUTHOR

Nigel Hamilton <nigel@turbo10.com>

=head1 SEE ALSO

