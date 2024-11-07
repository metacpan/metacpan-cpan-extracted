package TestCode;

use Mojo::Base qw(Mojolicious -signatures);
use MFab::Plugins::Datadog qw(startSpan endSpan);

sub startup ($self) {
	$self->config("hypnotoad" => {
		listen => [ "http://*:4301" ],
		pid_file => "/tmp/hypnotoad.pid"
	});

	push(@{ $self->plugins->namespaces }, 'MFab::Plugins');

	$self->plugin("Datadog");

	my $routes = $self->routes;
	$routes->get("/")->to(cb => sub ($c) {
		$c->render(text => "this is an endpoint\n");
	});
	$routes->get("/restart")->to(cb => sub ($c) {
		$c->render(text => "restarting\n");
		system("pkill -HUP -F/tmp/hypnotoad.pid");
	});
	$routes->get("/some/specific/route/:id")->to(cb => sub ($c) {
		my $id = $c->param("id");
		$c->render(text => "this is a specific route for $id\n");
	});
	$routes->get("/sleep10")->to(cb => sub ($c) {
		sleep(10);
		$c->render(text => "slept 10 seconds\n");
	});
	$routes->get("/sleep10-async")->to(cb => sub ($c) {
		$c->render_later;
		Mojo::IOLoop->timer(10 => sub {
			$c->render(text => "slept 10 seconds (async)\n");
		});
	});
	$routes->get("/loopget")->to(cb => sub ($c) {
		$c->app->ua->get("http://localhost:4301/" => sub ($ua, $tx) {
			$c->render(text => $tx->res->body);
		});
	});
	$routes->get("/recurse-sleep")->to(cb => sub ($c) {
                my $url = "http://localhost:4301/sleep10-async";
                my $span = startSpan($c->tx, "subrequest", $url);
		$c->app->ua->get($url => sub ($ua, $tx) {
			$c->render(text => $tx->res->body);
                        endSpan($span);
		});
	});
}

1;
