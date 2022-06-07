use Test2::V0;
use Test2::Require::Module 'Teng' => '0.19';
use Test2::Require::Module 'DBD::SQLite';
use Test2::Require::Module 'Cpanel::JSON::XS' => '4.00';

use Cpanel::JSON::XS::Type;
use JSON::UnblessObject qw(unbless_object);

{
    package TengTest::Schema;
    use utf8;
    use Teng::Schema::Declare;

    table {
        name 'foo';
        pk 'id';
        columns qw/
            id
            name
            delete_fg
        /;
    };
}

{
    package TengTest;
    use parent qw(Teng);
}

sub setup {
    my $dbh = DBI->connect('dbi:SQLite::memory:','','',{ RaiseError => 1, PrintError => 0, AutoCommit => 1 });
    my $db = TengTest->new({dbh => $dbh});

    $dbh->do(q{
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

subtest 'unbless Teng::Row object' => sub {
    my $row = $db->single(foo => {id => 1});
    isa_ok $row, 'Teng::Row';

    is unbless_object($row, { id => JSON_TYPE_INT }), { id => 1 };
    is unbless_object($row, { name => JSON_TYPE_STRING }), { name => 'perl' };
    is unbless_object($row, { id => JSON_TYPE_INT, name => JSON_TYPE_STRING }), { id => 1, name => 'perl' };
};

subtest 'unbless Teng::Iterator object' => sub {
    my $iter = $db->search('foo');
    isa_ok $iter, 'Teng::Iterator';

    my $spec = { id => JSON_TYPE_INT, name => JSON_TYPE_STRING };
    is unbless_object($iter, json_type_arrayof($spec)),
       [
           { id => 1, name => 'perl' },
           { id => 2, name => 'raku' },
       ];
};

done_testing;
