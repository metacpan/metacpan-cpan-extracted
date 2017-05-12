#!/usr/local/bin/perl -w

use strict;
use warnings;
use Test::More tests => 5;
use Image::Epeg qw(:constants);

my @i = stat( "t/epeg_crash.jpg" );
my $rawimgsize = $i[7];

# Test 1: new( [file] )
my $epeg = Image::Epeg->new( "t/epeg_crash.jpg" );
isa_ok $epeg, 'Image::Epeg';


# Test 2: get_width(), get_height()
is $epeg->get_width(), 550;
is $epeg->get_height(), 384;

# Test 3: resize()
$epeg->resize( 150, 150, MAINTAIN_ASPECT_RATIO );
$epeg->set_comment( "test comment" );
$epeg->set_quality( 80 );


# Test 4: write_file()
my $rc = $epeg->write_file( "t/epeg_crash2.jpg" );
ok !$rc;

# Test 5: new( [file] )
# Will fail because we're trying to open a gif.
# Test graceful recovery
$epeg = Image::Epeg->new( "t/test.gif" );
ok !$epeg;

