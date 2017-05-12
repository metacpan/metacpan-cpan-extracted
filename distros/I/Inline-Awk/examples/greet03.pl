#/usr/bin/perl -w

########################################################################
#
# Simple example of using Inline::Awk.
#
# reverse('©'), November 2001, John McNamara, jmcnamara@cpan.org
#

use Inline AWK;
use strict;


hello("Awk");
ciao("Awk");

__END__
__AWK__

function hello(str) {
    print "Hello " str

}

function ciao(str) {
    print "Ciao bello " str

}














