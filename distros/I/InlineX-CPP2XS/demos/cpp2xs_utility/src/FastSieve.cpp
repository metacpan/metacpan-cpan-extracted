#include <vector>

/* Class _Sieve below.  Perl sees it as a class named
 * "Math::Prime::FastSieve::_Sieve".  The constructor is mapped to
 * "new()" within Perl, and the destructor to "DESTROY()".  All other
 * methods are mapped with the same name as declared in the class.
 *
 * Therefore, Perl sees this class approximately like this:
 *
 * package Math::Prime::FastSieve;
 *
 * sub new {
 *     my $class = shift;
 *     my $n     = shift;
 *     my $self = bless {}, $class;
 *     $self->{max_n} = n;
 *     $self->{num_primes} = 0;
 *     # Build the sieve here...
 *     # I won't bother translating it to Perl.
 *     $self->{sieve} = $primes;  // A reference to a bit vector.
 *     return $self;
 *  }
 *
 */


class _Sieve
{
    public:
        _Sieve ( long n ); // Constructor. Perl sees "new()".
        bool isprime( long n ); // Test if n is prime.
        SV*  primes ( long n ); // Return all primes in an aref.
        unsigned long  nearest_le ( long n ); // Return nearest prime <= n.
        unsigned long  nearest_ge ( long n ); // Return nearest prime >= n.
        unsigned long  nth_prime  ( long n ); // Return the nth prime.
        unsigned long  count_sieve(        ); // Return sieve's prime count.
        unsigned long  count_le   ( long n ); // Return number of primes <= n.
        SV*  ranged_primes( long lower, long upper );
                  // Return all primes where "lower <= primes <= upper".
    private:
        std::vector<bool>::size_type max_n;
        unsigned long                num_primes;
        std::vector<bool>            sieve;
};


// Set up a primes sieve of 0 .. n inclusive.
// This sieve has been optimized to only represent odds, cutting memory
// footprint in half.
_Sieve::_Sieve( long n ) :max_n(n), num_primes(0), sieve(n/2+1,0)
{
    if( n < 0 ) // Trap negative n's before we start wielding unsigned longs.
        max_n = 0UL;
    else
    {
        for( std::vector<bool>::size_type i = 3; i * i <= n; i+=2 )
            if( ! sieve[i/2] )
                for( std::vector<bool>::size_type k = i*i; k <= n; k += 2*i)
                    sieve[k/2] = 1;
    }
}


// Yes or no: Is the number a prime?  Must be within the range of
// 0 through max_n (the upper limit set by the constructor).
bool _Sieve::isprime( long n )
{
    if( n < 2 || n > max_n )  return false; // Bounds checking.
    if( n == 2 )              return true;  // 2 is prime.
    if( ! ( n % 2 ) )         return false; // No other evens are prime.
    if( ! ( sieve[n/2] ) )    return true;  // 0 bit signifies prime.
    return false;                           // default: not prime.
}


// Return a reference to an array containing the list of all primes
// less than or equal to n.  n must be within the range set in the
// constructor.
SV* _Sieve::primes( long n )
{
    AV* av = newAV();
    if( n < 2 || n > max_n ) // Logical short circuit order is significant
                             // since we're about to wield unsigned longs.
        return newRV_noinc( (SV*) av );
    av_push( av, newSVuv( 2UL ) );
    num_primes = 1;          // Count 2; it's prime.
    for( std::vector<bool>::size_type i = 3; i <= n; i += 2 )
        if( ! sieve[i/2] )
            av_push( av, newSVuv( static_cast<unsigned long>(i) ) );
    return newRV_noinc( (SV*) av );
}

SV* _Sieve::ranged_primes( long lower, long upper )
{
    AV* av = newAV();
    if(
        upper > max_n ||        // upper exceeds upper bound.
        lower > max_n ||        // lower exceeds upper bound.
        upper < 2     ||        // No possible primes.
        lower < 0     ||        // lower underruns bounds.
        lower > upper ||        // zero-width range.
        ( lower == upper && lower > 2 && !( lower % 2 ) ) // Even.
    )
        return newRV_noinc( (SV*) av );  // No primes possible.
    if( lower <= 2 && upper >= 2 )
        av_push( av, newSVuv( 2UL ) );    // Lower limit needs to be odd
    if( lower < 3 ) lower = 3;           // Lower limit cannot < 3.
    if( ( upper - lower ) > 0 && ! ( lower % 2 ) ) lower++;
    for( std::vector<bool>::size_type i = lower; i <= upper; i += 2 )
        if( ! sieve[i/2] )
            av_push( av, newSVuv( static_cast<unsigned long>(i) ) );
    return newRV_noinc( (SV*) av );
}


