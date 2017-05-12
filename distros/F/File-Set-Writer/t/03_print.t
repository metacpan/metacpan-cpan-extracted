#!/usr/bin/perl
use warnings;
use strict;
# Disable extra testing for deficient development environments
BEGIN { $ENV{PERL_STRICTURES_EXTRA} = 0; }
use Test::More;
use File::Set::Writer;


BAIL_OUT "Will not run if ./A or ./B exist."
    if -f "A" or -f "B";

my $writer = File::Set::Writer->new(
    max_handles => 10,
    max_lines   => 10,
);

foreach my $i ( 1 .. 10_000 ) {
    $writer->print( $i % 2 ? "A" : "B", "Hello World" );
}

undef($writer);

open my $lf, "<", "A"
    or die "Failed to read A: $!";
is scalar(grep { $_ eq "Hello World\n" } <$lf>), 5_000, "Writing successful.";

open $lf, "<", "B"
    or die "Failed to read B: $!";
is scalar(grep { $_ eq "Hello World\n" } <$lf>), 5_000, "Writing successful.";

unlink( $_ ) for qw( A B );

done_testing;
