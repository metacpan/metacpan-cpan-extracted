use Test::More tests => 43;

use DBI;
use strict;
use FindBin;
use warnings;
use Test::Exception;

{

    package Test::Mock::Geoffrey::Action::Sql;
    use parent 'Geoffrey::Role::Action';
}
{

    package Test::Mock::Geoffrey::Changelog::Test;
    use parent 'Geoffrey::Role::Changelog';
}
{

    package Test::Mock::Geoffrey::Converter::SQLite;
    use parent 'Geoffrey::Role::Converter';
}
{

    package Test::Mock::Geoffrey::Converter::SQLite::Table;
    use parent 'Geoffrey::Role::ConverterType';
}

require_ok('Geoffrey::Action::Sql');
use_ok 'Geoffrey::Action::Sql';

my $dbh = DBI->connect("dbi:SQLite:database=.tmp.sqlite") or plan skip_all => $DBI::errstr;

require_ok('Geoffrey::Converter::SQLite');
my $converter = Geoffrey::Converter::SQLite->new();
my $object = Geoffrey::Action::Sql->new( converter => $converter, dbh => $dbh );

require_ok('Geoffrey::Exception::Database');
use_ok 'Geoffrey::Exception::Database';

throws_ok { Geoffrey::Exception::Database::throw_sql_handle( 'test', 'SELECT * from foo' ); }
'Geoffrey::Exception::Database::SqlHandle', 'Not supportet thrown';

require_ok('Geoffrey::Exception::NotSupportedException');
use_ok 'Geoffrey::Exception::NotSupportedException';

throws_ok { Geoffrey::Exception::NotSupportedException::throw_index( 'add', 'test' ); }
'Geoffrey::Exception::NotSupportedException::Index', 'Not supportet thrown';

$object = Test::Mock::Geoffrey::Action::Sql->new( converter => $converter, dbh => $dbh );

throws_ok { $object->add(); } 'Geoffrey::Exception::NotSupportedException::Action',
  'Not supportet thrown';

throws_ok { $object->alter(); } 'Geoffrey::Exception::NotSupportedException::Action',
  'Not supportet thrown';

throws_ok { $object->drop(); } 'Geoffrey::Exception::NotSupportedException::Action',
  'Not supportet thrown';

throws_ok { $object->list_from_schema(); }
'Geoffrey::Exception::NotSupportedException::Action', 'Not supportet thrown';

throws_ok { Test::Mock::Geoffrey::Changelog::Test->new->load; }
'Geoffrey::Exception::NotSupportedException::File',
  'load not supportet thrown';

throws_ok { Test::Mock::Geoffrey::Changelog::Test->new->tpl_main; }
'Geoffrey::Exception::NotSupportedException::File',
  'tpl_main not supportet thrown';

throws_ok { Test::Mock::Geoffrey::Changelog::Test->new->tpl_sub; }
'Geoffrey::Exception::NotSupportedException::File',
  'tpl_sub not supportet thrown';

throws_ok { $converter->trigger_information; }
'Geoffrey::Exception::NotSupportedException::ListInformation',
  'tpl_sub not supportet thrown';

throws_ok { $converter->function_information; }
'Geoffrey::Exception::NotSupportedException::ListInformation',
  'tpl_sub not supportet thrown';

require_ok('Geoffrey::Utils');
throws_ok { Geoffrey::Utils::obj_from_name(); }
'Geoffrey::Exception::RequiredValue::PackageName',
  'throw_package_name package name missing';

throws_ok {
    require Geoffrey;
    Geoffrey->new( converter => $converter, dbh => bless {}, 'Foo::Bar' );
}
'Geoffrey::Exception::Database::NotDbh', 'tpl_sub not supportet thrown';

throws_ok { Geoffrey::Exception::NotSupportedException::throw_sequence( 'add', 'test' ); }
'Geoffrey::Exception::NotSupportedException::Sequence', 'Not supportet thrown';

throws_ok { Geoffrey::Exception::NotSupportedException::throw_primarykey( 'add', 'test' ); }
'Geoffrey::Exception::NotSupportedException::Primarykey', 'Not supportet thrown';

throws_ok { Geoffrey::Exception::NotSupportedException::throw_unique( 'add', 'test' ); }
'Geoffrey::Exception::NotSupportedException::Uniquekey', 'Not supportet thrown';

$converter = Test::Mock::Geoffrey::Converter::SQLite->new();

throws_ok { $converter->constraints(); }
'Geoffrey::Exception::NotSupportedException::ConverterType',
  'Not supportet thrown';

throws_ok { $converter->index(); } 'Geoffrey::Exception::NotSupportedException::ConverterType',
  'Not supportet thrown';

throws_ok { $converter->table(); } 'Geoffrey::Exception::NotSupportedException::ConverterType',
  'Not supportet thrown';

throws_ok { $converter->view(); } 'Geoffrey::Exception::NotSupportedException::ConverterType',
  'Not supportet thrown';

throws_ok { $converter->foreign_key(); }
'Geoffrey::Exception::NotSupportedException::ConverterType',
  'Not supportet thrown';

throws_ok { $converter->trigger(); }
'Geoffrey::Exception::NotSupportedException::ConverterType',
  'Not supportet thrown';

throws_ok { $converter->primary_key(); }
'Geoffrey::Exception::NotSupportedException::ConverterType',
  'Not supportet thrown';

throws_ok { $converter->sequence(); }
'Geoffrey::Exception::NotSupportedException::ConverterType',
  'Not supportet thrown';

throws_ok { $converter->function(); }
'Geoffrey::Exception::NotSupportedException::ConverterType',
  'Not supportet thrown';

throws_ok { $converter->unique(); }
'Geoffrey::Exception::NotSupportedException::ConverterType',
  'Not supportet thrown';

throws_ok { $converter->colums_information(); }
'Geoffrey::Exception::NotSupportedException::ListInformation',
  'Not supportet thrown';

throws_ok { $converter->index_information(); }
'Geoffrey::Exception::NotSupportedException::ListInformation',
  'Not supportet thrown';

throws_ok { $converter->view_information(); }
'Geoffrey::Exception::NotSupportedException::ListInformation',
  'Not supportet thrown';

throws_ok { $converter->sequence_information(); }
'Geoffrey::Exception::NotSupportedException::ListInformation',
  'Not supportet thrown';

throws_ok { $converter->primary_key_information(); }
'Geoffrey::Exception::NotSupportedException::ListInformation',
  'Not supportet thrown';

throws_ok { $converter->function_information(); }
'Geoffrey::Exception::NotSupportedException::ListInformation',
  'Not supportet thrown';

throws_ok { $converter->unique_information(); }
'Geoffrey::Exception::NotSupportedException::ListInformation',
  'Not supportet thrown';

my $converter_type = Test::Mock::Geoffrey::Converter::SQLite::Table->new();

throws_ok { $converter_type->append(); }
'Geoffrey::Exception::NotSupportedException::ConverterType',
  'Not supportet thrown';

throws_ok { $converter_type->information(); }
'Geoffrey::Exception::NotSupportedException::ConverterType',
  'Not supportet thrown';
