#!/usr/local/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $CRLF $DEBUG );
    use Test2::V0;
    our $CRLF = "\015\012";
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

BEGIN
{
    use ok( 'HTTP::Promise::Headers' );
};

my( $h, $h2, $rv );
$h = HTTP::Promise::Headers->new;
isa_ok( $h, ['HTTP::Promise::Headers'] );
# for m in `egrep -E '^=head2 (\w+)' ./lib/HTTP/Promise/Headers.pm| awk '{ print $2 }'`; do echo "can_ok( \$h => '$m' );"; done
# perl -lnE '/^sub (?!init|[A-Z]|_)/ and say "can_ok( \$h, \''", [split(/\s+/, $_)]->[1], "\'' );"' ./lib/HTTP/Promise/Headers.pm
can_ok( $h => 'new' );
can_ok( $h => 'add' );
can_ok( $h => 'as_string' );
can_ok( $h => 'authorization_basic' );
can_ok( $h => 'boundary' );
can_ok( $h => 'charset' );
can_ok( $h => 'clear' );
can_ok( $h => 'clone' );
can_ok( $h => 'content_type_charset' );
can_ok( $h => 'decode_filename' );
can_ok( $h => 'debug' );
can_ok( $h => 'default_type' );
can_ok( $h => 'delete' );
can_ok( $h => 'encode_filename' );
can_ok( $h => 'error' );
can_ok( $h => 'exists' );
can_ok( $h => 'get' );
can_ok( $h => 'header' );
can_ok( $h => 'header_field_names' );
can_ok( $h => 'init_header' );
can_ok( $h => 'mime_attr' );
can_ok( $h => 'mime_encoding' );
can_ok( $h => 'mime_type' );
can_ok( $h => 'multipart_boundary' );
can_ok( $h => 'print' );
can_ok( $h => 'proxy_authorization_basic' );
can_ok( $h => 'push_header' );
can_ok( $h => 'recommended_filename' );
can_ok( $h => 'remove_content_headers' );
can_ok( $h => 'remove_header' );
can_ok( $h => 'replace' );
can_ok( $h => 'request_timeout' );
can_ok( $h => 'scan' );
can_ok( $h => 'type' );
can_ok( $h => 'accept' );
can_ok( $h => 'accept_charset' );
can_ok( $h => 'accept_encoding' );
can_ok( $h => 'accept_language' );
can_ok( $h => 'accept_patch' );
can_ok( $h => 'accept_post' );
can_ok( $h => 'accept_ranges' );
can_ok( $h => 'acceptables' );
can_ok( $h => 'age' );
can_ok( $h => 'allow' );
can_ok( $h => 'allow_credentials' );
can_ok( $h => 'allow_headers' );
can_ok( $h => 'allow_methods' );
can_ok( $h => 'allow_origin' );
can_ok( $h => 'alt_svc' );
can_ok( $h => 'alternate_server' );
can_ok( $h => 'authorization' );
can_ok( $h => 'cache_control' );
can_ok( $h => 'clear_site_data' );
can_ok( $h => 'connection' );
can_ok( $h => 'content_disposition' );
can_ok( $h => 'content_encoding' );
can_ok( $h => 'content_is_text' );
can_ok( $h => 'content_is_html' );
can_ok( $h => 'content_is_json' );
can_ok( $h => 'content_is_xhtml' );
can_ok( $h => 'content_is_xml' );
can_ok( $h => 'content_language' );
can_ok( $h => 'content_length' );
can_ok( $h => 'content_location' );
can_ok( $h => 'content_range' );
can_ok( $h => 'content_security_policy' );
can_ok( $h => 'content_security_policy_report_only' );
can_ok( $h => 'content_type' );
can_ok( $h => 'cross_origin_embedder_policy' );
can_ok( $h => 'cross_origin_opener_policy' );
can_ok( $h => 'cross_origin_resource_policy' );
can_ok( $h => 'cspro' );
can_ok( $h => 'date' );
can_ok( $h => 'device_memory' );
can_ok( $h => 'digest' );
can_ok( $h => 'dnt' );
can_ok( $h => 'early_data' );
can_ok( $h => 'etag' );
can_ok( $h => 'expect' );
can_ok( $h => 'expect_ct' );
can_ok( $h => 'expires' );
can_ok( $h => 'expose_headers' );
can_ok( $h => 'forwarded' );
can_ok( $h => 'from' );
can_ok( $h => 'host' );
can_ok( $h => 'if_match' );
can_ok( $h => 'if_modified_since' );
can_ok( $h => 'if_none_match' );
can_ok( $h => 'if_range' );
can_ok( $h => 'if_unmodified_since' );
can_ok( $h => 'keep_alive' );
can_ok( $h => 'last_modified' );
can_ok( $h => 'link' );
can_ok( $h => 'location' );
can_ok( $h => 'max_age' );
can_ok( $h => 'nel' );
can_ok( $h => 'origin' );
can_ok( $h => 'proxy' );
can_ok( $h => 'proxy_authenticate' );
can_ok( $h => 'proxy_authorization' );
can_ok( $h => 'range' );
can_ok( $h => 'referer' );
can_ok( $h => 'referrer' );
can_ok( $h => 'referrer_policy' );
can_ok( $h => 'request_headers' );
can_ok( $h => 'request_method' );
can_ok( $h => 'retry_after' );
can_ok( $h => 'save_data' );
can_ok( $h => 'server' );
can_ok( $h => 'server_timing' );
can_ok( $h => 'set_cookie' );
can_ok( $h => 'sourcemap' );
can_ok( $h => 'strict_transport_security' );
can_ok( $h => 'te' );
can_ok( $h => 'timing_allow_origin' );
can_ok( $h => 'title' );
can_ok( $h => 'tk' );
can_ok( $h => 'trailer' );
can_ok( $h => 'transfer_encoding' );
can_ok( $h => 'upgrade' );
can_ok( $h => 'upgrade_insecure_requests' );
can_ok( $h => 'user_agent' );
can_ok( $h => 'vary' );
can_ok( $h => 'via' );
can_ok( $h => 'want_digest' );
can_ok( $h => 'warning' );
can_ok( $h => 'www_authenticate' );
can_ok( $h => 'x_content_type_options' );
can_ok( $h => 'x_dns_prefetch_control' );
can_ok( $h => 'x_forwarded_for' );
can_ok( $h => 'x_forwarded_host' );
can_ok( $h => 'x_forwarded_proto' );
can_ok( $h => 'x_frame_options' );
can_ok( $h => 'x_xss_protection' );

