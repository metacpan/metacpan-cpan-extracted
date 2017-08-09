# ABSTRACT: JsonSQL::Query::Select object. Stores a Perl representation of a SELECT statement created from a JSON string.



use strict;
use warnings;
use 5.014;

package JsonSQL::Query::Select;

our $VERSION = '0.41'; # VERSION

use base qw( JsonSQL::Query::Query );

use JsonSQL::Validator;
use JsonSQL::Error;
use JsonSQL::Param::Fields;
use JsonSQL::Param::Field;
use JsonSQL::Param::Tables;
use JsonSQL::Param::Joins;
use JsonSQL::Param::ConditionDispatcher;
use JsonSQL::Param::OrderBy;

# Using this as a crutch for now, but will deprecate at some point.
use SQL::Maker::Select;

#use Data::Dumper;
#use constant DEBUG => 0; # toggle me



sub new {
    my ( $class, $query_rulesets, $json_query, $quote_char ) = @_;
    
    # Inherit from JsonSQL::Query::Query base class.
    my $self = $class->SUPER::new($query_rulesets, 'select', $quote_char);
    if ( eval { $self->is_error } ) {
        return (0, "Could not create JsonSQL SELECT query object: $self->{message}");
    }
    
    # Validate the $json_query to make sure it conforms to the 'select' JSON schema.
    my $validator = $self->{_validator};
    my $selecthashref = $validator->validate_schema($json_query);
    if ( eval { $selecthashref->is_error } ) {
        return (0, $selecthashref->{message});
    }
    
    # Save the default DB schema to use, if one is provided.
    if ( defined $selecthashref->{defaultschema} ) {
        $self->{_defaultSchema} = $selecthashref->{defaultschema};
    }
    
    # For our purposes, a minimum SELECT query must have at least one FROM, which can be specified on its own or as part of a JOIN.
    if ( defined $selecthashref->{from} ) {
        my $selectfrom = JsonSQL::Param::Tables->new($selecthashref->{from}, $self);
        if ( eval { $selectfrom->is_error } ) {
            return (0, $selectfrom->{message});
        } else {
            $self->{_selectFrom} = $selectfrom;
        }
    }
    
    if ( defined $selecthashref->{joins} ) {
        my $selectjoins = JsonSQL::Param::Joins->new($selecthashref->{joins}, $self);
        if ( eval { $selectjoins->is_error } ) {
            return (0, $selectjoins->{message});
        } else {
            $self->{_selectJoins} = $selectjoins;
        }
    }
    
    my $fromExists = ( defined $self->{_selectFrom} && scalar @{ $self->{_selectFrom} } );
    my $joinsExist = ( defined $self->{_selectJoins} && scalar @{ $self->{_selectJoins} } );
    unless ( $fromExists or $joinsExist ) {
        return (0, "No valid from_items for SELECT statement.");
    }
    
    # Although it is not recommended, column identifiers can be specified without a table param for simple queries.
    # In these limited cases where there is no ambiguity, we take the from_item as the table param for the column.
    # Unfortunately, there is no clean way to support this for JOINs. So, column identifiers that are part of JOIN 
    # conditions must be fully qualified, or else they will probably fail the whitelisting check.
    my $default_table_rules = [];
    if ( $fromExists ) {
        # Note: we are taking just the first from_item in the list. So, whitelisting checks will probably fail if 
        # there is more than one FROM table. Best to use fully qualified column identifiers in this case.
        $default_table_rules = $self->{_selectFrom}->[0]->{_tableRules};
    }
    
    # For our purposes, a minimum SELECT query must have field expressions defined.
    my $selectfields = JsonSQL::Param::Fields->new($selecthashref->{fields}, $self, $default_table_rules);
    if ( eval { $selectfields->is_error } ) {
        return (0, $selectfields->{message});
    }
    
    if ( @{ $selectfields } ) {
        $self->{_selectFields} = $selectfields;
    } else {
        return (0, "No valid field expressions for SELECT statement.");
    }
    
    # The rest of the parameters are optional, but we still break on parsing errors.
    my @select_errors;
    
    $self->{_selectDistinct} = $selecthashref->{distinct} || 'false';
    
    if ( defined $selecthashref->{where} ) {
        my $selectwhere = JsonSQL::Param::ConditionDispatcher->parse($selecthashref->{where}, $self, $default_table_rules);
        if ( eval { $selectwhere->is_error } ) {
            push(@select_errors, "Error creating WHERE clause: $selectwhere->{message}");
        } else {
            $self->{_selectWhere} = $selectwhere;
        }
    }

    if ( defined $selecthashref->{groupby} ) {
        my $selectgroupby = JsonSQL::Param::Fields->new($selecthashref->{groupby}, $self, $default_table_rules);
        if ( eval { $selectgroupby->is_error } ) {
            push(@select_errors, "Error creating GROUP BY clause: $selectgroupby->{message}");
        } else {
            $self->{_selectGroupBy} = $selectgroupby;
        }
    }

    if ( defined $selecthashref->{having} ) {
        my $selecthaving = JsonSQL::Param::ConditionDispatcher->parse($selecthashref->{having}, $self, $default_table_rules);
        if ( eval { $selecthaving->is_error } ) {
            push(@select_errors, "Error creating HAVING clause: $selecthaving->{message}");
        } else {
            $self->{_selectHaving} = $selecthaving;
        }
    }

    if (defined $selecthashref->{orderby}) {
        my $selectorderby = JsonSQL::Param::OrderBy->new($selecthashref->{orderby}, $self, $default_table_rules);
        if ( eval { $selectorderby->is_error } ) {
            push(@select_errors, "Error creating ORDER BY clause: $selectorderby->{message}");
        } else {
            $self->{_selectOrderBy} = $selectorderby;
        }
    }

    if (defined $selecthashref->{limit}) {
        $self->{_selectLimit} = $selecthashref->{limit};
    }
        
    if (defined $selecthashref->{offset}) {
        $self->{_selectOffset} = $selecthashref->{offset};
    }
    
    if ( @select_errors ) {
        my $err = "Error(s) parsing some SELECT parameters: \n\t";
        $err .= join("\n\t", @select_errors);
        return (0, $err);
    } else {
        bless $self, $class;
        return $self;
    }
}


