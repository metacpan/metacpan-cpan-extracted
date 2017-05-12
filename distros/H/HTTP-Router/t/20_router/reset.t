use Test::More tests => 3;
use HTTP::Router;
use HTTP::Router::Route;

my $r = HTTP::Router->new;
is @{[ $r->routes ]} => 0;

for my $i (1..10) {
    my $route = HTTP::Router::Route->new(path => $i);
    $r->add_route($route);
}
is @{[ $r->routes ]} => 10;

$r->reset;
is @{[ $r->routes ]} => 0;
