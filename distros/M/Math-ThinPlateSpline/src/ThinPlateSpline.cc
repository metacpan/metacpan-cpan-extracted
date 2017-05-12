/*
 *  Thin Plate Spline class that was created on the basis of "tpsdemo".
 *  "tpsdemo" comes with the following copyright and license. This
 *  library adopts the same license.
 *
 *  Thin Plate Spline demo/example in C++
 *
 *  - a simple TPS editor, using the Boost uBlas library for large
 *    matrix operations and OpenGL + GLUT for 2D function visualization
 *    (curved plane) and user interface
 *
 *  Copyright (C) 2003,2005 by Jarno Elonen
 *
 *  TPSDemo is Free Software / Open Source with a very permissive
 *  license:
 *
 *  Permission to use, copy, modify, distribute and sell this software
 *  and its documentation for any purpose is hereby granted without fee,
 *  provided that the above copyright notice appear in all copies and
 *  that both that copyright notice and this permission notice appear
 *  in supporting documentation.  The authors make no representations
 *  about the suitability of this software for any purpose.
 *  It is provided "as is" without express or implied warranty.
 *
 *  TODO:
 *    - implement TPS approximation 3 as suggested in paper
 *      Gianluca Donato and Serge Belongie, 2002: "Approximation
 *      Methods for Thin Plate Spline Mappings and Principal Warps"
 *
 *  -- END tpsdemo copyright and license --
 *
 *  The changes from tpsdemo to this library are
 *    Copyright (C) 2010 by Steffen Mueller (smueller -at- cpan -dot- org)
 *
 */
#include "ThinPlateSpline.h"
#include <boost/numeric/ublas/matrix.hpp>

#include "linalg3d.h"
#include "ludecomposition.h"

#include <vector>
#include <cmath>
#include <string>
#include <sstream>
#include <iostream>

using namespace boost::numeric::ublas;
using namespace std;
using namespace TPS;

ThinPlateSpline::ThinPlateSpline() :
  fRegularization(0.)
{
}


ThinPlateSpline::ThinPlateSpline(const std::vector<Vec>& controlPoints, const double regularization) :
  fRegularization(regularization), fControlPoints(controlPoints)
{
  InitializeMatrix();
}


ThinPlateSpline::ThinPlateSpline(std::istream& input)
{
  input >> fRegularization;
  unsigned int nPoints;
  input >> nPoints;
  fControlPoints.resize(nPoints);
  for (unsigned int iPoint = 0; iPoint < nPoints; ++iPoint)
    input >> fControlPoints[iPoint];

  fMtx_l = ReadMatrix(input);
  fMtx_v = ReadMatrix(input);
  fMtx_orig_k = ReadMatrix(input);
}


void ThinPlateSpline::InitializeMatrix()
{
  const unsigned int p = fControlPoints.size();
  if (p < 3)
    throw NotEnoughControlPointsException();

  // Allocate the matrix
  fMtx_l = matrix<double>(p+3, p+3);
  fMtx_v = matrix<double>(p+3, 1);
  fMtx_orig_k = matrix<double> (p, p);

  // Fill K (p x p, upper left of L) and calculate
  // mean edge length from control points
  //
  // K is symmetrical so we really have to
  // calculate only about half of the coefficients.
  double a = 0.0;
  for (unsigned int i = 0; i < p; ++i) {
    for (unsigned int j = i+1; j < p; ++j) {
      Vec pt_i = fControlPoints[i];
      Vec pt_j = fControlPoints[j];
      pt_i.y = pt_j.y = 0;
      double elen = (pt_i - pt_j).len();
      fMtx_l(i,j) = fMtx_l(j,i) =
        fMtx_orig_k(i,j) = fMtx_orig_k(j,i) = tps_base_func(elen);
      a += elen * 2; // same for upper & lower tri
    }
  }
  a /= (double)(p*p);

  // Fill the rest of L
  for (unsigned int i = 0; i < p; ++i) {
    // diagonal: reqularization parameters (lambda * a^2)
    fMtx_l(i,i) = fMtx_orig_k(i,i) = fRegularization * (a*a);

    // P (p x 3, upper right)
    fMtx_l(i, p+0) = 1.0;
    fMtx_l(i, p+1) = fControlPoints[i].x;
    fMtx_l(i, p+2) = fControlPoints[i].z;

    // P transposed (3 x p, bottom left)
    fMtx_l(p+0, i) = 1.0;
    fMtx_l(p+1, i) = fControlPoints[i].x;
    fMtx_l(p+2, i) = fControlPoints[i].z;
  }
  // O (3 x 3, lower right)
  for (unsigned int i = p; i < p+3; ++i)
    for (unsigned int j = p; j < p+3; ++j)
      fMtx_l(i,j) = 0.0;

  // Fill the right hand vector V
  for (unsigned int i = 0; i < p; ++i)
    fMtx_v(i,0) = fControlPoints[i].y;
  fMtx_v(p+0, 0) = fMtx_v(p+1, 0) = fMtx_v(p+2, 0) = 0.0;

  // Solve the linear system "inplace"
  if (0 != LU_Solve(fMtx_l, fMtx_v))
    throw SingularMatrixException();

/*
  // Interpolate grid heights
  for ( int x=-GRID_W/2; x<GRID_W/2; ++x )
  {
    for ( int z=-GRID_H/2; z<GRID_H/2; ++z )
    {
      double h = fMtx_v(p+0, 0) + fMtx_v(p+1, 0)*x + fMtx_v(p+2, 0)*z;
      Vec pt_i, pt_cur(x,0,z);
      for ( unsigned i=0; i<p; ++i )
      {
        pt_i = control_points[i];
        pt_i.y = 0;
        h += fMtx_v(i,0) * tps_base_func( ( pt_i - pt_cur ).len());
      }
      grid[x+GRID_W/2][z+GRID_H/2] = h;
    }
  }
*/
}


