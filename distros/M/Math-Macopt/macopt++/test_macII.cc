/* test_macII.c           example executable that minimizes a quadratic function using macopt

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
#include "r.h"
#include "macopt.h"

/* 
   test program for macopt solution of equation A x = b. 

   this equation is solved by minimizing the function 1/2 xAx - bx
*/
   
#include "test_fn.h"

int main(int argc, char *argv[])
{
  double *x ;
  int n ;
  double epsilon=0.001 ;

  /* Load up the parameters of the function that you want to optimize */
  printf("============================================================\n");
  printf("= Demonstration program for macopt                         =\n");
  printf("= Solves A x = b by minimizing the function 1/2 xAx - bx   =\n");
  printf("= A must be positive definite (e.g. 2 1 1 2)               =\n");
  printf("\n  Dimension of A (eg 2)?\n");

  inputi(&(n));

  Test_fn* test_fn = new Test_fn(n);

  x=dvector(1,n);

  typeindmatrix(test_fn->param_A, 1, n, 1, n);

  printf("  b vector?\n");

  typeindvector(test_fn->param_b,1,n);

  printf("  Initial condition x?\n");

  typeindvector(x,1,n);

  /* Check that the gradient_function is the gradient of the function  */
  /* You don't have to do this, but it is a good idea when debugging ! */

  test_fn->maccheckgrad (  x , n , epsilon , 0 ) ;

  /* Do an optimization */
  test_fn->macoptII ( x , n ) ;

  printf("Solution:\n");
  test_fn->func(x);
}
