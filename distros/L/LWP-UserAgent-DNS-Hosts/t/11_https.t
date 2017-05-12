use strict;
use Test::More;
use Test::Fake::HTTPD 0.08;
use LWP::UserAgent;
use LWP::UserAgent::DNS::Hosts;

# server
plan skip_all => "disable SSL" unless Test::Fake::HTTPD::enable_ssl();

# client
for my $module (qw/ LWP::Protocol::https IO::Socket::SSL /) {
    plan skip_all => "$module required" unless eval "use $module; 1";
}

sub _uri {
    my ($uri, $httpd) = @_;
    $uri = URI->new($uri);
    $uri->port($httpd->port);
    $uri->as_string;
}

# need SSL options
my $ua = LWP::UserAgent->new(
    ssl_opts => { SSL_verify_mode => 0, verify_hostname => 0 },
);

# need SSL options for HTTP::Daemon::SSL
extra_daemon_args
    SSL_key_file  => 'certs/server-key.pem',
    SSL_cert_file => 'certs/server-cert.pem';

my $httpd = run_https_server {
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

    my $res = $ua->get( _uri('https://www.google.com/search?q=foobar', $httpd) );
    is $res->content => 'quux';
    is $res->header('X-FooBar') => 'foobar';
};

subtest '.register_hosts' => sub {
    my @hosts = qw( www.example.com  www.example.co.jp );
    LWP::UserAgent::DNS::Hosts->register_hosts(
        map { $_ => '127.0.0.1' } @hosts
    );

    for my $host (@hosts) {
        my $res = $ua->get( _uri("https://$host/search?q=baz", $httpd) );
        is $res->content => 'quux';
    }
};

subtest '.clear_hosts' => sub {
    LWP::UserAgent::DNS::Hosts->clear_hosts;

    my $res = $ua->get('https://www.example.com/');
    isnt $res->content => 'quux';
    isnt $res->header('X-FooBar') => 'foobar';
};

done_testing;