# Following test units courtesy of Sawyer X
sub j { join( '|', @_ ) }

diag( "As string: '", $h->as_string, "'" ) if( $DEBUG );
is( $h->as_string, '' );

$h = HTTP::Promise::Headers->new( foo => 'bar', foo => 'baaaaz', Foo => 'baz' );
is( $h->as_string, "Foo: bar${CRLF}Foo: baaaaz${CRLF}Foo: baz${CRLF}" );

$h = HTTP::Promise::Headers->new( foo => [qw( bar baz )] );
is( $h->as_string, "Foo: bar${CRLF}Foo: baz${CRLF}" );

$h = HTTP::Promise::Headers->new( foo => 1, bar => 2, foo_bar => 3 );
is( $h->as_string, "Bar: 2${CRLF}Foo: 1${CRLF}Foo-Bar: 3${CRLF}" );
is( $h->as_string( ';' ), "Bar: 2;Foo: 1;Foo-Bar: 3;" );

is( $h->header( 'Foo' ), 1 );
is( $h->header( 'FOO' ), 1 );
is( j( $h->header( 'foo' ) ), 1 );
is( $h->header( 'foo-bar' ), 3 );
is( $h->header( 'foo_bar' ), 3 );
is( $h->header( 'Not-There' ), undef );
is( j( $h->header( 'Not-There' ) ), '' );
is( eval{ $h->header }, undef );
ok( $@ );

