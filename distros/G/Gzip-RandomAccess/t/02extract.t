# Test basic usage (passing a filename) and random extraction.

use strict;
use warnings;
use Test::More tests => 15;

use Carp;
use File::Spec::Functions qw(catfile);
use FindBin;
use Gzip::RandomAccess;

our $no_test_exception;
BEGIN {
    eval "use Test::Exception";
    $no_test_exception = 1 if $@;
}

my $big_string = join '', map { "$_\n" } (278..2422);
my $big_string2 = join '', map { "$_\n" } (8223..15185);
my @tests = (
    [0, 0, ''],
    [0, 1, '1'],
    [0, 5, "1\n2\n3"],
    [2, 10, "2\n3\n4\n5\n6\n"],
    [1000, 10, "278\n279\n28"],
    [1000, 10003, $big_string],
    [40003, 40001, $big_string2],
    [6888894, 1, '0'],
    [6888886, 10, "9\n1000000\n"],
    [6888886, 1024, "9\n1000000\n", 'partially out of range'],
    [7000000, 0, '', 'out of range'],
    [7000000, 4096, '', 'out of range'],
);

my $filename = catfile($FindBin::Bin, 'fixtures', 'seq.gz');
my $index = catfile($FindBin::Bin, 'fixtures', 'seq.gz.idx');
wipe_index($index);

my $gzip = Gzip::RandomAccess->new($filename);
ok( -f $index, 'index file exists' );

for my $test (@tests) {
    my ($offset, $length, $expected, $message) = @$test;
    is( $gzip->extract($offset, $length), $expected,
        $message || "extract $offset+$length" );
}

is( $gzip->uncompressed_size, 6888896, 'uncompressed_size' );

wipe_index($index);

SKIP: {
    skip "Test::Exception needed for exception tests" => 1 if $no_test_exception;
    throws_ok { $gzip->extract(0, 10) } qr/input corrupted/, "extract with no index";
}


sub wipe_index {
    my $index = shift;
    unlink($index) or do {
        croak $! unless $! =~ /No such file or directory/;
    }
}
