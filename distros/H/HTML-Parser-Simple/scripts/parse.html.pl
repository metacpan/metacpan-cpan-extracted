#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;

use HTML::Parser::Simple;

# -----------------------

my($p) = HTML::Parser::Simple -> new
(
	input_file  => File::Spec -> catfile('data', 's.1.html'),
	output_file => File::Spec -> catfile('data', 's.2.html'),
);

print $p -> parse_file -> result;
