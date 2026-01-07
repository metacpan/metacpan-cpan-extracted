use v5.40;
use Test2::V1 -ipP;
use Gears::App;
use Gears::Context;
use Gears::Config;

use lib 't/lib';
use Gears::Test::Router;

################################################################################
# This tests whether App / Controller / Context work
################################################################################

my $router = Gears::Test::Router->new(location_impl => 'Gears::Router::Location::Match');
my $app;

subtest 'app should be built' => sub {
	my $config = Gears::Config->new;
	$app = My::Gears::App->new(router => $router, config => $config);

	is $app->router, exact_ref $router, 'router ok';
	is $app->config, exact_ref $config, 'config ok';
	is $app->{build}, 'app built', 'build method ok';
};

subtest 'should add controllers to an app' => sub {
	$app->load_controller('C1')
		->load_controller('C11')
		->load_controller('^C2')
		;

	isa_ok $app->controllers->[0], ['My::Gears::App::Controller::C1'], 'first controller ok';
	is $app->controllers->[0]->{build}, 'controller built', 'built ok';
	is $app->controllers->[0]->app, exact_ref $app, 'app ok';

	isa_ok $app->controllers->[1], ['My::Gears::App::Controller::C11'], 'second controller ok';
	is $app->controllers->[1]->{build}, undef, 'not built without build method ok';

	isa_ok $app->controllers->[2], ['C2'], 'third controller ok';
	is $app->controllers->[2]->{build}, undef, 'not built at all ok';
};

subtest 'should create context' => sub {
	my $ctx = Gears::Context->new(app => $app);
	is $ctx->app, exact_ref $app, 'context app ok';
};

done_testing;

package My::Gears::App {
	use parent 'Gears::App';

	sub build ($self)
	{
		$self->{build} = 'app built';
	}
}

package My::Gears::App::Controller::C1 {
	use parent 'Gears::Controller';

	sub build ($self)
	{
		$self->{build} = 'controller built';
	}
}

package My::Gears::App::Controller::C11 {
	use parent -norequire, 'My::Gears::App::Controller::C1';

	# no explicit build method - parent method should not be called
}

package C2 {
	use parent 'Gears::Controller';
}

