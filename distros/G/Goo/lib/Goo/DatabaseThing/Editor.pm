package Goo::DatabaseThing::Editor;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::DatabaseThing::Editor.pm
# Description:  Edit a Table
#
# Date          Change
# -----------------------------------------------------------------------------
# 16/10/2005    Auto generated file
# 16/10/2005    Need to create a Table
#
###############################################################################

use strict;

use Goo::Object;
use Goo::Prompter;
use Goo::Database;
use Goo::TextEditor;

use base qw(Goo::Object);


###############################################################################
#
# run - edit a task
#
###############################################################################

sub run {

    my ($this, $thing, $field) = @_;

    unless ($field) {
        $field = Goo::Prompter::pick_one("Edit which field?", $thing->get_columns());
    }

    # grab the task
    my $dbo = $thing->get_database_object();

    # create a filename
    my $temp_filename = "/tmp/" . $thing->{table} . "-" . $field . ".tmp";

    # write database value to a file
    Goo::FileUtilities::write_file($temp_filename, $dbo->{$field});

    # edit the value
    Goo::TextEditor::edit($temp_filename);

    # slurp the file back into RAM
    $dbo->{$field} = Goo::FileUtilities::slurp($temp_filename);

    # update the database
    $dbo->replace();

    # remove the temporary file
    unlink($temp_filename);

}

1;


__END__

=head1 NAME

Goo::DatabaseThing::Editor - Edit a row in a database table

=head1 SYNOPSIS

use Goo::DatabaseThing::Editor;

=head1 DESCRIPTION



=head1 METHODS

=over

=item run

edit a row in a database table

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

