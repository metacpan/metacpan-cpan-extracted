#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;
use 5.014;

use Test::More tests => 10;

use JsonSQL::Query::Insert;

## Create a couple of INSERT test cases. 
# A JsonSQL::Query::Insert with a basic rule set.
my $basic_ruleset = [ { schema => '#anySchema', '#anyTable' } ];
my $simple_insert = '{
    "inserts": [
    {
        "table": {"table": "table1", "schema": "MySchema"},
        "values": [
            {"column": "column1", "value": "value1"},
            {"column": "column2", "value": "value2"}
        ]
    },
    {
        "table": {"table": "table2"},
        "values": [
            {"column": "columnA", "value": "valueA"},
            {"column": "columnB", "value": "valueB"}
        ]
    }
]}';

my $simple_result1 = qq(INSERT INTO "MySchema"."table1" ("column1","column2") VALUES (?,?));
my $simple_result2 = qq(INSERT INTO "table2" ("columnA","columnB") VALUES (?,?));

my ( $insert_query, $err ) = JsonSQL::Query::Insert->new($basic_ruleset, $simple_insert);
ok($insert_query, 'Create a simple INSERT query object');

my ( $simple_sql, $simple_binds ) = $insert_query->get_all_inserts;
is($simple_sql->[0], $simple_result1, 'A simple INSERT, statement #1');
is($simple_sql->[1], $simple_result2, 'A simple INSERT, statement #2');

# A more complex INSERT
my $complex_insert = '{
    "inserts": [
    {
        "table": {"table": "table1", "schema": "MySchema"},
        "values": [
            {"column": "column1", "value": "value1"},
            {"column": "column2", "value": "value2"}
        ],
        "returning": [{"column": "column1", "as": "bestcolumn"}, {"column": "column2"}]
    }
]}';

my $complex_result = qq(WITH insert_q AS (\nINSERT INTO "MySchema"."table1" ("column1","column2") VALUES (?,?)\nRETURNING "column1" AS "bestcolumn","column2"\n)\nSELECT * FROM insert_q);

( $insert_query, $err ) = JsonSQL::Query::Insert->new($basic_ruleset, $complex_insert);
ok($insert_query, 'Create a more complicated INSERT query object');

my ( $complex_sql, $complex_binds ) = $insert_query->get_all_inserts;
is($complex_sql->[0], $complex_result, 'An INSERT with RETURNING clause');


# One simple whitelisting test
my $simple_ruleset = [ { schema => 'MySchema', 'AllowedTable' => ['#anyColumn'], 'RestrictedTable' => [] } ];
my $allowed_insert = '{
    "defaultschema": "MySchema",
    "inserts": [
    {
        "table": {"table": "AllowedTable"},
        "values": [
            {"column": "column1", "value": "value1"},
            {"column": "column2", "value": "value2"}
        ]
    }
]}';

my $allowed_result = qq(INSERT INTO "MySchema"."AllowedTable" ("column1","column2") VALUES (?,?));

( $insert_query, $err ) = JsonSQL::Query::Insert->new($simple_ruleset, $allowed_insert);
ok($insert_query, 'Create a simple INSERT with whitelisting in effect');

my ( $allowed_sql, $allowed_binds ) = $insert_query->get_all_inserts;
is($allowed_sql->[0], $allowed_result, 'INSERT permitted');

my $restricted_insert_table = '{
    "defaultschema": "MySchema",
    "inserts": [
    {
        "table": {"table": "RestrictedTable"},
        "values": [
            {"column": "column1", "value": "value1"},
            {"column": "column2", "value": "value2"}
        ]
    }
]}';

( $insert_query, $err ) = JsonSQL::Query::Insert->new($simple_ruleset, $restricted_insert_table);
ok($insert_query == 0, 'Columns of an INSERT table that are not permitted by the whitelisting');
print "$err\n";

my $blocked_insert_table = '{
    "defaultschema": "MySchema",
    "inserts": [
    {
        "table": {"table": "AnotherTable"},
        "values": [
            {"column": "column1", "value": "value1"},
            {"column": "column2", "value": "value2"}
        ]
    }
]}';

( $insert_query, $err ) = JsonSQL::Query::Insert->new($simple_ruleset, $blocked_insert_table);
ok($insert_query == 0, 'An INSERT table that is not permitted by the whitelisting');
print "$err\n";

my $blocked_insert_schema = '{
    "defaultschema": "AnotherSchema",
    "inserts": [
    {
        "table": {"table": "AllowedTable"},
        "values": [
            {"column": "column1", "value": "value1"},
            {"column": "column2", "value": "value2"}
        ]
    }
]}';

( $insert_query, $err ) = JsonSQL::Query::Insert->new($simple_ruleset, $blocked_insert_schema);
ok($insert_query == 0, 'An INSERT schema that is not permitted by the whitelisting');
print "$err\n";
