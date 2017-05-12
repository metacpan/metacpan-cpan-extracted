#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 12;
use Data::Dumper;
use Marketplace::Rakuten::Response;
use Marketplace::Rakuten;
$Data::Dumper::Sortkeys = 1;

my $sandbox = {
                       'url' => 'http://webservice.rakuten.de/merchants/orders/getOrders?key=123456789a123456789a123456789a12&status=pending',
                       'headers' => {
                                     'serv' => '101',
                                     'date' => 'Thu, 06 Apr 2017 08:12:44 GMT',
                                     'access-control-allow-headers' => 'Origin, X-Requested-With, Content-Type, Accept, 2',
                                     'connection' => 'keep-alive',
                                     'vary' => 'Accept-Encoding',
                                     'access-control-allow-origin' => [
                                                                       'https://www.rakuten.de',
                                                                       'http://www.rakuten.de'
                                                                      ],
                                     'content-length' => '2177',
                                     'p3p' => 'CP="CURa ADMa DEVa PSAo PSDo OUR BUS UNI PUR INT DEM STA PRE COM NAV OTC NOI DSP COR"',
                                     'hamster' => '225',
                                     'server' => 'nginx',
                                     'content-type' => 'text/xml; charset=utf-8'
                                    },
                       'success' => 1,
                                 'content' => '<?xml version="1.0" encoding="utf-8"?>
<result>
  <success>1</success>
  <orders>
    <paging>
      <total>1</total>
      <page>1</page>
      <pages>1</pages>
      <per_page>20</per_page>
    </paging>
    <order>
      <order_no>123-456-789</order_no>
      <total>12.12</total>
      <shipping>3.50</shipping>
      <max_shipping_date>2010-01-01 20:15:00</max_shipping_date>
      <payment>CC</payment>
      <status>pending</status>
      <invoice_no>123456</invoice_no>
      <comment_client>Ich freu mich so sehr!</comment_client>
      <comment_merchant>Beim Lieferanten bestellt</comment_merchant>
      <created>2010-01-01 20:15:00</created>
      <client>
        <client_id>1</client_id>
        <gender>Herr</gender>
        <first_name>Max</first_name>
        <last_name>Mustermann</last_name>
        <company>Muster GmbH</company>
        <street>Musterstraße</street>
        <street_no>1</street_no>
        <address_add>Seiteneingang</address_add>
        <zip_code>11111</zip_code>
        <city>Musterstadt</city>
        <country>DE</country>
        <email>max@mustermann.de</email>
        <phone>123456-4555</phone>
      </client>
      <delivery_address>
        <gender>Herr</gender>
        <first_name>Max</first_name>
        <last_name>Mustermann</last_name>
        <company>Muster GmbH</company>
        <street>Musterstraße</street>
        <street_no>1</street_no>
        <address_add>Seiteneingang</address_add>
        <zip_code>11111</zip_code>
        <city>Musterstadt</city>
        <country>DE</country>
      </delivery_address>
      <items>
        <item>
          <item_id>1</item_id>
          <product_id>1</product_id>
          <variant_id>5</variant_id>
          <product_art_no>ART-99</product_art_no>
          <name>Musterprodukt</name>
          <name_add>Grün</name_add>
          <qty>2</qty>
          <price>10.00</price>
          <price_sum>20.00</price_sum>
          <tax>1</tax>
        </item>
      </items>
      <coupon>
        <coupon_id>1</coupon_id>
        <total>10.00</total>
        <code>ABCDEFG</code>
        <comment>Neukunde</comment>
      </coupon>
    </order>
  </orders>
</result>
',
                       'protocol' => 'HTTP/1.1',
                       'status' => '200',
                       'reason' => 'OK'
                      };

