# -*- Mode: cperl; mode: folding; -*-

package TaskLister;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     TaskLister.pm
# Description:  Show a list of Tasks
#
# Date          Change
# -----------------------------------------------------------------------------
#
###############################################################################

use strict;

use Object;
use Profile;
use Goo::Loader;
use Goo::Prompter;
use Goo::Database;
use Text::FormatTable;

use base qw(Object);

# the size of the mental buffer
our $BUFFER_SIZE = 7;


###############################################################################
#
# get_tasks_table - return a table of things i care about
#
###############################################################################

sub get_tasks_table {

    my ($this, $profile) = @_;

    my $query = Goo::Database::execute_sql(<<EOSQL);
		
		select 		taskid, title, description, importance,
					date_format(requestedon, '%d %b %Y') as 'requestedon'
		from 		task	
		where		status = 'pending'
		order by 	importance desc, requestedon desc 
		limit		$BUFFER_SIZE

EOSQL

    my $full_text = "";

    # set up the table
    my $table = Text::FormatTable->new('4l 60l 6l 11l 18l');

    # column headings
    $table->head('[#]', 'Title', 'TaskID', 'Importance', 'Requested On');
    $table->rule('-');

    while (my $row = Goo::Database::get_result_hash($query)) {

        my $index_key = $profile->get_next_index_key();

        $profile->add_option($index_key, "$row->{taskid}.task", "ThingProfileOption");

        # print "addin conter === $counter \n";
        $table->row("[$index_key]",     $row->{title}, $row->{taskid},
                    $row->{importance}, $row->{requestedon});

        $full_text .= $row->{title} . " " . $row->{description};

    }

    return ($table->render(), $full_text);

}


###############################################################################
#
# run - show the care-o-meter
#
###############################################################################

sub run {

    my ($this, $thing) = @_;

    my $profile = Profile->new(Goo::Loader::load("care.goo"));

    # show a profile of the Things I need to care about
    while (1) {

        # profile clear
        $profile->clear();

        Goo::Prompter::show_detailed_header("TaskList", "Current Tasks");

        my $full_text;

        # add the tasks I care about
        my ($task_table, $task_text) = $this->get_tasks_table($profile);
        $full_text .= $task_text;
        $profile->add_rendered_table($task_table);

        # add a list of Things found in this Thing
        $profile->add_things_table($full_text);

        # show the profile and all the rendered tables
        $profile->display();

        # prompt the user for the next command
        $profile->get_command();

    }

}

1;


__END__

=head1 NAME

TaskLister - Show a list of Tasks

=head1 SYNOPSIS

use TaskLister;

=head1 DESCRIPTION



=head1 METHODS

=over

=item get_tasks_table

return a table of things i care about

=item run

show the care-o-meter


=back

=head1 AUTHOR

Nigel Hamilton <nigel@turbo10.com>

=head1 SEE ALSO

