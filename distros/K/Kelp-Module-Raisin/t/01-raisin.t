use strict;
use warnings;

use Test::More;
use KelpX::Symbiosis::Test;
use HTTP::Request::Common;
use lib 't/lib';
use KelpApp;
use RaisinApp;

my $app = KelpApp->new(mode => 'base');
my $t = KelpX::Symbiosis::Test->wrap(app => $app);

isa_ok $app->symbiosis->loaded->{raisin}, 'Kelp::Module::Raisin';
isa_ok $app->raisin, 'Raisin';

$t->request(GET "/home")
	->code_is(200)
	->content_is("Hello World from Kelp!");

$t->request(GET "/api/test/ttt")
	->code_is(200)
	->content_is('["Hello World from Raisin!"]');

$t->request(GET "/api/from-kelp")
	->code_is(200)
	->content_is('["Hello World from Kelp, in Raisin!"]');

$t->request(GET "/should/not/exist")
	->code_is(404);

$t->request(GET "/api/should/not/exist")
	->code_is(404);

done_testing;
