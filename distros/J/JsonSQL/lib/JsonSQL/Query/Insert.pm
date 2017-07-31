# ABSTRACT: JsonSQL::Query::Insert object. Stores a Perl representation of a set of INSERT statements created from a JSON string.



use strict;
use warnings;
use 5.014;

package JsonSQL::Query::Insert;

our $VERSION = '0.4'; # VERSION

use base qw( JsonSQL::Query::Query );

use JsonSQL::Validator;
use JsonSQL::Error;
use JsonSQL::Param::Insert;



sub new {
    my ( $class, $query_rulesets, $json_query ) = @_;
    
    # Inherit from JsonSQL::Query::Query base class.
    my $self = $class->SUPER::new($query_rulesets, 'insert');
    if ( eval { $self->is_error } ) {
        return (0, "Could not create JsonSQL INSERT query object: $self->{message}");
    }
    
    # Validate the $json_query to make sure it conforms to the 'insert' JSON schema.
    my $validator = $self->{_validator};
    my $multiinserthashref = $validator->validate_schema($json_query);
    if ( eval { $multiinserthashref->is_error } ) {
        return (0, $multiinserthashref->{message});
    }
    
    # Save the default DB schema to use, if one is provided.
    if ( defined $multiinserthashref->{defaultschema} ) {
        $self->{_defaultSchema} = $multiinserthashref->{defaultschema};
    }
    
    $self->{_inserts} = [];
    my @insert_errors;
    
    for my $inserthashref ( @{ $multiinserthashref->{inserts} } ) {
        # Note: for safety, no default table parameters are supplied, so all column identifiers
        # must be fully qualified or they will fail whitelisting checks.
        my $insertObj = JsonSQL::Param::Insert->new($inserthashref, $self);
        if ( eval { $insertObj->is_error } ) {
            push(@insert_errors, $insertObj->{message});
        } else {
            push (@{ $self->{_inserts} }, $insertObj);
        }
    }
    
    if ( @insert_errors ) {
        my $err = "Error(s) constructing one or more INSERT statements: \n\t";
        $err .= join("\n\t", @insert_errors);
        return (0, $err);
    } else {
        bless $self, $class;
        return $self;
    }
}


sub get_all_inserts {
    my $self = shift;
    
    my @sql_stmts;
    my @sql_binds;
    for my $insertObj (@{ $self->{_inserts} }) {
        my ($sql, $binds) = $insertObj->get_insert_stmt($self);
        push(@sql_stmts, $sql);
        push(@sql_binds, $binds);
    }
    
    return (\@sql_stmts, \@sql_binds);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JsonSQL::Query::Insert - JsonSQL::Query::Insert object. Stores a Perl representation of a set of INSERT statements created from a JSON string.

=head1 VERSION

version 0.4

=head1 SYNOPSIS

Use this to generate an SQL INSERT statement from a JSON string.

To use this:

    use JsonSQL::Query::Insert;
    
    my $jsonString = '{
        "inserts": [
            {
                "table": {"table": "table1", "schema": "MySchema"},
                "values": [
                    {"column": "column1", "value": "value1"},
                    {"column": "column2", "value": "value2"}
                ],
                "returning": [{"column": "column1", "as": "bestcolumn"}, {"column": "column2"}]
            },
            {
                "table": {"table": "table2"},
                "values": [
                    {"column": "columnA", "value": "valueA"},
                    {"column": "columnB", "value": "valueB"}
                ]
            }
        ]
    }';
    
    my $whitelisting_rules = [
        { schema => '#anySchema', 'table1' => [ 'column1', 'column2' ], 'table2' => [ 'columnA', 'columnB' ] }
    ];
    
    my ( $insertObj, $err ) = JsonSQL::Query::Insert->new($whitelisting_rules, $jsonString);
    if ( $insertObj ) {
        my ( $sql, $binds ) = $insertObj->get_all_inserts;
        <...>
    } else {
        die $err;
    }

Now you can go ahead and use $sql and $binds directly with the L<DBI> module to do the query.

=head1 DESCRIPTION

This is a JsonSQL Query module that supports SQL generation for batched INSERT statements.

Examples of INSERT features supported by this module:

=head2 A single INSERT statement (minimum),

    {
        "inserts": [
            {
                "table": {"table": "MyTable"},
                "values": [
                    {"column": "Animal", "value": "Giraffe"},
                    {"column": "Color", "value": "Yellow/Brown"}
                ]
            }
        ]
    }

=head2 An INSERT statement with a RETURNING clause,

    {
        "inserts": [
            {
                "table": {"table": "MyTable"},
                "values": [
                    {"column": "Animal", "value": "Giraffe"},
                    {"column": "Color", "value": "Yellow/Brown"}
                ],
                "returning": [
                    {"column": "animal_id"}
                ]
            }
        ]
    }

=head2 Multiple INSERT statements for batch processing,

    {
        "inserts": [
            {
                "table": {"table": "MyTable"},
                "values": [
                    {"column": "Animal", "value": "Giraffe"},
                    {"column": "Color", "value": "Yellow/Brown"}
                ]
            },
            {
                "table": {"table": "MyTable"},
                "values": [
                    {"column": "Animal", "value": "Elephant"},
                    {"column": "Color", "value": "Grey"}
                ]
            },
            {
                "table": {"table": "MyTable"},
                "values": [
                    {"column": "Animal", "value": "Horse"},
                    {"column": "Color", "value": "Black"}
                ]
            }
        ]
    }

=head2 Structure of INSERT JSON object:

The top-level property is the "inserts" property, which is an array of objects representing each INSERT. Each INSERT object has the
following properties:

=head3 Required,

=over

=item table => { table => "table1" }

    Generates: INSERT INTO 'table1'
See L<JsonSQL::Param::Table> for more info.

=item values => [ { column => "scientist", value = "Einstein" }, { column => "theory", value = "Relativity" } ]

    Generates ('scientist','theory') VALUES (?,?)
        Bind: ['Einstein','Relativity']
See L<JsonSQL::Param::InsertValues> for more info.

=back

=head3 Optional,

=over

=item returning => { column => "column_id" }

    Generates: RETURNING 'column_id';
See L<JsonSQL::Param::Insert> for more info.

=back

=head3 Additional Properties,

=over

=item defaultschema => 'myschema'

If you are using DB schemas, this property can be used to generate the schema identifier for your queries. Particularly useful for
per-user DB schemas.

=back

See L<JsonSQL::Schemas::insert> to view the restrictions enforced by the JSON schema.

=head2 Whitelisting Module

A set of whitelisting rules is required to successfully use this module to generate SQL. See L<JsonSQL::Validator> to learn how this works.

=head1 METHODS

=head2 Constructor new($query_rulesets, $json_query)

Instantiates and returns a new JsonSQL::Query::Insert object.

    $query_rulesets      => The whitelisting rules to validate the query with.
    $json_query          => A stringified JSON object representing the query.

Returns (0, <error message>) on failure.

=head2 ObjectMethod get_all_inserts -> ( $sql, $binds )

Generates the SQL statement represented by the object. Returns:

    $sql            => An arrayref of SQL INSERT strings.
    $binds          => An arrayref of arrays of parameterized values to pass with each INSERT query.

=head1 AUTHOR

Chris Hoefler <bhoefler@draper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Hoefler.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