// Find the nearest prime less than or equal to n.  Very fast.
unsigned long _Sieve::nearest_le( long n )
{
    // Remember that order of testing is significant; we have to
    // disqualify negative numbers before we do comparisons against
    // unsigned longs.
    if( n < 2 || n > max_n ) return 0; // Bounds checking.
    if( n == 2 ) return 2UL;            // 2 is the only even prime.
    // Even numbers map to the next odd number down.
    std::vector<bool>::size_type n_idx = (n-1)/2;  // n_idx >= 1
    do {
       if( ! sieve[n_idx] )  return static_cast<unsigned long>(2*n_idx+1);
    } while (--n_idx > 0);
    return 0UL; // We should never get here.
}


// Find the nearest prime greater than or equal to n.  Very fast.
unsigned long _Sieve::nearest_ge( long n )
{
    // Order of bounds tests IS significant.
    // Because max_n is unsigned, testing "n > max_n" for values where
    // n is negative results in n being treated as a real big unsigned value.
    // Thus we MUST handle negatives before testing max_n.
    if( n <= 2 ) return 2UL;              // 2 is only even prime.
    n |= 1;                               // Make sure n is odd before check.
    if( n > max_n ) return 0UL;           // Bounds checking.
    std::vector<bool>::size_type n_idx   = n/2;
    std::vector<bool>::size_type max_idx = max_n/2;
    do {
       if( ! sieve[n_idx] )  return static_cast<unsigned long>(2*n_idx+1);
    } while (++n_idx < max_idx);
    return 0UL;   // We've run out of sieve to test.
}


// Since we're only storing the sieve (not the primes list), this is a
// linear time operation: O(n).
unsigned long _Sieve::nth_prime( long n )
{
    if( n <  1     ) return 0; // Why would anyone want the 0th prime?
    if( n >  max_n ) return 0; // There can't be more primes than sieve.
    if( n == 1     ) return 2; // We have to handle the only even prime.
    unsigned long count = 1;
    for( std::vector<bool>::size_type i = 3; i <= max_n; i += 2 )
    {
        if( ! sieve[i/2] ) count++;
        if( count == n ) return static_cast<unsigned long>(i);
    }
    return 0UL;
}


// Return the number of primes in the sieve.  Once results are
// calculated, they're cached.  First time through is O(n).
unsigned long _Sieve::count_sieve ()
{
    if( num_primes > 0 ) return static_cast<unsigned long>(num_primes);
    num_primes = this->count_le( max_n );
    return static_cast<unsigned long>(num_primes);
}


// Return the number of primes less than or equal to n.  If n == max_n
// the data member num_primes will be set.
unsigned long _Sieve::count_le( long n )
{
    if( n <= 1 || n > max_n ) return 0UL;
    unsigned long count = 1UL;      // 2 is prime. Count it.
    for( std::vector<bool>::size_type i = 3; i <= n; i+=2 )
        if( !sieve[i/2] ) count++;
    if( n == max_n && num_primes == 0 ) num_primes = count;
    return count;
}


// ---------------- For export: Not part of _Sieve class ----------------

/* Sieve of Eratosthenes.  Return a reference to an array containing all
 * prime numbers less than or equal to search_to.  Uses an optimized sieve
 * that requires one bit per odd from 0 .. n.  Evens aren't represented in the
 * sieve.  2 is just handled as a special case.
 */


SV* primes( long search_to )
{
    AV* av = newAV();
    if( search_to < 2 )
        return newRV_noinc( (SV*) av ); // Return an empty list ref.
    av_push( av, newSVuv( 2UL ) );
    // Allocate space for odd numbers (15 bits per 30 values)
    std::vector<bool> primes( search_to/2 + 1, 0 );
    // Sieve over the odd numbers
    for( std::vector<bool>::size_type i = 3; i * i <= search_to; i+=2 )
        if( ! primes[i/2] )
            for( std::vector<bool>::size_type k = i*i; k <= search_to; k += 2*i)
                primes[k/2] = 1;
    // Add each prime to the list ref
    for( std::vector<bool>::size_type i = 3; i <= search_to; i += 2 )
        if( ! primes[i/2] )
            av_push( av, newSVuv( static_cast<unsigned long>( i ) ) );
    return newRV_noinc( (SV*) av );
}


