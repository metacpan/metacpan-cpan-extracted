#!/usr/bin/env perl

use strict;
use warnings;

use Lego::Part;
use Lego::Part::Image;

# Error pure setting.
$ENV{'ERROR_PURE_TYPE'} = 'Print';

# Object.
my $obj = Lego::Part::Image->new(
        'part' => Lego::Part->new(
               'color' => 'red',
               'design_id' => '3002',
        ),
);

# Get image.
$obj->image;

# Output:
# Lego::Part::Image: This is abstract class. image() method not implemented.