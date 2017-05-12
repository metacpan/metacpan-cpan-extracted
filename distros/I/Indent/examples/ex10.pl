#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
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