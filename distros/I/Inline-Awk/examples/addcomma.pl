#/usr/bin/perl -w

########################################################################
#
# Commify a number using Awk and Inline::Awk.
#
# reverse('©'), November 2001, John McNamara, jmcnamara@cpan.org
#

use Inline AWK;
use strict;

my $num = 1_234_567;

print "$num = ", addcomma($num), "\n";

__END__
__AWK__

# This code is modified from the Gawk distribution under the GPL.
function addcomma(x) {
    if (x < 0) return "-" addcomma(-x)

    num = sprintf("%.2f", x) # num is dddddd.dd

    while (num ~ /[0-9][0-9][0-9][0-9]/) {
        sub(/[0-9][0-9][0-9][,.]/, ",&", num)
    }

    return num
}












