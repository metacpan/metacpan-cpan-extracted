use Test::More tests=> 207;
use lib qw( ../lib ./lib );
use Egg::Helper;

my $e= Egg::Helper->run('Vtest');

can_ok $e, 'response';
  isa_ok $e->response, 'Egg::Response::handler';
  can_ok $e, 'res';
  is $e->response, $e->res, q{$e->response, $e->res};
  ok my $res= $e->res, q{my $res= $e->res};

can_ok $res, 'no_content_length';

can_ok $res, 'headers';
  isa_ok $res->headers, 'Egg::Response::Headers';
  isa_ok $res->headers, 'HASH';
  isa_ok tied(%{$res->headers}), 'Egg::Response::Headers::TieHash';
  ok my $headers= $res->headers, q{$headers= $res->headers};
    ok $headers->{Boo}= 'hoge', q{$headers->{Boo}= 'hoge'};
    isa_ok $headers->{boo}, 'ARRAY';
    is $headers->{boo}->[0], 'Boo', q{$headers->{Boo}->[0], 'Boo'};
    is $headers->{boo}->[1], 'hoge' , q{$headers->{boo}->[1], 'hoge'};
  can_ok $headers, 'header';
    ok $headers->header(qw/ Test foo /), q{$headers->header(qw/ Test foo /)};
    isa_ok $headers->{test}, 'ARRAY';
    is $headers->{Test}->[0], 'Test', q{$headers->{Test}->[0], 'Test'};
    is $headers->{Test}->[1], 'foo' , q{$headers->{Test}->[1], 'foo'};
  can_ok $headers, 'delete';
    ok $headers->delete('Test'), q{$headers->delete('Test')};
    ok ! $headers->{Test}, q{! $headers->{Test}};
    ok $headers->{boo}, q{$headers->{boo}};
  can_ok $headers, 'clear';
    ok $headers->clear, q{$headers->clear};
    ok ! $headers->{boo}, q{! $headers->{boo}};
  ok @{$headers}{qw/ test1 test2 /}= qw/ foo baa /, q{@{$headers}{qw/ test1 test2 /}= qw/ foo baa /};
  ok $headers->{test1}, q{$headers->{test1}};
  ok $headers->{test2}, q{$headers->{test2}};
  is scalar(keys %$headers), 2, q{scalar(keys %$headers), 2};
  ok $headers->clear, q{$headers->clear};
  is scalar(keys %$headers), 0, q{scalar(keys %$headers), 0};

can_ok $res, 'content_disposition';
  can_ok $res, 'attachment';
  ok $res->attachment('egg_test.txt'), q{$res->attachment('egg_test.txt')};
  ok my $head= $res->headers->{'Content-Disposition'}, q{my $tmp= $res->headers->{'Content-Disposition'}};
  isa_ok $head, 'ARRAY';
  is $head->[0], 'Content-Disposition', q{$head->[0], 'Content-Disposition'};
  like $head->[1], qr{^attachment\; filename=egg_test\.txt}, q{$head->[1], [regexp]};
  is $head->[1], $res->attachment, q{$head->[1], $res->attachment};

