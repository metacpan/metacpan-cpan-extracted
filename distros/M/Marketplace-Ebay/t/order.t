#!perl

use strict;
use warnings;
use Test::More;
use_ok ('Marketplace::Ebay::Order');
use Math::BigFloat;

my $struc = {
            'IntegratedMerchantCreditCardEnabled' => 0,
            'AdjustmentAmount' => {
                                  '_' => bless( {
                                                  '_e' => [
                                                            1
                                                          ],
                                                  'sign' => '+',
                                                  '_es' => '+',
                                                  '_m' => [
                                                            0
                                                          ]
                                                }, 'Math::BigFloat' ),
                                  'currencyID' => 'EUR'
                                },
            'CancelStatus' => 'NotApplicable',
            'SellerUserID' => 'seller_id',
            'OrderStatus' => 'Completed',
            'BuyerUserID' => 'meeeeoowww',
            'ShippingAddress' => {
                                 'Street1' => 'Pixasdf.21',
                                 'Country' => 'DE',
                                 'CityName' => "Foou\x{fc}ren",
                                 'Name' => 'Pinco U. Pallino-Pinz',
                                 'StateOrProvince' => '',
                                 'Phone' => 'Invalid Request',
                                 'AddressOwner' => 'eBay',
                                 'ExternalAddressID' => '',
                                 'AddressID' => '6666666',
                                 'PostalCode' => '48499',
                                 'Street2' => '',
                                 'CountryName' => 'Deutschland'
                               },
            'ShippingDetails' => {
                                 'SalesTax' => {
                                               'ShippingIncludedInTax' => 0,
                                               'SalesTaxState' => '',
                                               'SalesTaxPercent' => bless( {
                                                                           '_m' => [
                                                                                     0
                                                                                   ],
                                                                           '_es' => '+',
                                                                           '_e' => [
                                                                                     1
                                                                                   ],
                                                                           'sign' => '+'
                                                                         }, 'Math::BigFloat' ),
                                               'SalesTaxAmount' => {
                                                                   'currencyID' => 'EUR',
                                                                   '_' => bless( {
                                                                                   '_m' => [
                                                                                             0
                                                                                           ],
                                                                                   '_es' => '+',
                                                                                   '_e' => [
                                                                                             1
                                                                                           ],
                                                                                   'sign' => '+'
                                                                                 }, 'Math::BigFloat' )
                                                                 }
                                             },
                                 'GetItFast' => 0,
                                 'InsuranceWanted' => 0,
                                 'SellingManagerSalesRecordNumber' => 6666,
                                 'InsuranceOption' => 'NotOffered',
                                 'InsuranceFee' => {
                                                   '_' => bless( {
                                                                   '_es' => '+',
                                                                   '_m' => [
                                                                             0
                                                                           ],
                                                                   '_e' => [
                                                                             1
                                                                           ],
                                                                   'sign' => '+'
                                                                 }, 'Math::BigFloat' ),
                                                   'currencyID' => 'EUR'
                                                 },
                                 'ShippingServiceOptions' => [
                                                             {
                                                               'ShippingServicePriority' => 1,
                                                               'ShippingTimeMin' => 1,
                                                               'ExpeditedService' => 0,
                                                               'ShippingService' => 'DE_DHLPaket',
                                                               'ShippingServiceCost' => {
                                                                                        '_' => bless( {
                                                                                                        'sign' => '+',
                                                                                                        '_e' => [
                                                                                                                  0
                                                                                                                ],
                                                                                                        '_m' => [
                                                                                                                  5
                                                                                                                ],
                                                                                                        '_es' => '+'
                                                                                                      }, 'Math::BigFloat' ),
                                                                                        'currencyID' => 'EUR'
                                                                                      },
                                                               'ShippingTimeMax' => 2
                                                             }
                                                           ]
                               },
            'CreatedTime' => '2015-06-18T08:58:12.000Z',
            'SellerEmail' => 'selleremail@mytest.com',
            'PaymentMethods' => [
                                'PayPal'
                              ],
            'PaymentHoldStatus' => 'None',
            'IsMultiLegShipping' => 0,
            'OrderID' => '123412341234-1234123412341',
            'TransactionArray' => {
                                  'Transaction' => [
                                                   {
                                                     'Variation' => {
                                                                    'VariationViewItemURL' => 'http://cgi.ebay.de/ws/eBayISAPI.dll?ViewItem&item=666666666666&vti=Farbe%09schwarz%0AGr%C3%B6%C3%9Fe%09110cm',
                                                                    'VariationSpecifics' => {
                                                                                            'NameValueList' => [
                                                                                                               {
                                                                                                                 'Name' => 'Farbe',
                                                                                                                 'Value' => [
                                                                                                                            'schwarz'
                                                                                                                          ]
                                                                                                               },
                                                                                                               {
                                                                                                                 'Value' => [
                                                                                                                            '110cm'
                                                                                                                          ],
                                                                                                                 'Name' => "Gr\x{f6}\x{df}e"
                                                                                                               }
                                                                                                             ]
                                                                                          },
                                                                    'VariationTitle' => 'Title - alsdflkj alksdjflkk asldkfl kasdfkljalskdf]',
                                                                    'SKU' => '1030112-009000-110'
                                                                  },
                                                     'ShippingServiceSelected' => {
                                                                                  'ShippingPackageInfo' => [
                                                                                                           {
                                                                                                             'EstimatedDeliveryTimeMax' => '2015-06-25T07:00:00.000Z',
                                                                                                             'EstimatedDeliveryTimeMin' => '2015-06-24T07:00:00.000Z'
                                                                                                           }
                                                                                                         ]
                                                                                },
                                                     'TransactionID' => '1396666666666',
                                                     'Buyer' => {
                                                                'UserFirstName' => 'Pinco',
                                                                'UserLastName' => 'Pallino',
                                                                'Email' => 'pallino.pinco@net.hr',
                                                              },
                                                     'ExtendedOrderID' => '123412342345-2345435838998!666666666666',
                                                     'TransactionSiteID' => 'Germany',
                                                     'Status' => {
                                                                 'PaymentHoldStatus' => 'None',
                                                                 'InquiryStatus' => 'NotApplicable',
                                                                 'ReturnStatus' => 'NotApplicable'
                                                               },
                                                     'ShippingDetails' => {
                                                                          'SellingManagerSalesRecordNumber' => 6666,
                                                                        },
                                                     'QuantityPurchased' => 1,
                                                     'TransactionPrice' => {
                                                                           'currencyID' => 'EUR',
                                                                           '_' => bless( {
                                                                                           '_m' => [
                                                                                                     199
                                                                                                   ],
                                                                                           '_es' => '-',
                                                                                           'sign' => '+',
                                                                                           '_e' => [
                                                                                                     1
                                                                                                   ]
                                                                                         }, 'Math::BigFloat' )
                                                                         },
                                                     'Item' => {
                                                               'Title' => 'Title - lsdflkj alksdjflkk asldkfl kasdfkljalskdf]',
                                                               'ConditionID' => 1000,
                                                               'SKU' => '1030112',
                                                               'ConditionDisplayName' => 'Neu',
                                                               'Site' => 'Germany',
                                                               'ItemID' => '222222222222'
                                                             },
                                                     'Taxes' => {
                                                                'TotalTaxAmount' => {
                                                                                    'currencyID' => 'EUR',
                                                                                    '_' => bless( {
                                                                                                    '_m' => [
                                                                                                              0
                                                                                                            ],
                                                                                                    '_es' => '+',
                                                                                                    '_e' => [
                                                                                                              1
                                                                                                            ],
                                                                                                    'sign' => '+'
                                                                                                  }, 'Math::BigFloat' )
                                                                                  },
                                                                'TaxDetails' => [
                                                                                {
                                                                                  'TaxDescription' => 'SalesTax',
                                                                                  'TaxOnSubtotalAmount' => {
                                                                                                           'currencyID' => 'EUR',
                                                                                                           '_' => bless( {
                                                                                                                           '_e' => [
                                                                                                                                     1
                                                                                                                                   ],
                                                                                                                           'sign' => '+',
                                                                                                                           '_es' => '+',
                                                                                                                           '_m' => [
                                                                                                                                     0
                                                                                                                                   ]
                                                                                                                         }, 'Math::BigFloat' )
                                                                                                         },
                                                                                  'TaxOnShippingAmount' => {
                                                                                                           '_' => bless( {
                                                                                                                           '_e' => [
                                                                                                                                     1
                                                                                                                                   ],
                                                                                                                           'sign' => '+',
                                                                                                                           '_es' => '+',
                                                                                                                           '_m' => [
                                                                                                                                     0
                                                                                                                                   ]
                                                                                                                         }, 'Math::BigFloat' ),
                                                                                                           'currencyID' => 'EUR'
                                                                                                         },
                                                                                  'TaxAmount' => {
                                                                                                 '_' => bless( {
                                                                                                                 '_m' => [
                                                                                                                           0
                                                                                                                         ],
                                                                                                                 '_es' => '+',
                                                                                                                 '_e' => [
                                                                                                                           1
                                                                                                                         ],
                                                                                                                 'sign' => '+'
                                                                                                               }, 'Math::BigFloat' ),
                                                                                                 'currencyID' => 'EUR'
                                                                                               },
                                                                                  'Imposition' => 'SalesTax',
                                                                                  'TaxOnHandlingAmount' => {
                                                                                                           'currencyID' => 'EUR',
                                                                                                           '_' => bless( {
                                                                                                                           '_m' => [
                                                                                                                                     0
                                                                                                                                   ],
                                                                                                                           '_es' => '+',
                                                                                                                           '_e' => [
                                                                                                                                     1
                                                                                                                                   ],
                                                                                                                           'sign' => '+'
                                                                                                                         }, 'Math::BigFloat' )
                                                                                                         }
                                                                                },
                                                                                {
                                                                                  'Imposition' => 'WasteRecyclingFee',
                                                                                  'TaxAmount' => {
                                                                                                 '_' => bless( {
                                                                                                                 '_m' => [
                                                                                                                           0
                                                                                                                         ],
                                                                                                                 '_es' => '+',
                                                                                                                 'sign' => '+',
                                                                                                                 '_e' => [
                                                                                                                           1
                                                                                                                         ]
                                                                                                               }, 'Math::BigFloat' ),
                                                                                                 'currencyID' => 'EUR'
                                                                                               },
                                                                                  'TaxDescription' => 'ElectronicWasteRecyclingFee'
                                                                                }
                                                                              ]
                                                              },
                                                     'OrderLineItemID' => '123498123394-9012349812343',
                                                     'CreatedDate' => '2015-06-18T08:58:12.000Z',
                                                     'Platform' => 'eBay'
                                                   }
                                                 ]
                                },
            'PaidTime' => '2015-06-18T09:02:41.000Z',
            'BuyerCheckoutMessage' => 'Testbestellung',
            'ExtendedOrderID' => '123412341234-1234123412343!123412341234',
            'EIASToken' => 'kxkw8kdjk8jsd89je81jsd84jkwtoiujwoktjqwkojrkjwo1894w2e==',
            'AmountPaid' => {
                            '_' => bless( {
                                            '_es' => '-',
                                            '_m' => [
                                                      249
                                                    ],
                                            'sign' => '+',
                                            '_e' => [
                                                      1
                                                    ]
                                          }, 'Math::BigFloat' ),
                            'currencyID' => 'EUR'
                          },
            'ShippingServiceSelected' => {
                                         'ShippingInsuranceCost' => {
                                                                    'currencyID' => 'EUR',
                                                                    '_' => bless( {
                                                                                    'sign' => '+',
                                                                                    '_e' => [
                                                                                              1
                                                                                            ],
                                                                                    '_es' => '+',
                                                                                    '_m' => [
                                                                                              0
                                                                                            ]
                                                                                  }, 'Math::BigFloat' )
                                                                  },
                                         'ShippingService' => 'DE_DHLPaket',
                                         'ShippingServiceCost' => {
                                                                  '_' => bless( {
                                                                                  'sign' => '+',
                                                                                  '_e' => [
                                                                                            0
                                                                                          ],
                                                                                  '_es' => '+',
                                                                                  '_m' => [
                                                                                            5
                                                                                          ]
                                                                                }, 'Math::BigFloat' ),
                                                                  'currencyID' => 'EUR'
                                                                }
                                       },
            'Subtotal' => {
                          'currencyID' => 'EUR',
                          '_' => bless( {
                                          '_m' => [
                                                    199
                                                  ],
                                          '_es' => '-',
                                          '_e' => [
                                                    1
                                                  ],
                                          'sign' => '+'
                                        }, 'Math::BigFloat' )
                        },
            'CheckoutStatus' => {
                                'eBayPaymentStatus' => 'NoPaymentFailure',
                                'IntegratedMerchantCreditCardEnabled' => 0,
                                'LastModifiedTime' => '2015-06-18T09:02:41.000Z',
                                'PaymentInstrument' => 'PayPal',
                                'PaymentMethod' => 'PayPal',
                                'Status' => 'Complete'
                              },
            'SellerEIASToken' => 'sxkd91o23oas123412341234asjdo71934j5lkasjdfo792354jklw==',
            'Total' => {
                       'currencyID' => 'EUR',
                       '_' => bless( {
                                       '_e' => [
                                                 1
                                               ],
                                       'sign' => '+',
                                       '_m' => [
                                                 249
                                               ],
                                       '_es' => '-'
                                     }, 'Math::BigFloat' )
                     },
            'AmountSaved' => {
                             'currencyID' => 'EUR',
                             '_' => bless( {
                                             '_es' => '+',
                                             '_m' => [
                                                       0
                                                     ],
                                             '_e' => [
                                                       1
                                                     ],
                                             'sign' => '+'
                                           }, 'Math::BigFloat' )
                           }
            };

