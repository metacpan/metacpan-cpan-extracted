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

	attr file => sub { Plack::App::File->new(root => path(__FILE__)->parent->parent->child('static')) };

	sub wrap_static
	{
		my $self = shift;
		my $static = $self->file->to_app;

		return sub {
			my $env = shift;
			if ($env->{PATH_INFO} =~ m{^/?$}) {
				return [200, ['Content-Type' => 'text/plain'], ["I'm a static app"]];
			}

			return $static->($env);
		};
	}

	sub build
	{
		my $self = shift;

		$self->symbiosis->mount('/static', $self->wrap_static);
	}

	1;
}

my $app = Symbiosis::Static::Test->new(mode => 'just_kelp');
my $t = KelpX::Symbiosis::Test->wrap(app => $app);

$t->request(GET "/")
	->code_is(404);

$t->request(GET "/static")
	->code_is(200)
	->content_is("I'm a static app");

$t->request(GET "/static/")
	->code_is(200)
	->content_is("I'm a static app");

$t->request(GET "/static/f")
	->code_is(404);

$t->request(GET "/static/file1")
	->code_is(200)
	->content_like(qr/^hello world$/);

# not matching because of the trailing slash - preserved by default
$t->request(GET "/static/file1/")
	->code_is(404);

$t->request(GET "/static/files/file2")
	->code_is(200)
	->content_like(qr/^hello file2$/);

done_testing;

