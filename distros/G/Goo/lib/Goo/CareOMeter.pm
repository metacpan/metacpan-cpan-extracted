package Goo::CareOMeter;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::CareOMeter.pm
# Description:  Keep a track of what I need to care about
#
# Date          Change
# -----------------------------------------------------------------------------
# 19/10/2005    Added method: getTableOfCare
# 25/10/2005    decided to add tasks and bugs on the same screen - but new
#               Things are coming: ideas, feedback, projects, events etc.
#
###############################################################################

use strict;

use Goo::Object;
use Goo::Profile;
use Goo::Loader;
use Goo::Prompter;
use Goo::Database;
use Text::FormatTable;

use base qw(Goo::Object);

# the size of the mental buffer
our $BUFFER_SIZE = 3;

###############################################################################
#
# get_bugs_table - return a table of bugs I care about
#
###############################################################################

sub get_bugs_table {

    my ($this, $profile) = @_;

    my $query = Goo::Database::execute_sql(<<EOSQL);
		
		select 		title, bugid, importance, 
					date_format(foundon, '%d %b %Y') as 'foundon', 
					description
		from 		bug
		where		status = 'alive'
		order by 	importance desc, foundon desc 
		limit		$BUFFER_SIZE

EOSQL

    my $full_text = "";

    # set up the table
    my $table = Text::FormatTable->new('4l 60l 6l 11l 18l');

    # column headings
    $table->head('', 'Bugs', 'BugID', 'Importance', 'Found On');
    $table->rule('-');

    while (my $row = Goo::Database::get_result_hash($query)) {

        my $index_key = $profile->get_next_index_key();

        $profile->add_option($index_key, "$row->{bugid}.bug", "Goo::ThingProfileOption");

        # print "addin conter === $counter \n";
        $table->row("[$index_key]",     $row->{title}, $row->{bugid},
                    $row->{importance}, $row->{foundon});
        $full_text .= $row->{title} . " " . $row->{description};

    }

    return (Goo::Prompter::highlight_options($table->render()), $full_text);

}

###############################################################################
#
# get_tasks_table - return a table of tasks I care about
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
    $table->head('', 'Tasks', 'TaskID', 'Importance', 'Requested On');
    $table->rule('-');

    while (my $row = Goo::Database::get_result_hash($query)) {

        my $index_key = $profile->get_next_index_key();

        $profile->add_option($index_key, "$row->{taskid}.task", "Goo::ThingProfileOption");

        # print "addin conter === $counter \n";
        $table->row("[$index_key]",     $row->{title}, $row->{taskid},
                    $row->{importance}, $row->{requestedon});

        $full_text .= $row->{title} . " " . $row->{description};

    }

    return (Goo::Prompter::highlight_options($table->render()), $full_text);

}

###############################################################################
#
# run - show the care-o-meter
#
###############################################################################

sub run {

    my ($this, $thing) = @_;

    my $profile = Goo::Profile->new(Goo::Loader::load("care.goo"));

    # show a profile of the Things I need to care about
    while (1) {

        # profile clear
        $profile->clear();

        $profile->show_header("CareOMeter", "Things I need to care about", "care.goo");

        my $full_text;

        # add the tasks I care about
        my ($task_table, $task_text) = $this->get_tasks_table($profile);
        $full_text .= $task_text;
        $profile->add_rendered_table($task_table);

        # add the bugs I care about
        my ($bugs_table, $bugs_text) = $this->get_bugs_table($profile);
        $full_text .= $bugs_text;
        $profile->add_rendered_table($bugs_table);

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

Goo::CareOMeter - Show an ordered list of Things you care about

=head1 SYNOPSIS

use Goo::CareOMeter;

=head1 DESCRIPTION

The Care[O]Meter is a top-level action handler that shows an ordered list of Things you care about.
It helps answer the question, "what do I do next?"

=head1 METHODS

=over

=item get_bugs_table

return a table of bugs I care about ranked by descending care_factor

=item get_tasks_table

return a table of tasks I care about ranked by descending care_factor

=item run

show the Care-O-Meter

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