sub get_select {
    my $self = shift;
    
    my $makerObj = SQL::Maker::Select->new(quote_char => '"');
    
    for my $field (@{ $self->{_selectFields}->get_fields($self) }) {
        if (ref $field eq 'HASH') {
            $makerObj->add_select(%$field);
        } else {
            $makerObj->add_select($field);
        }
    }
    
    if (defined $self->{_selectFrom}) {
        for my $from (@{ $self->{_selectFrom}->get_tables($self) }) {
            $makerObj->add_from($from);
        }
    }

    if (defined $self->{_selectJoins}) {
        for my $join (@{ $self->{_selectJoins}->get_joins($self) }) {
            $makerObj->add_join(%$join);
        }
    }
    
    if (defined $self->{_selectWhere} ) {
        my ($sql, @binds) = $self->{_selectWhere}->get_cond($self);
        $makerObj->add_where_raw($sql, @binds);
    }

    if (defined $self->{_selectGroupBy}) {
        for my $grouping (@{ $self->{_selectGroupBy}->get_fields($self) }) {
            $makerObj->add_group_by($grouping);
        }
    }

    ## SQL::Maker doesn't support this at the moment, so leaving disabled.
#    if (defined $self->{_selectHaving}) {
#        $makerObj->add_having($self->{_selectHaving}->get_sql_obj);
#    }

    if (defined $self->{_selectOrderBy}) {
        for my $ordering (@{ $self->{_selectOrderBy}->get_ordering($self) }) {
#print "Ref: " . ref($ordering) . "\n";
            if ( ref($ordering) eq 'ARRAY' ) {
#print "@$ordering\n";
            $makerObj->add_order_by(@$ordering);
            } else {
#print "$ordering\n";
            $makerObj->add_order_by($ordering);
            }
#print Dumper($ordering);
        }
#die;
    }
    
    if (defined $self->{_selectLimit}) {
        $makerObj->limit($self->{_selectLimit});
    }
    
    if (defined $self->{_selectOffset}) {
        $makerObj->offset($self->{_selectOffset});
    }
        
    my $sql = $makerObj->as_sql;

    ## SMELL: Hack to add support for SELECT DISTINCT
    if ( $self->{_selectDistinct} eq 'true' ) {
        $sql =~ s/SELECT/SELECT DISTINCT/;
    }
 
    my @binds = $makerObj->bind;
    
    return ($sql, \@binds);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JsonSQL::Query::Select - JsonSQL::Query::Select object. Stores a Perl representation of a SELECT statement created from a JSON string.

=head1 VERSION

version 0.41

=head1 SYNOPSIS

Use this to generate an SQL SELECT statement from a JSON string.

To use this:

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
    
    my ( $selectObj, $err ) = JsonSQL::Query::Select->new($whitelisting_rules, $jsonString);
    if ( $selectObj ) {
        my ( $sql, $binds ) = $selectObj->get_select;
        <...>
    } else {
        die $err;
    }

Now you can go ahead and use $sql and $binds directly with the L<DBI> module to do the query.

=head1 DESCRIPTION

This is a JsonSQL Query module that supports SQL generation for a broad range of the most common SQL SELECT features, including JOINs.

Examples of SELECT features supported by this module:

=head2 A simple SELECT statement (minimum),

    {
        "fields": [
            {"column": "*"}
        ],
        "from": [
            {"table": "my_table"}
        ]
    }

=head2 A more complicated SELECT statement,

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

=head2 A SELECT statement with JOINs,

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

=head2 Mapping of JSON object properties to SELECT parameters:

=head3 Required,

=over

=item fields => [ { table => "table1", column => "column1" }, { table => "table1", column => "column2" } ]

    Generates: "table1"."column1", "table1"."column2"
See L<JsonSQL::Param::Fields> and L<JsonSQL::Param::Field> for more info.

=item from => [ { schema => "myschema", table = "table1" } ] ( if you are using a JOIN, you can omit the FROM )

    Generates FROM "myschema"."table1"
See L<JsonSQL::Param::Tables> and L<JsonSQL::Param::Table> for more info.

=back

=head3 Optional,

=over

=item joins => [ { jointype => "inner", from => { table => "table1" }, to => { table => "table2" }, on => { eq => { field => { table => "table1", column => "column1" }, value => { table => "table2", column: "column2"}} } } ]

    Generates: FROM "table1" INNER JOIN "table2" ON "table1"."column1" = "table2"."column2"
See L<JsonSQL::Param::Joins> and L<JsonSQL::Param::Join> for more info.

=item where => { eq => { field => { table => "table1", column => "column1" }, value => 32 } }

    Generates: WHERE "table1"."column1" = ?
        Bind: [ 32 ]
See L<JsonSQL::Param::Condition> and L<JsonSQL::Param::ConditionDispatcher> for more info.

=item orderby => [ { field => { table => "table1", column => "column1" }, order => 'ASC'} ]

    Generates: ORDER BY "table"."column1" ASC
See L<JsonSQL::Param::OrderBy> and L<JsonSQL::Param::Order> for more info.

=item groupby => [ { table => "table1", column => "column1" } ]

    Generates: GROUP BY "table1"."column1"
See L<JsonSQL::Param::Fields> and L<JsonSQL::Param::Field> for more info.

=item having => { eq => { field => { table => "table1", column => "column1" }, value => 32 } }

    Generates: HAVING "table1"."column1" = ?
        Bind: [ 32 ]
See L<JsonSQL::Param::Condition> and L<JsonSQL::Param::ConditionDispatcher> for more info.

=item distinct => 'true'

    Generates: DISTINCT

=item limit => 23

    Generates: LIMIT ?
        Bind: [ 23 ]

=item offset => 12

    Generates: OFFSET ?
        Bind: [ 12 ]

=back

=head3 Additional Properties,

=over

=item defaultschema => 'myschema'

If you are using DB schemas, this property can be used to generate the schema identifier for your queries. Particularly useful for
per-user DB schemas.

=back

See L<JsonSQL::Schemas::select> to view the restrictions enforced by the JSON schema.

=head2 Whitelisting Module

A set of whitelisting rules is required to successfully use this module to generate SQL. See L<JsonSQL::Validator> to learn how this works.

=head1 METHODS

=head2 Constructor new($query_rulesets, $json_query, $quote_char)

Instantiates and returns a new JsonSQL::Query::Select object.

    $query_rulesets      => The whitelisting rules to validate the query with.
    $json_query          => A stringified JSON object representing the query.
    $quote_char          => Optional: the character to use for quoting identifiers. The SUPER defaults to ANSI double quotes.

Returns (0, <error message>) on failure.

=head2 ObjectMethod get_select -> ( $sql, $binds )

Generates the SQL statement represented by the object. Returns:

    $sql            => An SQL SELECT string.
    $binds          => An arrayref of parameterized values to pass to the query.

=head1 AUTHOR

Chris Hoefler <bhoefler@draper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Hoefler.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
