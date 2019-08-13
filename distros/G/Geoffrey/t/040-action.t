use Test::More tests => 20;

use strict;
use FindBin;
use warnings;
use Data::Dumper;
use Test::Exception;

use_ok 'DBI';

{

    package Test::Mock::Geoffrey::Converter::SQLite::ForeignKey;
    sub new { bless {}, shift; }
    sub drop {'ALTER TABLE {0} DROP FOREIGNKEY {1}'}
}
{

    package Test::Mock::Geoffrey::Converter::SQLite::PrimaryKey;
    sub new { bless {}, shift; }
    sub add {'CONSTRAINT {0} PRIMARY KEY ( {1} )'}
}

require_ok('Geoffrey::Action::Constraint');
require_ok('Geoffrey::Converter::SQLite');

use_ok 'Geoffrey::Action::Constraint';
use_ok 'Geoffrey::Converter::SQLite';

my $dbh       = DBI->connect("dbi:SQLite:database=.tmp.sqlite");
my $converter = new_ok('Geoffrey::Converter::SQLite');
my $object    = Geoffrey::Action::Constraint->new( converter => $converter );

throws_ok { $object->alter(""); } 'Geoffrey::Exception::General::WrongRef',
    'Alter constraint thrown';

can_ok( 'Geoffrey::Action::Constraint', @{ [ 'alter', 'drop' ] } );
isa_ok( $object, 'Geoffrey::Action::Constraint' );

dies_ok( sub { $object->drop }, 'expecting to die' );
my $constraints = [];

dies_ok(
    sub {
        $object->add( 'test_table',
            { name => 'primarykey_test', primarykey => [ 'pk_col1', 'pk_col2' ] }, $constraints );
    },
    'expecting to die'
);

throws_ok {
    $object->add( 'test_table',
        { name => 'primarykey_test', primary => [ 'pk_col1', 'pk_col2' ] }, $constraints );
}
'Geoffrey::Exception::General::UnknownAction', 'Unknown action thrown';

$constraints = [];
dies_ok(
    sub {
        $object->add( 'test_table',
            { name => 'unique_test', unique => { columns => [ 'un_col1', 'un_col2' ] } },
            $constraints );
    },
    'expecting to die'
);

$constraints = [];
$object->for_table(1);
$object->add(
    'table',
    {   name       => 'foreign_test',
        foreignkey => { reftable => 'player', refcolumn => 'id' }
    },
    $constraints
);
$object->for_table(0);

is( Data::Dumper->new($constraints)->Indent(0)->Terse(1)->Deparse(1)->Sortkeys(1)->Dump,
    Data::Dumper->new( ['FOREIGN KEY (foreign_test) REFERENCES player(id)'] )->Indent(0)
        ->Terse(1)->Deparse(1)->Sortkeys(1)->Dump,
    "Foreign keys"
);

require_ok('Geoffrey::Action::Function');
$object = new_ok( 'Geoffrey::Action::Function',
    [ 'converter', Geoffrey::Converter::SQLite->new(), 'dbh', $dbh ] );

throws_ok { $object->do_arrayref("Wrong SQL"); } 'Geoffrey::Exception::Database::SqlHandle',
    'Throw list_from_schema not supported';

throws_ok { Geoffrey::Action::Constraint->new(); }
'Geoffrey::Exception::RequiredValue::Converter', 'Throw list_from_schema not supported';

$converter->foreign_key( Test::Mock::Geoffrey::Converter::SQLite::ForeignKey->new );
$object = Geoffrey::Action::Constraint->new( converter => $converter, dbh => $dbh );

is( $object->dryrun(1)->drop(
        'test_table',
        { constraints => [ { constraint => 'foreignkey', name => 'key_name', } ] }, q~~
    ),
    'ALTER TABLE test_table DROP FOREIGNKEY key_name',
    'Drop foreignkey test.'
);

my $constr_ref = [];
$object->for_table(1);
$object->add(
    'primary_test',
    {   primarykey => {
            name    => 'primary_test',
            columns => [ 'player', 'id', ],
        },
    },
    $constr_ref
);
$object->add(
    'unique_table_test',
    {   unique => {
            name    => 'unique_test',
            columns => [ 'player', 'id' ],
        },
    },
    $constr_ref
);

is( Data::Dumper->new($constr_ref)->Indent(0)->Terse(1)->Deparse(1)->Sortkeys(1)->Dump,
    Data::Dumper->new(
        [   'CONSTRAINT primary_test PRIMARY KEY ( player,id )',
            'CONSTRAINT unique_test UNIQUE ( player,id )'
        ]
        )->Indent(0)->Terse(1)->Deparse(1)->Sortkeys(1)->Dump,
    'List indexes from schema'
);