double
ThinPlateSpline::Evaluate(const double x, const double y)
  const
{
  const unsigned int p = fControlPoints.size();
  double h = fMtx_v(p+0, 0) + fMtx_v(p+1, 0)*x + fMtx_v(p+2, 0)*y;
  Vec pt_i;
  Vec pt_cur(x, 0, y);
  for (unsigned int i = 0; i < p; ++i) {
    pt_i = fControlPoints[i];
    pt_i.y = 0;
    h += fMtx_v(i,0) * tps_base_func( (pt_i-pt_cur).len() );
  }
  return h;
}


std::vector<double>
ThinPlateSpline::Evaluate(const std::vector<double>& x, const std::vector<double>& y)
  const
{
  const unsigned int s = x.size();
  if (s != y.size())
    throw BadNoCoordinatesException();

  const unsigned int np = fControlPoints.size();

  std::vector<double> z(s);
  for (unsigned int j = 0; j < s; ++j) {
    const double xi = x[j];
    const double yi = y[j];
    double h = fMtx_v(np+0, 0) + fMtx_v(np+1, 0)*xi + fMtx_v(np+2, 0)*yi;
    Vec pt_i;
    Vec pt_cur(xi, 0, yi);
    for (unsigned int i = 0; i < np; ++i) {
      pt_i = fControlPoints[i];
      pt_i.y = 0;
      h += fMtx_v(i,0) * tps_base_func( (pt_i-pt_cur).len() );
    }
    z[j] = h;
  }
  return z;
}


double
ThinPlateSpline::GetBendingEnergy()
  const
{
  // Calc bending energy
  const unsigned int p = fControlPoints.size();
  matrix<double> w(p, 1);
  for (unsigned int i = 0; i < p; ++i)
    w(i, 0) = fMtx_v(i, 0);
  matrix<double> be = prod( prod<matrix<double> >( trans(w), fMtx_orig_k ), w );
  const double bending_energy = be(0, 0);
  return bending_energy;
}


double ThinPlateSpline::tps_base_func(double r)
{
  if ( r == 0.0 )
    return 0.0;
  else
    return r*r * log(r);
}


void
ThinPlateSpline::WriteToStream(std::ostream& stream)
  const
{
  const unsigned int p = fControlPoints.size();
  stream << fRegularization << "\n" << p << "\n";
  for (unsigned int i = 0; i < p; i++)
    stream << fControlPoints[i] << " ";

  stream << "\n";
  DumpMatrix(stream, fMtx_l);
  stream << "\n";
  DumpMatrix(stream, fMtx_v);
  stream << "\n";
  DumpMatrix(stream, fMtx_orig_k);
  stream << "\n";
}


void
ThinPlateSpline::DumpMatrix(std::ostream& stream, const boost::numeric::ublas::matrix<double>& matrix)
  const
{
  stream << matrix.size1() << " " << matrix.size2() << "\n";
  for (unsigned i = 0; i < matrix.size1(); ++i) {
    for (unsigned j = 0; j < matrix.size2(); ++j)
      stream << matrix(i, j) << " ";
  }
}


boost::numeric::ublas::matrix<double>
ThinPlateSpline::ReadMatrix(std::istream& in)
  const
{
  unsigned int size1, size2;
  in >> size1;
  in >> size2;
  matrix<double> m(size1, size2);

  double value;
  for (unsigned i = 0; i < size1; ++i) {
    for (unsigned j = 0; j < size2; ++j) {
      in >> value;
      m(i, j) = value;
    }
  }

  return m;
}

std::ostream&
TPS::operator<<(std::ostream& stream, const ThinPlateSpline& tps) {
  tps.WriteToStream(stream);
  return stream;
}