can_ok $res, 'p3p';
  ok $res->p3p(qw/ CAO DSP COR CUR ADM DEV /), q{$res->p3p(qw/ CAO DSP COR CUR ADM DEV /)};
  ok $head= $res->headers->{P3P}, q{$head= $res->headers->{P3P}};
  like $head->[1], qr{^policyref\=\"/w3c/p3p\.xml\"\, CP=\"CAO DSP COR CUR ADM DEV\"}, q{$head->[1], [regexp]};
  is $head->[1], $res->p3p, q{$head->[1], $res->p3p};

can_ok $res, 'window_target';
  ok $res->window_target('my_body'), q{$res->window_target('my_body')};
  ok $head= $res->headers->{'Window-Target'}, q{$head= $res->headers->{'Window-Target'}};
  is $head->[1], 'my_body', q{$head->[1], 'my_body'};
  is $head->[1], $res->window_target, q{$head->[1], $res->window_target};

can_ok $res, 'content_encoding';
  ok $res->content_encoding('deflate'), q{$res->content_encoding('deflate')};
  ok $head= $res->headers->{'Content-Encoding'}, q{$head= $res->headers->{'Content-Encoding'}};
  is $head->[1], 'deflate', q{$head->[1], 'deflate'};
  is $head->[1], $res->content_encoding, q{$head->[1], $res->content_encoding};

can_ok $res, 'status';
  can_ok $res, 'status_string';
  ok $res->status('404 Not Found'), q{$res->status('404 Not Found')};
  is $res->status, 404, q{$res->status, 404};
  is $res->status_string, ' Not Found', q{$res->status_string, ' Not Found'};
  ok $res->status(403), q{$res->status(403)};
  is $res->status, 403, q{$res->status, 403};
  is $res->status_string, ' Forbidden', q{$res->status_string, ' Forbidden'};
  ok ! $res->status(0), q{! $res->status(0)};
  ok ! $res->status, q{! $res->status};
  ok ! $res->status_string, q{! $res->status_string};
  ok $res->status(200), q{$res->status(200)};

can_ok $res, 'redirect';
  can_ok $res, 'location';
  ok $res->redirect('/index', 307, target=> 'new_body'), q{$res->redirect(...};
  is $res->location, '/index', q{$res->location, '/index'};
  is $res->window_target, 'new_body', q{$res->window_target, 'new_body'};
  ok $e->finished, q{$e->finished};

can_ok $res, 'header';
  ok my $header= $res->header, q{my $header= $res->header};
  isa_ok $header, 'SCALAR';
  like $$header, qr{\bStatus\: 307}, q{qr{\bStatus\: 307}};
  like $$header, qr{\bLocation\: /index}, q{qr{\bLocation\: /index}};
  like $$header, qr{\bContent-Disposition\:}, q{qr{\bContent-Disposition\:}};
  like $$header, qr{\bP3P\:}, q{qr{\bP3P\:}};
  like $$header, qr{\bContent\-Encoding\:}, q{qr{\bContent\-Encoding\:}};
  like $$header, qr{\bWindow\-Target\:}, q{qr{\bWindow\-Target\:}};
  ok ! $res->redirect(0), q{! $res->redirect(0)};
  ok ! $res->attachment(0), q{! $res->attachment(0)};
  ok ! $res->p3p(0), q{! $res->p3p(0)};
  ok ! $res->content_encoding(0), q{! $res->content_encoding(0)};

can_ok $res, 'content_type';
  ok $res->content_type('text/javascript'), q{$res->content_type('text/javascript')};
  ok $header= $res->header, q{$header= $res->header};
  like $$header, qr{\bContent\-Type\: text/javascript}, q{qr{\bContent\-Type\: text/javascript}};
  ok ! $res->content_type(0), q{! $res->content_type(0)};
  ok $header= $res->header, q{$header= $res->header};
  like $$header, qr{\bContent\-Type\: text/html}, q{qr{\bContent\-Type\: text/html}};

can_ok $res, 'content_language';
  ok $res->content_language('ja'), q{$res->content_language('ja')};
  ok $header= $res->header, q{$header= $res->header};
  like $$header, qr{\bContent\-Language\: ja}, q{qr{\bContent\-Language\: ja}};
  ok $res->content_type('image/png'), q{$res->content_type('image/png')};
  ok $header= $res->header, q{$header= $res->header};
  unlike $$header, qr{\bContent\-Language\:}, q{! qr{\bContent\-Language\:}};
  ok ! $res->content_type(0), q{! $res->content_type(0)};
  ok ! $res->content_language(0), q{! $res->content_language(0)};
  ok $header= $res->header, q{$header= $res->header};
  unlike $$header, qr{\bContent\-Language\:}, q{! qr{\bContent\-Language\:}};

can_ok $res, 'is_expires';
  ok $res->is_expires('+1d'), q{$res->is_expires('+1d')};
  ok $header= $res->header, q{$header= $res->header};
  like $$header, qr{\bExpires\: }, q{qr{\bExpires\: }};
  like $$header, qr{\bDate\: }, q{qr{\bDate\: }};
  ok ! $res->is_expires(0), q{! $res->is_expires(0)};
  ok $header= $res->header, q{$header= $res->header};
  unlike $$header, qr{\bExpires\: }, q{! qr{\bExpires\: }};
  unlike $$header, qr{\bDate\: }, q{! qr{\bDate\: }};

can_ok $res, 'last_modified';
  ok $res->last_modified('+1d'), q{$res->last_modified('+1d')};
  ok $header= $res->header, q{$header= $res->header};
  like $$header, qr{\bLast\-Modified\: }, q{qr{\bLast\-Modified\: }};
  ok ! $res->last_modified(0), q{! $res->last_modified(0)};
  ok $header= $res->header, q{$header= $res->header};
  unlike $$header, qr{\bLast\-Modified\: }, q{! qr{\bLast\-Modified\: }};

can_ok $res, 'no_cache';
  ok $res->no_cache(1), q{$res->no_cache(1)};
  ok $res->is_expires, q{$res->is_expires};
  ok $res->last_modified, q{$res->last_modified};
  ok $res->{no_cache}, q{$res->{no_cache}};
  ok ! $res->no_cache(0), q{! $res->no_cache(0)};
  ok ! $res->is_expires, q{! $res->is_expires};
  ok ! $res->last_modified, q{! $res->last_modified};
  ok ! $res->{no_cache}, q{! $res->{no_cache}};
  ok $res->no_cache(1), q{$res->no_cache(1)};
  ok $header= $res->header, q{$header= $res->header};
  unlike $$header, qr{\bStatus\: 307}, q{! qr{\bStatus\: 307}};
  unlike $$header, qr{\bLocation\:}, q{! qr{\bLocation\:}};
  like $$header, qr{\bDate\:}, q{qr{\bDate\:}};
  like $$header, qr{\bExpires\:}, q{qr{\bExpires\:}};
  like $$header, qr{\bLast\-Modified\:}, q{qr{\bLast\-Modified\:}};
  like $$header, qr{\bPragma\: no-cache}, q{qr{\bPragma\: no-cache}};
  like $$header, qr{\bCache\-Control\: no\-cache}, q{qr{\bCache\-Control\: no\-cache}};

can_ok $res, 'cookie';
  can_ok $res, 'cookies';
  ok my $cookie= $res->cookies, q{my $cookie= $res->cookies};
  isa_ok $cookie, 'HASH';
  isa_ok tied(%$cookie), 'Egg::Response::TieCookie';
  ok ! $res->p3p(0), q{! $res->p3p(0)};
  ok $header= $res->header, q{$header= $res->header};
  unlike $$header, qr{\bP3P\:}, q{! qr{\bP3P\:}};
  ok $e->config->{p3p_policy}= [qw/ CAO DSP COR CUR ADM DEV /],
     q{$e->config->{p3p_policy}= [qw/ CAO DSP COR CUR ADM DEV /]};
  ok $cookie->{test}= {
    value  => 'foo',
    path   => '/',
    domain => 'mydomain.com',
    expires=> '+1m',
    secure => 1,
    }, q{$cookie->{test}= 'foo'};
  isa_ok $cookie->{test}, 'Egg::Response::FetchCookie';
  can_ok $cookie->{test}, 'name';
  can_ok $cookie->{test}, 'value';
  can_ok $cookie->{test}, 'path';
  can_ok $cookie->{test}, 'domain';
  can_ok $cookie->{test}, 'expires';
  can_ok $cookie->{test}, 'secure';
  is $cookie->{test}->name, 'test', q{$cookie->{test}->name, 'test'};
  is $cookie->{test}->value, 'foo', q{$cookie->{test}->value, 'foo'};
  is $cookie->{test}->path, '/', q{$cookie->{test}->path, '/'};
  is $cookie->{test}->domain, 'mydomain.com', q{$cookie->{test}->domain, 'mydomain.com'};
  is $cookie->{test}->expires, '+1m', q{$cookie->{test}->expires, '+1m'};
  is $cookie->{test}->secure, 1, q{$cookie->{test}->secure, 1};
  ok $header= $res->header, q{$header= $res->header};
  like $$header, qr{\bSet\-Cookie\: +.*?test=foo}, q{qr{\bSet\-Cookie\: +.*?test=foo}};
  like $$header, qr{\bSet\-Cookie\: +.*?path=/}, q{qr{\bSet\-Cookie\: +.*?path=/}};
  like $$header, qr{\bSet\-Cookie\: +.*?expires=[A-Z][a-z]+\, }, q{qr{\bSet\-Cookie\: +.*?expires=[A-Z][a-z]+\, }};
  like $$header, qr{\bSet\-Cookie\: +.*?secure}, q{qr{\bSet\-Cookie\: +.*?secure}};
  like $$header, qr{\bP3P\:}, q{qr{\bP3P\:}};
  ok delete($e->config->{p3p_policy}), q{delete($e->config->{p3p_policy})};
  ok $res->clear_cookies, q{$res->clear_cookies};
  ok $header= $res->header, q{$header= $res->header};
  unlike $$header, qr{\bSet\-Cookie\:}, q{! qr{\bSet\-Cookie\:}};
  unlike $$header, qr{\bP3P\:}, q{! qr{\bP3P\:}};
  ok $headers->clear, q{$headers->clear};
  ok ! $res->no_cache(0), q{$res->no_cache(0)};

can_ok $res, 'body';
  can_ok $res, 'clear_body';
  ok ! $res->body, q{! $res->body};
  ok my $body= $res->body('content'), q{my $body= $res->body('content')};
  isa_ok $body, 'SCALAR';
  ok ! $res->clear_body, q{$res->clear_body};
  ok ! $res->body, q{! $res->body};

can_ok $res, 'nph';
  ok $res->nph(1), q{$res->nph(1)};
  ok $header= $res->header, q{$header= $res->header};
  like $$header, qr{\bHTTP/1\.1 200 OK}, q{qr{HTTP/1\.1 200 OK}};
  like $$header, qr{\bServer\: }, q{qr{\bServer\: }};
  like $$header, qr{\bDate\: }, q{qr{\bDate\: }};
  ok ! $res->nph(0), q{! $res->nph(0)};
  ok $header= $res->header, q{$header= $res->header};
  unlike $$header, qr{\bHTTP/1\.1 200 OK}, q{! qr{HTTP/1\.1 200 OK}};
  unlike $$header, qr{\bServer\: }, q{! qr{\bServer\: }};
  unlike $$header, qr{\bDate\: }, q{! qr{\bDate\: }};
  ok my @part= split /\n+/, crean_header($header);
  is scalar(@part), 2, q{scalar(split /\n+/, $$header), 2};

can_ok $res, 'clear';
  ok $res->no_cache(1), q{$res->no_cache(1)};
  ok $res->redirect('/'), q{$res->redirect('/')};
  ok $res->headers->{clear_test}= 'zzz', q{$res->headers->{clear_test}= 'zzz'};
  ok $res->cookies->{clear_test}= 1, q{$res->cookies->{clear_test}= 1};
  ok $header= $res->header, q{$header= $res->header};
  ok @part= split /\n+/, crean_header($header);
  ok scalar(@part) > 2, q{scalar(split /\n+/, $$header) > 2};
  ok $res->clear, q{$res->clear};
  ok $header= $res->header, q{$header= $res->header};
  ok @part= split /\n+/, crean_header($header);
  is scalar(@part), 2, q{scalar(split /\n+/, $$header), 2};


sub crean_header {
	my($str)= @_;
	$$str=~tr/\r//d;
	$$str=~s{\n+$} []s;
	$$str;
}
