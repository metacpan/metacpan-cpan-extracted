#ifndef __linalg3d_h
#define __linalg3d_h

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

#include <cmath>
#include <iostream>

// =========================================
// 3-vector
// =========================================
namespace TPS {

  static const double kEPSILON = 1.e-5;
  class Vec {
  public:

    // Position
    float x, y, z;

    // Default constructor
    Vec()
      : x( 0 ), y( 0 ), z( 0 ) {}

    Vec( float x, float y, float z )
      : x( x ), y( y ), z( z ) {}

    Vec( const Vec& a )
      : x( a.x ), y( a.y ), z( a.z ) {}

    /// Norm (len^2)
    inline float norm() const { return x*x + y*y + z*z; }

    /// Length of the vector
    inline float len() const { return (float)sqrt(norm()); }

    Vec &operator+= (const Vec& src) { x += src.x; y += src.y; z += src.z; return *this; }
    Vec operator+ (const Vec& src) const { Vec tmp( *this ); return ( tmp += src ); }
    Vec &operator-= (const Vec& src) { x -= src.x; y -= src.y; z -= src.z; return *this; }
    Vec operator- (const Vec& src) const { Vec tmp( *this ); return ( tmp -= src ); }

    Vec operator- () const { return Vec(-x,-y,-z); }

    Vec &operator*= (const float src) { x *= src; y *= src; z *= src;  return *this; }
    Vec operator* (const float src) const { Vec tmp( *this ); return ( tmp *= src ); }
    Vec &operator/= (const float src) { x /= src; y /= src; z /= src; return *this; }
    Vec operator/ (const float src) const { Vec tmp( *this ); return ( tmp /= src ); }

    bool operator== (const Vec& b) const { return (*this-b).norm() < kEPSILON; }
    
    void WriteTo(std::ostream& stream) const { stream << x << " " << y << " " << z; }
  };

  std::ostream& operator<<(std::ostream& stream, Vec const& obj);
  std::istream& operator>>(std::istream& stream, Vec& obj);


  /// Left hand float multplication
  Vec operator* (const float src, const Vec& v);

  /// Dot product
  float dot(const Vec& a, const Vec& b);

  /// Cross product
  Vec cross(const Vec &a, const Vec &b);


  // =========================================
  // 4 x 4 matrix
  // =========================================
  class Mtx {
  public:

    // 4x4, [[0 1 2 3] [4 5 6 7] [8 9 10 11] [12 13 14 15]]
    float data[ 16 ];

    /// Creates an identity matrix
    Mtx();
    /// Returns the transpose of this matrix
    Mtx transpose() const;

    // Operators
    float operator() (unsigned column, unsigned row)
    { return data[ column + row*4 ]; }
  };

  /// Creates a scale matrix
  Mtx scale(const Vec& scale);

  /// Creates a translation matrix
  Mtx translate(const Vec& moveAmt);

  /// Creates an euler rotation matrix (by X-axis)
  Mtx rotateX(float ang);

  /// Creates an euler rotation matrix (by Y-axis)
  Mtx rotateY(float ang);

  /// Creates an euler rotation matrix (by Z-axis)
  Mtx rotateZ(float ang);

  /// Creates an euler rotation matrix (pitch/head/roll (x/y/z))
  Mtx rotate(float pitch, float head, float roll);

  /// Creates an arbitraty rotation matrix
  Mtx makeRotationMatrix(const Vec& dir, const Vec& up);

  /// Transforms a vector by a matrix
  inline Vec operator* (const Vec& v, const Mtx& m)
  {
    return Vec(
      m.data[ 0 ] * v.x + m.data[ 1 ] * v.y + m.data[ 2 ] * v.z + m.data[ 3 ],
      m.data[ 4 ] * v.x + m.data[ 5 ] * v.y + m.data[ 6 ] * v.z + m.data[ 7 ],
      m.data[ 8 ] * v.x + m.data[ 9 ] * v.y + m.data[ 10 ] * v.z + m.data[ 11 ] );
  }

  /// Multiplies a matrix by another matrix
  Mtx operator* (const Mtx& a, const Mtx& b);

  // =========================================
  // Plane
  // =========================================
  class Plane {
  public:
    enum PLANE_EVAL
    {
      EVAL_COINCIDENT,
      EVAL_IN_BACK_OF,
      EVAL_IN_FRONT_OF,
      EVAL_SPANNING
    };

    Vec normal;
    float d;

    /// Default constructor
    Plane(): normal( 0,1,0 ), d( 0 ) {}

    /** Vector form constructor
     *  normal = normalized normal of the plane
     *  pt = any point on the plane
     */
    Plane( const Vec& normal, const Vec& pt )
      : normal( normal ), d( dot( -normal, pt )) {}

    Plane( const Plane& a )
      : normal( a.normal ), d( a.d ) {}

    // Classifies a point (<0 == back, 0 == on plane, >0 == front)
    float classify(const Vec& pt) const;
  };
} // end namespace TPS

#endif
