/***********************************************************************
 *
 * File        : Distributions.hxx
 * Author      : Ihab A.B. Awad
 * Date Begun  : October 08 2004
 *
 * $Id: Distributions.hxx,v 1.2 2004/10/14 22:35:13 ihab Exp $
 *
 * License information (the MIT license)
 *
 * Copyright (c) 2004 Ihab A.B. Awad; Stanford University

 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use, copy,
 * modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 *
 **********************************************************************/

#include <map>
#include <vector>

/***********************************************************************
 *
 * This class computes statistics for GO::TermFinder. It does not
 * attempt to be a general-purpose statistical library; rather, it is
 * a performance enhancement feature that is tightly bound to
 * GO::TermFinder.
 *
 */

class Distributions {

public:

  /*********************************************************************
   *
   * Construct a new Distributions object.
   *
   * maxPopulationSize - the maximum size of the populations of interest.
   *
   */

  Distributions(const int maxPopulationSize);

  /*********************************************************************
   *
   * Destroy this Distributions object.
   *
   */

  ~Distributions();

  /*********************************************************************
   *
   * This method calculates the pvalue of of observing x or more
   * positives from a sample of n, given that there are M positives in
   * a population of N.
   *
   * If the value of N as supplied here is greater than the
   * constructor parameter maxPopulationSize, the behavior of this
   * method is undefined.
   *
   */

  double pValueByHypergeometric(const int x,
				const int n,
				const int M,
				const int N);

  /*********************************************************************
   *
   * This method returns the hypergeometric probability value for
   * sampling without replacement.  The calculation is the probability
   * of picking x positives from a sample of n, given that there are M
   * positives in a population of N.
   * 
   * The value is calculated as:
   * 
   *         (M choose x) (N-M choose n-x)
   *   P =   -----------------------------
   *                  N choose n
   * 
   * where generically n choose r is number of permutations by which r
   * things can be chosen from a population of n (see logNCr(int, int))
   * 
   * However, given that these n choose r values may be extremely high
   * (as they are are calculated using factorials) it is safer to do
   * this instead in log space, as we are far less likely to have an
   * overflow.
   * 
   * thus :
   * 
   *   log(P) = log(M choose x) + log(N-M choose n-x) - log (N choose n);
   * 
   * this means we can now calculate log(n choose r) for our
   * hypergeometric calculation.
   *
   * If the value of N as supplied here is greater than the
   * constructor parameter maxPopulationSize, the behavior of this
   * method is undefined.
   *
   */

  double hypergeometric(const int x,
			const int n,
			const int M,
			const int N);

  /*********************************************************************
   *
   * This method returns the log of n choose r.  This means that it
   * can do the calculation in log space itself.
   *
   *             n!
   *   nCr =  ---------
   *          r! (n-r)!
   * 
   * which means:
   * 
   *   log(nCr) = log(n!) - (log(r!) + log((n-r)!))
   *
   * If the value of N as supplied here is greater than the
   * constructor parameter maxPopulationSize, the behavior of this
   * method is undefined.
   *
   */
  
  double logNCr(const int n,
		const int r);

  /*********************************************************************
   *
   * Return the value of log(n!) from the cache.
   *
   * If n > _maxPopulationSize, the the behavior of this method is
   * undefined.
   *
   */

  double logFactorial(const int n);

protected:

private:

  typedef std::map< std::pair< int, int >, double > LogNCrMap;
  typedef std::vector< double > LogFactorialList;

  /*********************************************************************
   *
   * Populate the cache of log(n!) values, _logNFactorialCache.
   *
   * The maximum factorial that will ever have to be calculated is for
   * _maxPopulationSize, so we wil cache that many. 
   *
   * Since :
   * 
   *        n! = n * (n-1) * (n-2) ... * 1
   * 
   * Then :
   * 
   *   log(n!) = log(n * (n-1) * (n-2) ... * 1)
   * 
   *           = log(n) + log(n-1) + log(n-2) ... + log(1)
   *
   */

  void buildLogFactorialCache();

  /*********************************************************************
   *
   * Compute and return the value of log(n choose r). This method is
   * used by logNCr(int, int) to populate the cache if the specified
   * pair of (n, r) has not already been seen.
   *
   */

  double computeLogNCr(const int n, 
		       const int r);

  /*********************************************************************
   *
   * The maximum population size as specified in the constructor. This
   * specifies the size of the cache of log(n!) values.
   *
   */

  int _maxPopulationSize;

  /*********************************************************************
   *
   * A cache of values of log(n choose r) keyed by pairs of input
   * values (n, r). Since the same pairs of n and r come up again and
   * again, we maintain them here.
   *
   */

  LogNCrMap _logNCrCache;

  /*********************************************************************
   *
   * A cache of values of log(n!). The value of the n-th element in
   * the list is the value of log(n!), where n <= _maxPopulationSize.
   *
   */

  LogFactorialList _logFactorialCache;

};
