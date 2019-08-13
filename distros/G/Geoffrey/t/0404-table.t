use Test::More tests => 28;

use strict;
use FindBin;
use warnings;
use Data::Dumper;
use Test::Exception;
use Geoffrey::Converter::SQLite;

use_ok 'DBI';


require_ok('Geoffrey::Action::Table');
use_ok 'Geoffrey::Action::Table';

my $dbh       = DBI->connect("dbi:SQLite:database=.tmp.sqlite");
my $converter = Geoffrey::Converter::SQLite->new();
my $object    = new_ok( 'Geoffrey::Action::Table', [ 'converter', $converter, 'dbh', $dbh ] );

can_ok( 'Geoffrey::Action::Table', @{ [ 'add', 'alter', 'drop' ] } );
isa_ok( $object, 'Geoffrey::Action::Table' );
is( $object->prefix('foo_'),  'foo_', 'Set table prefix' );
is( $object->postfix('_bar'), '_bar', 'Set table postfix' );

is( $object->prefix(q~~),  q~~, 'Set table prefix' );
is( $object->postfix(q~~), q~~, 'Set table postfix' );

throws_ok { $object->add(); } 'Geoffrey::Exception::RequiredValue::TableName', 'Not supportet thrown';

throws_ok { $object->add( { name => '404_test_add_name', } ); }
'Geoffrey::Exception::NotSupportedException::EmptyTable', 'Not supportet thrown';

ok(
    $object->add(
        {
            name    => 'test_add_name_404',
            columns => [
                {
                    name       => 'id',
                    type       => 'varchar',
                    lenght     => 64,
                    primarykey => 1,
                    notnull    => 1,
                    default    => '\'\''
                },
            ],
        }
    ),
    'Alter table add column'
);

throws_ok {
    $object->alter();
}
'Geoffrey::Exception::General::WrongRef', 'Alter table thrown';

throws_ok {
    $object->alter( {} );
}
'Geoffrey::Exception::General::TableNameMissing', 'Unknown action thrown';

throws_ok {
    $object->alter(
        {
            name  => 'test_table',
            alter => [
                { action => 'column.add', name => 'some_column' },
                { action => 'column.add', name => 'another_column' }
            ]
        }
    );
}
'Geoffrey::Exception::RequiredValue::ColumnType', 'Unknown action thrown';

$object->dryrun(1);
is(
    Data::Dumper->new(
        $object->alter(
            {
                name  => 'test_table',
                alter => [
                    { action => 'column.add', name => 'some_column',    type => 'integer' },
                    { action => 'column.add', name => 'another_column', type => 'varchar' }
                ]
            }
        )
    )->Indent(0)->Terse(1)->Deparse(1)->Sortkeys(1)->Dump,
    Data::Dumper->new(
        [
            "ALTER TABLE test_table ADD COLUMN some_column INTEGER",
            "ALTER TABLE test_table ADD COLUMN another_column VARCHAR"
        ]
    )->Indent(0)->Terse(1)->Deparse(1)->Sortkeys(1)->Dump,
    'Alter table add column'
);

throws_ok {
    $object->dryrun(0)->drop();
}
'Geoffrey::Exception::General::TableNameMissing', 'Not supportet thrown';

is( $object->drop( { name => 'test_add_name_404' } ), 'DROP TABLE test_add_name_404', 'Alter table add column' );

is(
    join( q/,/, @{ $object->list_from_schema('main') } ),
    'geoffrey_changelogs,client,sqlite_sequence,company,user,player,team,match_player,match_team',
    'Table list from SQLite'
);

throws_ok {
    $object->add(
        {
            name     => 'test_add_name_404',
            template => 'not_existent',
        }
    );
}
'Geoffrey::Exception::Template::NotFound', 'Not supportet thrown';

throws_ok {
    $object->alter(
        {
            name  => 'test_table',
            alter => [ { action => 'column.drop', name => 'some_column' } ],
        }
    );
}
'Geoffrey::Exception::NotSupportedException::Column', 'Not supportet thrown';

throws_ok {
    $object->alter(
        {
            name  => 'test_table',
            alter => [
                { action => 'constraint.foreign_key.drop', name => 'fk_any_key' },
                { action => 'constraint.foreign_key.drop', name => 'fk_another_key' },
            ],
        }
    );
}
'Geoffrey::Exception::NotSupportedException::ConverterType', 'Alter foreign key not supportet thrown';

throws_ok {
    $object->alter(
        {
            name  => 'test_table',
            alter => [
                {
                    action    => 'constraint.foreign_key.alter',
                    name      => 'fk_any_key',
                    column    => 'for_column',
                    reftable  => 'for_reftable',
                    refcolumn => 'for_refcolumn',
                }
            ],
        }
    );
}
'Geoffrey::Exception::NotSupportedException::ConverterType', 'Not supportet thrown';

throws_ok {
    $object->alter( { name => 'test_table', alter => [ { action => 'foreign' } ], } );
}
'Geoffrey::Exception::General::Eval', 'Not supportet thrown';

throws_ok {
    $object->alter( { name => 'test_table', alter => [ { action => 'constraint.foreign_key.adds', } ], } );
}
'Geoffrey::Exception::RequiredValue::ActionSub', 'Not supportet thrown';

$object->dryrun(1);
is(
    Data::Dumper->new(
        $object->alter(
            {
                name  => 'test_table',
                alter => [
                    {
                        action    => 'constraint.foreign_key.add',
                        column    => 'for_column',
                        reftable  => 'for_reftable',
                        refcolumn => 'for_refcolumn',
                    }
                ],
            }
        )
    )->Indent(0)->Terse(1)->Deparse(1)->Sortkeys(1)->Dump,
    Data::Dumper->new( ['FOREIGN KEY (for_column) REFERENCES for_reftable(for_refcolumn)'] )->Indent(0)->Terse(1)
      ->Deparse(1)->Sortkeys(1)->Dump,
    'Alter table add foreign key'
);
$object->dryrun(0);

throws_ok {
    $object->alter(
        {
            name  => 'test_table',
            alter => [ { action => 'column.alter' } ],
        }
    );
}
'Geoffrey::Exception::NotSupportedException::Action', 'Not supportet thrown';

