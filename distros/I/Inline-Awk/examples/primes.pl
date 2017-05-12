#/usr/bin/perl -w

########################################################################
#
# Prime number generator.
#
# reverse('©'), November 2001, John McNamara, jmcnamara@cpan.org
#

use Inline AWK;
use strict;

primes(0, 100);

__END__
__AWK__

# This code is modified from the Mawk distribution under the GPL.
function primes(start, stop) {

    if ( start < 2 ) start = 2
    if ( stop < start ) stop = start

    prime[p_cnt = 1] =  3  # keep primes in prime[]

    # keep track of integer part of square root by adding
    # odd integers
    odd     = 5
    test    = 5
    root    = 2
    squares = 9


    while ( test <= stop )
    {
	if ( test >= squares )
	{ root++
	    odd += 2
	    squares += odd
	}

	flag = 1
	for ( i = 1 ; prime[i] <= root ; i++ )
	    if ( test % prime[i] == 0 )  #  not prime
	    { flag = 0 ; break }

	if ( flag )  prime[ ++p_cnt ] = test

	test += 2
    }

    prime[0] = 2

    for( i = 0 ; prime[i] < start ; i++)  ;

    for (  ;  i <= p_cnt ; i++ )  print prime[i]
}