is( $h->header( 'Foo', 11 ), 1 );
is( $h->header( 'Foo', [1, 1] ), 11 );
is( $h->header( 'Foo' ), '1, 1' );
is( j( $h->header( 'Foo' ) ), '1|1' );
is( $h->header( foo => 11, Foo => 12, bar => 22 ), 2 );
is( $h->header( 'Foo' ), '11, 12' );
is( $h->header( 'Bar' ), 22 );
is( $h->header( 'Bar', undef ), 22 );
is( j( $h->header( 'bar', 22 ) ), '' );

$h->push_header( Bar => 22 );
is( $h->header( 'Bar' ), '22, 22' );
$h->push_header( Bar => [23 .. 25] );
is( $h->header( 'Bar' ), '22, 22, 23, 24, 25' );
is( j($h->header( 'Bar' ) ), '22|22|23|24|25' );

$h->clear;
$h->header( Foo => 1 );
is( $h->as_string, "Foo: 1${CRLF}" );
$h->init_header( Foo => 2 );
$h->init_header( Bar => 2 );
is( $h->as_string, "Bar: 2${CRLF}Foo: 1${CRLF}" );
$h->init_header( Foo => [2, 3] );
$h->init_header( Baz => [2, 3] );
is( $h->as_string, "Bar: 2${CRLF}Baz: 2${CRLF}Baz: 3${CRLF}Foo: 1${CRLF}" );

eval{ $h->init_header( A => 1, B => 2, C => 3 ) };
ok( $@, 'init_header failed' );
is( $h->as_string, "Bar: 2${CRLF}Baz: 2${CRLF}Baz: 3${CRLF}Foo: 1${CRLF}" );

is( $h->clone->remove_header( 'Foo' ), 1 );
is( $h->clone->remove_header( 'Bar' ), 1 );
is( $h->clone->remove_header( 'Baz' ), 2 );
is( $h->clone->remove_header( qw( Foo Bar Baz Not-There ) ), 4 );
is( $h->clone->remove_header( 'Not-There' ), 0 );
is( j( $h->clone->remove_header( 'Foo' ) ), 1 );
is( j( $h->clone->remove_header( 'Bar' ) ), 2 );
is( j( $h->clone->remove_header( 'Baz' ) ), '2|3' );
is( j( $h->clone->remove_header( qw( Foo Bar Baz Not-There ) ) ), '1|2|2|3' );
is( j( $h->clone->remove_header( 'Not-There' ) ), '' );

$h = HTTP::Promise::Headers->new(
    allow => 'GET',
    content => 'none',
    content_type => 'text/html',
    content_md5 => 'dummy',
    content_encoding => 'gzip',
    content_foo => 'bar',
    last_modified => 'yesterday',
    expires => 'tomorrow',
    etag => 'abc',
    date => 'today',
    user_agent => 'http-promise',
    zoo => 'foo',
   );
is( $h->as_string, join( $CRLF, split( /\n/, <<EOT, -1 ) ) );
Date: today
User-Agent: http-promise
ETag: abc
Allow: GET
Content-Encoding: gzip
Content-MD5: dummy
Content-Type: text/html
Expires: tomorrow
Last-Modified: yesterday
Content: none
Content-Foo: bar
Zoo: foo
EOT

$h2 = $h->clone;
is( $h->as_string, $h2->as_string );

is( $h->remove_content_headers->as_string, join( $CRLF, split( /\n/, <<EOT, -1 ) ) );
Allow: GET
Content-Encoding: gzip
Content-MD5: dummy
Content-Type: text/html
Expires: tomorrow
Last-Modified: yesterday
Content-Foo: bar
EOT

is( $h->as_string, join( $CRLF, split( /\n/, <<EOT, -1 ) ) );
Date: today
User-Agent: http-promise
ETag: abc
Content: none
Zoo: foo
EOT

