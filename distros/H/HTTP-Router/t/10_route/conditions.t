use Test::Base;
use Test::Deep;
use t::Router;
use HTTP::Router::Route;

plan tests => 2 * blocks;

filters {
    map { $_ => ['eval'] } qw(params conditions request match)
};

run {
    my $block = shift;
    my $name  = $block->name;
    my $route = HTTP::Router::Route->new(
        path       => $block->path,
        params     => $block->params,
        conditions => $block->conditions,
    );

    my $req = create_request($block->request);
    my $match = $route->match($req);
    ok $match, "match ($name)";
    cmp_deeply $match->params => $block->match, "params ($name)";
};

__END__
=== scalar conditions
--- path      : /
--- params    : { controller => 'Root', action => 'index' }
--- conditions: { method => 'GET' }
--- request   : { path => '/', method => 'GET' }
--- match     : { controller => 'Root', action => 'index' }

=== array conditions
--- path      : /
--- params    : { controller => 'Root', action => 'index' }
--- conditions: { method => ['GET', 'POST'] }
--- request   : { path => '/', method => 'GET' }
--- match     : { controller => 'Root', action => 'index' }

=== regexp conditions
--- path      : /
--- params    : { controller => 'Root', action => 'index' }
--- conditions: { method => qr/^(?:GET|POST)$/ }
--- request   : { path => '/', method => 'GET' }
--- match     : { controller => 'Root', action => 'index' }

=== captures
--- path      : /archives/{year}
--- params    : { controller => 'Archive', action => 'by_year' }
--- conditions: { year => qr/^\d{4}$/ }
--- request   : { path => '/archives/2008' }
--- match     : { controller => 'Archive', action => 'by_year', year => 2008 }

=== captures and conditions
--- path      : /archives/{year}
--- params    : { controller => 'Archive', action => 'by_year' }
--- conditions: { method => 'GET', year => qr/^\d{4}$/ }
--- request   : { path => '/archives/2008', method => 'GET' }
--- match     : { controller => 'Archive', action => 'by_year', year => 2008 }
