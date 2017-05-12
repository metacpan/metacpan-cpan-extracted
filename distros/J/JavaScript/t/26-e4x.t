#!perl

use Test::More;

use strict;
use warnings;

use JavaScript;

if (JavaScript->does_support_e4x()) {
    plan tests => 2;
}
else {
    plan skip_all => "No E4X available";
}


my $runtime = new JavaScript::Runtime();
my $context = $runtime->create_context();

my $ret = $context->eval(<<'EOP');
<xml>this is an E4X object</xml>
EOP
is($ret, '<xml>this is an E4X object</xml>');

$ret = $context->eval(<<'EOP');
( <xml attr="foo">this is an E4X object</xml> ).@attr;
EOP
is($ret, 'foo');
