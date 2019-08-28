use strict;
use warnings;
use Test::More tests => 8;

require_ok('Geoffrey::Converter::Pg::Tables');
my $o_pg = new_ok('Geoffrey::Converter::Pg::Tables', []);

is $o_pg->add,   q~CREATE TABLE {0} ( {1} )~, 'plain add test';
is $o_pg->drop,  q~DROP TABLE {0}~,           'plain drop test';
is $o_pg->alter, q~ALTER TABLE {0}~,          'plain alter test';

is $o_pg->add_column, q~ALTER TABLE {0} ADD COLUMN {1}~, 'plain add_column test';

is $o_pg->list, q~SELECT t.*
          FROM information_schema.tables t
          WHERE t.table_type != 'VIEW' AND t.table_schema=?~, 'plain list test';

is $o_pg->s_list_columns, q~SELECT *
          FROM information_schema.columns
          WHERE table_name = ?
          AND table_schema = ?~, 'plain s_list_columns test';
