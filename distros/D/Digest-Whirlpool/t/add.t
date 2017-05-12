use strict;

use Test::More tests => 3;

use Digest::Whirlpool;

{
    local $@;
    eval { Digest::Whirlpool::add };
    like $@, qr/\(self/, "add as a non-oo method";
}

my $whirlpool = Digest::Whirlpool->new;

$whirlpool->add( "a" );

like $whirlpool->clone->hexdigest, qr/^8aca/, "adding one item";

$whirlpool->add( qw< b c > );

like $whirlpool->clone->hexdigest, qr/^4e244/, "adding two items to the first one";


