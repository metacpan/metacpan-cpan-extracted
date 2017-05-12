# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as
# `perl Filter-BoxString.t'

#########################

use Test::More tests => 2;

BEGIN {

    use_ok('Filter::BoxString');
}

TEST:
{
    my $xml = eval {

        my $xml = +---------------------------------------+
                  |<?xml version="1.0" encoding="UTF-8"?>
                  |  <item>Milk</item>
                  |  <item>Eggs</item>
                  |  <item>Apples</item>
                  |</shopping_list>
                  +---------------------------------------+;
    };

    my $expected_xml
        = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        . "  <item>Milk</item>\n"
        . "  <item>Eggs</item>\n"
        . "  <item>Apples</item>\n"
        . "</shopping_list>\n";

    is( $xml, $expected_xml, 'xml content' );
}

