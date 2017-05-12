#!/usr/bin/perl
use warnings;
use strict;

use HTML::WikiConverter::WebApp;

#
# Configure the html-to-wiki web application. (Note that each line
# ends in a comma.)
#

my %config = (
  # Full path to the templates/ directory (eg, where main.html is)
  template_path => '__PATH_TO_TEMPLATES__',
);

HTML::WikiConverter::WebApp->new( PARAMS => \%config )->run;
