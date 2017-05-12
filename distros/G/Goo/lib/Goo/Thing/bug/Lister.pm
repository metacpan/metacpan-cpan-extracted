# -*- Mode: cperl; mode: folding; -*-

package Goo::Thing::bug::Lister;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Lister.pm
# Description:  List all the bugs
#
# Date          Change
# -----------------------------------------------------------------------------
#
###############################################################################

use strict;

use Goo::Object;
use Goo::Loader;
use Goo::Profile;
use Goo::Prompter;
use Goo::Database;

use Text::FormatTable;

use base qw(Goo::Object);

# the size of the mental buffer
our $BUFFER_SIZE = 7;


###############################################################################
#
# get_bugs_table - return a table of things i care about
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
    $table->head('[#]', 'Title', 'BugID', 'Importance', 'Found On');
    $table->rule('-');

    while (my $row = Goo::Database::get_result_hash($query)) {

        my $index_key = $profile->get_next_index_key();

        $profile->add_option($index_key, "$row->{bugid}.bug", "Goo::ThingProfileOption");

        # print "addin conter === $counter \n";
        $table->row("[$index_key]",     $row->{title}, $row->{bugid},
                    $row->{importance}, $row->{foundon});
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

    my $profile = Goo::Profile->new(Goo::Loader::load("care.goo"));

    # show a profile of the Things I need to care about
    while (1) {

        # profile clear
        $profile->clear();

        Goo::Header::show("BugLister", "Things I need to care about");

        my $full_text;

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

Goo::Thing::bug::Lister - List all the bugs

=head1 SYNOPSIS

use Goo::Thing::bug::Lister;

=head1 DESCRIPTION



=head1 METHODS

=over

=item get_bugs_table

return a table of things i care about

=item run

show the care-o-meter


=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

