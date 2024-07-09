use Kelp::Base -strict;

use Kelp;
use Kelp::Test;
use HTTP::Request::Common;
use Test::More;

use lib 't/lib';
use TestApp;

my $app = TestApp->new(mode => 'test');
my $t = Kelp::Test->new(app => $app);

$t->request(GET '/')
	->code_is(200)
	->header_is('X-Framework', 'Perl Kelp')
	->header_is('X-Dispatch', 'true')
	->json_cmp(
		{
			class => 'TestApp::Controller',
			app => 'TestApp',
			context => 'KelpX::Controller::Context',
			req => 'Kelp::Request',
			res => 'Kelp::Response',
			test => 1,
		}
	);

# try again to make sure the controller is persistent
$t->request(GET '/')
	->code_is(200)
	->json_cmp(
		{
			class => 'TestApp::Controller',
			app => 'TestApp',
			context => 'KelpX::Controller::Context',
			req => 'Kelp::Request',
			res => 'Kelp::Response',
			test => 1,
		}
	);

done_testing;

