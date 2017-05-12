// Modified version by Jonathan Leto <jonathan@leto.net>
//
// gcc -I/opt/local/include -L/opt/local/lib -lgmp bpsw1.c trn.c -o bpsw
//
/* bpsw1.c               Thomas R. Nicely          2007.02.09.2350
 *                    http://www.trnicely.net
 * GCC 3.04                 DJGPP 2.03                    GMP 4.01
 *
 * Freeware copyright (c) 2007 Thomas R. Nicely
 * <http://www.trnicely.net>. No warranties expressed or implied.
 * Distributed under the terms of the GNU GPL, GNU FDL, and DJGPP
 * licenses; see <http://www.gnu.org/licenses/licenses.html> and
 * <http://www.delorie.com/djgpp>. Source, binaries, and license
 * terms available upon request.
 *
 * Revised for compatibility with GCC 4.02 and GMP 4.14
 * (-std=gnu99) running under GNU/Linux (kernel release
 * 2.6.13-15-default, SUSE Linux 10.0 i386) as root.
 *
 * NOTE: Most of the functions called in this code are
 * defined and implemented in the accompanying support files
 * trn.h and trn.c. Command-line compilation of the code is carried
 * out by a command such as
 *
 *                  gcc bpsw1.c trn.c
 *
 * with trn.c and trn.h present in the current directory or on
 * the search path. This will be dependent on the environment and
 * configuration of your system.
 *
 * SYNTAX: bpsw1 LB UB|dN [UF]
 *
 * The bounds may be expressed in floating point notation, e.g.,
 * bpsw1 1e50 1e5. If arg2 is less than arg1, it is interpreted as
 * an increment, and UB = arg1 + arg2. If arg2 is negative, the
 * bounds are (arg1 + arg2) and arg1. The optional third argument
 * UF sets the screen update frequency (default is every 1000
 * integers).
 *
 * The purpose of this code is not to simply to compute pi(x),
 * which can be done in much more efficiently, but to test and
 * illustrate the various primality testing routines called.
 *
 * This code, and its support routines trn.c and trn.h, implement
 * the standard and strong versions of the Lucas-Selfridge and
 * Baillie-PSW primality tests, as well as the extra strong Lucas
 * test; see <http://www.trnicely.net/misc/bpsw.html> for details.
 * The GMP mpz_probab_prime_p function, employing Miller-Rabin
 * tests with 13 different bases, is called to determine the
 * "true" primality of each odd number between the specified
 * bounds, and this result is then compared with those from the
 * standard BPSW test, strong BPSW test, and extra strong Lucas
 * test (base 3), as well as the standard and strong Lucas tests
 * and the Miller-Rabin test with base 2. Discrepancies are
 * reported as counts of psueudoprimes for each category.
 * As of this date, there is no known integer N for which this
 * implementation of either the standard or strong BPSW test
 * will return a false primality result---there is no known
 * strong or standard BPSW pseudoprime. The author has
 * directly verified that none exists for N < 10^13; Martin Fuller
 * has verified that none exists for N < 10^15. If a BPSW
 * pseudoprime is detected (a significant and highly unexpected
 * event), it will be reported directly to the screen.
 *
 * See the documentation in the individual modules for additional
 * details, including bibliographies. These modules are part of
 * the accompanying support files trn.h and trn.c.
 *
 * NOTE:
 *
 * The routine mpz_init2 is being used to implement quasi-static
 * manual memory allocation for mpz's, in an attempt to work around
 * bugs encountered in the GMP memory management routines. The use
 * of fprintf(stderr, ...) instead of printf is intended to
 * facilitate redirection, and to eliminate the need for non-ANSI
 * screen manipulation routines from <conio.h>
 *
 */

#include <float.h>
#include <math.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <gmp.h>
#include "trn.h"

int iBPSW(mpz_t mpzN, int iStrong);

