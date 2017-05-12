#!perl

use strict;
use warnings;

use Marketplace::Ebay;
use File::Spec;
use Test::More;
use Data::Dumper;

# pulled in by XML::Compile
# use Log::Report  mode => "DEBUG";


plan tests => 4;


my $ebay = Marketplace::Ebay->new(
                                  production => 0,
                                  site_id => 77,
                                  developer_key => '1234',
                                  application_key => '6789',
                                  certificate_key => '6666',
                                  token => 'asd12348' x 20,
                                  xsd_file => File::Spec->catfile(qw/t ebay.xsd/),
                                 );

like $ebay->session_certificate, qr/;/, "Session created";

ok($ebay->schema, "Schema found");

my $xml = $ebay->prepare_xml('GeteBayOfficialTime');
like $xml, qr{<GeteBayOfficialTimeRequest .*</GeteBayOfficialTimeRequest>}s,
  "XML looks ok";

# print $ebay->show_xml_template("AddItem");

my $item = {
            Country => "US",
            Description => "Like new. Shipping is responsibility of the buyer.",
            ListingDuration => "7",
            Location => "Anytown, USA, 43215",
            PictureDetails => {
                               GalleryType => "Gallery",
                               GalleryURL => 'http://example.org/test.jpg',
                              },
            BuyItNowPrice => { currencyID => 'EUR', _ => 19.99} ,
            Quantity => "1",
            Title => "Igor's Item with Gallery xaxa",
           };


$xml = $ebay->prepare_xml("AddItem", { Item => $item });

like($xml, qr{<AddItemRequest .*eBayAuthToken.*</Item>.*</AddItemRequest>}s,
     "XML produced");
# print $xml;
