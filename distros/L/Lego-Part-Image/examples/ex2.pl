#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Lego::Part;
use Lego::Part::Image::LugnetCom;

# Object.
my $obj = Lego::Part::Image::LugnetCom->new(
        'part' => Lego::Part->new(
               'design_id' => '3003',
        ),
);

# Get image URL.
my $image_url = $obj->image_url;

# Print out.
print "Part with design ID '3003' URL is: ".$image_url."\n";

# Output:
# Part with design ID '3003' URL is: http://img.lugnet.com/ld/3003.gif