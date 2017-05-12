use strict;
use Test::More tests => 1;

BEGIN { use_ok 'HTML::TreeBuilder::LibXML' }
require HTML::TreeBuilder::XPath;

diag "soft dependencies";
diag "HTML::TreeBuilder::XPath: $HTML::TreeBuilder::XPath::VERSION";

