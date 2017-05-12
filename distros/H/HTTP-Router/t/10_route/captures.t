use Test::Base;
use Test::Deep;
use t::Router;
use HTTP::Router::Route;

plan tests => 2 * blocks;

filters { map { $_ => ['eval'] } qw(params match request) };

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
    cmp_deeply $match->params => $block->match, "params ($name)";
};

__END__
=== /archives/{year}
--- path    : /archives/{year}
--- params  : { controller => 'Archive', action => 'by_year' }
--- request : { path => '/archives/2008' }
--- match   : { controller => 'Archive', action => 'by_year', year => 2008 }

=== /archives/{year}/{month}
--- path    : /archives/{year}/{month}
--- params  : { controller => 'Archive', action => 'by_month' }
--- request : { path => '/archives/2008/12' }
--- match   : { controller => 'Archive', action => 'by_month', year => 2008, month => 12 }
