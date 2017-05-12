/*  Copyright Ton Dieker                                                    */
/*  Centre of Mathematics and Computer Science (CWI) Amsterdam              */
/*  April 2002                                                              */

/*  ton@cwi.nl                                                              */


#include <math.h>

extern double covariance(long i, double H) {
  if (i == 0) return 1;
  else return (pow(i-1,2*H)-2*pow(i,2*H)+pow(i+1,2*H))/2;
}
