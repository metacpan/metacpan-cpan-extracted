#!/usr/bin/perl
use warnings;
use strict;
# Disable extra testing for deficient development environments
BEGIN { $ENV{PERL_STRICTURES_EXTRA} = 0; }
use Test::More;
use File::Set::Writer;

foreach my $file ( qw( A B C D E F G H I J ) ) {
    BAIL_OUT "Error: Will not run while ./$file exists."
        if -f $file;
}

ok my $writer = File::Set::Writer->new(
    max_lines   => 10,
    max_handles => 10,
    max_files   => 10,
    expire_files_batch_size => 10,
);

my %files = (
    0   => "A",
    1   => "B",
    2   => "C",
    3   => "D",
    4   => "E",
    5   => "F",
    6   => "G",
    7   => "H",
    8   => "I",
    9   => "J",
    10  => "K",
);

foreach my $i ( 1 .. 10_000 ) {
    ok $writer->print( $files{ $i % 10 }, "Hello World" ), "Write Line.";
    is $writer->_files, $i % 10, "max_files respected.";
}

unlink( $_ ) for qw( A B C D E F G H I J );

END { unlink( $_ ) for qw( A B C D E F G H I J ) };

done_testing;
