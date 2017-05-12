#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Module.
use IO::Barf;

# Content.
my $content = "foo\nbar\n";

# Barf out.
barf(\*STDOUT, $content);

# Output:
# foo
# bar