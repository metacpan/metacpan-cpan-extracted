package Mock::Webserver;

use Mojo::Base qw(Mojolicious -signatures);

sub startup ($self) {
    push(@{ $self->plugins->namespaces }, 'MFab::Plugins');

    $self->plugin("Datadog", {
	    enabled => "true",
    });

    my $routes = $self->routes;
    $routes->get("/")->to(cb => sub ($c) {
	    $c->render(text => "this is an endpoint\n");
    });
}

1;
