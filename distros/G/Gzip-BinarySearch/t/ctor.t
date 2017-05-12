use Test::More tests => 8;

use strict;
use warnings;
use lib './t/lib';
use Gzip::BinarySearch;
use Test::Gzip::BinarySearch;
use Test::Exception;

my ($filename, $index) = fixture('dict', 'dict.gz.idx.custom');

my $index_span = 1337;
my $bs = Gzip::BinarySearch->new(
    file => $filename,
    index_file => $index,
    index_span => $index_span,
    cleanup => 1,
    est_line_length => 52,
    surrounding_lines_blocksize => 1024,
);
isa_ok( $bs->gzip, 'Gzip::RandomAccess' );
is( $bs->gzip->index_file, $index );
is( $bs->gzip->index_span, $index_span );
is( $bs->gzip->cleanup, 1 );
is( $bs->est_line_length, 52 );
is( $bs->surrounding_lines_blocksize, 1024 );
undef $bs;

throws_ok {
    Gzip::BinarySearch->new(
        file => $filename,
        index_file => $index,        
        foo => 1,
    );
} qr/Invalid argument 'foo'/, 'detect invalid arguments';

lives_ok {
    Gzip::BinarySearch->new(
        file => $filename,
        index_file => $index,        
        key_func => sub { 1 },
    );
} "Don't just pass everything to the Gzip::RandomAccess object";

wipe_index($index);