char signature[]=
  "\n __bpsw1.c__Version 2007.02.09.2350__Freeware copyright (c) 2007"
  "\n Thomas R. Nicely <http://www.trnicely.net>. No warranties expressed"
  "\n or implied. Distributed under the terms of the GNU GPL, GNU FDL, and"
  "\n DJGPP licenses; see <http://www.gnu.org/licenses/licenses.html> and"
  "\n <http://www.delorie.com/djgpp>. Source, binaries, and license terms"
  "\n available upon request.\n";

/**********************************************************************/
int main(int argc, char *argv[])
{
char *szBuffer;
int i, iPower, iNsmall=0, iPrime, iPrimeBPSW, iPrimeSBPSW, iPrimeMR2,
  iPrimeLS, iPrimeSLS, iPrimeXSL, iPrimeConsensus, iPrimeFermat2;
unsigned long ulPix=0, ulUF=1000UL, ulPSP_BPSW=0, ulPSP_SBPSW=0,
  ulPSP_MR2=0, ulPSP_LS=0, ulPSP_SLS=0, ulPSP_XSL=0, ulPSP_Fermat2=0;
double t0, lfSec;
long double ldLB, ldUB, ldUF;
mpz_t mpzLB, mpzUB, mpzStart, mpzN, mpzRem, mpzDelta, mpzSmallUL, mpzTWO;

/* Much of the logic in MAIN is present simply to process the bounds in
   the command-line arguments, allowing for user-friendly input formats. */

t0=lfSeconds2();

atexit(vAtExit);
signal(SIGINT, exit);
signal(SIGQUIT, exit);
signal(SIGTERM, exit);

if(argc < 2)
  {
  fprintf(stderr, "%s\n SYNTAX: %s LB UB|dN [UF]\n", signature, argv[0]);
  fprintf(stderr,
    "\n ...Illustrates the Baillie-PSW and Lucas primality tests.");
  exit(EXIT_FAILURE);
  }

/* Allocate memory for the mpz's. Assume that all the integers are
   within the domain of long doubles (less than about 4932 decimal
   digits on most systems). */

mpz_init2(mpzLB, LDBL_MAX_EXP);
mpz_init2(mpzUB, LDBL_MAX_EXP);
mpz_init2(mpzStart, LDBL_MAX_EXP);
mpz_init2(mpzN, LDBL_MAX_EXP);
mpz_init2(mpzRem, LDBL_MAX_EXP);
mpz_init(mpzDelta);  /* only contains increments */
mpz_init2(mpzSmallUL, 64);  /* Holds values up to about 10^19 */
mpz_init_set_si(mpzTWO, 2);
szBuffer=(char *)malloc(2 + LDBL_MAX_10_EXP);

/* If only one argument is given, assume LB=0 and UB=argument. */

if(argc==2)
  {
  ldLB=0;
  ldUB=__strtold(argv[1], NULL);
  mpz_set_ui(mpzLB, 0);
  _mpz_set_ld(mpzUB, ldUB);
  goto GOT_BOUNDS;  /* Long live FORTRAN II, ROM BASIC, and assembler */
  }

/* Try to process the arguments as mpz_t strings. If this fails
   (e.g., if a value such as 1e30 is specified), convert it from a
   long double value (18 most significant digits retained, the
   others zeroed) to an mpz_t. */

if(mpz_set_str(mpzLB, argv[1], 0))
  {
  ldLB=__strtold(argv[1], NULL);
  iPower=floorl(log10l(ldLB + 0.5));
  if(iPower > 18)
    {
    ldLB=(1 + 1e-19L)*ldLB;
    _mpz_set_ld(mpzLB, ldLB);
    mpz_get_str(szBuffer, 10, mpzLB);
    for(i=18; i < strlen(szBuffer); i++)szBuffer[i]='0';
    mpz_set_str(mpzLB, szBuffer, 0);
    }
  else
    _mpz_set_ld(mpzLB, ldLB);
  }

if(mpz_set_str(mpzUB, argv[2], 0))
  {
  ldUB=__strtold(argv[2], NULL);
  iPower=floorl(log10l(fabsl(ldUB) + 0.5));
  if(iPower > 18)
    {
    ldUB=(1 + 1e-19L)*ldUB;
    _mpz_set_ld(mpzUB, ldUB);
    mpz_get_str(szBuffer, 10, mpzUB);
    for(i=18; i < strlen(szBuffer); i++)szBuffer[i]='0';
    mpz_set_str(mpzUB, szBuffer, 0);
    }
  else
    _mpz_set_ld(mpzUB, ldUB);
  }

/* If the second argument is less than the first, interpret it
   as an increment, which could be negative. */

if(mpz_cmp(mpzLB, mpzUB) > 0)mpz_add(mpzUB, mpzUB, mpzLB);
if(mpz_cmp(mpzLB, mpzUB) > 0)mpz_swap(mpzLB, mpzUB);

GOT_BOUNDS:
mpz_set(mpzStart, mpzLB);
if(mpz_cmp_ui(mpzStart, 3) < 0)mpz_set_ui(mpzStart, 3);
if(mpz_even_p(mpzStart))mpz_add_ui(mpzStart, mpzStart, 1);
if((mpz_cmp_ui(mpzLB, 2) <= 0) && (mpz_cmp_ui(mpzUB, 2) >= 0))ulPix=1;
if(mpz_cmp_d(mpzUB, 1e19) < 0)iNsmall=1;

/* Optional argument to control display update frequency.
   If absent, adjust update frequency to size of integers. */

ulUF=1000;
i=mpz_sizeinbase(mpzUB, 10);
if(i > 499)ulUF=2;
else if(i > 199)ulUF=10;
else if(i > 49)ulUF=100;

if(argc > 3)
  {
  ldUF=__strtold(argv[3], NULL);
  if((ldUF > 0) && (ldUF <= 4e9))
    {
    ulUF=__nearbyintl(ldUF);
    if(ulUF&1)ulUF++;
    }
  }

mpz_set(mpzN, mpzStart);
mpz_sub(mpzDelta, mpzStart, mpzLB);
mpz_sub_ui(mpzDelta, mpzDelta, 1);

fprintf(stderr, "\n");
while(1)
  {
  if(mpz_cmp(mpzN, mpzUB) > 0)break;
  if(mpz_fdiv_ui(mpzDelta, ulUF)==0)
    {
    lfSec=lfSeconds2() - t0;
    __clearline();
    if(iNsmall)
      {
      fprintf(stderr, "\r LB=");
      mpz_out_str(stderr, 10, mpzLB);
      fprintf(stderr, "   UB=");
      mpz_add(mpzSmallUL, mpzLB, mpzDelta);
      mpz_out_str(stderr, 10, mpzSmallUL);
      }
    else
      {
      fprintf(stderr, "\r dN=");
      mpz_out_str(stderr, 10, mpzDelta);
      }
    fprintf(stderr, "   Pix=%lu   T=%.2lf sec", ulPix, lfSec);
    }

  /* We will accept as the "true primality" of N the result from GMP's
     mpz_probab_prime_p, using the Miller-Rabin strong probable prime
     test with 13 different bases. No mpz_spsp13 pseudoprime is known;
     see <http://www.trnicely.net/misc/mpzspsp.html>. If an mpz_spsp13
     is encountered, it is likely (but not certain) that one of the
     other tests will detect it.

     Note that mpz_probab_prime_p can return 2 (certified prime). */

  iPrime = (mpz_probab_prime_p(mpzN, 13) > 0);
  ulPix += iPrime;

  /* Now calculate the primality of N using the other tests. */

  iPrimeBPSW=iBPSW(mpzN, 0);  /* standard Lucas-Selfridge test */
  iPrimeSBPSW=iBPSW(mpzN, 1);  /* strong Lucas-Selfridge test */
  mpz_powm(mpzRem, mpzTWO, mpzN, mpzN);
  iPrimeFermat2=(mpz_cmp_ui(mpzRem, 2)==0);
  iPrimeMR2=iMillerRabin(mpzN, 2);
  iPrimeLS=iLucasSelfridge(mpzN);
  iPrimeSLS=iStrongLucasSelfridge(mpzN);
  iPrimeXSL=iExtraStrongLucas(mpzN, 3);

  /* The following would indicate an mpz_spsp13 pseudoprime (or
     possibly a coding error in the conflicting algorithm).
     Notify and halt. */

  iPrimeConsensus=
    iPrimeBPSW*iPrimeSBPSW*iPrimeMR2*iPrimeLS*iPrimeSLS*iPrimeXSL;
  if((iPrime) && (!iPrimeConsensus))
    {
    __clearline();
    fprintf(stderr, "\r ");
    mpz_out_str(stderr, 10, mpzN);
    fprintf(stderr, " = %s + ", argv[1]);
    mpz_add_ui(mpzDelta, mpzDelta, 1);
    mpz_out_str(NULL, 10, mpzDelta);
    fprintf(stderr, " appears to be an mpz_spsp13 pseudoprime.\n");
    fprintf(stderr, "  MPZ13=%d  BPSW=%d  SBPSW=%d\n",
      iPrime, iPrimeBPSW, iPrimeSBPSW);
    fprintf(stderr, " Fermat2=%d  MR2=%d  LS=%d  SLS=%d  ",
      iPrimeFermat2, iPrimeMR2, iPrimeLS, iPrimeSLS);
    fprintf(stderr, "  XSL(3)=%d", iPrimeXSL);
    exit(EXIT_SUCCESS);
    }

  /* The following would indicate a BPSW pseudoprime. Notify and halt. */

  if(!iPrime && iPrimeBPSW)
    {
    __clearline();
    fprintf(stderr, "\r ");
    mpz_out_str(NULL, 10, mpzN);
    fprintf(stderr, " = %s + ", argv[1]);
    mpz_add_ui(mpzDelta, mpzDelta, 1);
    mpz_out_str(NULL, 10, mpzDelta);
    fprintf(stderr, " is a Baillie-PSW pseudoprime!!!\n");
    fprintf(stderr, "  MPZ13=%d  BPSW=%d  SBPSW=%d\n",
      iPrime, iPrimeBPSW, iPrimeSBPSW);
    fprintf(stderr, " Fermat2=%d  MR2=%d  LS=%d  SLS=%d  ",
      iPrimeFermat2, iPrimeMR2, iPrimeLS, iPrimeSLS);
    fprintf(stderr, "  XSL(3)=%d\n", iPrimeXSL);
    if(iPrimeSBPSW)
      fprintf(stderr, "\n *** Also a STRONG Baillie-PSW pseudoprime!!!\n");
    else
      fprintf(stderr,
        "\n ...However, N is NOT a STRONG Baillie-PSW pseudoprime.");
    exit(EXIT_SUCCESS);
    }

  /* Tabulate pseudoprimes. */

  if(!iPrime && iPrimeBPSW)ulPSP_BPSW++;
  if(!iPrime && iPrimeSBPSW)ulPSP_SBPSW++;
  if(!iPrime && iPrimeMR2)ulPSP_MR2++;
  if(!iPrime && iPrimeFermat2)ulPSP_Fermat2++;
  if(!iPrime && iPrimeLS)ulPSP_LS++;
  if(!iPrime && iPrimeSLS)ulPSP_SLS++;
  if(!iPrime && iPrimeXSL)ulPSP_XSL++;

  mpz_add_ui(mpzN, mpzN, 2);
  mpz_add_ui(mpzDelta, mpzDelta, 2);
  }

lfSec=lfSeconds2() - t0;
__clearline();
if(iNsmall)
  {
  printf("\r LB=");
  mpz_out_str(NULL, 10, mpzLB);
  printf("   UB=");
  mpz_out_str(NULL, 10, mpzUB);
  }
else
  {
  printf("\r dN=");
  mpz_out_str(NULL, 10, mpzDelta);
  }
printf("   Pix=%lu   T=%.2lf sec\n", ulPix, lfSec);

printf("\n ...Pseudoprimes detected:\n");

printf("\n             Fermat (base 2): %lu", ulPSP_Fermat2);
printf("\n       Miller-Rabin (base 2): %lu", ulPSP_MR2);
printf("\n             Lucas-Selfridge: %lu", ulPSP_LS);
printf("\n      Strong Lucas-Selfridge: %lu", ulPSP_SLS);
printf("\n Extra Strong Lucas (base 3): %lu", ulPSP_XSL);
printf("\n        Standard Baillie-PSW: %lu", ulPSP_BPSW);
printf("\n          Strong Baillie-PSW: %lu", ulPSP_SBPSW);

return(EXIT_SUCCESS);
}
/**********************************************************************/
int iBPSW(mpz_t mpzN, int iStrong)
{
/* Returns 1 if N is a probable prime, that is, passes the primality
 * tests in this algorithm; in that case, N is prime, or a Baillie-
 * Pomerance-Selfridge-Wagstaff (Baillie-PSW or BPSW) pseudoprime
 * (standard or strong, depending on iStrong). Returns 0 if N is
 * definitely composite.
 *
 * If iStrong=0, the standard Baillie-PSW test is used (the standard
 * Lucas-Selfridge test is called). If iStrong=1, the strong
 * Baillie-PSW test is used (the strong Lucas-Selfridge test is
 * called). Note that every strong Lucas-Selfridge pseudoprime is
 * also a standard Lucas-Selfridge pseudoprime.
 *
 * Note that many of the functions called by this routine are
 * defined in the accompanying support files trn.h and trn.c.
 * The codes must be compiled in a manner similar to
 *
 *                  gcc bpsw1.c trn.c
 *
 * with trn.c and trn.h present in the current directory or on
 * the search path; details will depend on the environment and
 * configuration of your own system.
 *
 * The strong Lucas-Selfridge test returns roughly 30 % as many
 * pseudoprimes as the standard test. For example, testing all odd
 * composites (without trial divisors) below 10^6 yields 219 standard
 * Lucas-Selfridge pseudoprimes, 58 strong Lucas-Selfridge pseudoprimes,
 * and 46 base-2 strong pseudoprimes. The extra running time amounts
 * to roughly 10 %, and thus for most purposes the strong
 * Lucas-Selfridge test would appear to be more effective.
 *
 * Determines if N is a probable prime, using a version of the
 * algorithm outlined by Baillie, Pomerance, Selfridge, and Wagstaff
 * (ca. 1980). Values of N are tested successively as follows.
 *
 * (1) N < 2 is not prime. N=2 is prime. Even N > 2 are composite.
 * (2) Try the primes < 1000 as trial prime divisors.
 * (3) If there is no prime divisor p < 1000, apply the Miller-Rabin
 *     strong probable prime test with base 2. If N fails, it is
 *     definitely composite. If N passes, it is a prime or a strong
 *     pseudoprime to base 2.
 * (4) Apply the standard or strong Lucas sequence test with Selfridge's
 *     parameters. If N fails the Lucas-Selfridge test, it is definitely
 *     composite (and a strong pseudoprime to base 2). If N passes the
 *     Lucas-Selfridge test, it is a standard or strong Lucas probable
 *     prime (lprp or slprp), i.e., a prime or a (standard or strong)
 *     Lucas-Selfridge pseudoprime.
 * (5) If N has passed all these tests, it is a (standard or strong)
 *     BPSW probable prime---either prime, or a (standard or strong)
 *     BPSW pseudoprime. In this event the relative frequency of
 *     primality is believed to be very close to 1, and possibly even
 *     equal to 1. With the aid of Pinch's tables of pseudoprimes, the
 *     author has verified (May, 2005) that there exists no Baillie-PSW
 *     pseudoprime (either strong or standard) in N < 10^13. More recently
 *     (January, 2007), with the aid of the present implementation and
 *     William Galway's table of pseudoprimes, Martin Fuller has determined
 *     that no Baillie-PSW pseudoprime (standard or strong) exists for
 *     N < 10^15. Furthermore, no integer N > 10^15 is known (as of the
 *     date of this code) to be either a standard or strong Baillie-PSW
 *     pseudoprime.
 *
 * In the unexpected event that no counterexample exists, this algorithm
 * would constitute a definitive fast certification of primality with
 * polynomial running time, O((log N)^3). In view of the previously
 * mentioned performance characteristics, the strong Lucas-Selfridge
 * and strong BPSW algorithms appear to be more computationally effective
 * as well as more reliable.
 *
 * References:
 *
 * o Arnault, Francois. The Rabin-Monier theorem for Lucas pseudoprimes.
 *   Math. Comp. 66 (1997) 869-881. See
 *   <http://www.unilim.fr/pages_perso/francois.arnault/publications.html>
 * o Baillie, Robert, and Samuel S. Wagstaff, Jr. Lucas pseudoprimes.
 *   Math. Comp. 35:152 (1980) 1391-1417. MR0583518 (81j:10005). See
 *   <http://mpqs.free.fr/LucasPseudoprimes.pdf>.
 * o Galway, William. The pseudoprimes below 10^15. 4 November 2002.
 *   Available at <http://oldweb.cecm.sfu.ca/pseudoprime/>.
 * o Grantham, Jon. Frobenius pseudoprimes. Preprint (16 July 1998)
 *   available at <http://www.pseudoprime.com/pseudo1.ps>.
 * o Martin, Marcel. Re: Baillie-PSW - Which variant is correct?
 *   9 January 2004. See
 *   <http://groups.google.com/groups?hl=en&lr=&ie=UTF-8&oe=UTF-8&safe=off&selm=3FFF275C.2C6B5185%40ellipsa.no.sp.am.net>.
 * o Mo, Zhaiyu, and James P. Jones. A new primality test using Lucas
 *   sequences. Preprint (circa 1997).
 * o Pinch, Richard G. E. Pseudoprimes up to 10^13. 4th International
 *   Algorithmic Number Theory Symposium, ANTS-IV, Leiden, The
 *   Netherlands, 2--7 July 2000. Springer Lecture Notes in Computer
 *   Science 1838 (2000) 459-474. See
 *   <http://www.chalcedon.demon.co.uk/rgep/carpsp.html>.
 * o Pomerance, Carl. Are there counterexamples to the Baillie-PSW
 *   primality test? 1984. See <http://www.pseudoprime.com/dopo.pdf>.
 * o Pomerance, Carl, John L. Selfridge, and Samuel S. Wagstaff, Jr.
 *   The pseudoprimes to 25*10^9. Math. Comp. 35 (1980) 1003-1026. See
 *   <http://mpqs.free.fr/ThePseudoprimesTo25e9.pdf>.
 * o Ribenboim, Paulo. The new book of prime number records. 3rd ed.,
 *   Springer-Verlag, 1995/6, pp. 53-83, 126-132, 141-142 (note that on
 *   line 2, p. 142, "0 < r < s" should read "0 <= r < s").
 * o Weisstein, Eric W. Baillie-PSW primality test. See
 *   <http://mathworld.wolfram.com/Baillie-PSWPrimalityTest.html>.
 * o Weisstein, Eric W. Strong Lucas pseudoprime. See
 *   <http://mathworld.wolfram.com/StrongLucasPseudoprime.html>.
 *
 */

int iComp2, isPrime;
unsigned long ulDiv;

/* First eliminate all N < 3 and all even N. */

iComp2=mpz_cmp_si(mpzN, 2);
if(iComp2 < 0)return(0);
if(iComp2==0)return(1);
if(mpz_even_p(mpzN))return(0);

/* Check for small prime divisors p < 1000. */

ulDiv=ulPrmDiv(mpzN, 1000);
if(ulDiv==1)return(1);
if(ulDiv > 1)return(0);

/* Carry out the Miller-Rabin test with base 2. */

if(iMillerRabin(mpzN, 2)==0)return(0);

/* The rumored strategy of M*thematica could be imitated here by
 * performing additional Miller-Rabin tests. One could also
 * carry out one or more extra strong Lucas tests. See the
 * routine iPrP in trn.c for an implementation.
 *
 * Now N is a prime, or a base-2 strong pseudoprime with no prime
 * divisor < 1000. Apply the appropriate Lucas-Selfridge primality
 * test.
 */

if(iStrong)return(iStrongLucasSelfridge(mpzN));
return(iLucasSelfridge(mpzN));
}
/**********************************************************************/
