#!perl

use strict;
use warnings;

use Test::More tests => 3;

use HTTP::Body;

{
    my $raw  = join '&', map { "f$_=v" } 1 .. 1000;
    my $body = HTTP::Body->new( 'application/x-www-form-urlencoded', length $raw );
    $body->add($raw);
    is( scalar keys %{ $body->param }, 1000, '1000 urlencoded fields are accepted' );
}

{
    my $raw  = join ';', map { "f$_=v" } 1 .. 1001;
    my $body = HTTP::Body->new( 'application/x-www-form-urlencoded', length $raw );
    eval { $body->add($raw) };
    like( $@, qr/Too many parameters/, '1001 urlencoded fields are refused' );
}

{
    my $raw  = ( qq{--x\r\nContent-Disposition: form-data; name="a"\r\n\r\nv\r\n} x 1001 ) . "--x--\r\n";
    my $body = HTTP::Body->new( 'multipart/form-data; boundary=x', length $raw );
    eval { $body->add($raw) };
    like( $@, qr/Too many parts/, '1001 multipart parts are refused' );
}
