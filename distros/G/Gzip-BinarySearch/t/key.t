use Test::More tests => 4;

use strict;
use warnings;
use lib './t/lib';
use Gzip::BinarySearch;
use Test::Gzip::BinarySearch;

my ($filename, $index) = fixture('bars');

my $bs = Gzip::BinarySearch->new(
    file => $filename,
    key_func => sub { /(.*)\|/; return $1; },
);

is( $bs->find('g'), "g|6\n" );
is( $bs->find('z'), undef );

is_deeply( [ $bs->find_all('f') ], [
    "f|6\n",
    "f|7\n",
    "f|8\n",
] );
is_deeply( [ $bs->find_all('c') ], [ "c|3\n" ] );

wipe_index($index);

