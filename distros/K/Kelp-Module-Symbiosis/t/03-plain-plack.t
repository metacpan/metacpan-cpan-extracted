use strict;
use warnings;

use Test::More;
use Kelp::Test;
use HTTP::Request::Common;
use Kelp::Module::Symbiosis::Test;

{

	package Plain::Test;

	use Kelp::Less config_module => 'Kelp::Module::Config::Null';
	use Plack::Response;

	module "Symbiosis", automount => 1;

	my $app = sub {
		my $res = Plack::Response->new(200);
		$res->body("mounted");
		return $res->finalize;
	};

	app->symbiosis->mount("/test", $app);

	route "/" => sub {
		"kelp";
	};

	sub get_app
	{
		return app;
	}

	1;
}

my $app = Kelp::Module::Symbiosis::Test->new(app => Plain::Test::get_app);
my $t = Kelp::Test->new(app => $app);

$t->request(GET "/")
	->code_is(200)
	->content_is("kelp");

$t->request(GET "/test")
	->code_is(200)
	->content_is("mounted");

done_testing;
