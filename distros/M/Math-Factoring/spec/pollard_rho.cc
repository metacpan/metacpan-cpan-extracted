/**************************************************************************
*	pollard_rho.cc - Use Pollard's "rho" method to factor a large integer
*
*	Uses Pollard's Rho alg. to factor a large integer into smaller 
*	pieces until all pieces are prime. Code was based on a factor 
*	program (included in the gmp library), as well as outlines of the alg.
*	found everywhere on the internet.
*
*	Compile:
*	g++ -s -O4 -o pollard_rho pollard_rho.cc
*	Invoke:
*	./pollard_rho NumberToFactor
*	Where NumberToFactor is the number you wish to factor
*
* ChangeLog:
* 970301 -- Created by Paul Herman <a540pau@pslc.ucla.edu>
************************************************************************/

#include <Integer.h>

#define random() rand()

Integer factor(Integer n, int a_int, int x0)
{
  Integer x, y, q, a, d;
  int i = 1, j = 1;

  q = 1; a = a_int; x = x0; y = x0;

  for (;;) {
	x  = (x*x + a)  %  n;
	y  = (y*y + a)  %  n;
	y  = (y*y + a)  %  n;
	q *= (x - y); q %= n;

	i++;
	if (!j) j=1;
	if ( (i % j) == 0) {
	  j++;
	  d = gcd(q, n);
	  if (d != 1) {
		if (!isprime(d))
			return factor(d, (random() & 32) - 16, random() & 31);
		else return d;
       }
    } 
  } // while n != 1
	return 0;
}


main (int argc, char *argv[])
{
	Integer n, t;
	int x0, a;
	int p;

    if (argc != 2) { cerr << "Usage: " << argv[0] << " NumberToFactor" << endl;
    return -1; }

	n = argv[1];

	a = -1;
	x0 = 3;

	cout << n << ": " << flush;
	while (!isprime(n)) {
		t = factor(n, a, x0);
		if (t==0) break;
		cout << t << " " << flush;
		n /= t;
		}
	cout << n << endl;
	return 0;
}
