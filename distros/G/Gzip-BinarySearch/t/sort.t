use Test::More tests => 9;

use strict;
use warnings;
no warnings 'once';
use lib './t/lib';
use Gzip::BinarySearch;
use Test::Gzip::BinarySearch;

my ($filename, $index) = fixture('numbersort');

my $bs = Gzip::BinarySearch->new(
    file => $filename,
    cmp_func => sub { $a <=> $b },
);

for my $number (qw(1 2 3 9 10 11 100)) {
    is( $bs->find($number), "$number\n" );
}

is( $bs->find(12), undef );

is_deeply( [$bs->find_all(21)], ["21\n", "21\ta\n", "21\tb\n"] );

wipe_index($index);
