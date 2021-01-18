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

	module "Symbiosis", mount => undef;
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
can_ok $app, qw(symbiosis run_all testmod);

my $symbiosis = $app->symbiosis;
can_ok $symbiosis, qw(loaded mounted run mount);

my $mounted = $symbiosis->mounted;
is scalar keys %$mounted, 2, "mounted count ok";
isa_ok $mounted->{"/kelp"}, "Kelp";
isa_ok $mounted->{"/test"}, "TestSymbiont";

my $loaded = $symbiosis->loaded;
is scalar keys %$loaded, 1, "loaded count ok";
isa_ok $loaded->{"symbiont"}, "TestSymbiont";

my $t = KelpX::Symbiosis::Test->wrap(app => $app);

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
