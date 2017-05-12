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
        plan tests => 24;
    };

    use_ok('Handel::Storage::RDBO');
    use_ok('Handel::Exception', ':try');
};

my $schema = Handel::Test->init_schema;
$ENV{'HandelDBIDSN'} = $schema->dsn;

my $storage = Handel::Storage::RDBO->new({
    schema_class     => 'Handel::Schema::RDBO::Cart::Item',
    currency_code    => 'CAD',
    currency_columns => [qw/price/],
});


my $item = $storage->search->first;
isa_ok($item->price, 'Handel::Currency');
is($item->price->code, 'CAD', 'got currency code');
is($item->price->format, 'FMT_STANDARD', 'got default format');
is($item->price->stringify, '1.11 CAD', 'got default format');

$storage->currency_code('DKK');
$item = $storage->search->first;
isa_ok($item->price, 'Handel::Currency');
is($item->price->code, 'DKK', 'code set from storage code');
is($item->price->format, 'FMT_STANDARD', 'got default format');
is($item->price->stringify, '1,11 DKK', 'got default format');


$storage->currency_code(undef);
$item = $storage->search->first;
isa_ok($item->price, 'Handel::Currency');
is($item->price->code, 'USD', 'no code set');


{
    local $ENV{'HandelCurrencyCode'} = 'CAD';
    my $item = $storage->search->first;
    isa_ok($item->price, 'Handel::Currency');
    is($item->price->code, 'CAD', 'no code set');
    is($item->price->format, 'FMT_STANDARD', 'got default format');
    is($item->price->stringify, '1.11 CAD', 'got default format');
};


{
    my $item = $storage->search->first;
    isa_ok($item->price, 'Handel::Currency');
    is($item->price->code, 'USD', 'no code is set');
    is($item->price->format, 'FMT_STANDARD', 'got default format');
    is($item->price->stringify, '1.11 USD', 'got default format');
};


$storage->currency_code_column('sku');
$item = $storage->search->first;
$item->sku('CAD');
isa_ok($item->price, 'Handel::Currency');
is($item->price->code, 'CAD', 'code set from column');


$storage->currency_code_column('sku');
$storage->currency_code('CAD');
$item = $storage->search->first;
$item->sku(undef);
isa_ok($item->price, 'Handel::Currency');
is($item->price->code, 'CAD', 'code set from env');
