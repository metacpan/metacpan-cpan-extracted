package Goo::Thing::goo::Maker;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::Thing::goo::Maker.pm
# Description:  Make .goo configuration file
#
# Date          Change
# -----------------------------------------------------------------------------
# 15/06/2005    Auto generated file
# 15/06/2005    Need to make new goo files
# 06/11/2005    Added method: writeConfigFile
# 08/11/2005    Added method: tableMaker
#
###############################################################################

use strict;

use Goo::Header;
use Goo::Object;
use Goo::Prompter;
use Goo::Database;
use Goo::TextTable;
use Goo::ConfigFile;
use Goo::TextEditor;

use base qw(Goo::Object);

my $GOO_ROOT = "$ENV{HOME}/.goo/things/goo/";


###############################################################################
#
# run - generate a goo file
#
###############################################################################

sub run {

    my ($this, $filename) = @_;

    my $prefix = get_prefix($filename);

    while (1) {

        # show the Maker header
        Goo::Header::show($prefix, $filename);

        Goo::Prompter::say();
        Goo::Prompter::say("Make a new Thing of type $prefix");
        Goo::Prompter::say();

        # each type of Thing must have a title
        my $title = Goo::Prompter::ask("Enter a title for $prefix Things?");
        return unless ($title);

        my $description = Goo::Prompter::ask("Enter a description?");

        # get the location of these Things
        my $thing_location =
            Goo::Prompter::pick_one("Where are $prefix things found?",
                                    ("file system", "database"));

        my @locations;
        my $column_display_order;

        # grab Things out of the database
        if ($thing_location eq "database") {

            # possibly return a connect string here.
            # push(@locations, "");
            # we need a table name
            # create a table
            make_table($prefix);

            # create a default display order

            $column_display_order = join(" ", Goo::Database::get_table_columns($prefix));

        } else {

            # grab the file locations for these Things
            @locations = get_file_locations($prefix);

        }

        # get a list of commands and their handlers
        my $commands = get_commands();

        # print Dumper($commands);
        # write the config file to disk
        write_config_file($filename,               # the new .goo file
                          $title,
                          $description,
                          $commands,
                          $column_display_order,
                          @locations
                         );


        # confirm the Thing is made. Long live the Thing.
        Goo::Prompter::say();
        Goo::Prompter::yell("Finished making a new Thing: $prefix.");
        Goo::Prompter::say();

        # bail out if they want to
        last unless Goo::Prompter::confirm("Make another type of Thing?", "N");

        # ask for what other Things they want to make
        $filename = Goo::Prompter::ask("Enter the filename of the new Thing?");

    }

}


###############################################################################
#
# get_file_locations - find all the locations for this thing?
#
###############################################################################

sub get_file_locations {

    my ($suffix) = @_;

    # scan all the subdirectories for this type of Thing
    # for version 1 we should ask - version 2 we should scan for them
    my @locations =
        Goo::Prompter::keep_asking("Enter a directory where $suffix files are found?");

    # add all the directory locations for this Thing
    foreach my $location (@locations) {
        unless (-e $location) {
            Goo::Prompter::say("No location found: $location");
            if (Goo::Prompter::confirm("Create a new location $location?")) {

                # may need to create a new directory
                mkdir $location;
            }
        }
    }

    return @locations;

}


###############################################################################
#
# get_commands - get a list of commands and action handlers for this thing
#
###############################################################################

sub get_commands {

    my ($this, $thing) = @_;

    Goo::Prompter::say();
    Goo::Prompter::yell("Enter the actions for this Thing");

    my $config_file;

    while ($config_file = Goo::Prompter::ask("Inherit actions from another Thing?", "goo.goo")) {
        unless ($config_file =~ /goo$/) {
            Goo::Prompter::say("Please enter a .goo configuration file (e.g., goo.goo).");
            next;
        }
        last;
    }

    # get the top level goo.goo config file
    my $goo_config = Goo::ConfigFile->new($config_file);

    # build a hash of commands
    my $commands;

    # ask for global handlers
    foreach my $command ($goo_config->get_commands()) {

        # keep the same action handler
        $commands->{$command} =
            Goo::Prompter::ask("Enter an action handler for $command?",
                               $goo_config->get_action_handler($command));

    }

    # ask for new handlers
    while (my $new_command = Goo::Prompter::ask("Add a new action for this Thing?")) {

        if ($new_command !~ /\[[A-Z]\]/) {
            Goo::Prompter::notify("Invalid command. " .
                "Actions must include a capitalised letter in square brackets(e.g., [E]dit). Press a key. "
            );
            next;
        }

        # get the action handler for this command
        $commands->{$new_command} =
            Goo::Prompter::ask("Enter an action handler for $new_command?");
    }

    return $commands;

}


