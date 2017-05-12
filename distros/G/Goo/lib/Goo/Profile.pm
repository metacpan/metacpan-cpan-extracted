package Goo::Profile;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::Profile.pm
# Description:  Show a profile for a Thing
#
# Date          Change
# -----------------------------------------------------------------------------
# 04/10/2005    Auto generated file
# 04/10/2005    Needed a model that could be used across all profilers
# 06/10/2005    Added method: clear
# 08/10/2005    Added method: addOption
# 08/10/2005    Added method: addTable
# 08/10/2005    Added method: addDescription
# 09/10/2005    Added method: showMessage
#
###############################################################################

use strict;

use Goo::Object;
use Goo::Header;
use Goo::Prompter;
use Goo::ThingFinder;
use Goo::OptionIndexTable;
use Text::FormatTable;

use base qw(Goo::Object);

# use Smart::Comments;


###############################################################################
#
# new - construct a profile object
#
###############################################################################

sub new {

    my ($class, $thing) = @_;

    my $this = $class->SUPER::new();

    $this->{thing} = $thing;

    ### keep an index counter
    $this->{index_counter} = [ "a" .. "z", 0 .. 9 ];

    ### keep all option in an index
    $this->{index} = {};

    $this->{option_tables} = "";

    ### get the commands for this Thing
    $this->{command_string} = join(', ', $thing->get_commands());

    return $this;

}


###############################################################################
#
# get_next_index_key - grab the next key in the index
#
###############################################################################

sub get_next_index_key {

    my ($this) = @_;

    # what index position are we up to in the Profile?
    return shift(@{ $this->{index_counter} });

}


###############################################################################
#
# add_options_table - add a table of options for display
#
###############################################################################

sub add_options_table {

    my ($this, $title, $columns, $option_type, @list) = @_;

    # add a new table of options to the profile
    my $index_table = {};

    # add each sub_thing to the index
    foreach my $option_text (@list) {

        my $current_index = $this->get_next_index_key();
        $index_table->{$current_index} = $option_text;

        # print "Option_type: $option_type\n";
        $this->add_option($current_index, $option_text, $option_type);

    }

    $this->add_rendered_table(Goo::OptionIndexTable::make($title, $columns, $index_table));

}


###############################################################################
#
# add_things_table - find a list of sub-things in a thing
#
###############################################################################

sub add_things_table {

    my ($this, $thing_string) = @_;

    # extract Things from a string or the Thing itself
    $thing_string = $thing_string || $this->{thing}->get_file();

    #use Goo::Prompter;
    #Goo::Prompter::notify("about to start looking for Things ... ");

    # add a table of Things to the profile
    $this->add_options_table("Things", 4, "Goo::ThingProfileOption",
                             Goo::ThingFinder::get_things($thing_string));

}


###############################################################################
#
# show_header - show the header for the profile
#
###############################################################################

sub show_header {

    my ($this, $action, $filename, $location) = @_;

    # $this->{called_by} = $this->{called_by} || caller();
    Goo::Header::show($action, $filename, $location);

    #Goo::Prompter::show_detailed_header("testing1" || caller(),
    #                                "testing2" || $this->{thing}->{filename},
    #                                "testing3" || $this->{thing}->{location}
    #                               );
    #Goo::Prompter::say($this->{description} || $this->{thing}->{description});
    Goo::Prompter::say();

}


###############################################################################
#
# display - show the profile
#
###############################################################################

sub display {

    my ($this) = @_;

    # print out all the tables
    print $this->{option_tables};

}


###############################################################################
#
# get_command - show the profile
#
###############################################################################

sub get_command {

    my ($this) = @_;

    #print $this->{command_string};
    my $option_key = Goo::Prompter::pick_command($this->{command_string});

    # if this is a lowercase option or a number
    # this must be an option in the profile
    if ($option_key =~ /[a-z0-9]/) {

        ### lookup the index
        my $option = $this->{index}->{$option_key};
        next unless $option;

        ### do the action
        $option->do($this->{thing});

    } elsif ($option_key =~ /[A-Z]/) {

        ### it may be an uppercase command?
        if ($this->{thing}->can_do_action($option_key)) {
            $this->{thing}->do_action($option_key);
        }

    } else {

        Goo::Prompter::notify("Invalid option. Press a key.");

    }

}


###############################################################################
#
# clear - clear the profile
#
###############################################################################

sub clear {

    my ($this) = @_;

    ### repopulate the index counter
    $this->{index_counter} = [ "a" .. "z", 0 .. 9 ];

    ### clear the option index
    $this->{index} = {};

    $this->{option_tables} = "";

}


###############################################################################
#
# add_option - add an individual option to the profile
#
###############################################################################

sub add_option {

    my ($this, $index_key, $option_text, $option_type) = @_;

    # load the option type - hmmm - from where though?
    # this could be a problem -
    eval "use $option_type;";

    # did the require work?
    if ($@) { die("Failed to require $option_type: $@"); }

    # add a new option to the index
    $this->{index}->{$index_key} =
        $option_type->new(
                          { thing => $this->{thing},
                            text  => $option_text
                          }
                         );


}


###############################################################################
#
# add_rendered_table - add a fully rendered table to the profile
#
###############################################################################

sub add_rendered_table {

    my ($this, $rendered_table) = @_;

    $this->{option_tables} .= $rendered_table;
    $this->{option_tables} .= "\n";


}


###############################################################################
#
# set_description - add a description to this profile
#
###############################################################################

sub set_description {

    my ($this, $description) = @_;

    $this->{description} = $description;

}


###############################################################################
#
# set_filename - add a filename to this profile
#
###############################################################################

sub set_filename {

    my ($this, $filename) = @_;

    $this->{filename} = $filename;

}


###############################################################################
#
# set_location - add a filename to this profile
#
###############################################################################

sub set_location {

    my ($this, $location) = @_;

    $this->{location} = $location;

}


###############################################################################
#
# show_message - display a message in the profile
#
###############################################################################

sub show_message {

    my ($this, $message) = @_;

    Goo::Prompter::say($message);

}

1;


__END__

=head1 NAME

Goo::Profile - Show a profile for a Thing

=head1 SYNOPSIS

use Goo::Profile;

=head1 DESCRIPTION



=head1 METHODS

=over

=item new

construct a profile object

=item get_next_index_key

grab the next key in the index

=item add_options_table

add a table of options for display

=item add_things_table

find a list of sub-things in a thing

=item show_header

show the header for the profile

=item display

show the profile

=item get_command

show the profile

=item clear

clear the profile

=item add_option

add an individual option to the profile

=item add_rendered_table

add a fully rendered table to the profile

=item set_description

add a description to this profile

=item set_filename

add a filename to this profile

=item set_location

add a filename to this profile

=item show_message

display a message in the profile


=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

