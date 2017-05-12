#!/usr/local/bin/perl -w

use strict;
use warnings;
use Test::More;
use Image::Epeg qw(:constants);

my @i = stat( "t/test.jpg" );
my $rawimgsize = $i[7];

my $f = undef;
{
    open my $fh, "t/test.jpg";
    binmode $fh;
    $f .= $_ while <$fh>;
    close $fh;
}


# Test 1: new( [reference] )
my $epeg = new Image::Epeg( \$f );
ok defined $epeg;

# Test 2: get_width()
is $epeg->get_width(), 640;

# Test 3: get_height()
is $epeg->get_height(), 480;

# Test 4: get_output_width()
is $epeg->get_output_width(), 640;

# Test 5: get_output_height()
is $epeg->get_output_height(), 480;

# resize() setup
$epeg->resize( 150, 150, MAINTAIN_ASPECT_RATIO );

# Test 4: get_width() don't change by resize(for compatible)
is $epeg->get_width(), 640;

# Test 5: get_height() dont't change by resize(for compatible)
is $epeg->get_height(), 480;

# Test 6: get_output_width(): get new width after resize
is $epeg->get_output_width(), 150;

# Test 7: get_output_height(): get new height after resize
is $epeg->get_output_height(), 113;

done_testing;

