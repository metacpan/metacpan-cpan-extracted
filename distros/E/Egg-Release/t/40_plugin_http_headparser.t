use Test::More tests=> 23;
use lib qw( ./lib ../lib );
use Egg::Helper;

ok $e= Egg::Helper->run( Vtest=> {
  vtest_plugins=> [qw/ HTTP::HeadParser /],
  }), q{load plugin.};

my @head= $e->helper_yaml_load(join '', <DATA>);

can_ok $e, 'parse_http_header';

# request header.
ok my $req= $e->parse_http_header($head[0]),
  q{my $req= $e->parse_http_header($head[0])};
isa_ok $req, 'HASH';
is $req->{method},          'GET / HTTP/1.1',
  q{$req->{method}};
is $req->{accept},          'image/gif, image/x-xbitmap, image/jpeg, image/pjpeg, application/x-shockwave-flash, */*',
  q{$req->{accept}};
is $req->{referer},         'http://domain.name/',
  q{$req->{referer}};
is $req->{accept_language}, 'en-us',
  q{$req->{accept_language}};
is $req->{accept_encoding}, 'gzip, deflate',
  q{$req->{accept_encoding}};
is $req->{user_agent},      'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET)',
  q{$req->{user_agent}};
is $req->{host},            'domain.name',
  q{$req->{host}};
is $req->{connection},      'Keep-Alive',
  q{$req->{connection}};
is $req->{cookie},          'test=OK;',
  q{$req->{cookie}};

# response header.
ok my $res= $e->parse_http_header($head[1]),
  q{my $res= $e->parse_http_header($head[1])};
isa_ok $res, 'HASH';
is $res->{status},         'HTTP/1.1 200 OK',
  q{$res->{status}};
is $res->{connection},     'close',
  q{$res->{connection}};
is $res->{server},         'Apache',
  q{$res->{server}};
is $res->{cache_control},  'private, max-age=0',
  q{$res->{cache_control}};
is $res->{content_type},   'text/xml; charset=utf-8',
  q{$res->{content_type}};

ok ! $res->{content1}, q{! $res->{content1}};
ok ! $res->{content2}, q{! $res->{content2}};
ok ! $res->{content3}, q{! $res->{content3}};

__DATA__
--- |
  GET / HTTP/1.1
  Accept: image/gif, image/x-xbitmap, image/jpeg, image/pjpeg, application/x-shockwave-flash, */*
  Referer: http://domain.name/
  Accept-Language: en-us
  Accept-Encoding: gzip, deflate
  User-Agent: Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET)
  Host: domain.name
  Connection: Keep-Alive
  Cookie: test=OK;
--- |
  HTTP/1.1 200 OK
  Connection: close
  Server: Apache
  Cache-Control: private, max-age=0
  Content-Type: text/xml; charset=utf-8
  
  content1
  content2
  content3
