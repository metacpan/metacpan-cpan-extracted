#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec::Functions qw(catfile);
use File::Temp qw(tempfile tempdir);
use Image::Random;
use Image::Select::Array;

# Temporary directory for random images.
my $tempdir = tempdir(CLEANUP => 1);

# Create temporary images.
my $rand = Image::Random->new;
my @images;
for my $i (1 .. 5) {
        my $image = catfile($tempdir, $i.'.png');
        $rand->create(catfile($tempdir, $i.'.png'));
        push @images, $image;
}

# Object.
my $obj = Image::Select::Array->new(
        'image_list' => \@images,
        'loop' => 0,
);

# Temporary file.
my (undef, $temp) = tempfile();

# Create image.
while (my $type = $obj->create($temp)) {

        # Print out type.
        print $type."\n";
}

# Unlink file.
unlink $temp;

# Output:
# bmp
# bmp
# bmp
# bmp
# bmp