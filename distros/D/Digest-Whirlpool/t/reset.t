use strict;
use warnings;

use Test::More tests => 4;

use Digest::Whirlpool;

{
    local $@;
    eval { Digest::Whirlpool::reset };
    like $@, qr/\(self/, "reset as a non-oo method";
}

my $whirlpool = Digest::Whirlpool->new;

$whirlpool->add( "a" );
like $whirlpool->clone->hexdigest, qr/^8aca/, "adding one item";
$whirlpool->reset;

$whirlpool->add( "a" );
like $whirlpool->clone->hexdigest, qr/^8aca/, "adding one item";
$whirlpool = $whirlpool->reset;

$whirlpool->add( "a" );
like $whirlpool->clone->hexdigest, qr/^8aca/, "adding one item";
