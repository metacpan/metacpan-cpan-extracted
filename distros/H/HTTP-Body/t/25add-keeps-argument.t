#!perl

use strict;
use warnings;

use Test::More tests => 3;

use HTTP::Body;

my $ct = 'application/x-www-form-urlencoded';

{
    my $body = HTTP::Body->new( $ct, 3 );
    my $buf  = 'a=b&c=d';
    $body->add($buf);
    is( $buf, 'a=b&c=d', "add leaves the caller's buffer alone when it exceeds the content length" );
    is_deeply( $body->param, { a => 'b' }, '... and keeps only the content length' );
}

{
    my $body = HTTP::Body->new( $ct, 3 );
    my $ok   = eval { $body->add('a=b&c=d'); 1 };
    ok( $ok, 'add accepts a read-only value that exceeds the content length' ) or diag $@;
}
