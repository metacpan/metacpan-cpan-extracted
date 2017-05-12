use strict;
use warnings;
use Test::More tests => 2;
use YAML;
use HTTPx::Dispatcher;
use HTTP::Request;
use Test::Requires 'Plack::Request';

{
    package MyDispatcher;
    use HTTPx::Dispatcher;
    connect '', { controller => 'Root', action => 'index' };
    connect '/blog/{year}/{month}/{day}', { controller => 'Blog', action => 'show' };
}

do {
    my $req = Plack::Request->new({PATH_INFO => '/'});
    my $x = MyDispatcher->match($req);
    is_deeply $x,
      {
        'controller' => 'Root',
        'args'       => {},
        'action'     => 'index'
      };
};

do {
    my $req = Plack::Request->new({PATH_INFO => '/blog/2009/11/14'});
    my $x = MyDispatcher->match($req);
    is_deeply $x,
      {
        'controller' => 'Blog',
        'args'       => {
            'month' => '11',
            'day'   => '14',
            'year'  => '2009'
        },
        'action' => 'show'
      };
};

