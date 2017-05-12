/***********************************************************************
 *
 * File        : Distributions.cxx
 * Author      : Ihab A.B. Awad
 * Date Begun  : October 08 2004
 *
 * $Id: Distributions.cxx,v 1.7 2009/11/19 17:27:52 sherlock Exp $
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

#include "Distributions.hxx"

#include <stdio.h>
#include <math.h>
#include <stdlib.h>

Distributions::Distributions(const int maxPopulationSize)
{
  this->_maxPopulationSize = maxPopulationSize;
  buildLogFactorialCache();
}

Distributions::~Distributions()
{
}

double 
Distributions::pValueByHypergeometric(const int x, 
				      const int n, 
				      const int M, 
				      const int N)
{
  int min = (M < n) ? M : n;
  double pValue = 0;

  /* do some error checking */

  if ((N - M) < (n - x)){

    /* this situation should never arise, because the number of
     * failures in the sampling cannot exceed the total number of
     * failures in the population.  For example, if all but one gene
     * has a particular annotation, then you can't pick 3 genes and
     * get 2 without it
     */

    fprintf(stderr, "For N, M, n, x being %d, %d, %d, %d, (N - M) < (n - x), which is impossible\n", N, M, n, x);
    exit(1);
	
  }else if (x > n){

    fprintf(stderr, "For n, x being %d, %d, n < x, which is impossible\n", n, x);
    exit(1);

  }else if (M > N){

    fprintf(stderr, "For N, M being %d, %d, N < M, which is impossible\n", N, M);
    exit(1);

  }

  for (int i = x; i <= min; i++) {
    pValue += this->hypergeometric(i, n, M, N);
  }

  if (pValue > 1){ /* fix rounding errors */

    pValue = 1;
  }

  return pValue;

}

double
Distributions::hypergeometric(const int x,
			      const int n,
			      const int M,
			      const int N)
{
  double z =
    this->logNCr(M, x) +
    this->logNCr(N - M, n - x)  -
    this->logNCr(N, n);
  return exp(z);
}

double
Distributions::logNCr(const int n,
		      const int r)
{
  const std::pair< int, int > key(n, r);
  LogNCrMap::const_iterator found = this->_logNCrCache.find(key);

  if (found != this->_logNCrCache.end()) {

    return found->second;

  } else {

    double value = computeLogNCr(n, r);
    std::pair< std::pair< int, int >, double > entry(key, value);
    this->_logNCrCache.insert(entry);
    return value;
  }
}

double
Distributions::computeLogNCr(const int n,
			     const int r)
{
  return
    this->logFactorial(n) - 
    (this->logFactorial(r) + this->logFactorial(n - r));
}

void 
Distributions::buildLogFactorialCache()
{
  this->_logFactorialCache.resize(this->_maxPopulationSize + 1);

  this->_logFactorialCache[0] = 0;
  this->_logFactorialCache[1] = 0;

  for (int i = 2; i < this->_maxPopulationSize + 1; i++) {
    this->_logFactorialCache[i] = this->_logFactorialCache[i - 1] + log(i);
  }
}

double
Distributions::logFactorial(const int n)
{
  return this->_logFactorialCache[n];
}
