use Test2::V0;
use Test2::Require::Module 'DBIx::Class' => '0.08271';
use Test2::Require::Module 'DBD::SQLite';
use Test2::Require::Module 'SQL::Translator' => '0.11016';
use Test2::Require::Module 'Cpanel::JSON::XS' => '4.00';

use Cpanel::JSON::XS::Type;
use JSON::UnblessObject qw(unbless_object);

use FindBin;
use lib $FindBin::Bin . '/lib';

use My::Schema;

sub setup {
    my @info = ('dbi:SQLite::memory:','','',{ RaiseError => 1, PrintError => 0, AutoCommit => 1 });
    my $schema = My::Schema->connect(@info);
    $schema->deploy;

    $schema->resultset('Foo')->create({
        id   => 1,
        name => 'perl',
    });

    $schema->resultset('Foo')->create({
        id   => 2,
        name => 'raku',
    });

    return $schema;
}

my $schema = setup();

subtest 'unbless Schema::Result::Foo object' => sub {
    my $rs = $schema->resultset('Foo')->search({id => 1});
    my $row = $rs->next;
    isa_ok $row, 'My::Schema::Result::Foo';

    is unbless_object($row, { id => JSON_TYPE_INT }), { id => 1 };
    is unbless_object($row, { name => JSON_TYPE_STRING }), { name => 'perl' };
    is unbless_object($row, { id => JSON_TYPE_INT, name => JSON_TYPE_STRING }), { id => 1, name => 'perl' };
};

subtest 'unbless My::Schema::Result object' => sub {
    my $rs = $schema->resultset('Foo');
    my $iter = $rs->search({});

    isa_ok $iter, 'DBIx::Class::ResultSet';

    my $spec = { id => JSON_TYPE_INT, name => JSON_TYPE_STRING };
    is unbless_object($iter, json_type_arrayof($spec)),
       [
           { id => 1, name => 'perl' },
           { id => 2, name => 'raku' },
       ];
};

done_testing;
