use strict;
use warnings;

use Test::More tests => 2;

use Digest::Whirlpool;

{
    local $@;
    eval { Digest::Whirlpool::digest };
    like $@, qr/\(self/, "digest as a non-oo method";
}

my $whirlpool = Digest::Whirlpool->new;

$whirlpool->add( "a" );

cmp_ok length $whirlpool->digest, '==', 64, "digest";

