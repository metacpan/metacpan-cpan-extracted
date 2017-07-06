use strict;
use warnings;

use Marketplace::Ebay;
use Marketplace::Ebay::Response;
use File::Spec;
use Test::More;
use Data::Dumper;

# pulled in by XML::Compile
# use Log::Report  mode => "DEBUG";


my $ebay = Marketplace::Ebay->new(
                                  production => 0,
                                  site_id => 77,
                                  developer_key => '1234',
                                  application_key => '6789',
                                  certificate_key => '6666',
                                  token => 'asd12348' x 20,
                                  xsd_file => File::Spec->catfile(qw/t ebay.xsd/),
                                 );
my $xml = <<'XML';
<?xml version="1.0" encoding="UTF-8"?>
<GeteBayOfficialTimeResponse xmlns="urn:ebay:apis:eBLBaseComponents"><Timestamp>2014-12-16T11:31:23.999Z</Timestamp><Ack>Success</Ack><Version>891</Version><Build>E891_INTL_API_17051666_R1</Build></GeteBayOfficialTimeResponse>
XML

my $data = $ebay->_parse_response(GeteBayOfficialTime => $xml);

# print $ebay->show_xml_template(GeteBayOfficialTime => 'Response');

ok($data, "data parsed");
is($data->{Timestamp}, '2014-12-16T11:31:23.999Z', "Found the timestamp");
is($data->{Ack}, 'Success', "Found success ack");

