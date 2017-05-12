use strict;

BEGIN {
    $ENV{PERL_HTTP_RESPONSE_PARSER_PP} = 0;
};

use Benchmark qw(:all);
use HTTP::Response;
use HTTP::Response::Parser qw(parse parse_http_response);

my %header;
use Data::Dumper;

$header{large_header} =<<"END";
HTTP/1.0 200 OK
Date: Mon, 03 May 2010 17:34:05 GMT
Server: hi
Status: 200 OK
X-Transaction: 1272908045-29861-29017
X-RateLimit-Limit: 150
Etag: "93ac529570386caa165a0de5e10c3bdc"-gzip
Last-Modified: Mon, 03 May 2010 17:34:05 GMT
X-RateLimit-Remaining: 148
X-Runtime: 0.06693
Content-Type: application/rss+xml; charset=utf-8
Pragma: no-cache
X-RateLimit-Class: api
X-Revision: DEV
Expires: Tue, 31 Mar 1981 05:00:00 GMT
Cache-Control: no-cache, no-store, must-revalidate, pre-check=0, post-check=0
Set-Cookie: lang=en; path=/
Set-Cookie: _twitter_sess=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX; domain=.twitter.com; path=/
X-RateLimit-Reset: 1272910971
Vary: Accept-Encoding
Content-Encoding: gzip
Content-Length: 1796
Connection: close

content-body
END

$header{small_header} =<<"END";
HTTP/1.0 200 OK
Date: Mon, 03 May 2010 17:34:05 GMT
Last-Modified: Mon, 03 May 2010 17:34:05 GMT
Content-Type: application/rss+xml; charset=utf-8
Vary: Accept-Encoding
Content-Length: 1796
Connection: close

content-body
END

eval {
    parse($header{small_header});
    parse($header{large_header});
};

if ($@) {
    die $@ 
}

for (qw(small_header large_header)) {
    my $buf = $header{$_};
    printf "parse %s\n", $_;
    cmpthese timethese 20000, {
        parse => sub { HTTP::Response->parse($buf) },
        xs    => sub { HTTP::Response::Parser::parse($buf) },
    };
}

exit;



