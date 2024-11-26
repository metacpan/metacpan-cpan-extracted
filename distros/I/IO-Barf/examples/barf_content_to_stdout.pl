#!/usr/bin/env perl

use strict;
use warnings;

use IO::Barf;

# Content.
my $content = "foo\nbar\n";

# Barf out.
barf(\*STDOUT, $content);

# Output:
# foo
# bar