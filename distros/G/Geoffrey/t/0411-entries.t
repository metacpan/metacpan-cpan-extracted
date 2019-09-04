use Test::More tests => 16;

use DBI;
use strict;
use FindBin;
use warnings;
use Test::Exception;

require_ok('DBI');
use_ok 'DBI';

require_ok('Geoffrey::Converter::SQLite');
use_ok 'Geoffrey::Converter::SQLite';

require_ok('Geoffrey::Action::Entry');
use_ok 'Geoffrey::Action::Entry';

my $dbh = DBI->connect("dbi:SQLite:database=.tmp.sqlite")
  or plan skip_all => $DBI::errstr;

my $converter = Geoffrey::Converter::SQLite->new();
my $object = Geoffrey::Action::Entry->new( converter => $converter, dbh => $dbh );

can_ok( 'Geoffrey::Action::Entry', @{ [ 'add', 'alter', 'drop' ] } );

isa_ok( $object, 'Geoffrey::Action::Entry' );

throws_ok { $object->add(); } 'Geoffrey::Exception::RequiredValue::TableName', 'Not supportet thrown';

throws_ok { $object->add( { table => "user" } ); } 'Geoffrey::Exception::RequiredValue::Values', 'Not supportet thrown';

ok( $object->add( { table => "user", values => [ { name => 'test', client => 1 } ] } ), 'Add entry test' );

is(
    $object->alter(
        '"user"',
        { name => 'test', },
        [ { client => 1, name => 'test_name' } ],

    ),
    q~UPDATE "user" SET client = ?, name = ? WHERE ( name = ? )~,
    'Alter entry test'
);

is(
    $object->drop( { table => '"user"', conditions => { name => q~'test'~ } } ),
    q~DELETE FROM "user" WHERE ( name = ? )~,
    'Delete entry test'
);

$dbh->disconnect();

throws_ok { $object->alter('"user"'); }
'Geoffrey::Exception::RequiredValue::WhereClause', 'Not supportet thrown';

throws_ok { $object->alter(); } 'Geoffrey::Exception::RequiredValue::TableName', 'Not supportet thrown';

throws_ok { $object->drop(); } 'Geoffrey::Exception::RequiredValue::TableName', 'Not supportet thrown';
