#/usr/bin/perl -w

########################################################################
#
# Simple example of using Inline::Awk with Inline::Files.
#
# reverse('©'), November 2001, John McNamara, jmcnamara@cpan.org
#

use Inline::Files;
use Inline AWK; # Note uppercase name
use strict;

hello("Awk");



__AWK__

function hello(str) {
    print "Hello " str
}



