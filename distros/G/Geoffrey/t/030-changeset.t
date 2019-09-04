use Test::More tests => 41;

use strict;
use FindBin;
use warnings;
use Test::Exception;

use_ok 'DBI';

require_ok('Geoffrey::Changeset');
use_ok 'Geoffrey::Changeset';

require_ok('Geoffrey::Converter::SQLite');
use_ok 'Geoffrey::Converter::SQLite';

my $s_filepath = '.tmp.sqlite';
my $dbh        = DBI->connect( "dbi:SQLite:database=$s_filepath", { PrintError => 0, RaiseError => 1 } );
my $converter  = Geoffrey::Converter::SQLite->new();
my $object     = new_ok( 'Geoffrey::Changeset', [ 'converter', $converter, 'dbh', $dbh ] );

is( $object->prefix('foo_'),  'foo_', 'Set table prefix' );
is( $object->postfix('_bar'), '_bar', 'Set table postfix' );
is( $object->prefix(q~~),     q~~,    'Set table prefix' );
is( $object->postfix(q~~),    q~~,    'Set table postfix' );

throws_ok { $object->handle_entries( [ { action => 'table.drop' } ] ); }
'Geoffrey::Exception::General::TableNameMissing', 'Drop non existing table';

throws_ok {
    $object->handle_entries( [ { action => 'constraint.index.alter', name => 'idx_test_01' } ] );
}
'Geoffrey::Exception::Database::SqlHandle', 'Drop non existing index';

throws_ok {
    $object->handle_entries( [ { action => 'constraint.index.alte', name => 'idx_test_01' } ] );
}
'Geoffrey::Exception::RequiredValue::ActionSub', 'Drop non existing index';

throws_ok {
    $object->handle_entries( [ { action => 'constraint.index.drop', name => 'idx_test_01' } ] );
}
'Geoffrey::Exception::Database::SqlHandle', 'Drop non existing index';

throws_ok { $object->handle_entries( [ { action => 'view.drop', name => 'test_view' } ] ); }
'Geoffrey::Exception::Database::SqlHandle', 'Drop non existing view';

throws_ok { $object->handle_entries( [ { action => 'view.alter', nam => 'test_view' } ] ); }
'Geoffrey::Exception::General::TableNameMissing', 'Alter non existing view';

throws_ok {
    $object->handle_entries( [ { action => 'constraint.default.add', name => 'test_seq' } ] );
}
'Geoffrey::Exception::RequiredValue::TableName', 'Throw unsupported sequence on add';

throws_ok {
    $object->handle_entries( [ { action => 'constraint.default.add', name => 'test_seq', table => 'test_table' } ] );
}
'Geoffrey::Exception::NotSupportedException::ConverterType', 'Throw unsupported sequence on add';

throws_ok {
    $object->handle_entries( [ { action => 'constraint.default.drop', name => 'test_seq' } ] );
}
'Geoffrey::Exception::NotSupportedException::ConverterType', 'Throw unsupported sequence on drop';

throws_ok {
    $object->handle_entries( [ { action => 'constraint.default.alter', name => 'test_seq' } ] );
}
'Geoffrey::Exception::NotSupportedException::Action', 'Alter non existing sequence';

throws_ok {
    $object->handle_entries( [ { action => 'function.add', name => 'test_function' } ] );
}
'Geoffrey::Exception::NotSupportedException::ConverterType', 'Throw unsupported function on add';

throws_ok {
    $object->handle_entries( [ { action => 'function.drop', name => 'test_function' } ] );
}
'Geoffrey::Exception::NotSupportedException::Action', 'Throw unsupported function on drop';

throws_ok {
    $object->handle_entries( [ { action => 'function.alter', name => 'test_function' } ] );
}
'Geoffrey::Exception::NotSupportedException::Action', 'Alter non existing function';

throws_ok { $object->handle_entries( [ { action => 'trigger.add' } ] ); }
'Geoffrey::Exception::RequiredValue::TriggerName', 'Throw missing trigger name on add';

throws_ok {
    $object->handle_entries( [ { action => 'trigger.drop', name => '_test_view' } ] );
}
'Geoffrey::Exception::RequiredValue::TableName', 'Throw missing trigger name on drop';

