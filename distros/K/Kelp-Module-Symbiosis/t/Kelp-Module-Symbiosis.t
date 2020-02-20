use strict;
use warnings;

use Test::More;
use Kelp::Test;
use HTTP::Request::Common;
use Kelp::Module::Symbiosis::Test;

# Some module that can be served by Plack via run()
# extending Symbiosis::Base
{
	package TestModule;
	use Kelp::Base qw(Kelp::Module::Symbiosis::Base);
	use Plack::Response;

	sub psgi
	{
		return sub {
			my $res = Plack::Response->new(200);
			$res->body("mounted");
			return $res->finalize;
		};
	}
}

# Kelp module being tested
{
	package Symbiosis::Test;

	use Kelp::Less;

	module "Symbiosis", automount => 0;
	app->symbiosis->mount("/kelp", app);
	my $module = TestModule->new(app => app);
	$module->build(middleware => [qw(ContentMD5)]);
	app->symbiosis->mount("/test", $module);

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
	->header_is("Content-MD5", "81c4e3af4002170ab76fe2e53488b6a4")
	->content_is("mounted");

$t->request(GET "/test/test")
	->code_is(200)
	->header_is("Content-MD5", "81c4e3af4002170ab76fe2e53488b6a4")
	->content_is("mounted");

$t->request(GET "/kelp/kelp")
	->code_is(404);

done_testing;
