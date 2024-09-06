#!/usr/local/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG $CRLF );
    use Test2::V0;
    our $CRLF = "\015\012";
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use ok( 'HTTP::Promise::Request' );
};

use strict;
use warnings;

my( $req, $rv );

$req = HTTP::Promise::Request->new;
isa_ok( $req => ['HTTP::Promise::Request'] );

# for m in `egrep -E '^sub ([a-z]\w+)' ./lib/HTTP/Promise/Request.pm| awk '{ print $2 }'`; do echo "can_ok( \$req => '$m' );"; done
# perl -lnE '/^sub (?!init|[A-Z]|_)/ and say "can_ok( \$req, \''", [split(/\s+/, $_)]->[1], "\'' );"' ./lib/HTTP/Promise/Request.pm
can_ok( $req => 'accept_decodable' );
can_ok( $req => 'clone' );
can_ok( $req => 'cookie_jar' );
can_ok( $req => 'dump' );
can_ok( $req => 'headers' );
can_ok( $req => 'make_form_data' );
can_ok( $req => 'method' );
can_ok( $req => 'parse' );
can_ok( $req => 'start_line' );
can_ok( $req => 'timeout' );
can_ok( $req => 'uri' );
can_ok( $req => 'uri_absolute' );
can_ok( $req => 'uri_canonical' );

$req = HTTP::Promise::Request->new( GET => "http://www.example.com", { debug => $DEBUG } );
$req->accept_decodable;

is( $req->method, 'GET' );
is( $req->uri,    'http://www.example.com' );
# assuming IO::Uncompress::Gunzip is there
like( $req->header( 'Accept-Encoding' ), qr/\bgzip\b/ );

$req->dump( prefix => '# ' );

is( $req->method, 'GET' );
$req->method( 'DELETE' );
is( $req->method, 'DELETE' );

is( $req->uri, 'http://www.example.com' );
$rv = $req->uri( 'http:' );
ok( $rv, 'uri -> http:' );
is( $req->uri, 'http:' );

$req->protocol( 'HTTP/1.1' );

diag( "Request is:\n", $req->as_string ) if( $DEBUG );
my $r2 = HTTP::Promise::Request->parse( $req->as_string, { debug => $DEBUG } );
isa_ok( $r2 => ['HTTP::Promise::Request'], 'parsed request' );
# ok( !defined( $r2 ), 'parse succeeded, but bad request rejected' );
# like( HTTP::Promise::Request->error->message, qr/Invalid parameters received/, 'malformed uri rejection' );
$req->uri( 'https://example.com' );
$r2 = HTTP::Promise::Request->parse( $req->as_string );
ok( $r2, 'parse succeeded with proper uri' );
diag( "Error creating request: ", HTTP::Promise::Request->error ) if( $DEBUG && !defined( $r2 ) );
is( $r2->method, 'DELETE', 'method' );
# is( $r2->uri, 'https://example.com', 'uri' );
is( $r2->uri, '/', 'uri' );
is( $r2->protocol, 'HTTP/1.1', 'protocol' );
is( $r2->header( 'Accept-Encoding' ), $req->header( 'Accept-Encoding' ), 'header Accept-Encoding' );

$rv = $req->uri({ foo => 'bar'});
ok( !defined( $rv ), 'bad uri assignment rejected' );
like( $req->error->message, qr/URI value provided '(?:.*?)' does not look like an URI/, 'bad uri error' );
$rv = $req->uri( ['foo'] );
ok( !defined( $rv ), 'bad uri assignment rejected' );
like( $req->error->message, qr/URI value provided '(?:.*?)' does not look like an URI/, 'bad uri error' );

$req = HTTP::Promise::Request->new;
is( $req->as_string, "GET / HTTP/1.1${CRLF}${CRLF}" );
is( $req->dump, <<EOT );
GET / HTTP/1.1

(no content)
EOT
$req->protocol( 'HTTP/1.1' );
is( $req->dump, <<EOT, 'dump' );
GET / HTTP/1.1

(no content)
EOT

