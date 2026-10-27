#!perl

use strict;
use warnings;

use Test::More tests => 3;

use HTTP::Body;

my $ct   = 'multipart/form-data; boundary=xYz';
my $part = qq{--xYz\r\nContent-Disposition: form-data; name="a"\r\n\r\nv\r\n};

{
    my $raw  = $part . '--xYzQ' . ( '-' x 100 );
    my $body = HTTP::Body->new( $ct, length $raw );
    eval { $body->add($raw) };
    like( $@, qr/Invalid multipart boundary delimiter/, 'malformed delimiter line is refused' );
}

{
    my $raw  = $part . "--xYz--  \r\n";
    my $body = HTTP::Body->new( $ct, length $raw );
    $body->add($raw);
    is( $body->state, 'done', 'close delimiter with padding ends the body' );
}

{
    my $raw  = ( 'p' x 1000 ) . "\r\n$part--xYz--\r\n";
    my $body = HTTP::Body->new( $ct, length $raw );
    $body->add( substr $raw, $_, 1 ) for 0 .. length($raw) - 1;
    is( $body->param->{a}, 'v', 'preamble and boundary fed one byte at a time' );
}
