use strict;

use Test::More tests => 3;

use Digest::Whirlpool;

my $whirlpool = new Digest::Whirlpool;

$whirlpool->add("a");

my $whirlpool2 = $whirlpool->clone;
like $whirlpool->hexdigest, qr/^8aca/;

# do this after the digest above to make sure we're not just
# pointing to the same memory location

$whirlpool2->add( "bc" ); # abc
my $whirlpool3 = $whirlpool2->clone->clone->clone; # chaned cloning
like $whirlpool2->hexdigest, qr/^4e24/;

# do this after the digest above to make sure we're not just
# pointing to the same memory location

$whirlpool3->add( "de" ); # abcde
like $whirlpool3->hexdigest, qr/^5d74/;