###############################################################################
#
# get_prefix - return a prefix for a file
#
###############################################################################

sub get_prefix {

    my ($filename) = @_;

    $filename =~ s/.*\///;
    $filename =~ m/(.*)\..*$/;

    return $1;

}


###############################################################################
#
# write_config_file - write the file to disk
#
###############################################################################

sub write_config_file {

    my ($filename, $title, $description, $commands, $column_display_order, @locations) = @_;

    my $commands_table = Goo::TextTable->new();

    # go through all the commands
    foreach my $key (keys %$commands) {

        # add the command_string to the file
        $commands_table->add_row($key, " = ", $commands->{$key});
    }

    # add this to the locations
    my $locations_table = Goo::TextTable->new();

    foreach my $location (@locations) {
        $locations_table->add_row("locations", " = ", $location);
    }


    my $database_string;

    if ($column_display_order) {

        my $table = $filename;
        $table =~ s/\.goo//;

        $database_string = <<DATABASE;
# database details
table					= 	$table
column_display_order	=	$column_display_order
DATABASE

    }

    # use string for interpolation
    my $commands_string  = $commands_table->render();
    my $locations_string = $locations_table->render();

    # here is a template for all configuration files
    my $file_contents = <<CONFIG;
###############################################################################
#
# $filename - goo config file
#
###############################################################################

# what is this Thing?
title			=	$title
description		=	$description

# actions and the programs that handle them
$commands_string

# where is this Thing
$locations_string

$database_string

CONFIG

    Goo::FileUtilities::write_file($filename, $file_contents);

}


###############################################################################
#
# make_table - make a table
#
###############################################################################

sub make_table {

    my ($thing) = @_;

    my $table = $thing;
    my $key   = $thing . "id";

    Goo::Prompter::say(ucfirst($thing) . " Things will be stored in the $thing database table.");
    Goo::Prompter::say("The primary key of the $thing table is $key.");

    # check if the table already exists?
    if (Goo::Database::get_primary_key($thing)) {

        # do they want to drop it?
        if (Goo::Prompter::confirm("Table $thing already exists. Delete $thing table?", "N")) {
            Goo::Database::execute_sql("drop table $thing");
            Goo::Prompter::say("$thing table deleted.");
        } else {

            # bail out they're happy with the table already
            Goo::Prompter::say("$thing table is unchanged.");
            return;
        }
    }

    # start building the create statement
    my @columns;

    # each database thing has a numerical id
    push(@columns, "$key int not null primary key auto_increment ");

    # each Thing should have a title
    if (Goo::Prompter::confirm("Add a title column to $table?", "Y")) {
        push(@columns, "title varchar(100)");
    }

    # and a description
    if (Goo::Prompter::confirm("Add a description column to $table?", "Y")) {
        push(@columns, "description text");
    }

    # ask for more columns
    while (my $column = lc(Goo::Prompter::ask("Add another column to the $table table?"))) {

        my $type =
            Goo::Prompter::pick_one("What type is the column $column?",
                                    qw(varchar text int date datetime));

        if ($type eq "varchar") {
            my $length = Goo::Prompter::ask("Enter the length of the varchar?", "100");
            $type = "varchar($length)";
        }

        # more null handling etc.
        # what about enum types?
        push(@columns, "$column $type");

    }

    # make create statement
    my $column_text = join(", \n ", @columns);

    my $sql_statement = "\n\ncreate table $table ($column_text) \n\n";

    while (Goo::Prompter::confirm("The SQL create statement: $sql_statement " . "Edit?", "N")) {

        # let the user edit the create statement
        $sql_statement =
            Goo::TextEditor::edit_string("\# Edit the SQL create statement $sql_statement");
    }

    if (Goo::Prompter::confirm("Execute SQL?", "Y")) {

        # execute the SQL
        Goo::Database::execute_sql($sql_statement);

        # let the user know about
        Goo::Prompter::say();
        Goo::Prompter::yell("$table table created.");
        Goo::Prompter::say();

    } else {

        # let the user know about
        Goo::Prompter::say();
        Goo::Prompter::yell("$table table was not created.");
        Goo::Prompter::say();

    }

}

1;


__END__

=head1 NAME

Goo::Thing::goo::Maker - Make a new Thing by creating a .goo configuration file

=head1 SYNOPSIS

# make a new Python Thing
shell> goo -m py.goo

# make a new Thing for handling text files
shell> goo -m txt.goo


=head1 DESCRIPTION

=head1 METHODS

=over

=item run

generate a Goo file

=item get_file_locations

find all the locations for this Thing?

=item get_commands

get a list of commands and action handlers for this Thing

=item get_prefix

return a prefix for a file

=item write_config_file

write the file to disk

=item make_table

make a table

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

