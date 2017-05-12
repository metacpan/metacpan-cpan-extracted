use strict;
use Test::More;
use Test::Fake::HTTPD;
use LWP::UserAgent;
use LWP::UserAgent::DNS::Hosts;

sub _uri {
    my ($uri, $httpd) = @_;
    $uri = URI->new($uri);
    $uri->port($httpd->port);
    $uri->as_string;
}

my $ua = LWP::UserAgent->new;

my $httpd = run_http_server {
    my $req = shift;
    return [
        200,
        [
            'Content-Type' => 'text/plain',
            'X-FooBar'     => 'foobar',
        ],
        [ 'quux' ],
    ];
};

my $guard = LWP::UserAgent::DNS::Hosts->enable_override;

subtest '.register_host' => sub {
    LWP::UserAgent::DNS::Hosts->register_host('www.google.com' => '127.0.0.1');

    my $res = $ua->get( _uri('http://www.google.com/search?q=foobar', $httpd) );
    is $res->content => 'quux';
    is $res->header('X-FooBar') => 'foobar';
};

subtest '.register_hosts' => sub {
    my @hosts = qw( www.example.com  www.example.co.jp );
    LWP::UserAgent::DNS::Hosts->register_hosts(
        map { $_ => '127.0.0.1' } @hosts
    );

    for my $host (@hosts) {
        my $res = $ua->get( _uri("http://$host/search?q=baz", $httpd) );
        is $res->content => 'quux';
    }
};

subtest '.clear_hosts' => sub {
    LWP::UserAgent::DNS::Hosts->clear_hosts;

    my $res = $ua->get('http://www.example.com/');

    isnt $res->content => 'quux';
    isnt $res->header('X-FooBar') => 'foobar';
};

done_testing;
