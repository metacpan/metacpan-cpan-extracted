#!/usr/local/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG $CRLF );
    use Test2::V0;
    use Crypt::Misc;
    use Scalar::Util;
    our $CRLF = "\015\012";
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use ok( 'HTTP::Promise::Message' );
};

use strict;
use warnings;

my( $m, $m2, @parts, $parts, $io_layer, $body, $rv, $decoded_content );

$m = HTTP::Promise::Message->new;
isa_ok( $m => ['HTTP::Promise::Message'] );

# for m in `egrep -E '^sub ([a-z]\w+)' ./lib/HTTP/Promise/Message.pm| awk '{ print $2 }'`; do echo "can_ok( \$m => '$m' );"; done
# perl -lnE '/^sub (?!init|[A-Z]|_)/ and say "can_ok( \$m, \''", [split(/\s+/, $_)]->[1], "\'' );"' ./lib/HTTP/Promise/Message.pm
can_ok( $m => 'add_content' );
can_ok( $m => 'add_content_utf8' );
can_ok( $m => 'add_part' );
can_ok( $m => 'as_string' );
can_ok( $m => 'boundary' );
can_ok( $m => 'can' );
can_ok( $m => 'clear' );
can_ok( $m => 'clone' );
can_ok( $m => 'content' );
can_ok( $m => 'content_charset' );
can_ok( $m => 'content_ref' );
can_ok( $m => 'decodable' );
can_ok( $m => 'decode' );
can_ok( $m => 'decode_content' );
can_ok( $m => 'decoded_content' );
can_ok( $m => 'decoded_content_utf8' );
can_ok( $m => 'dump' );
can_ok( $m => 'encode' );
can_ok( $m => 'entity' );
can_ok( $m => 'header' );
can_ok( $m => 'headers' );
can_ok( $m => 'headers_as_string' );
can_ok( $m => 'is_encoding_supported' );
can_ok( $m => 'make_boundary' );
can_ok( $m => 'parse' );
can_ok( $m => 'parts' );
can_ok( $m => 'protocol' );
can_ok( $m => 'start_line' );
can_ok( $m => 'version' );

is( ref( $m->headers ), 'HTTP::Promise::Headers' );
is( $m->as_string, $CRLF, 'empty headers and no content' );
is( $m->headers->as_string, '', 'headers->as_string' );
is( $m->headers_as_string, '', 'headers_as_string' );
is( $m->content, '', 'no content' );

$m->header( 'Foo', 1 );
is( $m->as_string, "Foo: 1${CRLF}${CRLF}" );

$m2 = HTTP::Promise::Message->new( $m->headers, { debug => $DEBUG } ) ||
    bail_out( "Failed to instantiate a HTTP::Promise::Message object: " . HTTP::Promise::Message->error );
$m2->header( bar => 2 );
is( $m->as_string, "Foo: 1${CRLF}${CRLF}" );
is( $m2->as_string, "Bar: 2${CRLF}Foo: 1${CRLF}${CRLF}" );
is( $m2->dump, "Bar: 2${CRLF}Foo: 1${CRLF}\n(no content)\n" );
is( $m2->dump( no_content => '' ), "Bar: 2${CRLF}Foo: 1${CRLF}\n\n" );
is( $m2->dump( no_content => '-' ), "Bar: 2${CRLF}Foo: 1${CRLF}\n-\n" );
$body = $m2->content( '0' );
diag( "Error setting content: ", $m2->error ) if( $DEBUG && !defined( $body ) );
is( $m2->content, '0', 'checking content is 0' );
is( $m2->dump( no_content => '-' ), "Bar: 2${CRLF}Foo: 1${CRLF}\n0\n" );
is( $m2->dump( no_content => '0' ), "Bar: 2${CRLF}Foo: 1${CRLF}\n\\x30\n" );

$m2 = HTTP::Promise::Message->new( $m->headers, 'foo', { debug => $DEBUG } );
is( $m2->as_string, "Foo: 1${CRLF}${CRLF}foo", '1 header and content foo' );
is( $m2->as_string( "<<\n" ), "Foo: 1<<\n<<\nfoo", 'using <<\n as eol' );
$m2 = HTTP::Promise::Message->new( $m->headers, "foo\n", { debug => $DEBUG } );
is( $m2->as_string, "Foo: 1${CRLF}${CRLF}foo\n", '1 header and content foo\n' );

$m = HTTP::Promise::Message->new( [ a => 1, b => 2 ], 'abc', { debug => $DEBUG } );
is( $m->as_string, "A: 1${CRLF}B: 2${CRLF}${CRLF}abc", 'lower case content get proper casing' );

