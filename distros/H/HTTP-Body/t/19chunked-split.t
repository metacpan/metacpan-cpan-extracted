#!perl

use strict;
use warnings;

use Test::More tests => 5;

use HTTP::Body;

# A chunked body must parse to the same result no matter where the reads that
# feed add() fall. The old length check counted the chunk-size line as part of
# the chunk, so a read that ended inside a chunk made the parser take it short
# and reparse the leftover bytes as the next chunk-size line, and the body
# never completed.

sub parse {
    my ( $raw, $size ) = @_;
    my $body = HTTP::Body->new( 'application/x-www-form-urlencoded', undef );
    for ( my $o = 0 ; $o < length $raw ; $o += $size ) {
        $body->add( substr $raw, $o, $size );
    }
    return $body;
}

# de-chunked payload: a=b&c=defgh  (chunks of 4 and 7 bytes)
my $raw = "4\r\na=b&\r\n7\r\nc=defgh\r\n0\r\n\r\n";

{
    my $body = parse( $raw, length $raw );
    is( $body->state, 'done', 'whole body completes' );
    is_deeply( $body->param, { a => 'b', c => 'defgh' }, 'whole body parsed' );
}

{
    # One byte at a time: every read falls inside a chunk.
    my $body = parse( $raw, 1 );
    is( $body->state, 'done', 'body completes when fed one byte at a time' );
    is_deeply( $body->param, { a => 'b', c => 'defgh' },
        'byte-at-a-time delivery gives the same result' );
}

{
    # Chunk data that begins with hex digits (payload x=abcdef0123456789, as a
    # 4- and a 14-byte chunk): taken short, the leftover "cdef0123456789" would
    # be reparsed as a large chunk size and the parser would wait forever.
    my $hex = "4\r\nx=ab\r\ne\r\ncdef0123456789\r\n0\r\n\r\n";
    my $body = parse( $hex, 6 );
    is( $body->state, 'done', 'hex-leading chunk data is not reparsed as a size line' );
}
