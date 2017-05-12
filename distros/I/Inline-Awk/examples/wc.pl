#/usr/bin/perl -w

########################################################################
#
# Simple minded version of wc
#
# reverse('©'), November 2001, John McNamara, jmcnamara@cpan.org
#

use Inline AWK;
use strict;

awk();

__END__
__AWK__

BEGIN {
    file = ARGV[1]
}

{
    words += NF
    chars += length($0) +1 # +2 in DOS
}


END {
    printf("%7d%8d%8d %s\n", NR, words, chars, file)
}