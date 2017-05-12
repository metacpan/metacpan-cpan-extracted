#!perl -wT
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 11;

    use_ok('Handel::Storage::RDBO');
    use_ok('Handel::Exception', ':try');
};

my $storage = Handel::Storage::RDBO->new;
$storage->setup({
    connection_info => {
        driver => 'sqlite',
        type => 'bogus',
        domain => 'handel',
        dsn => 'dbi:SQLite:dbname=F:\CPAN\handel.db'
    },
    item_relationship    => 'myitems',
    schema_class         => 'Handel::Base',
    schema_instance      => 'FakeSchemaInstance',
    table_name           => 'mytable'
});

is_deeply($storage->connection_info, {
        driver => 'sqlite',
        type => 'bogus',
        domain => 'handel',
        dsn => 'dbi:SQLite:dbname=F:\CPAN\handel.db'
    }, 'connection was set');
is($storage->item_relationship, 'myitems', 'item relationship was set');
is($storage->schema_class, 'Handel::Base', 'schema class was set');
is($storage->schema_instance, 'FakeSchemaInstance', 'schema instance was set');
is($storage->table_name, 'mytable', 'table name was set');


## throw exception if no result is passed
try {
    local $ENV{'LANG'} = 'en';
    $storage->setup;

    fail('no exception thrown');
} catch Handel::Exception::Argument with {
    pass('argument exception caught');
    like(shift, qr/not a HASH/i, 'not a hash in message');
} otherwise {
    fail('other exception caught');
};


## throw exception if no result is passed
try {
    local $ENV{'LANG'} = 'en';
    $storage->setup({});

    fail('no exception thrown');
} catch Handel::Exception::Storage with {
    pass('storage exception caught');
    like(shift, qr/schema instance/i, 'existing schema instance in message');
} otherwise {
    fail('other exception thrown');
};
