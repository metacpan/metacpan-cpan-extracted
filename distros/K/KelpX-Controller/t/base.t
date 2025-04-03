use Kelp::Base -strict;

use Kelp;
use Kelp::Test;
use HTTP::Request::Common;
use Test::More;

use lib 't/lib';
use TestApp;

my $app = TestApp->new(mode => 'test');
my $t = Kelp::Test->new(app => $app);

subtest 'should access controller route' => sub {
	$t->request(GET '/dump')
		->code_is(200)
		->header_is('X-Framework', 'Perl Kelp')
		->header_is('X-Dispatch', 'TestApp::Controller')
		->json_cmp(
			{
				class => 'TestApp::Controller',
				app => 'TestApp',
				context => 'KelpX::Controller::Context',
				req => 'Kelp::Request',
				res => 'Kelp::Response',
				test => 1,
				extra => ['TestApp::Controller'],
			}
		);

	# try again to make sure the controller is persistent
	$t->request(GET '/dump')
		->code_is(200)
		->json_cmp(
			{
				class => 'TestApp::Controller',
				app => 'TestApp',
				context => 'KelpX::Controller::Context',
				req => 'Kelp::Request',
				res => 'Kelp::Response',
				test => 1,
				extra => ['TestApp::Controller'],
			}
		);
};

subtest 'should access controller plain subroutine route' => sub {
	$t->request(GET '/dump_sub')
		->code_is(200)
		->header_is('X-Framework', 'Perl Kelp')
		->header_is('X-Dispatch', 'TestApp::Controller')
		->json_cmp(
			{
				class => 'TestApp::Controller',
				app => 'TestApp',
				context => 'KelpX::Controller::Context',
				req => 'Kelp::Request',
				res => 'Kelp::Response',
				test => 1,
				extra => [],
			}
		);
};

subtest 'should access nested controller route' => sub {
	$t->request(GET '/dump2')
		->code_is(200)
		->header_is('X-Framework', 'Perl Kelp')
		->header_is('X-Dispatch', 'TestApp::Controller::Nested')
		->json_cmp(
			{
				class => 'TestApp::Controller::Nested',
				app => 'TestApp',
				context => 'KelpX::Controller::Context',
				req => 'Kelp::Request',
				res => 'Kelp::Response',
				test => 2,
				extra => ['TestApp::Controller::Nested'],
			}
		);
};

subtest 'should access nested controller plain subroutine route' => sub {
	$t->request(GET '/dump2_sub')
		->code_is(200)
		->header_is('X-Framework', 'Perl Kelp')
		->header_is('X-Dispatch', 'TestApp::Controller::Nested')
		->json_cmp(
			{
				class => 'TestApp::Controller::Nested',
				app => 'TestApp',
				context => 'KelpX::Controller::Context',
				req => 'Kelp::Request',
				res => 'Kelp::Response',
				test => 2,
				extra => [],
			}
		);
};

subtest 'should allow declaring routes with controller names' => sub {
	$t->request(GET '/dump3')
		->code_is(200)
		->header_is('X-Framework', 'Perl Kelp')
		->header_is('X-Dispatch', 'TestApp::Controller::Nested')
		->json_cmp(
			{
				class => 'TestApp::Controller::Nested',
				app => 'TestApp',
				context => 'KelpX::Controller::Context',
				req => 'Kelp::Request',
				res => 'Kelp::Response',
				test => 2,
				extra => ['TestApp::Controller::Nested'],
			}
		);
};

done_testing;

