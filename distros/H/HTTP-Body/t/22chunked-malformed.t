#!perl

use strict;
use warnings;

use Test::More tests => 12;

use HTTP::Body;

my $ct = 'application/octet-stream';

# A line that is not a chunk-size line used to end the parse silently, with
# every later add() growing the chunk buffer forever.
{
    my $body = HTTP::Body->new( $ct, undef );
    eval { $body->add("zzz\r\n") };
    like( $@, qr/Invalid chunk size line/, 'a line that is no chunk-size line is refused' );
}

{
    my $body = HTTP::Body->new( $ct, undef );
    eval { $body->add( '1' x 2000 ) };
    like( $@, qr/Chunk size line exceeds/, 'an unterminated chunk-size line over the limit is refused' );
}

{
    local $HTTP::Body::max_chunk_line_size = 0;
    my $body = HTTP::Body->new( $ct, undef );
    eval { $body->add( '1' x 2000 ) };
    is( $@, '', 'the chunk-size line limit can be disabled' );
}

{
    my $body = HTTP::Body->new( $ct, undef );
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    eval { $body->add( ( 'F' x 40 ) . "\r\n" ) };
    like( $@, qr/Chunk size too large/, 'a chunk size beyond the integer range is refused' );
    is( scalar @warnings, 0, '... without an overflow warning' );
}

# A chunk used to be held back until it had arrived completely, so a large
# chunk needed as much memory as it was long.
{
    my $body = HTTP::Body->new( $ct, undef );
    $body->add( sprintf "%x\r\n", 1_000_000 );
    $body->add( 'x' x 8192 ) for 1 .. 10;
    is( $body->length, 81920, 'chunk data reaches the body before the chunk is complete' );
}

{
    my $body = HTTP::Body->new( $ct, undef );
    eval { $body->add("5\r\nhelloXX") };
    like( $@, qr/not followed by CRLF/, 'chunk data not followed by CRLF is refused' );
}

# Nothing after the last chunk is kept.
{
    my $body = HTTP::Body->new( 'application/x-www-form-urlencoded', undef );
    $body->add("3\r\na=b\r\n0\r\n\r\n");
    $body->add( 'z' x 100_000 );
    is( $body->state, 'done', 'body stays done after the last chunk' );
    is( length $body->{chunk_buffer}, 0, 'data after the last chunk is dropped' );
    is_deeply( $body->param, { a => 'b' }, 'parameters are unchanged by it' );
}

# A multipart body is done at its close delimiter; later chunks are not kept.
{
    my $mp   = qq{--x\r\nContent-Disposition: form-data; name="a"\r\n\r\nv\r\n--x--\r\n};
    my $body = HTTP::Body->new( 'multipart/form-data; boundary=x', undef );
    $body->add( sprintf "%x\r\n%s\r\n", length $mp, $mp );
    my $chunk = 'y' x 10_000;
    $body->add( sprintf "%x\r\n%s\r\n", length $chunk, $chunk ) for 1 .. 10;
    is( length $body->{buffer}, 0, 'chunk data after the body parser is done is dropped' );
    is( $body->param->{a}, 'v', 'the parsed parameter is kept' );
}
