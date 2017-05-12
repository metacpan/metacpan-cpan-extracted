package Test::Cart;

use Test::Exception;
use Test::Roo::Role;
use Test::More;

test cart => sub {
    my $self = shift;
    my $schema = $self->ic6s_schema;
    # create some products, an user, a session
    my @skus;
    foreach my $sku (99991 .. 99995) {
        push @skus, $sku;
        $schema->resultset('Product')->create({ sku => $sku, name => $sku,
                                                description => '',
                                              });
    }
    my $user = $schema->resultset('User')->create({ username => 'marco' });
    my $session = $schema->resultset('Session')->create({ sessions_id => '12435',
                                                          session_data => '',
                                                        });
    my $cart = $schema->resultset('Cart')
      ->create({sessions_id => 12435,
                users_id => $user->users_id,
                cart_products => [ map { +{ sku => $_, cart_position => 0 } } @skus ]});
    $cart->discard_changes;
    ok defined($cart->name), "Name is defined";
    ok($cart, "Cart created");
    my $existing = $schema->resultset('CartProduct')->count;
    foreach my $name ('', 0, $cart->name) {
        throws_ok { $cart->clone($name) } qr/Can't clone/, "invalid clone argument caught";
    }
    for (1..3) {
        my $testclone = $cart->clone('clone-1234');
        ok($testclone, "Clone created");
        ok $testclone->session, "Found the session";
        ok $testclone->user, "Found the username";
    }
    my $clone = $cart->clone('clone-1234');
    ok ($clone, "Clone created");
    isnt $clone->carts_id, $cart->carts_id, "New carts id";
    my @cloned_products = $clone->cart_products;
    ok (scalar(@cloned_products), "Found the products");
    is $schema->resultset('CartProduct')->count, $existing * 2,
      "New cart products generated";
    $cart->update({ sessions_id => undef });
    for (1..3) {
        my $testclone = $cart->clone('clone-9999');
        is $testclone->cart_products->count, 5, "Found 5 products";
        is $testclone->session, undef, "No session";
    }
    is $schema->resultset('CartProduct')->count, ($existing * 2 + 5 * 3),
      "New products found";
    is $schema->resultset('Cart')->count, 5, "Total 5 carts";
    $schema->resultset('Cart')->delete;
    $session->delete;
    $user->delete;
    $schema->resultset('Product')->search({ sku => \@skus })->delete;
};

1;
