package Goo::DatabaseThing::Profiler;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2004
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::DatabaseThing::Profiler.pm
# Description:  Provide a profile of a database Thing
#
# Date          Change
# -----------------------------------------------------------------------------
# 17/10/2005    Version 1
# 17/10/2005    Added method: getRow
# 18/10/2005    Created test file: TableProfilerTest.tpm
#
###############################################################################

use strict;

use Goo::List;
use Goo::Object;
use Goo::Header;
use Goo::Profile;
use Goo::Prompter;
use Text::FormatTable;

use base qw(Goo::Object);


###############################################################################
#
# get_row_table - return the object in a table
#
###############################################################################

sub get_row_table {

    my ($this, $profile, $thing) = @_;

    my $table = Text::FormatTable->new('4l 20l 77l');

    $table->head('', 'Columns', '');

    $table->rule('-');

    my $dbo = $thing->get_database_object();

    foreach my $column ($thing->get_columns()) {

        my $index_key = $profile->get_next_index_key();

        $profile->add_option($index_key, $column, "Goo::DatabaseProfileOption");

        # print "addin conter === $counter \n";
        $table->row("[$index_key]", $column, $dbo->{$column});

    }

    return Goo::Prompter::highlight_options($table->render());

}


###############################################################################
#
# run - return a table of methods
#
###############################################################################

sub run {

    my ($this, $thing) = @_;

    my $profile = Goo::Profile->new($thing);

    while (1) {

        $profile->clear();

        $profile->show_header(ucfirst($thing->{table}) . " Profile", 
									  $thing->get_filename(), 
									  "database");

        # profile the database object
        my $table_row = $this->get_row_table($profile, $thing);

        # render a table of method signatures and descriptions
        $profile->add_rendered_table($table_row);

        # add a list of Things found in this Thing
        $profile->add_things_table($table_row);

        $profile->display();

        # show the profile and all the rendered tables
        # $profile->display();

        # prompt the user for the next command
        $profile->get_command();

    }

}


1;



__END__

=head1 NAME

Goo::DatabaseThing::Profiler - Show a profile of a database Thing

=head1 SYNOPSIS

use Goo::DatabaseThing::Profiler;

=head1 DESCRIPTION



=head1 METHODS

=over

=item get_row_table

return the object in a table

=item run

return a table of methods


=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

