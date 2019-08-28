use strict;
use warnings;
use Test::More tests => 11;
use Test::Exception;

require_ok('Geoffrey::Converter::Pg::Index');
my $o_pg = new_ok('Geoffrey::Converter::Pg::Index', []);

#is $o_pg->add,   q~CREATE TABLE {0} ( {1} )~, 'plain add test';
throws_ok { $o_pg->drop(); } 'Geoffrey::Exception::RequiredValue::IndexName', 'plain type call test without param';

is $o_pg->drop('test_table'), q~DROP INDEX test_table~, 'plain drop test with param';

is $o_pg->list, q~SELECT
                U.usename                AS user_name,
                ns.nspname               AS schema_name,
                idx.indrelid :: REGCLASS AS table_name,
                i.relname                AS index_name,
                am.amname                AS index_type,
                idx.indkey,
                ARRAY(
                SELECT
                    pg_get_indexdef(idx.indexrelid, k + 1, TRUE)
                FROM
                    generate_subscripts(idx.indkey, 1) AS k
                ORDER BY k
                ) AS index_keys,
                (idx.indexprs IS NOT NULL) OR (idx.indkey::int[] @> array[0]) AS is_functional,
                idx.indpred IS NOT NULL AS is_partial
            FROM 
                pg_index AS idx
                JOIN pg_class AS i ON i.oid = idx.indexrelid
                JOIN pg_am AS am ON i.relam = am.oid
                JOIN pg_namespace AS NS ON i.relnamespace = NS.OID
                JOIN pg_user AS U ON i.relowner = U.usesysid
            WHERE
                    NOT nspname LIKE 'pg%'
                AND NOT idx.indisprimary
                AND NOT idx.indisunique~, 'plain list test';

throws_ok { $o_pg->add(); } 'Geoffrey::Exception::General::ParamsMissing', 'plain add call test without param';

throws_ok { $o_pg->add({column => 'test'}); } 'Geoffrey::Exception::RequiredValue::TableName',
    'plain add call test without param';

throws_ok { $o_pg->add({table => 'test'}); } 'Geoffrey::Exception::RequiredValue::RefColumn',
    'plain add call test without param';

like(
    $o_pg->add({table => 'test_table', column => 'test_column'}),
    qr/CREATE INDEX ix_test_table_\d+ ON test_table/,
    'plain add call test without name'
);

is $o_pg->add({table => 'test_table', column => 'test_column', name => 'index_name'}),
    q~CREATE INDEX index_name ON test_table (test_column)~, 'plain add call test wit name';

is $o_pg->add({table => 'test_table', column => ['test_column', 'test_column_1'], name => 'index_name'}),
    q~CREATE INDEX index_name ON test_table (test_column, test_column_1)~, 'plain add call test wit name';
