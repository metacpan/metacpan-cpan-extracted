#!perl -wT
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test;

    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'DBD::SQLite not installed';
    } else {
        plan tests => 9;
    };

    use_ok('Handel::Storage::RDBO');
    use_ok('Handel::Exception', ':try');
};

$ENV{'HandelDBIDSN'} = Handel::Test->init_schema(no_populate => 1)->dsn;

my $storage = Handel::Storage::RDBO->new({
    schema_class       => 'Handel::Schema::RDBO::Cart',
    item_storage_class => 'Handel::Storage::RDBO::Cart::Item'
});


## get copyable item columns
is_deeply([sort $storage->copyable_item_columns], [qw/description price quantity sku/], 'got correct item columns');


## add another primary and make sure it disappears
$storage->item_storage->schema_instance->meta->primary_key_columns(qw/id sku/);
is_deeply([sort $storage->copyable_item_columns], [qw/description price quantity/], 'new id column removed from list');


## get them columns when source isn't found
$storage->item_storage->schema_instance->meta->primary_key_columns(qw/id/);
$storage->schema_instance->meta->delete_relationship($storage->item_relationship);
is_deeply([sort $storage->copyable_item_columns], [qw/cart description price quantity sku/], 'column is returned when no in relationship');


## no item storage
try {
    local $ENV{'LANG'} = 'en';
    $storage->item_storage_class(undef);
    $storage->item_storage(undef);
    $storage->copyable_item_columns;

    fail('no exception thrown');
} catch Handel::Exception::Storage with {
    pass('storage exception caught');
    like(shift, qr/no item storage/i, 'no item in message');
} otherwise {
    fail('other exception caught');
};


## no item relationship
try {
    local $ENV{'LANG'} = 'en';
    $storage->item_relationship(undef);
    $storage->copyable_item_columns;

    fail('no exception thrown');
} catch Handel::Exception::Storage with {
    pass('storage exception caught');
    like(shift, qr/no item relationship/i, 'no relationship in storage');
} otherwise {
    fail('other exception caught');
};
