# ABSTRACT: JsonSQL::Param::Insert object. Stores a Perl representation of an INSERT statement used by the JsonSQL Insert query object.



use strict;
use warnings;
use 5.014;

package JsonSQL::Param::Insert;

our $VERSION = '0.41'; # VERSION

use JsonSQL::Error;
use JsonSQL::Param::Table;
use JsonSQL::Param::InsertValues;



sub new {
    my ( $class, $inserthashref, $queryObj ) = @_;
    
    my $self = {};
    my @insert_errors;
    
    # Construct _insertTable property.
    my $inserttable = JsonSQL::Param::Table->new($inserthashref->{table}, $queryObj);
    if ( eval { $inserttable->is_error } ) {
        push(@insert_errors, "Error creating table $inserthashref->{table}->{table} for INSERT: $inserttable->{message}");
    } else {
        $self->{_insertTable} = $inserttable;
    }
    
    # Construct _insertValues property.
    my $insertvalues = JsonSQL::Param::InsertValues->new($inserthashref->{values}, $queryObj, $self->{_insertTable}->{_tableRules});
    if ( eval { $insertvalues->is_error } ) {
        push(@insert_errors, "Error parsing VALUES parameters for INSERT: $insertvalues->{message}");
    } else {
        $self->{_insertValues} = $insertvalues;
    }
    
    ## SMELL: this is a little bit of a hack and should be redone properly at some point.
    ## Requires support for CTEs.
    if ( defined $inserthashref->{returning} ) {
        $self->{_insertReturning} = $inserthashref->{returning};
    }
    
    if ( @insert_errors ) {
        my $err = "Could not construct INSERT statement: \n\t";
        $err .= join("\n\t", @insert_errors);
        return JsonSQL::Error->new("invalid_inserts", $err);
    } else {
        bless $self, $class;
        return $self;
    }
}


sub get_returning_param_string {
    my ( $self, $queryObj ) = @_;

    if (defined $self->{_insertReturning}) {
        my @returningParam;

        for my $returnvalue (@{ $self->{_insertReturning} }) {
            my $column = $queryObj->quote_identifier($returnvalue->{column});
            my $alias = $queryObj->quote_identifier($returnvalue->{as});

            if ( defined $alias ) {
                push(@returningParam, "$column AS $alias");
            } else {
                push(@returningParam, "$column");
            }
        }

        return join(",", @returningParam);
    }
}


sub get_insert_stmt {
    my ( $self, $queryObj ) = @_;
    
    my $table = $self->{_insertTable}->get_table_param($queryObj);
    my ($columns, $placeholders, $values) = $self->{_insertValues}->get_insert_param_strings($queryObj);
    my $returning = $self->get_returning_param_string($queryObj);
    
    my $insertSql = "INSERT INTO $table ($columns) VALUES ($placeholders)";

    if ( $returning ) {
        my $insertWrapper = "WITH insert_q AS (\n";
        $insertWrapper .= $insertSql . "\n";
        $insertWrapper .= "RETURNING " . $returning . "\n)\n";
        $insertWrapper .= "SELECT * FROM insert_q";

        return ($insertWrapper, $values);
    } else {
        return ($insertSql, $values);
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JsonSQL::Param::Insert - JsonSQL::Param::Insert object. Stores a Perl representation of an INSERT statement used by the JsonSQL Insert query object.

=head1 VERSION

version 0.41

=head1 SYNOPSIS

This module constructs a Perl object representing an SQL INSERT statement and has methods for generating the appropriate SQL statement
and bind values for use with the L<DBI> module.

=head1 DESCRIPTION

=head3 Object properties:

=over

=item _insertTable => L<JsonSQL::Param::Table>

=item _insertValues => L<JsonSQL::Param::InsertValues>

=item _insertReturning => <string>

( Note: not currently whitelist validated due to the way this is implemented. Will change in future. )

=back

=head3

Structure of INSERT statement:

    INSERT INTO <table> ( <columns> ) VALUES ( <parameterized values> )

=head3 RETURNING clause

When using the RETURNING clause, the INSERT statement is wrapped in a WITH CTE, so your database has to support this.

    WITH insert_q AS (
        INSERT INTO <table> ( <columns> ) VALUES ( <parameterized values> )
        RETURNING <return columns>
    )
    SELECT * FROM insert_q

=head1 METHODS

=head2 Constructor new($inserthashref, $queryObj)

Instantiates and returns a new JsonSQL::Param::Insert object.

    $inserthashref       => A hashref with the properties needed to construct the object.
    $queryObj            => A reference to the JsonSQL::Query object that will own this object.

Returns a JsonSQL::Error object on failure.

=head2 ObjectMethod get_returning_param_string -> $returningParam

Generates the RETURNING clause from the _insertReturning property.

=head2 ObjectMethod get_insert_stmt -> ( $sql, $binds )

Generates the SQL statement represented by the object. Returns:

    $sql            => An SQL INSERT string.
    $binds          => An arrayref of parameterized values to pass with the query.

=head1 AUTHOR

Chris Hoefler <bhoefler@draper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Hoefler.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
