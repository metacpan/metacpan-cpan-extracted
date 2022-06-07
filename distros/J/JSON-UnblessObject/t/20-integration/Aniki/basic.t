use Test2::V0;
use Test2::Require::Module 'Aniki' => '1.00';
use Test2::Require::Module 'DBD::SQLite';
use Test2::Require::Module 'Cpanel::JSON::XS' => '4.00';

use Cpanel::JSON::XS::Type;
use JSON::UnblessObject qw(unbless_object);

{
    package AnikiTest::Schema;
    use DBIx::Schema::DSL;

    create_table 'foo' => columns {
      integer 'id', primary_key;
      varchar 'name';
      tinyint 'delete_fg', default => 0;
    };
}

{
    package AnikiTest;
    use Mouse;
    extends qw( Aniki );

    __PACKAGE__->setup(
        schema => 'AnikiTest::Schema',
    );
}

sub setup {
    my $db = AnikiTest->new(connect_info => ['dbi:SQLite::memory:','','',{ RaiseError => 1, PrintError => 0, AutoCommit => 1 }]);

    $db->execute(q{
        CREATE TABLE foo (
            id   integer,
            name text,
            delete_fg int(1) default 0,
            primary key ( id )
        )
    });

    $db->insert('foo',{
        id   => 1,
        name => 'perl',
    });

    $db->insert('foo',{
        id   => 2,
        name => 'raku',
    });

    return $db;
}


my $db = setup();

subtest 'unbless Aniki::Row object' => sub {
    my $row = $db->select(foo => {id => 1})->first;
    isa_ok $row, 'Aniki::Row';

    is unbless_object($row, { id => JSON_TYPE_INT }), { id => 1 };
    is unbless_object($row, { name => JSON_TYPE_STRING }), { name => 'perl' };
    is unbless_object($row, { id => JSON_TYPE_INT, name => JSON_TYPE_STRING }), { id => 1, name => 'perl' };
};

subtest 'unbless Aniki::Result::Collection object' => sub {
    my $collection = $db->select('foo');
    isa_ok $collection, 'Aniki::Result::Collection';

    my $spec = { id => JSON_TYPE_INT, name => JSON_TYPE_STRING };
    is unbless_object($collection, json_type_arrayof($spec)),
       [
           { id => 1, name => 'perl' },
           { id => 2, name => 'raku' },
       ];

    is unbless_object($collection, [$spec, $spec]),
       [
           { id => 1, name => 'perl' },
           { id => 2, name => 'raku' },
       ];

    is unbless_object($collection, [$spec]),
       [
           { id => 1, name => 'perl' },
       ];
};

done_testing;
