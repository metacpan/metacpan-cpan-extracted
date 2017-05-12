#!/usr/bin/perl -T

# Make sure we can load HTML::DOM::Element without HTML::DOM already loaded 
# (this caused syntax errors in 0.042 and earlier; probably broken
# in 0.028).

use HTML::DOM::Element;

print "1..1\nok 1\n";
