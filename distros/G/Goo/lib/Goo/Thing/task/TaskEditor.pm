package Goo::Thing::task::Editor;

###############################################################################
# Turbo10.com
#
# Copyright Turbo10.com 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::Thing::task::Editor
# Description:  Edit a task
#
# Date          Change
# -----------------------------------------------------------------------------
# 16/10/2005    Auto generated file
# 16/10/2005    Need to create a task object
#
###############################################################################

use strict;

use Object;
use Prompter;
use GooDatabase;
use Goo::Prompter;
use base qw(Object);


###############################################################################
#
# run - edit a task
#
###############################################################################

sub run {

    my ($this, $thing) = @_;

    Prompter::clear();

    Goo::Prompter::showDetailedHeader("TaskEditor", $thing->get_filename());

    Prompter::say();

    # grab the task
    my $task = $thing->get_database_object("task", $thing->get_prefix());

    $task->{title} = Prompter::ask("Edit the task?"), $task->{title});
    $task->{description} = Prompter::ask("Edit the description?"), $task->{description});
    $task->{requestedby} = Prompter::pick_one("requested by?", qw(nigel megan rena
                sven));
    $task->{importance} = Prompter::ask("How important is this (1-10)?", $task->{importance});

    # what is the pain associated with this task???
    GooDatabase::execute($query);

    Prompter::say("New task created.");

    if (Prompter::confirm("Create another task?")) {
            $this->run($filename);
    }

}


1;


__END__

=head1 NAME

Goo::Thing::task::Editor - Edit a task

=head1 SYNOPSIS

use Goo::Thing::task::Editor;

=head1 DESCRIPTION



=head1 METHODS

=over

=item run

edit a task


=back

=head1 AUTHOR

Nigel Hamilton <nigel@turbo10.com>

=head1 SEE ALSO

