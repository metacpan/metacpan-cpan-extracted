/* test_fn.h           example header file for a quadratic function for use with macopt

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

#ifndef TEST_FN_H
#define TEST_FN_H

#include "macopt.h"

class Test_fn : public Macopt
{
public:
  Test_fn(int _n);
  ~Test_fn();
  double func(double* _p);
  void dfunc(double* _p, double* _g);
  void qdfunc(double *x, double *g);
  void Atimesh( double *x , double *h , double *v);

  int param_n;
  double **param_A, *param_b;
};


#endif

