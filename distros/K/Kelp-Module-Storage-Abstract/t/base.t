use Test2::V0;
use Kelp;
use Kelp::Test;
use HTTP::Request::Common;

################################################################################
# This tests whether the module works
################################################################################

my $app = Kelp->new(mode => 'test');
my $t = Kelp::Test->new(app => $app);

$app->add_route(
	'/stored_file' => {
		to => sub {
			my ($self) = @_;
			$self->res->render_file('f1');
		}
	}
);

subtest 'should be usable from app object' => sub {
	ok $app->can('storage'), 'app can invoke storage ok';
	isa_ok $app->storage, 'Storage::Abstract';

	$app->storage->store('f1', \'test1');
	$app->storage->store('public/f2', \'test2');
	$app->storage->store('public/f3/f3', \'test3');

	is $app->url_for(storage_publicurl => file => 'f3/f3'), '/publicurl/f3/f3', 'url building ok';
};

subtest 'should not be accessible from direct urls' => sub {
	$t->request(GET '/f1')
		->code_is(404);

	$t->request(GET '/f2')
		->code_is(404);

	$t->request(GET '/f3/f3')
		->code_is(404);
};

subtest 'should be accessible from public urls' => sub {
	$t->request(GET '/publicurl/f1')
		->code_is(404);

	$t->request(GET '/publicurl/f2')
		->code_is(200)
		->header_like('Content-Type', qr{text/plain})
		->header_is('Content-Length', 5)
		->content_is('test2');

	$t->request(GET '/publicurl/f3/f3')
		->code_is(200)
		->header_like('Content-Type', qr{text/plain})
		->header_is('Content-Length', 5)
		->content_is('test3');
};

subtest 'should allow rendering files' => sub {
	$t->request(GET '/stored_file')
		->code_is(200)
		->header_like('Content-Type', qr{text/plain})
		->header_is('Content-Length', 5)
		->content_is('test1');
};

done_testing;

