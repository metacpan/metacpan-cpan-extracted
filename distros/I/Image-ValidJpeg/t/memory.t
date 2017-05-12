use strict;
use Test::More tests=>2;
use Image::ValidJpeg;

my $empty_buf = '';
my $fh;

open $fh, '<', \$empty_buf;

is( Image::ValidJpeg::check_tail($fh), Image::ValidJpeg::BAD, "check_tail on empty file" );

my $valid_buf = do {
  local $/ = undef;
  open my($fh2), '<', 't/data/small.jpg';
  binmode($fh2);
  <$fh2> 
};

open $fh, '<', \$valid_buf;
binmode($fh);
is( Image::ValidJpeg::check_jpeg($fh), Image::ValidJpeg::GOOD, "check_jpeg on valid image" );

