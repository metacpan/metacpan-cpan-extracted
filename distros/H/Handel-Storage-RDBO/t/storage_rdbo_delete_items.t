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
        plan tests => 19;
    };

    use_ok('Handel::Storage::RDBO');
    use_ok('Handel::Exception', ':try');
};

my $testschema = Handel::Test->init_schema;
$ENV{'HandelDBIDSN'} = $testschema->dsn;

my $storage = Handel::Storage::RDBO->new({
    schema_class    => 'Handel::Schema::RDBO::Cart',
    item_storage_class => 'Handel::Storage::RDBO::Cart::Item'
});


## delete all items from a cart
is($testschema->resultset('CartItems')->search->count, 5, 'start with 5 items');
my $schema = $storage->schema_instance;
my $cart = $schema->new(id => '11111111-1111-1111-1111-111111111111')->load;
my $result = bless {'storage_result' => $cart}, 'GenericResult';
ok($storage->delete_items($result), 'delete items returns');
is($testschema->resultset('CartItems')->search->count, 3, 'deleted 2 items');
Handel::Test->populate_schema($testschema, clear => 1);


## delete items using CDBI wildcard
is($testschema->resultset('CartItems')->search->count, 5, 'start with 5 items');
ok($storage->delete_items($result, {sku => 'SKU22%'}), 'delete using CDBI wildcard');
is($testschema->resultset('CartItems')->search->count, 4, 'have 4 items left');
Handel::Test->populate_schema($testschema, clear => 1);


## delete items using DBIC wildcard
is($testschema->resultset('CartItems')->search->count, 5, 'start with 5 items');
ok($storage->delete_items($result, {sku => {like => 'SKU22%'}}), 'delete using DBIC wildcards');
is($testschema->resultset('CartItems')->search->count, 4, 'have 4 items left');


## throw exception if no result is passed
try {
    local $ENV{'LANG'} = 'en';
    $storage->delete_items;

    fail('no exception thrown');
} catch Handel::Exception::Argument with {
    pass('caught argument exception');
    like(shift, qr/no result/i, 'no result in message');
} otherwise {
    fail('other exception caught');
};


## throw exception if data isn't a hashref
try {
    local $ENV{'LANG'} = 'en';
    $storage->delete_items($result, []);

    fail('no exception thrown');
} catch Handel::Exception::Argument with {
    pass('caught argument exception');
    like(shift, qr/not a hash/i, 'not a hash in message');
} otherwise {
    fail('other exception caught');
};


## throw exception when adding an item to something with incorrect relationship
try {
    local $ENV{'LANG'} = 'en';
    $storage->item_relationship('bogus');
    $storage->delete_items($result, {
        id       => '99999999-9999-9999-9999-999999999999',
        sku      => 'ABC-123',
        quantity => 2,
        price    => 2.22
    });

    fail('no exception thrown');
} catch Handel::Exception::Storage with {
    pass('caught storage exception');
    like(shift, qr/no item relationship/i, 'no relationship in message');
} otherwise {
    fail('other exception caught');
};


## throw exception when adding an item with no defined relationship
try {
    local $ENV{'LANG'} = 'en';
    $storage->item_relationship(undef);
    $storage->delete_items($result, {
        id       => '99999999-9999-9999-9999-999999999999',
        sku      => 'ABC-123',
        quantity => 2,
        price    => 2.22
    });

    fail('no exception thrown');
} catch Handel::Exception::Storage with {
    pass('caught storage exception');
    like(shift, qr/no item relationship defined/i, 'no relationship in message');
} otherwise {
    fail('other exception caught');
};


package GenericResult;
sub storage_result {return shift->{'storage_result'}};
1;
