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
        plan tests => 17;
    };

    use_ok('Handel::Storage::RDBO');
    use_ok('Handel::Exception', ':try');
};

my $schema = Handel::Test->init_schema;
$ENV{'HandelDBIDSN'} = $schema->dsn;

my $storage = Handel::Storage::RDBO->new({
    schema_class    => 'Handel::Schema::RDBO::Cart',
    item_storage_class => 'Handel::Storage::RDBO::Cart::Item'
});


## delete all items w/ no params
is($schema->resultset('Carts')->search->count, 3, 'start with 3 carts');
is($schema->resultset('CartItems')->search->count, 5, 'start with 5 items');
ok($storage->delete, 'delete all');
is($schema->resultset('Carts')->search->count, 0, 'no carts');
is($schema->resultset('CartItems')->search->count, 0, 'no items');


## delete all items w/ CDBI wildcards
Handel::Test->populate_schema($schema, clear => 1);
is($schema->resultset('Carts')->search->count, 3, 'start with 3 carts');
is($schema->resultset('CartItems')->search->count, 5, 'start with 5 items');
ok($storage->delete({ description => 'Test%'}), 'delete using CDBI wildcards');
is($schema->resultset('Carts')->search->count, 1, '1 cart left');
is($schema->resultset('CartItems')->search->count, 2, '2 items left');


## delete all items w/ DBIC wildcards
Handel::Test->populate_schema($schema, clear => 1);
is($schema->resultset('Carts')->search->count, 3, 'start with 3 carts');
is($schema->resultset('CartItems')->search->count, 5, 'start with 5 items');
ok($storage->delete({ description => {like => 'Test%'}}), 'delete using DBIC wildcards');
is($schema->resultset('Carts')->search->count, 1, '1 cart left');
is($schema->resultset('CartItems')->search->count, 2, '2 items left');