$m = HTTP::Promise::Message->parse( '', debug => $DEBUG );
diag( "Error parsing: ", HTTP::Promise::Message->error ) if( $DEBUG && !defined( $m ) );
isa_ok( $m => ['HTTP::Promise::Message'] );
is( $m->as_string, "${CRLF}", 'no content' );
$m = HTTP::Promise::Message->parse( "\n", debug => $DEBUG );
# is( $m->as_string, "${CRLF}\n", 'parse 1 crlf only' );
is( $m, undef, 'bad request cannot be parsed: only 1 new line' );
$m = HTTP::Promise::Message->parse( "\n\n", debug => $DEBUG );
# is( $m->as_string, "\n\n", 'parse 2 crlf only' );
# is( $m->content, "\n" );
is( $m, undef, 'bad request cannot be parsed: only 2 new lines' );
is( HTTP::Promise::Message->error->code, 400, 'bad request error code' );

$m = HTTP::Promise::Message->parse( 'foo', debug => $DEBUG );
# is( $m->as_string, "${CRLF}foo", 'parse no header' );
is( $m, undef, 'bad request cannot be parsed: no header' );
$m = HTTP::Promise::Message->parse( "foo: 1\n\n", debug => $DEBUG );
diag( "Error parsing: ", HTTP::Promise::Message->error ) if( $DEBUG && !defined( $m ) );
is( $m->as_string, "Foo: 1${CRLF}${CRLF}" );
$m = HTTP::Promise::Message->parse( "foo_bar: 1\n", debug => $DEBUG );
diag( "Error parsing: ", HTTP::Promise::Message->error ) if( $DEBUG && !defined( $m ) );
# is( $m->as_string, "Foo-Bar: 1\n\n" );
is( $m, undef, 'bad request cannot be parsed: missing 2 crlf to separate headers' );
$m = HTTP::Promise::Message->parse( "foo: 1\nfoo", debug => $DEBUG );
diag( "Error parsing: ", HTTP::Promise::Message->error ) if( $DEBUG && !defined( $m ) );
# is( $m->as_string, "Foo: 1${CRLF}${CRLF}foo\n" );
is( $m, undef, 'bad request cannot be parsed: missing 2 crlf to separate headers' );
$m = HTTP::Promise::Message->parse( <<EOT, debug => $DEBUG );
Foo: 1 2 3 4
bar: 1
Baz: 1

foobarbaz
EOT
diag( "Error parsing: ", HTTP::Promise::Message->error ) if( $DEBUG && !defined( $m ) );
is( $m->as_string, join( $CRLF, split( /\n/, <<EOT, -1 ) ) . "foobarbaz\n", 'order of headers' );
Bar: 1
Baz: 1
Foo: 1 2 3 4

EOT

$m = HTTP::Promise::Message->parse( <<EOT, debug => $DEBUG );
Date: Fri, 18 Feb 2005 18:33:46 GMT
Connection: close
Content-Type: text/plain

foo:bar
second line
EOT
is( $m->content, <<EOT, 'body only' );
foo:bar
second line
EOT
$m->content( '' );
is( $m->as_string, join( $CRLF, split( /\n/, <<EOT, -1 ) ), 'headers only' );
Connection: close
Date: Fri, 18 Feb 2005 18:33:46 GMT
Content-Type: text/plain

EOT

$m = HTTP::Promise::Message->parse( "  abc\nfoo: 1\n", debug => $DEBUG );
# is( $m->as_string, "\n  abc\nfoo: 1\n" );
is( $m, undef, 'bad request cannot be parsed: missing headers' );
$m = HTTP::Promise::Message->parse( " foo : 1\n", debug => $DEBUG );
# is( $m->as_string, "\n foo : 1\n" );
is( $m, undef, 'bad request cannot be parsed: space at start is not allowed -> missing headers' );
$m = HTTP::Promise::Message->parse( "\nfoo: bar\n", debug => $DEBUG );
# is( $m->as_string, "\nfoo: bar\n");
is( $m, undef, 'bad request cannot be parsed: crlf at start is not allowed -> missing headers' );

$m = HTTP::Promise::Message->new( [ a => 1, b => 2 ], 'abc', { debug => $DEBUG } );
is( $m->content, 'abc' );
$m->content( "foo\n" );
is( $m->content, "foo\n" );

$m->add_content( 'bar' );
is( $m->content, "foo\nbar" );
$m->add_content( \"\n" );
is( $m->content, "foo\nbar\n" );

is( Scalar::Util::reftype( $m->content_ref ), 'SCALAR', 'returning content as scalar reference' );
is( ${$m->content_ref}, "foo\nbar\n", 'content reference' );
$m->entity->body->replace( qr/[ao]/, 'i' );
# ${$m->content_ref} =~ s/[ao]/i/g;
is( $m->content, "fii\nbir\n", 'body->replace' );

$m->clear;
is( $m->headers->header_field_names, 0 );
is( $m->content, '' );

