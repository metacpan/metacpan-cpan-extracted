use Test::More tests => 12;

use strict;
use FindBin;
use warnings;
use Data::Dumper;
use Test::Exception;

use_ok 'DBI';

{

    package Test::Mock::Geoffrey::Converter::PrimaryKey;
    sub new { bless {}, shift; }
    sub drop { 'ALTER TABLE {0} DROP CONSTRAINT {1}' }
    sub list { 'SELECT ALL FROM PRIMARY_KEYS' }

}

require_ok('Geoffrey::Action::Constraint::PrimaryKey');
use_ok 'Geoffrey::Action::Constraint::PrimaryKey';

require_ok('Geoffrey::Converter::SQLite');
use_ok 'Geoffrey::Converter::SQLite';

my $dbh = DBI->connect("dbi:SQLite:database=.tmp.sqlite")
  or plan skip_all => $DBI::errstr;
my $converter = Geoffrey::Converter::SQLite->new();
my $object    = new_ok( 'Geoffrey::Action::Constraint::PrimaryKey',
    [ 'converter', $converter, 'dbh', $dbh ] );

can_ok( 'Geoffrey::Action::Constraint::PrimaryKey', @{ [ 'add', 'alter', 'drop' ] } );
isa_ok( $object, 'Geoffrey::Action::Constraint::PrimaryKey' );

throws_ok { $object->alter(); }
'Geoffrey::Exception::NotSupportedException::ConverterType',
  'Alter primary key not supportet thrown';

throws_ok { $object->drop(); }
'Geoffrey::Exception::NotSupportedException::ConverterType',
  'Drop primary key not supportet thrown';

throws_ok { $object->list_from_schema(); }
'Geoffrey::Exception::NotSupportedException::ConverterType',
  'List primary key not supportet thrown';

is(
    $object->add( 'test_table', { name => 'test_primaryname', columns => ['test_column'], } ),
    'CONSTRAINT test_primaryname PRIMARY KEY ( test_column )',
    'Add primary key mock test'
);
