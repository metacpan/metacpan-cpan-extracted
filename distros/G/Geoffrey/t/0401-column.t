use Test::More tests => 24;

use strict;
use FindBin;
use warnings;
use Data::Dumper;
use Test::Exception;

use_ok 'DBI';

require_ok('Geoffrey::Converter::SQLite');
use_ok 'Geoffrey::Converter::SQLite';

require_ok('Geoffrey::Action::Column');
use_ok 'Geoffrey::Action::Column';

{

    package Test::Mock::Geoffrey::Converter::SQLite::Tables;
    use parent 'Geoffrey::Role::ConverterType';
}

{

    package Test::Mock::Geoffrey::Converter::SQLite::Tables2;
    sub new { return bless { alter => q~ALTER TABLE {0}~, }, shift; }
    sub alter       { return $_[0]->{alter}; }
    sub drop_column { return $_[0]->alter . q~ DROP COLUMN {1}~; }

}

{

    package Test::Mock::Geoffrey::Converter::SQLite;
    use parent 'Geoffrey::Role::Converter';

    sub new {
        my $class = shift;
        my $self  = $class->SUPER::new(@_);
        bless $self, $class;
        return $self;

    }

    sub table {
        Geoffrey::Converter::SQLite::Tables->new;
    }
}

my $dbh       = DBI->connect("dbi:SQLite:database=.tmp.sqlite");
my $converter = Geoffrey::Converter::SQLite->new();
my $object    = new_ok( 'Geoffrey::Action::Column', [ 'converter', $converter, 'dbh', $dbh ] );

can_ok( 'Geoffrey::Action::Column', @{ [ 'add', 'alter', 'drop' ] } );
isa_ok( $object, 'Geoffrey::Action::Column' );

is( $object->add( { table => '"user"', name => 'drop_another_test', type => 'integer' }, q~~ ),
    'ALTER TABLE "user" ADD COLUMN drop_another_test INTEGER ',
    'Add column test.'
);

throws_ok {
    $object->alter(
        { table => '"user"', name => 'drop_another_test', type => 'varchar', lenght => 255 } );
}
'Geoffrey::Exception::NotSupportedException::Action', 'Not supportet thrown';

throws_ok { $object->drop( { table => '"user"', name => 'drop_another_test' } ); }
'Geoffrey::Exception::NotSupportedException::Column', 'Drop column thrown';

throws_ok {
    $object->add(
        {   table      => '"user"',
            name       => 'drop_another_test',
            type       => 'integer',
            primarykey => q~~
        },
        q~~
    );
}
'Geoffrey::Exception::RequiredValue::TableColumn', 'Required value thrown';

is( Data::Dumper->new( $object->list_from_schema( 'main', 'user' ) )->Indent(0)->Terse(1)
        ->Deparse(1)->Sortkeys(1)->Dump,
    Data::Dumper->new(
        [   {   name        => "id",
                not_null    => "NOT NULL",
                primary_key => "PRIMARY KEY",
                type        => "INTEGER",
            },
            { name => "active", type     => "BOOL", },
            { name => "name",   not_null => "NOT NULL", type => "VARCHAR", },
            { name => "flag",   not_null => "NOT NULL", type => "DATETIME", },
            { name => "client", not_null => "NOT NULL", type => "INTEGER", },
            { length => '255', name => "mail", not_null => "NOT NULL", type => "VARCHAR", },
            { name => "last_login", type => "DATETIME", },
            { name => "locale",     type => "CHAR", },
            { length => '255', name => "salt", not_null => "NOT NULL", type => "VARCHAR", },
            { length => '255', name => "pass", not_null => "NOT NULL", type => "VARCHAR", }
        ]
        )->Indent(0)->Terse(1)->Deparse(1)->Sortkeys(1)->Dump,
    'Columns from SQLite table'
);

$dbh->disconnect();

#throw test just too be sure
$object = Geoffrey::Action::Column->new(
    converter => new_ok(
        'Geoffrey::Converter::SQLite',
        [ 'table', Test::Mock::Geoffrey::Converter::SQLite::Tables->new ]
    ),
    dbh => $dbh
);

throws_ok {
    $object->add( { table => '"user"', name => 'drop_test', type => 'integer' }, q~~ );
}
'Geoffrey::Exception::NotSupportedException::Column', 'Add column thrown';

is( $object->defaults(), undef, q~Add without params~ );
is( $object->defaults( { default => 'autoincrement' } ),
    'AUTOINCREMENT', q~Add param {default => 'autoincrement'}~ );
is( $object->defaults( { default => 'current_timestamp' } ),
    'DEFAULT CURRENT_TIMESTAMP',
    q~Add param {default => 'current_timestamp'}~
);

is( $object->defaults( { default => 'current_timestamp' } ),
    'DEFAULT CURRENT_TIMESTAMP',
    q~Add param {default => 'current_timestamp'}~
);

$object = Geoffrey::Action::Column->new(
    converter => new_ok(
        'Geoffrey::Converter::SQLite',
        [ 'table', Test::Mock::Geoffrey::Converter::SQLite::Tables2->new ]
    ),
    dbh => $dbh
);

is( Data::Dumper->new(
        $object->dryrun(1)->drop( { table => '"user"', dropcolumn => ['drop_another_test'] } )
        )->Indent(0)->Terse(1)->Deparse(1)->Sortkeys(1)->Dump,
    Data::Dumper->new( [ 'ALTER TABLE "user" DROP COLUMN drop_another_test', ] )->Indent(0)
        ->Terse(1)->Deparse(1)->Sortkeys(1)->Dump,
    'Drop column ok'
);

$object
    = Geoffrey::Action::Column->new( converter => Test::Mock::Geoffrey::Converter::SQLite->new, );

$object->dryrun(1);

throws_ok { $object->list_from_schema( 'main', 'user' ); }
'Geoffrey::Exception::NotSupportedException::ListInformation', 'Add column thrown';

throws_ok { $object->add(""); } 'Geoffrey::Exception::General::WrongRef', 'Add column thrown';

throws_ok { $object->drop(""); } 'Geoffrey::Exception::General::WrongRef', 'Add column thrown';

