# ABSTRACT: JSON schema validation module. Returns a JsonSQL::Validator object for validating a JSON string against a pre-defined schema.


use strict;
use warnings;
use 5.014;

package JsonSQL::Validator;

our $VERSION = '0.41'; # VERSION

use JSON::Validator;
use JSON::Parse qw( assert_valid_json parse_json );
use List::Util qw( any );

use JsonSQL::Schemas::Schema;
use JsonSQL::Error;
#use Data::Dumper;



sub new {
    my ( $class, $jsonSchema, $ruleSets ) = @_;
    
    my $self = {};
    
    # Load the specified JSON schema.
    my $schema = JsonSQL::Schemas::Schema->load_schema($jsonSchema);
    if ( eval { $schema->is_error } ) {
        return JsonSQL::Error->new("validate", "Error loading JSON schema object '$jsonSchema': $schema->{message}.");
    } else {
        my $validator = JSON::Validator->new;
        $validator->schema($schema);
        $self->{jsonValidator} = $validator;
    }
    
    if (defined $ruleSets && 'ARRAY' eq ref ($ruleSets) ) {
        $self->{ruleSets} = $ruleSets;
    } else {
        $self->{ruleSets} = [];
    }
    
    bless $self, $class;
    return $self;
}


sub validate_schema {
    my ( $self, $json ) = @_;

    # Parse and validate the JSON string.
    eval {
        # Check if string is valid JSON before continuing.
        assert_valid_json($json);
    };
    
    if ( $@ ) {
        return JsonSQL::Error->new("validate", "Input is invalid JSON at: $@");
    } else {
        my $perldata = parse_json($json);
        my @errors = $self->{jsonValidator}->validate($perldata);
        
        if ( @errors ) {
            my $err = "JSON failed schema validation at: \n";
            for my $error ( @errors ) {
                $err .= "\t $error->{message} at $error->{path} \n";
            }
            return JsonSQL::Error->new("validate", $err);
        } else {
            return $perldata;
        }
    }
}



sub _getRuleSets {
    my ( $self, $schemaString ) = @_;
    
    my $schema = $schemaString || '';
    my @matchingRuleSets;
    
    for my $ruleSet ( @{ $self->{ruleSets} } ) {
        if ( $ruleSet->{schema} eq $schema || $ruleSet->{schema} eq '#anySchema' ) {
            push(@matchingRuleSets, $ruleSet);
        }
    }
    
    return \@matchingRuleSets;
}


sub _getTableRules {
    my ( $tableString, $ruleSet ) = @_;
    
    my @matchingTableRules;
    for my $tableRule ( keys %{ $ruleSet } ) {
        if ( $tableRule eq '#anyTable' ) {
            push(@matchingTableRules, $tableRule);
        } elsif ( defined $tableString && $tableRule eq $tableString ) {
            push(@matchingTableRules, $ruleSet->{$tableRule});
        }
    }
    
    return \@matchingTableRules;
}


sub check_table_allowed {
    my ( $self, $tableObj ) = @_;
    
    my @table_rules;
    my @table_violations;
    my $ruleSets = $self->_getRuleSets($tableObj->{schema});
    
    if ( @{ $ruleSets } ) {
        for my $ruleSet ( @{ $ruleSets } ) {
            # For a given rule set, the default is to be restrictive.
            my $table_allowed = 0;
            my $tableRules = _getTableRules($tableObj->{table}, $ruleSet);
            
            for my $tableRule ( @{ $tableRules } ) {
                # If there is a rule defined for the table, the table is marked as "allowed"...
                $table_allowed = 1;
                
                # Check to be sure the table rule is an array of allowed columns.
                # The table rule '#anyTable' is a special case that turns off restrictions for all tables in the schema.
                unless ( $tableRule eq '#anyTable' ) {
                    if ( 'ARRAY' eq ref ($tableRule) ) {
                        push(@table_rules, $tableRule);
                    } else {
                        push(@table_violations, "Bad syntax in rule set $ruleSet->{schema}. Table rules must be arrays of allowed columns.");
                    }
                }
            }
            
            unless ( $table_allowed ) {
                push(@table_violations, "Table $tableObj->{table} is not allowed by rule set $ruleSet->{schema}");
            }
        }
    } else {
        # If no rule sets are defined, the default is to be restrictive.
        push(@table_violations, "No access rules have been defined. Default is to be restrictive.");
    }
    
    # If any violation is found, the access control test fails.
    # If cases where there are multiple rule sets for a schema, this ensures that the most restrictive set is used.
    if ( @table_violations ) {
        my $err = "Table failed access control test.\n\t";
        $err .= join("\n\t", @table_violations);
        return JsonSQL::Error->new("access_control", $err);
    } else {
        # Otherwise, return the @table_rules so they can be used for additional checks.
        return \@table_rules;
    }
}


