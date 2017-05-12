#!/usr/bin/perl

use 5.006;
use warnings;
use strict;

my $have_io_zlib;

BEGIN {
    eval "require IO::Zlib";
    unless ($@) {
        require IO::Zlib;
        $have_io_zlib++;
    }
}

use Test::More;
use File::MergeSort;

if ( $have_io_zlib ) {
    plan tests => 6;
} else {
    plan skip_all => 'IO::Zlib not available';
}

my @compress_files   = qw( t/1.gz t/2.gz );
my @uncompress_files = qw( t/1 t/2 );
my @mix_files        = qw( t/1.gz t/2 );

my $coderef = sub { my $line = shift; substr($line,0,2); };

# Test 1: create object with purely compressed files.

my $m;

eval {
    $m = File::MergeSort->new( \@compress_files, $coderef );
};

ok( ref $m eq 'File::MergeSort', 'File::MergeSort object created' ); # test 1

my $in_lines = 0;

foreach my $file ( @uncompress_files ) {
    open my $fh, '<', $file or die "Unable to open test file $file: $!";
    while (<$fh>) { $in_lines++ };
    close $fh or die "Problems closing test file, $file: $!";
}

my $d = $m->dump('t/output_from_compressed');

ok($d eq $in_lines, 'dump() reporting expected number of lines output' ); # test 2

if ( -f 't/output_from_compressed' ) {
    unlink 't/output_from_compressed' or warn "Failed to unlink output_from_compressed test file";
}

# Test 3: create object with mixed compressed/uncompress files.

eval {
    $m = File::MergeSort->new( \@mix_files, $coderef );
};

ok( ref $m eq 'File::MergeSort'); # test 3

$d = $m->dump();

ok( $d eq $in_lines, 'dump() reporting expected number of lines output'); # test 4

eval {
    $m = File::MergeSort->new( \@compress_files, $coderef );
};

# Check data being returned by next_line really is in sorted order.

my $i = 0;
my $last;
my $fail = 0;
while ( my $line = $m->next_line() ) {
    my $key = $coderef->( $line );
    if ( $i > 1 ) {
        $fail++ unless $key ge $last;
    }
    $last = $key;
    $i++;
}

ok( 0 == $fail , 'All keys in expected order' ); # test 5
ok($i eq $in_lines, 'Expected number of lines output' ); # test 6
