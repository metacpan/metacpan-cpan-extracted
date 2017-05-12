#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 115;
use Data::Dumper;

use_ok('Marketplace::Rakuten::Response');
use_ok('Marketplace::Rakuten');


# key is the sandbox one
# http://webservice.rakuten.de/documentation/howto/test
my $rakuten = Marketplace::Rakuten->new(key => '123456789a123456789a123456789a12');

ok $rakuten->key;

is $rakuten->endpoint, 'http://webservice.rakuten.de/merchants/';

test_success('get_key_info');
test_success(add_product => {
                             name => 'test',
                             price => '10.00',
                             description => 'a test product',
                             product_art_no => 'SKU00001',
                            }, 'product_id');

test_failure(add_product => {
                             name => 'test',
                             description => 'a test product',
                            });
test_success(add_product_image => {
                                   product_art_no => 'SKU00001',
                                  });

test_success(add_product_image => {
                                   product_art_no => 'SKU00001',
                                   url => 'http://my_image/prova.png'
                                  }, 'image_id');


test_failure(add_product_variant => {
                                     product_id => '1',
                                    });

test_success(add_product_variant => {
                                     product_art_no => 'SKU00001',
                                     variant_art_no => 'SKU00001-Blue',
                                     label => 'Color',
                                     name => 'Blue',
                                     price => '10.05',
                                    }, 'variant_id');



# here it looks like the sandbox return a success => 0 which is not documented.
test_success(add_product_variant_definition => {
                                                product_id => '1',
                                                variant_1 => 'Farbe',
                                                variant_2 => 'Size',
                                               });

test_success(add_product_multi_variant => {
                                           product_art_no => 'SKU00001',
                                           variant_art_no => 'SKU00001-Blue-Big',
                                           variation1_type => 'Farbe',
                                           variation1_value => 'Blue',
                                           variation2_type => 'Size',
                                           variation2_value => 'Big',
                                           price => '10.05',
                                          });

test_success(add_product_link => {
                                  product_art_no => 'SKU00001',
                                  name => 'My product',
                                  url => 'http://example.org/my-product',
                                 }, 'link_id');

test_success(add_product_attribute => {
                                       product_art_no => 'SKU00001',
                                       title => 'An attribute',
                                       value => 'The value of the attribute',
                                      }, 'attribute_id');

test_success(edit_product => {
                              product_art_no => 'SKU00001',
                              description => 'edited',
                             }, 'success');

test_success(edit_product_variant => {
                                      variant_art_no => 'SKU00001-Big-Blue',
                                      description => 'edited',
                                     }, 'success');

test_success(edit_product_variant_definition => {
                                                 product_art_no => 'SKU00001',
                                                 variant_1 => 'Coolor',
                                                });

test_success(edit_product_multi_variant => {
                                            variant_art_no => 'SKU00001-Big-Blue',
                                            description => 'edited',
                                           }, 'success');

test_success(edit_product_attribute => {
                                        attribute_id => '1',
                                        title => 'An attribute',
                                        value => 'The value of the attribute',
                                       }, 'success');

test_success(delete_product => {
                              product_art_no => 'SKU00001',
                             }, 'success');

test_success(delete_product_variant => {
                                      variant_art_no => 'SKU00001-Big-Blue',
                                     }, 'success');

test_success(delete_product_image => {
                                      image_id => '1',
                                     }, 'success');

test_success(delete_product_link => {
                                     link_id => '1',
                                    }, 'success');

test_success(delete_product_attribute => {
                                        attribute_id => '1',
                                       }, 'success');

test_success(get_orders => {} => 'success', sub { print Dumper(shift) });

test_success(set_order_shipped => {
                                   order_no => '111-222-333',
                                   carrier => 'TNT',
                                   tracking_number => '12341234',
                                  }, 'success');

test_success(set_order_cancelled => {
                                     order_no => '111-222-333',
                                     comment => 'False alarm',
                                  }, 'success');
# out of order, apparently
# test_success(set_order_returned => {
#                                     order_no => '111-222-333',
#                                     type => 'partly',
#                                   }, 'success');
# 

test_success(get_shop_categories => {});
test_success(add_shop_category => { name => 'Test' }, 'shop_category_id');
test_success(edit_shop_category => { shop_category_id => 1, name => 'Test2' },
             'success');
test_success(delete_shop_category => { shop_category_id => 1 }, 'success');
test_success(add_product_to_shop_category => {
                                              shop_category_id => 1,
                                              product_art_no => 'SKU000001',
                                             }, 'success');

# test_failure(add_product_image => {}) # sandbox always return success

sub test_success {
    my ($call, $arg, $expected_data, $sub) = @_;
    diag "Calling $call with " . Dumper($arg);
    my $res = $rakuten->$call($arg);
    ok ($res->is_success, "$call with is OK");
    ok ($res->content, "$call content ok");
    ok ($res->data, "$call data ok") and diag Dumper($res->data);
    if ($expected_data) {
        ok($res->data->{$expected_data}, "Found $expected_data in data");
    }
    if ($sub) {
        ok($sub->($res), "Callback test on $call success");
    }
}

sub test_failure {
    my ($call, $arg, $sub) = @_;
    diag "Calling $call with " . Dumper($arg);
    my $res = $rakuten->$call($arg);
    ok (!$res->is_success, "$call is a falure");
    ok ($res->errors, "Found errors") and diag Dumper($res->errors);
    ok ($res->content, "$call content ok");
    ok ($res->data, "$call data ok") and diag Dumper($res->data);
    if ($sub) {
        ok($sub->($res), "Callback test on $call success");
    }
}
