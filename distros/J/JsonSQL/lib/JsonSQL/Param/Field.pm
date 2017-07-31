# ABSTRACT: JsonSQL::Param::Field object. Stores a Perl representation of an SQL field expression for use in JsonSQL::Query objects.



use strict;
use warnings;
use 5.014;

package JsonSQL::Param::Field;

our $VERSION = '0.4'; # VERSION

use JsonSQL::Error;



sub new {
    my ( $class, $fieldhashref, $queryObj, $default_table_rules ) = @_;
    
    my $fieldName = $fieldhashref->{column};
    if ( defined $fieldName and ($fieldName =~ /^[a-zA-Z_][a-zA-Z0-9_:]*$/ or $fieldName eq '*') ) {
        my $self = {
            _fieldName => $fieldName
        };

        ## These are optional parameters. Store them if they are defined and valid.
        my $fieldAlias = $fieldhashref->{alias};
        if ( defined $fieldAlias and $fieldAlias =~ /^[a-zA-Z_][a-zA-Z0-9_]*$/ ) {
            $self->{_fieldAlias} = $fieldAlias;
        }
        
        my $fieldTable = $fieldhashref->{table};
        if ( defined $fieldTable and $fieldTable =~ /^[a-zA-Z_][a-zA-Z0-9_]*$/ ) {
            $self->{_fieldTable} = $fieldTable;
        }
        
        my $fieldSchema = $fieldhashref->{schema} || $queryObj->{_defaultSchema};
        if ( defined $fieldSchema and $fieldSchema =~ /^[a-zA-Z_][a-zA-Z0-9_]*$/ ) {
            $self->{_fieldSchema} = $fieldSchema;
        }
        
        ## Check if field access is allowed based on $queryObj rule sets.
        my $validator = $queryObj->{_validator};
        
        ## The table rules for validation can be specified by the caller or can be acquired using the field parameters.
        ## If both are supplied, the field parameters override the default table rules.
        ## If none are supplied, the restrictive empty list is used.
        my $table_rules = $default_table_rules || [];
        if ( defined $self->{_fieldTable} ) {
            $table_rules = $validator->check_table_allowed({ schema => $self->{_fieldSchema}, table => $self->{_fieldTable} });
            if ( eval { $table_rules->is_error } ) {
                return JsonSQL::Error->new("invalid_fields", "Error validating table $self->{_fieldTable} for field $self->{_fieldName}: $table_rules->{message}");
            }
        }
        
        ## With the appropriate table rules, check to see if access to this field is allowed.
        my $allowed_field = $validator->check_field_allowed($table_rules, $self->{_fieldName});
        if ( eval { $allowed_field->is_error } ) {
            return JsonSQL::Error->new("invalid_fields", "Field $self->{_fieldName} not allowed by the table rule set.");
        } else {
            bless $self, $class;
            return $self;
        }
    } else {
        return JsonSQL::Error->new("invalid_fields", "Invalid field name $fieldName.");
    }
}


sub get_field_param {
    my ( $self, $queryObj ) = @_;

    ## First we need to build up the field string, since there are a few possible versions.
    my $fieldString;
    
    ## Determine the field prefix.
    # Format as: schema.table.column
    if ( (defined $self->{_fieldSchema}) and (defined $self->{_fieldTable}) )  {
        $fieldString = $queryObj->quote_identifier($self->{_fieldSchema});
        $fieldString .= '.' . $queryObj->quote_identifier($self->{_fieldTable}) . '.';
    } 
    # Format as: table.column
    elsif (defined $self->{_fieldTable}) {
        $fieldString = $queryObj->quote_identifier($self->{_fieldTable}) . '.';
    }
    
    ## Now add the column
    if ( $self->{_fieldName} eq '*' ) {
        $fieldString .= $self->{_fieldName};
    } else {
        $fieldString .= $queryObj->quote_identifier($self->{_fieldName});
    }

    ## If an alias has been specified, return a hash ref. If not, return a scalar ref.
    if (defined $self->{_fieldAlias}) {
      return { $fieldString => $queryObj->quote_identifier($self->{_fieldAlias}) };
    } else {
      return $fieldString;
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JsonSQL::Param::Field - JsonSQL::Param::Field object. Stores a Perl representation of an SQL field expression for use in JsonSQL::Query objects.

=head1 VERSION

version 0.4

=head1 SYNOPSIS

This module constructs a Perl object representing a field identifier for use in SQL queries. It has a method for 
extracting the parameters to generate the appropriate SQL string.

=head1 DESCRIPTION

=head3 Object properties:

=over

=item _fieldName => <string>

=item _fieldAlias => <string>

=item _fieldTable => <string>

=item _fieldSchema => <string>

=back

=head3 Generated parameters:

=over

=item $fieldString => <string>

=item $fieldAlias  => <string>

=back

=head1 METHODS

=head2 Constructor new($fieldhashref, $queryObj, $default_table_rules)

Instantiates and returns a new JsonSQL::Param::Field object.

    $fieldhashref               => A hashref of column/alias/table/schema properties used to construct the object.
    $queryObj                   => A reference to the JsonSQL::Query object that will own this object.
    $default_table_rules        => The default whitelist table rules to use to validate access when the table params 
                                   are not provided to the field object. Usually, these are acquired from the table params
                                   of another object (ex: the FROM clause of a SELECT statement).

Returns a JsonSQL::Error object on failure.

=head2 ObjectMethod get_field_param -> $fieldString || { $fieldString => $fieldAlias }

Generates parameters represented by the object for the SQL statement. Returns:

    $fieldString           => The SQL field identifier as a quoted string. Includes schema and table as appropriate.
    $fieldAlias            => The alias to use for the field if specified.

=head1 AUTHOR

Chris Hoefler <bhoefler@draper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Hoefler.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
