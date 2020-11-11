#!/usr/bin/env perl

use strict;
use warnings;

use Indent::Block;

# Object.
my $i = Indent::Block->new(
        'line_size' => 2,
 'next_indent' => '',
);

# Print in scalar context.
print $i->indent(['text', 'text', 'text'])."\n";

# Output:
# text
# text
# text