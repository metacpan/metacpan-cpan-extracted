/*
 *  One file long C++ library of linear algebra primitives for
 *  simple 3D programs
 *
 *  Copyright (C) 2001-2003 by Jarno Elonen
 *
 *  Permission to use, copy, modify, distribute and sell this software
 *  and its documentation for any purpose is hereby granted without fee,
 *  provided that the above copyright notice appear in all copies and
 *  that both that copyright notice and this permission notice appear
 *  in supporting documentation.  The authors make no representations
 *  about the suitability of this software for any purpose.
 *  It is provided "as is" without express or implied warranty.
 *
 *  Slight modifications:
 *    - introduce namespace
 *    - use M_PI instead of private constant
 *    - split in .cc and .h
 *    Copyright (C) 2010 by Steffen Mueller (smueller -at- cpan -dot- org)
 */

#include "linalg3d.h"
#include <cmath>
#include "TPSException.h"

#define Deg2Rad(Ang) ((float)( Ang * M_PI / 180.0 ))
#define Rad2Deg(Ang) ((float)( Ang * 180.0 / M_PI ))

using namespace TPS;

// Left hand float multplication
inline Vec TPS::operator* ( const float src, const Vec& v ) { Vec tmp(v); return (tmp *= src); }

// Dot product
inline float TPS::dot(const Vec& a, const Vec& b) { return a.x*b.x + a.y*b.y + a.z*b.z; }

// Cross product
inline Vec TPS::cross(const Vec &a, const Vec &b) {
  return Vec( a.y*b.z - a.z*b.y, a.z*b.x - a.x*b.z, a.x*b.y - a.y*b.x );
}

// streaming
std::ostream&
TPS::operator<<(std::ostream& stream, Vec const& obj)
{
  obj.WriteTo(stream);
  return stream;
}

std::istream&
TPS::operator>>(std::istream& stream, Vec& obj)
{
  if (!stream.good())
    throw EndOfFileException();
  stream >> obj.x;
  if (!stream.good())
    throw EndOfFileException();
  stream >> obj.y;
  if (!stream.good())
    throw EndOfFileException();
  stream >> obj.z;
  return stream;
}



// Creates an identity matrix
Mtx::Mtx()
{
  for ( int i = 0; i < 16; ++i )
    data[ i ] = 0;
  data[ 0 + 0 ] = data[ 4 + 1 ] = data[ 8 + 2 ] = data[ 12 + 3 ] = 1;
}

// Returns the transpose of this matrix
Mtx Mtx::transpose() const
{
  Mtx m;
  int idx = 0;
  for ( int row = 0; row < 4; ++row ) {
    for ( int col = 0; col < 4; ++col, ++idx )
      m.data[ idx ] = data[ row + col*4 ];
  }
  return m;
}

// Creates a scale matrix
Mtx TPS::scale(const Vec& scale)
{
  Mtx m;
  m.data[0+0] = scale.x;
  m.data[4+1] = scale.y;
  m.data[8+2] = scale.z;
  return m;
}

// Creates a translation matrix
Mtx TPS::translate(const Vec& moveAmt)
{
  Mtx m;
  m.data[0+3] = moveAmt.x;
  m.data[4+3] = moveAmt.y;
  m.data[8+3] = moveAmt.z;
  return m;
}

// Creates an euler rotation matrix (by X-axis)
Mtx TPS::rotateX(float ang)
{
  float s = (float) sin(Deg2Rad(ang));
  float c = (float) cos(Deg2Rad(ang));

  Mtx m;
  m.data[4+1] = c; m.data[4+2] = -s;
  m.data[8+1] = s; m.data[8+2] = c;
  return m;
}

// Creates an euler rotation matrix (by Y-axis)
Mtx TPS::rotateY(float ang)
{
  float s = (float) sin( Deg2Rad( ang ) );
  float c = (float) cos( Deg2Rad( ang ) );

  Mtx m;
  m.data[ 0 + 0 ] = c; m.data[ 0 + 2 ] = s;
  m.data[ 8 + 0 ] = -s; m.data[ 8 + 2 ] = c;
  return m;
}

// Creates an euler rotation matrix (by Z-axis)
Mtx TPS::rotateZ(float ang)
{
  float s = (float) sin( Deg2Rad( ang ) );
  float c = (float) cos( Deg2Rad( ang ) );

  Mtx m;
  m.data[ 0 + 0 ] = c; m.data[ 0 + 1 ] = -s;
  m.data[ 4 + 0 ] = s; m.data[ 4 + 1 ] = c;
  return m;
}

// Creates an euler rotation matrix (pitch/head/roll (x/y/z))
Mtx TPS::rotate(float pitch, float head, float roll)
{
  float sp = (float) sin( Deg2Rad( pitch ) );
  float cp = (float) cos( Deg2Rad( pitch ) );
  float sh = (float) sin( Deg2Rad( head ) );
  float ch = (float) cos( Deg2Rad( head ) );
  float sr = (float) sin( Deg2Rad( roll ) );
  float cr = (float) cos( Deg2Rad( roll ) );

  Mtx m;
  m.data[ 0 + 0 ] = cr * ch - sr * sp * sh;
  m.data[ 0 + 1 ] = -sr * cp;
  m.data[ 0 + 2 ] = cr * sh + sr * sp * ch;

  m.data[ 4 + 0 ] = sr * ch + cr * sp * sh;
  m.data[ 4 + 1 ] = cr * cp;
  m.data[ 4 + 2 ] = sr * sh - cr * sp * ch;

  m.data[ 8 + 0 ] = -cp * sh;
  m.data[ 8 + 1 ] = sp;
  m.data[ 8 + 2 ] = cp * ch;
  return m;
}

// Creates an arbitraty rotation matrix
Mtx TPS::makeRotationMatrix(const Vec& dir, const Vec& up)
{
  Vec x = cross(up, dir), y = cross(dir, x), z = dir;
  Mtx m;
  m.data[ 0 ] = x.x; m.data[ 1 ] = x.y; m.data[ 2 ] = x.z;
  m.data[ 4 ] = y.x; m.data[ 5 ] = y.y; m.data[ 6 ] = y.z;
  m.data[ 8 ] = z.x; m.data[ 9 ] = z.y; m.data[ 10 ] = z.z;
  return m;
}

// Multiplies a matrix by another matrix
Mtx TPS::operator* (const Mtx& a, const Mtx& b)
{
  Mtx ans;
  for ( int aRow = 0; aRow < 4; ++aRow )
    for ( int bCol = 0; bCol < 4; ++bCol ) {
      int aIdx = aRow * 4;
      int bIdx = bCol;

      float val = 0;
      for ( int idx = 0; idx < 4; ++idx, ++aIdx, bIdx += 4 )
        val += a.data[ aIdx ] * b.data[ bIdx ];
      ans.data[ bCol + aRow * 4 ] = val;
    }
  return ans;
}

// =========================================
// Plane
// =========================================

// Classifies a point (<0 == back, 0 == on plane, >0 == front)
float Plane::classify(const Vec& pt)
  const
{
  float f = dot( normal, pt ) + d;
  return ( f > -kEPSILON && f < kEPSILON ) ? 0 : f;
}

