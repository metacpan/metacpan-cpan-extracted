use Test::More tests => 20;

use FindBin;
use strict;
use warnings;
use Test::Exception;
use Geoffrey::Converter::SQLite;
{

    package Test::Mock::Geoffrey::Converter::ForeignKey;
    use parent 'Geoffrey::Role::ConverterType';
    sub add  { 'CREATE UNIQUE INDEX CONCURRENTLY {0} ON {1} ({2})' }
    sub drop { 'ALTER TABLE {0} DROP CONSTRAINT {1}' }
    sub list { 'SELECT ALL FROM UNIQUE_KEYS' }

}
require_ok('Geoffrey::Action::Constraint::ForeignKey');
use_ok 'Geoffrey::Action::Constraint::ForeignKey';

my $converter = Geoffrey::Converter::SQLite->new();
my $object = new_ok( 'Geoffrey::Action::Constraint::ForeignKey', [ 'converter', $converter ] );

can_ok( 'Geoffrey::Action::Constraint::ForeignKey', @{ [ 'add', 'alter', 'drop' ] } );
isa_ok( $object, 'Geoffrey::Action::Constraint::ForeignKey' );

throws_ok {
    $object->add();
}
'Geoffrey::Exception::General::WrongRef', 'Required value thrown';

throws_ok {
    $object->add( {} );
}
'Geoffrey::Exception::RequiredValue::TableName', 'Required value thrown';

throws_ok {
    $object->add( { table => 'test_table' } );
}
'Geoffrey::Exception::RequiredValue::RefTable', 'Required value thrown';

throws_ok {
    $object->add( { table => 'test_table', reftable => 'reftable' } );
}
'Geoffrey::Exception::RequiredValue::RefColumn', 'Required value thrown';

throws_ok {
    $object->add(
        { table => 'test_table', reftable => 'reftable', refcolumn => 'refcolumn' } );
}
'Geoffrey::Exception::RequiredValue::TableColumn', 'Required value thrown';

throws_ok {
    $object->alter( { name => 'fk_test' } );
}
'Geoffrey::Exception::NotSupportedException::ConverterType', 'Not supportet thrown';

throws_ok {
    $object->drop();
}
'Geoffrey::Exception::NotSupportedException::ConverterType',
  'Drop foreign key not supportet thrown';

throws_ok {
    $object->list_from_schema();
}
'Geoffrey::Exception::NotSupportedException::ConverterType',
  'List foreign key not supportet thrown';

$converter->foreign_key(q~~);
throws_ok { $object->add( {} ); } 'Geoffrey::Exception::NotSupportedException::ForeignKey',
  'Unique missing thrown';

throws_ok { $object->alter( { name => 'fk_test' } ); }
'Geoffrey::Exception::NotSupportedException::ForeignKey',
  'Unique missing thrown';

throws_ok { $object->drop(); } 'Geoffrey::Exception::NotSupportedException::ForeignKey',
  'Unique missing thrown';

throws_ok { $object->list_from_schema(); }
'Geoffrey::Exception::NotSupportedException::ForeignKey',
  'Unique missing thrown';

$converter->foreign_key( Test::Mock::Geoffrey::Converter::ForeignKey->new );

require_ok('Geoffrey::Action::Constraint');
$object = Geoffrey::Action::Constraint->new( converter => $converter );

isa_ok( $object, 'Geoffrey::Action::Constraint' );

throws_ok {
    $object->alter(
        {
            table       => 'table',
            constraints => [
                {
                    constraint => 'foreignkey',
                    column     => 'foreign_test',
                    reftable   => 'player',
                    refcolumn  => 'id',
                    name       => 'fk_test',
                },
            ]
        }
    );
}
'Geoffrey::Exception::Database::NoDbh', 'Not supportet thrown';

