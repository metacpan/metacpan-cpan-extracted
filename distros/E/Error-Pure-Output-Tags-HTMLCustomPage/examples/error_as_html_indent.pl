#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure::Output::Tags::HTMLCustomPage qw(err_pretty);
use Tags::Output::Indent;

# Tags object.
my $tags = Tags::Output::Indent->new(
        'output_handler' => \*STDOUT,
        'auto_flush' => 1,
);

# Error.
err_pretty($tags, 'utf-8', 'application/xhtml+xml', '1.0', [
        ['b', 'html'],
        ['b', 'head'],
        ['b', 'title'],
        ['d', 'Foo'],
        ['e', 'title'],
        ['e', 'head'],
        ['b', 'div'],
        ['d', 'Bar'],
        ['e', 'div'],
        ['e', 'html'],
]);

# Output like:
# Cache-Control: no-cache
# Date: Wed, 03 Sep 2014 11:48:37 GMT
# Content-Type: application/xhtml+xml
#
# <?xml version="1.0" encoding="utf-8" standalone="no"?><!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"><html>
#   <head>
#     <title>
#       Foo
#     </title>
#   </head>
#   <div>
#     Bar
#   </div>
# </html>