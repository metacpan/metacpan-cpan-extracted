#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# Network-free tests for tool registration and the entity projection helpers.
# The picnic attribute is stubbed so constructing the server never logs in or
# touches the network.

{
  package Fake::Picnic;
  sub new { bless {}, shift }
}

use MCP::Picnic;

sub build_mcp {
  return MCP::Picnic->new(
    user   => 'dummy@example.com',
    pass   => 'dummy-pass',
    picnic => Fake::Picnic->new
  );
}

# --- The server builds and exposes every expected tool name --------------
{
  my $mcp = build_mcp();
  my $server = $mcp->server;
  isa_ok $server, 'MCP::Server', 'server builds';

  my @expected = qw(
    verify_2fa
    search_products
    get_product_details
    get_suggestions
    get_cart
    add_to_cart
    remove_from_cart
    clear_cart
    get_delivery_slots
    set_delivery_slot
    get_user
    get_categories
  );

  my @names = map { $_->name } @{$server->tools};
  is scalar(@names), scalar(@expected), 'twelve tools are registered';

  my %got = map { $_ => 1 } @names;
  for my $name (@expected) {
    ok $got{$name}, "tool '$name' is registered";
  }
}

# --- _article_to_hash projects the WWW::Picnic article shape -------------
{
  package Fake::Article;
  sub new { bless {}, shift }
  sub id            { 'art-1' }
  sub name          { 'Whole Milk' }
  sub price         { 119 }
  sub display_price { '1.19' }
  sub unit_quantity { '1 L' }
  sub image_id      { 'img-1' }
}
{
  my $mcp = build_mcp();
  my $hash = $mcp->_article_to_hash(Fake::Article->new);
  is_deeply $hash, {
    id            => 'art-1',
    name          => 'Whole Milk',
    price         => 119,
    display_price => '1.19',
    unit_quantity => '1 L',
    image_id      => 'img-1'
  }, '_article_to_hash projects the expected fields';
}

# --- _article_detail_to_hash projects the get_product_details shape ------
{
  package Fake::ArticleDetail;
  sub new           { bless {}, shift }
  sub id            { 'art-1' }
  sub name          { 'Whole Milk' }
  sub price         { 119 }
  sub price_info    { { price => 119, original_price => 139 } }
  sub description   { 'Fresh whole milk, 1 litre.' }
  sub unit_quantity { '1 L' }
  sub image_ids     { ['img-1', 'img-2'] }
  sub labels        { ['organic'] }
}
{
  my $mcp = build_mcp();
  my $hash = $mcp->_article_detail_to_hash(Fake::ArticleDetail->new);
  is_deeply $hash, {
    id            => 'art-1',
    name          => 'Whole Milk',
    price         => 119,
    price_info    => { price => 119, original_price => 139 },
    description   => 'Fresh whole milk, 1 litre.',
    unit_quantity => '1 L',
    image_ids     => ['img-1', 'img-2'],
    labels        => ['organic'],
  }, '_article_detail_to_hash projects the expected fields';
}

# --- _cart_to_hash ---------------------------------------------------------
# Cart items are plain hashrefs (the backend shape), projected per-item through
# _cart_item_to_hash rather than passed straight through.
{
  package Fake::Cart;
  sub new { bless {}, shift }
  sub total_count   { 3 }
  sub total_price   { 357 }
  sub items         { [ { id => 'p1', name => 'Milk', count => 2, price => 119 } ] }
  sub selected_slot { 'slot-9' }
}
{
  my $mcp = build_mcp();
  my $hash = $mcp->_cart_to_hash(Fake::Cart->new);
  is_deeply $hash, {
    total_count   => 3,
    total_price   => 357,
    items         => [ { id => 'p1', name => 'Milk', count => 2, price => 119 } ],
    delivery_slot => 'slot-9'
  }, '_cart_to_hash projects items through _cart_item_to_hash (count kept, not renamed)';
}

# --- _cart_item_to_hash ----------------------------------------------------
{
  my $mcp = build_mcp();
  my $hash = $mcp->_cart_item_to_hash({
    id    => 'p1',
    name  => 'Milk',
    count => 2,
    price => 119,
    extra => 'ignored',
  });
  is_deeply $hash, {
    id    => 'p1',
    name  => 'Milk',
    count => 2,
    price => 119,
  }, '_cart_item_to_hash projects id/name/count/price, count is not renamed to quantity';
}

# --- _slot_to_hash -------------------------------------------------------
{
  package Fake::Slot;
  sub new { bless {}, shift }
  sub slot_id             { 'slot-9' }
  sub window_start        { '2026-06-20T10:00:00' }
  sub window_end          { '2026-06-20T11:00:00' }
  sub is_available        { 1 }
  sub minimum_order_value { 3500 }
}
{
  my $mcp = build_mcp();
  my $hash = $mcp->_slot_to_hash(Fake::Slot->new);
  is_deeply $hash, {
    slot_id             => 'slot-9',
    window_start        => '2026-06-20T10:00:00',
    window_end          => '2026-06-20T11:00:00',
    is_available        => 1,
    minimum_order_value => 3500
  }, '_slot_to_hash projects the expected fields';
}

