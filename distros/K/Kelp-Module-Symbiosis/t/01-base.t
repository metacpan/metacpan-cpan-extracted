use strict;
use warnings;

use Test::More;
use Kelp::Test;
use HTTP::Request::Common;
use Kelp::Module::Symbiosis::Test;
use File::Basename;
use lib dirname(__FILE__) . '/lib';

# Kelp module being tested
{

	package Symbiosis::Test;

	use Kelp::Less config_module => 'Kelp::Module::Config::Null';

	module "Symbiosis", automount => 0;
	module "+TestSymbiont", middleware => [qw(ContentMD5)];

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
can_ok $app, "symbiosis", "run_all";

my $mounted = $app->symbiosis->mounted;
ok exists $mounted->{"/kelp"}, "something was mounted";
isa_ok $mounted->{"/kelp"}, "Kelp";

my $t = Kelp::Test->new(app => Kelp::Module::Symbiosis::Test->new(app => $app));

$t->request(GET "/kelp/test")
	->code_is(200)
	->content_is("kelp");

$t->request(GET "/test")
	->code_is(200)
	->header_is("Content-MD5", "d7a414cac18f91e2de29b206f0ac1c21")
	->content_is("mounted1");

$t->request(GET "/test/test")
	->code_is(200)
	->header_is("Content-MD5", "d7a414cac18f91e2de29b206f0ac1c21")
	->content_is("mounted1");

$t->request(GET "/kelp/kelp")
	->code_is(404);

done_testing;
