use strict;
use warnings;

use Test::More;
use HTTP::Request::Common;
use KelpX::Symbiosis::Test;
use lib 't/lib';

# Kelp module being tested
{

	package Symbiosis::Static::Test;

	use Kelp::Base 'Kelp';
	use Plack::App::File;
	use Plack::Middleware::AccessLog;
	use Path::Tiny;

	sub build
	{
		my $self = shift;

		my $dumper_app = sub {
			my $env = shift;
			return [
				200,
				['Content-Type' => 'text/plain'],
				[
					'script: ' . $env->{SCRIPT_NAME} . "\n",
					'path: ' . $env->{PATH_INFO} . "\n",
				],
			];
		};

		$self->symbiosis->mount('/path', $dumper_app);
		$self->symbiosis->mount('/script', $dumper_app);
	}

	1;
}

my $app = Symbiosis::Static::Test->new(mode => 'just_kelp');
my $t = KelpX::Symbiosis::Test->wrap(app => $app);

# NOTE: trailing slashes are preserved

$t->request(GET "/pat")
	->code_is(404);

$t->request(GET "/path")
	->code_is(200)
	->content_like(qr{script: /path$}m)
	->content_like(qr{path: $}m);

$t->request(GET "/path/")
	->code_is(200)
	->content_like(qr{script: /path$}m)
	->content_like(qr{path: /$}m);

$t->request(GET "/path/a")
	->code_is(200)
	->content_like(qr{script: /path$}m)
	->content_like(qr{path: /a$}m);

$t->request(GET "/path/a/")
	->code_is(200)
	->content_like(qr{script: /path$}m)
	->content_like(qr{path: /a/$}m);

$t->request(GET "/path/a/b")
	->code_is(200)
	->content_like(qr{script: /path$}m)
	->content_like(qr{path: /a/b$}m);

$t->request(GET "/path/a/b/")
	->code_is(200)
	->content_like(qr{script: /path$}m)
	->content_like(qr{path: /a/b/$}m);

done_testing;