{
	my @warn;
	local $SIG{__WARN__} = sub{ push( @warn, @_ ); };
	no warnings;
	$r2 = HTTP::Promise::Request->parse( undef );
	is( $#warn, -1 );
	use warnings;
	$r2 = HTTP::Promise::Request->parse( undef );
	is( $#warn, 0 );
	like( $warn[0], qr/Undefined argument to/ );
}
isa_ok( $r2 => ['HTTP::Promise::Request'] );
# $r2->debug( $DEBUG ) if( $DEBUG );
is( $r2->method, undef, 'undefined method' );
is( $r2->uri, undef, 'undefined uri' );
is( $r2->protocol, undef, 'undefined protocol' );
is( $r2->header( 'Accept-Encoding' ), $req->header( 'Accept-Encoding' ) );

$r2 = HTTP::Promise::Request->parse( 'unknown' );
ok( !defined( $r2 ), 'file "unknown" does not exists (string must be passed as reference)' );
$r2 = HTTP::Promise::Request->parse( \"get / HTTP/1.0${CRLF}${CRLF}", debug => $DEBUG );
ok( !defined( $r2 ), 'unknown bad http method name' );
like( HTTP::Promise::Request->error->message, qr/Invalid parameters received/, 'bad headers error message' );
$r2 = HTTP::Promise::Request->parse( \"METHONLY / HTTP/1.0${CRLF}${CRLF}", debug => $DEBUG );
# diag( "Error parsing non-standard http method name 'methonly': ", HTTP::Promise::Request->error ) if( !defined( $r2 ) && $DEBUG );
# ok( !defined( $r2 ), 'unknown bad http method name (2)' );
isa_ok( $r2 => ['HTTP::Promise::Request'], 'returned object is a HTTP::Promise::Request' );
$r2 = HTTP::Promise::Request->new( 'METHONLY', undef );
diag( "Error instantiating new HTTP::Promise::Request: ", HTTP::Promise::Request->error ) if( !defined( $r2 ) && $DEBUG );
#isa_ok( $r2 => ['HTTP::Promise::Request'] );
is( $r2->method, 'METHONLY' );
is( $r2->uri, undef );
is( $r2->protocol, undef );

# $r2 = HTTP::Promise::Request->parse( 'methonly http://www.example.com/' );
# is( $r2->method, 'methonly' );
# is( $r2->uri, 'http://www.example.com/' );
# is( $r2->protocol, undef );

# CONNECT DELETE GET HEAD OPTIONS PATCH POST PUT TRACE
my @test_methods = (
    [ 'connect', undef ],
    [ 'delete', undef ],
    [ 'get', undef ],
    [ 'head', undef ],
    [ 'options', undef ],
    [ 'patch', undef ],
    [ 'post', undef ],
    [ 'put', undef ],
    [ 'trace', undef ],
    [ 'dummy', 'dummy' ],

    [ 'CONNECT', 'CONNECT' ],
    [ 'DELETE', 'DELETE' ],
    [ 'GET', 'GET' ],
    [ 'HEAD', 'HEAD' ],
    [ 'OPTIONS', 'OPTIONS' ],
    [ 'PATCH', 'PATCH' ],
    [ 'POST', 'POST' ],
    [ 'PUT', 'PUT' ],
    [ 'TRACE', 'TRACE' ],
    [ 'NONSTANDARD', 'NONSTANDARD' ],
);

for( @test_methods )
{
    my( $meth, $expect ) = @$_;
    no warnings 'HTTP::Promise::Request';
    my $r = HTTP::Promise::Request->new( $meth, '/', { debug => $DEBUG } );
    if( !defined( $expect ) )
    {
        ok( !defined( $r ), "HTTP::Promise::Request failed to instantiate with method \"$meth\"" );
    }
    else
    {
        SKIP:
        {
            isa_ok( $r => 'HTTP::Promise::Request' );
            skip( "Object unexpectedly failed to instantiate for method ${meth}", 1 ) if( !defined( $r ) );
            is( $r->method, $meth, "method ${meth}" );
        }
    }
}

done_testing();

__END__

