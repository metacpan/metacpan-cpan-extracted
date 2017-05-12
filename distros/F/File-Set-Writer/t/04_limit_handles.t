#!/usr/bin/perl
use warnings;
use strict;
# Disable extra testing for deficient development environments
BEGIN { $ENV{PERL_STRICTURES_EXTRA} = 0; }
use Test::More;
use File::Set::Writer;

foreach my $file ( qw( A B C D E F G H I J K ) ) {
    BAIL_OUT "Error: Will not run while ./$file exists."
        if -f $file;
}

ok my $writer = File::Set::Writer->new(
    max_lines   => 1,
    max_handles => 10,
    max_files   => 1,
    expire_files_batch_size => 1,
    expire_handles_batch_size => 10,
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

foreach my $i ( 1 .. 1_000 ) {
    my $int = ( $i % 10 );
    $int ||= 10; # Set 0 = 10;

    ok $writer->print( $files{$int}, "Hello World" ), "Write Line.";
    is $writer->_handles, $int, "max_handles respected.";
}

unlink( $_ ) for qw( A B C D E F G H I J K );

END { unlink( $_ ) for qw( A B C D E F G H I J K ) };

done_testing;
