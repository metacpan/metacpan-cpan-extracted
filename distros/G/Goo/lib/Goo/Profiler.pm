package Profiler;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Profiler.pm
# Description:  Show a synopsis of a Thing
#
# Date          Change
# -----------------------------------------------------------------------------
# 01/08/2005    Superclassed TemplateProfiler and ModuleProfiler
# 17/09/2005    Added method: makeIndex
# 22/09/2005    Added method: showProfiler
#
###############################################################################

use strict;

use Goo::Object;
use Goo::Prompter;
use Goo::ThingFinder;

use Text::FormatTable;
use Goo::ThingProfileOption;

use base qw(Goo::Object);


###############################################################################
#
# show_header - show the top header
#
###############################################################################

sub show_header {

    my ($this, $thing) = @_;

    Goo::Prompter::show_header($thing);
    Goo::Prompter::say($thing->{description});
    Goo::Prompter::say();

}


###############################################################################
#
# run - goo interface method
#
###############################################################################

sub run {

    my ($this, $thing) = @_;

    ### get the commands for this Thing
    my $command_string = join(', ', $thing->get_commands());

    while (1) {

        # show the profile
        $this->show_profile($thing);

        # Prompter::notify("Got to here in profiler ... now what?");

        my $option_key = Goo::Prompter::pick_command($command_string);

        # if this is a lowercase option or a number
        # this must be an option in the profile
        if ($option_key =~ /[a-z0-9]/) {

            # Goo::Prompter::notify("looking up ---- $option_key");
            # lookup the index
            my $option = $this->get_option($option_key);
            next unless $option;

            # Goo::Prompter::notify($option->to_string() . "\n");
            # do the action
            $option->do($thing);

        } elsif ($option_key =~ /[A-Z]/) {

            # it may be an uppercase command?
            if ($thing->can_do_action($option_key)) {
                $thing->do_action($option_key);
            }

        } else {

            Goo::Prompter::notify("Invalid option. Press a key.");
        }

    }

}


###############################################################################
#
# get_option - get the default action associated with the option
#
###############################################################################

sub get_option {

    my ($this, $option_key) = @_;

    # look up the option
    return $this->{index}->{$option_key};

}


###############################################################################
#
# populate_table - give a table and a list fill it!
#
###############################################################################

sub populate_table {

    my ($this, $table, $number_of_columns, $option_type, @list) = @_;

    my @options = $this->get_option_list($option_type, @list);

    # sort the options alphabetically
    # @options = sort { $a->get_text() cmp $b->get_text() } @options;

    # how many rows do we need?
    my $number_of_rows = scalar(@options)/$number_of_columns;

    # is there a remainder?
    if ($number_of_rows =~ /(\d+)\./) {
        $number_of_rows = $1;
        $number_of_rows++;
    }

    foreach my $row (1 .. $number_of_rows) {

        my @args = ();

        foreach my $column (1 .. $number_of_columns) {

            my $option = shift(@options);

            if ($option) {
                my $counter = shift(@{ $this->{counter} });
                push(@args, "[$counter]");
                $this->{index}->{$counter} = $option;
                push(@args, $option->get_text());
            } else {

                # blank cells
                push(@args, '');
                push(@args, '');

            }
        }

        $table->row(@args);

    }

    return $table->render();

}


###############################################################################
#
# get_things_table - return a table of templates
#
###############################################################################

sub get_things_table {

    my ($this, $thing) = @_;

    use Goo::Prompter;

    Goo::Prompter::prompt("Looking for things in " . $thing);

    my @things = Goo::ThingFinder::get_things($thing);

    Goo::Prompter::prompt("Found " . scalar(@things));

    return unless @things;

    my $table = Text::FormatTable->new('4l 20l 4l 20l 4l 20l 4l 20l');

    $table->head('', 'Things', '', '', '', '', '', '');

    $table->rule('-');

    return $this->populate_table($table, 4, "Goo::ThingProfileOption", @things);

}


###############################################################################
#
# get_option_list - return a list of options
#
###############################################################################

sub get_option_list {

    my ($this, $option_type, @list) = @_;

    my @options = ();

    eval "require $option_type";

    foreach my $option_text (@list) {

        push(@options, $option_type->new({ text => $option_text }));

    }

    return @options;
}


###############################################################################
#
# make_index - start off the index
#
###############################################################################

sub make_index {

    my ($this) = @_;

    $this->{counter} = [ 'a' .. 'z', 0 .. 9 ];

}


###############################################################################
#
# show_profile - this should be implemented by the subclass
#
###############################################################################

sub show_profile {

    print "showProfile not implemented\n";


}

1;


__END__

=head1 NAME

Profiler - Show a synopsis of a Thing

=head1 SYNOPSIS

use Profiler;

=head1 DESCRIPTION



=head1 METHODS

=over

=item show_header

show the top header

=item run

run this action handler

=item get_option

get the default action associated with the option

=item populate_table

give a table and a list fill it!

=item get_things_table

return a table of templates

=item get_option_list

return a list of options

=item make_index

start off the index

=item show_profile

this should be implemented by the subclass

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

