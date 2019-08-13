use Test::More tests => 24;

use FindBin;
use strict;
use warnings;
use Test::Exception;
use Geoffrey::Converter::SQLite;

use_ok 'DBI';

{

    package Test::Mock::Geoffrey::Converter::Uniques;
    use parent 'Geoffrey::Role::ConverterType';
    sub append { 'CREATE UNIQUE INDEX CONCURRENTLY {0} ON {1} ({2})' }
    sub drop   { 'ALTER TABLE {0} DROP CONSTRAINT {1}' }
    sub list   { 'SELECT ALL FROM UNIQUE_KEYS' }
}
{

    package Test::Mock::Geoffrey::Converter::UniquesEmpty;
    use parent 'Geoffrey::Role::ConverterType';
}

require_ok('Data::Dumper');
use_ok 'Data::Dumper';

require_ok('Geoffrey::Action::Constraint::Unique');
use_ok 'Geoffrey::Action::Constraint::Unique';

require_ok('Geoffrey::Converter::SQLite');
use_ok 'Geoffrey::Converter::SQLite';

my $dbh = DBI->connect("dbi:SQLite:database=.tmp.sqlite")
  or plan skip_all => $DBI::errstr;
my $converter = Geoffrey::Converter::SQLite->new();
my $object    = new_ok(
    'Geoffrey::Action::Constraint::Unique',
    [ 'converter', $converter, 'dbh', $dbh ]
);

can_ok( 'Geoffrey::Action::Constraint::Unique',
    @{ [ 'add', 'alter', 'drop' ] } );
isa_ok( $object, 'Geoffrey::Action::Constraint::Unique' );

throws_ok { $object->add(); } 'Geoffrey::Exception::RequiredValue::TableName',
  'No table name thrown';

throws_ok { $object->add( 'main', {} ); }
'Geoffrey::Exception::RequiredValue::TableColumn',
  'No table columns thrown';

throws_ok { $object->add( 'main', 'wrong' ); }
'Geoffrey::Exception::General::WrongRef',
  'Thron if params is a string';

throws_ok { $object->add( 'main', [] ); }
'Geoffrey::Exception::General::WrongRef',
  'Thrown if params is a arrayref';

is $object->dryrun(1)->for_table(1)
  ->add( 'table', { columns => [qw/id name/], name => 'udx_test_table' } ),
  'CONSTRAINT udx_test_table UNIQUE ( id,name )',
  'Add unique not supportet thrown';

is $object->dryrun(1)
  ->for_table(0)
  ->add( 'table', { columns => [qw/id name/], name => 'udx_test_table' } ),
  'CREATE UNIQUE INDEX IF NOT EXISTS udx_test_table ON table ( id,name )',
  'Add unique not supportet thrown';

$object->dryrun(0);

is $object->add(
    'team', { columns => [qw/client name/], name => 'udx_test_table' }
  ),
  'CREATE UNIQUE INDEX IF NOT EXISTS udx_test_table ON team ( client,name )',
  'Add unique not supportet thrown';

throws_ok { $object->alter(); } 'Geoffrey::Exception::RequiredValue::TableName',
  'Alter unique not supportet thrown';

is $object->dryrun(1)->drop( 'main', { name => 'index_name' } ),
  'DROP INDEX IF EXISTS index_name',
  'Not unique not supportet thrown';

throws_ok { $object->dryrun(1)->list_from_schema('main'); }
'Geoffrey::Exception::NotSupportedException::ConverterType',
  'List uniques not supportet thrown';

$converter->unique( Test::Mock::Geoffrey::Converter::Uniques->new );
is(
    $object->add(
        'uq_table_01', { columns => [ 'id', 'name' ], name => 'test_table' }
    ),
    'CREATE UNIQUE INDEX IF NOT EXISTS test_table ON uq_table_01 ( id,name )',
    'Add unique index check'
);

throws_ok { $object->dryrun(1)->list_from_schema('main'); }
'Geoffrey::Exception::NotSupportedException::ConverterType',
  'List uniques not supportet thrown';

throws_ok { $object->add(); } 'Geoffrey::Exception::RequiredValue::TableName',
  'Not supportet thrown';

throws_ok { $object->add( 'uq_table_01', {} ); }
'Geoffrey::Exception::RequiredValue::TableColumn',
  'Not supportet thrown';
