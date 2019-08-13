use Test::More tests => 21;

use DBI;
use strict;
use FindBin;
use warnings;
use Data::Dumper;
use Test::Exception;
use Geoffrey::Converter::SQLite;

{

    package Test::Mock::Geoffrey::Converter::Index;
    use parent 'Geoffrey::Role::ConverterType';
}

{

    package Test::Mock::Geoffrey::Converter::SQLite;
    use parent 'Geoffrey::Role::Converter';

    sub new {
        my $class = shift;
        my $self  = $class->SUPER::new(@_);
        return bless $self, $class;
    }
    sub index { Geoffrey::Converter::SQLite::Index->new }
}

require_ok('Geoffrey::Action::Constraint::Index');
use_ok 'Geoffrey::Action::Constraint::Index';

my $dbh       = DBI->connect("dbi:SQLite:database=.tmp.sqlite");
my $converter = Geoffrey::Converter::SQLite->new();
my $object
    = new_ok( 'Geoffrey::Action::Constraint::Index', [ 'converter', $converter, 'dbh', $dbh ] );

can_ok( 'Geoffrey::Action::Constraint::Index', @{ [ 'add', 'alter', 'drop' ] } );
isa_ok( $object, 'Geoffrey::Action::Constraint::Index' );

can_ok( 'Geoffrey::Action::Constraint::Index', @{ [ 'add', 'alter', 'drop' ] } );
isa_ok( $object, 'Geoffrey::Action::Constraint::Index' );

throws_ok { $object->add(); } 'Geoffrey::Exception::General::ParamsMissing',
    'Add index without params';

throws_ok { $object->add( {} ); } 'Geoffrey::Exception::RequiredValue::TableName',
    'Add index with empty params';

throws_ok { $object->add( { table => 'client' } ); }
'Geoffrey::Exception::RequiredValue::RefColumn',
    'Add index without columns';

is( $object->add( { name => 'ix_client_1503825426', table => 'client', column => 'id' } ),
    'CREATE INDEX ix_client_1503825426 ON client (id)',
    'Add index (id)'
);

is( $object->add(
        { name => 'ix_client_150382542', table => 'client', column => [ 'id', 'name' ] }
    ),
    'CREATE INDEX ix_client_150382542 ON client (id, name)',
    'Add index (id, name)'
);

throws_ok { $object->drop(); } 'Geoffrey::Exception::RequiredValue::IndexName',
    'Drop index needs a name';

$object->dryrun(1);
is(

    Data::Dumper->new(
        $object->alter(
            { name => 'ix_client_1503825426', table => 'client', column => [ 'id', 'name' ] }
        )
        )->Indent(0)->Terse(1)->Deparse(1)->Sortkeys(1)->Dump,
    Data::Dumper->new(
        [   'DROP INDEX ix_client_1503825426',
            'CREATE INDEX ix_client_1503825426 ON client (id, name)'
        ]
        )->Indent(0)->Terse(1)->Deparse(1)->Sortkeys(1)->Dump,
    'Alter index'
);

ok( $object->add( { table => 'client', column => 'id' } )
        =~ /^CREATE INDEX ix_client_\d+ ON client \(id\)$/,
    'Add generated index'
);

$object->dryrun(0);
is( $object->drop( { name => 'ix_client_1503825426' } ),
    'DROP INDEX ix_client_1503825426',
    'Drop index'
);

is( Data::Dumper->new( $object->list_from_schema() )->Indent(0)->Terse(1)->Deparse(1)
        ->Sortkeys(1)->Dump,
    Data::Dumper->new(
        [   { columns => ["id"], name => "index_test", table => "match_team" },

            #{ columns => ['mail'], name => 'unique_changset_91', table => 'user' },
            { columns => [ "id", "name" ], name => "ix_client_150382542", table => "client" },
        ]
        )->Indent(0)->Terse(1)->Deparse(1)->Sortkeys(1)->Dump,
    'List indexes from schema'
);

$converter->index( Test::Mock::Geoffrey::Converter::Index->new );

throws_ok { $object->add(); } 'Geoffrey::Exception::NotSupportedException::ConverterType',
    'Add index not supportet test';

throws_ok { $object->alter( { name => 'index_test' } ); }
'Geoffrey::Exception::NotSupportedException::ConverterType',
    'Add index not supportet test';

throws_ok { $object->drop( { name => 'index_test' } ); }
'Geoffrey::Exception::NotSupportedException::ConverterType',
    'Add index not supportet test';

$object = Geoffrey::Action::Constraint::Index->new(
    converter => Test::Mock::Geoffrey::Converter::SQLite->new, );

$object->dryrun(1);

throws_ok { $object->list_from_schema('main'); }
'Geoffrey::Exception::NotSupportedException::ListInformation', 'Add column thrown';
