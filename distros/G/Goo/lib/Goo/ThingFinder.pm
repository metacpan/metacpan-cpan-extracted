package Goo::ThingFinder;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::ThingFinder.pm
# Description:  Find all the "Things" in a string
#
# Date          Change
# -----------------------------------------------------------------------------
# 01/07/2005    Auto generated file
# 01/07/2005    Need to extract all the Things to show in profile
# 01/08/2005    Added the ability to show an indexed table of things
#               Replace OO interface with simple package
#
###############################################################################

use strict;

use Goo::TypeManager;
use Text::FormatTable;


###############################################################################
#
# get_things - return a unique list of things found
#
###############################################################################

sub get_things {

    my ($thing_string) = @_;

    my @things;

    # what are all the suffixes
    foreach my $type (Goo::TypeManager::get_all_types()) {

        #use Goo::Prompter;
        #Goo::Prompter::notify("looing for $type ");

        # search the file for Things!
        while ($thing_string =~ m/([\w\.\-]+)\.$type/sg) {

            my $prefix = $1;
            my $suffix = $type;

            # print "found $1 \. $type \n";
            push(@things, $prefix . "." . $suffix);

        }

    }

    # remove repeats
    my %unique_things = map { $_ => 1 } @things;

    return keys %unique_things;

}


###############################################################################
#
# get_table - show a text based table of things
#
###############################################################################

sub get_table {

    my ($thing, $index, $options) = @_;

    my @things = get_things($thing);

    return unless @things;

    # prepare the head of the table
    my $table = Text::FormatTable->new('5l 30l');
    $table->head('', 'Things');
    $table->rule('-');

    # populate the table
    foreach my $thing (@things) {

        # pop off the options
        my $counter = shift(@$options);

        # remember the index position
        $index->{$counter} = $thing;

        # display a row
        $table->row("[$counter]", $thing);

    }

    # show the whole thing
    print $table->render();

}


###############################################################################
#
# run_driver - drive the module
#
###############################################################################

sub run_driver {

    my ($thing) = get_things("goo.goo");

	print $thing . "\n";
    # print $thing->to_string();

}

# call the driver
run_driver() unless caller(); 

1;


__END__

=head1 NAME

Goo::ThingFinder - Find all the "Things" in a string

=head1 SYNOPSIS

use Goo::ThingFinder;

=head1 DESCRIPTION

=head1 METHODS

=over

=item get_things

return a unique list of Things found

=item get_table

show a text based table of Things

=item run_driver

drive the module

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

