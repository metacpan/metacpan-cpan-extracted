#!/usr/bin/env perl

use strict;
use warnings;

use Indent;

# Indent object.
my $indent = Indent->new(

       # Begin indent.
       'indent' => '->',

       # Next indent.
       'next_indent' => "->"
);

# Print example.
print $indent->get;
print "Example\n";

# Add indent and print ok.
$indent->add;
print $indent->get;
print "Ok\n";

# Remove indent and print nex example.
$indent->remove;
print $indent->get;
print "Example2\n";

# Reset.
$indent->reset;

# Output: 
# ->Example
# ->->Ok
# ->Example2