my $live = {
                       'url' => 'http://webservice.rakuten.de/merchants/orders/getOrders?key=123456789a123456789a123456789a12&status=pending',
                       'headers' => {
                                     'serv' => '101',
                                     'date' => 'Thu, 06 Apr 2017 08:12:44 GMT',
                                     'access-control-allow-headers' => 'Origin, X-Requested-With, Content-Type, Accept, 2',
                                     'connection' => 'keep-alive',
                                     'vary' => 'Accept-Encoding',
                                     'access-control-allow-origin' => [
                                                                       'https://www.rakuten.de',
                                                                       'http://www.rakuten.de'
                                                                      ],
                                     'content-length' => '2177',
                                     'p3p' => 'CP="CURa ADMa DEVa PSAo PSDo OUR BUS UNI PUR INT DEM STA PRE COM NAV OTC NOI DSP COR"',
                                     'hamster' => '225',
                                     'server' => 'nginx',
                                     'content-type' => 'text/xml; charset=utf-8'
                                    },
                       'success' => 1,
                                 'content' => '<?xml version="1.0" encoding="utf-8"?>
<result>
  <success>1</success>
  <orders>
    <paging>
      <total>1</total>
      <page>1</page>
      <pages>1</pages>
      <per_page>20</per_page>
    </paging>
    <order>
      <order_no>123-456-789</order_no>
      <total>12.12</total>
      <shipping>3.50</shipping>
      <max_shipping_date>2010-01-01 20:15:00</max_shipping_date>
      <payment>CC</payment>
      <status>pending</status>
      <invoice_no>123456</invoice_no>
      <comment_client>Ich freu mich so sehr!</comment_client>
      <comment_merchant>Beim Lieferanten bestellt</comment_merchant>
      <created>2010-01-01 20:15:00</created>
      <client>
        <client_id>1</client_id>
        <gender>Herr</gender>
        <first_name>Max</first_name>
        <last_name>Mustermann</last_name>
        <company>Muster GmbH</company>
        <street>Musterstraße</street>
        <street_no>1</street_no>
        <address_add>Seiteneingang</address_add>
        <zip_code>11111</zip_code>
        <city>Musterstadt</city>
        <country>DE</country>
        <email>max@mustermann.de</email>
        <phone>123456-4555</phone>
      </client>
      <delivery_address>
        <gender>Herr</gender>
        <first_name>Max</first_name>
        <last_name>Mustermann</last_name>
        <company>Muster GmbH</company>
        <street>Musterstraße</street>
        <street_no>1</street_no>
        <address_add>Seiteneingang</address_add>
        <zip_code>11111</zip_code>
        <city>Musterstadt</city>
        <country>DE</country>
      </delivery_address>
      <items>
        <item>
          <item_id>1</item_id>
          <product_id>1</product_id>
          <variant_id>5</variant_id>
          <product_art_no>ART-99</product_art_no>
          <name>Musterprodukt</name>
          <name_add>Grün</name_add>
          <qty>2</qty>
          <price>10.00</price>
          <price_sum>20.00</price_sum>
          <tax>1</tax>
        </item>
        <item>
          <item_id>2</item_id>
          <product_id>2</product_id>
          <variant_id>6</variant_id>
          <product_art_no>ART-98</product_art_no>
          <name>Musterprodukt2</name>
          <name_add>Grün2</name_add>
          <qty>3</qty>
          <price>10.00</price>
          <price_sum>30.00</price_sum>
          <tax>1</tax>
        </item>
      </items>
      <coupon>
        <coupon_id>1</coupon_id>
        <total>10.00</total>
        <code>ABCDEFG</code>
        <comment>Neukunde</comment>
      </coupon>
    </order>
  </orders>
</result>
',
                       'protocol' => 'HTTP/1.1',
                       'status' => '200',
                       'reason' => 'OK'            
           };

foreach my $res ($sandbox, $live) {
    diag "Checking XML parsing";
    my $obj = Marketplace::Rakuten::Response->new(%$res);
    ok $obj->data->{orders}->{order}->[0]->{items};
    my @orders = Marketplace::Rakuten->_parse_orders($obj->data);
    foreach my $order (@orders) {
        ok $order->number_of_items, "Order has ".  $order->number_of_items . ' items';
        my @items = $order->items;
        ok (@items > 0, "Found " . scalar(@items) . " orderlines");
        foreach my $i (@items) {
            ok $i->quantity, "Item has quantity" or diag Dumper($i);
            ok $i->sku, "Item has sku";
        }
    }
}

