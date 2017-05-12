use Test::More tests => 5;

use strict;
use warnings;
use lib './t/lib';
use Gzip::BinarySearch;
use Test::Gzip::BinarySearch;

my ($filename, $index) = fixture('multiple');

my %tests = (
    '1000' => ['apple', 'banana'],
    '2000' => ['apple'],
    '3000' => ['banana', 'mango', 'advocado', 'grape', 'hob nobs', 'ham and eggs'],
    '4000' => ['coffee', 'sandwich', 'yoghurt'],
    '5000' => [],
);

my $bs = Gzip::BinarySearch->new(file => $filename);

for my $key (sort keys %tests) {
    my $values = $tests{$key};
    my @expected = map {"$key\t$_\n"} @$values;
    {
        my @results = $bs->find_all($key);
        is_deeply(\@results, \@expected, "find_all - $key");
    }
}

wipe_index($index);