is( $m->parts->first, undef, 'no part' );
# $m->debug( $DEBUG ) if( $DEBUG );
# $m->parts(
#     HTTP::Promise::Message->new,
#     HTTP::Promise::Message->new( [a => 1], 'foo' ),
#     HTTP::Promise::Message->new( undef, "bar\n" ),
# );
my $p1 = HTTP::Promise::Message->new( { debug => $DEBUG } );
diag( "Error setting part #1 object: ", HTTP::Promise::Message->error ) if( $DEBUG && !defined( $p1 ) );
my $p2 = HTTP::Promise::Message->new( [a => 1], 'foo', { debug => $DEBUG } );
diag( "Error setting part #2 object: ", HTTP::Promise::Message->error ) if( $DEBUG && !defined( $p2 ) );
my $p3 = HTTP::Promise::Message->new( undef, "bar\n", { debug => $DEBUG } );
diag( "Error setting part #3 object: ", HTTP::Promise::Message->error ) if( $DEBUG && !defined( $p3 ) );
isa_ok( $p1 => ['HTTP::Promise::Message'], 'part #1 is a HTTP::Promise::Message object' );
isa_ok( $p2 => ['HTTP::Promise::Message'], 'part #2 is a HTTP::Promise::Message object' );
isa_ok( $p3 => ['HTTP::Promise::Message'], 'part #3 is a HTTP::Promise::Message object' );
$parts = $m->parts( $p1, $p2, $p3 );
diag( "Setting parts resulted in an error: ", $m->error ) if( $DEBUG && !defined( $parts ) );
isa_ok( $parts => [ 'Module::Generic::Array' ] );
isa_ok( $parts->first => ['HTTP::Promise::Entity'] );
diag( "Is first part (", $parts->first, ") same as part #1 (", $p1->entity, ") ?" ) if( $DEBUG );
is( Scalar::Util::refaddr( $parts->first ), Scalar::Util::refaddr( $p1->entity ) );

is( $m->parts->first->as_string, "${CRLF}", 'parts as string' );

my $str = $m->as_string;
my $boundary = $m->boundary;
$str =~ s/\r/<CR>/g;
is( $str, <<EOT );
Content-Type: multipart/mixed; boundary=${boundary}<CR>
<CR>
--${boundary}<CR>
<CR>
<CR>
--${boundary}<CR>
A: 1<CR>
<CR>
foo<CR>
--${boundary}<CR>
<CR>
bar
<CR>
--${boundary}--<CR>
EOT

$m2 = HTTP::Promise::Message->new( { debug => $DEBUG } );
$m2->parts( $m );
diag( "Encapsulated object ($m) boundary is '", $m->boundary, "'" ) if( $DEBUG );
# $boundary = $m2->boundary;
$str = $m2->as_string;
diag( "Top object ($m2) boundary is '", $m2->boundary, "'" ) if( $DEBUG );
$str =~ s/\r/<CR>/g;
ok( $str =~ /boundary=(\S+)/ );
my $boundary2 = $m2->boundary;

is( $str, <<EOT );
Content-Type: multipart/mixed; boundary=${boundary2}<CR>
<CR>
--${boundary2}<CR>
Content-Type: multipart/mixed; boundary=${boundary}<CR>
<CR>
--${boundary}<CR>
<CR>
<CR>
--${boundary}<CR>
A: 1<CR>
<CR>
foo<CR>
--${boundary}<CR>
<CR>
bar
<CR>
--${boundary}--<CR>
<CR>
--${boundary2}--<CR>
EOT

$parts = $m2->parts;
is( $parts->length, 1 );

$parts = $parts->first->parts;
is( $parts->length, 3 );
is( $parts->[1]->header( 'A' ), 1 );

$m2->parts( [ HTTP::Promise::Message->new ] );
$parts = $m2->parts;
is( $parts->length, 1 );

$m2->parts( [] );
$parts = $m2->parts;
is( $parts->length, 0 );

$m->clear;
$m2->clear;

# diag( "Testing parsing get request." ) if( $DEBUG );
$m = HTTP::Promise::Message->new( [ content_type => "message/http; boundary=aaa", ], <<EOT, { debug => $DEBUG } );
GET / HTTP/1.1
Host: www.example.com:8008

EOT

diag( "HTTP message is:\n", $m->as_string ) if( $DEBUG );

$parts = $m->parts;
is( $parts->length, 1, 'number of parts' );
$m2 = $parts->[0];
isa_ok( $m2 => ['HTTP::Promise::Entity'], 'part is an entity object' );
SKIP:
{
    skip( 'No part object defined', 6 ) unless( defined( $m2 ) );
    my $msg = $m2->http_message;
    isa_ok( $msg => ['HTTP::Promise::Request'], 'http message is an HTTP::Promise::Request object' );
    is( $msg->method, 'GET', 'method is GET' );
    is( $msg->uri, '/', 'uri is /' );
    is( $msg->protocol, 'HTTP/1.1', 'protocol is HTTP/1.1' );
    is( $msg->header( 'Host' ), 'www.example.com:8008' );
    is( $msg->content, '', 'no content' );
};

diag( "Changing content to HTTP/1.0 200 OK\\nContent-Type: text/plain\\n\\nHello\\n" ) if( $DEBUG );
$m->content( <<EOT );
HTTP/1.0 200 OK
Content-Type: text/plain

