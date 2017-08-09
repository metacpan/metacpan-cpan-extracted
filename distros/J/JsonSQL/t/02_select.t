#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;
use 5.014;

use Test::More tests => 9;

use JsonSQL::Query::Select;

# Create a simple JsonSQL::Query::Select with a basic rule set.
my $basic_ruleset = [ { schema => '#anySchema', '#anyTable' } ];
my $simple_select = '{
    "fields": [
      {"column": "*"}
    ],
    "from": [
      {"table": "test_table"}
    ]
}';

my $simple_result = qq(SELECT *\nFROM "test_table");

my ( $select_query, $err ) = JsonSQL::Query::Select->new($basic_ruleset, $simple_select);
ok($select_query, 'Create a simple SELECT query object');

my ( $simple_sql, $simple_binds ) = $select_query->get_select;
is($simple_sql, $simple_result, 'A simple SELECT');

# A more complex SELECT
my $qualified_select = '{
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
}';

my $qualified_result = qq(SELECT "field1", "field2" AS "test"\nFROM "MySchema"."table1"\nWHERE (("field2" = ?) AND ("field1" = ?) AND (("field2" = ?) OR ("field3" > ?))));

( $select_query, $err ) = JsonSQL::Query::Select->new($basic_ruleset, $qualified_select);
ok($select_query, 'Create a more complicated SELECT query object');

my ( $qualified_sql, $qualified_binds ) = $select_query->get_select;
is($qualified_sql, $qualified_result, 'A SELECT with aliases, schema, and WHERE clause');

# A SELECT with joins
my $join_select = '{
    "defaultschema": "MySchema",
    "fields": [
                {"table": "table1", "column": "field1"},
                {"table": "table2", "column": "*"}
        ],
        "joins": [
            {"jointype": "inner", "from": {"table": "table1"}, "to": {"table": "table2"}, "on": {"eq": {"field": {"table": "table2", "column": "field2"}, "value": {"table": "table2", "column": "field1"}} }}
        ]
}';

my $join_result = qq(SELECT "MySchema"."table1"."field1", "MySchema"."table2".*\nFROM "MySchema"."table1" INNER JOIN "MySchema"."table2" ON "MySchema"."table2"."field2" = "MySchema"."table2"."field1");

( $select_query, $err ) = JsonSQL::Query::Select->new($basic_ruleset, $join_select);
ok($select_query, 'Create a SELECT query object with JOIN');

my ( $join_sql, $join_binds ) = $select_query->get_select;
is($join_sql, $join_result, 'A SELECT with default schema and JOIN clause');

# One simple whitelisting test
my $simple_ruleset = [ { schema => '#anySchema', 'AllowedTable' => ['#anyColumn'], 'RestrictedTable' => [] } ];
my $allowed_select = '{
    "fields": [
      {"column": "*"}
    ],
    "from": [
      {"table": "AllowedTable"}
    ]
}';

my $allowed_result = qq(SELECT *\nFROM "AllowedTable");

( $select_query, $err ) = JsonSQL::Query::Select->new($simple_ruleset, $allowed_select);
ok($select_query, 'Create a simple SELECT with whitelisting in effect');

my ( $allowed_sql, $allowed_binds ) = $select_query->get_select;
is($allowed_sql, $allowed_result, 'SELECT permitted');

my $restricted_select = '{
    "fields": [
      {"column": "*"}
    ],
    "from": [
      {"table": "RestrictedTable"}
    ]
}';

( $select_query, $err ) = JsonSQL::Query::Select->new($simple_ruleset, $restricted_select);
ok($select_query == 0, 'A simple SELECT that is not permitted by the whitelisting');
print $err;