# --- _user_to_hash -------------------------------------------------------
{
  package Fake::User;
  sub new { bless {}, shift }
  sub user_id   { 'usr-1' }
  sub firstname { 'Ada' }
  sub lastname  { 'Lovelace' }
  sub address   { 'Analytical Engine St 1' }
  sub phone     { '+490000000000' }
}
{
  my $mcp = build_mcp();
  my $hash = $mcp->_user_to_hash(Fake::User->new);
  is_deeply $hash, {
    user_id   => 'usr-1',
    firstname => 'Ada',
    lastname  => 'Lovelace',
    address   => 'Analytical Engine St 1',
    phone     => '+490000000000'
  }, '_user_to_hash projects the expected fields';
}

# --- _suggestion_to_hash ---------------------------------------------------
# Takes a plain hashref (the backend shape); internal id is omitted.
{
  my $mcp = build_mcp();
  my $hash = $mcp->_suggestion_to_hash({ id => 'sug-1', suggestion => 'milk', type => 'PRODUCT' });
  is_deeply $hash, {
    suggestion => 'milk',
    type       => 'PRODUCT',
  }, '_suggestion_to_hash projects suggestion/type, omits id';
}

# --- _category_to_hash ------------------------------------------------------
# Takes a plain hashref (the backend shape); nested items/decorators are omitted.
{
  my $mcp = build_mcp();
  my $hash = $mcp->_category_to_hash({
    type       => 'category',
    id         => 'cat-1',
    name       => 'Dairy',
    level      => 0,
    items      => ['sub-cat-1', 'sub-cat-2'],
    decorators => ['decorator-1'],
  });
  is_deeply $hash, {
    id    => 'cat-1',
    name  => 'Dairy',
    type  => 'category',
    level => 0,
  }, '_category_to_hash projects id/name/type/level, omits items and decorators';
}

# --- Helper: fetch a registered MCP::Tool instance by name -----------------
sub tool_named {
  my ($mcp, $name) = @_;
  for my $tool (@{$mcp->server->tools}) {
    return $tool if $tool->name eq $name;
  }
  return undef;
}

# --- REGRESSION (ticket #1): get_suggestions / get_categories must not leak
# a blessed WWW::Picnic::Result::* object into _to_json. Before the fix, the
# handlers mapped over ->all_suggestions / ->all_categories but then passed
# the *outer* result object (or an unprojected blessed item) into JSON
# encoding, which dies at runtime against WWW::Picnic >= 0.101 since
# convert_blessed=>1 with no TO_JSON just stringifies the ref address. Drive
# both tools end-to-end through a stubbed picnic attribute and assert the
# JSON text decodes to a plain array of projected hashes.
{
  package Fake::SuggestionsResult;
  sub new             { bless { suggestions => $_[1] }, $_[0] }
  sub all_suggestions { @{ $_[0]->{suggestions} } }
}
{
  package Fake::CategoriesResult;
  sub new           { bless { categories => $_[1] }, $_[0] }
  sub all_categories { @{ $_[0]->{categories} } }
}
{
  package Fake::Picnic::WithData;
  sub new { bless {}, shift }
  sub get_suggestions {
    return Fake::SuggestionsResult->new([
      { id => 'sug-1', suggestion => 'milk',           type => 'PRODUCT' },
      { id => 'sug-2', suggestion => 'milk chocolate', type => 'PRODUCT' },
    ]);
  }
  sub get_categories {
    return Fake::CategoriesResult->new([
      {
        type       => 'category',
        id         => 'cat-1',
        name       => 'Dairy',
        level      => 0,
        items      => ['sub-cat-1'],
        decorators => ['decorator-1'],
      },
    ]);
  }
}
{
  my $mcp = MCP::Picnic->new(
    user   => 'dummy@example.com',
    pass   => 'dummy-pass',
    picnic => Fake::Picnic::WithData->new,
  );
  $mcp->_auth_state('authenticated');

  my $suggestions_tool = tool_named($mcp, 'get_suggestions');
  my $result = $suggestions_tool->call({ term => 'mil' }, {});
  ok !$result->{isError}, 'get_suggestions does not error on a blessed backend result';
  my $decoded = $mcp->json->decode($result->{content}[0]{text});
  is_deeply $decoded, [
    { suggestion => 'milk',           type => 'PRODUCT' },
    { suggestion => 'milk chocolate', type => 'PRODUCT' },
  ], 'get_suggestions JSON decodes to the projected plain-hash array (no id, no blessed ref)';

  my $categories_tool = tool_named($mcp, 'get_categories');
  my $cat_result = $categories_tool->call({}, {});
  ok !$cat_result->{isError}, 'get_categories does not error on a blessed backend result';
  my $cat_decoded = $mcp->json->decode($cat_result->{content}[0]{text});
  is_deeply $cat_decoded, [
    { id => 'cat-1', name => 'Dairy', type => 'category', level => 0 },
  ], 'get_categories JSON decodes to the projected plain-hash array (no items/decorators, no blessed ref)';
}

done_testing;
