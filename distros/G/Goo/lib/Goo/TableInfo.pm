package Goo::TableInfo;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::TableInfo.pm
# Description:  Provide meta details about SQL tables
#
# Date          Change
# -----------------------------------------------------------------------------
# 30/04/2005    Auto generated file
# 30/04/2005    Needed for DatabaseObject registry
#
###############################################################################

use strict;

use Goo::Object;
use Goo::Database;

use base qw(Goo::Object);


###############################################################################
#
# new - constructor
#
###############################################################################

sub new {

    my ($class, $table) = @_;

    my $this = $class->SUPER::new();

    my $query = Goo::Database::execute_sql("describe $table");

    $this->{columns} = ();

    while (my $row = Goo::Database::get_result_hash($query)) {

        if ($row->{Key} eq "PRI") { $this->{key} = $row->{Field}; }
        push(@{ $this->{columns} }, $row->{Field});

        # remember the type of each field
        $this->{ $row->{Field} } = $row->{Type};

    }

    return $this;

}


###############################################################################
#
# get_columns - return an array of columns
#
###############################################################################

sub get_columns {

    my ($this) = @_;

    return @{ $this->{columns} };


}


###############################################################################
#
# get_key - return the primary key of a table
#
###############################################################################

sub get_key {

    my ($this) = @_;

    return $this->{key};

}


###############################################################################
#
# get_column_type - return a type for the column
#
###############################################################################

sub get_column_type {

    my ($this, $column) = @_;

    return $this->{$column};


}


1;


__END__

=head1 NAME

Goo::TableInfo - Provide meta details about MySQL tables

=head1 SYNOPSIS

use Goo::TableInfo;

=head1 DESCRIPTION


=head1 METHODS

=over

=item new

constructor

=item get_columns

return an array of columns

=item get_key

return the primary key of a table

=item get_column_type

return a type for the column

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

