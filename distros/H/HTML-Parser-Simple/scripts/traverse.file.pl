#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;

use HTML::Parser::Simple::Reporter;

# ---------------------------------

my($p) = HTML::Parser::Simple::Reporter -> new;

print "$_\n" for @{$p -> traverse_file(File::Spec -> catfile('data' ,'s.1.html') )};
