#!perl

use strict;
use warnings;

use Test::More tests => 4;

use HTTP::Body;

my $ct   = 'multipart/form-data; boundary=x';
my $part = qq{--x\r\nContent-Disposition: form-data; name="a"\r\n};

{
    my $raw  = $part . ( "a\r\n" x 20000 ) . "\r\nv\r\n--x--\r\n";
    my $body = HTTP::Body->new( $ct, length $raw );
    eval { $body->add($raw) };
    like( $@, qr/header exceeds/, 'part header block over the limit is refused' );
}

{
    my $raw  = $part . ( "a:\r\n" x 200 ) . "\r\nv\r\n--x--\r\n";
    my $body = HTTP::Body->new( $ct, length $raw );
    eval { $body->add($raw) };
    like( $@, qr/header exceeds/, 'part header block of too many lines is refused' );
}

{
    my $body = HTTP::Body->new( $ct, 1_000_000 );
    eval { $body->add($part); $body->add( "a\r\n" x 1000 ) for 1 .. 20 };
    like( $@, qr/header exceeds/, 'unterminated part header block over the limit is refused' );
}

{
    my $raw  = $part . 'X-Pad: ' . ( 'a' x 1024 ) . "\r\n\r\nv\r\n--x--\r\n";
    my $body = HTTP::Body->new( $ct, length $raw );
    $body->add($raw);
    is( $body->param->{a}, 'v', 'part with a 1 KiB header block is parsed' );
}