my $order = Marketplace::Ebay::Order->new(order => $struc);
ok ($order, "object created");
is_deeply($order->order, $struc, "order contains the struct");
is ($order->shop_type, 'ebay', "Fixed string for shop type");

my $address = $order->shipping_address;
is ($address->address1, 'Pixasdf.21');
is ($address->address2, '' );
is ($address->name, 'Pinco U. Pallino-Pinz');
is ($address->city, "Foou\x{fc}ren");
is ($address->state, '');
is ($address->zip, '48499');
is ($address->phone, '');
is ($address->country, 'DE');

my ($item) = $order->items;
is ($item->sku, '1030112-009000-110', "sku ok");
is ($item->variant_sku, '1030112-009000-110', "variant sku ok");
is ($item->canonical_sku, '1030112', "canonical ok");

is ($item->price, '19.90');
is ($item->subtotal, '19.90');
is ($order->shipping_cost, '5.00');
is ($order->total_cost, '24.90');
is ($order->subtotal, '19.90');
is ($order->payment_method, 'PayPal');
is ($order->currency, 'EUR');
is ($item->remote_shop_order_item, '123498123394-9012349812343');
ok (!$item->is_shipped);
ok (!$order->order_is_shipped);
is ($order->email,'pallino.pinco@net.hr');
is ($order->first_name, 'Pinco U.', "first name ok");
is ($order->last_name, 'Pallino-Pinz', "last name ok");
is ($order->order_date->ymd, '2015-06-18');
is ($order->shipping_method, 'DE_DHLPaket', "shipping method ok");
is ($order->username, 'meeeeoowww', "username ok");
$order = Marketplace::Ebay::Order->new(order => $struc, name_from_shipping_address => 0);
is ($order->first_name, 'Pinco', "Legacy option works for first name");
is ($order->last_name, 'Pallino', "Legacy option works for last name");

$struc->{ShippingAddress}->{Name} = 'Marco';

$order = Marketplace::Ebay::Order->new(order => $struc);
is ($order->first_name, '', "first name kinda ok");
is ($order->last_name, 'Marco', 'last name ok');

done_testing;
