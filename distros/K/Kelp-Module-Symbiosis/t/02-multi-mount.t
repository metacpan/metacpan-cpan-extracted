use strict;
use warnings;

use Test::More;
use Kelp::Test;
use HTTP::Request::Common;
use Kelp::Module::Symbiosis::Test;
use File::Basename;
use lib dirname(__FILE__) . '/lib';
use TestApp;

my $app = Kelp::Module::Symbiosis::Test->new(app => TestApp->new);
my $t = Kelp::Test->new(app => $app);

$t->request(GET "/home")
	->code_is(200)
	->content_is("this is home");

$t->request(GET "/test")
	->code_is(200)
	->content_is("mounted1");

$t->request(GET "/test2")
	->code_is(200)
	->content_is("mounted2");

$t->request(GET "/test/wt")
	->code_is(200)
	->content_is("mounted1");

$t->request(GET "/test/test")
	->code_is(200)
	->content_is("mounted3");

$t->request(GET "/test/test/test")
	->code_is(200)
	->content_is("mounted3");

$t->request(GET "/home/test")
	->code_is(404);

done_testing;

