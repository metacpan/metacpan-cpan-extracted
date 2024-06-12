use strict;
use warnings;

use Test::More;
use KelpX::Symbiosis::Test;
use HTTP::Request::Common;
use Kelp::Test;

{

	package Less::Test;

	use Kelp::Less;
	use Plack::Response;

	module 'Symbiosis';

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

my $t = KelpX::Symbiosis::Test->wrap(app => Less::Test::get_app);

$t->request(GET "/")
	->code_is(200)
	->content_is("kelp");

$t->request(GET "/test")
	->code_is(200)
	->content_is("mounted");

$t->request(GET "/ke")
	->code_is(404);

done_testing;