Hello
EOT

diag( "Entity is:\n", $m->as_string ) if( $DEBUG );

diag( "Check 1. There are ", $m->parts->length, " parts found." ) if( $DEBUG );
$m2 = $m->parts->[0];
isa_ok( $m2 => ['HTTP::Promise::Entity'], 'part is an entity object' );
SKIP:
{
    skip( 'No part object defined', 6 ) unless( defined( $m2 ) );
    my $msg = $m2->http_message;
    diag( "Part as string is: '", $msg->as_string, "'" ) if( $DEBUG );
    is( $msg->protocol, 'HTTP/1.0', 'protocol is HTTP/1.0' );
    is( $msg->code, '200', 'code is 200' );
    is( $msg->status, 'OK', 'status is OK' );
    is( $msg->content_type, 'text/plain', 'mime-type is text/plain' );
    is( $msg->content, "Hello\n", 'content is Hello\n' );
};
diag( "Check 2. There are ", $m->parts->length, " parts found." ) if( $DEBUG );
diag( "HTTP message is:\n", $m->as_string ) if( $DEBUG );

$parts = $m->parts( HTTP::Promise::Message->new, HTTP::Promise::Message->new );
diag( "Error message is: ", $m->error ) if( $DEBUG && !defined( $parts ) );
ok( !defined( $parts ) && $m->error->message, 'only 1 part possible for message/http' );

$m->entity->debug( $DEBUG );
# Current type is message/http and now we add a new part, which will change the type to multipart/form-data and shift the current content as a top part.
diag( "Calliing \$m->add_part" ) if( $DEBUG );
$rv = $m->add_part( HTTP::Promise::Message->new( [ a => [1..3] ], 'a' ) );
diag( "is \$rv from add_part an HTTP::Promise::Message object ?" ) if( $DEBUG );
isa_ok( $rv => ['HTTP::Promise::Message'], 'add_part returns the message object' );
diag( "Error adding part: ", $m->error ) if( $DEBUG && !defined( $rv ) );
is( $m->parts->length, 2, 'number of parts' );
$boundary = $m->boundary;
$str = $m->as_string;
$str =~ s/\r/<CR>/g;
is( $str, <<EOT, 'message as string ater adding part' );
Content-Type: multipart/form-data; boundary=${boundary}<CR>
<CR>
--${boundary}<CR>
Content-Type: message/http; boundary=aaa<CR>
Content-Disposition: form-data; name="part1"<CR>
<CR>
HTTP/1.0 200 OK<CR>
Content-Type: text/plain<CR>
<CR>
Hello
<CR>
--${boundary}<CR>
A: 1<CR>
A: 2<CR>
A: 3<CR>
Content-Disposition: form-data; name="part2"<CR>
<CR>
a<CR>
--${boundary}--<CR>
EOT

# Now, force it to be a multipart/mixed
$m->content_type( 'multipart/mixed' );

$m->add_part( HTTP::Promise::Message->new( [ b => [1..3] ], 'b' ) );
$boundary = $m->boundary;
$str = $m->as_string;
$str =~ s/\r/<CR>/g;
is( $str, <<EOT, 'adding part in an explicit multipart/mixed structure' );
Content-Type: multipart/mixed; boundary=${boundary}<CR>
<CR>
--${boundary}<CR>
Content-Type: message/http; boundary=aaa<CR>
<CR>
HTTP/1.0 200 OK<CR>
Content-Type: text/plain<CR>
<CR>
Hello
<CR>
--${boundary}<CR>
A: 1<CR>
A: 2<CR>
A: 3<CR>
<CR>
a<CR>
--${boundary}<CR>
B: 1<CR>
B: 2<CR>
B: 3<CR>
<CR>
b<CR>
--${boundary}--<CR>
EOT

$m = HTTP::Promise::Message->new({ debug => $DEBUG });
$m->add_part( HTTP::Promise::Message->new( [ a => [1..3] ], 'a' ) );
$boundary = $m->boundary;
is( $m->header( 'Content-Type' ), "multipart/form-data; boundary=${boundary}" );
$str = $m->as_string;
$str =~ s/\r/<CR>/g;
is( $str, <<EOT, 'default form-data upon adding part' );
Content-Type: multipart/form-data; boundary=${boundary}<CR>
<CR>
--${boundary}<CR>
A: 1<CR>
A: 2<CR>
A: 3<CR>
Content-Disposition: form-data; name="part1"<CR>
<CR>
a<CR>
--${boundary}--<CR>
EOT

