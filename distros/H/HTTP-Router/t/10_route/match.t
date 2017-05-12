use Test::Base;
use Test::Deep;
use t::Router;
use HTTP::Router::Route;

plan tests => 2 * blocks;

filters { map { $_ => ['eval'] } qw(params request) };

run {
    my $block = shift;
    my $name  = $block->name;
    my $route = HTTP::Router::Route->new(
        path   => $block->path,
        params => $block->params,
    );

    my $req = create_request($block->request);
    my $match = $route->match($req);
    ok $match, "match ($name)";
    cmp_deeply $match->params => $block->params, "params ($name)";
};

__END__
=== /
--- path  : /
--- params: { controller => 'Root', action => 'index' }
--- request: { path => '/' }

=== /account/login
--- path  : /account/login
--- params: { controller => 'Account', action => 'login' }
--- request: { path => '/account/login' }
