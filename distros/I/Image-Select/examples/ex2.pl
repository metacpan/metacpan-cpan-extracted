#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use File::Spec::Functions qw(catfile);
use File::Temp qw(tempfile tempdir);
use Image::Random;
use Image::Select;

# Temporary directory for random images.
my $tempdir = tempdir(CLEANUP => 1);

# Create temporary images.
my $rand = Image::Random->new;
for my $i (1 .. 5) {
        $rand->create(catfile($tempdir, $i.'.png'));
}

# Object.
my $obj = Image::Select->new(
        'loop' => 0,
        'path_to_images' => $tempdir,
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