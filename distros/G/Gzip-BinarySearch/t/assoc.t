use Test::More tests => 6;

use strict;
use warnings;
use lib './t/lib';
use Gzip::BinarySearch;
use Test::Gzip::BinarySearch;

my ($filename, $index) = fixture('assoc');

my %tests = (
    '1' => "1\ta\n",
    '2' => "2\tb\n",
    '5' => "5\te\n",
    '7' => "7\tg\tseven\n",
    '9' => "9\ti\n",
    '10' => "10\tj\n",
);

my $bs = Gzip::BinarySearch->new(file => $filename);
while (my ($key, $line) = each %tests) {
    is( $bs->find($key), $line, "key $key" );
}

wipe_index($index);
