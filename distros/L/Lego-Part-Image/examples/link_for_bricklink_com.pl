#!/usr/bin/env perl

use strict;
use warnings;

use Lego::Part;
use Lego::Part::Image::BricklinkCom;

# Object.
my $obj = Lego::Part::Image::BricklinkCom->new(
        'part' => Lego::Part->new(
               'color' => 1,
               'design_id' => '3003',
        ),
);

# Get image URL.
my $image_url = $obj->image_url;

# Print out.
print "Part with design ID '3003' and color '1' URL is: ".$image_url."\n";

# Output:
# Part with design ID '3003' and color '1' URL is: https://img.bricklink.com/ItemImage/PN/1/3003.png