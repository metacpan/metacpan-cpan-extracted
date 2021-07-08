use strict;
use warnings;

use Test::More;
use HTTP::Request::Common;
use KelpX::Symbiosis::Test;
use lib 't/lib';

# Kelp module being tested
{

	package Symbiosis::Test;

	use Kelp::Less;

	module "Symbiosis", mount => undef, middleware => [qw(ContentMD5)];
	module "+TestSymbiont", middleware => [qw(ContentLength)];

	app->symbiosis->mount("/kelp", app);
	app->symbiosis->mount("/test", app->testmod);

	route "/test" => sub {
		"kelp";
	};

	sub get_app
	{
		return app;
	}

	1;
}

my $app = Symbiosis::Test::get_app;
my $t = KelpX::Symbiosis::Test->wrap(app => $app);

$t->request(GET "/kelp/test")
	->code_is(200)
	->header_is("Content-MD5", "c40c69779e15780adae46c45eb451e23")
	->header_isnt("Content-Length", "4")
	->content_is("kelp");

$t->request(GET "/test")
	->code_is(200)
	->header_is("Content-MD5", "81c4e3af4002170ab76fe2e53488b6a4")
	->header_is("Content-Length", "7")
	->content_is("mounted");

done_testing;
