# ABSTRACT: JsonSQL::Param::InsertValues object. Stores a Perl representation of the VALUES parameter of an INSERT statement.



use strict;
use warnings;
use 5.014;

package JsonSQL::Param::InsertValues;

our $VERSION = '0.41'; # VERSION

use JsonSQL::Error;
use Data::Dumper;


sub new {
    my ( $class, $insertvaluesarrayref, $queryObj, $insert_table_rules ) = @_;
    
    my $self = [];
    my @insertvalue_errors;
    
    # Get the validator object from the $queryObj
    my $validator = $queryObj->{_validator};
    
    # If no table rules are defined, use an empty list. This will effectively cause validation to fail.
    my $table_rules = $insert_table_rules || [];
    
    for my $insertvalue ( @{ $insertvaluesarrayref } ) {
        my $column = $insertvalue->{column};
        if ( ( defined $column ) and ( $column =~ /^[a-zA-Z_][a-zA-Z0-9_]*$/ ) ) {
            my $allowed_field = $validator->check_field_allowed($table_rules, $column);
            if ( eval { $allowed_field->is_error } ) {
                push(@insertvalue_errors, "Setting value of column $column not allowed by the table rule set.");
            }
            
            my $value = $insertvalue->{value};
            if ( defined $value ) {
                push(@{ $self }, { column => $column, value => $value });
            } else {
                push(@insertvalue_errors, "Insert column $column specified without an insert value.");
            }
        } else {
            push(@insertvalue_errors, "Invalid column name $column specified.");
        }
    }
    
    if ( @insertvalue_errors ) {
        my $err = "Could not parse all value parameters for INSERT: \n\t";
        $err .= join("\n\t", @insertvalue_errors);
        return JsonSQL::Error->new("invalid_insertvalues", $err);
    } else {
        bless $self, $class;
        return $self;
    }
}


sub get_insert_param_strings {
    my ( $self, $queryObj ) = @_;

    ## For this, we just iterate through the stored value hashes and parse them out into two arrays: columns and values.
    ## A placeholder string of ? is constructed for parameterized value handling.
    my @columns;
    my @values;
    for my $column ( @{ $self } ) {
        push(@columns, $column->{column});
        push(@values, $column->{value});
    }

    my @placeholders = ("?") x scalar(@columns);

    my $columnString = join(",", map { $queryObj->quote_identifier($_) } @columns);

    my $placeholderString = join(",", @placeholders);

    return ($columnString, $placeholderString, \@values);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JsonSQL::Param::InsertValues - JsonSQL::Param::InsertValues object. Stores a Perl representation of the VALUES parameter of an INSERT statement.

=head1 VERSION

version 0.41

=head1 SYNOPSIS

This module constructs a Perl object representing the VALUES parameter of an SQL INSERT statement and has methods for 
generating the appropriate SQL string and bind values for use with the L<DBI> module.

=head1 DESCRIPTION

=head3 Object properties:

=over

=item <column_name> => <column value>

=back

=head3 Generated parameters:

=over

=item $columns => "column1,column2,..."

=item $placeholders => "?,?,..."

(One ? for each column)

=item $values => [value1,value2,...]

=back

=head1 METHODS

=head2 Constructor new($insertvaluesarrayref, $queryObj, $insert_table_rules)

Instantiates and returns a new JsonSQL::Param::InsertValues object.

    $insertvaluesarrayref       => An arrayref of column/value hashes used to construct the object.
    $queryObj                   => A reference to the JsonSQL::Query object that will own this object.
    $insert_table_rules         => The whitelist table rules used to validate access to the table columns for INSERT.

Returns a JsonSQL::Error object on failure.

=head2 ObjectMethod get_insert_param_strings -> ( $columns, $placeholders, $values )

Generates parameters represented by the object for the SQL statement. Returns:

    $columns                => A string of columns to use for the INSERT statement.
    $placeholders           => A placeholder string to use for parameterized VALUES.
    $values                 => An arrayref of values to match the parameterized $columns and $placeholders strings.

=head1 AUTHOR

Chris Hoefler <bhoefler@draper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Hoefler.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
