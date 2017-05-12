use Test::More tests => 4;

use File::Temp qw/ tempfile tempdir /;
use LWP::UserAgent::WithCache;

my $tempdir = tempdir( CLEANUP => 1 );

my $ua = LWP::UserAgent::WithCache->new({ cache_root => $tempdir });

my $res;
{
$res  = HTTP::Response->parse(<<'EOF');
HTTP/1.1 200 OK
Connection: close
Date: Tue, 09 Oct 2007 06:03:01 GMT
Accept-Ranges: bytes
ETag: "3bf60b-ed-61bb4b40"
Server: Apache
Content-Length: 237
Content-Type: text/css
Last-Modified: Wed, 03 Oct 2007 00:00:13 GMT
Client-Date: Mon, 08 Oct 2007 12:52:55 GMT
Client-Peer: 59.106.15.125:80
Client-Response-Num: 1

/* This is the StyleCatcher theme addition. Do not remove this block. */
/* Selected Layout:  */
@import url(base_theme.css);
@import url(http://mt.qootas.org/mt/mt-static/themes/minimalist-red/screen.css);
/* end StyleCatcher imports */
EOF

my $uri = 'http://www.example.com/styles.css';
$ua->set_cache($uri, $res);
my $cached_res = $ua->get('http://www.example.com/styles.css');

is ($cached_res->code, 200);
}

# haven't expired yet
{
$res  = HTTP::Response->parse(<<'EOF');
HTTP/1.1 200 OK
Connection: close
Date: Tue, 09 Oct 2007 06:03:01 GMT
Accept-Ranges: bytes
Server: Apache
Content-Length: 237
Content-Type: text/css
Last-Modified: Wed, 03 Oct 2007 00:00:13 GMT
Expires: Thr, 16 Jan 2038 03:14:06 GMT

/* This is the StyleCatcher theme addition. Do not remove this block. */
/* Selected Layout:  */
@import url(base_theme.css);
@import url(http://mt.qootas.org/mt/mt-static/themes/minimalist-red/screen.css);
/* end StyleCatcher imports */
EOF

my $uri = 'http://www.example.com/styles.css';
$ua->set_cache($uri, $res);
my $cached_res = $ua->get('http://www.example.com/styles.css');

is ($cached_res->code, 200);
}

# handle 304 Not Modified response
{
$res  = HTTP::Response->parse(<<'EOF');
HTTP/1.1 200 OK
Connection: close
Server: nginx/1.0.4
Content-Length: 237
Content-Type: text/css
Date:Fri, 07 Oct 2011 22:43:34 GMT
Last-Modified: Thr, 01 Jan 1970 00:00:00 GMT

/* This is the StyleCatcher theme addition. Do not remove this block. */
/* Selected Layout:  */
@import url(base_theme.css);
@import url(http://mt.qootas.org/mt/mt-static/themes/minimalist-red/screen.css);
/* end StyleCatcher imports */
EOF

my $not_modified_res  = HTTP::Response->parse(<<'EOF');
HTTP/1.1 304 Not Modified
Connection: close
Server: nginx/1.0.4
Date:Fri, 07 Oct 2011 22:43:34 GMT
Last-Modified: Thr, 01 Jan 1970 00:00:00 GMT

EOF

my $uri = 'http://www.example.com/styles.css';
$ua->set_cache($uri, $res);

## override request method to get not_modified_res
no warnings 'redefine';
local *LWP::UserAgent::request = sub {return $not_modified_res};

my $cached_res = $ua->get('http://www.example.com/styles.css');

is ($cached_res->code, 200);
is ($cached_res->content, $res->content);
}
