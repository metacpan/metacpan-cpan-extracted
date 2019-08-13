use Test::More tests => 17;

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

throws_ok { $object->add({table => "user"}); } 'Geoffrey::Exception::RequiredValue::TableColumn', 'Not supportet thrown';

throws_ok { $object->add( { table => "user", columns => [ 'name', 'client' ] } ); }
'Geoffrey::Exception::RequiredValue::Values', 'Not supportet thrown';

ok( $object->add( { table => "user", columns => [ 'name', 'client' ], values => [ [ 'test', 1 ] ] } ),
    'Add entry test' );

is(
    $object->alter(
        '"user"',
        [ 'client', 'name' ],
        [ { column => 'name', operator => '=', value => q~'test'~, }, ],
        [ [ '1', 'test_name', ], ],
    ),
    q~UPDATE "user" SET client = ?, name = ? WHERE ( name = 'test' )~,
    'Alter entry test'
);

is(
    $object->drop( '"user"', [ { column => 'name', operator => '=', value => q~'test'~, }, ], 1 ),
    q~DELETE FROM "user" WHERE ( name = 'test' )~,
    'Delete entry test'
);

$dbh->disconnect();

throws_ok { $object->alter( '"user"', [ 'client', 'name' ], ); }
'Geoffrey::Exception::RequiredValue::WhereClause', 'Not supportet thrown';

throws_ok { $object->alter(); } 'Geoffrey::Exception::RequiredValue::TableName', 'Not supportet thrown';

throws_ok { $object->drop(); } 'Geoffrey::Exception::RequiredValue::TableName', 'Not supportet thrown';