$m = HTTP::Promise::Message->new( [ 'Content-Type' => 'multipart/mixed' ], { debug => $DEBUG } );
$m->add_part( HTTP::Promise::Message->new( [], 'foo and a lot more content', { debug => $DEBUG } ) );
$boundary = $m->boundary;
is( $m->header( 'Content-Type' ), "multipart/mixed; boundary=${boundary}" );
$parts = $m->parts;
is( $parts->[0]->body->as_string, 'foo and a lot more content' );
like( $parts->[0]->dump( maxlength => 4 ), qr/foo \.\.\./, 'dump max 4 bytes' );
like( $parts->[0]->dump( maxlength => 0 ), qr/foo and a lot/, 'dump no limit' );
$rv = $m->encode;
ok( !defined( $rv ) && $m->error->message =~ /Cannot encode multipart/ );
$m->content_type( 'message/http' );
$rv = $m->encode;
ok( !defined( $rv ) && $m->error->message =~ /Cannot encode message/ );

$m = HTTP::Promise::Message->new( { debug => $DEBUG } );
my $foo = 'foo';
my $ref = $m->content_ref( \$foo );
is( $m->content, 'foo', 'content_ref' );
my $foo2 = $m->content( 'bar' );
isa_ok( $foo2 => ['HTTP::Promise::Body::Scalar'] );
is( $foo2->as_string, 'bar' );
is( $m->content, 'bar' );
my $content_ref = $m->content_ref;
SKIP:
{
    skip( 'content_ref not set.', 2 ) if( !ref( $content_ref ) );
    is( Scalar::Util::reftype( $content_ref ), 'SCALAR', 'value returned by content_ref is a scalar object' );
    is( $$content_ref, 'bar' );
};

$m = HTTP::Promise::Message->new( { debug => $DEBUG } );
$m->content( 'fo=6F' );
$m->entity->is_encoded(1);
my $decoded = $m->decoded_content;
diag( "Error decoding: ", $m->error ) if( $DEBUG && !defined( $decoded ) );
is( $decoded, 'fo=6F', 'content enchanged without Content-Encoding set' );
$m->header( 'Content-Encoding', 'quoted-printable' );
is( $m->decoded_content, 'foo' );

for my $encoding ( qw/gzip x-gzip/ )
{
	$m = HTTP::Promise::Message->new( { debug => $DEBUG } );
	$m->header( 'Content-Encoding', "$encoding, base64" );
	$m->entity->is_encoded(1);
	$m->content_type( 'text/plain; charset=UTF-8' );
	$m->content( "H4sICFWAq0ECA3h4eAB7v3u/R6ZCSUZqUarCoxm7uAAZKHXiEAAAAA==\n" );

    my $decoded_content = $m->decoded_content( binmode => 'utf8', replace => 0 );
    # my $decoded_content = $m->decoded_content;
    diag( "Is content in decoded utf8? ", ( utf8::is_utf8( $decoded_content ) ? 'yes' : 'no' ) ) if( $DEBUG );
    ok( defined( $decoded_content ), 'content was decoded' );
    # \x{FEFF} is invisible no-break space and \x{263A} is a smiley
	is( $decoded_content, "\x{FEFF}Hi there \x{263A}\n", 'decoded utf-8 content' );
	is( $m->content->scalar, "H4sICFWAq0ECA3h4eAB7v3u/R6ZCSUZqUarCoxm7uAAZKHXiEAAAAA==\n", 'original content unchanged' );

	$m2 = $m->clone;
	isa_ok( $m2 => ['HTTP::Promise::Message'] );
	diag( "Error cloning HTTP::Promise::Message object: ", $m->error ) if( $DEBUG && !defined( $m2 ) );
	SKIP:
	{
        skip( 'clone did not return an HTTP::Promise::Message object.', 3 ) if( !defined( $m2 ) );
        ok( $m2->entity->is_encoded, 'entity body is encoded' );
        ok( $m2->decode, 'decoded entity body' );
        ok( !$m2->entity->is_encoded, 'entity body is not encoded' );
        # is( $m2->header( 'Content-Encoding' ), undef );
        like( $m2->content, qr/Hi there/, 'content check after decoding' );
	};

    diag( "List of supported encodings: '", $m->decodable->join( "', '" )->scalar, "'" ) if( $DEBUG );
	# ok( grep{ $_ eq "$encoding" } $m->decodable->list, "$encoding is among decodable encodings" );
	ok( $m->is_encoding_supported( $encoding ), "$encoding is supported" );

    #diag( "Base64 encoding '", $m->content->scalar, "'" ) if( $DEBUG );
	#my $tmp = Crypt::Misc::decode_b64( $m->content->scalar );
	#$m->content( $tmp );
	# $m->header( 'Content-Encoding', "$encoding" );
	# $m->debug( $DEBUG ) if( $DEBUG );
    $decoded_content = $m->decoded_content( binmode => 'utf8' );
    diag( "Error decoding content: ", $m->error ) if( $DEBUG && !defined( $decoded_content ) );
    ok( defined( $decoded_content ), 'decoded content defined' );
	is( $decoded_content, "\x{FEFF}Hi there \x{263A}\n", 'decoded content check' );
	
	# is( $m->content, $tmp );

	my $m2 = HTTP::Promise::Message->new([
	    'Content-Type' => 'text/plain',
	    ],
	    "Hi there\n",
	    { debug => $DEBUG },
	);
	$rv = $m2->encode( $encoding, update_header => 1 );
	diag( "Error encoding: ", $m2->error ) if( $DEBUG && !defined( $rv ) );
	ok( $rv, "encoding content using $encoding" );
	is( $m2->header( 'Content-Encoding' ), $encoding, "Content-Encoding is $encoding" );
	is( $m2->headers->content_encoding, $encoding, "content_encoding returns $encoding" );
	unlike( $m2->content->scalar, qr/Hi there/ );
	# $m2->debug( $DEBUG ) if( $DEBUG );
	diag( "Decoding content." ) if( $DEBUG );
	$decoded_content = $m2->decoded_content( binmode => 'utf8', replace => 0 );
	diag( "Error decoding content: ", $m2->error ) if( $DEBUG && !defined( $decoded_content ) );
	is( $decoded_content, "Hi there\n", 'decoded content check' );
	ok( $m2->decode, 'decode content' );
	is( $m2->content, "Hi there\n", 'decoded content check' );
}

