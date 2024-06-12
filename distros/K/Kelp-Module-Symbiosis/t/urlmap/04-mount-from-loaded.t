use strict;
use warnings;

use Test::More;
use HTTP::Request::Common;
use KelpX::Symbiosis::Test;
use lib 't/lib';
use TestApp;

my $app = TestApp->new(mode => 'none_mounted');
my $t = KelpX::Symbiosis::Test->wrap(app => $app);
$app->build_from_loaded;

$t->request(GET "/s/home")
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

$t->request(GET "/s")
	->code_is(404);

done_testing;