sub check_field_allowed {
    my ( $self, $table_rules, $field ) = @_;
    
    my @column_violations;
    for my $tableRule ( @{ $table_rules } ) {
        # Check allowed column list for the table.
        unless ( any { $_ eq $field || $_ eq '#anyColumn' } @{ $tableRule } ) {
            push(@column_violations, "Field $field is not allowed by the table rule set.");
        }
    }
        
    if ( @column_violations ) {
        my $err = "Field failed access control test.\n\t";
        $err .= join("\n\t", @column_violations);
        return JsonSQL::Error->new("access_control", $err);
    } else {
        return 1;
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JsonSQL::Validator - JSON schema validation module. Returns a JsonSQL::Validator object for validating a JSON string against a pre-defined schema.

=head1 VERSION

version 0.41

=head1 SYNOPSIS

This is a supporting module used by JsonSQL::Query modules.

To use this:

    my $validator = JsonSQL::Validator->new(<json_schema_name>, <whitelisting_rule_set>);
    my $perldata = $validator->validate_schema(<json_string>);
    if ( eval { $perldata->is_error } ) {
        return "$perldata->{message}";
    } else {
        ...
    }

To use the whitelisting module:

    my $table_rules = $validator->check_table_allowed({ schema => <schemaname>, table => <tablename> });
    if ( eval { $table_rules->is_error } ) {
        return "Use of table failed access check: $table_rules->{message}";
    } else {
        my $allowedField = $validator->check_field_allowed($table_rules, <fieldname>);
        if ( eval { $allowedField->is_error } ) {
            return "Use of field in table failed access check: $allowedField->{message}";
        } else {
            ...
        }
    }

For more information on the whitelisting module, and how to construct rule sets, see documentation below.

=head1 METHODS

=head2 Constructor new($jsonSchema, $ruleSets) -> JsonSQL::Validator

Loads the specified $jsonSchema and creates a JSON::Validator instance with it. A reference to the validator and to the provided
whitelisting rule sets is saved in the object before it is returned. If an error occurs during schema loading, a JsonSQL::Error object
is returned.

    $jsonSchema     => The JSON schema to load. Must be present in JsonSQL::Schemas as a subclass of JsonSQL::Schemas::Schema.
    $ruleSets       => An array of whitelisting rules to be applied when a JsonSQL query object is being constructed (see below).

=head2 ObjectMethod validate_schema($json) -> \%hash

Parses the provided JSON string into a Perl data structure, and then uses the stored JSON::Validator to validate it
against the specified schema (a JsonSQL::Schemas::<schema>). If the process fails at any step, it will return a JsonSQL::Error object
with an appropriate error message. If successful, a Perl data structure (depends on the schema, but usually a hashref)
representing the SQL query is returned.

    $json        => The JSON string to validate. Must be valid JSON.

=head2 PrivateMethod _getRuleSets($schemaString) -> \@array

Searches the @ruleSets array for the specified $schemaString and returns all matching rule sets.

    $schemaString       => Name of schema to match for identifying rulesets.

    Matches a rule set if ( $schemaString eq $ruleSet->{schema} || $ruleSet->{schema} eq '#anySchema' ).

=head2 PrivateMethod _getTableRules($tableString, $ruleSet) -> \@array

Looks at each table rule in the \@ruleSet array and returns it if it matches the specified $tableString.

    $tableString       => Name of table to match for identifying table rules.
    $ruleSet           => The @\ruleSet array to search for table matches.

    Matches table rules of the form ( $ruleSet->{$tableString} || $ruleSet->{'#anyTable'} ).

=head2 ObjectMethod check_table_allowed($tableObj) -> \@array

Determines whether access to a table is allowed by the current stored rule set. If yes, a set of table rules applicable to the table is
returned to use for column verification. If no, a JsonSQL::Error object is returned.

    $tableObj           => Name of table to match for identifying table rules.
    Takes the form { schema => <schemaname>, table => <tablename> }

=head2 ObjectMethod check_field_allowed($table_rules, $field) -> 1 || JsonSQL::Error

Determines whether access to a column is allowed by the supplied table rules. If yes, a true value is returned. If no, 
a JsonSQL::Error object is returned.

    $table_rules           => Array of table rules as returned by check_table_allowed.
    $field                 => The name of the field to check.

=head1 Whitelisting Module

To provide some basic whitelisting support for table and column identifiers, a set of whitelisting rules is saved in the
JsonSQL::Validator object when it is being created. The rules take the form of an \@arrayref as follows:

        [
            {
                schema => 'schemaName' || '#anySchema',
                <'#anyTable' || allowedTableName1 => [ '#anyColumn' || allowedFieldName1, allowedFieldName2, ... ]>,
                <... additional table rules ...>
            },
            < ... additional rule sets ... >
        ]

Rule sets are generally grouped by schema. If you are not using schemas (or you are using a DB that doesn't support them), you will have
to provide a rule set with the schema property set to '#anySchema'. Whitelisting security is enabled and restrictive by default, so 
at least one rule set will have to be defined in order to create JsonSQL query objects. If you want to disable whitelisting security
(not recommended), use this rule set,

    [ { schema = '#anySchema', '#anyTable' } ]

The above allows access to all tables in any schema. Column restrictions are not meaningful without table restrictions, so table rules 
have to be defined if you want column restrictions. You can have more than one rule set per schema, but in this case the most 
restrictive rule set will be the one that takes precedent. This behavior can be used as an effective way to disable access to specific 
schemas. For example,

    [
        { schema => '#anySchema', '#anyTable' },
        { schema => 'forbiddenSchema' }
    ]

will first allow access to all tables in any schema, and then restrict access to any table in 'forbiddenSchema'. Table verification and
column verification take place in separate steps. During table verification, rule sets are selected based on the schema property. The
remaining keys in each rule set %hash correspond to tables that the query object is allowed access to.

If there is a key in the rule set with the special name '#anyTable', access to any table in that rule set (schema) will be allowed.
For other keys (table names), the value needs to be set to an array of column names. During column verification, this list will be 
used to determine whether the query object has access to particular columns in the table.

As with schemas, access to a table can be governed by more than one 'table rule'. In this case, the most restrictive rule is the one 
that takes precedent. For example,

    [
        { schema => 'allowedSchema', '#anyTable', 'allowedTable' => [ 'allowedColumnA', 'allowedColumnB' ] }
    ]

will allow access to all columns of all tables in the schema 'allowedSchema', but for the table 'allowedTable', only access to
columns 'allowedColumnA' and 'allowedColumnB' is allowed. Similarly, 

    [
        { schema => 'allowedSchema', '#anyTable', 'forbiddenTable' => [] }
    ]

will allow access to all columns of all tables in the schema 'allowedSchema', but block access to the table 'forbiddenTable'.
(Technically, it is only blocking access to the columns in that table, but this is effectively the same thing for most SQL operations).

If the column list contains the special string '#anyColumn' access to all columns in the table will be allowed. So, 

    [
        { schema => 'allowedSchema', 'allowedTable1' => [ '#anyColumn' ], 'allowedTable2' => [ 'allowedColumn1' ] }
    ]

will allow access to any column in 'allowedTable1' and only column 'allowedColumn1' of 'allowedTable2'. Access to all other tables
in 'allowedSchema' will be blocked.

This module is designed to err on the side of caution, and in so doing will always take the more restrictive course of action in the
case of ambiguity. As such, many SQL queries will probably fail validation if you don't use fully-qualified table and column identifiers,
which is generally recommended as good practice when writing SQL queries anyway. However, if you are writing simple queries and find this 
to be annoying, you can turn off whitelisting and rely only on database-level security.

It is important to note that while this module aims to reduce the attack surface, it is NOT a replacement for database-level security. But
when combined with good database-level security (ex: per-user schemas and Kerberos), it provides for reasonably safe SQL query generation
using data from untrusted sources (ex: web browsers).

=head1 AUTHOR

Chris Hoefler <bhoefler@draper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Hoefler.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
