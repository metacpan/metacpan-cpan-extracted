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
        plan tests => 11;
    };

    use_ok('Handel::Storage::RDBO');
    use_ok('Handel::Exception', ':try');
};

$ENV{'HandelDBIDSN'} = Handel::Test->init_schema->dsn;

my $storage = Handel::Storage::RDBO->new({
    schema_class    => 'Handel::Schema::RDBO::Cart'
});

my $item_storage = Handel::Storage::RDBO->new({
    schema_class     => 'Handel::Schema::RDBO::Cart::Item',
    remove_columns   => ['quantity']
});
$storage->item_storage($item_storage);


## We have nothing
is($storage->_columns_to_remove, undef, 'no columns defined');


## Remove without schema instance adds to collection
$storage->remove_columns(qw/foo/);
is($storage->_schema_instance, undef, 'no schema instance');
is_deeply($storage->_columns_to_remove, [qw/foo/], 'stored columns to remove');
$storage->remove_columns(qw/bar/);
is_deeply($storage->_columns_to_remove, [qw/foo bar/], 'appended columns to remove');
$storage->_columns_to_remove(undef);


## Remove from a connected schema
my $schema = $storage->schema_instance;
ok($schema->meta->column('name'), 'have name column');
ok($schema->can('name'), 'has name column accessor');
$storage->remove_columns('name');
is_deeply($storage->_columns_to_remove, [qw/name/], 'added name to remove columns');
$schema->meta->delete_column('name');
$schema->meta->initialize;
ok(!$schema->meta->column('name'), 'name column is gone from has_columns');
my $cart = $schema->new(id => '11111111-1111-1111-1111-111111111111')->load;
ok(!$schema->meta->column('quantity'), 'quantity column removed from item storage');
