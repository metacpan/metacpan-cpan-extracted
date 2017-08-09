# ABSTRACT: JsonSQL::Param::Table object. Stores a Perl representation of an SQL table expression for use in JsonSQL::Query objects.



use strict;
use warnings;
use 5.014;

package JsonSQL::Param::Table;

our $VERSION = '0.41'; # VERSION

use JsonSQL::Error;



sub new {
    my ( $class, $tablehashref, $queryObj ) = @_;
    
    my $tableName = $tablehashref->{table};
    if ( defined $tableName and $tableName =~ /^[a-zA-Z_][a-zA-Z0-9_]*$/ ) {
        my $self = {
            _tableName => $tableName
        };

        ## Schema is an optional parameter. Store it if it has been provided.
        my $tableSchema = $tablehashref->{schema} || $queryObj->{_defaultSchema};
        if ( defined $tableSchema and $tableSchema =~ /^[a-zA-Z_][a-zA-Z0-9_]*$/ ) {
            $self->{_tableSchema} = $tableSchema;
        }
        
        ## Check if table access is allowed based on $queryObj rule sets.
        my $validator = $queryObj->{_validator};
        my $table_rules = $validator->check_table_allowed({ schema => $self->{_tableSchema}, table => $self->{_tableName} });
        if ( eval { $table_rules->is_error } ) {
            return JsonSQL::Error->new("invalid_tables", "Error validating table $self->{_tableName}: $table_rules->{message}");
        } else {
            ## Save a reference to the $table_rules for future column processing.
            $self->{_tableRules} = $table_rules;
        }

        ## This is for the future.
        # The current SQL::Maker code doesn't support aliases for tables, but most DB backends allow it.
        # Will be able to enable this when the SQL::Maker code gets replaced.
        #my $tableAlias = $tablehashref->{alias};
        #if (defined $tableAlias and $tableAlias =~ /^[a-zA-Z_][a-zA-Z0-9_]*$/) {
        #    $self->{_tableAlias} = $tableAlias;
        #}
            
        ## Return the blessed reference.
        bless $self, $class;
        return $self;
    } else {
        return JsonSQL::Error->new("invalid_tables", "Invalid table name $tableName.");
    }
}


sub get_table_param {
    my ( $self, $queryObj ) = @_;

    ## Format the table string as schema.table if a schema has been defined.
    my $tableString;
    
    if (defined $self->{_tableSchema}) {
        $tableString = $queryObj->quote_identifier($self->{_tableSchema}) . '.';
    }

    ## Now add the table
    $tableString .= $queryObj->quote_identifier($self->{_tableName});

    ## Return a scalar ref
    return $tableString;

    ## When table aliases become possible...
#    if (defined $self->{_tableAlias}) {
#      return { $tableString => $self->{_tableAlias} };
#    } else {
#      return $tableString;
#    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JsonSQL::Param::Table - JsonSQL::Param::Table object. Stores a Perl representation of an SQL table expression for use in JsonSQL::Query objects.

=head1 VERSION

version 0.41

=head1 SYNOPSIS

This module constructs a Perl object representing a table identifier for use in SQL queries. It has a method for 
extracting the parameters to generate the appropriate SQL string.

=head1 DESCRIPTION

=head3 Object properties:

=over

=item _tableName => <string>

=item _tableSchema => <string>

=back

=head3 Generated parameters:

=over

=item $tableString => <string>

=back

=head1 METHODS

=head2 Constructor new($tablehashref, $queryObj)

Instantiates and returns a new JsonSQL::Param::Table object.

    $tablehashref               => A hashref of table/schema properties used to construct the object.
    $queryObj                   => A reference to the JsonSQL::Query object that will own this object.

Returns a JsonSQL::Error object on failure.

=head2 ObjectMethod get_table_param -> $tableString

Generates parameters represented by the object for the SQL statement. Returns:

    $tableString           => The SQL table identifier as a quoted string. Includes schema as appropriate.

=head1 AUTHOR

Chris Hoefler <bhoefler@draper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Hoefler.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
