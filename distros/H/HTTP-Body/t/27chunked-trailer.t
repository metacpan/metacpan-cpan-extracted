#!perl

use strict;
use warnings;

use Test::More tests => 20;

use HTTP::Body;

my $ct = 'application/x-www-form-urlencoded';

# The trailing headers, or none while there is no trailer.
sub trailer { my $h = shift->trailing_headers; return $h ? $h : HTTP::Headers->new }

# The trailer of a chunked body used to be read only from the call to add()
# that carried the last chunk; a trailer that arrived in a later call was lost.
{
    my $body = HTTP::Body->new( $ct, undef );
    $body->add("3\r\na=b\r\n0\r\n");
    is( $body->state, 'done', 'the body is done at the last chunk' );
    is_deeply( $body->param, { a => 'b' }, '... with its parameters' );
    is( $body->trailing_headers, undef, 'no trailer before it has arrived' );

    $body->add("X-Foo: bar\r\n");
    isa_ok( $body->trailing_headers, 'HTTP::Headers', 'trailer from a later add' );
    is( trailer($body)->header('X-Foo'), 'bar', '... with its field' );

    $body->add("X-Baz: qux\r\n\r\n");
    is( trailer($body)->header('X-Baz'), 'qux', '... and the fields that follow it' );
}

# Some clients never send the blank line that ends the trailer; what has
# arrived of it is read all the same, as it was before.
{
    my $body = HTTP::Body->new( $ct, undef );
    $body->add("3\r\na=b\r\n0\r\nContent-MD5: abc\r\nX-Half");
    is( trailer($body)->header('Content-MD5'), 'abc', 'a trailer without its blank line' );
    is( trailer($body)->header('X-Half'), undef, '... but not a line still incomplete' );
}

{
    my $body = HTTP::Body->new( $ct, undef );
    $body->add($_) for split //, "3\r\na=b\r\n0\r\nX-Foo: bar\r\nX-Baz: qux\r\n\r\n";
    is( trailer($body)->header('X-Foo'), 'bar', 'trailer fed byte by byte' );
    is( trailer($body)->header('X-Baz'), 'qux', '... has all its fields' );
}

{
    my $body = HTTP::Body->new( $ct, undef );
    $body->add("3\r\na=b\r\n0\r\n\r\n");
    isa_ok( $body->trailing_headers, 'HTTP::Headers', 'an empty trailer' );
    is( scalar trailer($body)->header_field_names, 0, '... has no fields' );
}

# The blank line ends the body: nothing after it is read as a trailer field.
{
    my $body = HTTP::Body->new( $ct, undef );
    $body->add("3\r\na=b\r\n0\r\nX-Foo: bar\r\n\r\nX-Evil: 1\r\n");
    $body->add("X-Evil2: 1\r\n\r\n");
    is_deeply( [ trailer($body)->header_field_names ], ['X-Foo'], 'nothing after the trailer is read' );
    is( length $body->{chunk_buffer}, 0, '... or kept' );
}

# The trailer is collected until its blank line, so it is limited in size.
{
    my $body = HTTP::Body->new( $ct, undef );
    $body->add("3\r\na=b\r\n0\r\n");
    eval { $body->add( 'X-Foo: ' . ( 'b' x 991 ) . "\r\n" ) for 1 .. 40 };
    like( $@, qr/trailer exceeds 32768 bytes/, 'a trailer over the size limit is refused' );
}

{
    my $body = HTTP::Body->new( $ct, undef );
    $body->add("3\r\na=b\r\n0\r\n");
    eval { $body->add( 'X' x 1000 ) for 1 .. 40 };
    like( $@, qr/trailer exceeds 32768 bytes/, 'an unterminated trailer line over the limit is refused' );
}

# HTTP::Headers takes time quadratic in the number of fields of one name,
# which made a trailer of 16 KiB of "a:" lines cost seconds; and 1.24 parsed
# whatever followed the last chunk in the same call to add().
{
    my $body = HTTP::Body->new( $ct, undef );
    $body->add("3\r\na=b\r\n0\r\n");
    eval { $body->add("a:\r\n") for 1 .. 101 };
    like( $@, qr/trailer exceeds 100 lines/, 'a trailer over the line limit is refused' );
}

{
    my $body = HTTP::Body->new( $ct, undef );
    $body->add( "3\r\na=b\r\n0\r\n" . ( "a:\r\n" x 100 ) . "\r\n" );
    is( scalar( () = trailer($body)->header('a') ), 100, 'a trailer at the line limit is read' );
}

{
    local $HTTP::Body::max_trailer_size  = 0;
    local $HTTP::Body::max_trailer_lines = 0;
    my $body = HTTP::Body->new( $ct, undef );
    $body->add("3\r\na=b\r\n0\r\n");
    eval { $body->add( 'X-Foo: ' . ( 'b' x 991 ) . "\r\n" ) for 1 .. 200; $body->add("\r\n") };
    is( $@, '', 'the trailer limits can be disabled' );
    is( scalar( () = trailer($body)->header('X-Foo') ), 200, '... and the whole trailer is read' );
}
