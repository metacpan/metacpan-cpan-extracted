use Test::More tests => 9;

use DBI;
use FindBin;
use strict;
use warnings;
use Test::Exception;

require_ok('Geoffrey::Action::Sql');
use_ok 'Geoffrey::Action::Sql';

my $dbh = DBI->connect("dbi:SQLite:database=.tmp.sqlite") or plan skip_all => $DBI::errstr;

require_ok('Geoffrey::Converter::SQLite');
my $converter = Geoffrey::Converter::SQLite->new();
my $object = Geoffrey::Action::Sql->new( converter => $converter, dbh => $dbh );

can_ok( 'Geoffrey::Action::Sql', @{ [ 'add', 'alter', 'drop' ] } );
isa_ok( $object, 'Geoffrey::Action::Sql' );

is(
    $object->add(
        { as => q~SELECT t.name AS table_name FROM sqlite_master t  WHERE type='table'~ }
    ),
    q~SELECT t.name AS table_name FROM sqlite_master t  WHERE type='table'~,
    'Execute simple SQL'
);

throws_ok { $object->alter(); } 'Geoffrey::Exception::NotSupportedException::Action',
  'Not supportet thrown';

throws_ok { $object->drop(); } 'Geoffrey::Exception::NotSupportedException::Action',
  'Not supportet thrown';

throws_ok { $object->list_from_schema(); }
'Geoffrey::Exception::NotSupportedException::Action', 'Not supportet thrown';
