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
        plan tests => 22;
    };

    use_ok('Handel::Storage::RDBO');
    use_ok('Handel::Exception', ':try');
};

my $dsn = Handel::Test->init_schema(no_populate => 1)->dsn;
$ENV{'HandelDBIDSN'} = $dsn;
my $constraints = {
    id   => {'check_id' => sub{}},
    name => {'check_name' => sub{}}
};



## now for an instance
my $storage = Handel::Storage::RDBO->new({
    schema_class       => 'Handel::Schema::RDBO::Cart',
    item_storage_class => 'Handel::Storage::RDBO::Cart::Item',
    add_columns        => [qw/custom/],
    remove_columns     => [qw/description/],
    currency_columns   => [qw/name/]
});


{
    ## create a new storage and check schema_instance configuration
    isa_ok($storage, 'Handel::Storage');

    my $schema = $storage->schema_instance;
    my $cart_class = $schema;
    my $item_class = $schema->meta->relationship('items')->class;

    ## make sure we're running clones unique classes
    like($cart_class, qr/Handel::Schema::RDBO::Cart::[A-F0-9]{32}/, 'class is the composed style');
    like($item_class, qr/Handel::Schema::RDBO::Cart::Item::[A-F0-9]{32}/, 'class is the composed style');

    ## make sure we added/removed columns
    my %columns = map {$_ => 1} $cart_class->meta->column_names;
    ok(exists $columns{'custom'}, 'column custom not added');
    ok(!exists $columns{'description'}, 'column description not removed');

    ## make sure we set inflate/deflate
    ok($cart_class->meta->column('name')->triggers('inflate'), 'inflate sub added');
    ok($cart_class->meta->column('name')->triggers('deflate'), 'deflate sub added');


    ## throw exception if schema_class is empty
    {
        try {
            local $ENV{'LANG'} = 'en';
            my $storage = Handel::Storage::RDBO->new({
                connection_info => [$dsn]
            });
            $storage->schema_instance;

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass('caught storage exception');
            like(shift, qr/no schema_class/i, 'no schema class in message')
        } otherwise {
            fail('other exception caught');
        };
    };

    ## throw exception if item_relationship is missing
    {
        try {
            local $ENV{'LANG'} = 'en';
            my $storage = Handel::Storage::RDBO->new({
                schema_class       => 'Handel::Schema::RDBO::Cart',
                item_storage_class => 'Handel::Storage::RDBO::Cart::Item',
                item_relationship  => 'foo'
            });
            $storage->schema_instance;

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass('caught storage exception');
            like(shift, qr/no relationship named/i, 'no relationship in message')
        } otherwise {
            fail('other exception caught');
        };
    };
};


## work on class too
{
    Handel::Storage::RDBO->schema_class('Handel::Schema::RDBO::Cart');
    Handel::Storage::RDBO->add_columns(qw/custom/);
    Handel::Storage::RDBO->remove_columns(qw/description/);
    Handel::Storage::RDBO->currency_columns(qw/name/);

    my $schema = Handel::Storage::RDBO->schema_instance;
    my $cart_class = $schema;

    ## make sure we're running clones unique classes
    like($cart_class, qr/Handel::Schema::RDBO::Cart::[A-F0-9]{32}/, 'class is the composed style');

    ## make sure we added/removed columns
    my %columns = map {$_ => 1} $cart_class->meta->column_names;
    ok(exists $columns{'custom'}, 'column custom not added');
    ok(!exists $columns{'description'}, 'column description not removed');

    ## make sure we set inflate/deflate
    ok($cart_class->meta->column('name')->triggers('inflate'), 'inflate subs loaded');
    ok($cart_class->meta->column('name')->triggers('deflate'), 'deflate subs loaded');

    ## throw exception if schema_class is empty
    {
        try {
            local $ENV{'LANG'} = 'en';
            Handel::Storage::RDBO->_schema_instance(undef);
            Handel::Storage::RDBO->schema_class(undef);
            Handel::Storage::RDBO->schema_instance;

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass('storage exception caught');
            like(shift, qr/no schema_class/i, 'no schema class in message')
        } otherwise {
            fail('other exception caught');
        };
    };

    ## throw exception if item_relationship is missing
    {
        try {
            local $ENV{'LANG'} = 'en';
            Handel::Storage::RDBO->_schema_instance(undef);
            Handel::Storage::RDBO->schema_class('Handel::Schema::RDBO::Cart');
            Handel::Storage::RDBO->item_storage_class('Handel::Storage::RDBO::Cart::Item');
            Handel::Storage::RDBO->item_relationship('foo');
            Handel::Storage::RDBO->schema_instance;

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass('storage exception caught');
            like(shift, qr/no relationship named/i, 'no relationship in message')
        } otherwise {
            fail('caught other exception');
        };
    };
};
