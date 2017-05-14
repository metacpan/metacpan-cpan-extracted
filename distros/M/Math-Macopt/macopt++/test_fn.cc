/* test_fn.c       example quadratic function for use with macopt

   (c) 2002 David J.C. MacKay and Steve Waterhouse
  
    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

    GNU licenses are here :
    http://www.gnu.org/licenses/licenses.html

    Author contact details are here :
    http://www.inference.phy.cam.ac.uk/mackay/c/macopt.html       mackay@mrao.cam.ac.uk
*/

#include <stdio.h> 
#include "test_fn.h"

Test_fn::Test_fn(int _n) : 
  Macopt(_n), 
  param_n(_n)
{
  param_A= new double* [param_n+1];
  for(int n = 0; n < param_n+1; n ++) {
    param_A[n] = new double[param_n+1];
  }
  param_b = new double[param_n+1];
}

Test_fn::~Test_fn() {

}


double Test_fn::func(double *x)
{
  int i,j;
  double f=0.0,g;
 
  printf ( "quadr. at " ) ;
  for ( i = 1 ; i <= param_n ; i++ ) printf( "%g " , x[i] ) ;
  for ( i = 1 ; i <= param_n ; i++ ) {
    g=0.0;
    for(j=1;j<=param_n;j++){
      g += param_A[i][j] * x[j];
    }
    f+=x[i]*(g/2.0 - param_b[i]);
  }
  printf(" : %g\n",f);
  return(f); 
}

void Test_fn::dfunc(double *x, double *g)
{
  int i,j;
  double f=0.0;
  printf ( "grad_q at " ) ;
  for ( i = 1 ; i <= param_n ; i++ ) printf ( "%g " , x[i] ) ;
  for ( i = 1 ; i <= param_n ; i++ ) {
    g[i] = 0.0 ;
    for ( j = 1 ; j <= param_n ; j++ ) {
      g[i] += param_A[i][j] * x[j] ;
    }
    f += x[i] * ( g[i] / 2.0 - param_b[i] ) ;
    g[i] -= param_b[i] ;
  }
  printf ( " :: %g :: " , f ) ;
  for ( i = 1 ; i <= param_n ; i++ ) printf ( "%g " , g[i] ) ;
  printf ( "\n" ) ;
//  return ( f ) ;
}


void Test_fn::qdfunc(double *x, double *g)
{
  int i,j;
  double f=0.0;
  printf ( "grad_q at " ) ;
  for ( i = 1 ; i <= param_n ; i++ ) printf ( "%g " , x[i] ) ;
  for ( i = 1 ; i <= param_n ; i++ ) {
    g[i] = 0.0 ;
    for ( j = 1 ; j <= param_n ; j++ ) {
      g[i] += param_A[i][j] * x[j] ;
    }
    f += x[i] * ( g[i] / 2.0 - param_b[i] ) ;
    g[i] -= param_b[i] ;
  }
  printf ( " :: %g :: " , f ) ;
  for ( i = 1 ; i <= param_n ; i++ ) printf ( "%g " , g[i] ) ;
  printf ( "\n" ) ;
}

void Test_fn::Atimesh( double *x , double *h , double *v)
{ /* This ignores the first argument */
  int i,j;

  for ( i = 1 ; i <= param_n ; i++ ) {
    v[i] = 0 ;
    for ( j = 1 ; j <= param_n ; j++ ) {
      v[i] += param_A[i][j] * h[j] ;
    }
  }
}
