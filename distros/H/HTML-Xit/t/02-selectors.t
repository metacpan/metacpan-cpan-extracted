use strict;
use warnings FATAL => 'all';

use Data::Dumper;
use Test::More;

BEGIN {
    use_ok('HTML::Xit');
}

# Since HTML::Xit relies entirely on HTML::Selector::XPath
# and XML::LibXML for its selection mechanism these tests
# are meant only to provide a basic smoke test to check that
# the wrappers around the underlying components are
# implemented correctly.

my($X);

# get new instance from test file
$X = HTML::Xit->new("t/data/test.html");
# select by tag name
is($X->("title")->text, "Lorem ipsum dolor sit amet", "select by tag name");
# select by class
is($X->(".body")->attr("id"), "body", "select by class");
# select by id
is($X->("#body")->attr("id"), "body", "select by id");
# select by tag name with attribute
is($X->("meta[name=robots]")->attr("content"), "index", "select by tag name with attribute");

done_testing();
