#!perl

use strict;
use warnings;

use Test::More tests => 3;

use HTTP::Body;
use Time::HiRes qw/ time /;

my $ct = 'application/x-www-form-urlencoded';

{
    my $body = HTTP::Body->new( $ct, undef );
    $body->add("5;ext=1\r\na=b&c\r\n4\r\n=d&e\r\n0\r\n\r\n");
    is_deeply( $body->param, { a => 'b', c => 'd' }, 'chunks with an extension are parsed' );
    is( $body->state, 'done', 'last chunk ends the body' );
}

{
    # A size line whose first LF has no CR before it never matches; the
    # old pattern backtracked over it in time quadratic in its length.
    my $body = HTTP::Body->new( $ct, undef );
    my $t    = time;
    $body->add( ( '1' x 100_000 ) . "\n\r\n" );
    cmp_ok( time - $t, '<', 5, 'unterminated chunk size line is rejected in linear time' );
}