# separate code path for the void context case, so test it as well
$h2->remove_content_headers;
is( $h->as_string, $h2->as_string );

$h->clear;
is( $h->as_string, '' );
undef( $h2 );

$h = HTTP::Promise::Headers->new;
is( $h->header_field_names, 0 );
is( j( $h->header_field_names), '' );

$h = HTTP::Promise::Headers->new( etag => 1, foo => [2,3],
			 content_type => 'text/plain' );
is( $h->header_field_names, 3 );
is( j( $h->header_field_names ), 'ETag|Content-Type|Foo' );

{
    my @tmp;
    $h->scan(sub{ push( @tmp, @_ ) });
    is( j( @tmp ), 'ETag|1|Content-Type|text/plain|Foo|2|Foo|3' );

    @tmp = ();
    eval{ $h->scan(sub{ push( @tmp, @_ ); die if( $_[0] eq 'Content-Type' ) }) };
    ok( $@ );
    is( j( @tmp ), 'ETag|1|Content-Type|text/plain' );

    @tmp = ();
    $h->scan(sub{ push( @tmp, @_ ) });
    is( j( @tmp ), 'ETag|1|Content-Type|text/plain|Foo|2|Foo|3' );
}

# CONVENIENCE METHODS
$h = HTTP::Promise::Headers->new( { debug => $DEBUG } );
is( $h->date, undef );
$rv = $h->date( time );
diag( "Error setting Date field: ", $h->error ) if( $DEBUG && !defined( $rv ) );
isa_ok( $rv, 'Module::Generic::DateTime' );
my $d = $h->date;
diag( "Date field value is '$d' (", overload::StrVal( $d ), ")" ) if( $DEBUG );
is( j( $h->header_field_names ), 'Date' );
ok( $h->header( 'Date' ) =~ /^[A-Z][a-z][a-z], \d\d .* GMT$/ );
{
    my $d = $h->date;
    diag( "Date field value is '$d' (", overload::StrVal( $d ), ")" ) if( $DEBUG );
    isa_ok( $d => 'Module::Generic::DateTime' );
    my $off = time - $h->date;
    ok( $off == 0 || $off == 1);
}

