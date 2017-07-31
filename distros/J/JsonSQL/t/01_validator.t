#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;
use 5.014;

use Test::More tests => 19;

use JsonSQL::Validator;

# Load a 'select' validator with a basic rule set.
my $basic_ruleset = [ { schema => '#anySchema', '#anyTable' } ];
my $select_validator = JsonSQL::Validator->new('select', $basic_ruleset);

is(ref($select_validator), 'JsonSQL::Validator', 'SELECT validator init');

## Check 'select' query validation.
# A good query.
my $good_select = '{
    "fields": [
      {"column": "*"}
    ],
    "from": [
      {"table": "test_table"}
    ]
  }';

my $good_select_query = $select_validator->validate_schema($good_select);
isnt(ref($good_select_query), 'JsonSQL::Error', 'Valid SELECT query');

# A query with invalid JSON.
my $select_invalidjson = '{
    fields: [
      {"column": "*"}
    ],
    "from": [
      {"table": "test_table"}
    ]
  }';

my $select_invalidjson_query = $select_validator->validate_schema($select_invalidjson);
is(ref($select_invalidjson_query), 'JsonSQL::Error', 'Invalid SELECT JSON');

# A query with valid JSON, but doesn't conform to the schema.
my $select_invalidquery = '{
    "fields": [
      {"column": "*)"}
    ],
    "from": [
      {"table": "test_table"}
    ]
  }';

my $select_invalid_query = $select_validator->validate_schema($select_invalidquery);
is(ref($select_invalid_query), 'JsonSQL::Error', 'Invalid SELECT query');

# Load a 'insert' validator with a basic rule set.
my $insert_validator = JsonSQL::Validator->new('insert', $basic_ruleset);

is(ref($insert_validator), 'JsonSQL::Validator', 'INSERT validator init');

## Check 'insert' query validation.
# A good query.
my $good_insert = '{
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

my $good_insert_query = $insert_validator->validate_schema($good_insert);
isnt(ref($good_insert_query), 'JsonSQL::Error', 'Valid INSERT query');

# An invalid query.
my $insert_invalidquery = '{
    "inserts": [
        {
            "table": {"table": "32", "schema": "MySchema"},
            "values": [
                {"column": "column1", "value": "value1"},
                {"column": "column2", "value": "value2"}
            ],
            "returning": [{"column": "column1", "as": "bestcolumn"}, {"column": "column2"}]
        }
    ]}';

my $insert_invalid_query = $insert_validator->validate_schema($insert_invalidquery);
is(ref($insert_invalid_query), 'JsonSQL::Error', 'Invalid INSERT query');

## Check access validation.
# Permissive rule set
my $table_check_permitted = $select_validator->check_table_allowed({ table => 'MyTable' });
my $schema_check_permitted = $select_validator->check_table_allowed({ schema => 'MySchema', table => 'MyTable' });
my $column_check_permitted = $select_validator->check_field_allowed($table_check_permitted, 'column1');

isnt(ref($table_check_permitted), 'JsonSQL::Error', 'Table check permitted');
isnt(ref($schema_check_permitted), 'JsonSQL::Error', 'Schema check permitted');
isnt(ref($column_check_permitted), 'JsonSQL::Error', 'Column check permitted');

# Restrictive rule set
my $restrictive_ruleset = [{ schema => 'MySchema', 'AllowedTable' => ['AllowedColumn'], 'RestrictedTable' => []}];
my $restricted_select = JsonSQL::Validator->new('select', $restrictive_ruleset);
isnt(ref($restricted_select), 'JsonSQL::Error', 'SELECT validator with restrictions init');

my $table_check_ok = $restricted_select->check_table_allowed({ schema => 'MySchema', table => 'AllowedTable' });
isnt(ref($table_check_ok), 'JsonSQL::Error', 'Table check allowed by restrictive set');

my $column_check_ok = $restricted_select->check_field_allowed($table_check_ok, 'AllowedColumn');
isnt(ref($column_check_ok), 'JsonSQL::Error', 'Column check allowed by restrictive set');

my $blocked_noschema = $restricted_select->check_table_allowed({ table => 'AllowedTable' });
my $blocked_badschema = $restricted_select->check_table_allowed({ schema => 'MyCoolSchema', table => 'AllowedTable' });
my $blocked_badtable = $restricted_select->check_table_allowed({ schema => 'MySchema', table => 'AnotherTable' });
my $blocked_restrictedcolumn = $restricted_select->check_field_allowed($table_check_ok, 'AnotherColumn');
my $restricted_table = $restricted_select->check_table_allowed({ schema => 'MySchema', table => 'RestrictedTable' });
my $blocked_nocolumns = $restricted_select->check_field_allowed($restricted_table, 'AnyColumn');

is(ref($blocked_noschema), 'JsonSQL::Error', 'Null schema not permitted');
is(ref($blocked_badschema), 'JsonSQL::Error', 'Bad schema not permitted');
is(ref($blocked_badtable), 'JsonSQL::Error', 'Table not permitted');
is(ref($blocked_restrictedcolumn), 'JsonSQL::Error', 'Column not permitted');
isnt(ref($restricted_table), 'JsonSQL::Error', 'Restricted table permitted');
is(ref($blocked_nocolumns), 'JsonSQL::Error', 'Columns in restricted table not permitted');