my $struct = {
          'Fees' => {
                    'Fee' => [
                             {
                               'Fee' => {
                                        'currencyID' => 'GBP',
                                        '_' => bless( {
                                                        '_m' => [
                                                                  0
                                                                ],
                                                        '_e' => [
                                                                  1
                                                                ],
                                                        '_es' => '+',
                                                        'sign' => '+'
                                                      }, 'Math::BigFloat' )
                                      },
                               'Name' => 'AuctionLengthFee'
                             },
                             {
                               'Fee' => {
                                        'currencyID' => 'GBP',
                                        '_' => bless( {
                                                        'sign' => '+',
                                                        '_e' => [
                                                                  1
                                                                ],
                                                        '_m' => [
                                                                  0
                                                                ],
                                                        '_es' => '+'
                                                      }, 'Math::BigFloat' )
                                      },
                               'Name' => 'BoldFee'
                             },
                             {
                               'Fee' => {
                                        'currencyID' => 'GBP',
                                        '_' => bless( {
                                                        '_m' => [
                                                                  0
                                                                ],
                                                        '_e' => [
                                                                  1
                                                                ],
                                                        '_es' => '+',
                                                        'sign' => '+'
                                                      }, 'Math::BigFloat' )
                                      },
                               'Name' => 'BuyItNowFee'
                             },
                             {
                               'Fee' => {
                                        'currencyID' => 'GBP',
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
                                      },
                               'Name' => 'CategoryFeaturedFee'
                             },
                             {
                               'Name' => 'FeaturedFee',
                               'Fee' => {
                                        '_' => bless( {
                                                        'sign' => '+',
                                                        '_m' => [
                                                                  0
                                                                ],
                                                        '_e' => [
                                                                  1
                                                                ],
                                                        '_es' => '+'
                                                      }, 'Math::BigFloat' ),
                                        'currencyID' => 'GBP'
                                      }
                             },
                             {
                               'Name' => 'GalleryPlusFee',
                               'Fee' => {
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
                                        'currencyID' => 'GBP'
                                      }
                             },
                             {
                               'Fee' => {
                                        '_' => bless( {
                                                        'sign' => '+',
                                                        '_m' => [
                                                                  0
                                                                ],
                                                        '_e' => [
                                                                  1
                                                                ],
                                                        '_es' => '+'
                                                      }, 'Math::BigFloat' ),
                                        'currencyID' => 'GBP'
                                      },
                               'Name' => 'FeaturedGalleryFee'
                             },
                             {
                               'Fee' => {
                                        '_' => bless( {
                                                        'sign' => '+',
                                                        '_m' => [
                                                                  0
                                                                ],
                                                        '_e' => [
                                                                  1
                                                                ],
                                                        '_es' => '+'
                                                      }, 'Math::BigFloat' ),
                                        'currencyID' => 'GBP'
                                      },
                               'Name' => 'FixedPriceDurationFee'
                             },
                             {
                               'Fee' => {
                                        'currencyID' => 'GBP',
                                        '_' => bless( {
                                                        '_es' => '+',
                                                        '_e' => [
                                                                  1
                                                                ],
                                                        '_m' => [
                                                                  0
                                                                ],
                                                        'sign' => '+'
                                                      }, 'Math::BigFloat' )
                                      },
                               'Name' => 'GalleryFee'
                             },
                             {
                               'Name' => 'GiftIconFee',
                               'Fee' => {
                                        '_' => bless( {
                                                        'sign' => '+',
                                                        '_es' => '+',
                                                        '_e' => [
                                                                  1
                                                                ],
                                                        '_m' => [
                                                                  0
                                                                ]
                                                      }, 'Math::BigFloat' ),
                                        'currencyID' => 'GBP'
                                      }
                             },
                             {
                               'Name' => 'HighLightFee',
                               'Fee' => {
                                        '_' => bless( {
                                                        'sign' => '+',
                                                        '_es' => '+',
                                                        '_m' => [
                                                                  0
                                                                ],
                                                        '_e' => [
                                                                  1
                                                                ]
                                                      }, 'Math::BigFloat' ),
                                        'currencyID' => 'GBP'
                                      }
                             },
                             {
                               'Name' => 'InsertionFee',
                               'Fee' => {
                                        'currencyID' => 'GBP',
                                        '_' => bless( {
                                                        'sign' => '+',
                                                        '_es' => '-',
                                                        '_m' => [
                                                                  35
                                                                ],
                                                        '_e' => [
                                                                  2
                                                                ]
                                                      }, 'Math::BigFloat' )
                                      }
                             },
                             {
                               'Name' => 'InternationalInsertionFee',
                               'Fee' => {
                                        '_' => bless( {
                                                        'sign' => '+',
                                                        '_m' => [
                                                                  0
                                                                ],
                                                        '_e' => [
                                                                  1
                                                                ],
                                                        '_es' => '+'
                                                      }, 'Math::BigFloat' ),
                                        'currencyID' => 'GBP'
                                      }
                             },
                             {
                               'Name' => 'ListingDesignerFee',
                               'Fee' => {
                                        'currencyID' => 'GBP',
                                        '_' => bless( {
                                                        '_m' => [
                                                                  0
                                                                ],
                                                        '_e' => [
                                                                  1
                                                                ],
                                                        '_es' => '+',
                                                        'sign' => '+'
                                                      }, 'Math::BigFloat' )
                                      }
                             },
                             {
                               'Fee' => {
                                        'currencyID' => 'GBP',
                                        '_' => bless( {
                                                        'sign' => '+',
                                                        '_m' => [
                                                                  35
                                                                ],
                                                        '_e' => [
                                                                  2
                                                                ],
                                                        '_es' => '-'
                                                      }, 'Math::BigFloat' )
                                      },
                               'Name' => 'ListingFee'
                             },
                             {
                               'Name' => 'PhotoDisplayFee',
                               'Fee' => {
                                        'currencyID' => 'GBP',
                                        '_' => bless( {
                                                        '_m' => [
                                                                  0
                                                                ],
                                                        '_e' => [
                                                                  1
                                                                ],
                                                        '_es' => '+',
                                                        'sign' => '+'
                                                      }, 'Math::BigFloat' )
                                      }
                             },
                             {
                               'Name' => 'PhotoFee',
                               'Fee' => {
                                        'currencyID' => 'GBP',
                                        '_' => bless( {
                                                        'sign' => '+',
                                                        '_e' => [
                                                                  1
                                                                ],
                                                        '_m' => [
                                                                  0
                                                                ],
                                                        '_es' => '+'
                                                      }, 'Math::BigFloat' )
                                      }
                             },
                             {
                               'Fee' => {
                                        'currencyID' => 'GBP',
                                        '_' => bless( {
                                                        '_es' => '+',
                                                        '_e' => [
                                                                  1
                                                                ],
                                                        '_m' => [
                                                                  0
                                                                ],
                                                        'sign' => '+'
                                                      }, 'Math::BigFloat' )
                                      },
                               'Name' => 'ReserveFee'
                             },
                             {
                               'Fee' => {
                                        '_' => bless( {
                                                        '_m' => [
                                                                  0
                                                                ],
                                                        '_e' => [
                                                                  1
                                                                ],
                                                        '_es' => '+',
                                                        'sign' => '+'
                                                      }, 'Math::BigFloat' ),
                                        'currencyID' => 'GBP'
                                      },
                               'Name' => 'SchedulingFee'
                             },
                             {
                               'Name' => 'SubtitleFee',
                               'Fee' => {
                                        '_' => bless( {
                                                        'sign' => '+',
                                                        '_es' => '+',
                                                        '_m' => [
                                                                  0
                                                                ],
                                                        '_e' => [
                                                                  1
                                                                ]
                                                      }, 'Math::BigFloat' ),
                                        'currencyID' => 'GBP'
                                      }
                             },
                             {
                               'Name' => 'BorderFee',
                               'Fee' => {
                                        'currencyID' => 'GBP',
                                        '_' => bless( {
                                                        'sign' => '+',
                                                        '_es' => '+',
                                                        '_m' => [
                                                                  0
                                                                ],
                                                        '_e' => [
                                                                  1
                                                                ]
                                                      }, 'Math::BigFloat' )
                                      }
                             },
                             {
                               'Fee' => {
                                        '_' => bless( {
                                                        'sign' => '+',
                                                        '_es' => '+',
                                                        '_m' => [
                                                                  0
                                                                ],
                                                        '_e' => [
                                                                  1
                                                                ]
                                                      }, 'Math::BigFloat' ),
                                        'currencyID' => 'GBP'
                                      },
                               'Name' => 'ProPackBundleFee'
                             },
                             {
                               'Name' => 'BasicUpgradePackBundleFee',
                               'Fee' => {
                                        'currencyID' => 'GBP',
                                        '_' => bless( {
                                                        'sign' => '+',
                                                        '_m' => [
                                                                  0
                                                                ],
                                                        '_e' => [
                                                                  1
                                                                ],
                                                        '_es' => '+'
                                                      }, 'Math::BigFloat' )
                                      }
                             },
                             {
                               'Fee' => {
                                        'currencyID' => 'GBP',
                                        '_' => bless( {
                                                        'sign' => '+',
                                                        '_m' => [
                                                                  0
                                                                ],
                                                        '_e' => [
                                                                  1
                                                                ],
                                                        '_es' => '+'
                                                      }, 'Math::BigFloat' )
                                      },
                               'Name' => 'ValuePackBundleFee'
                             },
                             {
                               'Fee' => {
                                        'currencyID' => 'GBP',
                                        '_' => bless( {
                                                        '_es' => '+',
                                                        '_e' => [
                                                                  1
                                                                ],
                                                        '_m' => [
                                                                  0
                                                                ],
                                                        'sign' => '+'
                                                      }, 'Math::BigFloat' )
                                      },
                               'Name' => 'PrivateListingFee'
                             },
                             {
                               'Fee' => {
                                        '_' => bless( {
                                                        'sign' => '+',
                                                        '_e' => [
                                                                  1
                                                                ],
                                                        '_m' => [
                                                                  0
                                                                ],
                                                        '_es' => '+'
                                                      }, 'Math::BigFloat' ),
                                        'currencyID' => 'GBP'
                                      },
                               'Name' => 'ProPackPlusBundleFee'
                             },
                             {
                               'Name' => 'MotorsGermanySearchFee',
                               'Fee' => {
                                        '_' => bless( {
                                                        'sign' => '+',
                                                        '_es' => '+',
                                                        '_m' => [
                                                                  0
                                                                ],
                                                        '_e' => [
                                                                  1
                                                                ]
                                                      }, 'Math::BigFloat' ),
                                        'currencyID' => 'GBP'
                                      }
                             }
                           ]
                  },
          'StartTime' => '2014-12-18T08:45:39.351Z',
          'Version' => '899',
          'Ack' => 'Success',
          'EndTime' => '2014-12-25T08:45:39.351Z',
          'Build' => 'E899_UNI_API5_17299296_R1',
          'Timestamp' => '2014-12-18T08:45:39.772Z',
          'ItemID' => '9999999'
        };

