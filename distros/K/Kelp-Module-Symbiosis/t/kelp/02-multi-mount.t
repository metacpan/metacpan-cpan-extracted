use strict;
use warnings;

use Test::More;
use HTTP::Request::Common;
use KelpX::Symbiosis::Test;
use lib 't/lib';
use TestApp;

my $app = TestApp->new(mode => 'mostly_mounted');
$app->build_from_methods;
my $t = KelpX::Symbiosis::Test->wrap(app => $app);

my $loaded = $app->symbiosis->loaded;
is scalar keys %$loaded, 2, "loaded count ok";
isa_ok $loaded->{"symbiont"}, "TestSymbiont";
isa_ok $loaded->{"AnotherTestSymbiont"}, "AnotherTestSymbiont";

$t->request(GET "/home")
	->code_is(200)
	->content_is("this is home");

$t->request(GET "/test")
	->code_is(200)
	->content_is("mounted");

$t->request(GET "/test/test2")
	->code_is(200)
	->content_is("also mounted");

$t->request(GET "/test/wt")
	->code_is(200)
	->content_is("mounted");

$t->request(GET "/")
	->code_is(404);

done_testing;

