#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Lego::Part;

# Object.
my $part = Lego::Part->new(
        'element_id' => '300221',
);

# Print color and design ID.
print 'Element ID: '.$part->element_id."\n";

# Output:
# Element ID: 300221