my $response = Marketplace::Ebay::Response->new(struct => $struct);

ok($response->is_success, "response is success");
is ($response->version, '899', "version found");
is_deeply($response->fees,
          {
           'FeaturedGalleryFee' => '0.00',
           'BoldFee' => '0.00',
           'GiftIconFee' => '0.00',
           'PhotoDisplayFee' => '0.00',
           'MotorsGermanySearchFee' => '0.00',
           'BorderFee' => '0.00',
           'SubtitleFee' => '0.00',
           'AuctionLengthFee' => '0.00',
           'BasicUpgradePackBundleFee' => '0.00',
           'ValuePackBundleFee' => '0.00',
           'PhotoFee' => '0.00',
           'ReserveFee' => '0.00',
           'PrivateListingFee' => '0.00',
           'GalleryPlusFee' => '0.00',
           'FixedPriceDurationFee' => '0.00',
           'CategoryFeaturedFee' => '0.00',
           'ListingFee' => '0.35',
           'InsertionFee' => '0.35',
           'GalleryFee' => '0.00',
           'SchedulingFee' => '0.00',
           'InternationalInsertionFee' => '0.00',
           'ListingDesignerFee' => '0.00',
           'FeaturedFee' => '0.00',
           'ProPackBundleFee' => '0.00',
           'HighLightFee' => '0.00',
           'ProPackPlusBundleFee' => '0.00',
           'BuyItNowFee' => '0.00'
          }, "fees as expected");

