use strict;

use Test::More tests => 1;

use Digest::Whirlpool;

my $whirlpool = Digest::Whirlpool->new;

$whirlpool->add( "a" );

like $whirlpool->hexdigest, qr/^8aca/, "digest";

