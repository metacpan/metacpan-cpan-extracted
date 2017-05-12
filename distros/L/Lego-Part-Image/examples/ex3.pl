#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Lego::Part;
use Lego::Part::Image::PeeronCom;

# Object.
my $obj = Lego::Part::Image::PeeronCom->new(
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
# Part with design ID '3003' and color '1' URL is: http://media.peeron.com/ldraw/images/1/100/3003.png