is ($response->total_listing_fee, '0.35', "listing fee is 0.35");
is ($response->item_id, '9999999', "item_id ok");
is ($response->start_time, '2014-12-18T08:45:39.351Z', "start_time ok");
is ($response->start_time_dt->ymd, '2014-12-18');
is ($response->end_time, '2014-12-25T08:45:39.351Z', "stop_time ok");
is ($response->end_time_dt->ymd, '2014-12-25');
is ($response->timestamp, '2014-12-18T08:45:39.772Z', "timestamp ok");
is ($response->timestamp_dt->ymd, '2014-12-18', "timestamp ok");

delete $struct->{Timestamp};
$response = Marketplace::Ebay::Response->new(struct => $struct);

is ($response->timestamp, undef, "now timestamp is not found");

$struct = {
           'Version' => '899',
           'Timestamp' => '2014-12-18T10:18:43.819Z',
           'Ack' => 'Failure',
           'Errors' => [
                        {
                         'ErrorParameters' => [
                                               {
                                                'ParamID' => '0',
                                                'Value' => 'Blab lbal bal'
                                               },
                                               {
                                                'Value' => 'XXXXXXXX',
                                                'ParamID' => '1'
                                               }
                                              ],
                         'ErrorClassification' => 'RequestError',
                         'LongMessage' => 'This Listing is a duplicate of your item: Blab lbal bal (XXXXXXXX). Under the Duplicate Listing policy, sellers can\'t have multiple Fixed Price listings, multiple Auction-style (with the Buy It Now option) listings, or in both the Fixed Price and Auction-style (with the Buy It Now option) listings for identical items at the same time. We recommend you create a multiple quantity Fixed Price listing to sell identical items.',
                         'ShortMessage' => 'Listing violates the Duplicate Listing policy.',
                         'SeverityCode' => 'Error',
                         'ErrorCode' => '21919067'
                        }
                       ],
           'Build' => 'E899_UNI_API5_17299296_R1'
          };

$response = Marketplace::Ebay::Response->new(struct => $struct);
is_deeply($response->errors, $struct->{Errors}, "found errors");
diag $response->errors_as_string;
like $response->errors_as_string, qr/21919067/;
is_deeply([$response->error_codes], [21919067]);
like $response->errors_as_string, qr/Listing violates the Duplicate Listing policy/;
like $response->errors_as_string, qr/This Listing is a duplicate of your item: Blab lbal bal/;

