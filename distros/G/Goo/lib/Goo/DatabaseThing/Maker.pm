package Goo::DatabaseThing::Maker;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::DatabaseThing::Maker.pm
# Description:  Make a new row in a Table
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

    Goo::Header::show($thing->get_filename(), "database");


    foreach my $column ($thing->get_columns()) {


    }


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

Goo::DatabaseThing::Maker - Make a new row in a database table

=head1 SYNOPSIS

use Goo::DatabaseThing::Maker;

=head1 DESCRIPTION


=head1 METHODS

=over

=item run

make a new row

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

