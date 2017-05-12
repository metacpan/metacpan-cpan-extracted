package Goo::DatabaseObject;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     GooDatabaseObject.pm
# Description:  Bridge the relational and OO world!
#
# Date          Change
# -----------------------------------------------------------------------------
# 02/05/2005    Auto generated file
# 02/05/2005    Got sick of writing standard SQL
# 19/10/2005    Created test file: GooDatabaseObjectTest.tpm
#
###############################################################################

use strict;

use Goo::Object;
use Goo::Database;

# GooDatabaseObject isa Object
use base qw(Goo::Object);


###############################################################################
#
# new - construct a goo_database_object object
#
###############################################################################

sub new {

    my ($class, $table, $primary_key_value) = @_;

    my $this = $class->SUPER::new();

    # beware of name clashes in object fields
    $this->{table_name}        = $table;
    $this->{primary_key}       = Goo::Database::get_primary_key($table);
    $this->{primary_key_value} = $primary_key_value;

    # look the object up in the database
    if ($this->{primary_key_value}) {

        # look up the database for the object
        my $row =
            Goo::Database::get_row($this->{table_name}, $this->{primary_key},
                                $this->{primary_key_value});

        # die if nothing is found
        unless ($row) {
            die("No object found for $primary_key_value in $table");
        }

        # it's there!
        $this->{object_exists} = 1;

        # add all the columns to the current object - merge hashes
        %$this = (%$this, %$row);

    }

    return $this;

}


###############################################################################
#
# delete - delete the current object in the database
#
###############################################################################

sub delete {

    my ($this) = @_;

    unless ($this->{primary_key_value}) {
        die("Can't delete without a primary key " . $this->to_string());
    }

    Goo::Database::delete_row($this->{table_name}, $this->{primary_key}, $this->{primary_key_value});

}


###############################################################################
#
# replace - replace the entire row in the database with the 'state' of the
#           current object
#
###############################################################################

sub replace {

    my ($this) = @_;

    # save the changes to the database
    my @columns = Goo::Database::get_table_columns($this->{table_name});

    my $into = join(",", @columns);

    my @place_holders;

    foreach my $column (@columns) {

        # watch out for dates
        if ($this->{$column} eq "now()") {
            push(@place_holders, $this->{$column});
        } else {
            push(@place_holders, "?");
        }
    }

    # join up all the place holders
    my $places = join(',', @place_holders);

    my $query = Goo::Database::prepare_sql(<<EOSQL);
	replace into $this->{table_name} ($into)
	values ($places)
EOSQL

    my $column_count = 0;

    foreach my $column (@columns) {
        next if $this->{$column} eq "now()";
        $column_count++;
        Goo::Database::bind_param($query, $column_count, $this->{$column});
    }

    Goo::Database::execute($query);

}


1;


__END__

=head1 NAME

Goo::DatabaseObject - Bridge between relational and OO model

=head1 SYNOPSIS

use Goo::DatabaseObject;

=head1 DESCRIPTION

=head1 METHODS

=over

=item new

constructor

=item delete

delete the current object in the database

=item replace

replace the entire row in the database with the current 'state' of the object

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

