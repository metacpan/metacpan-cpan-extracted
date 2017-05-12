use Test::More tests => 12;

use strict;
use warnings;
use lib './t/lib';
use Gzip::BinarySearch;
use Test::Gzip::BinarySearch;

my ($filename, $index) = fixture('dict');

my $bs = Gzip::BinarySearch->new(file => $filename);
for my $key (qw(a abash abbreviates abhorring bookmaker extoll uninviting yoghurts zits zooms a)) {
    is( $bs->find($key), "$key\n" );
}

is( $bs->find('nonexistentword'), undef );

wipe_index($index);
