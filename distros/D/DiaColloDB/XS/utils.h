//-*- Mode: C++ -*-

#ifndef DIACOLLO_XS_UTILS_H
#define DIACOLLO_XS_UTILS_H

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <errno.h>
#include <inttypes.h> //-- PRIu32 etc.

#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h> //-- struct stat, fstat()

#include <string>
#include <map>
#include <vector>
#include <algorithm>
#include <typeinfo> //-- for typeid()
#include <stdexcept> //-- std::runtime_error etc.

using namespace std;

//======================================================================
// Format (printf substitute)

#include <stdarg.h>

string Format(const char *fmt, ...)
{
  char *buf = NULL;
  size_t len=0;
  va_list ap;
  va_start(ap,fmt);
  len = vasprintf(&buf,fmt,ap);
  va_end(ap);
  string s(buf,len);
  if (buf) free(buf);
  return s;
};


/*======================================================================
 * generic utilities: byte-order and swapping
 *  see https://stackoverflow.com/questions/4239993/determining-endianness-at-compile-time/4240029
 *  and https://codereview.stackexchange.com/questions/64797/byte-swapping-functions
 */

#if defined(__BYTE_ORDER) && __BYTE_ORDER == __BIG_ENDIAN || \
    defined(__BIG_ENDIAN__) || \
    defined(__ARMEB__) || \
    defined(__THUMBEB__) || \
    defined(__AARCH64EB__) || \
    defined(_MIBSEB) || defined(__MIBSEB) || defined(__MIBSEB__)
// It's a big-endian target architecture
# define T2C_BIG_ENDIAN 1
//# warning "native byte-order: big-endian"
#elif defined(__BYTE_ORDER) && __BYTE_ORDER == __LITTLE_ENDIAN || \
    defined(__LITTLE_ENDIAN__) || \
    defined(__ARMEL__) || \
    defined(__THUMBEL__) || \
    defined(__AARCH64EL__) || \
    defined(_MIPSEL) || defined(__MIPSEL) || defined(__MIPSEL__)
// It's a little-endian target architecture
# define T2C_LITTLE_ENDIAN 1
//# warning "native byte-order: little-endian"
#else
# error "Can't determine architecture byte order!"
#endif

inline uint16_t _bswap16(uint16_t a)
{
  a = ((a & 0x00FF) << 8) | ((a & 0xFF00) >> 8);
  return a;
}
inline uint32_t _bswap32(uint32_t a)
{
  a = ((a & 0x000000FF) << 24) |
      ((a & 0x0000FF00) <<  8) |
      ((a & 0x00FF0000) >>  8) |
      ((a & 0xFF000000) >> 24);
  return a;
}
inline uint64_t _bswap64(uint64_t a)
{
  a = ((a & 0x00000000000000FFULL) << 56) | 
      ((a & 0x000000000000FF00ULL) << 40) | 
      ((a & 0x0000000000FF0000ULL) << 24) | 
      ((a & 0x00000000FF000000ULL) <<  8) | 
      ((a & 0x000000FF00000000ULL) >>  8) | 
      ((a & 0x0000FF0000000000ULL) >> 24) | 
      ((a & 0x00FF000000000000ULL) >> 40) | 
      ((a & 0xFF00000000000000ULL) >> 56);
  return a;
}

union swapfU { float f; uint32_t i; };
inline float _bswapf(float f)
{
  swapfU u;
  u.f = f;
  u.i = _bswap32(u.i);
  return u.f;
};

union swapgU { double g; uint64_t i; };
inline double _bswapg(double g) {
  swapgU u;
  u.g = g;
  u.i = _bswap64(u.i);
  return u.g;
};


//-- val = bin2native(val_bigEndian)
#if T2C_BIG_ENDIAN
# define _bin2native(sz)
#else
# define _bin2native(sz) _bswap ## sz
#endif

inline uint16_t binval(uint16_t val) { return _bin2native(16)(val); };
inline uint32_t binval(uint32_t val) { return _bin2native(32)(val); };
inline uint64_t binval(uint64_t val) { return _bin2native(64)(val); };
inline float    binval(float    val) { return _bin2native(f)(val); };
inline double   binval(double   val) { return _bin2native(g)(val); };

/*======================================================================
 * generic utilities: type names (for error messages)
 */
template<typename T> const char* typestr() { return typeid(T).name(); };
template<> const char* typestr<uint8_t>() { return "uint8_t"; };
template<> const char* typestr<uint16_t>() { return "uint16_t"; };
template<> const char* typestr<uint32_t>() { return "uint32_t"; };
template<> const char* typestr<uint64_t>() { return "uint64_t"; };
template<> const char* typestr<float>() { return "float"; };
template<> const char* typestr<double>() { return "double"; };

/*======================================================================
 * generic utilities: type formats (for scanf)
 */
template<typename T>
const char* scanItemFormat()
{ throw runtime_error(Format("scanItemFormat(): unknown type `%s'", typestr<T>())); };

//template<> const char* scanItemFormat<uint8_t>() { return SCNu8; };
template<> const char* scanItemFormat<uint16_t>() { return SCNu16; };
template<> const char* scanItemFormat<uint32_t>() { return SCNu32; };
template<> const char* scanItemFormat<uint64_t>() { return SCNu64; };
template<> const char* scanItemFormat<float>() { return "f"; };
template<> const char* scanItemFormat<double>() { return "g"; };


#endif /* DIACOLLO_XS_UTILS_H */
