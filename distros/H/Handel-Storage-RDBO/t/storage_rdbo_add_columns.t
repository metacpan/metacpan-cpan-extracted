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
        plan tests => 21;
    };

    use_ok('Handel::Storage::RDBO');
};


$ENV{'HandelDBIDSN'} = Handel::Test->init_schema->dsn;


my $storage = Handel::Storage::RDBO->new({
    schema_class    => 'Handel::Schema::RDBO::Cart'
});


## We have nothing
is($storage->_columns_to_add, undef, 'no columns added');


## Add generic without schema instance adds to collection
$storage->add_columns(qw/foo/);
is($storage->_schema_instance, undef, 'no schema instance');
is_deeply($storage->_columns_to_add, [qw/foo/], 'added foo');
$storage->add_columns(qw/bar/);
is_deeply($storage->_columns_to_add, [qw/foo bar/], 'appended bar');
$storage->_columns_to_add(undef);


## Add w/info without schema instance
$storage->add_columns(bar => {accessor => 'baz'});
is($storage->_schema_instance, undef, 'unset schema instance');
is_deeply($storage->_columns_to_add, [bar => {accessor => 'baz'}], 'added column w/ accessor');
$storage->_columns_to_add(undef);


## Add to a connected schema
my $schema = $storage->schema_instance;
ok(!$schema->meta->column('custom'), 'source has no custom column');
ok(!$schema->can('custom'), 'source has no accessor for custom');
$storage->add_columns('custom');
is_deeply($storage->_columns_to_add, [qw/custom/], 'added column');
ok($schema->meta->column('custom'), 'custom column added');
$schema->meta->initialize;
ok($schema->can('custom'), 'custom accessor added');
$storage->_columns_to_add(undef);
my $cart = $schema->new(id => '11111111-1111-1111-1111-111111111111')->load;
ok($cart->can('custom'), 'result has custom method');
is($cart->custom, 'custom', 'got custom value');
$schema->meta->delete_column('custom');
$schema->meta->initialize;


## Add w/info to a connected schema
ok(!$schema->meta->column('custom'), 'source has no custom');
ok(!$schema->can('baz'), 'source has no accessor');
$storage->add_columns(custom => {alias => 'baz'});
is_deeply($storage->_columns_to_add, [custom => {alias => 'baz', type => 'scalar'}], 'added custom columnd w/ accessor');
ok($schema->meta->column('custom'), 'cutom column added');
$storage->schema_instance(undef);
$schema = $storage->schema_instance;
ok($schema->can('baz'), 'custom column accessor added');
$cart = $schema->new(id => '11111111-1111-1111-1111-111111111111')->load;
ok($cart->can('baz'), 'cart has custom accessor');
is($cart->baz, 'custom', 'got custom value');
