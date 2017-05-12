use strict;

use Test::More tests => 2;

use Digest::Whirlpool;

my $whirlpool = Digest::Whirlpool->new;

$whirlpool->add( "a" );

like $whirlpool->clone->$_, qr/^isom/, "digest"
    for map { qq<${_}64digest> } qw< b base >;

