#!perl
use strict;
use warnings;
use Test::More;
use Plack::Handler::Hyperman;

# The handler's own logic, with run() captured rather than started: the
# listen spellings, the aliases other servers use, the warning for an option
# Hyperman does not take, the deny scalar, and --enable-ssl without files.

my %got;
{
    no warnings 'redefine';
    *Hyperman::run = sub { shift; %got = @_; return };
}
my @warned;
local $SIG{__WARN__} = sub { push @warned, $_[0] };
my $app = sub { [ 200, [], ['x'] ] };

is_deeply(Plack::Handler::Hyperman::_parse_listen({ port => 1 }), { port => 1 }, 'a hash is taken as it is');
is_deeply(Plack::Handler::Hyperman::_parse_listen('/tmp/x.sock'), { path => '/tmp/x.sock' }, 'a path is a unix socket');
is_deeply(Plack::Handler::Hyperman::_parse_listen('[::1]:8080'), { host => '::1', port => 8080 }, 'a bracketed v6 host');
is_deeply(Plack::Handler::Hyperman::_parse_listen('127.0.0.1:8080'), { host => '127.0.0.1', port => 8080 }, 'a host and port');
is_deeply(Plack::Handler::Hyperman::_parse_listen(':8080'), { port => 8080 }, 'a port with an empty host');
is_deeply(Plack::Handler::Hyperman::_parse_listen('8080'), { port => 8080 }, 'a bare port');
eval { Plack::Handler::Hyperman::_parse_listen('nonsense') };
like($@, qr/cannot parse listen spec 'nonsense'/, 'and nonsense is refused');

Plack::Handler::Hyperman->new(host => '127.0.0.1', port => 1, workers => 2)->run($app);
is($got{workers}, 2, 'workers passes');
is($got{host}, '127.0.0.1', 'and the host');
Plack::Handler::Hyperman->new(max_workers => 3)->run($app);
is($got{workers}, 3, 'max_workers is the plackup spelling of workers');
is($got{host}, '0.0.0.0', 'the host defaults');
is($got{port}, 8080, 'and the port');
Plack::Handler::Hyperman->new->run($app);
is($got{workers}, 0, 'no workers given means the core count');

Plack::Handler::Hyperman->new(ssl_cert_file => 'c.pem', ssl_key_file => 'k.pem', tls_ca => 'ca.pem')->run($app);
is($got{tls_cert}, 'c.pem', 'ssl_cert_file is tls_cert');
is($got{tls_key}, 'k.pem', 'ssl_key_file is tls_key');
Plack::Handler::Hyperman->new(ssl_cert => 'other.pem', tls_cert => 'mine.pem')->run($app);
is($got{tls_cert}, 'mine.pem', 'the Hyperman spelling wins over an alias');

@warned = ();
Plack::Handler::Hyperman->new(colour => 'blue', deny => '10.0.0.1')->run($app);
like($warned[0], qr/option 'colour' is not one Hyperman takes; ignored/, 'an unknown option warns');
is_deeply($got{deny}, ['10.0.0.1'], 'a single deny becomes a list');
Plack::Handler::Hyperman->new(deny => ['10.0.0.1', '10.0.0.2'])->run($app);
is_deeply($got{deny}, ['10.0.0.1', '10.0.0.2'], 'and a list stays one');

Plack::Handler::Hyperman->new(listen => ['127.0.0.1:81', '/tmp/h.sock'])->run($app);
is_deeply($got{listen}, [ { host => '127.0.0.1', port => 81 }, { path => '/tmp/h.sock' } ], 'listen specs are parsed');
ok(!exists $got{host}, 'and host is not sent beside them');
Plack::Handler::Hyperman->new(listen => [])->run($app);
is($got{port}, 8080, 'an empty listen list falls back to host and port');

eval { Plack::Handler::Hyperman->new(enable_ssl => 1)->run($app) };
like($@, qr/--enable-ssl needs --ssl-cert-file/, '--enable-ssl without files dies');
Plack::Handler::Hyperman->new(enable_ssl => 1, ssl_cert_file => 'c.pem', ssl_key_file => 'k.pem')->run($app);
is($got{tls_cert}, 'c.pem', 'and with the files it is simply TLS');

done_testing;