throws_ok { $object->handle_entries( [ { action => 'trigger.alter' } ] ); }
'Geoffrey::Exception::NotSupportedException::ConverterType', 'Throw alter trigger not supported';

throws_ok { $object->handle_entries( [ { action => 'constraint.add' } ] ); }
'Geoffrey::Exception::General::UnknownAction', 'Alter non existing trigger';

throws_ok { $object->handle_entries( [ { action => 'entry.add' } ] ); }
'Geoffrey::Exception::RequiredValue::TableName', 'Alter non existing trigger';
throws_ok { $object->handle_entries( [ { action => 'entry.alter' } ] ); }
'Geoffrey::Exception::RequiredValue::WhereClause', 'Alter non existing trigger';

throws_ok {
    $object->handle_entries(
        [
            {
                action      => 'constraint.alter',
                table       => 'table',
                constraints => [ { constraint => 'foreignkey', name => 'fkey_test', } ],
            }
        ]
    );
}
'Geoffrey::Exception::NotSupportedException::ConverterType', 'Alter non existing foreignkey';

throws_ok { $object->handle_entries( [ { action => 'constraints.alter', } ] ); }
'Geoffrey::Exception::General::Eval', 'Alter non existing package';

require_ok('Geoffrey::Read');
use_ok 'Geoffrey::Read';

$object = new_ok( 'Geoffrey::Read', [ 'converter', $converter, 'dbh', $dbh ] );

throws_ok { $object->run_changeset( {}, 'no file at all' ); }
'Geoffrey::Exception::RequiredValue::ChangesetId', 'Alter non existing trigger';

throws_ok { $object->run_changeset( { id => '001.01-maz' } ); }
'Geoffrey::Exception::Database::CorruptChangeset', 'Corrupt changeset exception';

throws_ok {
    Geoffrey::Changeset->new( changeset_converter => 'SQLite', dbh => "" );
}
'Geoffrey::Exception::Database::NoDbh', 'Test exception if dbh is wrong datatype';

throws_ok { Geoffrey::Read->new( changeset_converter => 'SQLite', dbh => "" ); }
'Geoffrey::Exception::Database::NoDbh', 'Test exception if dbh is wrong datatype';

$object->_obj_entries->dryrun(1);
is(
    Data::Dumper->new(
        [
            $object->run_changeset(
                {
                    id      => '003.14-maz',
                    author  => 'Mario Zieschang',
                    entries => [
                        {
                            action    => 'constraint.foreign_key.add',
                            dryrun    => 1,
                            table     => 'client',
                            column    => 'for_column',
                            reftable  => 'for_reftable',
                            refcolumn => 'for_refcolumn',
                        },
                    ],
                },

            )
        ]
    )->Indent(0)->Terse(1)->Deparse(1)->Sortkeys(1)->Dump,
    Data::Dumper->new(
        [
            {
                changeset =>
'INSERT INTO geoffrey_changelogs ( comment, created_by, filename, geoffrey_version, id, md5sum) VALUES ( ?, ?, ?, ?, ?, ? )'
            }
        ]
    )->Indent(0)->Terse(1)->Deparse(1)->Sortkeys(1)->Dump,
    'no file at all'
);

throws_ok {
    $object->run_changeset(
        {
            id      => '003.14-maz',
            author  => 'Mario Zieschang',
            entries => [
                {
                    action => 'constraint.foreign_key.drop',
                    dryrun => 1,
                    table  => 'client',
                    name   => 'fk_foreignkey_to_drop',
                },
            ],
        },

    );
}
'Geoffrey::Exception::NotSupportedException::ConverterType', 'Drop foreignkey is not supported';

throws_ok {
    $object->run_changeset(
        {
            id      => '003.14-maz',
            author  => 'Mario Zieschang',
            entries => [
                {
                    action    => 'constraint.foreign_key.alter',
                    dryrun    => 1,
                    name      => 'fkey_test',
                    table     => 'client',
                    column    => 'for_column',
                    reftable  => 'for_reftable',
                    refcolumn => 'for_refcolumn',
                },
            ],
        },

    );
}
'Geoffrey::Exception::NotSupportedException::ConverterType', 'Drop foreignkey is not supported during alter';
$object->_obj_entries->dryrun(0);

