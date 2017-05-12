#!perl -w
use strict;
use warnings;
use Compress::Deflate7 qw(zlib7);
use Image::PNG::Rewriter;

die "Usage: $0 /path/to/image.png\n" unless @ARGV == 1;

my $zlib = sub {
  my $data = shift;
  return zlib7($data, Algorithm => 1, FastBytes => 258, Pass => 10);
};

open(my $f, '<', $ARGV[0]) or die $!;
binmode $f;

my $size = -s $f;

my $re = Image::PNG::Rewriter->new(handle => $f, zlib => $zlib);
$re->refilter($re->original_filters);

my $new_size = length $re->as_png;

printf "Old size: %u; new size: %u\n", $size, $new_size;
