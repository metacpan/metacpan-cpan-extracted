#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;

use HTML::Parser::Simple;

# -----------------------

print HTML::Parser::Simple -> new
(
	input_file  => File::Spec -> catfile('t', 'data', '90.xml.declaration.xhtml'),
	output_file => File::Spec -> catfile('data', '90.xml.declaration.xml'),
	xhtml       => 1,
) -> parse_file -> result;
