#! perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Image::JPEG::Size;

my $jpeg_sizer = Image::JPEG::Size->new;
my $file = "t/data/cc0_320_213.jpg";

is_deeply([$jpeg_sizer->file_dimensions($file)], [320, 213],
          'correct dimensions for sample image');

is_deeply({ $jpeg_sizer->file_dimensions_hash($file) },
          { width => 320, height => 213 },
          'correct hash dimensions for sample image');

like($_, qr/^Image::JPEG::Size->new takes a hash list or hash ref\b/,
     'exception on ctor args')
    for exception { Image::JPEG::Size->new([]) };

SKIP: {
    my $bad_file = 'does-not-exist.jpg';
    skip "surprisingly enough, $bad_file does exist", 1 if -e $bad_file;
    like($_, qr/^Can't open \Q$bad_file\E: /, 'exception on bad file')
        for exception { $jpeg_sizer->file_dimensions($bad_file) };
};

like($_, qr/^Invalid error-handling action foo\b/,
     'exception on bad error action')
    for exception { Image::JPEG::Size->new(error => 'foo') };

like($_, qr/^Invalid warning-handling action foo\b/,
     'exception on bad warning action')
    for exception { Image::JPEG::Size->new(warning => 'foo') };

done_testing();
