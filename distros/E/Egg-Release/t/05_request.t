use Test::More tests=> 96;
use lib qw( ../lib ./lib );
use Egg::Helper;

$ENV{HTTP_HOST}  = 'localhost';
$ENV{HTTP_COOKIE}= 'test1=ok1; test2=ok2';

my $e= Egg::Helper->run('Vtest', { character_in=> 'euc' });

can_ok $e, 'mp_version';
  ok defined($Egg::Request::MP_VERSION), q{defined($Egg::Request::MP_VERSION)};
  is $e->mp_version, $Egg::Request::MP_VERSION, q{$e->mp_version, $Egg::Request::MP_VERSION};
  is $e->mp_version, 0, q{$e->mp_version, 0};

is $e->global->{request_class}, 'Egg::Request::CGI',
   q{$e->global->{request_class}, 'Egg::Request::CGI'};

can_ok $e, 'handler';

can_ok $e, 'request';
  ok my $req= $e->request, q{my $req= $e->request};
  isa_ok $req, 'Egg::Request::CGI';
  isa_ok $req, 'Egg::Request::handler';
  isa_ok $req, 'Egg::Base';
  can_ok $e, 'req';
  is $req, $e->req, q{$req, $e->req};

can_ok $req, 'r';
  isa_ok $req->r, 'CGI';

can_ok $req, 'is_get';
can_ok $req, 'is_post';
can_ok $req, 'is_head';
  is $req->is_get,  1, q{$req->is_get,  1};
  is $req->is_post, 0, q{$req->is_post, 0};
  is $req->is_head, 0, q{$req->is_head, 0};

can_ok $req, 'path';
  is $req->path, '/', q{$req->path, '/'};

can_ok $req, 'snip';
  isa_ok $req->snip, 'ARRAY';
  is scalar(@{$req->snip}), 0, q{scalar(@{$req->snip})};

can_ok $req, 'parameters';
  isa_ok $req->parameters, 'HASH';
  ok $req->can('params'), q{$req->can('params')};
  is $req->params, $req->parameters, '$req->params, $req->parameters';
  can_ok $req, 'param';
  ok $req->param( foo => 'baa' ), q{$req->param( foo => 'baa' )};
  is $req->param('foo'), 'baa', q{$req->param('foo'), 'baa'};
  is $req->param('foo'), $req->params->{foo}, q{$req->param('foo'), $req->params->{foo}};
  delete($req->params->{foo});
  ok ! $req->param('foo'), q{! $req->param('foo')};

can_ok $req, 'cookies';
  can_ok $req, 'cookie';
  can_ok $req, 'cookie_value';
  ok my $cookie= $req->cookies, q{my $cookie= $req->cookies};
  isa_ok $cookie, 'HASH';
  ok $cookie->{test1}, q{$cookie->{test1}};
  is $cookie->{test1}->value, 'ok1', q{$cookie->{test1}->value, 'ok1'};
  is $cookie->{test1}->value, $req->cookie('test1')->value,
     q{$cookie->{test1}->value, $req->cookie('test1')->value};
  is $cookie->{test1}->value, $req->cookie_value('test1'),
     q{$cookie->{test1}->value, $req->cookie_value('test1')};
  ok $cookie->{test2}, q{$cookie->{test2}};
  is $cookie->{test2}->value, 'ok2', q{$cookie->{test2}->value, 'ok2'};
  is $cookie->{test2}->value, $req->cookie('test2')->value,
     q{$cookie->{test2}->value, $req->cookie('test2')->value};
  is $cookie->{test2}->value, $req->cookie_value('test2'),
     q{$cookie->{test2}->value, $req->cookie_value('test2')};

  can_ok $req, 'cookie_more';
  ok $req->cookie_more( test3=> 'test_ok' ), q{$req->cookie_more( test3 => 'test_ok' )};
  ok $cookie->{test3}, q{$cookie->{test3}};
  is $cookie->{test3}->value, 'test_ok', q{$cookie->{test3}->value, 'test_ok'};
  is $cookie->{test3}->value, $req->cookie_value('test3'),
     q{$cookie->{test3}->value, $req->cookie_value('test3')};

can_ok $req, 'scheme';
  is $req->scheme, 'http', q{$req->scheme, 'http'};

can_ok $req, 'uri';
  is $req->uri, "http://$ENV{HTTP_HOST}/", q{$req->uri, "http://$ENV{HTTP_HOST}/"};

can_ok $req, 'host_name';
  is $req->host_name, $ENV{HTTP_HOST}, q{$req->host_name, $ENV{HTTP_HOST}};

can_ok $req, 'remote_host';
can_ok $req, 'secure';
can_ok $req, 'output';
can_ok $req, 'result';
can_ok $req, 'remote_user';
can_ok $req, 'script_name';
can_ok $req, 'request_uri';
can_ok $req, 'path_info';
can_ok $req, 'args';

can_ok $req, 'http_accept_encoding';
  can_ok $req, 'accept_encoding';

can_ok $req, 'http_referer';
  can_ok $req, 'referer';

can_ok $req, 'remote_addr';
  can_ok $req, 'addr';
  is $req->remote_addr, $req->addr, q{$req->remote_addr, $req->addr};
  is $req->addr, '127.0.0.1', q{$req->addr, '127.0.0.1'};

can_ok $req, 'request_method';
  can_ok $req, 'method';
  is $req->request_method, $req->method, q{$req->request_method, $req->method};
  is $req->method, 'GET', q{$req->method, 'GET'};

can_ok $req, 'server_name';
  is $req->server_name, 'localhost', q{$req->server_name, 'localhost'};

can_ok $req, 'server_software';
  is $req->server_software, 'cmdline', q{$req->server_software, 'cmdline'};

can_ok $req, 'server_protocol';
  can_ok $req, 'protocol';
  is $req->server_protocol, $req->protocol, q{$req->server_protocol, $req->protocol};
  is $req->protocol, 'HTTP/1.1', q{$req->protocol, 'HTTP/1.1'};

can_ok $req, 'http_user_agent';
  can_ok $req, 'agent';
  is $req->http_user_agent, $req->agent, q{$req->http_user_agent, $req->agent};
  is $req->agent, 'local', q{$req->agent, 'local'};

can_ok $req, 'server_port';
  can_ok $req, 'port';
  is $req->server_port, $req->port, q{$req->server_port, $req->port};
  is $req->port, 80, q{$req->port, 80};

