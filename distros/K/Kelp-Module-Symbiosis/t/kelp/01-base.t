use strict;
use warnings;

use Test::More;
use HTTP::Request::Common;
use KelpX::Symbiosis::Test;
use lib 't/lib';

# Kelp module being tested
{

	package Symbiosis::Test;

	use Kelp::Base 'Kelp';

	sub build
	{
		my $self = shift;
		$self->load_module("+TestSymbiont", middleware => [qw(ContentMD5)]);

		$self->symbiosis->mount('/test', $self->testmod);
		$self->symbiosis->mount([GET => qr{^/test2(?:/.+)?$}], $self->testmod);

		$self->add_route("/testkelp" => sub {
			"kelp";
		});
	}

	1;
}

my $app = Symbiosis::Test->new(mode => 'just_kelp');
can_ok $app, qw(symbiosis run_all testmod);
is $app->symbiosis->reverse_proxy, 0, 'reverse proxy status ok';

my $symbiosis = $app->symbiosis;
can_ok $symbiosis, qw(loaded mounted run mount);

my $mounted = $symbiosis->mounted;
is scalar keys %$mounted, 2, "mounted count ok";
isa_ok $mounted->{'/test'}, "TestSymbiont";

my $loaded = $symbiosis->loaded;
is scalar keys %$loaded, 1, "loaded count ok";
isa_ok $loaded->{"symbiont"}, "TestSymbiont";

my $t = KelpX::Symbiosis::Test->wrap(app => $app);

$t->request(GET "/")
	->code_is(404);

$t->request(GET "/testkelp")
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

$t->request(GET "/test2")
	->code_is(200)
	->header_is("Content-MD5", "81c4e3af4002170ab76fe2e53488b6a4")
	->content_is("mounted");

$t->request(GET "/test2/test")
	->code_is(200)
	->header_is("Content-MD5", "81c4e3af4002170ab76fe2e53488b6a4")
	->content_is("mounted");

done_testing;

