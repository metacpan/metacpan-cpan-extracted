#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Lego::Part;
use Lego::Part::Image::LegoCom;

# Object.
my $obj = Lego::Part::Image::LegoCom->new(
        'part' => Lego::Part->new(
               'element_id' => '300321',
        ),
);

# Get image URL.
my $image_url = $obj->image_url;

# Print out.
print "Part with element ID '300321' URL is: ".$image_url."\n";

# Output:
# Part with element ID '300321' URL is: http://cache.lego.com/media/bricks/5/2/300321.jpg