$m->remove_header( 'Content-Encoding' );
$m->content( "a\x{FF}" );
$m->entity->debug( $DEBUG );

diag( "Content-Type is '", $m->headers->content_type, "'" ) if( $DEBUG );
$io_layer = $m->entity->io_encoding;
is( $io_layer, 'utf-8', 'io encoding' );
# This returns by default the utf decoded, since we did not specify any binmode
$decoded_content = $m->decoded_content( replace => 0 );
diag( "Is \$decoded_content in perl utf8? ", ( utf8::is_utf8( $$decoded_content ) ? 'yes' : 'no' ) ) if( $DEBUG );
if( $DEBUG )
{
    my $utf8_data = $$decoded_content;
    $utf8_data =~ s/([\N{U+0080}-\N{U+FFFF}\n])/sprintf('\\x{%X}',ord($1))/eg;
    diag( "utf string returned: '$utf8_data'" );
}
# Loose decoding (non-strict) of utf8 \x{FF} becomes \x{FFFD}, 
# although strictly this is forbidden in normal utf-8
is( "$decoded_content", "a\x{FFFD}", 'guessed utf8 content check' );

$io_layer = $m->entity->io_encoding( charset_strict => 1 );
is( $io_layer, undef, 'strict io encoding returns undef' );
is( $m->decoded_content( charset_strict => 1 )->scalar, "a\x{FF}", 'decoded_content returns body content unaltered' );

$m->header( 'Content-Encoding', 'foobar' );
$m->entity->is_encoded(1);
$decoded_content = $m->decoded_content;
is( ( defined( $decoded_content ) ? "$decoded_content" : '' ), '', 'failed decoding content' );
like( $m->error->message, qr/^Decoding provided "foobar" is unsupported/, 'error->message for unsupported encoding' );

my $err = 0;
eval
{
    $m->decoded_content( raise_error => 1 );
    $err++;
};
diag( "\$@ is '$@'" );
like( $@->message, qr/Decoding provided "foobar" is unsupported/, '$@->message for unsupported encoding' );
is( $err, 0 );

$rv = HTTP::Promise::Message->new( [], "\x{263A}", { debug => $DEBUG } );
ok( !defined( $rv ) );
like( HTTP::Promise::Message->error->message, qr/bytes/ );
$m = HTTP::Promise::Message->new( { debug => $DEBUG } );
$rv = $m->add_content( "\x{263A}" );
ok( !defined( $rv ) );
like( $m->error->message, qr/bytes/ );
$rv = $m->content( "\x{263A}" );
ok( !defined( $rv ) );
like( $m->error->message, qr/bytes/ );

# test the add_content_utf8 method
{
    $m = HTTP::Promise::Message->new( [ 'Content-Type', 'text/plain; charset=UTF-8' ], { debug => $DEBUG } );
    my $body = $m->add_content_utf8( "\x{263A}" );
    isa_ok( $body => ['HTTP::Promise::Body'] );
    diag( "An error occurred adding utf8 content: ", $m->error ) if( $DEBUG && !defined( $body ) );
    $body = $m->add_content_utf8( "-\xC5" );
    diag( "An error occurred adding utf8 content: ", $m->error ) if( $DEBUG && !defined( $body ) );
    isa_ok( $body => ['HTTP::Promise::Body'] );
    my $content = $m->content;
    is( "$content", "\xE2\x98\xBA-\xC3\x85", 'resulting utf8 content added' );
    is( $m->decoded_content( binmode => 'utf-8' ), "\x{263A}-\x{00C5}", 'resulting decoded utf8 content added' );
}

