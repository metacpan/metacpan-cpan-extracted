# ABSTRACT: JsonSQL distribution. A collection of modules for generating safe SQL from JSON strings.






use strict;
use warnings;
use 5.014;

package JsonSQL;

our $VERSION = '0.4'; # VERSION


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JsonSQL - JsonSQL distribution. A collection of modules for generating safe SQL from JSON strings.

=head1 VERSION

version 0.4

=head1 SYNOPSIS

This is a set of modules used to turn a JSON string representing an SQL query into an appropriate SQL statement.

For example,

    use JsonSQL::Query::Select;
    
    my $jsonString = '{
        "fields": [
            {"column": "*"}
        ],
        "from": [
            {"table": "my_table"}
        ]
    }';
    
    my $whitelisting_rules = [
        { schema => '#anySchema', 'my_table' => [ '#anyColumn' ] }
    ];
    
    my $selectObj = JsonSQL::Query::Select->new($whitelisting_rules, $jsonString);
    my ( $sql, $binds ) = $selectObj->get_select;

Generates:

    $sql = 'SELECT * FROM 'my_table';
    $binds = <arrayref of parameterized values, if applicable>

Now you can go ahead and use $sql and $binds directly with the L<DBI> module to do the query.

=head1 DESCRIPTION

The purpose of this distribution is to provide a reasonably safe mechanism for SQL query generation using data from untrusted sources, namely
web browsers. JSON is a convenient format native to JavaScript (ECMAScript), which can be translated to and from Perl objects fairly easily. 
JSON was selected to provide a structured format for representing SQL statements such that it can be validated, checked for appropriate
access restrictions, and used to generate a well-formed and parameterized SQL statement that can be passed off to the L<DBI> module.

The format is somewhat verbose in a few places, with the idea that the user/developer needs to be very explicit when passing parameters
to the query. This makes it well-suited for handling untrusted data (for example, from HTML forms), but if you just need a basic SQL
generator, you would probably be better off looking at L<SQL::Abstract> or L<SQL::Maker> instead.

A simple SELECT statement,

    {
        "fields": [
            {"column": "*"}
        ],
        "from": [
            {"table": "my_table"}
        ]
    }

A more complicated SELECT statement,

    {
        "fields": [
            {"column": "field1"},
            {"column": "field2", "alias": "test"}
        ],
        "from": [
            {"table": "table1", "schema": "MySchema"}
        ], 
        "where": {
            "and": [
                { "eq": {"field": {"column": "field2"}, "value": "Test.Field2"} },
                { "eq": {"field": {"column": "field1"}, "value": "453.6"} },
                { "or": [
                    { "eq": {"field": {"column": "field2"}, "value": "field3"} },
                    { "gt": {"field": {"column": "field3"}, "value": "45"} }
                ]}
            ]
        }
    }

A SELECT statement with JOINs,

    {
        "fields": [
            {"column": "field1"},
            {"column": "field2", "alias": "test"}
        ],
        "joins": [
            {"jointype": "inner", "from": {"table": "table1", "schema": "MySchema"}, "to": {"table": "table2", "schema": "MySchema"}, "on": {"eq": {"field": {"column": "field2"}, "value": {"column": "field1"}} }}
        ],
        "where": {
            "and": [
                { "eq": {"field": {"column": "field2"}, "value": "Test.Field2"} },
                { "eq": {"field": {"column": "field1"}, "value": "453.6"} },
                { "or": [
                    { "eq": {"field": {"column": "field2"}, "value": "field3"} },
                    { "gt": {"field": {"column": "field3"}, "value": "45"} }
                ]}
            ]
        }
    }

A couple of INSERT statements,

    {
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
    ]}

For more detailed information, see the main query modules,

=over

=item L<JsonSQL::Query::Select> for SELECT statements

=item L<JsonSQL::Query::Insert> for INSERT statements

=back

An important feature of this distribution is whitelisting of allowed table and column identifiers. The whitelisting rules are defined
in the format,

    [
        {
            schema => 'schemaName' || '#anySchema',
            <'#anyTable' || allowedTableName1 => [ '#anyColumn' || allowedFieldName1, allowedFieldName2, ... ]>,
            <... additional table rules ...>
        },
        < ... additional rule sets ... >
    ]

and are saved in the query object when it is created. Subsequent building of the SQL statement examines this whitelist and returns an
error if table/column identifiers are used that have not been explicitly allowed. This allows JSON query generation and processing to
be safely separated and handled by different modules. The generating module (ex: a JavaScript client) is responsible for generating 
the query in stringified JSON format, and the processing module (ex: CGI script) is responsible for validating and processing that JSON
query into an SQL statement.

** Important Takeaway: JsonSQL query object construction and SQL generation will fail if you have not defined any whitelisting rules. **

It is not recommended, but you can disable the whitelisting module by defining a permissive rule,

    [ { schema => '#anySchema', '#anyTable' } ]

For more information on the whitelisting module, and how to construct rule sets, see the L<JsonSQL::Validator> module.

=head1 METHODS

=head2 Methods

This module is a documentation stub and does not contain any code. For detailed API information, see the appropriate modules.

For users, the main JsonSQL Query modules,

=over

=item * L<JsonSQL::Query::Select>

=item * L<JsonSQL::Query::Insert>

=back

For a description of the whitelisting feature,

=over

=item * L<JsonSQL::Validator>

=back

For developers,

=over

=item * The module used for returning errors:

L<JsonSQL::Error>

=item * To create a new schema,

L<JsonSQL::Schemas::Schema>

Examples: L<JsonSQL::Schemas::select> and L<JsonSQL::Schemas::insert>

=item * To create a new query object,

L<JsonSQL::Query::Query>

If your aim is to add additional features to an existing query object, you may also need to extend the schema.
If you are supporting a completely new query type, you will need to write an appropriate schema for it.

=item * To create additional query parameters,

The individual JsonSQL::Param modules have a lot of documentation.
Start with L<JsonSQL::Param::Tables> or L<JsonSQL::Param::Fields> to see how they work and how they integrate whitelist validation.
For WHERE-like parameters, see L<JsonSQL::Param::Condition> and L<JsonSQL::Param::ConditionDispatcher>.

=back

=head1 Changes

=over

=item I<0.1 - 0.3>

Internal Development

=item I<0.4>

First public release

=back

=head1 TODO

A short list, in more-or-less relative priority, of things I would like to change/fix as time allows.

=over

=item * Deprecate SQL::Maker dependency.

This is only useful for SELECT queries, and there are a fair amount of bugs that need to be worked around. To strengthen feature support,
a full SQL-generating backend needs to be written.

=item * Support Common Table Expressions (CTEs) and subqueries.

=item * Support additional query types: UPDATE, DELETE ( and maybe CREATE, DROP ).

=item * Support database-specific drivers to better deal with database-specific nuances.

=back

=head1 AUTHOR

Chris Hoefler <bhoefler@draper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Hoefler.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
