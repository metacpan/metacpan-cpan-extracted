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
        plan tests => 16;
    };

    use_ok('Handel::Test::RDBO::Cart');
    use_ok('Handel::Test::RDBO::Cart::Item');
    use_ok('Handel::Constants', ':cart');
    use_ok('Handel::Exception', ':try');
};


## This is a hack, but it works. :-)
my $schema = Handel::Test->init_schema(no_populate => 1);

&run('Handel::Test::RDBO::Cart', 'Handel::Test::RDBO::Cart::Item', 1);

sub run {
    my ($subclass, $itemclass, $dbsuffix) = @_;

    Handel::Test->populate_schema($schema, clear => 1);
    local $ENV{'HandelDBIDSN'} = $schema->dsn;


    ## Clear cart contents and validate counts
    {
        my $total_items = $schema->resultset('CartItems')->count;
        ok($total_items, 'has items');

        my $it = $subclass->search({
            id => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($it, 'Handel::Iterator');
        is($it, 1, 'got 1 cart');

        my $cart = $it->first;
        isa_ok($cart, 'Handel::Cart');
        isa_ok($cart, $subclass);

        my $related_items = $cart->count;
        ok($related_items >= 1, 'has more than 1 item');
        $cart->clear;
        is($cart->count, 0, 'items cleared');

        my $reit = $subclass->search({
            id => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($reit, 'Handel::Iterator');
        is($reit, 1, 'got 1 cart');

        my $recart = $reit->first;
        isa_ok($recart, $subclass);

        is($recart->count, 0, 'have no items');

        my $remaining_items = $schema->resultset('CartItems')->count;
        is($remaining_items, $total_items - $related_items, 'deleted appropriate items');
    };

};