$m = HTTP::Promise::Message->new([
    'Content-Type' => 'text/plain',
    ],
    'Hello world!',
    { debug => $DEBUG },
);
$m->content_length( $m->content->length );
$m->encode( 'deflate', update_header => 1 );
$m->dump( prefix => '# ' );
is( $m->dump( prefix => '| ' ), join( "| \n", <<EOT1, <<'EOT2' ), 'dump with prefix' );
| Content-Encoding: deflate\r
| Content-Type: text/plain\r
EOT1
| x\x9C\xF3H\xCD\xC9\xC9W(\xCF/\xCAIQ\4\0\35\t\4^
EOT2
for my $encoding ( qw/identity none/ )
{
	my $m2 = $m->clone;
	$m2->encode( 'base64', $encoding );
	is( $m2->as_string, join( $CRLF, split( /\n/, <<"EOT", -1 ) ) . "eJzzSM3JyVcozy/KSVEEAB0JBF4=" );
Content-Encoding: deflate, base64, $encoding
Content-Type: text/plain

EOT
	is( $m2->decoded_content, 'Hello world!' );
}

# Raw RFC 1951 deflate
$m = HTTP::Promise::Message->new([
    'Content-Type' => 'text/plain',
    'Content-Encoding' => 'deflate, base64',
    ],
    '80jNyclXCM8vyklRBAA=',
    { debug => $DEBUG }
);
$m->entity->is_encoded(1);
$m->debug( $DEBUG ) if( $DEBUG );
$decoded_content = $m->decoded_content;
diag( "Error decoding content: ", $m->error ) if( $DEBUG && !defined( $decoded_content ) );
is( $decoded_content, 'Hello World!', 'decoded content from base64 and deflate' );
ok( !$m->header( 'Client-Warning' ) );

if( HTTP::Promise::Stream->load( 'bzip2' ) )
{
	for my $encoding ( qw( x-bzip2 bzip2 ) )
	{
	    my $m = HTTP::Promise::Message->new([
	        'Content-Type' => 'text/plain',
	        'Content-Encoding' => "$encoding, base64",
	        ],
            "QlpoOTFBWSZTWcvLx0QAAAHVgAAQYAAAQAYEkIAgADEAMCBoYlnQeSEMvxdyRThQkMvLx0Q=\n",
            { debug => $DEBUG },
	    );
	    isa_ok( $m => ['HTTP::Promise::Message'], "object created with encodings $encoding, base64" );
	    SKIP:
	    {
	        skip( 'Cannot create HTTP::Promise::Message object', 3 );
            is( $m->decoded_content( replace => 0 ), "Hello world!\n", 'decoded content' );
            ok( $m->decode, 'decode' );
            is( $m->content, "Hello world!\n", 'content after decode()' );
	    };
	
        $m = HTTP::Promise::Message->new([
            'Content-Type' => 'text/plain',
            ],
            'Hello world!',
            { debug => $DEBUG },
        );
	    isa_ok( $m => ['HTTP::Promise::Message'], "object created with plain content" );
	    SKIP:
	    {
	        skip( 'Cannot create HTTP::Promise::Message object', 6 );
            ok( $m->encode( $encoding ), "encode( $encoding )" );
            is( $m->header( 'Content-Encoding' ), $encoding, 'Content-Encoding header added' );
            like( $m->content, qr/^BZh.*\0/, "encoded content with $encoding" );
            is( $m->decoded_content( replace => 0 ), 'Hello world!', 'decoded_content' );
            ok( $m->decode, 'decode' );
            is( $m->content, 'Hello world!', 'content after decode()' );
        };
	}
}
else
{
    skip( 'Need IO::Compress::Bzip2 and IO::Uncompress::Bunzip2', 18 );
}

# test decoding of XML content
$m = HTTP::Promise::Message->new(
    [ 'Content-Type', 'application/xml' ],
    "\xFF\xFE<\0?\0x\0m\0l\0 \0v\0e\0r\0s\0i\0o\0n\0=\0\"\x001\0.\x000\0\"\0 \0e\0n\0c\0o\0d\0i\0n\0g\0=\0\"\0U\0T\0F\0-\x001\x006\0l\0e\0\"\0?\0>\0\n\0<\0r\0o\0o\0t\0>\0\xC9\0r\0i\0c\0<\0/\0r\0o\0o\0t\0>\0\n\0",
    { debug => $DEBUG }
);
is( $m->decoded_content, qq{<?xml version="1.0"?>\n<root>\xC9ric</root>\n}, 'UTF-16le decoded content' );

# DESTROY is a no-op
$m->DESTROY;
is( $m->decoded_content, qq{<?xml version="1.0"?>\n<root>\xC9ric</root>\n}, 'UTF-16le decoded content after DESTROY' );

$m = HTTP::Promise::Message->new([
    'Content-Type' => 'text/plain',
    ],
    "Hello World!\n",
    { debug => $DEBUG }
);
is( $m->content, "Hello World!\n", 'content' );
ok( $m->encode(), 'encode' );
is( $m->content, "Hello World!\n", 'content unchanged with no encoding' );
is( $m->encode( 'not-an-encoding' ), undef, 'encode fail with bad encoding' );
is( $m->content, "Hello World!\n", 'content unchanged with bad encoding' );

for my $encoding ( qw( compress x-compress ) )
{
    $m = HTTP::Promise::Message->new([
        'Content-Type' => 'text/plain',
        'Content-Encoding' => $encoding,
        ],
        'foo',
        { debug => $DEBUG },
    );
    isa_ok( $m => ['HTTP::Promise::Message'], "object created with encoding $encoding, but plain content" );
    SKIP:
    {
        skip( 'Cannot create HTTP::Promise::Message object', 1 );
        eval{ $m->decoded_content( raise_error => 1 ); };
        like( $@, qr/Cannot uncompress content/, "cannot uncompress uncompressed content" );
	};
}

$m = HTTP::Promise::Message->new( 'bad-header' );
ok( !defined( $m ), 'failed to create object with bad header' );
like( HTTP::Promise::Message->error->message, qr/Bad header argument/, 'bad header error message' );
$m = HTTP::Promise::Message->new( [ 'Content-Encoding' => 'foo' ], 'Hello world', { debug => $DEBUG } );
isa_ok( $m => ['HTTP::Promise::Message'], "object created with bad encoding foo" );
is( $m->decode, undef, 'decode with encoding foo failed' );

$m = HTTP::Promise::Message->new( { debug => $DEBUG } );
isa_ok( $m => ['HTTP::Promise::Message'], "dummy object created" );
ok( $m->decode, 'decode' );
$body = $m->content( undef );
isa_ok( $body => ['HTTP::Promise::Body'], 'content is reset and an HTTP::Promise::Body is returned' );
ok( $m->entity->body->is_empty, 'body is empty' );
$rv = $m->content( [] );
ok( !defined( $rv ), 'content() failed when provided with an array' );
like( $m->error->message, qr/I was expecting a string or a scalar reference, but instead got/, 'content() error message' );

$m = HTTP::Promise::Message->new( [ 'Content-Type' => 'text/plain',], "\xEF\xBB\xBFaa/", { debug => $DEBUG } );
isa_ok( $m => ['HTTP::Promise::Message'], "object created with utf-8 content to be guessed." );
is( $m->content_charset, 'UTF-8', 'content_charset correctly guessed utf-8' );
diag( 'changing content to UTF-32LE data' ) if( $DEBUG );
$m->content( "\xFF\xFE\x00\x00aa/" );
is( $m->content_charset, "UTF-32LE", 'content_charset correctly guessed UTF-32LE' );
diag( 'changing content to UTF-32BE data' ) if( $DEBUG );
$m->content( "\x00\x00\xFE\xFFaa/" );
is( $m->content_charset, "UTF-32BE", 'content_charset correctly guessed UTF-32BE' );
diag( 'changing content to UTF-16LE data' ) if( $DEBUG );
$m->content( "\xFF\xFEaa/" );
is( $m->content_charset, "UTF-16LE", 'content_charset correctly guessed UTF-16LE' );
diag( 'changing content to UTF-16BE data' ) if( $DEBUG );
$m->content( "\xFE\xFFaa/" );
is( $m->content_charset, "UTF-16BE", 'content_charset correctly guessed UTF-16BE' );

{
    $m = HTTP::Promise::Message->new( { debug => $DEBUG } );
    local $@ = 'pre-existing error';
    $m->decodable;
    is( $@, 'pre-existing error', 'decodable() does not overwrite $@' );
}

$m = HTTP::Promise::Message->new([
    'User-Agent' => 'Mozilla/5.0',
    'Referer' => 'https://example.com/',
    { debug => $DEBUG }
]);
ok( $m->can( 'content' ), 'can content()' );
my $method = $m->can( 'user_agent' );
is( ref( $method ), 'CODE', 'can user_agent from HTTP::Promise::Headers' );
is( HTTP::Promise::Message->can( 'user_agent' ), $method, 'user_agent code reference' );
is( $m->$method, 'Mozilla/5.0', 'user_agent value retrieved' );

ok( HTTP::Promise::Message->can( 'content' ), 'content() as a class function' );
$method = HTTP::Promise::Message->can( 'referrer' );
is( ref( $method ), 'CODE', 'referrer code reference' );
is( $m->can( 'referrer' ), $method, 'can referrer' );
is( $m->$method, 'https://example.com/', 'referrer value retrieved' );

eval{ $m->unknown_method; };
like( $@, qr/Method unknown_method\(\) is not defined in class HTTP::Promise::Message/, 'trapping $m->unknown_method' );
is( $m->can( 'unknown_method' ), undef, 'can not unknown_method using object' );
eval{ HTTP::Promise::Message->unknown_method; };
like( $@, qr/Method unknown_method\(\) is not defined in class HTTP::Promise::Message/, 'trapping HTTP::Promise::Message->unknown_method' );
is( HTTP::Promise::Message->can( 'unknown_method' ), undef, 'can not unknown_method as class function' );
eval{ my $empty = ''; $m->$empty; };
like( $@, qr/Method \(\) is not defined in class HTTP::Promise::Message/, 'cannot call null method' );

done_testing();

__END__

