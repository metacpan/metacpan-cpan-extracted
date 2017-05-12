package Goo::DatabaseThing;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::DatabaseThing.pm
# Description:  Like a "Thing" but it's found in the database.
#
# Date          Change
# -----------------------------------------------------------------------------
# 19/10/2005    Added method: getColumns
#
###############################################################################

use strict;

use Goo::Thing;
use Goo::Database;
use Goo::DatabaseObject;

use base qw(Goo::Thing);


###############################################################################
#
# new - construct a DatabaseThing
#
###############################################################################

sub new {

    my ($class, $handle) = @_;

    # grab the conf
    my $this = $class->SUPER::new($handle);

    # map the filename to the database (12.bug => bug table with bugid 12)
    $this->{id}    = $this->get_prefix();
    $this->{table} = $this->get_suffix();

    # if the key is specified in (.goo) otherwise assume
    # the primary key column is the table name with id appended
    $this->{key} = $this->{key} || $this->{table} . "id";

    # add fields found in the database
    $this->add_fields(Goo::Database::get_row($this->{table}, $this->{key}, $this->{id}));

    return $this;

}


###############################################################################
#
# get_database_object - return an object for this thing
#
###############################################################################

sub get_database_object {

    my ($this) = @_;

    # bail out if we don't have these thing
    unless ($this->{table} && $this->{id}) {
        die("Missing table or id " . $this->to_string());
    }

    return Goo::DatabaseObject->new($this->{table}, $this->{id});

}


###############################################################################
#
# get_location - all Database Things are located in the database
#
###############################################################################

sub get_location {
	
	return "database";

}


###############################################################################
#
# get_columns - return the columns in display order
#
###############################################################################

sub get_columns {

    my ($this) = @_;

    # this should be set in the .goo config file
    return split(/\s+/, $this->{column_display_order});

}

1;


__END__

=head1 NAME

Goo::DatabaseThing - A "Thing" that is found in the database.

=head1 SYNOPSIS

use Goo::DatabaseThing;

=head1 DESCRIPTION


=head1 METHODS

=over

=item new

constructor

=item get_database_object

return an object for this Thing

=item get_location

return the table where this DatabaseThing is located.

=item get_columns

return the columns in display order

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