if( $] < 5.006 )
{
   skip( q{Can't call variable method}, 1 ) for( 1..13 );
}
else
{
    # other date fields
    for my $field ( qw( expires if_modified_since if_unmodified_since last_modified ) )
    {
        eval <<'EOT';
    is( $h->$field, undef );
    isa_ok( $h->$field(time), 'Module::Generic::DateTime' );
    ok( ( time - $h->$field ) =~ /^[01]$/ );
EOT
        die( $@ ) if( $@ );
    }
    is( j( $h->header_field_names ), 'Date|If-Modified-Since|If-Unmodified-Since|Expires|Last-Modified' );
}

$h->clear;
is( $h->content_type, undef );
is( $h->content_type( 'text/html' ), 'text/html' );
is( $h->content_type, 'text/html' );
is( $h->content_type( '   TEXT  / HTML   ' ) , '   TEXT  / HTML   ' );
is( $h->content_type, '   TEXT  / HTML   ' );
is( j($h->content_type ), '   TEXT  / HTML   ' );
is( $h->content_type( "text/html;\n charSet = \"ISO-8859-1\"; Foo=1 " ), qq{text/html;\n charSet = \"ISO-8859-1\"; Foo=1 } );
is( $h->content_type, qq{text/html;\n charSet = \"ISO-8859-1\"; Foo=1 } );
# is( j($h->content_type), 'text/html|charSet = "ISO-8859-1"; Foo=1 ' );
is( $h->header( 'content_type' ), qq{text/html;\n charSet = "ISO-8859-1"; Foo=1 } );
ok( $h->content_is_html );
ok( !$h->content_is_xhtml );
ok( !$h->content_is_xml );
$h->content_type( 'application/xhtml+xml' );
is( $h->content_type, 'application/xhtml+xml' );
ok( $h->content_is_html );
ok( $h->content_is_xhtml );
ok( $h->content_is_xml );
is( $h->content_type( qq{text/html;\n charSet = "ISO-8859-1"; Foo=1 } ), qq{text/html;\n charSet = "ISO-8859-1"; Foo=1 } );

is( $h->content_encoding, undef );
is( $h->content_encoding( 'gzip' ), 'gzip' );
is( $h->content_encoding, 'gzip' );
is( j( $h->header_field_names ), 'Content-Encoding|Content-Type' );

is( $h->content_language, undef );
is( $h->content_language( 'ja' ), 'ja' );
is( $h->content_language, 'ja' );

is( $h->title, undef);
is( $h->title( 'This is a test' ), 'This is a test' );
is( $h->title, "This is a test" );

is( $h->user_agent, undef );
is( $h->user_agent( 'Mozilla/1.2' ), 'Mozilla/1.2' );
is( $h->user_agent, 'Mozilla/1.2' );

is( $h->server, undef );
is( $h->server( 'Apache/2.1' ), 'Apache/2.1' );
is( $h->server, 'Apache/2.1' );

is( $h->from( 'john.doe@example.com' ), 'john.doe@example.com' );
ok( $h->header( 'from', 'john.doe@example.com' ) );

is( $h->referer( 'http://www.example.com' ), 'http://www.example.com' );
is( $h->referer, 'http://www.example.com' );
is( $h->referrer, 'http://www.example.com' );
is( $h->referer( 'http://www.example.com/#bar' ), 'http://www.example.com/#bar' );
is( $h->referer, 'http://www.example.com/#bar' );
{
    require URI;
    my $u = URI->new( 'http://www.example.com#bar' );
    $h->referer( $u );
    is( $u->as_string, 'http://www.example.com#bar' );
    is( $h->referer->fragment, 'bar' );
    is( $h->referrer->as_string, 'http://www.example.com#bar' );
}

is( $h->as_string, join( $CRLF, split( /\n/, <<EOT, -1 ) ) );
From: john.doe\@example.com
Referer: http://www.example.com#bar
User-Agent: Mozilla/1.2
Server: Apache/2.1
Content-Encoding: gzip
Content-Language: ja
Content-Type: text/html;
 charSet = "ISO-8859-1"; Foo=1
Title: This is a test
EOT

$h->clear;
is( $h->www_authenticate( 'foo' ), 'foo' );
is( $h->www_authenticate( 'bar' ), 'bar' );
is( $h->www_authenticate, 'bar' );
is( $h->proxy_authenticate( 'foo' ), 'foo' );
is( $h->proxy_authenticate( 'bar' ), 'bar' );
is( $h->proxy_authenticate, 'bar' );

is( $h->authorization_basic, undef );
is( $h->authorization_basic( 'u' ), 'u:' );
is( $h->authorization_basic( qw( u p ) ), 'u:p' );
is( $h->authorization_basic, 'u:p' );
is( j( $h->authorization_basic ), 'u|p' );
is( $h->authorization, 'Basic dTpw' );

{
    no warnings;
    $rv = $h->authorization_basic( 'u2:p' );
}
# diag( "Exepected error setting authorisation: ", $h->error ) if( $DEBUG && !defined( $rv ) );
is( $rv, undef, 'authorization_basic failed' );
like( $h->error->message, qr/Basic authorisation user name cannot contain/, 'authorization_basic failed message' );
is( j( $h->authorization_basic), 'u|p' );

is( $h->proxy_authorization_basic( qw( u2 p2 ) ), 'u2:p2' );
is( j($h->proxy_authorization_basic), 'u2|p2' );
is( $h->proxy_authorization, 'Basic dTI6cDI=' );

is( $h->as_string, join( $CRLF, split( /\n/, <<EOT, -1 ) ) );
Authorization: Basic dTpw
Proxy-Authorization: Basic dTI6cDI=
Proxy-Authenticate: bar
WWW-Authenticate: bar
EOT

#---- old tests below -----
$h = HTTP::Promise::Headers->new(
	mime_version  => '1.0',
	content_type  => 'text/html'
);
$h->header( URI => 'http://www.example.com/' );

is( $h->header( 'MIME-Version' ), '1.0' );
is( $h->header( 'Uri' ), 'http://www.example.com/' );

$h->header(
    'MY-header' => 'foo',
    'Date' => 'somedate',
    'Accept' => [qw( text/plain image/* )],
);
$h->push_header( 'accept' => 'audio/basic' );

is( $h->header( 'date' ), 'somedate' );

my @accept = $h->header( 'accept' );
is( @accept, 3 );

$h->remove_header( 'uri', 'date' );

my $str = $h->as_string;
my $lines = ( $str =~ tr/\n/\n/ );
is( $lines, 6 );

$h2 = $h->clone;

$h->header( 'accept', '*/*' );
$h->remove_header( 'my-header' );

@accept = $h2->header( 'accept' );
is( @accept, 3 );

@accept = $h->header( 'accept' );
is( @accept, 1 );

# Check order of headers, but first remove this one
$h2->remove_header( 'mime_version' );

# and add this general header
$h2->header( Connection => 'close' );

my @x = ( );
$h2->scan( sub{ push( @x, shift( @_ ) ); } );
is( join( ';', @x ), 'Connection;Accept;Accept;Accept;Content-Type;My-Header' );

# Check headers with embedded newlines:
$h = HTTP::Promise::Headers->new(
	a => "foo\n\n",
	b => "foo\nbar",
	c => "foo\n\nbar\n\n",
	d => "foo\n\tbar",
	e => "foo\n  bar  ",
	f => "foo\n bar\n  baz\nbaz",
      );
is( $h->as_string( "<<\n" ), <<EOT );
A: foo<<
B: foo<<
 bar<<
C: foo<<
 bar<<
D: foo<<
 bar<<
E: foo<<
 bar<<
F: foo<<
 bar<<
 baz<<
 baz<<
EOT

# Check for attempt to send a body
$h = HTTP::Promise::Headers->new(
    a => "foo\r\n\r\nevil body" ,
    b => "foo\015\012\015\012evil body" ,
    c => "foo\x0d\x0a\x0d\x0aevil body" ,
);
is(
    $h->as_string(),
    "A: foo\r\n evil body${CRLF}".
    "B: foo\015\012 evil body${CRLF}" .
    "C: foo\x0d\x0a evil body${CRLF}" ,
    'embedded CRLF are stripped out'
);

# Check if objects as header values works
require URI;
$h->header( URI => URI->new( 'http://www.example.org' ) );

is( $h->header( 'URI' )->scheme, 'http' );

$h->clear;
is( $h->as_string, '' );

$h->content_type( 'text/plain' );
$h->header( content_md5 => 'dummy' );
$h->header( 'Content-Foo' => 'foo' );
$h->header( Location => 'http:', xyzzy => 'plugh!' );

is( $h->as_string, join( $CRLF, split( /\n/, <<EOT, -1 ) ) );
Location: http:
Content-MD5: dummy
Content-Type: text/plain
Content-Foo: foo
Xyzzy: plugh!
EOT

my $c = $h->remove_content_headers;
is( $h->as_string, join( $CRLF, split( /\n/, <<EOT, -1 ) ) );
Location: http:
Xyzzy: plugh!
EOT

is( $c->as_string, join( $CRLF, split( /\n/, <<EOT, -1 ) ) );
Content-MD5: dummy
Content-Type: text/plain
Content-Foo: foo
EOT

# [RT#30579] IE6 appens "; length = NNNN" on If-Modified-Since (can we handle it)
$h = HTTP::Promise::Headers->new(
    if_modified_since => 'Sat, 29 Oct 1994 19:43:31 GMT; length=34343',
    { debug => $DEBUG }
);
is( gmtime( $h->if_modified_since ), 'Sat Oct 29 19:43:31 1994' );

done_testing();

__END__