$struct = {
           'Errors' => [
                        {
                         'LongMessage' => "Diese Sendungsnummer wird bereits verwendet und kann nicht f\x{fc}r mehrere Transaktionen eingesetzt werden. Der Artikel wurde jedoch bereits als verschickt markiert.",
                         'ErrorClassification' => 'RequestError',
                         'SeverityCode' => 'Error',
                         'ShortMessage' => 'Sendungsnummer wird bereits verwendet.',
                         'ErrorCode' => '21919089'
                        }
                       ],
           'Version' => '975',
           'Ack' => 'Failure',
           'Build' => 'E975_XXXX',
           'Timestamp' => '2016-09-03T12:20:04.700Z'
          };

$response = Marketplace::Ebay::Response->new(struct => $struct);
is_deeply($response->errors, $struct->{Errors}, "found errors");
ok ($response->is_error_code('21919089'));
ok ($response->has_error_code('21919089'));

$struct = {
           'Errors' => [
                        {
                         'LongMessage' => "Diese Sendungsnummer wird bereits verwendet und kann nicht f\x{fc}r mehrere Transaktionen eingesetzt werden. Der Artikel wurde jedoch bereits als verschickt markiert.",
                         'ErrorClassification' => 'RequestError',
                         'SeverityCode' => 'Error',
                         'ShortMessage' => 'Sendungsnummer wird bereits verwendet.',
                         'ErrorCode' => '21919089'
                        },
                        {
                         'ErrorParameters' => [
                                               {
                                                'ParamID' => '0',
                                                'Value' => 'Blab lbal bal'
                                               },
                                               {
                                                'Value' => 'XXXXXXXX',
                                                'ParamID' => '1'
                                               }
                                              ],
                         'ErrorClassification' => 'RequestError',
                         'LongMessage' => 'This Listing is a duplicate of your item: Blab lbal bal (XXXXXXXX). Under the Duplicate Listing policy, sellers can\'t have multiple Fixed Price listings, multiple Auction-style (with the Buy It Now option) listings, or in both the Fixed Price and Auction-style (with the Buy It Now option) listings for identical items at the same time. We recommend you create a multiple quantity Fixed Price listing to sell identical items.',
                         'ShortMessage' => 'Listing violates the Duplicate Listing policy.',
                         'SeverityCode' => 'Error',
                         'ErrorCode' => '21919067'
                        }
                       ],
           'Version' => '975',
           'Ack' => 'Failure',
           'Build' => 'E975_XXXX',
           'Timestamp' => '2016-09-03T12:20:04.700Z'
          };

$response = Marketplace::Ebay::Response->new(struct => $struct);
is_deeply($response->errors, $struct->{Errors}, "found errors");
ok (!$response->is_error_code('21919089'), "Multiple errors, is not a single one");
ok ($response->has_error_code('21919089'), "Found the error");
is ($response->errors_count, 2, "Two errors");


$struct = {
           'Errors' => [
                        {
                         'LongMessage' => "Diese Sendungsnummer wird bereits verwendet und kann nicht f\x{fc}r mehrere Transaktionen eingesetzt werden. Der Artikel wurde jedoch bereits als verschickt markiert.",
                         'ErrorClassification' => 'RequestError',
                         'SeverityCode' => 'Error',
                         'ShortMessage' => 'Sendungsnummer wird bereits verwendet.',
                         'ErrorCode' => '21919089'
                        },
                        {
                         'LongMessage' => "Diese Sendungsnummer wird bereits verwendet und kann nicht f\x{fc}r mehrere Transaktionen eingesetzt werden. Der Artikel wurde jedoch bereits als verschickt markiert.",
                         'ErrorClassification' => 'RequestError',
                         'SeverityCode' => 'Error',
                         'ShortMessage' => 'Sendungsnummer wird bereits verwendet.',
                         'ErrorCode' => '21919089'
                        }
                       ],
           'Version' => '975',
           'Ack' => 'Failure',
           'Build' => 'E975_XXXX',
           'Timestamp' => '2016-09-03T12:20:04.700Z'
          };

$response = Marketplace::Ebay::Response->new(struct => $struct);
is_deeply($response->errors, $struct->{Errors}, "found errors");
ok ($response->is_error_code('21919089'));
ok ($response->has_error_code('21919089'));
is ($response->errors_count, 2, "Two errors, but they have the same code");
eval { $response->has_error_code() };
ok $@, "Found error $@ with missing argument";
eval { $response->is_error_code() };
ok $@, "Found error $@ with missing argument";
done_testing;
