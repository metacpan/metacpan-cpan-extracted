#!/usr/bin/perl
use warnings;
use strict;
# Disable extra testing for deficient development environments
BEGIN { $ENV{PERL_STRICTURES_EXTRA} = 0; }
use Test::More;
use File::Set::Writer;

BAIL_OUT "Error: Will not run if ./A exists."
    if -f "A";

ok my $writer = File::Set::Writer->new(
    max_lines   => 10,
    max_handles => 10,
    max_files   => 10,
);

foreach my $i ( 1 .. 10_000 ) {
    ok $writer->print( "A", "Hello World" ), "Write Line.";
    is $writer->_lines( "A" ) % 10, $i % 10, "max_lines respected.";
}

unlink( "A" );

done_testing;
