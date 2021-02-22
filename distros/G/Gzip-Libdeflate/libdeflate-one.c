/*
Copyright 2016 Eric Biggers

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation files
(the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge,
publish, distribute, sublicense, and/or sell copies of the Software,
and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/
/* /usr/home/ben/projects/gzip-libdeflate/../../software/libdeflate-1.7/lib/adler32.c */


/* #include "lib_common.h" */


#ifndef LIB_LIB_COMMON_H
#define LIB_LIB_COMMON_H

#ifdef LIBDEFLATE_H
#  error "lib_common.h must always be included before libdeflate.h"
   
#endif

#define BUILDING_LIBDEFLATE

/* #include "../common/common_defs.h" */


#ifndef COMMON_COMMON_DEFS_H
#define COMMON_COMMON_DEFS_H

#ifdef __GNUC__
/* #  include "compiler_gcc.h" */


#if !defined(__clang__) && !defined(__INTEL_COMPILER)
#  define GCC_PREREQ(major, minor)		\
	(__GNUC__ > (major) ||			\
	 (__GNUC__ == (major) && __GNUC_MINOR__ >= (minor)))
#else
#  define GCC_PREREQ(major, minor)	0
#endif


#ifdef __clang__
#  ifdef __apple_build_version__
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__apple_build_version__ >= (apple_version))
#  else
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__clang_major__ > (major) ||			\
	 (__clang_major__ == (major) && __clang_minor__ >= (minor)))
#  endif
#else
#  define CLANG_PREREQ(major, minor, apple_version)	0
#endif

#ifndef __has_attribute
#  define __has_attribute(attribute)	0
#endif
#ifndef __has_feature
#  define __has_feature(feature)	0
#endif
#ifndef __has_builtin
#  define __has_builtin(builtin)	0
#endif

#ifdef _WIN32
#  define LIBEXPORT __declspec(dllexport)
#else
#  define LIBEXPORT __attribute__((visibility("default")))
#endif

#define inline			inline
#define forceinline		inline __attribute__((always_inline))
#define restrict		__restrict__
#define likely(expr)		__builtin_expect(!!(expr), 1)
#define unlikely(expr)		__builtin_expect(!!(expr), 0)
#define prefetchr(addr)		__builtin_prefetch((addr), 0)
#define prefetchw(addr)		__builtin_prefetch((addr), 1)
#define _aligned_attribute(n)	__attribute__((aligned(n)))

#define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE	\
	(GCC_PREREQ(4, 4) || __has_attribute(target))

#if COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE

#  if defined(__i386__) || defined(__x86_64__)

#    define COMPILER_SUPPORTS_PCLMUL_TARGET	\
	(GCC_PREREQ(4, 4) || __has_builtin(__builtin_ia32_pclmulqdq128))

#    define COMPILER_SUPPORTS_AVX_TARGET	\
	(GCC_PREREQ(4, 6) || __has_builtin(__builtin_ia32_maxps256))

#    define COMPILER_SUPPORTS_BMI2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_pdep_di))

#    define COMPILER_SUPPORTS_AVX2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_psadbw256))

#    define COMPILER_SUPPORTS_AVX512BW_TARGET	\
	(GCC_PREREQ(5, 1) || __has_builtin(__builtin_ia32_psadbw512))

	
#    if GCC_PREREQ(4, 9) || CLANG_PREREQ(3, 8, 7030000)
#      define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS	1
#      define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_PCLMUL_TARGET
#      define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX2_TARGET
#      define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX512BW_TARGET
#    endif

#  elif defined(__arm__) || defined(__aarch64__)

    
#    if (GCC_PREREQ(6, 1) && defined(__ARM_FP)) || \
        (defined(__clang__) && defined(__ARM_NEON))
#      define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 1
       
#      if defined(__clang__) && defined(__arm__)
#        undef __ARM_FEATURE_CRYPTO
#      elif __has_builtin(__builtin_neon_vmull_p64) || !defined(__clang__)
#        define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 1
#      endif
#    endif

     
#    if GCC_PREREQ(10, 1) || \
        (GCC_PREREQ(9, 3) && !GCC_PREREQ(10, 0)) || \
        (GCC_PREREQ(8, 4) && !GCC_PREREQ(9, 0)) || \
        (defined(__clang__) && __has_builtin(__builtin_arm_crc32b))
#      define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 1
#    endif

#  endif 

#endif 


#if (GCC_PREREQ(4, 0) && !GCC_PREREQ(5, 1)) || \
    (defined(__clang__) && !CLANG_PREREQ(3, 9, 8020000))
typedef unsigned long long  __v2du __attribute__((__vector_size__(16)));
typedef unsigned int        __v4su __attribute__((__vector_size__(16)));
typedef unsigned short      __v8hu __attribute__((__vector_size__(16)));
typedef unsigned char      __v16qu __attribute__((__vector_size__(16)));
typedef unsigned long long  __v4du __attribute__((__vector_size__(32)));
typedef unsigned int        __v8su __attribute__((__vector_size__(32)));
typedef unsigned short     __v16hu __attribute__((__vector_size__(32)));
typedef unsigned char      __v32qu __attribute__((__vector_size__(32)));
#endif


#ifdef __BYTE_ORDER__
#  define CPU_IS_LITTLE_ENDIAN() (__BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__)
#endif

#if GCC_PREREQ(4, 8) || __has_builtin(__builtin_bswap16)
#  define bswap16	__builtin_bswap16
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap32)
#  define bswap32	__builtin_bswap32
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap64)
#  define bswap64	__builtin_bswap64
#endif

#if defined(__x86_64__) || defined(__i386__) || defined(__ARM_FEATURE_UNALIGNED) || defined(__powerpc64__)
#  define UNALIGNED_ACCESS_IS_FAST 1
#endif

#define bsr32(n)	(31 - __builtin_clz(n))
#define bsr64(n)	(63 - __builtin_clzll(n))
#define bsf32(n)	__builtin_ctz(n)
#define bsf64(n)	__builtin_ctzll(n)

#elif defined(_MSC_VER)
/* #  include "compiler_msc.h" */


#include <stdint.h>
#include <stdlib.h> 

#define LIBEXPORT	__declspec(dllexport)


typedef int bool;
#define true 1
#define false 0
#define __bool_true_false_are_defined 1


#ifdef _WIN64
typedef long long ssize_t;
#else
typedef int ssize_t;
#endif


#define CPU_IS_LITTLE_ENDIAN()		1
#define UNALIGNED_ACCESS_IS_FAST	1


#define restrict


#define inline		__inline
#define forceinline	__forceinline


#define bswap16	_byteswap_ushort
#define bswap32	_byteswap_ulong
#define bswap64	_byteswap_uint64



static forceinline unsigned
bsr32(uint32_t n)
{
	_BitScanReverse(&n, n);
	return n;
}
#define bsr32 bsr32

static forceinline unsigned
bsf32(uint32_t n)
{
	_BitScanForward(&n, n);
	return n;
}
#define bsf32 bsf32

#ifdef _M_X64 

static forceinline unsigned
bsr64(uint64_t n)
{
	_BitScanReverse64(&n, n);
	return n;
}
#define bsr64 bsr64

static forceinline unsigned
bsf64(uint64_t n)
{
	_BitScanForward64(&n, n);
	return n;
}
#define bsf64 bsf64

#endif 

#else
#  pragma message("Unrecognized compiler.  Please add a header file for your compiler.  Compilation will proceed, but performance may suffer!")
#endif





#include <stddef.h> 

#ifndef __bool_true_false_are_defined
#  include <stdbool.h> 
#endif


#include <stdint.h>
typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
typedef int8_t s8;
typedef int16_t s16;
typedef int32_t s32;
typedef int64_t s64;


typedef size_t machine_word_t;


#define WORDBYTES	((int)sizeof(machine_word_t))


#define WORDBITS	(8 * WORDBYTES)






#ifndef LIBEXPORT
#  define LIBEXPORT
#endif


#ifndef inline
#  define inline
#endif


#ifndef forceinline
#  define forceinline inline
#endif


#ifndef restrict
#  define restrict
#endif


#ifndef likely
#  define likely(expr)		(expr)
#endif


#ifndef unlikely
#  define unlikely(expr)	(expr)
#endif


#ifndef prefetchr
#  define prefetchr(addr)
#endif


#ifndef prefetchw
#  define prefetchw(addr)
#endif


#ifndef COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE
#  define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE 0
#endif


#ifndef COMPILER_SUPPORTS_BMI2_TARGET
#  define COMPILER_SUPPORTS_BMI2_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX_TARGET
#  define COMPILER_SUPPORTS_AVX_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET
#  define COMPILER_SUPPORTS_AVX512BW_TARGET 0
#endif


#ifndef COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 0
#endif


#ifndef _aligned_attribute
#endif





#define ARRAY_LEN(A)		(sizeof(A) / sizeof((A)[0]))
#define MIN(a, b)		((a) <= (b) ? (a) : (b))
#define MAX(a, b)		((a) >= (b) ? (a) : (b))
#define DIV_ROUND_UP(n, d)	(((n) + (d) - 1) / (d))
#define STATIC_ASSERT(expr)	((void)sizeof(char[1 - 2 * !(expr)]))
#define ALIGN(n, a)		(((n) + (a) - 1) & ~((a) - 1))






#ifndef CPU_IS_LITTLE_ENDIAN
static forceinline int CPU_IS_LITTLE_ENDIAN(void)
{
	union {
		unsigned int v;
		unsigned char b;
	} u;
	u.v = 1;
	return u.b;
}
#endif


#ifndef bswap16
static forceinline u16 bswap16(u16 n)
{
	return (n << 8) | (n >> 8);
}
#endif


#ifndef bswap32
static forceinline u32 bswap32(u32 n)
{
	return ((n & 0x000000FF) << 24) |
	       ((n & 0x0000FF00) << 8) |
	       ((n & 0x00FF0000) >> 8) |
	       ((n & 0xFF000000) >> 24);
}
#endif


#ifndef bswap64
static forceinline u64 bswap64(u64 n)
{
	return ((n & 0x00000000000000FF) << 56) |
	       ((n & 0x000000000000FF00) << 40) |
	       ((n & 0x0000000000FF0000) << 24) |
	       ((n & 0x00000000FF000000) << 8) |
	       ((n & 0x000000FF00000000) >> 8) |
	       ((n & 0x0000FF0000000000) >> 24) |
	       ((n & 0x00FF000000000000) >> 40) |
	       ((n & 0xFF00000000000000) >> 56);
}
#endif

#define le16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap16(n))
#define le32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap32(n))
#define le64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap64(n))
#define be16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap16(n) : (n))
#define be32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap32(n) : (n))
#define be64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap64(n) : (n))






#ifndef UNALIGNED_ACCESS_IS_FAST
#  define UNALIGNED_ACCESS_IS_FAST 0
#endif







#ifndef bsr32
static forceinline unsigned
bsr32(u32 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

#ifndef bsr64
static forceinline unsigned
bsr64(u64 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

static forceinline unsigned
bsrw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsr32(n);
	else
		return bsr64(n);
}



#ifndef bsf32
static forceinline unsigned
bsf32(u32 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

#ifndef bsf64
static forceinline unsigned
bsf64(u64 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

static forceinline unsigned
bsfw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsf32(n);
	else
		return bsf64(n);
}

#endif 



#define SYM_FIXUP(sym)			_libdeflate_##sym
#define deflate_get_compression_level	SYM_FIXUP(deflate_get_compression_level)
#define _cpu_features			SYM_FIXUP(_cpu_features)
#define setup_cpu_features		SYM_FIXUP(setup_cpu_features)

void *libdeflate_malloc(size_t size);
void libdeflate_free(void *ptr);

void *libdeflate_aligned_malloc(size_t alignment, size_t size);
void libdeflate_aligned_free(void *ptr);

#ifdef FREESTANDING

void *memset(void *s, int c, size_t n);
#define memset(s, c, n)		__builtin_memset((s), (c), (n))

void *memcpy(void *dest, const void *src, size_t n);
#define memcpy(dest, src, n)	__builtin_memcpy((dest), (src), (n))

void *memmove(void *dest, const void *src, size_t n);
#define memmove(dest, src, n)	__builtin_memmove((dest), (src), (n))

int memcmp(const void *s1, const void *s2, size_t n);
#define memcmp(s1, s2, n)	__builtin_memcmp((s1), (s2), (n))
#else
#include <string.h>
#endif

#endif 

/* #include "libdeflate.h" */


#ifndef LIBDEFLATE_H
#define LIBDEFLATE_H

#ifdef __cplusplus
extern "C" {
#endif

#define LIBDEFLATE_VERSION_MAJOR	1
#define LIBDEFLATE_VERSION_MINOR	7
#define LIBDEFLATE_VERSION_STRING	"1.7"

#include <stddef.h>
#include <stdint.h>


#ifdef LIBDEFLATE_DLL
#  ifdef BUILDING_LIBDEFLATE
#    define LIBDEFLATEEXPORT	LIBEXPORT
#  elif defined(_WIN32) || defined(__CYGWIN__)
#    define LIBDEFLATEEXPORT	__declspec(dllimport)
#  endif
#endif
#ifndef LIBDEFLATEEXPORT
#  define LIBDEFLATEEXPORT
#endif

#if defined(_WIN32) && !defined(_WIN64)
#  define LIBDEFLATEAPI_ABI	__stdcall
#else
#  define LIBDEFLATEAPI_ABI
#endif

#if defined(BUILDING_LIBDEFLATE) && defined(__GNUC__) && \
	defined(_WIN32) && !defined(_WIN64)
    
#  define LIBDEFLATEAPI_STACKALIGN	__attribute__((force_align_arg_pointer))
#else
#  define LIBDEFLATEAPI_STACKALIGN
#endif

#define LIBDEFLATEAPI	LIBDEFLATEAPI_ABI LIBDEFLATEAPI_STACKALIGN





struct libdeflate_compressor;


LIBDEFLATEEXPORT struct libdeflate_compressor * LIBDEFLATEAPI
libdeflate_alloc_compressor(int compression_level);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_deflate_compress(struct libdeflate_compressor *compressor,
			    const void *in, size_t in_nbytes,
			    void *out, size_t out_nbytes_avail);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_deflate_compress_bound(struct libdeflate_compressor *compressor,
				  size_t in_nbytes);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_zlib_compress(struct libdeflate_compressor *compressor,
			 const void *in, size_t in_nbytes,
			 void *out, size_t out_nbytes_avail);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_zlib_compress_bound(struct libdeflate_compressor *compressor,
			       size_t in_nbytes);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_gzip_compress(struct libdeflate_compressor *compressor,
			 const void *in, size_t in_nbytes,
			 void *out, size_t out_nbytes_avail);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_gzip_compress_bound(struct libdeflate_compressor *compressor,
			       size_t in_nbytes);


LIBDEFLATEEXPORT void LIBDEFLATEAPI
libdeflate_free_compressor(struct libdeflate_compressor *compressor);





struct libdeflate_decompressor;


LIBDEFLATEEXPORT struct libdeflate_decompressor * LIBDEFLATEAPI
libdeflate_alloc_decompressor(void);


enum libdeflate_result {
	
	LIBDEFLATE_SUCCESS = 0,

	
	LIBDEFLATE_BAD_DATA = 1,

	
	LIBDEFLATE_SHORT_OUTPUT = 2,

	
	LIBDEFLATE_INSUFFICIENT_SPACE = 3,
};


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_deflate_decompress(struct libdeflate_decompressor *decompressor,
			      const void *in, size_t in_nbytes,
			      void *out, size_t out_nbytes_avail,
			      size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_deflate_decompress_ex(struct libdeflate_decompressor *decompressor,
				 const void *in, size_t in_nbytes,
				 void *out, size_t out_nbytes_avail,
				 size_t *actual_in_nbytes_ret,
				 size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_zlib_decompress(struct libdeflate_decompressor *decompressor,
			   const void *in, size_t in_nbytes,
			   void *out, size_t out_nbytes_avail,
			   size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_zlib_decompress_ex(struct libdeflate_decompressor *decompressor,
			      const void *in, size_t in_nbytes,
			      void *out, size_t out_nbytes_avail,
			      size_t *actual_in_nbytes_ret,
			      size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_gzip_decompress(struct libdeflate_decompressor *decompressor,
			   const void *in, size_t in_nbytes,
			   void *out, size_t out_nbytes_avail,
			   size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_gzip_decompress_ex(struct libdeflate_decompressor *decompressor,
			      const void *in, size_t in_nbytes,
			      void *out, size_t out_nbytes_avail,
			      size_t *actual_in_nbytes_ret,
			      size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT void LIBDEFLATEAPI
libdeflate_free_decompressor(struct libdeflate_decompressor *decompressor);






LIBDEFLATEEXPORT uint32_t LIBDEFLATEAPI
libdeflate_adler32(uint32_t adler, const void *buffer, size_t len);



LIBDEFLATEEXPORT uint32_t LIBDEFLATEAPI
libdeflate_crc32(uint32_t crc, const void *buffer, size_t len);






LIBDEFLATEEXPORT void LIBDEFLATEAPI
libdeflate_set_memory_allocator(void *(*malloc_func)(size_t),
				void (*free_func)(void *));

#ifdef __cplusplus
}
#endif

#endif 



#define DIVISOR 65521


#define MAX_CHUNK_SIZE	5552

typedef u32 (*adler32_func_t)(u32, const u8 *, size_t);


#undef DEFAULT_IMPL
#undef DISPATCH
#if defined(__arm__) || defined(__aarch64__)
/* #  include "arm/adler32_impl.h" */


/* #include "arm-cpu_features.h" */


#ifndef LIB_ARM_CPU_FEATURES_H
#define LIB_ARM_CPU_FEATURES_H

/* #include "lib_common.h" */


#ifndef LIB_LIB_COMMON_H
#define LIB_LIB_COMMON_H

#ifdef LIBDEFLATE_H
#  error "lib_common.h must always be included before libdeflate.h"
   
#endif

#define BUILDING_LIBDEFLATE

/* #include "../common/common_defs.h" */


#ifndef COMMON_COMMON_DEFS_H
#define COMMON_COMMON_DEFS_H

#ifdef __GNUC__
/* #  include "compiler_gcc.h" */


#if !defined(__clang__) && !defined(__INTEL_COMPILER)
#  define GCC_PREREQ(major, minor)		\
	(__GNUC__ > (major) ||			\
	 (__GNUC__ == (major) && __GNUC_MINOR__ >= (minor)))
#else
#  define GCC_PREREQ(major, minor)	0
#endif


#ifdef __clang__
#  ifdef __apple_build_version__
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__apple_build_version__ >= (apple_version))
#  else
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__clang_major__ > (major) ||			\
	 (__clang_major__ == (major) && __clang_minor__ >= (minor)))
#  endif
#else
#  define CLANG_PREREQ(major, minor, apple_version)	0
#endif

#ifndef __has_attribute
#  define __has_attribute(attribute)	0
#endif
#ifndef __has_feature
#  define __has_feature(feature)	0
#endif
#ifndef __has_builtin
#  define __has_builtin(builtin)	0
#endif

#ifdef _WIN32
#  define LIBEXPORT __declspec(dllexport)
#else
#  define LIBEXPORT __attribute__((visibility("default")))
#endif

#define inline			inline
#define forceinline		inline __attribute__((always_inline))
#define restrict		__restrict__
#define likely(expr)		__builtin_expect(!!(expr), 1)
#define unlikely(expr)		__builtin_expect(!!(expr), 0)
#define prefetchr(addr)		__builtin_prefetch((addr), 0)
#define prefetchw(addr)		__builtin_prefetch((addr), 1)
#define _aligned_attribute(n)	__attribute__((aligned(n)))

#define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE	\
	(GCC_PREREQ(4, 4) || __has_attribute(target))

#if COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE

#  if defined(__i386__) || defined(__x86_64__)

#    define COMPILER_SUPPORTS_PCLMUL_TARGET	\
	(GCC_PREREQ(4, 4) || __has_builtin(__builtin_ia32_pclmulqdq128))

#    define COMPILER_SUPPORTS_AVX_TARGET	\
	(GCC_PREREQ(4, 6) || __has_builtin(__builtin_ia32_maxps256))

#    define COMPILER_SUPPORTS_BMI2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_pdep_di))

#    define COMPILER_SUPPORTS_AVX2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_psadbw256))

#    define COMPILER_SUPPORTS_AVX512BW_TARGET	\
	(GCC_PREREQ(5, 1) || __has_builtin(__builtin_ia32_psadbw512))

	
#    if GCC_PREREQ(4, 9) || CLANG_PREREQ(3, 8, 7030000)
#      define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS	1
#      define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_PCLMUL_TARGET
#      define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX2_TARGET
#      define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX512BW_TARGET
#    endif

#  elif defined(__arm__) || defined(__aarch64__)

    
#    if (GCC_PREREQ(6, 1) && defined(__ARM_FP)) || \
        (defined(__clang__) && defined(__ARM_NEON))
#      define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 1
       
#      if defined(__clang__) && defined(__arm__)
#        undef __ARM_FEATURE_CRYPTO
#      elif __has_builtin(__builtin_neon_vmull_p64) || !defined(__clang__)
#        define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 1
#      endif
#    endif

     
#    if GCC_PREREQ(10, 1) || \
        (GCC_PREREQ(9, 3) && !GCC_PREREQ(10, 0)) || \
        (GCC_PREREQ(8, 4) && !GCC_PREREQ(9, 0)) || \
        (defined(__clang__) && __has_builtin(__builtin_arm_crc32b))
#      define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 1
#    endif

#  endif 

#endif 


#if (GCC_PREREQ(4, 0) && !GCC_PREREQ(5, 1)) || \
    (defined(__clang__) && !CLANG_PREREQ(3, 9, 8020000))
typedef unsigned long long  __v2du __attribute__((__vector_size__(16)));
typedef unsigned int        __v4su __attribute__((__vector_size__(16)));
typedef unsigned short      __v8hu __attribute__((__vector_size__(16)));
typedef unsigned char      __v16qu __attribute__((__vector_size__(16)));
typedef unsigned long long  __v4du __attribute__((__vector_size__(32)));
typedef unsigned int        __v8su __attribute__((__vector_size__(32)));
typedef unsigned short     __v16hu __attribute__((__vector_size__(32)));
typedef unsigned char      __v32qu __attribute__((__vector_size__(32)));
#endif


#ifdef __BYTE_ORDER__
#  define CPU_IS_LITTLE_ENDIAN() (__BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__)
#endif

#if GCC_PREREQ(4, 8) || __has_builtin(__builtin_bswap16)
#  define bswap16	__builtin_bswap16
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap32)
#  define bswap32	__builtin_bswap32
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap64)
#  define bswap64	__builtin_bswap64
#endif

#if defined(__x86_64__) || defined(__i386__) || defined(__ARM_FEATURE_UNALIGNED) || defined(__powerpc64__)
#  define UNALIGNED_ACCESS_IS_FAST 1
#endif

#define bsr32(n)	(31 - __builtin_clz(n))
#define bsr64(n)	(63 - __builtin_clzll(n))
#define bsf32(n)	__builtin_ctz(n)
#define bsf64(n)	__builtin_ctzll(n)

#elif defined(_MSC_VER)
/* #  include "compiler_msc.h" */


#include <stdint.h>
#include <stdlib.h> 

#define LIBEXPORT	__declspec(dllexport)


typedef int bool;
#define true 1
#define false 0
#define __bool_true_false_are_defined 1


#ifdef _WIN64
typedef long long ssize_t;
#else
typedef int ssize_t;
#endif


#define CPU_IS_LITTLE_ENDIAN()		1
#define UNALIGNED_ACCESS_IS_FAST	1


#define restrict


#define inline		__inline
#define forceinline	__forceinline


#define bswap16	_byteswap_ushort
#define bswap32	_byteswap_ulong
#define bswap64	_byteswap_uint64



static forceinline unsigned
bsr32(uint32_t n)
{
	_BitScanReverse(&n, n);
	return n;
}
#define bsr32 bsr32

static forceinline unsigned
bsf32(uint32_t n)
{
	_BitScanForward(&n, n);
	return n;
}
#define bsf32 bsf32

#ifdef _M_X64 

static forceinline unsigned
bsr64(uint64_t n)
{
	_BitScanReverse64(&n, n);
	return n;
}
#define bsr64 bsr64

static forceinline unsigned
bsf64(uint64_t n)
{
	_BitScanForward64(&n, n);
	return n;
}
#define bsf64 bsf64

#endif 

#else
#  pragma message("Unrecognized compiler.  Please add a header file for your compiler.  Compilation will proceed, but performance may suffer!")
#endif





#include <stddef.h> 

#ifndef __bool_true_false_are_defined
#  include <stdbool.h> 
#endif


#include <stdint.h>
typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
typedef int8_t s8;
typedef int16_t s16;
typedef int32_t s32;
typedef int64_t s64;


typedef size_t machine_word_t;


#define WORDBYTES	((int)sizeof(machine_word_t))


#define WORDBITS	(8 * WORDBYTES)






#ifndef LIBEXPORT
#  define LIBEXPORT
#endif


#ifndef inline
#  define inline
#endif


#ifndef forceinline
#  define forceinline inline
#endif


#ifndef restrict
#  define restrict
#endif


#ifndef likely
#  define likely(expr)		(expr)
#endif


#ifndef unlikely
#  define unlikely(expr)	(expr)
#endif


#ifndef prefetchr
#  define prefetchr(addr)
#endif


#ifndef prefetchw
#  define prefetchw(addr)
#endif


#ifndef COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE
#  define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE 0
#endif


#ifndef COMPILER_SUPPORTS_BMI2_TARGET
#  define COMPILER_SUPPORTS_BMI2_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX_TARGET
#  define COMPILER_SUPPORTS_AVX_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET
#  define COMPILER_SUPPORTS_AVX512BW_TARGET 0
#endif


#ifndef COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 0
#endif


#ifndef _aligned_attribute
#endif





#define ARRAY_LEN(A)		(sizeof(A) / sizeof((A)[0]))
#define MIN(a, b)		((a) <= (b) ? (a) : (b))
#define MAX(a, b)		((a) >= (b) ? (a) : (b))
#define DIV_ROUND_UP(n, d)	(((n) + (d) - 1) / (d))
#define STATIC_ASSERT(expr)	((void)sizeof(char[1 - 2 * !(expr)]))
#define ALIGN(n, a)		(((n) + (a) - 1) & ~((a) - 1))






#ifndef CPU_IS_LITTLE_ENDIAN
static forceinline int CPU_IS_LITTLE_ENDIAN(void)
{
	union {
		unsigned int v;
		unsigned char b;
	} u;
	u.v = 1;
	return u.b;
}
#endif


#ifndef bswap16
static forceinline u16 bswap16(u16 n)
{
	return (n << 8) | (n >> 8);
}
#endif


#ifndef bswap32
static forceinline u32 bswap32(u32 n)
{
	return ((n & 0x000000FF) << 24) |
	       ((n & 0x0000FF00) << 8) |
	       ((n & 0x00FF0000) >> 8) |
	       ((n & 0xFF000000) >> 24);
}
#endif


#ifndef bswap64
static forceinline u64 bswap64(u64 n)
{
	return ((n & 0x00000000000000FF) << 56) |
	       ((n & 0x000000000000FF00) << 40) |
	       ((n & 0x0000000000FF0000) << 24) |
	       ((n & 0x00000000FF000000) << 8) |
	       ((n & 0x000000FF00000000) >> 8) |
	       ((n & 0x0000FF0000000000) >> 24) |
	       ((n & 0x00FF000000000000) >> 40) |
	       ((n & 0xFF00000000000000) >> 56);
}
#endif

#define le16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap16(n))
#define le32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap32(n))
#define le64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap64(n))
#define be16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap16(n) : (n))
#define be32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap32(n) : (n))
#define be64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap64(n) : (n))






#ifndef UNALIGNED_ACCESS_IS_FAST
#  define UNALIGNED_ACCESS_IS_FAST 0
#endif







#ifndef bsr32
static forceinline unsigned
bsr32(u32 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

#ifndef bsr64
static forceinline unsigned
bsr64(u64 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

static forceinline unsigned
bsrw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsr32(n);
	else
		return bsr64(n);
}



#ifndef bsf32
static forceinline unsigned
bsf32(u32 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

#ifndef bsf64
static forceinline unsigned
bsf64(u64 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

static forceinline unsigned
bsfw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsf32(n);
	else
		return bsf64(n);
}

#endif 



#define SYM_FIXUP(sym)			_libdeflate_##sym
#define deflate_get_compression_level	SYM_FIXUP(deflate_get_compression_level)
#define _cpu_features			SYM_FIXUP(_cpu_features)
#define setup_cpu_features		SYM_FIXUP(setup_cpu_features)

void *libdeflate_malloc(size_t size);
void libdeflate_free(void *ptr);

void *libdeflate_aligned_malloc(size_t alignment, size_t size);
void libdeflate_aligned_free(void *ptr);

#ifdef FREESTANDING

void *memset(void *s, int c, size_t n);
#define memset(s, c, n)		__builtin_memset((s), (c), (n))

void *memcpy(void *dest, const void *src, size_t n);
#define memcpy(dest, src, n)	__builtin_memcpy((dest), (src), (n))

void *memmove(void *dest, const void *src, size_t n);
#define memmove(dest, src, n)	__builtin_memmove((dest), (src), (n))

int memcmp(const void *s1, const void *s2, size_t n);
#define memcmp(s1, s2, n)	__builtin_memcmp((s1), (s2), (n))
#else
#include <string.h>
#endif

#endif 


#if (defined(__arm__) || defined(__aarch64__)) && \
	defined(__linux__) && \
	COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE && \
	!defined(FREESTANDING)
#  define ARM_CPU_FEATURES_ENABLED 1
#else
#  define ARM_CPU_FEATURES_ENABLED 0
#endif

#if ARM_CPU_FEATURES_ENABLED

#define ARM_CPU_FEATURE_NEON		0x00000001
#define ARM_CPU_FEATURE_PMULL		0x00000002
#define ARM_CPU_FEATURE_CRC32		0x00000004

#define ARM_CPU_FEATURES_KNOWN		0x80000000

extern volatile u32 _cpu_features;

void setup_cpu_features(void);

static inline u32 get_cpu_features(void)
{
	if (_cpu_features == 0)
		setup_cpu_features();
	return _cpu_features;
}

#endif 

#endif 



#undef DISPATCH_NEON
#if !defined(DEFAULT_IMPL) &&	\
	(defined(__ARM_NEON) || (ARM_CPU_FEATURES_ENABLED &&	\
				 COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS))
#  define FUNCNAME		adler32_neon
#  define FUNCNAME_CHUNK	adler32_neon_chunk
#  define IMPL_ALIGNMENT	16
#  define IMPL_SEGMENT_SIZE	32

#  define IMPL_MAX_CHUNK_SIZE	(32 * (0xFFFF / 0xFF))
#  ifdef __ARM_NEON
#    define ATTRIBUTES
#    define DEFAULT_IMPL	adler32_neon
#  else
#    ifdef __arm__
#      define ATTRIBUTES	__attribute__((target("fpu=neon")))
#    else
#      define ATTRIBUTES	__attribute__((target("+simd")))
#    endif
#    define DISPATCH		1
#    define DISPATCH_NEON	1
#  endif
#  include <arm_neon.h>
static forceinline ATTRIBUTES void
adler32_neon_chunk(const uint8x16_t *p, const uint8x16_t * const end,
		   u32 *s1, u32 *s2)
{
	uint32x4_t v_s1 = (uint32x4_t) { 0, 0, 0, 0 };
	uint32x4_t v_s2 = (uint32x4_t) { 0, 0, 0, 0 };
	uint16x8_t v_byte_sums_a = (uint16x8_t) { 0, 0, 0, 0, 0, 0, 0, 0 };
	uint16x8_t v_byte_sums_b = (uint16x8_t) { 0, 0, 0, 0, 0, 0, 0, 0 };
	uint16x8_t v_byte_sums_c = (uint16x8_t) { 0, 0, 0, 0, 0, 0, 0, 0 };
	uint16x8_t v_byte_sums_d = (uint16x8_t) { 0, 0, 0, 0, 0, 0, 0, 0 };

	do {
		const uint8x16_t bytes1 = *p++;
		const uint8x16_t bytes2 = *p++;
		uint16x8_t tmp;

		v_s2 += v_s1;

		
		tmp = vpaddlq_u8(bytes1);

		
		tmp = vpadalq_u8(tmp, bytes2);

		
		v_s1 = vpadalq_u16(v_s1, tmp);

		
		v_byte_sums_a = vaddw_u8(v_byte_sums_a, vget_low_u8(bytes1));
		v_byte_sums_b = vaddw_u8(v_byte_sums_b, vget_high_u8(bytes1));
		v_byte_sums_c = vaddw_u8(v_byte_sums_c, vget_low_u8(bytes2));
		v_byte_sums_d = vaddw_u8(v_byte_sums_d, vget_high_u8(bytes2));

	} while (p != end);

	
	v_s2 = vqshlq_n_u32(v_s2, 5);

	
	v_s2 = vmlal_u16(v_s2, vget_low_u16(v_byte_sums_a),  (uint16x4_t) { 32, 31, 30, 29 });
	v_s2 = vmlal_u16(v_s2, vget_high_u16(v_byte_sums_a), (uint16x4_t) { 28, 27, 26, 25 });
	v_s2 = vmlal_u16(v_s2, vget_low_u16(v_byte_sums_b),  (uint16x4_t) { 24, 23, 22, 21 });
	v_s2 = vmlal_u16(v_s2, vget_high_u16(v_byte_sums_b), (uint16x4_t) { 20, 19, 18, 17 });
	v_s2 = vmlal_u16(v_s2, vget_low_u16(v_byte_sums_c),  (uint16x4_t) { 16, 15, 14, 13 });
	v_s2 = vmlal_u16(v_s2, vget_high_u16(v_byte_sums_c), (uint16x4_t) { 12, 11, 10,  9 });
	v_s2 = vmlal_u16(v_s2, vget_low_u16 (v_byte_sums_d), (uint16x4_t) {  8,  7,  6,  5 });
	v_s2 = vmlal_u16(v_s2, vget_high_u16(v_byte_sums_d), (uint16x4_t) {  4,  3,  2,  1 });

	*s1 += v_s1[0] + v_s1[1] + v_s1[2] + v_s1[3];
	*s2 += v_s2[0] + v_s2[1] + v_s2[2] + v_s2[3];
}
/* #include "adler32_vec_template.h" */




static u32 ATTRIBUTES
FUNCNAME(u32 adler, const u8 *p, size_t size)
{
	u32 s1 = adler & 0xFFFF;
	u32 s2 = adler >> 16;
	const u8 * const end = p + size;
	const u8 *vend;
	const size_t max_chunk_size =
		MIN(MAX_CHUNK_SIZE, IMPL_MAX_CHUNK_SIZE) -
		(MIN(MAX_CHUNK_SIZE, IMPL_MAX_CHUNK_SIZE) %
		 IMPL_SEGMENT_SIZE);

	
	if (p != end && (uintptr_t)p % IMPL_ALIGNMENT) {
		do {
			s1 += *p++;
			s2 += s1;
		} while (p != end && (uintptr_t)p % IMPL_ALIGNMENT);
		s1 %= DIVISOR;
		s2 %= DIVISOR;
	}

	
	STATIC_ASSERT(IMPL_SEGMENT_SIZE % IMPL_ALIGNMENT == 0);
	vend = end - ((size_t)(end - p) % IMPL_SEGMENT_SIZE);
	while (p != vend) {
		size_t chunk_size = MIN((size_t)(vend - p), max_chunk_size);

		s2 += s1 * chunk_size;

		FUNCNAME_CHUNK((const void *)p, (const void *)(p + chunk_size),
			       &s1, &s2);

		p += chunk_size;
		s1 %= DIVISOR;
		s2 %= DIVISOR;
	}

	
	if (p != end) {
		do {
			s1 += *p++;
			s2 += s1;
		} while (p != end);
		s1 %= DIVISOR;
		s2 %= DIVISOR;
	}

	return (s2 << 16) | s1;
}

#undef FUNCNAME
#undef FUNCNAME_CHUNK
#undef ATTRIBUTES
#undef IMPL_ALIGNMENT
#undef IMPL_SEGMENT_SIZE
#undef IMPL_MAX_CHUNK_SIZE

#endif 

#ifdef DISPATCH
static inline adler32_func_t
arch_select_adler32_func(void)
{
	u32 features = get_cpu_features();

#ifdef DISPATCH_NEON
	if (features & ARM_CPU_FEATURE_NEON)
		return adler32_neon;
#endif
	return NULL;
}
#endif 

#elif defined(__i386__) || defined(__x86_64__)
/* #  include "x86/adler32_impl.h" */


/* #include "x86-cpu_features.h" */


#ifndef LIB_X86_CPU_FEATURES_H
#define LIB_X86_CPU_FEATURES_H

/* #include "lib_common.h" */


#ifndef LIB_LIB_COMMON_H
#define LIB_LIB_COMMON_H

#ifdef LIBDEFLATE_H
#  error "lib_common.h must always be included before libdeflate.h"
   
#endif

#define BUILDING_LIBDEFLATE

/* #include "../common/common_defs.h" */


#ifndef COMMON_COMMON_DEFS_H
#define COMMON_COMMON_DEFS_H

#ifdef __GNUC__
/* #  include "compiler_gcc.h" */


#if !defined(__clang__) && !defined(__INTEL_COMPILER)
#  define GCC_PREREQ(major, minor)		\
	(__GNUC__ > (major) ||			\
	 (__GNUC__ == (major) && __GNUC_MINOR__ >= (minor)))
#else
#  define GCC_PREREQ(major, minor)	0
#endif


#ifdef __clang__
#  ifdef __apple_build_version__
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__apple_build_version__ >= (apple_version))
#  else
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__clang_major__ > (major) ||			\
	 (__clang_major__ == (major) && __clang_minor__ >= (minor)))
#  endif
#else
#  define CLANG_PREREQ(major, minor, apple_version)	0
#endif

#ifndef __has_attribute
#  define __has_attribute(attribute)	0
#endif
#ifndef __has_feature
#  define __has_feature(feature)	0
#endif
#ifndef __has_builtin
#  define __has_builtin(builtin)	0
#endif

#ifdef _WIN32
#  define LIBEXPORT __declspec(dllexport)
#else
#  define LIBEXPORT __attribute__((visibility("default")))
#endif

#define inline			inline
#define forceinline		inline __attribute__((always_inline))
#define restrict		__restrict__
#define likely(expr)		__builtin_expect(!!(expr), 1)
#define unlikely(expr)		__builtin_expect(!!(expr), 0)
#define prefetchr(addr)		__builtin_prefetch((addr), 0)
#define prefetchw(addr)		__builtin_prefetch((addr), 1)
#define _aligned_attribute(n)	__attribute__((aligned(n)))

#define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE	\
	(GCC_PREREQ(4, 4) || __has_attribute(target))

#if COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE

#  if defined(__i386__) || defined(__x86_64__)

#    define COMPILER_SUPPORTS_PCLMUL_TARGET	\
	(GCC_PREREQ(4, 4) || __has_builtin(__builtin_ia32_pclmulqdq128))

#    define COMPILER_SUPPORTS_AVX_TARGET	\
	(GCC_PREREQ(4, 6) || __has_builtin(__builtin_ia32_maxps256))

#    define COMPILER_SUPPORTS_BMI2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_pdep_di))

#    define COMPILER_SUPPORTS_AVX2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_psadbw256))

#    define COMPILER_SUPPORTS_AVX512BW_TARGET	\
	(GCC_PREREQ(5, 1) || __has_builtin(__builtin_ia32_psadbw512))

	
#    if GCC_PREREQ(4, 9) || CLANG_PREREQ(3, 8, 7030000)
#      define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS	1
#      define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_PCLMUL_TARGET
#      define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX2_TARGET
#      define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX512BW_TARGET
#    endif

#  elif defined(__arm__) || defined(__aarch64__)

    
#    if (GCC_PREREQ(6, 1) && defined(__ARM_FP)) || \
        (defined(__clang__) && defined(__ARM_NEON))
#      define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 1
       
#      if defined(__clang__) && defined(__arm__)
#        undef __ARM_FEATURE_CRYPTO
#      elif __has_builtin(__builtin_neon_vmull_p64) || !defined(__clang__)
#        define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 1
#      endif
#    endif

     
#    if GCC_PREREQ(10, 1) || \
        (GCC_PREREQ(9, 3) && !GCC_PREREQ(10, 0)) || \
        (GCC_PREREQ(8, 4) && !GCC_PREREQ(9, 0)) || \
        (defined(__clang__) && __has_builtin(__builtin_arm_crc32b))
#      define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 1
#    endif

#  endif 

#endif 


#if (GCC_PREREQ(4, 0) && !GCC_PREREQ(5, 1)) || \
    (defined(__clang__) && !CLANG_PREREQ(3, 9, 8020000))
typedef unsigned long long  __v2du __attribute__((__vector_size__(16)));
typedef unsigned int        __v4su __attribute__((__vector_size__(16)));
typedef unsigned short      __v8hu __attribute__((__vector_size__(16)));
typedef unsigned char      __v16qu __attribute__((__vector_size__(16)));
typedef unsigned long long  __v4du __attribute__((__vector_size__(32)));
typedef unsigned int        __v8su __attribute__((__vector_size__(32)));
typedef unsigned short     __v16hu __attribute__((__vector_size__(32)));
typedef unsigned char      __v32qu __attribute__((__vector_size__(32)));
#endif


#ifdef __BYTE_ORDER__
#  define CPU_IS_LITTLE_ENDIAN() (__BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__)
#endif

#if GCC_PREREQ(4, 8) || __has_builtin(__builtin_bswap16)
#  define bswap16	__builtin_bswap16
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap32)
#  define bswap32	__builtin_bswap32
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap64)
#  define bswap64	__builtin_bswap64
#endif

#if defined(__x86_64__) || defined(__i386__) || defined(__ARM_FEATURE_UNALIGNED) || defined(__powerpc64__)
#  define UNALIGNED_ACCESS_IS_FAST 1
#endif

#define bsr32(n)	(31 - __builtin_clz(n))
#define bsr64(n)	(63 - __builtin_clzll(n))
#define bsf32(n)	__builtin_ctz(n)
#define bsf64(n)	__builtin_ctzll(n)

#elif defined(_MSC_VER)
/* #  include "compiler_msc.h" */


#include <stdint.h>
#include <stdlib.h> 

#define LIBEXPORT	__declspec(dllexport)


typedef int bool;
#define true 1
#define false 0
#define __bool_true_false_are_defined 1


#ifdef _WIN64
typedef long long ssize_t;
#else
typedef int ssize_t;
#endif


#define CPU_IS_LITTLE_ENDIAN()		1
#define UNALIGNED_ACCESS_IS_FAST	1


#define restrict


#define inline		__inline
#define forceinline	__forceinline


#define bswap16	_byteswap_ushort
#define bswap32	_byteswap_ulong
#define bswap64	_byteswap_uint64



static forceinline unsigned
bsr32(uint32_t n)
{
	_BitScanReverse(&n, n);
	return n;
}
#define bsr32 bsr32

static forceinline unsigned
bsf32(uint32_t n)
{
	_BitScanForward(&n, n);
	return n;
}
#define bsf32 bsf32

#ifdef _M_X64 

static forceinline unsigned
bsr64(uint64_t n)
{
	_BitScanReverse64(&n, n);
	return n;
}
#define bsr64 bsr64

static forceinline unsigned
bsf64(uint64_t n)
{
	_BitScanForward64(&n, n);
	return n;
}
#define bsf64 bsf64

#endif 

#else
#  pragma message("Unrecognized compiler.  Please add a header file for your compiler.  Compilation will proceed, but performance may suffer!")
#endif





#include <stddef.h> 

#ifndef __bool_true_false_are_defined
#  include <stdbool.h> 
#endif


#include <stdint.h>
typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
typedef int8_t s8;
typedef int16_t s16;
typedef int32_t s32;
typedef int64_t s64;


typedef size_t machine_word_t;


#define WORDBYTES	((int)sizeof(machine_word_t))


#define WORDBITS	(8 * WORDBYTES)






#ifndef LIBEXPORT
#  define LIBEXPORT
#endif


#ifndef inline
#  define inline
#endif


#ifndef forceinline
#  define forceinline inline
#endif


#ifndef restrict
#  define restrict
#endif


#ifndef likely
#  define likely(expr)		(expr)
#endif


#ifndef unlikely
#  define unlikely(expr)	(expr)
#endif


#ifndef prefetchr
#  define prefetchr(addr)
#endif


#ifndef prefetchw
#  define prefetchw(addr)
#endif


#ifndef COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE
#  define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE 0
#endif


#ifndef COMPILER_SUPPORTS_BMI2_TARGET
#  define COMPILER_SUPPORTS_BMI2_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX_TARGET
#  define COMPILER_SUPPORTS_AVX_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET
#  define COMPILER_SUPPORTS_AVX512BW_TARGET 0
#endif


#ifndef COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 0
#endif


#ifndef _aligned_attribute
#endif





#define ARRAY_LEN(A)		(sizeof(A) / sizeof((A)[0]))
#define MIN(a, b)		((a) <= (b) ? (a) : (b))
#define MAX(a, b)		((a) >= (b) ? (a) : (b))
#define DIV_ROUND_UP(n, d)	(((n) + (d) - 1) / (d))
#define STATIC_ASSERT(expr)	((void)sizeof(char[1 - 2 * !(expr)]))
#define ALIGN(n, a)		(((n) + (a) - 1) & ~((a) - 1))






#ifndef CPU_IS_LITTLE_ENDIAN
static forceinline int CPU_IS_LITTLE_ENDIAN(void)
{
	union {
		unsigned int v;
		unsigned char b;
	} u;
	u.v = 1;
	return u.b;
}
#endif


#ifndef bswap16
static forceinline u16 bswap16(u16 n)
{
	return (n << 8) | (n >> 8);
}
#endif


#ifndef bswap32
static forceinline u32 bswap32(u32 n)
{
	return ((n & 0x000000FF) << 24) |
	       ((n & 0x0000FF00) << 8) |
	       ((n & 0x00FF0000) >> 8) |
	       ((n & 0xFF000000) >> 24);
}
#endif


#ifndef bswap64
static forceinline u64 bswap64(u64 n)
{
	return ((n & 0x00000000000000FF) << 56) |
	       ((n & 0x000000000000FF00) << 40) |
	       ((n & 0x0000000000FF0000) << 24) |
	       ((n & 0x00000000FF000000) << 8) |
	       ((n & 0x000000FF00000000) >> 8) |
	       ((n & 0x0000FF0000000000) >> 24) |
	       ((n & 0x00FF000000000000) >> 40) |
	       ((n & 0xFF00000000000000) >> 56);
}
#endif

#define le16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap16(n))
#define le32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap32(n))
#define le64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap64(n))
#define be16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap16(n) : (n))
#define be32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap32(n) : (n))
#define be64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap64(n) : (n))






#ifndef UNALIGNED_ACCESS_IS_FAST
#  define UNALIGNED_ACCESS_IS_FAST 0
#endif







#ifndef bsr32
static forceinline unsigned
bsr32(u32 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

#ifndef bsr64
static forceinline unsigned
bsr64(u64 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

static forceinline unsigned
bsrw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsr32(n);
	else
		return bsr64(n);
}



#ifndef bsf32
static forceinline unsigned
bsf32(u32 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

#ifndef bsf64
static forceinline unsigned
bsf64(u64 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

static forceinline unsigned
bsfw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsf32(n);
	else
		return bsf64(n);
}

#endif 



#define SYM_FIXUP(sym)			_libdeflate_##sym
#define deflate_get_compression_level	SYM_FIXUP(deflate_get_compression_level)
#define _cpu_features			SYM_FIXUP(_cpu_features)
#define setup_cpu_features		SYM_FIXUP(setup_cpu_features)

void *libdeflate_malloc(size_t size);
void libdeflate_free(void *ptr);

void *libdeflate_aligned_malloc(size_t alignment, size_t size);
void libdeflate_aligned_free(void *ptr);

#ifdef FREESTANDING

void *memset(void *s, int c, size_t n);
#define memset(s, c, n)		__builtin_memset((s), (c), (n))

void *memcpy(void *dest, const void *src, size_t n);
#define memcpy(dest, src, n)	__builtin_memcpy((dest), (src), (n))

void *memmove(void *dest, const void *src, size_t n);
#define memmove(dest, src, n)	__builtin_memmove((dest), (src), (n))

int memcmp(const void *s1, const void *s2, size_t n);
#define memcmp(s1, s2, n)	__builtin_memcmp((s1), (s2), (n))
#else
#include <string.h>
#endif

#endif 


#if (defined(__i386__) || defined(__x86_64__)) && \
	COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE
#  define X86_CPU_FEATURES_ENABLED 1
#else
#  define X86_CPU_FEATURES_ENABLED 0
#endif

#if X86_CPU_FEATURES_ENABLED

#define X86_CPU_FEATURE_SSE2		0x00000001
#define X86_CPU_FEATURE_PCLMUL		0x00000002
#define X86_CPU_FEATURE_AVX		0x00000004
#define X86_CPU_FEATURE_AVX2		0x00000008
#define X86_CPU_FEATURE_BMI2		0x00000010
#define X86_CPU_FEATURE_AVX512BW	0x00000020

#define X86_CPU_FEATURES_KNOWN		0x80000000

extern volatile u32 _cpu_features;

void setup_cpu_features(void);

static inline u32 get_cpu_features(void)
{
	if (_cpu_features == 0)
		setup_cpu_features();
	return _cpu_features;
}

#endif 

#endif 




#define ADLER32_FINISH_VEC_CHUNK_128(s1, s2, v_s1, v_s2)		    \
{									    \
	__v4su s1_last = (v_s1), s2_last = (v_s2);			    \
									    \
							    \
	s2_last += (__v4su)_mm_shuffle_epi32((__m128i)s2_last, 0x31);	    \
	s1_last += (__v4su)_mm_shuffle_epi32((__m128i)s1_last, 0x02);	    \
	s2_last += (__v4su)_mm_shuffle_epi32((__m128i)s2_last, 0x02);	    \
									    \
	*(s1) += (u32)_mm_cvtsi128_si32((__m128i)s1_last);		    \
	*(s2) += (u32)_mm_cvtsi128_si32((__m128i)s2_last);		    \
}

#define ADLER32_FINISH_VEC_CHUNK_256(s1, s2, v_s1, v_s2)		    \
{									    \
	__v4su s1_128bit, s2_128bit;					    \
									    \
							    \
	s1_128bit = (__v4su)_mm256_extracti128_si256((__m256i)(v_s1), 0) +  \
		    (__v4su)_mm256_extracti128_si256((__m256i)(v_s1), 1);   \
	s2_128bit = (__v4su)_mm256_extracti128_si256((__m256i)(v_s2), 0) +  \
		    (__v4su)_mm256_extracti128_si256((__m256i)(v_s2), 1);   \
									    \
	ADLER32_FINISH_VEC_CHUNK_128((s1), (s2), s1_128bit, s2_128bit);	    \
}

#define ADLER32_FINISH_VEC_CHUNK_512(s1, s2, v_s1, v_s2)		    \
{									    \
	__v8su s1_256bit, s2_256bit;					    \
									    \
							    \
	s1_256bit = (__v8su)_mm512_extracti64x4_epi64((__m512i)(v_s1), 0) + \
		    (__v8su)_mm512_extracti64x4_epi64((__m512i)(v_s1), 1);  \
	s2_256bit = (__v8su)_mm512_extracti64x4_epi64((__m512i)(v_s2), 0) + \
		    (__v8su)_mm512_extracti64x4_epi64((__m512i)(v_s2), 1);  \
									    \
	ADLER32_FINISH_VEC_CHUNK_256((s1), (s2), s1_256bit, s2_256bit);	    \
}


#undef DISPATCH_AVX512BW
#if !defined(DEFAULT_IMPL) &&						\
    									\
    COMPILER_SUPPORTS_AVX512BW_TARGET &&				\
    (defined(__AVX512BW__) || (X86_CPU_FEATURES_ENABLED &&		\
			       COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS))
#  define FUNCNAME		adler32_avx512bw
#  define FUNCNAME_CHUNK	adler32_avx512bw_chunk
#  define IMPL_ALIGNMENT	64
#  define IMPL_SEGMENT_SIZE	64
#  define IMPL_MAX_CHUNK_SIZE	MAX_CHUNK_SIZE
#  ifdef __AVX512BW__
#    define ATTRIBUTES
#    define DEFAULT_IMPL	adler32_avx512bw
#  else
#    define ATTRIBUTES		__attribute__((target("avx512bw")))
#    define DISPATCH		1
#    define DISPATCH_AVX512BW	1
#  endif
#  include <immintrin.h>
static forceinline ATTRIBUTES void
adler32_avx512bw_chunk(const __m512i *p, const __m512i *const end,
		       u32 *s1, u32 *s2)
{
	const __m512i zeroes = _mm512_setzero_si512();
	const __v64qi multipliers = (__v64qi){
		64, 63, 62, 61, 60, 59, 58, 57, 56, 55, 54, 53, 52, 51, 50, 49,
		48, 47, 46, 45, 44, 43, 42, 41, 40, 39, 38, 37, 36, 35, 34, 33,
		32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17,
		16, 15, 14, 13, 12, 11, 10,  9,  8,  7,  6,  5,  4,  3,  2,  1,
	};
	const __v32hi ones = (__v32hi)_mm512_set1_epi16(1);
	__v16si v_s1 = (__v16si)zeroes;
	__v16si v_s1_sums = (__v16si)zeroes;
	__v16si v_s2 = (__v16si)zeroes;

	do {
		
		__m512i bytes = *p++;

		
		__v32hi sums = (__v32hi)_mm512_maddubs_epi16(
						bytes, (__m512i)multipliers);

		
		v_s1_sums += v_s1;

		
		v_s1 += (__v16si)_mm512_sad_epu8(bytes, zeroes);

		
		v_s2 += (__v16si)_mm512_madd_epi16((__m512i)sums,
						   (__m512i)ones);
	} while (p != end);

	
	v_s2 += (__v16si)_mm512_slli_epi32((__m512i)v_s1_sums, 6);

	
	ADLER32_FINISH_VEC_CHUNK_512(s1, s2, v_s1, v_s2);
}
/* #include "adler32_vec_template.h" */




static u32 ATTRIBUTES
FUNCNAME(u32 adler, const u8 *p, size_t size)
{
	u32 s1 = adler & 0xFFFF;
	u32 s2 = adler >> 16;
	const u8 * const end = p + size;
	const u8 *vend;
	const size_t max_chunk_size =
		MIN(MAX_CHUNK_SIZE, IMPL_MAX_CHUNK_SIZE) -
		(MIN(MAX_CHUNK_SIZE, IMPL_MAX_CHUNK_SIZE) %
		 IMPL_SEGMENT_SIZE);

	
	if (p != end && (uintptr_t)p % IMPL_ALIGNMENT) {
		do {
			s1 += *p++;
			s2 += s1;
		} while (p != end && (uintptr_t)p % IMPL_ALIGNMENT);
		s1 %= DIVISOR;
		s2 %= DIVISOR;
	}

	
	STATIC_ASSERT(IMPL_SEGMENT_SIZE % IMPL_ALIGNMENT == 0);
	vend = end - ((size_t)(end - p) % IMPL_SEGMENT_SIZE);
	while (p != vend) {
		size_t chunk_size = MIN((size_t)(vend - p), max_chunk_size);

		s2 += s1 * chunk_size;

		FUNCNAME_CHUNK((const void *)p, (const void *)(p + chunk_size),
			       &s1, &s2);

		p += chunk_size;
		s1 %= DIVISOR;
		s2 %= DIVISOR;
	}

	
	if (p != end) {
		do {
			s1 += *p++;
			s2 += s1;
		} while (p != end);
		s1 %= DIVISOR;
		s2 %= DIVISOR;
	}

	return (s2 << 16) | s1;
}

#undef FUNCNAME
#undef FUNCNAME_CHUNK
#undef ATTRIBUTES
#undef IMPL_ALIGNMENT
#undef IMPL_SEGMENT_SIZE
#undef IMPL_MAX_CHUNK_SIZE

#endif 


#undef DISPATCH_AVX2
#if !defined(DEFAULT_IMPL) &&	\
	(defined(__AVX2__) || (X86_CPU_FEATURES_ENABLED &&	\
			       COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS))
#  define FUNCNAME		adler32_avx2
#  define FUNCNAME_CHUNK	adler32_avx2_chunk
#  define IMPL_ALIGNMENT	32
#  define IMPL_SEGMENT_SIZE	32
#  define IMPL_MAX_CHUNK_SIZE	MAX_CHUNK_SIZE
#  ifdef __AVX2__
#    define ATTRIBUTES
#    define DEFAULT_IMPL	adler32_avx2
#  else
#    define ATTRIBUTES		__attribute__((target("avx2")))
#    define DISPATCH		1
#    define DISPATCH_AVX2	1
#  endif
#  include <immintrin.h>
static forceinline ATTRIBUTES void
adler32_avx2_chunk(const __m256i *p, const __m256i *const end, u32 *s1, u32 *s2)
{
	const __m256i zeroes = _mm256_setzero_si256();
	const __v32qu multipliers = (__v32qu){
		32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17,
		16, 15, 14, 13, 12, 11, 10,  9,  8,  7,  6,  5,  4,  3,  2,  1,
	};
	const __v16hu ones = (__v16hu)_mm256_set1_epi16(1);
	__v8su v_s1 = (__v8su)zeroes;
	__v8su v_s1_sums = (__v8su)zeroes;
	__v8su v_s2 = (__v8su)zeroes;

	do {
		
		__m256i bytes = *p++;

		
		__v16hu sums = (__v16hu)_mm256_maddubs_epi16(
						bytes, (__m256i)multipliers);

		
		v_s1_sums += v_s1;

		
		v_s1 += (__v8su)_mm256_sad_epu8(bytes, zeroes);

		
		v_s2 += (__v8su)_mm256_madd_epi16((__m256i)sums, (__m256i)ones);
	} while (p != end);

	
	v_s2 += (__v8su)_mm256_slli_epi32((__m256i)v_s1_sums, 5);

	
	ADLER32_FINISH_VEC_CHUNK_256(s1, s2, v_s1, v_s2);
}
/* #include "x86-../adler32_vec_template.h" */




static u32 ATTRIBUTES
FUNCNAME(u32 adler, const u8 *p, size_t size)
{
	u32 s1 = adler & 0xFFFF;
	u32 s2 = adler >> 16;
	const u8 * const end = p + size;
	const u8 *vend;
	const size_t max_chunk_size =
		MIN(MAX_CHUNK_SIZE, IMPL_MAX_CHUNK_SIZE) -
		(MIN(MAX_CHUNK_SIZE, IMPL_MAX_CHUNK_SIZE) %
		 IMPL_SEGMENT_SIZE);

	
	if (p != end && (uintptr_t)p % IMPL_ALIGNMENT) {
		do {
			s1 += *p++;
			s2 += s1;
		} while (p != end && (uintptr_t)p % IMPL_ALIGNMENT);
		s1 %= DIVISOR;
		s2 %= DIVISOR;
	}

	
	STATIC_ASSERT(IMPL_SEGMENT_SIZE % IMPL_ALIGNMENT == 0);
	vend = end - ((size_t)(end - p) % IMPL_SEGMENT_SIZE);
	while (p != vend) {
		size_t chunk_size = MIN((size_t)(vend - p), max_chunk_size);

		s2 += s1 * chunk_size;

		FUNCNAME_CHUNK((const void *)p, (const void *)(p + chunk_size),
			       &s1, &s2);

		p += chunk_size;
		s1 %= DIVISOR;
		s2 %= DIVISOR;
	}

	
	if (p != end) {
		do {
			s1 += *p++;
			s2 += s1;
		} while (p != end);
		s1 %= DIVISOR;
		s2 %= DIVISOR;
	}

	return (s2 << 16) | s1;
}

#undef FUNCNAME
#undef FUNCNAME_CHUNK
#undef ATTRIBUTES
#undef IMPL_ALIGNMENT
#undef IMPL_SEGMENT_SIZE
#undef IMPL_MAX_CHUNK_SIZE

#endif 


#undef DISPATCH_SSE2
#if !defined(DEFAULT_IMPL) &&	\
	(defined(__SSE2__) || (X86_CPU_FEATURES_ENABLED &&	\
			       COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS))
#  define FUNCNAME		adler32_sse2
#  define FUNCNAME_CHUNK	adler32_sse2_chunk
#  define IMPL_ALIGNMENT	16
#  define IMPL_SEGMENT_SIZE	32

#  define IMPL_MAX_CHUNK_SIZE	(32 * (0x7FFF / 0xFF))
#  ifdef __SSE2__
#    define ATTRIBUTES
#    define DEFAULT_IMPL	adler32_sse2
#  else
#    define ATTRIBUTES		__attribute__((target("sse2")))
#    define DISPATCH		1
#    define DISPATCH_SSE2	1
#  endif
#  include <emmintrin.h>
static forceinline ATTRIBUTES void
adler32_sse2_chunk(const __m128i *p, const __m128i *const end, u32 *s1, u32 *s2)
{
	const __m128i zeroes = _mm_setzero_si128();

	
	__v4su v_s1 = (__v4su)zeroes;

	
	__v4su v_s2 = (__v4su)zeroes;

	
	__v8hu v_byte_sums_a = (__v8hu)zeroes;
	__v8hu v_byte_sums_b = (__v8hu)zeroes;
	__v8hu v_byte_sums_c = (__v8hu)zeroes;
	__v8hu v_byte_sums_d = (__v8hu)zeroes;

	do {
		
		const __m128i bytes1 = *p++;
		const __m128i bytes2 = *p++;

		
		v_s2 += v_s1;

		
		v_s1 += (__v4su)_mm_sad_epu8(bytes1, zeroes);
		v_s1 += (__v4su)_mm_sad_epu8(bytes2, zeroes);

		
		v_byte_sums_a += (__v8hu)_mm_unpacklo_epi8(bytes1, zeroes);
		v_byte_sums_b += (__v8hu)_mm_unpackhi_epi8(bytes1, zeroes);
		v_byte_sums_c += (__v8hu)_mm_unpacklo_epi8(bytes2, zeroes);
		v_byte_sums_d += (__v8hu)_mm_unpackhi_epi8(bytes2, zeroes);

	} while (p != end);

	
	v_s2 = (__v4su)_mm_slli_epi32((__m128i)v_s2, 5);
	v_s2 += (__v4su)_mm_madd_epi16((__m128i)v_byte_sums_a,
				       (__m128i)(__v8hu){ 32, 31, 30, 29, 28, 27, 26, 25 });
	v_s2 += (__v4su)_mm_madd_epi16((__m128i)v_byte_sums_b,
				       (__m128i)(__v8hu){ 24, 23, 22, 21, 20, 19, 18, 17 });
	v_s2 += (__v4su)_mm_madd_epi16((__m128i)v_byte_sums_c,
				       (__m128i)(__v8hu){ 16, 15, 14, 13, 12, 11, 10, 9 });
	v_s2 += (__v4su)_mm_madd_epi16((__m128i)v_byte_sums_d,
				       (__m128i)(__v8hu){ 8,  7,  6,  5,  4,  3,  2,  1 });

	
	ADLER32_FINISH_VEC_CHUNK_128(s1, s2, v_s1, v_s2);
}
/* #include "x86-../adler32_vec_template.h" */




static u32 ATTRIBUTES
FUNCNAME(u32 adler, const u8 *p, size_t size)
{
	u32 s1 = adler & 0xFFFF;
	u32 s2 = adler >> 16;
	const u8 * const end = p + size;
	const u8 *vend;
	const size_t max_chunk_size =
		MIN(MAX_CHUNK_SIZE, IMPL_MAX_CHUNK_SIZE) -
		(MIN(MAX_CHUNK_SIZE, IMPL_MAX_CHUNK_SIZE) %
		 IMPL_SEGMENT_SIZE);

	
	if (p != end && (uintptr_t)p % IMPL_ALIGNMENT) {
		do {
			s1 += *p++;
			s2 += s1;
		} while (p != end && (uintptr_t)p % IMPL_ALIGNMENT);
		s1 %= DIVISOR;
		s2 %= DIVISOR;
	}

	
	STATIC_ASSERT(IMPL_SEGMENT_SIZE % IMPL_ALIGNMENT == 0);
	vend = end - ((size_t)(end - p) % IMPL_SEGMENT_SIZE);
	while (p != vend) {
		size_t chunk_size = MIN((size_t)(vend - p), max_chunk_size);

		s2 += s1 * chunk_size;

		FUNCNAME_CHUNK((const void *)p, (const void *)(p + chunk_size),
			       &s1, &s2);

		p += chunk_size;
		s1 %= DIVISOR;
		s2 %= DIVISOR;
	}

	
	if (p != end) {
		do {
			s1 += *p++;
			s2 += s1;
		} while (p != end);
		s1 %= DIVISOR;
		s2 %= DIVISOR;
	}

	return (s2 << 16) | s1;
}

#undef FUNCNAME
#undef FUNCNAME_CHUNK
#undef ATTRIBUTES
#undef IMPL_ALIGNMENT
#undef IMPL_SEGMENT_SIZE
#undef IMPL_MAX_CHUNK_SIZE

#endif 

#ifdef DISPATCH
static inline adler32_func_t
arch_select_adler32_func(void)
{
	u32 features = get_cpu_features();

#ifdef DISPATCH_AVX512BW
	if (features & X86_CPU_FEATURE_AVX512BW)
		return adler32_avx512bw;
#endif
#ifdef DISPATCH_AVX2
	if (features & X86_CPU_FEATURE_AVX2)
		return adler32_avx2;
#endif
#ifdef DISPATCH_SSE2
	if (features & X86_CPU_FEATURE_SSE2)
		return adler32_sse2;
#endif
	return NULL;
}
#endif 

#endif


#ifndef DEFAULT_IMPL
#define DEFAULT_IMPL adler32_generic
static u32 adler32_generic(u32 adler, const u8 *p, size_t size)
{
	u32 s1 = adler & 0xFFFF;
	u32 s2 = adler >> 16;
	const u8 * const end = p + size;

	while (p != end) {
		size_t chunk_size = MIN(end - p, MAX_CHUNK_SIZE);
		const u8 *chunk_end = p + chunk_size;
		size_t num_unrolled_iterations = chunk_size / 4;

		while (num_unrolled_iterations--) {
			s1 += *p++;
			s2 += s1;
			s1 += *p++;
			s2 += s1;
			s1 += *p++;
			s2 += s1;
			s1 += *p++;
			s2 += s1;
		}
		while (p != chunk_end) {
			s1 += *p++;
			s2 += s1;
		}
		s1 %= DIVISOR;
		s2 %= DIVISOR;
	}

	return (s2 << 16) | s1;
}
#endif 

#ifdef DISPATCH
static u32 adler32_dispatch(u32, const u8 *, size_t);

static volatile adler32_func_t adler32_impl = adler32_dispatch;


static u32 adler32_dispatch(u32 adler, const u8 *buffer, size_t size)
{
	adler32_func_t f = arch_select_adler32_func();

	if (f == NULL)
		f = DEFAULT_IMPL;

	adler32_impl = f;
	return adler32_impl(adler, buffer, size);
}
#else
#  define adler32_impl DEFAULT_IMPL 
#endif

LIBDEFLATEEXPORT u32 LIBDEFLATEAPI
libdeflate_adler32(u32 adler, const void *buffer, size_t size)
{
	if (buffer == NULL) 
		return 1;
	return adler32_impl(adler, buffer, size);
}
/* /usr/home/ben/projects/gzip-libdeflate/../../software/libdeflate-1.7/lib/crc32.c */




/* #include "lib_common.h" */


#ifndef LIB_LIB_COMMON_H
#define LIB_LIB_COMMON_H

#ifdef LIBDEFLATE_H
#  error "lib_common.h must always be included before libdeflate.h"
   
#endif

#define BUILDING_LIBDEFLATE

/* #include "../common/common_defs.h" */


#ifndef COMMON_COMMON_DEFS_H
#define COMMON_COMMON_DEFS_H

#ifdef __GNUC__
/* #  include "compiler_gcc.h" */


#if !defined(__clang__) && !defined(__INTEL_COMPILER)
#  define GCC_PREREQ(major, minor)		\
	(__GNUC__ > (major) ||			\
	 (__GNUC__ == (major) && __GNUC_MINOR__ >= (minor)))
#else
#  define GCC_PREREQ(major, minor)	0
#endif


#ifdef __clang__
#  ifdef __apple_build_version__
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__apple_build_version__ >= (apple_version))
#  else
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__clang_major__ > (major) ||			\
	 (__clang_major__ == (major) && __clang_minor__ >= (minor)))
#  endif
#else
#  define CLANG_PREREQ(major, minor, apple_version)	0
#endif

#ifndef __has_attribute
#  define __has_attribute(attribute)	0
#endif
#ifndef __has_feature
#  define __has_feature(feature)	0
#endif
#ifndef __has_builtin
#  define __has_builtin(builtin)	0
#endif

#ifdef _WIN32
#  define LIBEXPORT __declspec(dllexport)
#else
#  define LIBEXPORT __attribute__((visibility("default")))
#endif

#define inline			inline
#define forceinline		inline __attribute__((always_inline))
#define restrict		__restrict__
#define likely(expr)		__builtin_expect(!!(expr), 1)
#define unlikely(expr)		__builtin_expect(!!(expr), 0)
#define prefetchr(addr)		__builtin_prefetch((addr), 0)
#define prefetchw(addr)		__builtin_prefetch((addr), 1)
#define _aligned_attribute(n)	__attribute__((aligned(n)))

#define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE	\
	(GCC_PREREQ(4, 4) || __has_attribute(target))

#if COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE

#  if defined(__i386__) || defined(__x86_64__)

#    define COMPILER_SUPPORTS_PCLMUL_TARGET	\
	(GCC_PREREQ(4, 4) || __has_builtin(__builtin_ia32_pclmulqdq128))

#    define COMPILER_SUPPORTS_AVX_TARGET	\
	(GCC_PREREQ(4, 6) || __has_builtin(__builtin_ia32_maxps256))

#    define COMPILER_SUPPORTS_BMI2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_pdep_di))

#    define COMPILER_SUPPORTS_AVX2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_psadbw256))

#    define COMPILER_SUPPORTS_AVX512BW_TARGET	\
	(GCC_PREREQ(5, 1) || __has_builtin(__builtin_ia32_psadbw512))

	
#    if GCC_PREREQ(4, 9) || CLANG_PREREQ(3, 8, 7030000)
#      define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS	1
#      define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_PCLMUL_TARGET
#      define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX2_TARGET
#      define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX512BW_TARGET
#    endif

#  elif defined(__arm__) || defined(__aarch64__)

    
#    if (GCC_PREREQ(6, 1) && defined(__ARM_FP)) || \
        (defined(__clang__) && defined(__ARM_NEON))
#      define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 1
       
#      if defined(__clang__) && defined(__arm__)
#        undef __ARM_FEATURE_CRYPTO
#      elif __has_builtin(__builtin_neon_vmull_p64) || !defined(__clang__)
#        define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 1
#      endif
#    endif

     
#    if GCC_PREREQ(10, 1) || \
        (GCC_PREREQ(9, 3) && !GCC_PREREQ(10, 0)) || \
        (GCC_PREREQ(8, 4) && !GCC_PREREQ(9, 0)) || \
        (defined(__clang__) && __has_builtin(__builtin_arm_crc32b))
#      define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 1
#    endif

#  endif 

#endif 


#if (GCC_PREREQ(4, 0) && !GCC_PREREQ(5, 1)) || \
    (defined(__clang__) && !CLANG_PREREQ(3, 9, 8020000))
typedef unsigned long long  __v2du __attribute__((__vector_size__(16)));
typedef unsigned int        __v4su __attribute__((__vector_size__(16)));
typedef unsigned short      __v8hu __attribute__((__vector_size__(16)));
typedef unsigned char      __v16qu __attribute__((__vector_size__(16)));
typedef unsigned long long  __v4du __attribute__((__vector_size__(32)));
typedef unsigned int        __v8su __attribute__((__vector_size__(32)));
typedef unsigned short     __v16hu __attribute__((__vector_size__(32)));
typedef unsigned char      __v32qu __attribute__((__vector_size__(32)));
#endif


#ifdef __BYTE_ORDER__
#  define CPU_IS_LITTLE_ENDIAN() (__BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__)
#endif

#if GCC_PREREQ(4, 8) || __has_builtin(__builtin_bswap16)
#  define bswap16	__builtin_bswap16
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap32)
#  define bswap32	__builtin_bswap32
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap64)
#  define bswap64	__builtin_bswap64
#endif

#if defined(__x86_64__) || defined(__i386__) || defined(__ARM_FEATURE_UNALIGNED) || defined(__powerpc64__)
#  define UNALIGNED_ACCESS_IS_FAST 1
#endif

#define bsr32(n)	(31 - __builtin_clz(n))
#define bsr64(n)	(63 - __builtin_clzll(n))
#define bsf32(n)	__builtin_ctz(n)
#define bsf64(n)	__builtin_ctzll(n)

#elif defined(_MSC_VER)
/* #  include "compiler_msc.h" */


#include <stdint.h>
#include <stdlib.h> 

#define LIBEXPORT	__declspec(dllexport)


typedef int bool;
#define true 1
#define false 0
#define __bool_true_false_are_defined 1


#ifdef _WIN64
typedef long long ssize_t;
#else
typedef int ssize_t;
#endif


#define CPU_IS_LITTLE_ENDIAN()		1
#define UNALIGNED_ACCESS_IS_FAST	1


#define restrict


#define inline		__inline
#define forceinline	__forceinline


#define bswap16	_byteswap_ushort
#define bswap32	_byteswap_ulong
#define bswap64	_byteswap_uint64



static forceinline unsigned
bsr32(uint32_t n)
{
	_BitScanReverse(&n, n);
	return n;
}
#define bsr32 bsr32

static forceinline unsigned
bsf32(uint32_t n)
{
	_BitScanForward(&n, n);
	return n;
}
#define bsf32 bsf32

#ifdef _M_X64 

static forceinline unsigned
bsr64(uint64_t n)
{
	_BitScanReverse64(&n, n);
	return n;
}
#define bsr64 bsr64

static forceinline unsigned
bsf64(uint64_t n)
{
	_BitScanForward64(&n, n);
	return n;
}
#define bsf64 bsf64

#endif 

#else
#  pragma message("Unrecognized compiler.  Please add a header file for your compiler.  Compilation will proceed, but performance may suffer!")
#endif





#include <stddef.h> 

#ifndef __bool_true_false_are_defined
#  include <stdbool.h> 
#endif


#include <stdint.h>
typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
typedef int8_t s8;
typedef int16_t s16;
typedef int32_t s32;
typedef int64_t s64;


typedef size_t machine_word_t;


#define WORDBYTES	((int)sizeof(machine_word_t))


#define WORDBITS	(8 * WORDBYTES)






#ifndef LIBEXPORT
#  define LIBEXPORT
#endif


#ifndef inline
#  define inline
#endif


#ifndef forceinline
#  define forceinline inline
#endif


#ifndef restrict
#  define restrict
#endif


#ifndef likely
#  define likely(expr)		(expr)
#endif


#ifndef unlikely
#  define unlikely(expr)	(expr)
#endif


#ifndef prefetchr
#  define prefetchr(addr)
#endif


#ifndef prefetchw
#  define prefetchw(addr)
#endif


#ifndef COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE
#  define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE 0
#endif


#ifndef COMPILER_SUPPORTS_BMI2_TARGET
#  define COMPILER_SUPPORTS_BMI2_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX_TARGET
#  define COMPILER_SUPPORTS_AVX_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET
#  define COMPILER_SUPPORTS_AVX512BW_TARGET 0
#endif


#ifndef COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 0
#endif


#ifndef _aligned_attribute
#endif





#define ARRAY_LEN(A)		(sizeof(A) / sizeof((A)[0]))
#define MIN(a, b)		((a) <= (b) ? (a) : (b))
#define MAX(a, b)		((a) >= (b) ? (a) : (b))
#define DIV_ROUND_UP(n, d)	(((n) + (d) - 1) / (d))
#define STATIC_ASSERT(expr)	((void)sizeof(char[1 - 2 * !(expr)]))
#define ALIGN(n, a)		(((n) + (a) - 1) & ~((a) - 1))






#ifndef CPU_IS_LITTLE_ENDIAN
static forceinline int CPU_IS_LITTLE_ENDIAN(void)
{
	union {
		unsigned int v;
		unsigned char b;
	} u;
	u.v = 1;
	return u.b;
}
#endif


#ifndef bswap16
static forceinline u16 bswap16(u16 n)
{
	return (n << 8) | (n >> 8);
}
#endif


#ifndef bswap32
static forceinline u32 bswap32(u32 n)
{
	return ((n & 0x000000FF) << 24) |
	       ((n & 0x0000FF00) << 8) |
	       ((n & 0x00FF0000) >> 8) |
	       ((n & 0xFF000000) >> 24);
}
#endif


#ifndef bswap64
static forceinline u64 bswap64(u64 n)
{
	return ((n & 0x00000000000000FF) << 56) |
	       ((n & 0x000000000000FF00) << 40) |
	       ((n & 0x0000000000FF0000) << 24) |
	       ((n & 0x00000000FF000000) << 8) |
	       ((n & 0x000000FF00000000) >> 8) |
	       ((n & 0x0000FF0000000000) >> 24) |
	       ((n & 0x00FF000000000000) >> 40) |
	       ((n & 0xFF00000000000000) >> 56);
}
#endif

#define le16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap16(n))
#define le32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap32(n))
#define le64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap64(n))
#define be16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap16(n) : (n))
#define be32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap32(n) : (n))
#define be64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap64(n) : (n))






#ifndef UNALIGNED_ACCESS_IS_FAST
#  define UNALIGNED_ACCESS_IS_FAST 0
#endif







#ifndef bsr32
static forceinline unsigned
bsr32(u32 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

#ifndef bsr64
static forceinline unsigned
bsr64(u64 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

static forceinline unsigned
bsrw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsr32(n);
	else
		return bsr64(n);
}



#ifndef bsf32
static forceinline unsigned
bsf32(u32 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

#ifndef bsf64
static forceinline unsigned
bsf64(u64 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

static forceinline unsigned
bsfw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsf32(n);
	else
		return bsf64(n);
}

#endif 



#define SYM_FIXUP(sym)			_libdeflate_##sym
#define deflate_get_compression_level	SYM_FIXUP(deflate_get_compression_level)
#define _cpu_features			SYM_FIXUP(_cpu_features)
#define setup_cpu_features		SYM_FIXUP(setup_cpu_features)

void *libdeflate_malloc(size_t size);
void libdeflate_free(void *ptr);

void *libdeflate_aligned_malloc(size_t alignment, size_t size);
void libdeflate_aligned_free(void *ptr);

#ifdef FREESTANDING

void *memset(void *s, int c, size_t n);
#define memset(s, c, n)		__builtin_memset((s), (c), (n))

void *memcpy(void *dest, const void *src, size_t n);
#define memcpy(dest, src, n)	__builtin_memcpy((dest), (src), (n))

void *memmove(void *dest, const void *src, size_t n);
#define memmove(dest, src, n)	__builtin_memmove((dest), (src), (n))

int memcmp(const void *s1, const void *s2, size_t n);
#define memcmp(s1, s2, n)	__builtin_memcmp((s1), (s2), (n))
#else
#include <string.h>
#endif

#endif 

/* #include "libdeflate.h" */


#ifndef LIBDEFLATE_H
#define LIBDEFLATE_H

#ifdef __cplusplus
extern "C" {
#endif

#define LIBDEFLATE_VERSION_MAJOR	1
#define LIBDEFLATE_VERSION_MINOR	7
#define LIBDEFLATE_VERSION_STRING	"1.7"

#include <stddef.h>
#include <stdint.h>


#ifdef LIBDEFLATE_DLL
#  ifdef BUILDING_LIBDEFLATE
#    define LIBDEFLATEEXPORT	LIBEXPORT
#  elif defined(_WIN32) || defined(__CYGWIN__)
#    define LIBDEFLATEEXPORT	__declspec(dllimport)
#  endif
#endif
#ifndef LIBDEFLATEEXPORT
#  define LIBDEFLATEEXPORT
#endif

#if defined(_WIN32) && !defined(_WIN64)
#  define LIBDEFLATEAPI_ABI	__stdcall
#else
#  define LIBDEFLATEAPI_ABI
#endif

#if defined(BUILDING_LIBDEFLATE) && defined(__GNUC__) && \
	defined(_WIN32) && !defined(_WIN64)
    
#  define LIBDEFLATEAPI_STACKALIGN	__attribute__((force_align_arg_pointer))
#else
#  define LIBDEFLATEAPI_STACKALIGN
#endif

#define LIBDEFLATEAPI	LIBDEFLATEAPI_ABI LIBDEFLATEAPI_STACKALIGN





struct libdeflate_compressor;


LIBDEFLATEEXPORT struct libdeflate_compressor * LIBDEFLATEAPI
libdeflate_alloc_compressor(int compression_level);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_deflate_compress(struct libdeflate_compressor *compressor,
			    const void *in, size_t in_nbytes,
			    void *out, size_t out_nbytes_avail);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_deflate_compress_bound(struct libdeflate_compressor *compressor,
				  size_t in_nbytes);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_zlib_compress(struct libdeflate_compressor *compressor,
			 const void *in, size_t in_nbytes,
			 void *out, size_t out_nbytes_avail);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_zlib_compress_bound(struct libdeflate_compressor *compressor,
			       size_t in_nbytes);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_gzip_compress(struct libdeflate_compressor *compressor,
			 const void *in, size_t in_nbytes,
			 void *out, size_t out_nbytes_avail);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_gzip_compress_bound(struct libdeflate_compressor *compressor,
			       size_t in_nbytes);


LIBDEFLATEEXPORT void LIBDEFLATEAPI
libdeflate_free_compressor(struct libdeflate_compressor *compressor);





struct libdeflate_decompressor;


LIBDEFLATEEXPORT struct libdeflate_decompressor * LIBDEFLATEAPI
libdeflate_alloc_decompressor(void);


enum libdeflate_result {
	
	LIBDEFLATE_SUCCESS = 0,

	
	LIBDEFLATE_BAD_DATA = 1,

	
	LIBDEFLATE_SHORT_OUTPUT = 2,

	
	LIBDEFLATE_INSUFFICIENT_SPACE = 3,
};


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_deflate_decompress(struct libdeflate_decompressor *decompressor,
			      const void *in, size_t in_nbytes,
			      void *out, size_t out_nbytes_avail,
			      size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_deflate_decompress_ex(struct libdeflate_decompressor *decompressor,
				 const void *in, size_t in_nbytes,
				 void *out, size_t out_nbytes_avail,
				 size_t *actual_in_nbytes_ret,
				 size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_zlib_decompress(struct libdeflate_decompressor *decompressor,
			   const void *in, size_t in_nbytes,
			   void *out, size_t out_nbytes_avail,
			   size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_zlib_decompress_ex(struct libdeflate_decompressor *decompressor,
			      const void *in, size_t in_nbytes,
			      void *out, size_t out_nbytes_avail,
			      size_t *actual_in_nbytes_ret,
			      size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_gzip_decompress(struct libdeflate_decompressor *decompressor,
			   const void *in, size_t in_nbytes,
			   void *out, size_t out_nbytes_avail,
			   size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_gzip_decompress_ex(struct libdeflate_decompressor *decompressor,
			      const void *in, size_t in_nbytes,
			      void *out, size_t out_nbytes_avail,
			      size_t *actual_in_nbytes_ret,
			      size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT void LIBDEFLATEAPI
libdeflate_free_decompressor(struct libdeflate_decompressor *decompressor);






LIBDEFLATEEXPORT uint32_t LIBDEFLATEAPI
libdeflate_adler32(uint32_t adler, const void *buffer, size_t len);



LIBDEFLATEEXPORT uint32_t LIBDEFLATEAPI
libdeflate_crc32(uint32_t crc, const void *buffer, size_t len);






LIBDEFLATEEXPORT void LIBDEFLATEAPI
libdeflate_set_memory_allocator(void *(*malloc_func)(size_t),
				void (*free_func)(void *));

#ifdef __cplusplus
}
#endif

#endif 


typedef u32 (*crc32_func_t)(u32, const u8 *, size_t);


#undef CRC32_SLICE1
#undef CRC32_SLICE4
#undef CRC32_SLICE8
#undef DEFAULT_IMPL
#undef DISPATCH
#if defined(__arm__) || defined(__aarch64__)
/* #  include "arm/crc32_impl.h" */


/* #include "arm-cpu_features.h" */


#ifndef LIB_ARM_CPU_FEATURES_H
#define LIB_ARM_CPU_FEATURES_H

/* #include "lib_common.h" */


#ifndef LIB_LIB_COMMON_H
#define LIB_LIB_COMMON_H

#ifdef LIBDEFLATE_H
#  error "lib_common.h must always be included before libdeflate.h"
   
#endif

#define BUILDING_LIBDEFLATE

/* #include "../common/common_defs.h" */


#ifndef COMMON_COMMON_DEFS_H
#define COMMON_COMMON_DEFS_H

#ifdef __GNUC__
/* #  include "compiler_gcc.h" */


#if !defined(__clang__) && !defined(__INTEL_COMPILER)
#  define GCC_PREREQ(major, minor)		\
	(__GNUC__ > (major) ||			\
	 (__GNUC__ == (major) && __GNUC_MINOR__ >= (minor)))
#else
#  define GCC_PREREQ(major, minor)	0
#endif


#ifdef __clang__
#  ifdef __apple_build_version__
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__apple_build_version__ >= (apple_version))
#  else
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__clang_major__ > (major) ||			\
	 (__clang_major__ == (major) && __clang_minor__ >= (minor)))
#  endif
#else
#  define CLANG_PREREQ(major, minor, apple_version)	0
#endif

#ifndef __has_attribute
#  define __has_attribute(attribute)	0
#endif
#ifndef __has_feature
#  define __has_feature(feature)	0
#endif
#ifndef __has_builtin
#  define __has_builtin(builtin)	0
#endif

#ifdef _WIN32
#  define LIBEXPORT __declspec(dllexport)
#else
#  define LIBEXPORT __attribute__((visibility("default")))
#endif

#define inline			inline
#define forceinline		inline __attribute__((always_inline))
#define restrict		__restrict__
#define likely(expr)		__builtin_expect(!!(expr), 1)
#define unlikely(expr)		__builtin_expect(!!(expr), 0)
#define prefetchr(addr)		__builtin_prefetch((addr), 0)
#define prefetchw(addr)		__builtin_prefetch((addr), 1)
#define _aligned_attribute(n)	__attribute__((aligned(n)))

#define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE	\
	(GCC_PREREQ(4, 4) || __has_attribute(target))

#if COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE

#  if defined(__i386__) || defined(__x86_64__)

#    define COMPILER_SUPPORTS_PCLMUL_TARGET	\
	(GCC_PREREQ(4, 4) || __has_builtin(__builtin_ia32_pclmulqdq128))

#    define COMPILER_SUPPORTS_AVX_TARGET	\
	(GCC_PREREQ(4, 6) || __has_builtin(__builtin_ia32_maxps256))

#    define COMPILER_SUPPORTS_BMI2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_pdep_di))

#    define COMPILER_SUPPORTS_AVX2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_psadbw256))

#    define COMPILER_SUPPORTS_AVX512BW_TARGET	\
	(GCC_PREREQ(5, 1) || __has_builtin(__builtin_ia32_psadbw512))

	
#    if GCC_PREREQ(4, 9) || CLANG_PREREQ(3, 8, 7030000)
#      define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS	1
#      define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_PCLMUL_TARGET
#      define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX2_TARGET
#      define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX512BW_TARGET
#    endif

#  elif defined(__arm__) || defined(__aarch64__)

    
#    if (GCC_PREREQ(6, 1) && defined(__ARM_FP)) || \
        (defined(__clang__) && defined(__ARM_NEON))
#      define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 1
       
#      if defined(__clang__) && defined(__arm__)
#        undef __ARM_FEATURE_CRYPTO
#      elif __has_builtin(__builtin_neon_vmull_p64) || !defined(__clang__)
#        define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 1
#      endif
#    endif

     
#    if GCC_PREREQ(10, 1) || \
        (GCC_PREREQ(9, 3) && !GCC_PREREQ(10, 0)) || \
        (GCC_PREREQ(8, 4) && !GCC_PREREQ(9, 0)) || \
        (defined(__clang__) && __has_builtin(__builtin_arm_crc32b))
#      define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 1
#    endif

#  endif 

#endif 


#if (GCC_PREREQ(4, 0) && !GCC_PREREQ(5, 1)) || \
    (defined(__clang__) && !CLANG_PREREQ(3, 9, 8020000))
typedef unsigned long long  __v2du __attribute__((__vector_size__(16)));
typedef unsigned int        __v4su __attribute__((__vector_size__(16)));
typedef unsigned short      __v8hu __attribute__((__vector_size__(16)));
typedef unsigned char      __v16qu __attribute__((__vector_size__(16)));
typedef unsigned long long  __v4du __attribute__((__vector_size__(32)));
typedef unsigned int        __v8su __attribute__((__vector_size__(32)));
typedef unsigned short     __v16hu __attribute__((__vector_size__(32)));
typedef unsigned char      __v32qu __attribute__((__vector_size__(32)));
#endif


#ifdef __BYTE_ORDER__
#  define CPU_IS_LITTLE_ENDIAN() (__BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__)
#endif

#if GCC_PREREQ(4, 8) || __has_builtin(__builtin_bswap16)
#  define bswap16	__builtin_bswap16
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap32)
#  define bswap32	__builtin_bswap32
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap64)
#  define bswap64	__builtin_bswap64
#endif

#if defined(__x86_64__) || defined(__i386__) || defined(__ARM_FEATURE_UNALIGNED) || defined(__powerpc64__)
#  define UNALIGNED_ACCESS_IS_FAST 1
#endif

#define bsr32(n)	(31 - __builtin_clz(n))
#define bsr64(n)	(63 - __builtin_clzll(n))
#define bsf32(n)	__builtin_ctz(n)
#define bsf64(n)	__builtin_ctzll(n)

#elif defined(_MSC_VER)
/* #  include "compiler_msc.h" */


#include <stdint.h>
#include <stdlib.h> 

#define LIBEXPORT	__declspec(dllexport)


typedef int bool;
#define true 1
#define false 0
#define __bool_true_false_are_defined 1


#ifdef _WIN64
typedef long long ssize_t;
#else
typedef int ssize_t;
#endif


#define CPU_IS_LITTLE_ENDIAN()		1
#define UNALIGNED_ACCESS_IS_FAST	1


#define restrict


#define inline		__inline
#define forceinline	__forceinline


#define bswap16	_byteswap_ushort
#define bswap32	_byteswap_ulong
#define bswap64	_byteswap_uint64



static forceinline unsigned
bsr32(uint32_t n)
{
	_BitScanReverse(&n, n);
	return n;
}
#define bsr32 bsr32

static forceinline unsigned
bsf32(uint32_t n)
{
	_BitScanForward(&n, n);
	return n;
}
#define bsf32 bsf32

#ifdef _M_X64 

static forceinline unsigned
bsr64(uint64_t n)
{
	_BitScanReverse64(&n, n);
	return n;
}
#define bsr64 bsr64

static forceinline unsigned
bsf64(uint64_t n)
{
	_BitScanForward64(&n, n);
	return n;
}
#define bsf64 bsf64

#endif 

#else
#  pragma message("Unrecognized compiler.  Please add a header file for your compiler.  Compilation will proceed, but performance may suffer!")
#endif





#include <stddef.h> 

#ifndef __bool_true_false_are_defined
#  include <stdbool.h> 
#endif


#include <stdint.h>
typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
typedef int8_t s8;
typedef int16_t s16;
typedef int32_t s32;
typedef int64_t s64;


typedef size_t machine_word_t;


#define WORDBYTES	((int)sizeof(machine_word_t))


#define WORDBITS	(8 * WORDBYTES)






#ifndef LIBEXPORT
#  define LIBEXPORT
#endif


#ifndef inline
#  define inline
#endif


#ifndef forceinline
#  define forceinline inline
#endif


#ifndef restrict
#  define restrict
#endif


#ifndef likely
#  define likely(expr)		(expr)
#endif


#ifndef unlikely
#  define unlikely(expr)	(expr)
#endif


#ifndef prefetchr
#  define prefetchr(addr)
#endif


#ifndef prefetchw
#  define prefetchw(addr)
#endif


#ifndef COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE
#  define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE 0
#endif


#ifndef COMPILER_SUPPORTS_BMI2_TARGET
#  define COMPILER_SUPPORTS_BMI2_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX_TARGET
#  define COMPILER_SUPPORTS_AVX_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET
#  define COMPILER_SUPPORTS_AVX512BW_TARGET 0
#endif


#ifndef COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 0
#endif


#ifndef _aligned_attribute
#endif





#define ARRAY_LEN(A)		(sizeof(A) / sizeof((A)[0]))
#define MIN(a, b)		((a) <= (b) ? (a) : (b))
#define MAX(a, b)		((a) >= (b) ? (a) : (b))
#define DIV_ROUND_UP(n, d)	(((n) + (d) - 1) / (d))
#define STATIC_ASSERT(expr)	((void)sizeof(char[1 - 2 * !(expr)]))
#define ALIGN(n, a)		(((n) + (a) - 1) & ~((a) - 1))






#ifndef CPU_IS_LITTLE_ENDIAN
static forceinline int CPU_IS_LITTLE_ENDIAN(void)
{
	union {
		unsigned int v;
		unsigned char b;
	} u;
	u.v = 1;
	return u.b;
}
#endif


#ifndef bswap16
static forceinline u16 bswap16(u16 n)
{
	return (n << 8) | (n >> 8);
}
#endif


#ifndef bswap32
static forceinline u32 bswap32(u32 n)
{
	return ((n & 0x000000FF) << 24) |
	       ((n & 0x0000FF00) << 8) |
	       ((n & 0x00FF0000) >> 8) |
	       ((n & 0xFF000000) >> 24);
}
#endif


#ifndef bswap64
static forceinline u64 bswap64(u64 n)
{
	return ((n & 0x00000000000000FF) << 56) |
	       ((n & 0x000000000000FF00) << 40) |
	       ((n & 0x0000000000FF0000) << 24) |
	       ((n & 0x00000000FF000000) << 8) |
	       ((n & 0x000000FF00000000) >> 8) |
	       ((n & 0x0000FF0000000000) >> 24) |
	       ((n & 0x00FF000000000000) >> 40) |
	       ((n & 0xFF00000000000000) >> 56);
}
#endif

#define le16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap16(n))
#define le32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap32(n))
#define le64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap64(n))
#define be16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap16(n) : (n))
#define be32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap32(n) : (n))
#define be64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap64(n) : (n))






#ifndef UNALIGNED_ACCESS_IS_FAST
#  define UNALIGNED_ACCESS_IS_FAST 0
#endif







#ifndef bsr32
static forceinline unsigned
bsr32(u32 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

#ifndef bsr64
static forceinline unsigned
bsr64(u64 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

static forceinline unsigned
bsrw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsr32(n);
	else
		return bsr64(n);
}



#ifndef bsf32
static forceinline unsigned
bsf32(u32 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

#ifndef bsf64
static forceinline unsigned
bsf64(u64 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

static forceinline unsigned
bsfw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsf32(n);
	else
		return bsf64(n);
}

#endif 



#define SYM_FIXUP(sym)			_libdeflate_##sym
#define deflate_get_compression_level	SYM_FIXUP(deflate_get_compression_level)
#define _cpu_features			SYM_FIXUP(_cpu_features)
#define setup_cpu_features		SYM_FIXUP(setup_cpu_features)

void *libdeflate_malloc(size_t size);
void libdeflate_free(void *ptr);

void *libdeflate_aligned_malloc(size_t alignment, size_t size);
void libdeflate_aligned_free(void *ptr);

#ifdef FREESTANDING

void *memset(void *s, int c, size_t n);
#define memset(s, c, n)		__builtin_memset((s), (c), (n))

void *memcpy(void *dest, const void *src, size_t n);
#define memcpy(dest, src, n)	__builtin_memcpy((dest), (src), (n))

void *memmove(void *dest, const void *src, size_t n);
#define memmove(dest, src, n)	__builtin_memmove((dest), (src), (n))

int memcmp(const void *s1, const void *s2, size_t n);
#define memcmp(s1, s2, n)	__builtin_memcmp((s1), (s2), (n))
#else
#include <string.h>
#endif

#endif 


#if (defined(__arm__) || defined(__aarch64__)) && \
	defined(__linux__) && \
	COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE && \
	!defined(FREESTANDING)
#  define ARM_CPU_FEATURES_ENABLED 1
#else
#  define ARM_CPU_FEATURES_ENABLED 0
#endif

#if ARM_CPU_FEATURES_ENABLED

#define ARM_CPU_FEATURE_NEON		0x00000001
#define ARM_CPU_FEATURE_PMULL		0x00000002
#define ARM_CPU_FEATURE_CRC32		0x00000004

#define ARM_CPU_FEATURES_KNOWN		0x80000000

extern volatile u32 _cpu_features;

void setup_cpu_features(void);

static inline u32 get_cpu_features(void)
{
	if (_cpu_features == 0)
		setup_cpu_features();
	return _cpu_features;
}

#endif 

#endif 



#undef DISPATCH_ARM
#if !defined(DEFAULT_IMPL) && \
    (defined(__ARM_FEATURE_CRC32) || \
     (ARM_CPU_FEATURES_ENABLED && COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS))
#  ifdef __ARM_FEATURE_CRC32
#    define ATTRIBUTES
#    define DEFAULT_IMPL	crc32_arm
#  else
#    ifdef __arm__
#      ifdef __clang__
#        define ATTRIBUTES	__attribute__((target("armv8-a,crc")))
#      else
#        define ATTRIBUTES	__attribute__((target("arch=armv8-a+crc")))
#      endif
#    else
#      ifdef __clang__
#        define ATTRIBUTES	__attribute__((target("crc")))
#      else
#        define ATTRIBUTES	__attribute__((target("+crc")))
#      endif
#    endif
#    define DISPATCH		1
#    define DISPATCH_ARM	1
#  endif


#ifndef __ARM_FEATURE_CRC32
#  define __ARM_FEATURE_CRC32	1
#endif
#include <arm_acle.h>

static u32 ATTRIBUTES
crc32_arm(u32 remainder, const u8 *p, size_t size)
{
	while (size != 0 && (uintptr_t)p & 7) {
		remainder = __crc32b(remainder, *p++);
		size--;
	}

	while (size >= 32) {
		remainder = __crc32d(remainder, le64_bswap(*((u64 *)p + 0)));
		remainder = __crc32d(remainder, le64_bswap(*((u64 *)p + 1)));
		remainder = __crc32d(remainder, le64_bswap(*((u64 *)p + 2)));
		remainder = __crc32d(remainder, le64_bswap(*((u64 *)p + 3)));
		p += 32;
		size -= 32;
	}

	while (size >= 8) {
		remainder = __crc32d(remainder, le64_bswap(*(u64 *)p));
		p += 8;
		size -= 8;
	}

	while (size != 0) {
		remainder = __crc32b(remainder, *p++);
		size--;
	}

	return remainder;
}
#undef ATTRIBUTES
#endif 


#undef DISPATCH_PMULL
#if !defined(DEFAULT_IMPL) && \
    (defined(__ARM_FEATURE_CRYPTO) ||	\
     (ARM_CPU_FEATURES_ENABLED &&	\
      COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS)) && \
       \
    (defined(__BYTE_ORDER__) && __BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__)
#  define FUNCNAME		crc32_pmull
#  define FUNCNAME_ALIGNED	crc32_pmull_aligned
#  ifdef __ARM_FEATURE_CRYPTO
#    define ATTRIBUTES
#    define DEFAULT_IMPL	crc32_pmull
#  else
#    ifdef __arm__
#      define ATTRIBUTES	__attribute__((target("fpu=crypto-neon-fp-armv8")))
#    else
#      ifdef __clang__
#        define ATTRIBUTES	__attribute__((target("crypto")))
#      else
#        define ATTRIBUTES	__attribute__((target("+crypto")))
#      endif
#    endif
#    define DISPATCH		1
#    define DISPATCH_PMULL	1
#  endif

#include <arm_neon.h>

static forceinline ATTRIBUTES uint8x16_t
clmul_00(uint8x16_t a, uint8x16_t b)
{
	return (uint8x16_t)vmull_p64((poly64_t)vget_low_u8(a),
				     (poly64_t)vget_low_u8(b));
}

static forceinline ATTRIBUTES uint8x16_t
clmul_10(uint8x16_t a, uint8x16_t b)
{
	return (uint8x16_t)vmull_p64((poly64_t)vget_low_u8(a),
				     (poly64_t)vget_high_u8(b));
}

static forceinline ATTRIBUTES uint8x16_t
clmul_11(uint8x16_t a, uint8x16_t b)
{
	return (uint8x16_t)vmull_high_p64((poly64x2_t)a, (poly64x2_t)b);
}

static forceinline ATTRIBUTES uint8x16_t
fold_128b(uint8x16_t dst, uint8x16_t src, uint8x16_t multipliers)
{
	return dst ^ clmul_00(src, multipliers) ^ clmul_11(src, multipliers);
}

static forceinline ATTRIBUTES u32
crc32_pmull_aligned(u32 remainder, const uint8x16_t *p, size_t nr_segs)
{
	
	const uint8x16_t multipliers_4 =
		(uint8x16_t)(uint64x2_t){ 0x8F352D95, 0x1D9513D7 };
	const uint8x16_t multipliers_1 =
		(uint8x16_t)(uint64x2_t){ 0xAE689191, 0xCCAA009E };
	const uint8x16_t final_multiplier =
		(uint8x16_t)(uint64x2_t){ 0xB8BC6765 };
	const uint8x16_t mask32 = (uint8x16_t)(uint32x4_t){ 0xFFFFFFFF };
	const uint8x16_t barrett_reduction_constants =
			(uint8x16_t)(uint64x2_t){ 0x00000001F7011641,
						  0x00000001DB710641 };
	const uint8x16_t zeroes = (uint8x16_t){ 0 };

	const uint8x16_t * const end = p + nr_segs;
	const uint8x16_t * const end512 = p + (nr_segs & ~3);
	uint8x16_t x0, x1, x2, x3;

	x0 = *p++ ^ (uint8x16_t)(uint32x4_t){ remainder };
	if (nr_segs >= 4) {
		x1 = *p++;
		x2 = *p++;
		x3 = *p++;

		
		while (p != end512) {
			x0 = fold_128b(*p++, x0, multipliers_4);
			x1 = fold_128b(*p++, x1, multipliers_4);
			x2 = fold_128b(*p++, x2, multipliers_4);
			x3 = fold_128b(*p++, x3, multipliers_4);
		}

		
		x1 = fold_128b(x1, x0, multipliers_1);
		x2 = fold_128b(x2, x1, multipliers_1);
		x0 = fold_128b(x3, x2, multipliers_1);
	}

	
	while (p != end)
		x0 = fold_128b(*p++, x0, multipliers_1);

	
	x0 = vextq_u8(x0, zeroes, 8) ^ clmul_10(x0, multipliers_1);

	
	x0 = vextq_u8(x0, zeroes, 4) ^ clmul_00(x0 & mask32, final_multiplier);

	
	x1 = x0;
	x0 = clmul_00(x0 & mask32, barrett_reduction_constants);
	x0 = clmul_10(x0 & mask32, barrett_reduction_constants);
	return vgetq_lane_u32((uint32x4_t)(x0 ^ x1), 1);
}
#define IMPL_ALIGNMENT		16
#define IMPL_SEGMENT_SIZE	16
/* #include "crc32_vec_template.h" */


#define CRC32_SLICE1	1
static u32 crc32_slice1(u32, const u8 *, size_t);


static u32 ATTRIBUTES
FUNCNAME(u32 remainder, const u8 *p, size_t size)
{
	if ((uintptr_t)p % IMPL_ALIGNMENT) {
		size_t n = MIN(size, -(uintptr_t)p % IMPL_ALIGNMENT);

		remainder = crc32_slice1(remainder, p, n);
		p += n;
		size -= n;
	}
	if (size >= IMPL_SEGMENT_SIZE) {
		remainder = FUNCNAME_ALIGNED(remainder, (const void *)p,
					     size / IMPL_SEGMENT_SIZE);
		p += size - (size % IMPL_SEGMENT_SIZE);
		size %= IMPL_SEGMENT_SIZE;
	}
	return crc32_slice1(remainder, p, size);
}

#undef FUNCNAME
#undef FUNCNAME_ALIGNED
#undef ATTRIBUTES
#undef IMPL_ALIGNMENT
#undef IMPL_SEGMENT_SIZE

#endif 

#ifdef DISPATCH
static inline crc32_func_t
arch_select_crc32_func(void)
{
	u32 features = get_cpu_features();

#ifdef DISPATCH_ARM
	if (features & ARM_CPU_FEATURE_CRC32)
		return crc32_arm;
#endif
#ifdef DISPATCH_PMULL
	if (features & ARM_CPU_FEATURE_PMULL)
		return crc32_pmull;
#endif
	return NULL;
}
#endif 

#elif defined(__i386__) || defined(__x86_64__)
/* #  include "x86/crc32_impl.h" */


/* #include "x86-cpu_features.h" */


#ifndef LIB_X86_CPU_FEATURES_H
#define LIB_X86_CPU_FEATURES_H

/* #include "lib_common.h" */


#ifndef LIB_LIB_COMMON_H
#define LIB_LIB_COMMON_H

#ifdef LIBDEFLATE_H
#  error "lib_common.h must always be included before libdeflate.h"
   
#endif

#define BUILDING_LIBDEFLATE

/* #include "../common/common_defs.h" */


#ifndef COMMON_COMMON_DEFS_H
#define COMMON_COMMON_DEFS_H

#ifdef __GNUC__
/* #  include "compiler_gcc.h" */


#if !defined(__clang__) && !defined(__INTEL_COMPILER)
#  define GCC_PREREQ(major, minor)		\
	(__GNUC__ > (major) ||			\
	 (__GNUC__ == (major) && __GNUC_MINOR__ >= (minor)))
#else
#  define GCC_PREREQ(major, minor)	0
#endif


#ifdef __clang__
#  ifdef __apple_build_version__
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__apple_build_version__ >= (apple_version))
#  else
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__clang_major__ > (major) ||			\
	 (__clang_major__ == (major) && __clang_minor__ >= (minor)))
#  endif
#else
#  define CLANG_PREREQ(major, minor, apple_version)	0
#endif

#ifndef __has_attribute
#  define __has_attribute(attribute)	0
#endif
#ifndef __has_feature
#  define __has_feature(feature)	0
#endif
#ifndef __has_builtin
#  define __has_builtin(builtin)	0
#endif

#ifdef _WIN32
#  define LIBEXPORT __declspec(dllexport)
#else
#  define LIBEXPORT __attribute__((visibility("default")))
#endif

#define inline			inline
#define forceinline		inline __attribute__((always_inline))
#define restrict		__restrict__
#define likely(expr)		__builtin_expect(!!(expr), 1)
#define unlikely(expr)		__builtin_expect(!!(expr), 0)
#define prefetchr(addr)		__builtin_prefetch((addr), 0)
#define prefetchw(addr)		__builtin_prefetch((addr), 1)
#define _aligned_attribute(n)	__attribute__((aligned(n)))

#define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE	\
	(GCC_PREREQ(4, 4) || __has_attribute(target))

#if COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE

#  if defined(__i386__) || defined(__x86_64__)

#    define COMPILER_SUPPORTS_PCLMUL_TARGET	\
	(GCC_PREREQ(4, 4) || __has_builtin(__builtin_ia32_pclmulqdq128))

#    define COMPILER_SUPPORTS_AVX_TARGET	\
	(GCC_PREREQ(4, 6) || __has_builtin(__builtin_ia32_maxps256))

#    define COMPILER_SUPPORTS_BMI2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_pdep_di))

#    define COMPILER_SUPPORTS_AVX2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_psadbw256))

#    define COMPILER_SUPPORTS_AVX512BW_TARGET	\
	(GCC_PREREQ(5, 1) || __has_builtin(__builtin_ia32_psadbw512))

	
#    if GCC_PREREQ(4, 9) || CLANG_PREREQ(3, 8, 7030000)
#      define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS	1
#      define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_PCLMUL_TARGET
#      define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX2_TARGET
#      define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX512BW_TARGET
#    endif

#  elif defined(__arm__) || defined(__aarch64__)

    
#    if (GCC_PREREQ(6, 1) && defined(__ARM_FP)) || \
        (defined(__clang__) && defined(__ARM_NEON))
#      define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 1
       
#      if defined(__clang__) && defined(__arm__)
#        undef __ARM_FEATURE_CRYPTO
#      elif __has_builtin(__builtin_neon_vmull_p64) || !defined(__clang__)
#        define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 1
#      endif
#    endif

     
#    if GCC_PREREQ(10, 1) || \
        (GCC_PREREQ(9, 3) && !GCC_PREREQ(10, 0)) || \
        (GCC_PREREQ(8, 4) && !GCC_PREREQ(9, 0)) || \
        (defined(__clang__) && __has_builtin(__builtin_arm_crc32b))
#      define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 1
#    endif

#  endif 

#endif 


#if (GCC_PREREQ(4, 0) && !GCC_PREREQ(5, 1)) || \
    (defined(__clang__) && !CLANG_PREREQ(3, 9, 8020000))
typedef unsigned long long  __v2du __attribute__((__vector_size__(16)));
typedef unsigned int        __v4su __attribute__((__vector_size__(16)));
typedef unsigned short      __v8hu __attribute__((__vector_size__(16)));
typedef unsigned char      __v16qu __attribute__((__vector_size__(16)));
typedef unsigned long long  __v4du __attribute__((__vector_size__(32)));
typedef unsigned int        __v8su __attribute__((__vector_size__(32)));
typedef unsigned short     __v16hu __attribute__((__vector_size__(32)));
typedef unsigned char      __v32qu __attribute__((__vector_size__(32)));
#endif


#ifdef __BYTE_ORDER__
#  define CPU_IS_LITTLE_ENDIAN() (__BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__)
#endif

#if GCC_PREREQ(4, 8) || __has_builtin(__builtin_bswap16)
#  define bswap16	__builtin_bswap16
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap32)
#  define bswap32	__builtin_bswap32
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap64)
#  define bswap64	__builtin_bswap64
#endif

#if defined(__x86_64__) || defined(__i386__) || defined(__ARM_FEATURE_UNALIGNED) || defined(__powerpc64__)
#  define UNALIGNED_ACCESS_IS_FAST 1
#endif

#define bsr32(n)	(31 - __builtin_clz(n))
#define bsr64(n)	(63 - __builtin_clzll(n))
#define bsf32(n)	__builtin_ctz(n)
#define bsf64(n)	__builtin_ctzll(n)

#elif defined(_MSC_VER)
/* #  include "compiler_msc.h" */


#include <stdint.h>
#include <stdlib.h> 

#define LIBEXPORT	__declspec(dllexport)


typedef int bool;
#define true 1
#define false 0
#define __bool_true_false_are_defined 1


#ifdef _WIN64
typedef long long ssize_t;
#else
typedef int ssize_t;
#endif


#define CPU_IS_LITTLE_ENDIAN()		1
#define UNALIGNED_ACCESS_IS_FAST	1


#define restrict


#define inline		__inline
#define forceinline	__forceinline


#define bswap16	_byteswap_ushort
#define bswap32	_byteswap_ulong
#define bswap64	_byteswap_uint64



static forceinline unsigned
bsr32(uint32_t n)
{
	_BitScanReverse(&n, n);
	return n;
}
#define bsr32 bsr32

static forceinline unsigned
bsf32(uint32_t n)
{
	_BitScanForward(&n, n);
	return n;
}
#define bsf32 bsf32

#ifdef _M_X64 

static forceinline unsigned
bsr64(uint64_t n)
{
	_BitScanReverse64(&n, n);
	return n;
}
#define bsr64 bsr64

static forceinline unsigned
bsf64(uint64_t n)
{
	_BitScanForward64(&n, n);
	return n;
}
#define bsf64 bsf64

#endif 

#else
#  pragma message("Unrecognized compiler.  Please add a header file for your compiler.  Compilation will proceed, but performance may suffer!")
#endif





#include <stddef.h> 

#ifndef __bool_true_false_are_defined
#  include <stdbool.h> 
#endif


#include <stdint.h>
typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
typedef int8_t s8;
typedef int16_t s16;
typedef int32_t s32;
typedef int64_t s64;


typedef size_t machine_word_t;


#define WORDBYTES	((int)sizeof(machine_word_t))


#define WORDBITS	(8 * WORDBYTES)






#ifndef LIBEXPORT
#  define LIBEXPORT
#endif


#ifndef inline
#  define inline
#endif


#ifndef forceinline
#  define forceinline inline
#endif


#ifndef restrict
#  define restrict
#endif


#ifndef likely
#  define likely(expr)		(expr)
#endif


#ifndef unlikely
#  define unlikely(expr)	(expr)
#endif


#ifndef prefetchr
#  define prefetchr(addr)
#endif


#ifndef prefetchw
#  define prefetchw(addr)
#endif


#ifndef COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE
#  define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE 0
#endif


#ifndef COMPILER_SUPPORTS_BMI2_TARGET
#  define COMPILER_SUPPORTS_BMI2_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX_TARGET
#  define COMPILER_SUPPORTS_AVX_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET
#  define COMPILER_SUPPORTS_AVX512BW_TARGET 0
#endif


#ifndef COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 0
#endif


#ifndef _aligned_attribute
#endif





#define ARRAY_LEN(A)		(sizeof(A) / sizeof((A)[0]))
#define MIN(a, b)		((a) <= (b) ? (a) : (b))
#define MAX(a, b)		((a) >= (b) ? (a) : (b))
#define DIV_ROUND_UP(n, d)	(((n) + (d) - 1) / (d))
#define STATIC_ASSERT(expr)	((void)sizeof(char[1 - 2 * !(expr)]))
#define ALIGN(n, a)		(((n) + (a) - 1) & ~((a) - 1))






#ifndef CPU_IS_LITTLE_ENDIAN
static forceinline int CPU_IS_LITTLE_ENDIAN(void)
{
	union {
		unsigned int v;
		unsigned char b;
	} u;
	u.v = 1;
	return u.b;
}
#endif


#ifndef bswap16
static forceinline u16 bswap16(u16 n)
{
	return (n << 8) | (n >> 8);
}
#endif


#ifndef bswap32
static forceinline u32 bswap32(u32 n)
{
	return ((n & 0x000000FF) << 24) |
	       ((n & 0x0000FF00) << 8) |
	       ((n & 0x00FF0000) >> 8) |
	       ((n & 0xFF000000) >> 24);
}
#endif


#ifndef bswap64
static forceinline u64 bswap64(u64 n)
{
	return ((n & 0x00000000000000FF) << 56) |
	       ((n & 0x000000000000FF00) << 40) |
	       ((n & 0x0000000000FF0000) << 24) |
	       ((n & 0x00000000FF000000) << 8) |
	       ((n & 0x000000FF00000000) >> 8) |
	       ((n & 0x0000FF0000000000) >> 24) |
	       ((n & 0x00FF000000000000) >> 40) |
	       ((n & 0xFF00000000000000) >> 56);
}
#endif

#define le16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap16(n))
#define le32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap32(n))
#define le64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap64(n))
#define be16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap16(n) : (n))
#define be32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap32(n) : (n))
#define be64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap64(n) : (n))






#ifndef UNALIGNED_ACCESS_IS_FAST
#  define UNALIGNED_ACCESS_IS_FAST 0
#endif







#ifndef bsr32
static forceinline unsigned
bsr32(u32 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

#ifndef bsr64
static forceinline unsigned
bsr64(u64 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

static forceinline unsigned
bsrw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsr32(n);
	else
		return bsr64(n);
}



#ifndef bsf32
static forceinline unsigned
bsf32(u32 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

#ifndef bsf64
static forceinline unsigned
bsf64(u64 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

static forceinline unsigned
bsfw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsf32(n);
	else
		return bsf64(n);
}

#endif 



#define SYM_FIXUP(sym)			_libdeflate_##sym
#define deflate_get_compression_level	SYM_FIXUP(deflate_get_compression_level)
#define _cpu_features			SYM_FIXUP(_cpu_features)
#define setup_cpu_features		SYM_FIXUP(setup_cpu_features)

void *libdeflate_malloc(size_t size);
void libdeflate_free(void *ptr);

void *libdeflate_aligned_malloc(size_t alignment, size_t size);
void libdeflate_aligned_free(void *ptr);

#ifdef FREESTANDING

void *memset(void *s, int c, size_t n);
#define memset(s, c, n)		__builtin_memset((s), (c), (n))

void *memcpy(void *dest, const void *src, size_t n);
#define memcpy(dest, src, n)	__builtin_memcpy((dest), (src), (n))

void *memmove(void *dest, const void *src, size_t n);
#define memmove(dest, src, n)	__builtin_memmove((dest), (src), (n))

int memcmp(const void *s1, const void *s2, size_t n);
#define memcmp(s1, s2, n)	__builtin_memcmp((s1), (s2), (n))
#else
#include <string.h>
#endif

#endif 


#if (defined(__i386__) || defined(__x86_64__)) && \
	COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE
#  define X86_CPU_FEATURES_ENABLED 1
#else
#  define X86_CPU_FEATURES_ENABLED 0
#endif

#if X86_CPU_FEATURES_ENABLED

#define X86_CPU_FEATURE_SSE2		0x00000001
#define X86_CPU_FEATURE_PCLMUL		0x00000002
#define X86_CPU_FEATURE_AVX		0x00000004
#define X86_CPU_FEATURE_AVX2		0x00000008
#define X86_CPU_FEATURE_BMI2		0x00000010
#define X86_CPU_FEATURE_AVX512BW	0x00000020

#define X86_CPU_FEATURES_KNOWN		0x80000000

extern volatile u32 _cpu_features;

void setup_cpu_features(void);

static inline u32 get_cpu_features(void)
{
	if (_cpu_features == 0)
		setup_cpu_features();
	return _cpu_features;
}

#endif 

#endif 



#undef DISPATCH_PCLMUL_AVX
#if !defined(DEFAULT_IMPL) && !defined(__AVX__) &&	\
	X86_CPU_FEATURES_ENABLED && COMPILER_SUPPORTS_AVX_TARGET &&	\
	(defined(__PCLMUL__) || COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS)
#  define FUNCNAME		crc32_pclmul_avx
#  define FUNCNAME_ALIGNED	crc32_pclmul_avx_aligned
#  define ATTRIBUTES		__attribute__((target("pclmul,avx")))
#  define DISPATCH		1
#  define DISPATCH_PCLMUL_AVX	1
/* #include "x86-crc32_pclmul_template.h" */


#include <wmmintrin.h>


static u32 ATTRIBUTES
FUNCNAME_ALIGNED(u32 remainder, const __m128i *p, size_t nr_segs)
{
	
	const __v2di multipliers_4 = (__v2di){ 0x8F352D95, 0x1D9513D7 };
	const __v2di multipliers_2 = (__v2di){ 0xF1DA05AA, 0x81256527 };
	const __v2di multipliers_1 = (__v2di){ 0xAE689191, 0xCCAA009E };
	const __v2di final_multiplier = (__v2di){ 0xB8BC6765 };
	const __m128i mask32 = (__m128i)(__v4si){ 0xFFFFFFFF };
	const __v2di barrett_reduction_constants =
			(__v2di){ 0x00000001F7011641, 0x00000001DB710641 };

	const __m128i * const end = p + nr_segs;
	const __m128i * const end512 = p + (nr_segs & ~3);
	__m128i x0, x1, x2, x3;

	
	x0 = *p++;
	x0 ^= (__m128i)(__v4si){ remainder };

	if (p > end512) 
		goto _128_bits_at_a_time;
	x1 = *p++;
	x2 = *p++;
	x3 = *p++;

	
	for (; p != end512; p += 4) {
		__m128i y0, y1, y2, y3;

		y0 = p[0];
		y1 = p[1];
		y2 = p[2];
		y3 = p[3];

		
		y0 ^= _mm_clmulepi64_si128(x0, multipliers_4, 0x00);
		y1 ^= _mm_clmulepi64_si128(x1, multipliers_4, 0x00);
		y2 ^= _mm_clmulepi64_si128(x2, multipliers_4, 0x00);
		y3 ^= _mm_clmulepi64_si128(x3, multipliers_4, 0x00);
		y0 ^= _mm_clmulepi64_si128(x0, multipliers_4, 0x11);
		y1 ^= _mm_clmulepi64_si128(x1, multipliers_4, 0x11);
		y2 ^= _mm_clmulepi64_si128(x2, multipliers_4, 0x11);
		y3 ^= _mm_clmulepi64_si128(x3, multipliers_4, 0x11);

		x0 = y0;
		x1 = y1;
		x2 = y2;
		x3 = y3;
	}

	
	x2 ^= _mm_clmulepi64_si128(x0, multipliers_2, 0x00);
	x3 ^= _mm_clmulepi64_si128(x1, multipliers_2, 0x00);
	x2 ^= _mm_clmulepi64_si128(x0, multipliers_2, 0x11);
	x3 ^= _mm_clmulepi64_si128(x1, multipliers_2, 0x11);
	x3 ^= _mm_clmulepi64_si128(x2, multipliers_1, 0x00);
	x3 ^= _mm_clmulepi64_si128(x2, multipliers_1, 0x11);
	x0 = x3;

_128_bits_at_a_time:
	while (p != end) {
		
		x1 = *p++;
		x1 ^= _mm_clmulepi64_si128(x0, multipliers_1, 0x00);
		x1 ^= _mm_clmulepi64_si128(x0, multipliers_1, 0x11);
		x0 = x1;
	}

	

	
	x0 = _mm_srli_si128(x0, 8) ^
	     _mm_clmulepi64_si128(x0, multipliers_1, 0x10);

	
	x0 = _mm_srli_si128(x0, 4) ^
	     _mm_clmulepi64_si128(x0 & mask32, final_multiplier, 0x00);

        
	x1 = x0;
	x0 = _mm_clmulepi64_si128(x0 & mask32, barrett_reduction_constants, 0x00);
	x0 = _mm_clmulepi64_si128(x0 & mask32, barrett_reduction_constants, 0x10);
	return _mm_cvtsi128_si32(_mm_srli_si128(x0 ^ x1, 4));
}

#define IMPL_ALIGNMENT		16
#define IMPL_SEGMENT_SIZE	16
/* #include "crc32_vec_template.h" */


#define CRC32_SLICE1	1
static u32 crc32_slice1(u32, const u8 *, size_t);


static u32 ATTRIBUTES
FUNCNAME(u32 remainder, const u8 *p, size_t size)
{
	if ((uintptr_t)p % IMPL_ALIGNMENT) {
		size_t n = MIN(size, -(uintptr_t)p % IMPL_ALIGNMENT);

		remainder = crc32_slice1(remainder, p, n);
		p += n;
		size -= n;
	}
	if (size >= IMPL_SEGMENT_SIZE) {
		remainder = FUNCNAME_ALIGNED(remainder, (const void *)p,
					     size / IMPL_SEGMENT_SIZE);
		p += size - (size % IMPL_SEGMENT_SIZE);
		size %= IMPL_SEGMENT_SIZE;
	}
	return crc32_slice1(remainder, p, size);
}

#undef FUNCNAME
#undef FUNCNAME_ALIGNED
#undef ATTRIBUTES
#undef IMPL_ALIGNMENT
#undef IMPL_SEGMENT_SIZE


#endif


#undef DISPATCH_PCLMUL
#if !defined(DEFAULT_IMPL) &&	\
	(defined(__PCLMUL__) || (X86_CPU_FEATURES_ENABLED &&	\
				 COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS))
#  define FUNCNAME		crc32_pclmul
#  define FUNCNAME_ALIGNED	crc32_pclmul_aligned
#  ifdef __PCLMUL__
#    define ATTRIBUTES
#    define DEFAULT_IMPL	crc32_pclmul
#  else
#    define ATTRIBUTES		__attribute__((target("pclmul")))
#    define DISPATCH		1
#    define DISPATCH_PCLMUL	1
#  endif
/* #include "x86-crc32_pclmul_template.h" */


#include <wmmintrin.h>


static u32 ATTRIBUTES
FUNCNAME_ALIGNED(u32 remainder, const __m128i *p, size_t nr_segs)
{
	
	const __v2di multipliers_4 = (__v2di){ 0x8F352D95, 0x1D9513D7 };
	const __v2di multipliers_2 = (__v2di){ 0xF1DA05AA, 0x81256527 };
	const __v2di multipliers_1 = (__v2di){ 0xAE689191, 0xCCAA009E };
	const __v2di final_multiplier = (__v2di){ 0xB8BC6765 };
	const __m128i mask32 = (__m128i)(__v4si){ 0xFFFFFFFF };
	const __v2di barrett_reduction_constants =
			(__v2di){ 0x00000001F7011641, 0x00000001DB710641 };

	const __m128i * const end = p + nr_segs;
	const __m128i * const end512 = p + (nr_segs & ~3);
	__m128i x0, x1, x2, x3;

	
	x0 = *p++;
	x0 ^= (__m128i)(__v4si){ remainder };

	if (p > end512) 
		goto _128_bits_at_a_time;
	x1 = *p++;
	x2 = *p++;
	x3 = *p++;

	
	for (; p != end512; p += 4) {
		__m128i y0, y1, y2, y3;

		y0 = p[0];
		y1 = p[1];
		y2 = p[2];
		y3 = p[3];

		
		y0 ^= _mm_clmulepi64_si128(x0, multipliers_4, 0x00);
		y1 ^= _mm_clmulepi64_si128(x1, multipliers_4, 0x00);
		y2 ^= _mm_clmulepi64_si128(x2, multipliers_4, 0x00);
		y3 ^= _mm_clmulepi64_si128(x3, multipliers_4, 0x00);
		y0 ^= _mm_clmulepi64_si128(x0, multipliers_4, 0x11);
		y1 ^= _mm_clmulepi64_si128(x1, multipliers_4, 0x11);
		y2 ^= _mm_clmulepi64_si128(x2, multipliers_4, 0x11);
		y3 ^= _mm_clmulepi64_si128(x3, multipliers_4, 0x11);

		x0 = y0;
		x1 = y1;
		x2 = y2;
		x3 = y3;
	}

	
	x2 ^= _mm_clmulepi64_si128(x0, multipliers_2, 0x00);
	x3 ^= _mm_clmulepi64_si128(x1, multipliers_2, 0x00);
	x2 ^= _mm_clmulepi64_si128(x0, multipliers_2, 0x11);
	x3 ^= _mm_clmulepi64_si128(x1, multipliers_2, 0x11);
	x3 ^= _mm_clmulepi64_si128(x2, multipliers_1, 0x00);
	x3 ^= _mm_clmulepi64_si128(x2, multipliers_1, 0x11);
	x0 = x3;

_128_bits_at_a_time:
	while (p != end) {
		
		x1 = *p++;
		x1 ^= _mm_clmulepi64_si128(x0, multipliers_1, 0x00);
		x1 ^= _mm_clmulepi64_si128(x0, multipliers_1, 0x11);
		x0 = x1;
	}

	

	
	x0 = _mm_srli_si128(x0, 8) ^
	     _mm_clmulepi64_si128(x0, multipliers_1, 0x10);

	
	x0 = _mm_srli_si128(x0, 4) ^
	     _mm_clmulepi64_si128(x0 & mask32, final_multiplier, 0x00);

        
	x1 = x0;
	x0 = _mm_clmulepi64_si128(x0 & mask32, barrett_reduction_constants, 0x00);
	x0 = _mm_clmulepi64_si128(x0 & mask32, barrett_reduction_constants, 0x10);
	return _mm_cvtsi128_si32(_mm_srli_si128(x0 ^ x1, 4));
}

#define IMPL_ALIGNMENT		16
#define IMPL_SEGMENT_SIZE	16
/* #include "crc32_vec_template.h" */


#define CRC32_SLICE1	1
static u32 crc32_slice1(u32, const u8 *, size_t);


static u32 ATTRIBUTES
FUNCNAME(u32 remainder, const u8 *p, size_t size)
{
	if ((uintptr_t)p % IMPL_ALIGNMENT) {
		size_t n = MIN(size, -(uintptr_t)p % IMPL_ALIGNMENT);

		remainder = crc32_slice1(remainder, p, n);
		p += n;
		size -= n;
	}
	if (size >= IMPL_SEGMENT_SIZE) {
		remainder = FUNCNAME_ALIGNED(remainder, (const void *)p,
					     size / IMPL_SEGMENT_SIZE);
		p += size - (size % IMPL_SEGMENT_SIZE);
		size %= IMPL_SEGMENT_SIZE;
	}
	return crc32_slice1(remainder, p, size);
}

#undef FUNCNAME
#undef FUNCNAME_ALIGNED
#undef ATTRIBUTES
#undef IMPL_ALIGNMENT
#undef IMPL_SEGMENT_SIZE


#endif

#ifdef DISPATCH
static inline crc32_func_t
arch_select_crc32_func(void)
{
	u32 features = get_cpu_features();

#ifdef DISPATCH_PCLMUL_AVX
	if ((features & X86_CPU_FEATURE_PCLMUL) &&
	    (features & X86_CPU_FEATURE_AVX))
		return crc32_pclmul_avx;
#endif
#ifdef DISPATCH_PCLMUL
	if (features & X86_CPU_FEATURE_PCLMUL)
		return crc32_pclmul;
#endif
	return NULL;
}
#endif 

#endif



#ifndef DEFAULT_IMPL
#  define CRC32_SLICE8	1
#  define DEFAULT_IMPL	crc32_slice8
#endif

#if defined(CRC32_SLICE1) || defined(CRC32_SLICE4) || defined(CRC32_SLICE8)
/* #include "crc32_table.h" */


#include <stdint.h>

static const uint32_t crc32_table[] = {
	0x00000000, 0x77073096, 0xee0e612c, 0x990951ba,
	0x076dc419, 0x706af48f, 0xe963a535, 0x9e6495a3,
	0x0edb8832, 0x79dcb8a4, 0xe0d5e91e, 0x97d2d988,
	0x09b64c2b, 0x7eb17cbd, 0xe7b82d07, 0x90bf1d91,
	0x1db71064, 0x6ab020f2, 0xf3b97148, 0x84be41de,
	0x1adad47d, 0x6ddde4eb, 0xf4d4b551, 0x83d385c7,
	0x136c9856, 0x646ba8c0, 0xfd62f97a, 0x8a65c9ec,
	0x14015c4f, 0x63066cd9, 0xfa0f3d63, 0x8d080df5,
	0x3b6e20c8, 0x4c69105e, 0xd56041e4, 0xa2677172,
	0x3c03e4d1, 0x4b04d447, 0xd20d85fd, 0xa50ab56b,
	0x35b5a8fa, 0x42b2986c, 0xdbbbc9d6, 0xacbcf940,
	0x32d86ce3, 0x45df5c75, 0xdcd60dcf, 0xabd13d59,
	0x26d930ac, 0x51de003a, 0xc8d75180, 0xbfd06116,
	0x21b4f4b5, 0x56b3c423, 0xcfba9599, 0xb8bda50f,
	0x2802b89e, 0x5f058808, 0xc60cd9b2, 0xb10be924,
	0x2f6f7c87, 0x58684c11, 0xc1611dab, 0xb6662d3d,
	0x76dc4190, 0x01db7106, 0x98d220bc, 0xefd5102a,
	0x71b18589, 0x06b6b51f, 0x9fbfe4a5, 0xe8b8d433,
	0x7807c9a2, 0x0f00f934, 0x9609a88e, 0xe10e9818,
	0x7f6a0dbb, 0x086d3d2d, 0x91646c97, 0xe6635c01,
	0x6b6b51f4, 0x1c6c6162, 0x856530d8, 0xf262004e,
	0x6c0695ed, 0x1b01a57b, 0x8208f4c1, 0xf50fc457,
	0x65b0d9c6, 0x12b7e950, 0x8bbeb8ea, 0xfcb9887c,
	0x62dd1ddf, 0x15da2d49, 0x8cd37cf3, 0xfbd44c65,
	0x4db26158, 0x3ab551ce, 0xa3bc0074, 0xd4bb30e2,
	0x4adfa541, 0x3dd895d7, 0xa4d1c46d, 0xd3d6f4fb,
	0x4369e96a, 0x346ed9fc, 0xad678846, 0xda60b8d0,
	0x44042d73, 0x33031de5, 0xaa0a4c5f, 0xdd0d7cc9,
	0x5005713c, 0x270241aa, 0xbe0b1010, 0xc90c2086,
	0x5768b525, 0x206f85b3, 0xb966d409, 0xce61e49f,
	0x5edef90e, 0x29d9c998, 0xb0d09822, 0xc7d7a8b4,
	0x59b33d17, 0x2eb40d81, 0xb7bd5c3b, 0xc0ba6cad,
	0xedb88320, 0x9abfb3b6, 0x03b6e20c, 0x74b1d29a,
	0xead54739, 0x9dd277af, 0x04db2615, 0x73dc1683,
	0xe3630b12, 0x94643b84, 0x0d6d6a3e, 0x7a6a5aa8,
	0xe40ecf0b, 0x9309ff9d, 0x0a00ae27, 0x7d079eb1,
	0xf00f9344, 0x8708a3d2, 0x1e01f268, 0x6906c2fe,
	0xf762575d, 0x806567cb, 0x196c3671, 0x6e6b06e7,
	0xfed41b76, 0x89d32be0, 0x10da7a5a, 0x67dd4acc,
	0xf9b9df6f, 0x8ebeeff9, 0x17b7be43, 0x60b08ed5,
	0xd6d6a3e8, 0xa1d1937e, 0x38d8c2c4, 0x4fdff252,
	0xd1bb67f1, 0xa6bc5767, 0x3fb506dd, 0x48b2364b,
	0xd80d2bda, 0xaf0a1b4c, 0x36034af6, 0x41047a60,
	0xdf60efc3, 0xa867df55, 0x316e8eef, 0x4669be79,
	0xcb61b38c, 0xbc66831a, 0x256fd2a0, 0x5268e236,
	0xcc0c7795, 0xbb0b4703, 0x220216b9, 0x5505262f,
	0xc5ba3bbe, 0xb2bd0b28, 0x2bb45a92, 0x5cb36a04,
	0xc2d7ffa7, 0xb5d0cf31, 0x2cd99e8b, 0x5bdeae1d,
	0x9b64c2b0, 0xec63f226, 0x756aa39c, 0x026d930a,
	0x9c0906a9, 0xeb0e363f, 0x72076785, 0x05005713,
	0x95bf4a82, 0xe2b87a14, 0x7bb12bae, 0x0cb61b38,
	0x92d28e9b, 0xe5d5be0d, 0x7cdcefb7, 0x0bdbdf21,
	0x86d3d2d4, 0xf1d4e242, 0x68ddb3f8, 0x1fda836e,
	0x81be16cd, 0xf6b9265b, 0x6fb077e1, 0x18b74777,
	0x88085ae6, 0xff0f6a70, 0x66063bca, 0x11010b5c,
	0x8f659eff, 0xf862ae69, 0x616bffd3, 0x166ccf45,
	0xa00ae278, 0xd70dd2ee, 0x4e048354, 0x3903b3c2,
	0xa7672661, 0xd06016f7, 0x4969474d, 0x3e6e77db,
	0xaed16a4a, 0xd9d65adc, 0x40df0b66, 0x37d83bf0,
	0xa9bcae53, 0xdebb9ec5, 0x47b2cf7f, 0x30b5ffe9,
	0xbdbdf21c, 0xcabac28a, 0x53b39330, 0x24b4a3a6,
	0xbad03605, 0xcdd70693, 0x54de5729, 0x23d967bf,
	0xb3667a2e, 0xc4614ab8, 0x5d681b02, 0x2a6f2b94,
	0xb40bbe37, 0xc30c8ea1, 0x5a05df1b, 0x2d02ef8d,
#if defined(CRC32_SLICE4) || defined(CRC32_SLICE8)
	0x00000000, 0x191b3141, 0x32366282, 0x2b2d53c3,
	0x646cc504, 0x7d77f445, 0x565aa786, 0x4f4196c7,
	0xc8d98a08, 0xd1c2bb49, 0xfaefe88a, 0xe3f4d9cb,
	0xacb54f0c, 0xb5ae7e4d, 0x9e832d8e, 0x87981ccf,
	0x4ac21251, 0x53d92310, 0x78f470d3, 0x61ef4192,
	0x2eaed755, 0x37b5e614, 0x1c98b5d7, 0x05838496,
	0x821b9859, 0x9b00a918, 0xb02dfadb, 0xa936cb9a,
	0xe6775d5d, 0xff6c6c1c, 0xd4413fdf, 0xcd5a0e9e,
	0x958424a2, 0x8c9f15e3, 0xa7b24620, 0xbea97761,
	0xf1e8e1a6, 0xe8f3d0e7, 0xc3de8324, 0xdac5b265,
	0x5d5daeaa, 0x44469feb, 0x6f6bcc28, 0x7670fd69,
	0x39316bae, 0x202a5aef, 0x0b07092c, 0x121c386d,
	0xdf4636f3, 0xc65d07b2, 0xed705471, 0xf46b6530,
	0xbb2af3f7, 0xa231c2b6, 0x891c9175, 0x9007a034,
	0x179fbcfb, 0x0e848dba, 0x25a9de79, 0x3cb2ef38,
	0x73f379ff, 0x6ae848be, 0x41c51b7d, 0x58de2a3c,
	0xf0794f05, 0xe9627e44, 0xc24f2d87, 0xdb541cc6,
	0x94158a01, 0x8d0ebb40, 0xa623e883, 0xbf38d9c2,
	0x38a0c50d, 0x21bbf44c, 0x0a96a78f, 0x138d96ce,
	0x5ccc0009, 0x45d73148, 0x6efa628b, 0x77e153ca,
	0xbabb5d54, 0xa3a06c15, 0x888d3fd6, 0x91960e97,
	0xded79850, 0xc7cca911, 0xece1fad2, 0xf5facb93,
	0x7262d75c, 0x6b79e61d, 0x4054b5de, 0x594f849f,
	0x160e1258, 0x0f152319, 0x243870da, 0x3d23419b,
	0x65fd6ba7, 0x7ce65ae6, 0x57cb0925, 0x4ed03864,
	0x0191aea3, 0x188a9fe2, 0x33a7cc21, 0x2abcfd60,
	0xad24e1af, 0xb43fd0ee, 0x9f12832d, 0x8609b26c,
	0xc94824ab, 0xd05315ea, 0xfb7e4629, 0xe2657768,
	0x2f3f79f6, 0x362448b7, 0x1d091b74, 0x04122a35,
	0x4b53bcf2, 0x52488db3, 0x7965de70, 0x607eef31,
	0xe7e6f3fe, 0xfefdc2bf, 0xd5d0917c, 0xcccba03d,
	0x838a36fa, 0x9a9107bb, 0xb1bc5478, 0xa8a76539,
	0x3b83984b, 0x2298a90a, 0x09b5fac9, 0x10aecb88,
	0x5fef5d4f, 0x46f46c0e, 0x6dd93fcd, 0x74c20e8c,
	0xf35a1243, 0xea412302, 0xc16c70c1, 0xd8774180,
	0x9736d747, 0x8e2de606, 0xa500b5c5, 0xbc1b8484,
	0x71418a1a, 0x685abb5b, 0x4377e898, 0x5a6cd9d9,
	0x152d4f1e, 0x0c367e5f, 0x271b2d9c, 0x3e001cdd,
	0xb9980012, 0xa0833153, 0x8bae6290, 0x92b553d1,
	0xddf4c516, 0xc4eff457, 0xefc2a794, 0xf6d996d5,
	0xae07bce9, 0xb71c8da8, 0x9c31de6b, 0x852aef2a,
	0xca6b79ed, 0xd37048ac, 0xf85d1b6f, 0xe1462a2e,
	0x66de36e1, 0x7fc507a0, 0x54e85463, 0x4df36522,
	0x02b2f3e5, 0x1ba9c2a4, 0x30849167, 0x299fa026,
	0xe4c5aeb8, 0xfdde9ff9, 0xd6f3cc3a, 0xcfe8fd7b,
	0x80a96bbc, 0x99b25afd, 0xb29f093e, 0xab84387f,
	0x2c1c24b0, 0x350715f1, 0x1e2a4632, 0x07317773,
	0x4870e1b4, 0x516bd0f5, 0x7a468336, 0x635db277,
	0xcbfad74e, 0xd2e1e60f, 0xf9ccb5cc, 0xe0d7848d,
	0xaf96124a, 0xb68d230b, 0x9da070c8, 0x84bb4189,
	0x03235d46, 0x1a386c07, 0x31153fc4, 0x280e0e85,
	0x674f9842, 0x7e54a903, 0x5579fac0, 0x4c62cb81,
	0x8138c51f, 0x9823f45e, 0xb30ea79d, 0xaa1596dc,
	0xe554001b, 0xfc4f315a, 0xd7626299, 0xce7953d8,
	0x49e14f17, 0x50fa7e56, 0x7bd72d95, 0x62cc1cd4,
	0x2d8d8a13, 0x3496bb52, 0x1fbbe891, 0x06a0d9d0,
	0x5e7ef3ec, 0x4765c2ad, 0x6c48916e, 0x7553a02f,
	0x3a1236e8, 0x230907a9, 0x0824546a, 0x113f652b,
	0x96a779e4, 0x8fbc48a5, 0xa4911b66, 0xbd8a2a27,
	0xf2cbbce0, 0xebd08da1, 0xc0fdde62, 0xd9e6ef23,
	0x14bce1bd, 0x0da7d0fc, 0x268a833f, 0x3f91b27e,
	0x70d024b9, 0x69cb15f8, 0x42e6463b, 0x5bfd777a,
	0xdc656bb5, 0xc57e5af4, 0xee530937, 0xf7483876,
	0xb809aeb1, 0xa1129ff0, 0x8a3fcc33, 0x9324fd72,
	0x00000000, 0x01c26a37, 0x0384d46e, 0x0246be59,
	0x0709a8dc, 0x06cbc2eb, 0x048d7cb2, 0x054f1685,
	0x0e1351b8, 0x0fd13b8f, 0x0d9785d6, 0x0c55efe1,
	0x091af964, 0x08d89353, 0x0a9e2d0a, 0x0b5c473d,
	0x1c26a370, 0x1de4c947, 0x1fa2771e, 0x1e601d29,
	0x1b2f0bac, 0x1aed619b, 0x18abdfc2, 0x1969b5f5,
	0x1235f2c8, 0x13f798ff, 0x11b126a6, 0x10734c91,
	0x153c5a14, 0x14fe3023, 0x16b88e7a, 0x177ae44d,
	0x384d46e0, 0x398f2cd7, 0x3bc9928e, 0x3a0bf8b9,
	0x3f44ee3c, 0x3e86840b, 0x3cc03a52, 0x3d025065,
	0x365e1758, 0x379c7d6f, 0x35dac336, 0x3418a901,
	0x3157bf84, 0x3095d5b3, 0x32d36bea, 0x331101dd,
	0x246be590, 0x25a98fa7, 0x27ef31fe, 0x262d5bc9,
	0x23624d4c, 0x22a0277b, 0x20e69922, 0x2124f315,
	0x2a78b428, 0x2bbade1f, 0x29fc6046, 0x283e0a71,
	0x2d711cf4, 0x2cb376c3, 0x2ef5c89a, 0x2f37a2ad,
	0x709a8dc0, 0x7158e7f7, 0x731e59ae, 0x72dc3399,
	0x7793251c, 0x76514f2b, 0x7417f172, 0x75d59b45,
	0x7e89dc78, 0x7f4bb64f, 0x7d0d0816, 0x7ccf6221,
	0x798074a4, 0x78421e93, 0x7a04a0ca, 0x7bc6cafd,
	0x6cbc2eb0, 0x6d7e4487, 0x6f38fade, 0x6efa90e9,
	0x6bb5866c, 0x6a77ec5b, 0x68315202, 0x69f33835,
	0x62af7f08, 0x636d153f, 0x612bab66, 0x60e9c151,
	0x65a6d7d4, 0x6464bde3, 0x662203ba, 0x67e0698d,
	0x48d7cb20, 0x4915a117, 0x4b531f4e, 0x4a917579,
	0x4fde63fc, 0x4e1c09cb, 0x4c5ab792, 0x4d98dda5,
	0x46c49a98, 0x4706f0af, 0x45404ef6, 0x448224c1,
	0x41cd3244, 0x400f5873, 0x4249e62a, 0x438b8c1d,
	0x54f16850, 0x55330267, 0x5775bc3e, 0x56b7d609,
	0x53f8c08c, 0x523aaabb, 0x507c14e2, 0x51be7ed5,
	0x5ae239e8, 0x5b2053df, 0x5966ed86, 0x58a487b1,
	0x5deb9134, 0x5c29fb03, 0x5e6f455a, 0x5fad2f6d,
	0xe1351b80, 0xe0f771b7, 0xe2b1cfee, 0xe373a5d9,
	0xe63cb35c, 0xe7fed96b, 0xe5b86732, 0xe47a0d05,
	0xef264a38, 0xeee4200f, 0xeca29e56, 0xed60f461,
	0xe82fe2e4, 0xe9ed88d3, 0xebab368a, 0xea695cbd,
	0xfd13b8f0, 0xfcd1d2c7, 0xfe976c9e, 0xff5506a9,
	0xfa1a102c, 0xfbd87a1b, 0xf99ec442, 0xf85cae75,
	0xf300e948, 0xf2c2837f, 0xf0843d26, 0xf1465711,
	0xf4094194, 0xf5cb2ba3, 0xf78d95fa, 0xf64fffcd,
	0xd9785d60, 0xd8ba3757, 0xdafc890e, 0xdb3ee339,
	0xde71f5bc, 0xdfb39f8b, 0xddf521d2, 0xdc374be5,
	0xd76b0cd8, 0xd6a966ef, 0xd4efd8b6, 0xd52db281,
	0xd062a404, 0xd1a0ce33, 0xd3e6706a, 0xd2241a5d,
	0xc55efe10, 0xc49c9427, 0xc6da2a7e, 0xc7184049,
	0xc25756cc, 0xc3953cfb, 0xc1d382a2, 0xc011e895,
	0xcb4dafa8, 0xca8fc59f, 0xc8c97bc6, 0xc90b11f1,
	0xcc440774, 0xcd866d43, 0xcfc0d31a, 0xce02b92d,
	0x91af9640, 0x906dfc77, 0x922b422e, 0x93e92819,
	0x96a63e9c, 0x976454ab, 0x9522eaf2, 0x94e080c5,
	0x9fbcc7f8, 0x9e7eadcf, 0x9c381396, 0x9dfa79a1,
	0x98b56f24, 0x99770513, 0x9b31bb4a, 0x9af3d17d,
	0x8d893530, 0x8c4b5f07, 0x8e0de15e, 0x8fcf8b69,
	0x8a809dec, 0x8b42f7db, 0x89044982, 0x88c623b5,
	0x839a6488, 0x82580ebf, 0x801eb0e6, 0x81dcdad1,
	0x8493cc54, 0x8551a663, 0x8717183a, 0x86d5720d,
	0xa9e2d0a0, 0xa820ba97, 0xaa6604ce, 0xaba46ef9,
	0xaeeb787c, 0xaf29124b, 0xad6fac12, 0xacadc625,
	0xa7f18118, 0xa633eb2f, 0xa4755576, 0xa5b73f41,
	0xa0f829c4, 0xa13a43f3, 0xa37cfdaa, 0xa2be979d,
	0xb5c473d0, 0xb40619e7, 0xb640a7be, 0xb782cd89,
	0xb2cddb0c, 0xb30fb13b, 0xb1490f62, 0xb08b6555,
	0xbbd72268, 0xba15485f, 0xb853f606, 0xb9919c31,
	0xbcde8ab4, 0xbd1ce083, 0xbf5a5eda, 0xbe9834ed,
	0x00000000, 0xb8bc6765, 0xaa09c88b, 0x12b5afee,
	0x8f629757, 0x37def032, 0x256b5fdc, 0x9dd738b9,
	0xc5b428ef, 0x7d084f8a, 0x6fbde064, 0xd7018701,
	0x4ad6bfb8, 0xf26ad8dd, 0xe0df7733, 0x58631056,
	0x5019579f, 0xe8a530fa, 0xfa109f14, 0x42acf871,
	0xdf7bc0c8, 0x67c7a7ad, 0x75720843, 0xcdce6f26,
	0x95ad7f70, 0x2d111815, 0x3fa4b7fb, 0x8718d09e,
	0x1acfe827, 0xa2738f42, 0xb0c620ac, 0x087a47c9,
	0xa032af3e, 0x188ec85b, 0x0a3b67b5, 0xb28700d0,
	0x2f503869, 0x97ec5f0c, 0x8559f0e2, 0x3de59787,
	0x658687d1, 0xdd3ae0b4, 0xcf8f4f5a, 0x7733283f,
	0xeae41086, 0x525877e3, 0x40edd80d, 0xf851bf68,
	0xf02bf8a1, 0x48979fc4, 0x5a22302a, 0xe29e574f,
	0x7f496ff6, 0xc7f50893, 0xd540a77d, 0x6dfcc018,
	0x359fd04e, 0x8d23b72b, 0x9f9618c5, 0x272a7fa0,
	0xbafd4719, 0x0241207c, 0x10f48f92, 0xa848e8f7,
	0x9b14583d, 0x23a83f58, 0x311d90b6, 0x89a1f7d3,
	0x1476cf6a, 0xaccaa80f, 0xbe7f07e1, 0x06c36084,
	0x5ea070d2, 0xe61c17b7, 0xf4a9b859, 0x4c15df3c,
	0xd1c2e785, 0x697e80e0, 0x7bcb2f0e, 0xc377486b,
	0xcb0d0fa2, 0x73b168c7, 0x6104c729, 0xd9b8a04c,
	0x446f98f5, 0xfcd3ff90, 0xee66507e, 0x56da371b,
	0x0eb9274d, 0xb6054028, 0xa4b0efc6, 0x1c0c88a3,
	0x81dbb01a, 0x3967d77f, 0x2bd27891, 0x936e1ff4,
	0x3b26f703, 0x839a9066, 0x912f3f88, 0x299358ed,
	0xb4446054, 0x0cf80731, 0x1e4da8df, 0xa6f1cfba,
	0xfe92dfec, 0x462eb889, 0x549b1767, 0xec277002,
	0x71f048bb, 0xc94c2fde, 0xdbf98030, 0x6345e755,
	0x6b3fa09c, 0xd383c7f9, 0xc1366817, 0x798a0f72,
	0xe45d37cb, 0x5ce150ae, 0x4e54ff40, 0xf6e89825,
	0xae8b8873, 0x1637ef16, 0x048240f8, 0xbc3e279d,
	0x21e91f24, 0x99557841, 0x8be0d7af, 0x335cb0ca,
	0xed59b63b, 0x55e5d15e, 0x47507eb0, 0xffec19d5,
	0x623b216c, 0xda874609, 0xc832e9e7, 0x708e8e82,
	0x28ed9ed4, 0x9051f9b1, 0x82e4565f, 0x3a58313a,
	0xa78f0983, 0x1f336ee6, 0x0d86c108, 0xb53aa66d,
	0xbd40e1a4, 0x05fc86c1, 0x1749292f, 0xaff54e4a,
	0x322276f3, 0x8a9e1196, 0x982bbe78, 0x2097d91d,
	0x78f4c94b, 0xc048ae2e, 0xd2fd01c0, 0x6a4166a5,
	0xf7965e1c, 0x4f2a3979, 0x5d9f9697, 0xe523f1f2,
	0x4d6b1905, 0xf5d77e60, 0xe762d18e, 0x5fdeb6eb,
	0xc2098e52, 0x7ab5e937, 0x680046d9, 0xd0bc21bc,
	0x88df31ea, 0x3063568f, 0x22d6f961, 0x9a6a9e04,
	0x07bda6bd, 0xbf01c1d8, 0xadb46e36, 0x15080953,
	0x1d724e9a, 0xa5ce29ff, 0xb77b8611, 0x0fc7e174,
	0x9210d9cd, 0x2aacbea8, 0x38191146, 0x80a57623,
	0xd8c66675, 0x607a0110, 0x72cfaefe, 0xca73c99b,
	0x57a4f122, 0xef189647, 0xfdad39a9, 0x45115ecc,
	0x764dee06, 0xcef18963, 0xdc44268d, 0x64f841e8,
	0xf92f7951, 0x41931e34, 0x5326b1da, 0xeb9ad6bf,
	0xb3f9c6e9, 0x0b45a18c, 0x19f00e62, 0xa14c6907,
	0x3c9b51be, 0x842736db, 0x96929935, 0x2e2efe50,
	0x2654b999, 0x9ee8defc, 0x8c5d7112, 0x34e11677,
	0xa9362ece, 0x118a49ab, 0x033fe645, 0xbb838120,
	0xe3e09176, 0x5b5cf613, 0x49e959fd, 0xf1553e98,
	0x6c820621, 0xd43e6144, 0xc68bceaa, 0x7e37a9cf,
	0xd67f4138, 0x6ec3265d, 0x7c7689b3, 0xc4caeed6,
	0x591dd66f, 0xe1a1b10a, 0xf3141ee4, 0x4ba87981,
	0x13cb69d7, 0xab770eb2, 0xb9c2a15c, 0x017ec639,
	0x9ca9fe80, 0x241599e5, 0x36a0360b, 0x8e1c516e,
	0x866616a7, 0x3eda71c2, 0x2c6fde2c, 0x94d3b949,
	0x090481f0, 0xb1b8e695, 0xa30d497b, 0x1bb12e1e,
	0x43d23e48, 0xfb6e592d, 0xe9dbf6c3, 0x516791a6,
	0xccb0a91f, 0x740cce7a, 0x66b96194, 0xde0506f1,
#endif 
#if defined(CRC32_SLICE8)
	0x00000000, 0x3d6029b0, 0x7ac05360, 0x47a07ad0,
	0xf580a6c0, 0xc8e08f70, 0x8f40f5a0, 0xb220dc10,
	0x30704bc1, 0x0d106271, 0x4ab018a1, 0x77d03111,
	0xc5f0ed01, 0xf890c4b1, 0xbf30be61, 0x825097d1,
	0x60e09782, 0x5d80be32, 0x1a20c4e2, 0x2740ed52,
	0x95603142, 0xa80018f2, 0xefa06222, 0xd2c04b92,
	0x5090dc43, 0x6df0f5f3, 0x2a508f23, 0x1730a693,
	0xa5107a83, 0x98705333, 0xdfd029e3, 0xe2b00053,
	0xc1c12f04, 0xfca106b4, 0xbb017c64, 0x866155d4,
	0x344189c4, 0x0921a074, 0x4e81daa4, 0x73e1f314,
	0xf1b164c5, 0xccd14d75, 0x8b7137a5, 0xb6111e15,
	0x0431c205, 0x3951ebb5, 0x7ef19165, 0x4391b8d5,
	0xa121b886, 0x9c419136, 0xdbe1ebe6, 0xe681c256,
	0x54a11e46, 0x69c137f6, 0x2e614d26, 0x13016496,
	0x9151f347, 0xac31daf7, 0xeb91a027, 0xd6f18997,
	0x64d15587, 0x59b17c37, 0x1e1106e7, 0x23712f57,
	0x58f35849, 0x659371f9, 0x22330b29, 0x1f532299,
	0xad73fe89, 0x9013d739, 0xd7b3ade9, 0xead38459,
	0x68831388, 0x55e33a38, 0x124340e8, 0x2f236958,
	0x9d03b548, 0xa0639cf8, 0xe7c3e628, 0xdaa3cf98,
	0x3813cfcb, 0x0573e67b, 0x42d39cab, 0x7fb3b51b,
	0xcd93690b, 0xf0f340bb, 0xb7533a6b, 0x8a3313db,
	0x0863840a, 0x3503adba, 0x72a3d76a, 0x4fc3feda,
	0xfde322ca, 0xc0830b7a, 0x872371aa, 0xba43581a,
	0x9932774d, 0xa4525efd, 0xe3f2242d, 0xde920d9d,
	0x6cb2d18d, 0x51d2f83d, 0x167282ed, 0x2b12ab5d,
	0xa9423c8c, 0x9422153c, 0xd3826fec, 0xeee2465c,
	0x5cc29a4c, 0x61a2b3fc, 0x2602c92c, 0x1b62e09c,
	0xf9d2e0cf, 0xc4b2c97f, 0x8312b3af, 0xbe729a1f,
	0x0c52460f, 0x31326fbf, 0x7692156f, 0x4bf23cdf,
	0xc9a2ab0e, 0xf4c282be, 0xb362f86e, 0x8e02d1de,
	0x3c220dce, 0x0142247e, 0x46e25eae, 0x7b82771e,
	0xb1e6b092, 0x8c869922, 0xcb26e3f2, 0xf646ca42,
	0x44661652, 0x79063fe2, 0x3ea64532, 0x03c66c82,
	0x8196fb53, 0xbcf6d2e3, 0xfb56a833, 0xc6368183,
	0x74165d93, 0x49767423, 0x0ed60ef3, 0x33b62743,
	0xd1062710, 0xec660ea0, 0xabc67470, 0x96a65dc0,
	0x248681d0, 0x19e6a860, 0x5e46d2b0, 0x6326fb00,
	0xe1766cd1, 0xdc164561, 0x9bb63fb1, 0xa6d61601,
	0x14f6ca11, 0x2996e3a1, 0x6e369971, 0x5356b0c1,
	0x70279f96, 0x4d47b626, 0x0ae7ccf6, 0x3787e546,
	0x85a73956, 0xb8c710e6, 0xff676a36, 0xc2074386,
	0x4057d457, 0x7d37fde7, 0x3a978737, 0x07f7ae87,
	0xb5d77297, 0x88b75b27, 0xcf1721f7, 0xf2770847,
	0x10c70814, 0x2da721a4, 0x6a075b74, 0x576772c4,
	0xe547aed4, 0xd8278764, 0x9f87fdb4, 0xa2e7d404,
	0x20b743d5, 0x1dd76a65, 0x5a7710b5, 0x67173905,
	0xd537e515, 0xe857cca5, 0xaff7b675, 0x92979fc5,
	0xe915e8db, 0xd475c16b, 0x93d5bbbb, 0xaeb5920b,
	0x1c954e1b, 0x21f567ab, 0x66551d7b, 0x5b3534cb,
	0xd965a31a, 0xe4058aaa, 0xa3a5f07a, 0x9ec5d9ca,
	0x2ce505da, 0x11852c6a, 0x562556ba, 0x6b457f0a,
	0x89f57f59, 0xb49556e9, 0xf3352c39, 0xce550589,
	0x7c75d999, 0x4115f029, 0x06b58af9, 0x3bd5a349,
	0xb9853498, 0x84e51d28, 0xc34567f8, 0xfe254e48,
	0x4c059258, 0x7165bbe8, 0x36c5c138, 0x0ba5e888,
	0x28d4c7df, 0x15b4ee6f, 0x521494bf, 0x6f74bd0f,
	0xdd54611f, 0xe03448af, 0xa794327f, 0x9af41bcf,
	0x18a48c1e, 0x25c4a5ae, 0x6264df7e, 0x5f04f6ce,
	0xed242ade, 0xd044036e, 0x97e479be, 0xaa84500e,
	0x4834505d, 0x755479ed, 0x32f4033d, 0x0f942a8d,
	0xbdb4f69d, 0x80d4df2d, 0xc774a5fd, 0xfa148c4d,
	0x78441b9c, 0x4524322c, 0x028448fc, 0x3fe4614c,
	0x8dc4bd5c, 0xb0a494ec, 0xf704ee3c, 0xca64c78c,
	0x00000000, 0xcb5cd3a5, 0x4dc8a10b, 0x869472ae,
	0x9b914216, 0x50cd91b3, 0xd659e31d, 0x1d0530b8,
	0xec53826d, 0x270f51c8, 0xa19b2366, 0x6ac7f0c3,
	0x77c2c07b, 0xbc9e13de, 0x3a0a6170, 0xf156b2d5,
	0x03d6029b, 0xc88ad13e, 0x4e1ea390, 0x85427035,
	0x9847408d, 0x531b9328, 0xd58fe186, 0x1ed33223,
	0xef8580f6, 0x24d95353, 0xa24d21fd, 0x6911f258,
	0x7414c2e0, 0xbf481145, 0x39dc63eb, 0xf280b04e,
	0x07ac0536, 0xccf0d693, 0x4a64a43d, 0x81387798,
	0x9c3d4720, 0x57619485, 0xd1f5e62b, 0x1aa9358e,
	0xebff875b, 0x20a354fe, 0xa6372650, 0x6d6bf5f5,
	0x706ec54d, 0xbb3216e8, 0x3da66446, 0xf6fab7e3,
	0x047a07ad, 0xcf26d408, 0x49b2a6a6, 0x82ee7503,
	0x9feb45bb, 0x54b7961e, 0xd223e4b0, 0x197f3715,
	0xe82985c0, 0x23755665, 0xa5e124cb, 0x6ebdf76e,
	0x73b8c7d6, 0xb8e41473, 0x3e7066dd, 0xf52cb578,
	0x0f580a6c, 0xc404d9c9, 0x4290ab67, 0x89cc78c2,
	0x94c9487a, 0x5f959bdf, 0xd901e971, 0x125d3ad4,
	0xe30b8801, 0x28575ba4, 0xaec3290a, 0x659ffaaf,
	0x789aca17, 0xb3c619b2, 0x35526b1c, 0xfe0eb8b9,
	0x0c8e08f7, 0xc7d2db52, 0x4146a9fc, 0x8a1a7a59,
	0x971f4ae1, 0x5c439944, 0xdad7ebea, 0x118b384f,
	0xe0dd8a9a, 0x2b81593f, 0xad152b91, 0x6649f834,
	0x7b4cc88c, 0xb0101b29, 0x36846987, 0xfdd8ba22,
	0x08f40f5a, 0xc3a8dcff, 0x453cae51, 0x8e607df4,
	0x93654d4c, 0x58399ee9, 0xdeadec47, 0x15f13fe2,
	0xe4a78d37, 0x2ffb5e92, 0xa96f2c3c, 0x6233ff99,
	0x7f36cf21, 0xb46a1c84, 0x32fe6e2a, 0xf9a2bd8f,
	0x0b220dc1, 0xc07ede64, 0x46eaacca, 0x8db67f6f,
	0x90b34fd7, 0x5bef9c72, 0xdd7beedc, 0x16273d79,
	0xe7718fac, 0x2c2d5c09, 0xaab92ea7, 0x61e5fd02,
	0x7ce0cdba, 0xb7bc1e1f, 0x31286cb1, 0xfa74bf14,
	0x1eb014d8, 0xd5ecc77d, 0x5378b5d3, 0x98246676,
	0x852156ce, 0x4e7d856b, 0xc8e9f7c5, 0x03b52460,
	0xf2e396b5, 0x39bf4510, 0xbf2b37be, 0x7477e41b,
	0x6972d4a3, 0xa22e0706, 0x24ba75a8, 0xefe6a60d,
	0x1d661643, 0xd63ac5e6, 0x50aeb748, 0x9bf264ed,
	0x86f75455, 0x4dab87f0, 0xcb3ff55e, 0x006326fb,
	0xf135942e, 0x3a69478b, 0xbcfd3525, 0x77a1e680,
	0x6aa4d638, 0xa1f8059d, 0x276c7733, 0xec30a496,
	0x191c11ee, 0xd240c24b, 0x54d4b0e5, 0x9f886340,
	0x828d53f8, 0x49d1805d, 0xcf45f2f3, 0x04192156,
	0xf54f9383, 0x3e134026, 0xb8873288, 0x73dbe12d,
	0x6eded195, 0xa5820230, 0x2316709e, 0xe84aa33b,
	0x1aca1375, 0xd196c0d0, 0x5702b27e, 0x9c5e61db,
	0x815b5163, 0x4a0782c6, 0xcc93f068, 0x07cf23cd,
	0xf6999118, 0x3dc542bd, 0xbb513013, 0x700de3b6,
	0x6d08d30e, 0xa65400ab, 0x20c07205, 0xeb9ca1a0,
	0x11e81eb4, 0xdab4cd11, 0x5c20bfbf, 0x977c6c1a,
	0x8a795ca2, 0x41258f07, 0xc7b1fda9, 0x0ced2e0c,
	0xfdbb9cd9, 0x36e74f7c, 0xb0733dd2, 0x7b2fee77,
	0x662adecf, 0xad760d6a, 0x2be27fc4, 0xe0beac61,
	0x123e1c2f, 0xd962cf8a, 0x5ff6bd24, 0x94aa6e81,
	0x89af5e39, 0x42f38d9c, 0xc467ff32, 0x0f3b2c97,
	0xfe6d9e42, 0x35314de7, 0xb3a53f49, 0x78f9ecec,
	0x65fcdc54, 0xaea00ff1, 0x28347d5f, 0xe368aefa,
	0x16441b82, 0xdd18c827, 0x5b8cba89, 0x90d0692c,
	0x8dd55994, 0x46898a31, 0xc01df89f, 0x0b412b3a,
	0xfa1799ef, 0x314b4a4a, 0xb7df38e4, 0x7c83eb41,
	0x6186dbf9, 0xaada085c, 0x2c4e7af2, 0xe712a957,
	0x15921919, 0xdececabc, 0x585ab812, 0x93066bb7,
	0x8e035b0f, 0x455f88aa, 0xc3cbfa04, 0x089729a1,
	0xf9c19b74, 0x329d48d1, 0xb4093a7f, 0x7f55e9da,
	0x6250d962, 0xa90c0ac7, 0x2f987869, 0xe4c4abcc,
	0x00000000, 0xa6770bb4, 0x979f1129, 0x31e81a9d,
	0xf44f2413, 0x52382fa7, 0x63d0353a, 0xc5a73e8e,
	0x33ef4e67, 0x959845d3, 0xa4705f4e, 0x020754fa,
	0xc7a06a74, 0x61d761c0, 0x503f7b5d, 0xf64870e9,
	0x67de9cce, 0xc1a9977a, 0xf0418de7, 0x56368653,
	0x9391b8dd, 0x35e6b369, 0x040ea9f4, 0xa279a240,
	0x5431d2a9, 0xf246d91d, 0xc3aec380, 0x65d9c834,
	0xa07ef6ba, 0x0609fd0e, 0x37e1e793, 0x9196ec27,
	0xcfbd399c, 0x69ca3228, 0x582228b5, 0xfe552301,
	0x3bf21d8f, 0x9d85163b, 0xac6d0ca6, 0x0a1a0712,
	0xfc5277fb, 0x5a257c4f, 0x6bcd66d2, 0xcdba6d66,
	0x081d53e8, 0xae6a585c, 0x9f8242c1, 0x39f54975,
	0xa863a552, 0x0e14aee6, 0x3ffcb47b, 0x998bbfcf,
	0x5c2c8141, 0xfa5b8af5, 0xcbb39068, 0x6dc49bdc,
	0x9b8ceb35, 0x3dfbe081, 0x0c13fa1c, 0xaa64f1a8,
	0x6fc3cf26, 0xc9b4c492, 0xf85cde0f, 0x5e2bd5bb,
	0x440b7579, 0xe27c7ecd, 0xd3946450, 0x75e36fe4,
	0xb044516a, 0x16335ade, 0x27db4043, 0x81ac4bf7,
	0x77e43b1e, 0xd19330aa, 0xe07b2a37, 0x460c2183,
	0x83ab1f0d, 0x25dc14b9, 0x14340e24, 0xb2430590,
	0x23d5e9b7, 0x85a2e203, 0xb44af89e, 0x123df32a,
	0xd79acda4, 0x71edc610, 0x4005dc8d, 0xe672d739,
	0x103aa7d0, 0xb64dac64, 0x87a5b6f9, 0x21d2bd4d,
	0xe47583c3, 0x42028877, 0x73ea92ea, 0xd59d995e,
	0x8bb64ce5, 0x2dc14751, 0x1c295dcc, 0xba5e5678,
	0x7ff968f6, 0xd98e6342, 0xe86679df, 0x4e11726b,
	0xb8590282, 0x1e2e0936, 0x2fc613ab, 0x89b1181f,
	0x4c162691, 0xea612d25, 0xdb8937b8, 0x7dfe3c0c,
	0xec68d02b, 0x4a1fdb9f, 0x7bf7c102, 0xdd80cab6,
	0x1827f438, 0xbe50ff8c, 0x8fb8e511, 0x29cfeea5,
	0xdf879e4c, 0x79f095f8, 0x48188f65, 0xee6f84d1,
	0x2bc8ba5f, 0x8dbfb1eb, 0xbc57ab76, 0x1a20a0c2,
	0x8816eaf2, 0x2e61e146, 0x1f89fbdb, 0xb9fef06f,
	0x7c59cee1, 0xda2ec555, 0xebc6dfc8, 0x4db1d47c,
	0xbbf9a495, 0x1d8eaf21, 0x2c66b5bc, 0x8a11be08,
	0x4fb68086, 0xe9c18b32, 0xd82991af, 0x7e5e9a1b,
	0xefc8763c, 0x49bf7d88, 0x78576715, 0xde206ca1,
	0x1b87522f, 0xbdf0599b, 0x8c184306, 0x2a6f48b2,
	0xdc27385b, 0x7a5033ef, 0x4bb82972, 0xedcf22c6,
	0x28681c48, 0x8e1f17fc, 0xbff70d61, 0x198006d5,
	0x47abd36e, 0xe1dcd8da, 0xd034c247, 0x7643c9f3,
	0xb3e4f77d, 0x1593fcc9, 0x247be654, 0x820cede0,
	0x74449d09, 0xd23396bd, 0xe3db8c20, 0x45ac8794,
	0x800bb91a, 0x267cb2ae, 0x1794a833, 0xb1e3a387,
	0x20754fa0, 0x86024414, 0xb7ea5e89, 0x119d553d,
	0xd43a6bb3, 0x724d6007, 0x43a57a9a, 0xe5d2712e,
	0x139a01c7, 0xb5ed0a73, 0x840510ee, 0x22721b5a,
	0xe7d525d4, 0x41a22e60, 0x704a34fd, 0xd63d3f49,
	0xcc1d9f8b, 0x6a6a943f, 0x5b828ea2, 0xfdf58516,
	0x3852bb98, 0x9e25b02c, 0xafcdaab1, 0x09baa105,
	0xfff2d1ec, 0x5985da58, 0x686dc0c5, 0xce1acb71,
	0x0bbdf5ff, 0xadcafe4b, 0x9c22e4d6, 0x3a55ef62,
	0xabc30345, 0x0db408f1, 0x3c5c126c, 0x9a2b19d8,
	0x5f8c2756, 0xf9fb2ce2, 0xc813367f, 0x6e643dcb,
	0x982c4d22, 0x3e5b4696, 0x0fb35c0b, 0xa9c457bf,
	0x6c636931, 0xca146285, 0xfbfc7818, 0x5d8b73ac,
	0x03a0a617, 0xa5d7ada3, 0x943fb73e, 0x3248bc8a,
	0xf7ef8204, 0x519889b0, 0x6070932d, 0xc6079899,
	0x304fe870, 0x9638e3c4, 0xa7d0f959, 0x01a7f2ed,
	0xc400cc63, 0x6277c7d7, 0x539fdd4a, 0xf5e8d6fe,
	0x647e3ad9, 0xc209316d, 0xf3e12bf0, 0x55962044,
	0x90311eca, 0x3646157e, 0x07ae0fe3, 0xa1d90457,
	0x579174be, 0xf1e67f0a, 0xc00e6597, 0x66796e23,
	0xa3de50ad, 0x05a95b19, 0x34414184, 0x92364a30,
	0x00000000, 0xccaa009e, 0x4225077d, 0x8e8f07e3,
	0x844a0efa, 0x48e00e64, 0xc66f0987, 0x0ac50919,
	0xd3e51bb5, 0x1f4f1b2b, 0x91c01cc8, 0x5d6a1c56,
	0x57af154f, 0x9b0515d1, 0x158a1232, 0xd92012ac,
	0x7cbb312b, 0xb01131b5, 0x3e9e3656, 0xf23436c8,
	0xf8f13fd1, 0x345b3f4f, 0xbad438ac, 0x767e3832,
	0xaf5e2a9e, 0x63f42a00, 0xed7b2de3, 0x21d12d7d,
	0x2b142464, 0xe7be24fa, 0x69312319, 0xa59b2387,
	0xf9766256, 0x35dc62c8, 0xbb53652b, 0x77f965b5,
	0x7d3c6cac, 0xb1966c32, 0x3f196bd1, 0xf3b36b4f,
	0x2a9379e3, 0xe639797d, 0x68b67e9e, 0xa41c7e00,
	0xaed97719, 0x62737787, 0xecfc7064, 0x205670fa,
	0x85cd537d, 0x496753e3, 0xc7e85400, 0x0b42549e,
	0x01875d87, 0xcd2d5d19, 0x43a25afa, 0x8f085a64,
	0x562848c8, 0x9a824856, 0x140d4fb5, 0xd8a74f2b,
	0xd2624632, 0x1ec846ac, 0x9047414f, 0x5ced41d1,
	0x299dc2ed, 0xe537c273, 0x6bb8c590, 0xa712c50e,
	0xadd7cc17, 0x617dcc89, 0xeff2cb6a, 0x2358cbf4,
	0xfa78d958, 0x36d2d9c6, 0xb85dde25, 0x74f7debb,
	0x7e32d7a2, 0xb298d73c, 0x3c17d0df, 0xf0bdd041,
	0x5526f3c6, 0x998cf358, 0x1703f4bb, 0xdba9f425,
	0xd16cfd3c, 0x1dc6fda2, 0x9349fa41, 0x5fe3fadf,
	0x86c3e873, 0x4a69e8ed, 0xc4e6ef0e, 0x084cef90,
	0x0289e689, 0xce23e617, 0x40ace1f4, 0x8c06e16a,
	0xd0eba0bb, 0x1c41a025, 0x92cea7c6, 0x5e64a758,
	0x54a1ae41, 0x980baedf, 0x1684a93c, 0xda2ea9a2,
	0x030ebb0e, 0xcfa4bb90, 0x412bbc73, 0x8d81bced,
	0x8744b5f4, 0x4beeb56a, 0xc561b289, 0x09cbb217,
	0xac509190, 0x60fa910e, 0xee7596ed, 0x22df9673,
	0x281a9f6a, 0xe4b09ff4, 0x6a3f9817, 0xa6959889,
	0x7fb58a25, 0xb31f8abb, 0x3d908d58, 0xf13a8dc6,
	0xfbff84df, 0x37558441, 0xb9da83a2, 0x7570833c,
	0x533b85da, 0x9f918544, 0x111e82a7, 0xddb48239,
	0xd7718b20, 0x1bdb8bbe, 0x95548c5d, 0x59fe8cc3,
	0x80de9e6f, 0x4c749ef1, 0xc2fb9912, 0x0e51998c,
	0x04949095, 0xc83e900b, 0x46b197e8, 0x8a1b9776,
	0x2f80b4f1, 0xe32ab46f, 0x6da5b38c, 0xa10fb312,
	0xabcaba0b, 0x6760ba95, 0xe9efbd76, 0x2545bde8,
	0xfc65af44, 0x30cfafda, 0xbe40a839, 0x72eaa8a7,
	0x782fa1be, 0xb485a120, 0x3a0aa6c3, 0xf6a0a65d,
	0xaa4de78c, 0x66e7e712, 0xe868e0f1, 0x24c2e06f,
	0x2e07e976, 0xe2ade9e8, 0x6c22ee0b, 0xa088ee95,
	0x79a8fc39, 0xb502fca7, 0x3b8dfb44, 0xf727fbda,
	0xfde2f2c3, 0x3148f25d, 0xbfc7f5be, 0x736df520,
	0xd6f6d6a7, 0x1a5cd639, 0x94d3d1da, 0x5879d144,
	0x52bcd85d, 0x9e16d8c3, 0x1099df20, 0xdc33dfbe,
	0x0513cd12, 0xc9b9cd8c, 0x4736ca6f, 0x8b9ccaf1,
	0x8159c3e8, 0x4df3c376, 0xc37cc495, 0x0fd6c40b,
	0x7aa64737, 0xb60c47a9, 0x3883404a, 0xf42940d4,
	0xfeec49cd, 0x32464953, 0xbcc94eb0, 0x70634e2e,
	0xa9435c82, 0x65e95c1c, 0xeb665bff, 0x27cc5b61,
	0x2d095278, 0xe1a352e6, 0x6f2c5505, 0xa386559b,
	0x061d761c, 0xcab77682, 0x44387161, 0x889271ff,
	0x825778e6, 0x4efd7878, 0xc0727f9b, 0x0cd87f05,
	0xd5f86da9, 0x19526d37, 0x97dd6ad4, 0x5b776a4a,
	0x51b26353, 0x9d1863cd, 0x1397642e, 0xdf3d64b0,
	0x83d02561, 0x4f7a25ff, 0xc1f5221c, 0x0d5f2282,
	0x079a2b9b, 0xcb302b05, 0x45bf2ce6, 0x89152c78,
	0x50353ed4, 0x9c9f3e4a, 0x121039a9, 0xdeba3937,
	0xd47f302e, 0x18d530b0, 0x965a3753, 0x5af037cd,
	0xff6b144a, 0x33c114d4, 0xbd4e1337, 0x71e413a9,
	0x7b211ab0, 0xb78b1a2e, 0x39041dcd, 0xf5ae1d53,
	0x2c8e0fff, 0xe0240f61, 0x6eab0882, 0xa201081c,
	0xa8c40105, 0x646e019b, 0xeae10678, 0x264b06e6,
#endif 
};

static forceinline u32
crc32_update_byte(u32 remainder, u8 next_byte)
{
	return (remainder >> 8) ^ crc32_table[(u8)remainder ^ next_byte];
}
#endif

#ifdef CRC32_SLICE1
static u32
crc32_slice1(u32 remainder, const u8 *buffer, size_t size)
{
	size_t i;

	STATIC_ASSERT(ARRAY_LEN(crc32_table) >= 0x100);

	for (i = 0; i < size; i++)
		remainder = crc32_update_byte(remainder, buffer[i]);
	return remainder;
}
#endif 

#ifdef CRC32_SLICE4
static u32
crc32_slice4(u32 remainder, const u8 *buffer, size_t size)
{
	const u8 *p = buffer;
	const u8 *end = buffer + size;
	const u8 *end32;

	STATIC_ASSERT(ARRAY_LEN(crc32_table) >= 0x400);

	for (; ((uintptr_t)p & 3) && p != end; p++)
		remainder = crc32_update_byte(remainder, *p);

	end32 = p + ((end - p) & ~3);
	for (; p != end32; p += 4) {
		u32 v = le32_bswap(*(const u32 *)p);
		remainder =
		    crc32_table[0x300 + (u8)((remainder ^ v) >>  0)] ^
		    crc32_table[0x200 + (u8)((remainder ^ v) >>  8)] ^
		    crc32_table[0x100 + (u8)((remainder ^ v) >> 16)] ^
		    crc32_table[0x000 + (u8)((remainder ^ v) >> 24)];
	}

	for (; p != end; p++)
		remainder = crc32_update_byte(remainder, *p);

	return remainder;
}
#endif 

#ifdef CRC32_SLICE8
static u32
crc32_slice8(u32 remainder, const u8 *buffer, size_t size)
{
	const u8 *p = buffer;
	const u8 *end = buffer + size;
	const u8 *end64;

	STATIC_ASSERT(ARRAY_LEN(crc32_table) >= 0x800);

	for (; ((uintptr_t)p & 7) && p != end; p++)
		remainder = crc32_update_byte(remainder, *p);

	end64 = p + ((end - p) & ~7);
	for (; p != end64; p += 8) {
		u32 v1 = le32_bswap(*(const u32 *)(p + 0));
		u32 v2 = le32_bswap(*(const u32 *)(p + 4));
		remainder =
		    crc32_table[0x700 + (u8)((remainder ^ v1) >>  0)] ^
		    crc32_table[0x600 + (u8)((remainder ^ v1) >>  8)] ^
		    crc32_table[0x500 + (u8)((remainder ^ v1) >> 16)] ^
		    crc32_table[0x400 + (u8)((remainder ^ v1) >> 24)] ^
		    crc32_table[0x300 + (u8)(v2 >>  0)] ^
		    crc32_table[0x200 + (u8)(v2 >>  8)] ^
		    crc32_table[0x100 + (u8)(v2 >> 16)] ^
		    crc32_table[0x000 + (u8)(v2 >> 24)];
	}

	for (; p != end; p++)
		remainder = crc32_update_byte(remainder, *p);

	return remainder;
}
#endif 

#ifdef DISPATCH
static u32 crc32_dispatch(u32, const u8 *, size_t);

static volatile crc32_func_t crc32_impl = crc32_dispatch;


static u32 crc32_dispatch(u32 remainder, const u8 *buffer, size_t size)
{
	crc32_func_t f = arch_select_crc32_func();

	if (f == NULL)
		f = DEFAULT_IMPL;

	crc32_impl = f;
	return crc32_impl(remainder, buffer, size);
}
#else
#  define crc32_impl DEFAULT_IMPL 
#endif

LIBDEFLATEEXPORT u32 LIBDEFLATEAPI
libdeflate_crc32(u32 remainder, const void *buffer, size_t size)
{
	if (buffer == NULL) 
		return 0;
	return ~crc32_impl(~remainder, buffer, size);
}
/* /usr/home/ben/projects/gzip-libdeflate/../../software/libdeflate-1.7/lib/deflate_compress.c */


/* #include "deflate_compress.h" */
#ifndef LIB_DEFLATE_COMPRESS_H
#define LIB_DEFLATE_COMPRESS_H

/* #include "lib_common.h" */


#ifndef LIB_LIB_COMMON_H
#define LIB_LIB_COMMON_H

#ifdef LIBDEFLATE_H
#  error "lib_common.h must always be included before libdeflate.h"
   
#endif

#define BUILDING_LIBDEFLATE

/* #include "../common/common_defs.h" */


#ifndef COMMON_COMMON_DEFS_H
#define COMMON_COMMON_DEFS_H

#ifdef __GNUC__
/* #  include "compiler_gcc.h" */


#if !defined(__clang__) && !defined(__INTEL_COMPILER)
#  define GCC_PREREQ(major, minor)		\
	(__GNUC__ > (major) ||			\
	 (__GNUC__ == (major) && __GNUC_MINOR__ >= (minor)))
#else
#  define GCC_PREREQ(major, minor)	0
#endif


#ifdef __clang__
#  ifdef __apple_build_version__
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__apple_build_version__ >= (apple_version))
#  else
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__clang_major__ > (major) ||			\
	 (__clang_major__ == (major) && __clang_minor__ >= (minor)))
#  endif
#else
#  define CLANG_PREREQ(major, minor, apple_version)	0
#endif

#ifndef __has_attribute
#  define __has_attribute(attribute)	0
#endif
#ifndef __has_feature
#  define __has_feature(feature)	0
#endif
#ifndef __has_builtin
#  define __has_builtin(builtin)	0
#endif

#ifdef _WIN32
#  define LIBEXPORT __declspec(dllexport)
#else
#  define LIBEXPORT __attribute__((visibility("default")))
#endif

#define inline			inline
#define forceinline		inline __attribute__((always_inline))
#define restrict		__restrict__
#define likely(expr)		__builtin_expect(!!(expr), 1)
#define unlikely(expr)		__builtin_expect(!!(expr), 0)
#define prefetchr(addr)		__builtin_prefetch((addr), 0)
#define prefetchw(addr)		__builtin_prefetch((addr), 1)
#define _aligned_attribute(n)	__attribute__((aligned(n)))

#define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE	\
	(GCC_PREREQ(4, 4) || __has_attribute(target))

#if COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE

#  if defined(__i386__) || defined(__x86_64__)

#    define COMPILER_SUPPORTS_PCLMUL_TARGET	\
	(GCC_PREREQ(4, 4) || __has_builtin(__builtin_ia32_pclmulqdq128))

#    define COMPILER_SUPPORTS_AVX_TARGET	\
	(GCC_PREREQ(4, 6) || __has_builtin(__builtin_ia32_maxps256))

#    define COMPILER_SUPPORTS_BMI2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_pdep_di))

#    define COMPILER_SUPPORTS_AVX2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_psadbw256))

#    define COMPILER_SUPPORTS_AVX512BW_TARGET	\
	(GCC_PREREQ(5, 1) || __has_builtin(__builtin_ia32_psadbw512))

	
#    if GCC_PREREQ(4, 9) || CLANG_PREREQ(3, 8, 7030000)
#      define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS	1
#      define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_PCLMUL_TARGET
#      define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX2_TARGET
#      define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX512BW_TARGET
#    endif

#  elif defined(__arm__) || defined(__aarch64__)

    
#    if (GCC_PREREQ(6, 1) && defined(__ARM_FP)) || \
        (defined(__clang__) && defined(__ARM_NEON))
#      define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 1
       
#      if defined(__clang__) && defined(__arm__)
#        undef __ARM_FEATURE_CRYPTO
#      elif __has_builtin(__builtin_neon_vmull_p64) || !defined(__clang__)
#        define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 1
#      endif
#    endif

     
#    if GCC_PREREQ(10, 1) || \
        (GCC_PREREQ(9, 3) && !GCC_PREREQ(10, 0)) || \
        (GCC_PREREQ(8, 4) && !GCC_PREREQ(9, 0)) || \
        (defined(__clang__) && __has_builtin(__builtin_arm_crc32b))
#      define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 1
#    endif

#  endif 

#endif 


#if (GCC_PREREQ(4, 0) && !GCC_PREREQ(5, 1)) || \
    (defined(__clang__) && !CLANG_PREREQ(3, 9, 8020000))
typedef unsigned long long  __v2du __attribute__((__vector_size__(16)));
typedef unsigned int        __v4su __attribute__((__vector_size__(16)));
typedef unsigned short      __v8hu __attribute__((__vector_size__(16)));
typedef unsigned char      __v16qu __attribute__((__vector_size__(16)));
typedef unsigned long long  __v4du __attribute__((__vector_size__(32)));
typedef unsigned int        __v8su __attribute__((__vector_size__(32)));
typedef unsigned short     __v16hu __attribute__((__vector_size__(32)));
typedef unsigned char      __v32qu __attribute__((__vector_size__(32)));
#endif


#ifdef __BYTE_ORDER__
#  define CPU_IS_LITTLE_ENDIAN() (__BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__)
#endif

#if GCC_PREREQ(4, 8) || __has_builtin(__builtin_bswap16)
#  define bswap16	__builtin_bswap16
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap32)
#  define bswap32	__builtin_bswap32
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap64)
#  define bswap64	__builtin_bswap64
#endif

#if defined(__x86_64__) || defined(__i386__) || defined(__ARM_FEATURE_UNALIGNED) || defined(__powerpc64__)
#  define UNALIGNED_ACCESS_IS_FAST 1
#endif

#define bsr32(n)	(31 - __builtin_clz(n))
#define bsr64(n)	(63 - __builtin_clzll(n))
#define bsf32(n)	__builtin_ctz(n)
#define bsf64(n)	__builtin_ctzll(n)

#elif defined(_MSC_VER)
/* #  include "compiler_msc.h" */


#include <stdint.h>
#include <stdlib.h> 

#define LIBEXPORT	__declspec(dllexport)


typedef int bool;
#define true 1
#define false 0
#define __bool_true_false_are_defined 1


#ifdef _WIN64
typedef long long ssize_t;
#else
typedef int ssize_t;
#endif


#define CPU_IS_LITTLE_ENDIAN()		1
#define UNALIGNED_ACCESS_IS_FAST	1


#define restrict


#define inline		__inline
#define forceinline	__forceinline


#define bswap16	_byteswap_ushort
#define bswap32	_byteswap_ulong
#define bswap64	_byteswap_uint64



static forceinline unsigned
bsr32(uint32_t n)
{
	_BitScanReverse(&n, n);
	return n;
}
#define bsr32 bsr32

static forceinline unsigned
bsf32(uint32_t n)
{
	_BitScanForward(&n, n);
	return n;
}
#define bsf32 bsf32

#ifdef _M_X64 

static forceinline unsigned
bsr64(uint64_t n)
{
	_BitScanReverse64(&n, n);
	return n;
}
#define bsr64 bsr64

static forceinline unsigned
bsf64(uint64_t n)
{
	_BitScanForward64(&n, n);
	return n;
}
#define bsf64 bsf64

#endif 

#else
#  pragma message("Unrecognized compiler.  Please add a header file for your compiler.  Compilation will proceed, but performance may suffer!")
#endif





#include <stddef.h> 

#ifndef __bool_true_false_are_defined
#  include <stdbool.h> 
#endif


#include <stdint.h>
typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
typedef int8_t s8;
typedef int16_t s16;
typedef int32_t s32;
typedef int64_t s64;


typedef size_t machine_word_t;


#define WORDBYTES	((int)sizeof(machine_word_t))


#define WORDBITS	(8 * WORDBYTES)






#ifndef LIBEXPORT
#  define LIBEXPORT
#endif


#ifndef inline
#  define inline
#endif


#ifndef forceinline
#  define forceinline inline
#endif


#ifndef restrict
#  define restrict
#endif


#ifndef likely
#  define likely(expr)		(expr)
#endif


#ifndef unlikely
#  define unlikely(expr)	(expr)
#endif


#ifndef prefetchr
#  define prefetchr(addr)
#endif


#ifndef prefetchw
#  define prefetchw(addr)
#endif


#ifndef COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE
#  define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE 0
#endif


#ifndef COMPILER_SUPPORTS_BMI2_TARGET
#  define COMPILER_SUPPORTS_BMI2_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX_TARGET
#  define COMPILER_SUPPORTS_AVX_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET
#  define COMPILER_SUPPORTS_AVX512BW_TARGET 0
#endif


#ifndef COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 0
#endif


#ifndef _aligned_attribute
#endif





#define ARRAY_LEN(A)		(sizeof(A) / sizeof((A)[0]))
#define MIN(a, b)		((a) <= (b) ? (a) : (b))
#define MAX(a, b)		((a) >= (b) ? (a) : (b))
#define DIV_ROUND_UP(n, d)	(((n) + (d) - 1) / (d))
#define STATIC_ASSERT(expr)	((void)sizeof(char[1 - 2 * !(expr)]))
#define ALIGN(n, a)		(((n) + (a) - 1) & ~((a) - 1))






#ifndef CPU_IS_LITTLE_ENDIAN
static forceinline int CPU_IS_LITTLE_ENDIAN(void)
{
	union {
		unsigned int v;
		unsigned char b;
	} u;
	u.v = 1;
	return u.b;
}
#endif


#ifndef bswap16
static forceinline u16 bswap16(u16 n)
{
	return (n << 8) | (n >> 8);
}
#endif


#ifndef bswap32
static forceinline u32 bswap32(u32 n)
{
	return ((n & 0x000000FF) << 24) |
	       ((n & 0x0000FF00) << 8) |
	       ((n & 0x00FF0000) >> 8) |
	       ((n & 0xFF000000) >> 24);
}
#endif


#ifndef bswap64
static forceinline u64 bswap64(u64 n)
{
	return ((n & 0x00000000000000FF) << 56) |
	       ((n & 0x000000000000FF00) << 40) |
	       ((n & 0x0000000000FF0000) << 24) |
	       ((n & 0x00000000FF000000) << 8) |
	       ((n & 0x000000FF00000000) >> 8) |
	       ((n & 0x0000FF0000000000) >> 24) |
	       ((n & 0x00FF000000000000) >> 40) |
	       ((n & 0xFF00000000000000) >> 56);
}
#endif

#define le16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap16(n))
#define le32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap32(n))
#define le64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap64(n))
#define be16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap16(n) : (n))
#define be32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap32(n) : (n))
#define be64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap64(n) : (n))






#ifndef UNALIGNED_ACCESS_IS_FAST
#  define UNALIGNED_ACCESS_IS_FAST 0
#endif







#ifndef bsr32
static forceinline unsigned
bsr32(u32 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

#ifndef bsr64
static forceinline unsigned
bsr64(u64 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

static forceinline unsigned
bsrw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsr32(n);
	else
		return bsr64(n);
}



#ifndef bsf32
static forceinline unsigned
bsf32(u32 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

#ifndef bsf64
static forceinline unsigned
bsf64(u64 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

static forceinline unsigned
bsfw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsf32(n);
	else
		return bsf64(n);
}

#endif 



#define SYM_FIXUP(sym)			_libdeflate_##sym
#define deflate_get_compression_level	SYM_FIXUP(deflate_get_compression_level)
#define _cpu_features			SYM_FIXUP(_cpu_features)
#define setup_cpu_features		SYM_FIXUP(setup_cpu_features)

void *libdeflate_malloc(size_t size);
void libdeflate_free(void *ptr);

void *libdeflate_aligned_malloc(size_t alignment, size_t size);
void libdeflate_aligned_free(void *ptr);

#ifdef FREESTANDING

void *memset(void *s, int c, size_t n);
#define memset(s, c, n)		__builtin_memset((s), (c), (n))

void *memcpy(void *dest, const void *src, size_t n);
#define memcpy(dest, src, n)	__builtin_memcpy((dest), (src), (n))

void *memmove(void *dest, const void *src, size_t n);
#define memmove(dest, src, n)	__builtin_memmove((dest), (src), (n))

int memcmp(const void *s1, const void *s2, size_t n);
#define memcmp(s1, s2, n)	__builtin_memcmp((s1), (s2), (n))
#else
#include <string.h>
#endif

#endif 




struct libdeflate_compressor;

unsigned int deflate_get_compression_level(struct libdeflate_compressor *c);

#endif 

/* #include "deflate_constants.h" */


#ifndef LIB_DEFLATE_CONSTANTS_H
#define LIB_DEFLATE_CONSTANTS_H


#define DEFLATE_BLOCKTYPE_UNCOMPRESSED		0
#define DEFLATE_BLOCKTYPE_STATIC_HUFFMAN	1
#define DEFLATE_BLOCKTYPE_DYNAMIC_HUFFMAN	2


#define DEFLATE_MIN_MATCH_LEN			3
#define DEFLATE_MAX_MATCH_LEN			258


#define DEFLATE_MIN_MATCH_OFFSET		1
#define DEFLATE_MAX_MATCH_OFFSET		32768

#define DEFLATE_MAX_WINDOW_SIZE			32768


#define DEFLATE_NUM_PRECODE_SYMS		19
#define DEFLATE_NUM_LITLEN_SYMS			288
#define DEFLATE_NUM_OFFSET_SYMS			32


#define DEFLATE_MAX_NUM_SYMS			288


#define DEFLATE_NUM_LITERALS			256
#define DEFLATE_END_OF_BLOCK			256
#define DEFLATE_NUM_LEN_SYMS			31


#define DEFLATE_MAX_PRE_CODEWORD_LEN		7
#define DEFLATE_MAX_LITLEN_CODEWORD_LEN		15
#define DEFLATE_MAX_OFFSET_CODEWORD_LEN		15


#define DEFLATE_MAX_CODEWORD_LEN		15


#define DEFLATE_MAX_LENS_OVERRUN		137


#define DEFLATE_MAX_EXTRA_LENGTH_BITS		5
#define DEFLATE_MAX_EXTRA_OFFSET_BITS		14


#define DEFLATE_MAX_MATCH_BITS	\
	(DEFLATE_MAX_LITLEN_CODEWORD_LEN + DEFLATE_MAX_EXTRA_LENGTH_BITS + \
	DEFLATE_MAX_OFFSET_CODEWORD_LEN + DEFLATE_MAX_EXTRA_OFFSET_BITS)

#endif 

/* #include "unaligned.h" */


#ifndef LIB_UNALIGNED_H
#define LIB_UNALIGNED_H

/* #include "lib_common.h" */


#ifndef LIB_LIB_COMMON_H
#define LIB_LIB_COMMON_H

#ifdef LIBDEFLATE_H
#  error "lib_common.h must always be included before libdeflate.h"
   
#endif

#define BUILDING_LIBDEFLATE

/* #include "../common/common_defs.h" */


#ifndef COMMON_COMMON_DEFS_H
#define COMMON_COMMON_DEFS_H

#ifdef __GNUC__
/* #  include "compiler_gcc.h" */


#if !defined(__clang__) && !defined(__INTEL_COMPILER)
#  define GCC_PREREQ(major, minor)		\
	(__GNUC__ > (major) ||			\
	 (__GNUC__ == (major) && __GNUC_MINOR__ >= (minor)))
#else
#  define GCC_PREREQ(major, minor)	0
#endif


#ifdef __clang__
#  ifdef __apple_build_version__
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__apple_build_version__ >= (apple_version))
#  else
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__clang_major__ > (major) ||			\
	 (__clang_major__ == (major) && __clang_minor__ >= (minor)))
#  endif
#else
#  define CLANG_PREREQ(major, minor, apple_version)	0
#endif

#ifndef __has_attribute
#  define __has_attribute(attribute)	0
#endif
#ifndef __has_feature
#  define __has_feature(feature)	0
#endif
#ifndef __has_builtin
#  define __has_builtin(builtin)	0
#endif

#ifdef _WIN32
#  define LIBEXPORT __declspec(dllexport)
#else
#  define LIBEXPORT __attribute__((visibility("default")))
#endif

#define inline			inline
#define forceinline		inline __attribute__((always_inline))
#define restrict		__restrict__
#define likely(expr)		__builtin_expect(!!(expr), 1)
#define unlikely(expr)		__builtin_expect(!!(expr), 0)
#define prefetchr(addr)		__builtin_prefetch((addr), 0)
#define prefetchw(addr)		__builtin_prefetch((addr), 1)
#define _aligned_attribute(n)	__attribute__((aligned(n)))

#define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE	\
	(GCC_PREREQ(4, 4) || __has_attribute(target))

#if COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE

#  if defined(__i386__) || defined(__x86_64__)

#    define COMPILER_SUPPORTS_PCLMUL_TARGET	\
	(GCC_PREREQ(4, 4) || __has_builtin(__builtin_ia32_pclmulqdq128))

#    define COMPILER_SUPPORTS_AVX_TARGET	\
	(GCC_PREREQ(4, 6) || __has_builtin(__builtin_ia32_maxps256))

#    define COMPILER_SUPPORTS_BMI2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_pdep_di))

#    define COMPILER_SUPPORTS_AVX2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_psadbw256))

#    define COMPILER_SUPPORTS_AVX512BW_TARGET	\
	(GCC_PREREQ(5, 1) || __has_builtin(__builtin_ia32_psadbw512))

	
#    if GCC_PREREQ(4, 9) || CLANG_PREREQ(3, 8, 7030000)
#      define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS	1
#      define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_PCLMUL_TARGET
#      define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX2_TARGET
#      define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX512BW_TARGET
#    endif

#  elif defined(__arm__) || defined(__aarch64__)

    
#    if (GCC_PREREQ(6, 1) && defined(__ARM_FP)) || \
        (defined(__clang__) && defined(__ARM_NEON))
#      define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 1
       
#      if defined(__clang__) && defined(__arm__)
#        undef __ARM_FEATURE_CRYPTO
#      elif __has_builtin(__builtin_neon_vmull_p64) || !defined(__clang__)
#        define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 1
#      endif
#    endif

     
#    if GCC_PREREQ(10, 1) || \
        (GCC_PREREQ(9, 3) && !GCC_PREREQ(10, 0)) || \
        (GCC_PREREQ(8, 4) && !GCC_PREREQ(9, 0)) || \
        (defined(__clang__) && __has_builtin(__builtin_arm_crc32b))
#      define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 1
#    endif

#  endif 

#endif 


#if (GCC_PREREQ(4, 0) && !GCC_PREREQ(5, 1)) || \
    (defined(__clang__) && !CLANG_PREREQ(3, 9, 8020000))
typedef unsigned long long  __v2du __attribute__((__vector_size__(16)));
typedef unsigned int        __v4su __attribute__((__vector_size__(16)));
typedef unsigned short      __v8hu __attribute__((__vector_size__(16)));
typedef unsigned char      __v16qu __attribute__((__vector_size__(16)));
typedef unsigned long long  __v4du __attribute__((__vector_size__(32)));
typedef unsigned int        __v8su __attribute__((__vector_size__(32)));
typedef unsigned short     __v16hu __attribute__((__vector_size__(32)));
typedef unsigned char      __v32qu __attribute__((__vector_size__(32)));
#endif


#ifdef __BYTE_ORDER__
#  define CPU_IS_LITTLE_ENDIAN() (__BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__)
#endif

#if GCC_PREREQ(4, 8) || __has_builtin(__builtin_bswap16)
#  define bswap16	__builtin_bswap16
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap32)
#  define bswap32	__builtin_bswap32
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap64)
#  define bswap64	__builtin_bswap64
#endif

#if defined(__x86_64__) || defined(__i386__) || defined(__ARM_FEATURE_UNALIGNED) || defined(__powerpc64__)
#  define UNALIGNED_ACCESS_IS_FAST 1
#endif

#define bsr32(n)	(31 - __builtin_clz(n))
#define bsr64(n)	(63 - __builtin_clzll(n))
#define bsf32(n)	__builtin_ctz(n)
#define bsf64(n)	__builtin_ctzll(n)

#elif defined(_MSC_VER)
/* #  include "compiler_msc.h" */


#include <stdint.h>
#include <stdlib.h> 

#define LIBEXPORT	__declspec(dllexport)


typedef int bool;
#define true 1
#define false 0
#define __bool_true_false_are_defined 1


#ifdef _WIN64
typedef long long ssize_t;
#else
typedef int ssize_t;
#endif


#define CPU_IS_LITTLE_ENDIAN()		1
#define UNALIGNED_ACCESS_IS_FAST	1


#define restrict


#define inline		__inline
#define forceinline	__forceinline


#define bswap16	_byteswap_ushort
#define bswap32	_byteswap_ulong
#define bswap64	_byteswap_uint64



static forceinline unsigned
bsr32(uint32_t n)
{
	_BitScanReverse(&n, n);
	return n;
}
#define bsr32 bsr32

static forceinline unsigned
bsf32(uint32_t n)
{
	_BitScanForward(&n, n);
	return n;
}
#define bsf32 bsf32

#ifdef _M_X64 

static forceinline unsigned
bsr64(uint64_t n)
{
	_BitScanReverse64(&n, n);
	return n;
}
#define bsr64 bsr64

static forceinline unsigned
bsf64(uint64_t n)
{
	_BitScanForward64(&n, n);
	return n;
}
#define bsf64 bsf64

#endif 

#else
#  pragma message("Unrecognized compiler.  Please add a header file for your compiler.  Compilation will proceed, but performance may suffer!")
#endif





#include <stddef.h> 

#ifndef __bool_true_false_are_defined
#  include <stdbool.h> 
#endif


#include <stdint.h>
typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
typedef int8_t s8;
typedef int16_t s16;
typedef int32_t s32;
typedef int64_t s64;


typedef size_t machine_word_t;


#define WORDBYTES	((int)sizeof(machine_word_t))


#define WORDBITS	(8 * WORDBYTES)






#ifndef LIBEXPORT
#  define LIBEXPORT
#endif


#ifndef inline
#  define inline
#endif


#ifndef forceinline
#  define forceinline inline
#endif


#ifndef restrict
#  define restrict
#endif


#ifndef likely
#  define likely(expr)		(expr)
#endif


#ifndef unlikely
#  define unlikely(expr)	(expr)
#endif


#ifndef prefetchr
#  define prefetchr(addr)
#endif


#ifndef prefetchw
#  define prefetchw(addr)
#endif


#ifndef COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE
#  define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE 0
#endif


#ifndef COMPILER_SUPPORTS_BMI2_TARGET
#  define COMPILER_SUPPORTS_BMI2_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX_TARGET
#  define COMPILER_SUPPORTS_AVX_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET
#  define COMPILER_SUPPORTS_AVX512BW_TARGET 0
#endif


#ifndef COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 0
#endif


#ifndef _aligned_attribute
#endif





#define ARRAY_LEN(A)		(sizeof(A) / sizeof((A)[0]))
#define MIN(a, b)		((a) <= (b) ? (a) : (b))
#define MAX(a, b)		((a) >= (b) ? (a) : (b))
#define DIV_ROUND_UP(n, d)	(((n) + (d) - 1) / (d))
#define STATIC_ASSERT(expr)	((void)sizeof(char[1 - 2 * !(expr)]))
#define ALIGN(n, a)		(((n) + (a) - 1) & ~((a) - 1))






#ifndef CPU_IS_LITTLE_ENDIAN
static forceinline int CPU_IS_LITTLE_ENDIAN(void)
{
	union {
		unsigned int v;
		unsigned char b;
	} u;
	u.v = 1;
	return u.b;
}
#endif


#ifndef bswap16
static forceinline u16 bswap16(u16 n)
{
	return (n << 8) | (n >> 8);
}
#endif


#ifndef bswap32
static forceinline u32 bswap32(u32 n)
{
	return ((n & 0x000000FF) << 24) |
	       ((n & 0x0000FF00) << 8) |
	       ((n & 0x00FF0000) >> 8) |
	       ((n & 0xFF000000) >> 24);
}
#endif


#ifndef bswap64
static forceinline u64 bswap64(u64 n)
{
	return ((n & 0x00000000000000FF) << 56) |
	       ((n & 0x000000000000FF00) << 40) |
	       ((n & 0x0000000000FF0000) << 24) |
	       ((n & 0x00000000FF000000) << 8) |
	       ((n & 0x000000FF00000000) >> 8) |
	       ((n & 0x0000FF0000000000) >> 24) |
	       ((n & 0x00FF000000000000) >> 40) |
	       ((n & 0xFF00000000000000) >> 56);
}
#endif

#define le16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap16(n))
#define le32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap32(n))
#define le64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap64(n))
#define be16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap16(n) : (n))
#define be32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap32(n) : (n))
#define be64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap64(n) : (n))






#ifndef UNALIGNED_ACCESS_IS_FAST
#  define UNALIGNED_ACCESS_IS_FAST 0
#endif







#ifndef bsr32
static forceinline unsigned
bsr32(u32 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

#ifndef bsr64
static forceinline unsigned
bsr64(u64 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

static forceinline unsigned
bsrw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsr32(n);
	else
		return bsr64(n);
}



#ifndef bsf32
static forceinline unsigned
bsf32(u32 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

#ifndef bsf64
static forceinline unsigned
bsf64(u64 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

static forceinline unsigned
bsfw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsf32(n);
	else
		return bsf64(n);
}

#endif 



#define SYM_FIXUP(sym)			_libdeflate_##sym
#define deflate_get_compression_level	SYM_FIXUP(deflate_get_compression_level)
#define _cpu_features			SYM_FIXUP(_cpu_features)
#define setup_cpu_features		SYM_FIXUP(setup_cpu_features)

void *libdeflate_malloc(size_t size);
void libdeflate_free(void *ptr);

void *libdeflate_aligned_malloc(size_t alignment, size_t size);
void libdeflate_aligned_free(void *ptr);

#ifdef FREESTANDING

void *memset(void *s, int c, size_t n);
#define memset(s, c, n)		__builtin_memset((s), (c), (n))

void *memcpy(void *dest, const void *src, size_t n);
#define memcpy(dest, src, n)	__builtin_memcpy((dest), (src), (n))

void *memmove(void *dest, const void *src, size_t n);
#define memmove(dest, src, n)	__builtin_memmove((dest), (src), (n))

int memcmp(const void *s1, const void *s2, size_t n);
#define memcmp(s1, s2, n)	__builtin_memcmp((s1), (s2), (n))
#else
#include <string.h>
#endif

#endif 






#define DEFINE_UNALIGNED_TYPE(type)				\
static forceinline type						\
load_##type##_unaligned(const void *p)				\
{								\
	type v;							\
	memcpy(&v, p, sizeof(v));				\
	return v;						\
}								\
								\
static forceinline void						\
store_##type##_unaligned(type v, void *p)			\
{								\
	memcpy(p, &v, sizeof(v));				\
}

DEFINE_UNALIGNED_TYPE(u16)
DEFINE_UNALIGNED_TYPE(u32)
DEFINE_UNALIGNED_TYPE(u64)
DEFINE_UNALIGNED_TYPE(machine_word_t)

#define load_word_unaligned	load_machine_word_t_unaligned
#define store_word_unaligned	store_machine_word_t_unaligned



static forceinline u16
get_unaligned_le16(const u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST)
		return le16_bswap(load_u16_unaligned(p));
	else
		return ((u16)p[1] << 8) | p[0];
}

static forceinline u16
get_unaligned_be16(const u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST)
		return be16_bswap(load_u16_unaligned(p));
	else
		return ((u16)p[0] << 8) | p[1];
}

static forceinline u32
get_unaligned_le32(const u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST)
		return le32_bswap(load_u32_unaligned(p));
	else
		return ((u32)p[3] << 24) | ((u32)p[2] << 16) |
			((u32)p[1] << 8) | p[0];
}

static forceinline u32
get_unaligned_be32(const u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST)
		return be32_bswap(load_u32_unaligned(p));
	else
		return ((u32)p[0] << 24) | ((u32)p[1] << 16) |
			((u32)p[2] << 8) | p[3];
}

static forceinline u64
get_unaligned_le64(const u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST)
		return le64_bswap(load_u64_unaligned(p));
	else
		return ((u64)p[7] << 56) | ((u64)p[6] << 48) |
			((u64)p[5] << 40) | ((u64)p[4] << 32) |
			((u64)p[3] << 24) | ((u64)p[2] << 16) |
			((u64)p[1] << 8) | p[0];
}

static forceinline machine_word_t
get_unaligned_leword(const u8 *p)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return get_unaligned_le32(p);
	else
		return get_unaligned_le64(p);
}



static forceinline void
put_unaligned_le16(u16 v, u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST) {
		store_u16_unaligned(le16_bswap(v), p);
	} else {
		p[0] = (u8)(v >> 0);
		p[1] = (u8)(v >> 8);
	}
}

static forceinline void
put_unaligned_be16(u16 v, u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST) {
		store_u16_unaligned(be16_bswap(v), p);
	} else {
		p[0] = (u8)(v >> 8);
		p[1] = (u8)(v >> 0);
	}
}

static forceinline void
put_unaligned_le32(u32 v, u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST) {
		store_u32_unaligned(le32_bswap(v), p);
	} else {
		p[0] = (u8)(v >> 0);
		p[1] = (u8)(v >> 8);
		p[2] = (u8)(v >> 16);
		p[3] = (u8)(v >> 24);
	}
}

static forceinline void
put_unaligned_be32(u32 v, u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST) {
		store_u32_unaligned(be32_bswap(v), p);
	} else {
		p[0] = (u8)(v >> 24);
		p[1] = (u8)(v >> 16);
		p[2] = (u8)(v >> 8);
		p[3] = (u8)(v >> 0);
	}
}

static forceinline void
put_unaligned_le64(u64 v, u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST) {
		store_u64_unaligned(le64_bswap(v), p);
	} else {
		p[0] = (u8)(v >> 0);
		p[1] = (u8)(v >> 8);
		p[2] = (u8)(v >> 16);
		p[3] = (u8)(v >> 24);
		p[4] = (u8)(v >> 32);
		p[5] = (u8)(v >> 40);
		p[6] = (u8)(v >> 48);
		p[7] = (u8)(v >> 56);
	}
}

static forceinline void
put_unaligned_leword(machine_word_t v, u8 *p)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		put_unaligned_le32(v, p);
	else
		put_unaligned_le64(v, p);
}




static forceinline u32
loaded_u32_to_u24(u32 v)
{
	if (CPU_IS_LITTLE_ENDIAN())
		return v & 0xFFFFFF;
	else
		return v >> 8;
}


static forceinline u32
load_u24_unaligned(const u8 *p)
{
#if UNALIGNED_ACCESS_IS_FAST
#  define LOAD_U24_REQUIRED_NBYTES 4
	return loaded_u32_to_u24(load_u32_unaligned(p));
#else
#  define LOAD_U24_REQUIRED_NBYTES 3
	if (CPU_IS_LITTLE_ENDIAN())
		return ((u32)p[0] << 0) | ((u32)p[1] << 8) | ((u32)p[2] << 16);
	else
		return ((u32)p[2] << 0) | ((u32)p[1] << 8) | ((u32)p[0] << 16);
#endif
}

#endif 


/* #include "libdeflate.h" */


#ifndef LIBDEFLATE_H
#define LIBDEFLATE_H

#ifdef __cplusplus
extern "C" {
#endif

#define LIBDEFLATE_VERSION_MAJOR	1
#define LIBDEFLATE_VERSION_MINOR	7
#define LIBDEFLATE_VERSION_STRING	"1.7"

#include <stddef.h>
#include <stdint.h>


#ifdef LIBDEFLATE_DLL
#  ifdef BUILDING_LIBDEFLATE
#    define LIBDEFLATEEXPORT	LIBEXPORT
#  elif defined(_WIN32) || defined(__CYGWIN__)
#    define LIBDEFLATEEXPORT	__declspec(dllimport)
#  endif
#endif
#ifndef LIBDEFLATEEXPORT
#  define LIBDEFLATEEXPORT
#endif

#if defined(_WIN32) && !defined(_WIN64)
#  define LIBDEFLATEAPI_ABI	__stdcall
#else
#  define LIBDEFLATEAPI_ABI
#endif

#if defined(BUILDING_LIBDEFLATE) && defined(__GNUC__) && \
	defined(_WIN32) && !defined(_WIN64)
    
#  define LIBDEFLATEAPI_STACKALIGN	__attribute__((force_align_arg_pointer))
#else
#  define LIBDEFLATEAPI_STACKALIGN
#endif

#define LIBDEFLATEAPI	LIBDEFLATEAPI_ABI LIBDEFLATEAPI_STACKALIGN





struct libdeflate_compressor;


LIBDEFLATEEXPORT struct libdeflate_compressor * LIBDEFLATEAPI
libdeflate_alloc_compressor(int compression_level);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_deflate_compress(struct libdeflate_compressor *compressor,
			    const void *in, size_t in_nbytes,
			    void *out, size_t out_nbytes_avail);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_deflate_compress_bound(struct libdeflate_compressor *compressor,
				  size_t in_nbytes);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_zlib_compress(struct libdeflate_compressor *compressor,
			 const void *in, size_t in_nbytes,
			 void *out, size_t out_nbytes_avail);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_zlib_compress_bound(struct libdeflate_compressor *compressor,
			       size_t in_nbytes);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_gzip_compress(struct libdeflate_compressor *compressor,
			 const void *in, size_t in_nbytes,
			 void *out, size_t out_nbytes_avail);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_gzip_compress_bound(struct libdeflate_compressor *compressor,
			       size_t in_nbytes);


LIBDEFLATEEXPORT void LIBDEFLATEAPI
libdeflate_free_compressor(struct libdeflate_compressor *compressor);





struct libdeflate_decompressor;


LIBDEFLATEEXPORT struct libdeflate_decompressor * LIBDEFLATEAPI
libdeflate_alloc_decompressor(void);


enum libdeflate_result {
	
	LIBDEFLATE_SUCCESS = 0,

	
	LIBDEFLATE_BAD_DATA = 1,

	
	LIBDEFLATE_SHORT_OUTPUT = 2,

	
	LIBDEFLATE_INSUFFICIENT_SPACE = 3,
};


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_deflate_decompress(struct libdeflate_decompressor *decompressor,
			      const void *in, size_t in_nbytes,
			      void *out, size_t out_nbytes_avail,
			      size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_deflate_decompress_ex(struct libdeflate_decompressor *decompressor,
				 const void *in, size_t in_nbytes,
				 void *out, size_t out_nbytes_avail,
				 size_t *actual_in_nbytes_ret,
				 size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_zlib_decompress(struct libdeflate_decompressor *decompressor,
			   const void *in, size_t in_nbytes,
			   void *out, size_t out_nbytes_avail,
			   size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_zlib_decompress_ex(struct libdeflate_decompressor *decompressor,
			      const void *in, size_t in_nbytes,
			      void *out, size_t out_nbytes_avail,
			      size_t *actual_in_nbytes_ret,
			      size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_gzip_decompress(struct libdeflate_decompressor *decompressor,
			   const void *in, size_t in_nbytes,
			   void *out, size_t out_nbytes_avail,
			   size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_gzip_decompress_ex(struct libdeflate_decompressor *decompressor,
			      const void *in, size_t in_nbytes,
			      void *out, size_t out_nbytes_avail,
			      size_t *actual_in_nbytes_ret,
			      size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT void LIBDEFLATEAPI
libdeflate_free_decompressor(struct libdeflate_decompressor *decompressor);






LIBDEFLATEEXPORT uint32_t LIBDEFLATEAPI
libdeflate_adler32(uint32_t adler, const void *buffer, size_t len);



LIBDEFLATEEXPORT uint32_t LIBDEFLATEAPI
libdeflate_crc32(uint32_t crc, const void *buffer, size_t len);






LIBDEFLATEEXPORT void LIBDEFLATEAPI
libdeflate_set_memory_allocator(void *(*malloc_func)(size_t),
				void (*free_func)(void *));

#ifdef __cplusplus
}
#endif

#endif 



#define SUPPORT_NEAR_OPTIMAL_PARSING 1


#define USE_FULL_OFFSET_SLOT_FAST	SUPPORT_NEAR_OPTIMAL_PARSING


#define MATCHFINDER_WINDOW_ORDER	15

/* #include "hc_matchfinder.h" */


/* #include "matchfinder_common.h" */


#ifndef LIB_MATCHFINDER_COMMON_H
#define LIB_MATCHFINDER_COMMON_H

/* #include "lib_common.h" */


#ifndef LIB_LIB_COMMON_H
#define LIB_LIB_COMMON_H

#ifdef LIBDEFLATE_H
#  error "lib_common.h must always be included before libdeflate.h"
   
#endif

#define BUILDING_LIBDEFLATE

/* #include "../common/common_defs.h" */


#ifndef COMMON_COMMON_DEFS_H
#define COMMON_COMMON_DEFS_H

#ifdef __GNUC__
/* #  include "compiler_gcc.h" */


#if !defined(__clang__) && !defined(__INTEL_COMPILER)
#  define GCC_PREREQ(major, minor)		\
	(__GNUC__ > (major) ||			\
	 (__GNUC__ == (major) && __GNUC_MINOR__ >= (minor)))
#else
#  define GCC_PREREQ(major, minor)	0
#endif


#ifdef __clang__
#  ifdef __apple_build_version__
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__apple_build_version__ >= (apple_version))
#  else
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__clang_major__ > (major) ||			\
	 (__clang_major__ == (major) && __clang_minor__ >= (minor)))
#  endif
#else
#  define CLANG_PREREQ(major, minor, apple_version)	0
#endif

#ifndef __has_attribute
#  define __has_attribute(attribute)	0
#endif
#ifndef __has_feature
#  define __has_feature(feature)	0
#endif
#ifndef __has_builtin
#  define __has_builtin(builtin)	0
#endif

#ifdef _WIN32
#  define LIBEXPORT __declspec(dllexport)
#else
#  define LIBEXPORT __attribute__((visibility("default")))
#endif

#define inline			inline
#define forceinline		inline __attribute__((always_inline))
#define restrict		__restrict__
#define likely(expr)		__builtin_expect(!!(expr), 1)
#define unlikely(expr)		__builtin_expect(!!(expr), 0)
#define prefetchr(addr)		__builtin_prefetch((addr), 0)
#define prefetchw(addr)		__builtin_prefetch((addr), 1)
#define _aligned_attribute(n)	__attribute__((aligned(n)))

#define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE	\
	(GCC_PREREQ(4, 4) || __has_attribute(target))

#if COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE

#  if defined(__i386__) || defined(__x86_64__)

#    define COMPILER_SUPPORTS_PCLMUL_TARGET	\
	(GCC_PREREQ(4, 4) || __has_builtin(__builtin_ia32_pclmulqdq128))

#    define COMPILER_SUPPORTS_AVX_TARGET	\
	(GCC_PREREQ(4, 6) || __has_builtin(__builtin_ia32_maxps256))

#    define COMPILER_SUPPORTS_BMI2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_pdep_di))

#    define COMPILER_SUPPORTS_AVX2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_psadbw256))

#    define COMPILER_SUPPORTS_AVX512BW_TARGET	\
	(GCC_PREREQ(5, 1) || __has_builtin(__builtin_ia32_psadbw512))

	
#    if GCC_PREREQ(4, 9) || CLANG_PREREQ(3, 8, 7030000)
#      define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS	1
#      define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_PCLMUL_TARGET
#      define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX2_TARGET
#      define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX512BW_TARGET
#    endif

#  elif defined(__arm__) || defined(__aarch64__)

    
#    if (GCC_PREREQ(6, 1) && defined(__ARM_FP)) || \
        (defined(__clang__) && defined(__ARM_NEON))
#      define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 1
       
#      if defined(__clang__) && defined(__arm__)
#        undef __ARM_FEATURE_CRYPTO
#      elif __has_builtin(__builtin_neon_vmull_p64) || !defined(__clang__)
#        define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 1
#      endif
#    endif

     
#    if GCC_PREREQ(10, 1) || \
        (GCC_PREREQ(9, 3) && !GCC_PREREQ(10, 0)) || \
        (GCC_PREREQ(8, 4) && !GCC_PREREQ(9, 0)) || \
        (defined(__clang__) && __has_builtin(__builtin_arm_crc32b))
#      define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 1
#    endif

#  endif 

#endif 


#if (GCC_PREREQ(4, 0) && !GCC_PREREQ(5, 1)) || \
    (defined(__clang__) && !CLANG_PREREQ(3, 9, 8020000))
typedef unsigned long long  __v2du __attribute__((__vector_size__(16)));
typedef unsigned int        __v4su __attribute__((__vector_size__(16)));
typedef unsigned short      __v8hu __attribute__((__vector_size__(16)));
typedef unsigned char      __v16qu __attribute__((__vector_size__(16)));
typedef unsigned long long  __v4du __attribute__((__vector_size__(32)));
typedef unsigned int        __v8su __attribute__((__vector_size__(32)));
typedef unsigned short     __v16hu __attribute__((__vector_size__(32)));
typedef unsigned char      __v32qu __attribute__((__vector_size__(32)));
#endif


#ifdef __BYTE_ORDER__
#  define CPU_IS_LITTLE_ENDIAN() (__BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__)
#endif

#if GCC_PREREQ(4, 8) || __has_builtin(__builtin_bswap16)
#  define bswap16	__builtin_bswap16
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap32)
#  define bswap32	__builtin_bswap32
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap64)
#  define bswap64	__builtin_bswap64
#endif

#if defined(__x86_64__) || defined(__i386__) || defined(__ARM_FEATURE_UNALIGNED) || defined(__powerpc64__)
#  define UNALIGNED_ACCESS_IS_FAST 1
#endif

#define bsr32(n)	(31 - __builtin_clz(n))
#define bsr64(n)	(63 - __builtin_clzll(n))
#define bsf32(n)	__builtin_ctz(n)
#define bsf64(n)	__builtin_ctzll(n)

#elif defined(_MSC_VER)
/* #  include "compiler_msc.h" */


#include <stdint.h>
#include <stdlib.h> 

#define LIBEXPORT	__declspec(dllexport)


typedef int bool;
#define true 1
#define false 0
#define __bool_true_false_are_defined 1


#ifdef _WIN64
typedef long long ssize_t;
#else
typedef int ssize_t;
#endif


#define CPU_IS_LITTLE_ENDIAN()		1
#define UNALIGNED_ACCESS_IS_FAST	1


#define restrict


#define inline		__inline
#define forceinline	__forceinline


#define bswap16	_byteswap_ushort
#define bswap32	_byteswap_ulong
#define bswap64	_byteswap_uint64



static forceinline unsigned
bsr32(uint32_t n)
{
	_BitScanReverse(&n, n);
	return n;
}
#define bsr32 bsr32

static forceinline unsigned
bsf32(uint32_t n)
{
	_BitScanForward(&n, n);
	return n;
}
#define bsf32 bsf32

#ifdef _M_X64 

static forceinline unsigned
bsr64(uint64_t n)
{
	_BitScanReverse64(&n, n);
	return n;
}
#define bsr64 bsr64

static forceinline unsigned
bsf64(uint64_t n)
{
	_BitScanForward64(&n, n);
	return n;
}
#define bsf64 bsf64

#endif 

#else
#  pragma message("Unrecognized compiler.  Please add a header file for your compiler.  Compilation will proceed, but performance may suffer!")
#endif





#include <stddef.h> 

#ifndef __bool_true_false_are_defined
#  include <stdbool.h> 
#endif


#include <stdint.h>
typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
typedef int8_t s8;
typedef int16_t s16;
typedef int32_t s32;
typedef int64_t s64;


typedef size_t machine_word_t;


#define WORDBYTES	((int)sizeof(machine_word_t))


#define WORDBITS	(8 * WORDBYTES)






#ifndef LIBEXPORT
#  define LIBEXPORT
#endif


#ifndef inline
#  define inline
#endif


#ifndef forceinline
#  define forceinline inline
#endif


#ifndef restrict
#  define restrict
#endif


#ifndef likely
#  define likely(expr)		(expr)
#endif


#ifndef unlikely
#  define unlikely(expr)	(expr)
#endif


#ifndef prefetchr
#  define prefetchr(addr)
#endif


#ifndef prefetchw
#  define prefetchw(addr)
#endif


#ifndef COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE
#  define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE 0
#endif


#ifndef COMPILER_SUPPORTS_BMI2_TARGET
#  define COMPILER_SUPPORTS_BMI2_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX_TARGET
#  define COMPILER_SUPPORTS_AVX_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET
#  define COMPILER_SUPPORTS_AVX512BW_TARGET 0
#endif


#ifndef COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 0
#endif


#ifndef _aligned_attribute
#endif





#define ARRAY_LEN(A)		(sizeof(A) / sizeof((A)[0]))
#define MIN(a, b)		((a) <= (b) ? (a) : (b))
#define MAX(a, b)		((a) >= (b) ? (a) : (b))
#define DIV_ROUND_UP(n, d)	(((n) + (d) - 1) / (d))
#define STATIC_ASSERT(expr)	((void)sizeof(char[1 - 2 * !(expr)]))
#define ALIGN(n, a)		(((n) + (a) - 1) & ~((a) - 1))






#ifndef CPU_IS_LITTLE_ENDIAN
static forceinline int CPU_IS_LITTLE_ENDIAN(void)
{
	union {
		unsigned int v;
		unsigned char b;
	} u;
	u.v = 1;
	return u.b;
}
#endif


#ifndef bswap16
static forceinline u16 bswap16(u16 n)
{
	return (n << 8) | (n >> 8);
}
#endif


#ifndef bswap32
static forceinline u32 bswap32(u32 n)
{
	return ((n & 0x000000FF) << 24) |
	       ((n & 0x0000FF00) << 8) |
	       ((n & 0x00FF0000) >> 8) |
	       ((n & 0xFF000000) >> 24);
}
#endif


#ifndef bswap64
static forceinline u64 bswap64(u64 n)
{
	return ((n & 0x00000000000000FF) << 56) |
	       ((n & 0x000000000000FF00) << 40) |
	       ((n & 0x0000000000FF0000) << 24) |
	       ((n & 0x00000000FF000000) << 8) |
	       ((n & 0x000000FF00000000) >> 8) |
	       ((n & 0x0000FF0000000000) >> 24) |
	       ((n & 0x00FF000000000000) >> 40) |
	       ((n & 0xFF00000000000000) >> 56);
}
#endif

#define le16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap16(n))
#define le32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap32(n))
#define le64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap64(n))
#define be16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap16(n) : (n))
#define be32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap32(n) : (n))
#define be64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap64(n) : (n))






#ifndef UNALIGNED_ACCESS_IS_FAST
#  define UNALIGNED_ACCESS_IS_FAST 0
#endif







#ifndef bsr32
static forceinline unsigned
bsr32(u32 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

#ifndef bsr64
static forceinline unsigned
bsr64(u64 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

static forceinline unsigned
bsrw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsr32(n);
	else
		return bsr64(n);
}



#ifndef bsf32
static forceinline unsigned
bsf32(u32 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

#ifndef bsf64
static forceinline unsigned
bsf64(u64 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

static forceinline unsigned
bsfw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsf32(n);
	else
		return bsf64(n);
}

#endif 



#define SYM_FIXUP(sym)			_libdeflate_##sym
#define deflate_get_compression_level	SYM_FIXUP(deflate_get_compression_level)
#define _cpu_features			SYM_FIXUP(_cpu_features)
#define setup_cpu_features		SYM_FIXUP(setup_cpu_features)

void *libdeflate_malloc(size_t size);
void libdeflate_free(void *ptr);

void *libdeflate_aligned_malloc(size_t alignment, size_t size);
void libdeflate_aligned_free(void *ptr);

#ifdef FREESTANDING

void *memset(void *s, int c, size_t n);
#define memset(s, c, n)		__builtin_memset((s), (c), (n))

void *memcpy(void *dest, const void *src, size_t n);
#define memcpy(dest, src, n)	__builtin_memcpy((dest), (src), (n))

void *memmove(void *dest, const void *src, size_t n);
#define memmove(dest, src, n)	__builtin_memmove((dest), (src), (n))

int memcmp(const void *s1, const void *s2, size_t n);
#define memcmp(s1, s2, n)	__builtin_memcmp((s1), (s2), (n))
#else
#include <string.h>
#endif

#endif 

/* #include "unaligned.h" */


#ifndef LIB_UNALIGNED_H
#define LIB_UNALIGNED_H

/* #include "lib_common.h" */


#ifndef LIB_LIB_COMMON_H
#define LIB_LIB_COMMON_H

#ifdef LIBDEFLATE_H
#  error "lib_common.h must always be included before libdeflate.h"
   
#endif

#define BUILDING_LIBDEFLATE

/* #include "../common/common_defs.h" */


#ifndef COMMON_COMMON_DEFS_H
#define COMMON_COMMON_DEFS_H

#ifdef __GNUC__
/* #  include "compiler_gcc.h" */


#if !defined(__clang__) && !defined(__INTEL_COMPILER)
#  define GCC_PREREQ(major, minor)		\
	(__GNUC__ > (major) ||			\
	 (__GNUC__ == (major) && __GNUC_MINOR__ >= (minor)))
#else
#  define GCC_PREREQ(major, minor)	0
#endif


#ifdef __clang__
#  ifdef __apple_build_version__
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__apple_build_version__ >= (apple_version))
#  else
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__clang_major__ > (major) ||			\
	 (__clang_major__ == (major) && __clang_minor__ >= (minor)))
#  endif
#else
#  define CLANG_PREREQ(major, minor, apple_version)	0
#endif

#ifndef __has_attribute
#  define __has_attribute(attribute)	0
#endif
#ifndef __has_feature
#  define __has_feature(feature)	0
#endif
#ifndef __has_builtin
#  define __has_builtin(builtin)	0
#endif

#ifdef _WIN32
#  define LIBEXPORT __declspec(dllexport)
#else
#  define LIBEXPORT __attribute__((visibility("default")))
#endif

#define inline			inline
#define forceinline		inline __attribute__((always_inline))
#define restrict		__restrict__
#define likely(expr)		__builtin_expect(!!(expr), 1)
#define unlikely(expr)		__builtin_expect(!!(expr), 0)
#define prefetchr(addr)		__builtin_prefetch((addr), 0)
#define prefetchw(addr)		__builtin_prefetch((addr), 1)
#define _aligned_attribute(n)	__attribute__((aligned(n)))

#define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE	\
	(GCC_PREREQ(4, 4) || __has_attribute(target))

#if COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE

#  if defined(__i386__) || defined(__x86_64__)

#    define COMPILER_SUPPORTS_PCLMUL_TARGET	\
	(GCC_PREREQ(4, 4) || __has_builtin(__builtin_ia32_pclmulqdq128))

#    define COMPILER_SUPPORTS_AVX_TARGET	\
	(GCC_PREREQ(4, 6) || __has_builtin(__builtin_ia32_maxps256))

#    define COMPILER_SUPPORTS_BMI2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_pdep_di))

#    define COMPILER_SUPPORTS_AVX2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_psadbw256))

#    define COMPILER_SUPPORTS_AVX512BW_TARGET	\
	(GCC_PREREQ(5, 1) || __has_builtin(__builtin_ia32_psadbw512))

	
#    if GCC_PREREQ(4, 9) || CLANG_PREREQ(3, 8, 7030000)
#      define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS	1
#      define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_PCLMUL_TARGET
#      define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX2_TARGET
#      define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX512BW_TARGET
#    endif

#  elif defined(__arm__) || defined(__aarch64__)

    
#    if (GCC_PREREQ(6, 1) && defined(__ARM_FP)) || \
        (defined(__clang__) && defined(__ARM_NEON))
#      define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 1
       
#      if defined(__clang__) && defined(__arm__)
#        undef __ARM_FEATURE_CRYPTO
#      elif __has_builtin(__builtin_neon_vmull_p64) || !defined(__clang__)
#        define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 1
#      endif
#    endif

     
#    if GCC_PREREQ(10, 1) || \
        (GCC_PREREQ(9, 3) && !GCC_PREREQ(10, 0)) || \
        (GCC_PREREQ(8, 4) && !GCC_PREREQ(9, 0)) || \
        (defined(__clang__) && __has_builtin(__builtin_arm_crc32b))
#      define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 1
#    endif

#  endif 

#endif 


#if (GCC_PREREQ(4, 0) && !GCC_PREREQ(5, 1)) || \
    (defined(__clang__) && !CLANG_PREREQ(3, 9, 8020000))
typedef unsigned long long  __v2du __attribute__((__vector_size__(16)));
typedef unsigned int        __v4su __attribute__((__vector_size__(16)));
typedef unsigned short      __v8hu __attribute__((__vector_size__(16)));
typedef unsigned char      __v16qu __attribute__((__vector_size__(16)));
typedef unsigned long long  __v4du __attribute__((__vector_size__(32)));
typedef unsigned int        __v8su __attribute__((__vector_size__(32)));
typedef unsigned short     __v16hu __attribute__((__vector_size__(32)));
typedef unsigned char      __v32qu __attribute__((__vector_size__(32)));
#endif


#ifdef __BYTE_ORDER__
#  define CPU_IS_LITTLE_ENDIAN() (__BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__)
#endif

#if GCC_PREREQ(4, 8) || __has_builtin(__builtin_bswap16)
#  define bswap16	__builtin_bswap16
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap32)
#  define bswap32	__builtin_bswap32
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap64)
#  define bswap64	__builtin_bswap64
#endif

#if defined(__x86_64__) || defined(__i386__) || defined(__ARM_FEATURE_UNALIGNED) || defined(__powerpc64__)
#  define UNALIGNED_ACCESS_IS_FAST 1
#endif

#define bsr32(n)	(31 - __builtin_clz(n))
#define bsr64(n)	(63 - __builtin_clzll(n))
#define bsf32(n)	__builtin_ctz(n)
#define bsf64(n)	__builtin_ctzll(n)

#elif defined(_MSC_VER)
/* #  include "compiler_msc.h" */


#include <stdint.h>
#include <stdlib.h> 

#define LIBEXPORT	__declspec(dllexport)


typedef int bool;
#define true 1
#define false 0
#define __bool_true_false_are_defined 1


#ifdef _WIN64
typedef long long ssize_t;
#else
typedef int ssize_t;
#endif


#define CPU_IS_LITTLE_ENDIAN()		1
#define UNALIGNED_ACCESS_IS_FAST	1


#define restrict


#define inline		__inline
#define forceinline	__forceinline


#define bswap16	_byteswap_ushort
#define bswap32	_byteswap_ulong
#define bswap64	_byteswap_uint64



static forceinline unsigned
bsr32(uint32_t n)
{
	_BitScanReverse(&n, n);
	return n;
}
#define bsr32 bsr32

static forceinline unsigned
bsf32(uint32_t n)
{
	_BitScanForward(&n, n);
	return n;
}
#define bsf32 bsf32

#ifdef _M_X64 

static forceinline unsigned
bsr64(uint64_t n)
{
	_BitScanReverse64(&n, n);
	return n;
}
#define bsr64 bsr64

static forceinline unsigned
bsf64(uint64_t n)
{
	_BitScanForward64(&n, n);
	return n;
}
#define bsf64 bsf64

#endif 

#else
#  pragma message("Unrecognized compiler.  Please add a header file for your compiler.  Compilation will proceed, but performance may suffer!")
#endif





#include <stddef.h> 

#ifndef __bool_true_false_are_defined
#  include <stdbool.h> 
#endif


#include <stdint.h>
typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
typedef int8_t s8;
typedef int16_t s16;
typedef int32_t s32;
typedef int64_t s64;


typedef size_t machine_word_t;


#define WORDBYTES	((int)sizeof(machine_word_t))


#define WORDBITS	(8 * WORDBYTES)






#ifndef LIBEXPORT
#  define LIBEXPORT
#endif


#ifndef inline
#  define inline
#endif


#ifndef forceinline
#  define forceinline inline
#endif


#ifndef restrict
#  define restrict
#endif


#ifndef likely
#  define likely(expr)		(expr)
#endif


#ifndef unlikely
#  define unlikely(expr)	(expr)
#endif


#ifndef prefetchr
#  define prefetchr(addr)
#endif


#ifndef prefetchw
#  define prefetchw(addr)
#endif


#ifndef COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE
#  define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE 0
#endif


#ifndef COMPILER_SUPPORTS_BMI2_TARGET
#  define COMPILER_SUPPORTS_BMI2_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX_TARGET
#  define COMPILER_SUPPORTS_AVX_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET
#  define COMPILER_SUPPORTS_AVX512BW_TARGET 0
#endif


#ifndef COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 0
#endif


#ifndef _aligned_attribute
#endif





#define ARRAY_LEN(A)		(sizeof(A) / sizeof((A)[0]))
#define MIN(a, b)		((a) <= (b) ? (a) : (b))
#define MAX(a, b)		((a) >= (b) ? (a) : (b))
#define DIV_ROUND_UP(n, d)	(((n) + (d) - 1) / (d))
#define STATIC_ASSERT(expr)	((void)sizeof(char[1 - 2 * !(expr)]))
#define ALIGN(n, a)		(((n) + (a) - 1) & ~((a) - 1))






#ifndef CPU_IS_LITTLE_ENDIAN
static forceinline int CPU_IS_LITTLE_ENDIAN(void)
{
	union {
		unsigned int v;
		unsigned char b;
	} u;
	u.v = 1;
	return u.b;
}
#endif


#ifndef bswap16
static forceinline u16 bswap16(u16 n)
{
	return (n << 8) | (n >> 8);
}
#endif


#ifndef bswap32
static forceinline u32 bswap32(u32 n)
{
	return ((n & 0x000000FF) << 24) |
	       ((n & 0x0000FF00) << 8) |
	       ((n & 0x00FF0000) >> 8) |
	       ((n & 0xFF000000) >> 24);
}
#endif


#ifndef bswap64
static forceinline u64 bswap64(u64 n)
{
	return ((n & 0x00000000000000FF) << 56) |
	       ((n & 0x000000000000FF00) << 40) |
	       ((n & 0x0000000000FF0000) << 24) |
	       ((n & 0x00000000FF000000) << 8) |
	       ((n & 0x000000FF00000000) >> 8) |
	       ((n & 0x0000FF0000000000) >> 24) |
	       ((n & 0x00FF000000000000) >> 40) |
	       ((n & 0xFF00000000000000) >> 56);
}
#endif

#define le16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap16(n))
#define le32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap32(n))
#define le64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap64(n))
#define be16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap16(n) : (n))
#define be32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap32(n) : (n))
#define be64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap64(n) : (n))






#ifndef UNALIGNED_ACCESS_IS_FAST
#  define UNALIGNED_ACCESS_IS_FAST 0
#endif







#ifndef bsr32
static forceinline unsigned
bsr32(u32 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

#ifndef bsr64
static forceinline unsigned
bsr64(u64 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

static forceinline unsigned
bsrw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsr32(n);
	else
		return bsr64(n);
}



#ifndef bsf32
static forceinline unsigned
bsf32(u32 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

#ifndef bsf64
static forceinline unsigned
bsf64(u64 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

static forceinline unsigned
bsfw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsf32(n);
	else
		return bsf64(n);
}

#endif 



#define SYM_FIXUP(sym)			_libdeflate_##sym
#define deflate_get_compression_level	SYM_FIXUP(deflate_get_compression_level)
#define _cpu_features			SYM_FIXUP(_cpu_features)
#define setup_cpu_features		SYM_FIXUP(setup_cpu_features)

void *libdeflate_malloc(size_t size);
void libdeflate_free(void *ptr);

void *libdeflate_aligned_malloc(size_t alignment, size_t size);
void libdeflate_aligned_free(void *ptr);

#ifdef FREESTANDING

void *memset(void *s, int c, size_t n);
#define memset(s, c, n)		__builtin_memset((s), (c), (n))

void *memcpy(void *dest, const void *src, size_t n);
#define memcpy(dest, src, n)	__builtin_memcpy((dest), (src), (n))

void *memmove(void *dest, const void *src, size_t n);
#define memmove(dest, src, n)	__builtin_memmove((dest), (src), (n))

int memcmp(const void *s1, const void *s2, size_t n);
#define memcmp(s1, s2, n)	__builtin_memcmp((s1), (s2), (n))
#else
#include <string.h>
#endif

#endif 






#define DEFINE_UNALIGNED_TYPE(type)				\
static forceinline type						\
load_##type##_unaligned(const void *p)				\
{								\
	type v;							\
	memcpy(&v, p, sizeof(v));				\
	return v;						\
}								\
								\
static forceinline void						\
store_##type##_unaligned(type v, void *p)			\
{								\
	memcpy(p, &v, sizeof(v));				\
}

DEFINE_UNALIGNED_TYPE(u16)
DEFINE_UNALIGNED_TYPE(u32)
DEFINE_UNALIGNED_TYPE(u64)
DEFINE_UNALIGNED_TYPE(machine_word_t)

#define load_word_unaligned	load_machine_word_t_unaligned
#define store_word_unaligned	store_machine_word_t_unaligned



static forceinline u16
get_unaligned_le16(const u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST)
		return le16_bswap(load_u16_unaligned(p));
	else
		return ((u16)p[1] << 8) | p[0];
}

static forceinline u16
get_unaligned_be16(const u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST)
		return be16_bswap(load_u16_unaligned(p));
	else
		return ((u16)p[0] << 8) | p[1];
}

static forceinline u32
get_unaligned_le32(const u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST)
		return le32_bswap(load_u32_unaligned(p));
	else
		return ((u32)p[3] << 24) | ((u32)p[2] << 16) |
			((u32)p[1] << 8) | p[0];
}

static forceinline u32
get_unaligned_be32(const u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST)
		return be32_bswap(load_u32_unaligned(p));
	else
		return ((u32)p[0] << 24) | ((u32)p[1] << 16) |
			((u32)p[2] << 8) | p[3];
}

static forceinline u64
get_unaligned_le64(const u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST)
		return le64_bswap(load_u64_unaligned(p));
	else
		return ((u64)p[7] << 56) | ((u64)p[6] << 48) |
			((u64)p[5] << 40) | ((u64)p[4] << 32) |
			((u64)p[3] << 24) | ((u64)p[2] << 16) |
			((u64)p[1] << 8) | p[0];
}

static forceinline machine_word_t
get_unaligned_leword(const u8 *p)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return get_unaligned_le32(p);
	else
		return get_unaligned_le64(p);
}



static forceinline void
put_unaligned_le16(u16 v, u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST) {
		store_u16_unaligned(le16_bswap(v), p);
	} else {
		p[0] = (u8)(v >> 0);
		p[1] = (u8)(v >> 8);
	}
}

static forceinline void
put_unaligned_be16(u16 v, u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST) {
		store_u16_unaligned(be16_bswap(v), p);
	} else {
		p[0] = (u8)(v >> 8);
		p[1] = (u8)(v >> 0);
	}
}

static forceinline void
put_unaligned_le32(u32 v, u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST) {
		store_u32_unaligned(le32_bswap(v), p);
	} else {
		p[0] = (u8)(v >> 0);
		p[1] = (u8)(v >> 8);
		p[2] = (u8)(v >> 16);
		p[3] = (u8)(v >> 24);
	}
}

static forceinline void
put_unaligned_be32(u32 v, u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST) {
		store_u32_unaligned(be32_bswap(v), p);
	} else {
		p[0] = (u8)(v >> 24);
		p[1] = (u8)(v >> 16);
		p[2] = (u8)(v >> 8);
		p[3] = (u8)(v >> 0);
	}
}

static forceinline void
put_unaligned_le64(u64 v, u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST) {
		store_u64_unaligned(le64_bswap(v), p);
	} else {
		p[0] = (u8)(v >> 0);
		p[1] = (u8)(v >> 8);
		p[2] = (u8)(v >> 16);
		p[3] = (u8)(v >> 24);
		p[4] = (u8)(v >> 32);
		p[5] = (u8)(v >> 40);
		p[6] = (u8)(v >> 48);
		p[7] = (u8)(v >> 56);
	}
}

static forceinline void
put_unaligned_leword(machine_word_t v, u8 *p)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		put_unaligned_le32(v, p);
	else
		put_unaligned_le64(v, p);
}




static forceinline u32
loaded_u32_to_u24(u32 v)
{
	if (CPU_IS_LITTLE_ENDIAN())
		return v & 0xFFFFFF;
	else
		return v >> 8;
}


static forceinline u32
load_u24_unaligned(const u8 *p)
{
#if UNALIGNED_ACCESS_IS_FAST
#  define LOAD_U24_REQUIRED_NBYTES 4
	return loaded_u32_to_u24(load_u32_unaligned(p));
#else
#  define LOAD_U24_REQUIRED_NBYTES 3
	if (CPU_IS_LITTLE_ENDIAN())
		return ((u32)p[0] << 0) | ((u32)p[1] << 8) | ((u32)p[2] << 16);
	else
		return ((u32)p[2] << 0) | ((u32)p[1] << 8) | ((u32)p[0] << 16);
#endif
}

#endif 


#ifndef MATCHFINDER_WINDOW_ORDER
#  error "MATCHFINDER_WINDOW_ORDER must be defined!"
#endif

#define MATCHFINDER_WINDOW_SIZE (1UL << MATCHFINDER_WINDOW_ORDER)

typedef s16 mf_pos_t;

#define MATCHFINDER_INITVAL ((mf_pos_t)-MATCHFINDER_WINDOW_SIZE)


#define MATCHFINDER_MEM_ALIGNMENT	32
#define MATCHFINDER_SIZE_ALIGNMENT	128

#undef matchfinder_init
#undef matchfinder_rebase
#ifdef _aligned_attribute
#  if defined(__arm__) || defined(__aarch64__)
/* #    include "arm/matchfinder_impl.h" */


#ifdef __ARM_NEON
#  include <arm_neon.h>
static forceinline void
matchfinder_init_neon(mf_pos_t *data, size_t size)
{
	int16x8_t *p = (int16x8_t *)data;
	int16x8_t v = (int16x8_t) {
		MATCHFINDER_INITVAL, MATCHFINDER_INITVAL, MATCHFINDER_INITVAL,
		MATCHFINDER_INITVAL, MATCHFINDER_INITVAL, MATCHFINDER_INITVAL,
		MATCHFINDER_INITVAL, MATCHFINDER_INITVAL,
	};

	STATIC_ASSERT(MATCHFINDER_MEM_ALIGNMENT % sizeof(*p) == 0);
	STATIC_ASSERT(MATCHFINDER_SIZE_ALIGNMENT % (4 * sizeof(*p)) == 0);
	STATIC_ASSERT(sizeof(mf_pos_t) == 2);

	do {
		p[0] = v;
		p[1] = v;
		p[2] = v;
		p[3] = v;
		p += 4;
		size -= 4 * sizeof(*p);
	} while (size != 0);
}
#define matchfinder_init matchfinder_init_neon

static forceinline void
matchfinder_rebase_neon(mf_pos_t *data, size_t size)
{
	int16x8_t *p = (int16x8_t *)data;
	int16x8_t v = (int16x8_t) {
		(u16)-MATCHFINDER_WINDOW_SIZE, (u16)-MATCHFINDER_WINDOW_SIZE,
		(u16)-MATCHFINDER_WINDOW_SIZE, (u16)-MATCHFINDER_WINDOW_SIZE,
		(u16)-MATCHFINDER_WINDOW_SIZE, (u16)-MATCHFINDER_WINDOW_SIZE,
		(u16)-MATCHFINDER_WINDOW_SIZE, (u16)-MATCHFINDER_WINDOW_SIZE,
	};

	STATIC_ASSERT(MATCHFINDER_MEM_ALIGNMENT % sizeof(*p) == 0);
	STATIC_ASSERT(MATCHFINDER_SIZE_ALIGNMENT % (4 * sizeof(*p)) == 0);
	STATIC_ASSERT(sizeof(mf_pos_t) == 2);

	do {
		p[0] = vqaddq_s16(p[0], v);
		p[1] = vqaddq_s16(p[1], v);
		p[2] = vqaddq_s16(p[2], v);
		p[3] = vqaddq_s16(p[3], v);
		p += 4;
		size -= 4 * sizeof(*p);
	} while (size != 0);
}
#define matchfinder_rebase matchfinder_rebase_neon

#endif 

#  elif defined(__i386__) || defined(__x86_64__)
/* #    include "x86/matchfinder_impl.h" */


#ifdef __AVX2__
#  include <immintrin.h>
static forceinline void
matchfinder_init_avx2(mf_pos_t *data, size_t size)
{
	__m256i *p = (__m256i *)data;
	__m256i v = _mm256_set1_epi16(MATCHFINDER_INITVAL);

	STATIC_ASSERT(MATCHFINDER_MEM_ALIGNMENT % sizeof(*p) == 0);
	STATIC_ASSERT(MATCHFINDER_SIZE_ALIGNMENT % (4 * sizeof(*p)) == 0);
	STATIC_ASSERT(sizeof(mf_pos_t) == 2);

	do {
		p[0] = v;
		p[1] = v;
		p[2] = v;
		p[3] = v;
		p += 4;
		size -= 4 * sizeof(*p);
	} while (size != 0);
}
#define matchfinder_init matchfinder_init_avx2

static forceinline void
matchfinder_rebase_avx2(mf_pos_t *data, size_t size)
{
	__m256i *p = (__m256i *)data;
	__m256i v = _mm256_set1_epi16((u16)-MATCHFINDER_WINDOW_SIZE);

	STATIC_ASSERT(MATCHFINDER_MEM_ALIGNMENT % sizeof(*p) == 0);
	STATIC_ASSERT(MATCHFINDER_SIZE_ALIGNMENT % (4 * sizeof(*p)) == 0);
	STATIC_ASSERT(sizeof(mf_pos_t) == 2);

	do {
		
		p[0] = _mm256_adds_epi16(p[0], v);
		p[1] = _mm256_adds_epi16(p[1], v);
		p[2] = _mm256_adds_epi16(p[2], v);
		p[3] = _mm256_adds_epi16(p[3], v);
		p += 4;
		size -= 4 * sizeof(*p);
	} while (size != 0);
}
#define matchfinder_rebase matchfinder_rebase_avx2

#elif defined(__SSE2__)
#  include <emmintrin.h>
static forceinline void
matchfinder_init_sse2(mf_pos_t *data, size_t size)
{
	__m128i *p = (__m128i *)data;
	__m128i v = _mm_set1_epi16(MATCHFINDER_INITVAL);

	STATIC_ASSERT(MATCHFINDER_MEM_ALIGNMENT % sizeof(*p) == 0);
	STATIC_ASSERT(MATCHFINDER_SIZE_ALIGNMENT % (4 * sizeof(*p)) == 0);
	STATIC_ASSERT(sizeof(mf_pos_t) == 2);

	do {
		p[0] = v;
		p[1] = v;
		p[2] = v;
		p[3] = v;
		p += 4;
		size -= 4 * sizeof(*p);
	} while (size != 0);
}
#define matchfinder_init matchfinder_init_sse2

static forceinline void
matchfinder_rebase_sse2(mf_pos_t *data, size_t size)
{
	__m128i *p = (__m128i *)data;
	__m128i v = _mm_set1_epi16((u16)-MATCHFINDER_WINDOW_SIZE);

	STATIC_ASSERT(MATCHFINDER_MEM_ALIGNMENT % sizeof(*p) == 0);
	STATIC_ASSERT(MATCHFINDER_SIZE_ALIGNMENT % (4 * sizeof(*p)) == 0);
	STATIC_ASSERT(sizeof(mf_pos_t) == 2);

	do {
		
		p[0] = _mm_adds_epi16(p[0], v);
		p[1] = _mm_adds_epi16(p[1], v);
		p[2] = _mm_adds_epi16(p[2], v);
		p[3] = _mm_adds_epi16(p[3], v);
		p += 4;
		size -= 4 * sizeof(*p);
	} while (size != 0);
}
#define matchfinder_rebase matchfinder_rebase_sse2
#endif 

#  endif
#endif


#ifndef matchfinder_init
static forceinline void
matchfinder_init(mf_pos_t *data, size_t size)
{
	size_t num_entries = size / sizeof(*data);
	size_t i;

	for (i = 0; i < num_entries; i++)
		data[i] = MATCHFINDER_INITVAL;
}
#endif


#ifndef matchfinder_rebase
static forceinline void
matchfinder_rebase(mf_pos_t *data, size_t size)
{
	size_t num_entries = size / sizeof(*data);
	size_t i;

	if (MATCHFINDER_WINDOW_SIZE == 32768) {
		
		for (i = 0; i < num_entries; i++) {
			u16 v = data[i];
			u16 sign_bit = v & 0x8000;
			v &= sign_bit - ((sign_bit >> 15) ^ 1);
			v |= 0x8000;
			data[i] = v;
		}
		return;
	}

	for (i = 0; i < num_entries; i++) {
		if (data[i] >= 0)
			data[i] -= (mf_pos_t)-MATCHFINDER_WINDOW_SIZE;
		else
			data[i] = (mf_pos_t)-MATCHFINDER_WINDOW_SIZE;
	}
}
#endif


static forceinline u32
lz_hash(u32 seq, unsigned num_bits)
{
	return (u32)(seq * 0x1E35A7BD) >> (32 - num_bits);
}


static forceinline unsigned
lz_extend(const u8 * const strptr, const u8 * const matchptr,
	  const unsigned start_len, const unsigned max_len)
{
	unsigned len = start_len;
	machine_word_t v_word;

	if (UNALIGNED_ACCESS_IS_FAST) {

		if (likely(max_len - len >= 4 * WORDBYTES)) {

		#define COMPARE_WORD_STEP				\
			v_word = load_word_unaligned(&matchptr[len]) ^	\
				 load_word_unaligned(&strptr[len]);	\
			if (v_word != 0)				\
				goto word_differs;			\
			len += WORDBYTES;				\

			COMPARE_WORD_STEP
			COMPARE_WORD_STEP
			COMPARE_WORD_STEP
			COMPARE_WORD_STEP
		#undef COMPARE_WORD_STEP
		}

		while (len + WORDBYTES <= max_len) {
			v_word = load_word_unaligned(&matchptr[len]) ^
				 load_word_unaligned(&strptr[len]);
			if (v_word != 0)
				goto word_differs;
			len += WORDBYTES;
		}
	}

	while (len < max_len && matchptr[len] == strptr[len])
		len++;
	return len;

word_differs:
	if (CPU_IS_LITTLE_ENDIAN())
		len += (bsfw(v_word) >> 3);
	else
		len += (WORDBITS - 1 - bsrw(v_word)) >> 3;
	return len;
}

#endif 


#define HC_MATCHFINDER_HASH3_ORDER	15
#define HC_MATCHFINDER_HASH4_ORDER	16

#define HC_MATCHFINDER_TOTAL_HASH_SIZE			\
	(((1UL << HC_MATCHFINDER_HASH3_ORDER) +		\
	  (1UL << HC_MATCHFINDER_HASH4_ORDER)) * sizeof(mf_pos_t))

struct hc_matchfinder {

	
	mf_pos_t hash3_tab[1UL << HC_MATCHFINDER_HASH3_ORDER];

	
	mf_pos_t hash4_tab[1UL << HC_MATCHFINDER_HASH4_ORDER];

	
	mf_pos_t next_tab[MATCHFINDER_WINDOW_SIZE];

}
#ifdef _aligned_attribute
  _aligned_attribute(MATCHFINDER_MEM_ALIGNMENT)
#endif
;


static forceinline void
hc_matchfinder_init(struct hc_matchfinder *mf)
{
	STATIC_ASSERT(HC_MATCHFINDER_TOTAL_HASH_SIZE %
		      MATCHFINDER_SIZE_ALIGNMENT == 0);

	matchfinder_init((mf_pos_t *)mf, HC_MATCHFINDER_TOTAL_HASH_SIZE);
}

static forceinline void
hc_matchfinder_slide_window(struct hc_matchfinder *mf)
{
	STATIC_ASSERT(sizeof(*mf) % MATCHFINDER_SIZE_ALIGNMENT == 0);

	matchfinder_rebase((mf_pos_t *)mf, sizeof(*mf));
}


static forceinline u32
hc_matchfinder_longest_match(struct hc_matchfinder * const restrict mf,
			     const u8 ** const restrict in_base_p,
			     const u8 * const restrict in_next,
			     u32 best_len,
			     const u32 max_len,
			     const u32 nice_len,
			     const u32 max_search_depth,
			     u32 * const restrict next_hashes,
			     u32 * const restrict offset_ret)
{
	u32 depth_remaining = max_search_depth;
	const u8 *best_matchptr = in_next;
	mf_pos_t cur_node3, cur_node4;
	u32 hash3, hash4;
	u32 next_hashseq;
	u32 seq4;
	const u8 *matchptr;
	u32 len;
	u32 cur_pos = in_next - *in_base_p;
	const u8 *in_base;
	mf_pos_t cutoff;

	if (cur_pos == MATCHFINDER_WINDOW_SIZE) {
		hc_matchfinder_slide_window(mf);
		*in_base_p += MATCHFINDER_WINDOW_SIZE;
		cur_pos = 0;
	}

	in_base = *in_base_p;
	cutoff = cur_pos - MATCHFINDER_WINDOW_SIZE;

	if (unlikely(max_len < 5)) 
		goto out;

	
	hash3 = next_hashes[0];
	hash4 = next_hashes[1];

	
	cur_node3 = mf->hash3_tab[hash3];
	cur_node4 = mf->hash4_tab[hash4];

	
	mf->hash3_tab[hash3] = cur_pos;

	
	mf->hash4_tab[hash4] = cur_pos;
	mf->next_tab[cur_pos] = cur_node4;

	
	next_hashseq = get_unaligned_le32(in_next + 1);
	next_hashes[0] = lz_hash(next_hashseq & 0xFFFFFF, HC_MATCHFINDER_HASH3_ORDER);
	next_hashes[1] = lz_hash(next_hashseq, HC_MATCHFINDER_HASH4_ORDER);
	prefetchw(&mf->hash3_tab[next_hashes[0]]);
	prefetchw(&mf->hash4_tab[next_hashes[1]]);

	if (best_len < 4) {  

		

		if (cur_node3 <= cutoff)
			goto out;

		seq4 = load_u32_unaligned(in_next);

		if (best_len < 3) {
			matchptr = &in_base[cur_node3];
			if (load_u24_unaligned(matchptr) == loaded_u32_to_u24(seq4)) {
				best_len = 3;
				best_matchptr = matchptr;
			}
		}

		

		if (cur_node4 <= cutoff)
			goto out;

		for (;;) {
			
			matchptr = &in_base[cur_node4];

			if (load_u32_unaligned(matchptr) == seq4)
				break;

			
			cur_node4 = mf->next_tab[cur_node4 & (MATCHFINDER_WINDOW_SIZE - 1)];
			if (cur_node4 <= cutoff || !--depth_remaining)
				goto out;
		}

		
		best_matchptr = matchptr;
		best_len = lz_extend(in_next, best_matchptr, 4, max_len);
		if (best_len >= nice_len)
			goto out;
		cur_node4 = mf->next_tab[cur_node4 & (MATCHFINDER_WINDOW_SIZE - 1)];
		if (cur_node4 <= cutoff || !--depth_remaining)
			goto out;
	} else {
		if (cur_node4 <= cutoff || best_len >= nice_len)
			goto out;
	}

	

	for (;;) {
		for (;;) {
			matchptr = &in_base[cur_node4];

			
		#if UNALIGNED_ACCESS_IS_FAST
			if ((load_u32_unaligned(matchptr + best_len - 3) ==
			     load_u32_unaligned(in_next + best_len - 3)) &&
			    (load_u32_unaligned(matchptr) ==
			     load_u32_unaligned(in_next)))
		#else
			if (matchptr[best_len] == in_next[best_len])
		#endif
				break;

			
			cur_node4 = mf->next_tab[cur_node4 & (MATCHFINDER_WINDOW_SIZE - 1)];
			if (cur_node4 <= cutoff || !--depth_remaining)
				goto out;
		}

	#if UNALIGNED_ACCESS_IS_FAST
		len = 4;
	#else
		len = 0;
	#endif
		len = lz_extend(in_next, matchptr, len, max_len);
		if (len > best_len) {
			
			best_len = len;
			best_matchptr = matchptr;
			if (best_len >= nice_len)
				goto out;
		}

		
		cur_node4 = mf->next_tab[cur_node4 & (MATCHFINDER_WINDOW_SIZE - 1)];
		if (cur_node4 <= cutoff || !--depth_remaining)
			goto out;
	}
out:
	*offset_ret = in_next - best_matchptr;
	return best_len;
}


static forceinline const u8 *
hc_matchfinder_skip_positions(struct hc_matchfinder * const restrict mf,
			      const u8 ** const restrict in_base_p,
			      const u8 *in_next,
			      const u8 * const in_end,
			      const u32 count,
			      u32 * const restrict next_hashes)
{
	u32 cur_pos;
	u32 hash3, hash4;
	u32 next_hashseq;
	u32 remaining = count;

	if (unlikely(count + 5 > in_end - in_next))
		return &in_next[count];

	cur_pos = in_next - *in_base_p;
	hash3 = next_hashes[0];
	hash4 = next_hashes[1];
	do {
		if (cur_pos == MATCHFINDER_WINDOW_SIZE) {
			hc_matchfinder_slide_window(mf);
			*in_base_p += MATCHFINDER_WINDOW_SIZE;
			cur_pos = 0;
		}
		mf->hash3_tab[hash3] = cur_pos;
		mf->next_tab[cur_pos] = mf->hash4_tab[hash4];
		mf->hash4_tab[hash4] = cur_pos;

		next_hashseq = get_unaligned_le32(++in_next);
		hash3 = lz_hash(next_hashseq & 0xFFFFFF, HC_MATCHFINDER_HASH3_ORDER);
		hash4 = lz_hash(next_hashseq, HC_MATCHFINDER_HASH4_ORDER);
		cur_pos++;
	} while (--remaining);

	prefetchw(&mf->hash3_tab[hash3]);
	prefetchw(&mf->hash4_tab[hash4]);
	next_hashes[0] = hash3;
	next_hashes[1] = hash4;

	return in_next;
}

#if SUPPORT_NEAR_OPTIMAL_PARSING
/* #  include "bt_matchfinder.h" */



/* #include "matchfinder_common.h" */


#ifndef LIB_MATCHFINDER_COMMON_H
#define LIB_MATCHFINDER_COMMON_H

/* #include "lib_common.h" */


#ifndef LIB_LIB_COMMON_H
#define LIB_LIB_COMMON_H

#ifdef LIBDEFLATE_H
#  error "lib_common.h must always be included before libdeflate.h"
   
#endif

#define BUILDING_LIBDEFLATE

/* #include "../common/common_defs.h" */


#ifndef COMMON_COMMON_DEFS_H
#define COMMON_COMMON_DEFS_H

#ifdef __GNUC__
/* #  include "compiler_gcc.h" */


#if !defined(__clang__) && !defined(__INTEL_COMPILER)
#  define GCC_PREREQ(major, minor)		\
	(__GNUC__ > (major) ||			\
	 (__GNUC__ == (major) && __GNUC_MINOR__ >= (minor)))
#else
#  define GCC_PREREQ(major, minor)	0
#endif


#ifdef __clang__
#  ifdef __apple_build_version__
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__apple_build_version__ >= (apple_version))
#  else
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__clang_major__ > (major) ||			\
	 (__clang_major__ == (major) && __clang_minor__ >= (minor)))
#  endif
#else
#  define CLANG_PREREQ(major, minor, apple_version)	0
#endif

#ifndef __has_attribute
#  define __has_attribute(attribute)	0
#endif
#ifndef __has_feature
#  define __has_feature(feature)	0
#endif
#ifndef __has_builtin
#  define __has_builtin(builtin)	0
#endif

#ifdef _WIN32
#  define LIBEXPORT __declspec(dllexport)
#else
#  define LIBEXPORT __attribute__((visibility("default")))
#endif

#define inline			inline
#define forceinline		inline __attribute__((always_inline))
#define restrict		__restrict__
#define likely(expr)		__builtin_expect(!!(expr), 1)
#define unlikely(expr)		__builtin_expect(!!(expr), 0)
#define prefetchr(addr)		__builtin_prefetch((addr), 0)
#define prefetchw(addr)		__builtin_prefetch((addr), 1)
#define _aligned_attribute(n)	__attribute__((aligned(n)))

#define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE	\
	(GCC_PREREQ(4, 4) || __has_attribute(target))

#if COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE

#  if defined(__i386__) || defined(__x86_64__)

#    define COMPILER_SUPPORTS_PCLMUL_TARGET	\
	(GCC_PREREQ(4, 4) || __has_builtin(__builtin_ia32_pclmulqdq128))

#    define COMPILER_SUPPORTS_AVX_TARGET	\
	(GCC_PREREQ(4, 6) || __has_builtin(__builtin_ia32_maxps256))

#    define COMPILER_SUPPORTS_BMI2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_pdep_di))

#    define COMPILER_SUPPORTS_AVX2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_psadbw256))

#    define COMPILER_SUPPORTS_AVX512BW_TARGET	\
	(GCC_PREREQ(5, 1) || __has_builtin(__builtin_ia32_psadbw512))

	
#    if GCC_PREREQ(4, 9) || CLANG_PREREQ(3, 8, 7030000)
#      define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS	1
#      define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_PCLMUL_TARGET
#      define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX2_TARGET
#      define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX512BW_TARGET
#    endif

#  elif defined(__arm__) || defined(__aarch64__)

    
#    if (GCC_PREREQ(6, 1) && defined(__ARM_FP)) || \
        (defined(__clang__) && defined(__ARM_NEON))
#      define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 1
       
#      if defined(__clang__) && defined(__arm__)
#        undef __ARM_FEATURE_CRYPTO
#      elif __has_builtin(__builtin_neon_vmull_p64) || !defined(__clang__)
#        define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 1
#      endif
#    endif

     
#    if GCC_PREREQ(10, 1) || \
        (GCC_PREREQ(9, 3) && !GCC_PREREQ(10, 0)) || \
        (GCC_PREREQ(8, 4) && !GCC_PREREQ(9, 0)) || \
        (defined(__clang__) && __has_builtin(__builtin_arm_crc32b))
#      define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 1
#    endif

#  endif 

#endif 


#if (GCC_PREREQ(4, 0) && !GCC_PREREQ(5, 1)) || \
    (defined(__clang__) && !CLANG_PREREQ(3, 9, 8020000))
typedef unsigned long long  __v2du __attribute__((__vector_size__(16)));
typedef unsigned int        __v4su __attribute__((__vector_size__(16)));
typedef unsigned short      __v8hu __attribute__((__vector_size__(16)));
typedef unsigned char      __v16qu __attribute__((__vector_size__(16)));
typedef unsigned long long  __v4du __attribute__((__vector_size__(32)));
typedef unsigned int        __v8su __attribute__((__vector_size__(32)));
typedef unsigned short     __v16hu __attribute__((__vector_size__(32)));
typedef unsigned char      __v32qu __attribute__((__vector_size__(32)));
#endif


#ifdef __BYTE_ORDER__
#  define CPU_IS_LITTLE_ENDIAN() (__BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__)
#endif

#if GCC_PREREQ(4, 8) || __has_builtin(__builtin_bswap16)
#  define bswap16	__builtin_bswap16
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap32)
#  define bswap32	__builtin_bswap32
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap64)
#  define bswap64	__builtin_bswap64
#endif

#if defined(__x86_64__) || defined(__i386__) || defined(__ARM_FEATURE_UNALIGNED) || defined(__powerpc64__)
#  define UNALIGNED_ACCESS_IS_FAST 1
#endif

#define bsr32(n)	(31 - __builtin_clz(n))
#define bsr64(n)	(63 - __builtin_clzll(n))
#define bsf32(n)	__builtin_ctz(n)
#define bsf64(n)	__builtin_ctzll(n)

#elif defined(_MSC_VER)
/* #  include "compiler_msc.h" */


#include <stdint.h>
#include <stdlib.h> 

#define LIBEXPORT	__declspec(dllexport)


typedef int bool;
#define true 1
#define false 0
#define __bool_true_false_are_defined 1


#ifdef _WIN64
typedef long long ssize_t;
#else
typedef int ssize_t;
#endif


#define CPU_IS_LITTLE_ENDIAN()		1
#define UNALIGNED_ACCESS_IS_FAST	1


#define restrict


#define inline		__inline
#define forceinline	__forceinline


#define bswap16	_byteswap_ushort
#define bswap32	_byteswap_ulong
#define bswap64	_byteswap_uint64



static forceinline unsigned
bsr32(uint32_t n)
{
	_BitScanReverse(&n, n);
	return n;
}
#define bsr32 bsr32

static forceinline unsigned
bsf32(uint32_t n)
{
	_BitScanForward(&n, n);
	return n;
}
#define bsf32 bsf32

#ifdef _M_X64 

static forceinline unsigned
bsr64(uint64_t n)
{
	_BitScanReverse64(&n, n);
	return n;
}
#define bsr64 bsr64

static forceinline unsigned
bsf64(uint64_t n)
{
	_BitScanForward64(&n, n);
	return n;
}
#define bsf64 bsf64

#endif 

#else
#  pragma message("Unrecognized compiler.  Please add a header file for your compiler.  Compilation will proceed, but performance may suffer!")
#endif





#include <stddef.h> 

#ifndef __bool_true_false_are_defined
#  include <stdbool.h> 
#endif


#include <stdint.h>
typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
typedef int8_t s8;
typedef int16_t s16;
typedef int32_t s32;
typedef int64_t s64;


typedef size_t machine_word_t;


#define WORDBYTES	((int)sizeof(machine_word_t))


#define WORDBITS	(8 * WORDBYTES)






#ifndef LIBEXPORT
#  define LIBEXPORT
#endif


#ifndef inline
#  define inline
#endif


#ifndef forceinline
#  define forceinline inline
#endif


#ifndef restrict
#  define restrict
#endif


#ifndef likely
#  define likely(expr)		(expr)
#endif


#ifndef unlikely
#  define unlikely(expr)	(expr)
#endif


#ifndef prefetchr
#  define prefetchr(addr)
#endif


#ifndef prefetchw
#  define prefetchw(addr)
#endif


#ifndef COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE
#  define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE 0
#endif


#ifndef COMPILER_SUPPORTS_BMI2_TARGET
#  define COMPILER_SUPPORTS_BMI2_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX_TARGET
#  define COMPILER_SUPPORTS_AVX_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET
#  define COMPILER_SUPPORTS_AVX512BW_TARGET 0
#endif


#ifndef COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 0
#endif


#ifndef _aligned_attribute
#endif





#define ARRAY_LEN(A)		(sizeof(A) / sizeof((A)[0]))
#define MIN(a, b)		((a) <= (b) ? (a) : (b))
#define MAX(a, b)		((a) >= (b) ? (a) : (b))
#define DIV_ROUND_UP(n, d)	(((n) + (d) - 1) / (d))
#define STATIC_ASSERT(expr)	((void)sizeof(char[1 - 2 * !(expr)]))
#define ALIGN(n, a)		(((n) + (a) - 1) & ~((a) - 1))






#ifndef CPU_IS_LITTLE_ENDIAN
static forceinline int CPU_IS_LITTLE_ENDIAN(void)
{
	union {
		unsigned int v;
		unsigned char b;
	} u;
	u.v = 1;
	return u.b;
}
#endif


#ifndef bswap16
static forceinline u16 bswap16(u16 n)
{
	return (n << 8) | (n >> 8);
}
#endif


#ifndef bswap32
static forceinline u32 bswap32(u32 n)
{
	return ((n & 0x000000FF) << 24) |
	       ((n & 0x0000FF00) << 8) |
	       ((n & 0x00FF0000) >> 8) |
	       ((n & 0xFF000000) >> 24);
}
#endif


#ifndef bswap64
static forceinline u64 bswap64(u64 n)
{
	return ((n & 0x00000000000000FF) << 56) |
	       ((n & 0x000000000000FF00) << 40) |
	       ((n & 0x0000000000FF0000) << 24) |
	       ((n & 0x00000000FF000000) << 8) |
	       ((n & 0x000000FF00000000) >> 8) |
	       ((n & 0x0000FF0000000000) >> 24) |
	       ((n & 0x00FF000000000000) >> 40) |
	       ((n & 0xFF00000000000000) >> 56);
}
#endif

#define le16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap16(n))
#define le32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap32(n))
#define le64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap64(n))
#define be16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap16(n) : (n))
#define be32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap32(n) : (n))
#define be64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap64(n) : (n))






#ifndef UNALIGNED_ACCESS_IS_FAST
#  define UNALIGNED_ACCESS_IS_FAST 0
#endif







#ifndef bsr32
static forceinline unsigned
bsr32(u32 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

#ifndef bsr64
static forceinline unsigned
bsr64(u64 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

static forceinline unsigned
bsrw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsr32(n);
	else
		return bsr64(n);
}



#ifndef bsf32
static forceinline unsigned
bsf32(u32 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

#ifndef bsf64
static forceinline unsigned
bsf64(u64 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

static forceinline unsigned
bsfw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsf32(n);
	else
		return bsf64(n);
}

#endif 



#define SYM_FIXUP(sym)			_libdeflate_##sym
#define deflate_get_compression_level	SYM_FIXUP(deflate_get_compression_level)
#define _cpu_features			SYM_FIXUP(_cpu_features)
#define setup_cpu_features		SYM_FIXUP(setup_cpu_features)

void *libdeflate_malloc(size_t size);
void libdeflate_free(void *ptr);

void *libdeflate_aligned_malloc(size_t alignment, size_t size);
void libdeflate_aligned_free(void *ptr);

#ifdef FREESTANDING

void *memset(void *s, int c, size_t n);
#define memset(s, c, n)		__builtin_memset((s), (c), (n))

void *memcpy(void *dest, const void *src, size_t n);
#define memcpy(dest, src, n)	__builtin_memcpy((dest), (src), (n))

void *memmove(void *dest, const void *src, size_t n);
#define memmove(dest, src, n)	__builtin_memmove((dest), (src), (n))

int memcmp(const void *s1, const void *s2, size_t n);
#define memcmp(s1, s2, n)	__builtin_memcmp((s1), (s2), (n))
#else
#include <string.h>
#endif

#endif 

/* #include "unaligned.h" */


#ifndef LIB_UNALIGNED_H
#define LIB_UNALIGNED_H

/* #include "lib_common.h" */


#ifndef LIB_LIB_COMMON_H
#define LIB_LIB_COMMON_H

#ifdef LIBDEFLATE_H
#  error "lib_common.h must always be included before libdeflate.h"
   
#endif

#define BUILDING_LIBDEFLATE

/* #include "../common/common_defs.h" */


#ifndef COMMON_COMMON_DEFS_H
#define COMMON_COMMON_DEFS_H

#ifdef __GNUC__
/* #  include "compiler_gcc.h" */


#if !defined(__clang__) && !defined(__INTEL_COMPILER)
#  define GCC_PREREQ(major, minor)		\
	(__GNUC__ > (major) ||			\
	 (__GNUC__ == (major) && __GNUC_MINOR__ >= (minor)))
#else
#  define GCC_PREREQ(major, minor)	0
#endif


#ifdef __clang__
#  ifdef __apple_build_version__
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__apple_build_version__ >= (apple_version))
#  else
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__clang_major__ > (major) ||			\
	 (__clang_major__ == (major) && __clang_minor__ >= (minor)))
#  endif
#else
#  define CLANG_PREREQ(major, minor, apple_version)	0
#endif

#ifndef __has_attribute
#  define __has_attribute(attribute)	0
#endif
#ifndef __has_feature
#  define __has_feature(feature)	0
#endif
#ifndef __has_builtin
#  define __has_builtin(builtin)	0
#endif

#ifdef _WIN32
#  define LIBEXPORT __declspec(dllexport)
#else
#  define LIBEXPORT __attribute__((visibility("default")))
#endif

#define inline			inline
#define forceinline		inline __attribute__((always_inline))
#define restrict		__restrict__
#define likely(expr)		__builtin_expect(!!(expr), 1)
#define unlikely(expr)		__builtin_expect(!!(expr), 0)
#define prefetchr(addr)		__builtin_prefetch((addr), 0)
#define prefetchw(addr)		__builtin_prefetch((addr), 1)
#define _aligned_attribute(n)	__attribute__((aligned(n)))

#define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE	\
	(GCC_PREREQ(4, 4) || __has_attribute(target))

#if COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE

#  if defined(__i386__) || defined(__x86_64__)

#    define COMPILER_SUPPORTS_PCLMUL_TARGET	\
	(GCC_PREREQ(4, 4) || __has_builtin(__builtin_ia32_pclmulqdq128))

#    define COMPILER_SUPPORTS_AVX_TARGET	\
	(GCC_PREREQ(4, 6) || __has_builtin(__builtin_ia32_maxps256))

#    define COMPILER_SUPPORTS_BMI2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_pdep_di))

#    define COMPILER_SUPPORTS_AVX2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_psadbw256))

#    define COMPILER_SUPPORTS_AVX512BW_TARGET	\
	(GCC_PREREQ(5, 1) || __has_builtin(__builtin_ia32_psadbw512))

	
#    if GCC_PREREQ(4, 9) || CLANG_PREREQ(3, 8, 7030000)
#      define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS	1
#      define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_PCLMUL_TARGET
#      define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX2_TARGET
#      define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX512BW_TARGET
#    endif

#  elif defined(__arm__) || defined(__aarch64__)

    
#    if (GCC_PREREQ(6, 1) && defined(__ARM_FP)) || \
        (defined(__clang__) && defined(__ARM_NEON))
#      define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 1
       
#      if defined(__clang__) && defined(__arm__)
#        undef __ARM_FEATURE_CRYPTO
#      elif __has_builtin(__builtin_neon_vmull_p64) || !defined(__clang__)
#        define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 1
#      endif
#    endif

     
#    if GCC_PREREQ(10, 1) || \
        (GCC_PREREQ(9, 3) && !GCC_PREREQ(10, 0)) || \
        (GCC_PREREQ(8, 4) && !GCC_PREREQ(9, 0)) || \
        (defined(__clang__) && __has_builtin(__builtin_arm_crc32b))
#      define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 1
#    endif

#  endif 

#endif 


#if (GCC_PREREQ(4, 0) && !GCC_PREREQ(5, 1)) || \
    (defined(__clang__) && !CLANG_PREREQ(3, 9, 8020000))
typedef unsigned long long  __v2du __attribute__((__vector_size__(16)));
typedef unsigned int        __v4su __attribute__((__vector_size__(16)));
typedef unsigned short      __v8hu __attribute__((__vector_size__(16)));
typedef unsigned char      __v16qu __attribute__((__vector_size__(16)));
typedef unsigned long long  __v4du __attribute__((__vector_size__(32)));
typedef unsigned int        __v8su __attribute__((__vector_size__(32)));
typedef unsigned short     __v16hu __attribute__((__vector_size__(32)));
typedef unsigned char      __v32qu __attribute__((__vector_size__(32)));
#endif


#ifdef __BYTE_ORDER__
#  define CPU_IS_LITTLE_ENDIAN() (__BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__)
#endif

#if GCC_PREREQ(4, 8) || __has_builtin(__builtin_bswap16)
#  define bswap16	__builtin_bswap16
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap32)
#  define bswap32	__builtin_bswap32
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap64)
#  define bswap64	__builtin_bswap64
#endif

#if defined(__x86_64__) || defined(__i386__) || defined(__ARM_FEATURE_UNALIGNED) || defined(__powerpc64__)
#  define UNALIGNED_ACCESS_IS_FAST 1
#endif

#define bsr32(n)	(31 - __builtin_clz(n))
#define bsr64(n)	(63 - __builtin_clzll(n))
#define bsf32(n)	__builtin_ctz(n)
#define bsf64(n)	__builtin_ctzll(n)

#elif defined(_MSC_VER)
/* #  include "compiler_msc.h" */


#include <stdint.h>
#include <stdlib.h> 

#define LIBEXPORT	__declspec(dllexport)


typedef int bool;
#define true 1
#define false 0
#define __bool_true_false_are_defined 1


#ifdef _WIN64
typedef long long ssize_t;
#else
typedef int ssize_t;
#endif


#define CPU_IS_LITTLE_ENDIAN()		1
#define UNALIGNED_ACCESS_IS_FAST	1


#define restrict


#define inline		__inline
#define forceinline	__forceinline


#define bswap16	_byteswap_ushort
#define bswap32	_byteswap_ulong
#define bswap64	_byteswap_uint64



static forceinline unsigned
bsr32(uint32_t n)
{
	_BitScanReverse(&n, n);
	return n;
}
#define bsr32 bsr32

static forceinline unsigned
bsf32(uint32_t n)
{
	_BitScanForward(&n, n);
	return n;
}
#define bsf32 bsf32

#ifdef _M_X64 

static forceinline unsigned
bsr64(uint64_t n)
{
	_BitScanReverse64(&n, n);
	return n;
}
#define bsr64 bsr64

static forceinline unsigned
bsf64(uint64_t n)
{
	_BitScanForward64(&n, n);
	return n;
}
#define bsf64 bsf64

#endif 

#else
#  pragma message("Unrecognized compiler.  Please add a header file for your compiler.  Compilation will proceed, but performance may suffer!")
#endif





#include <stddef.h> 

#ifndef __bool_true_false_are_defined
#  include <stdbool.h> 
#endif


#include <stdint.h>
typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
typedef int8_t s8;
typedef int16_t s16;
typedef int32_t s32;
typedef int64_t s64;


typedef size_t machine_word_t;


#define WORDBYTES	((int)sizeof(machine_word_t))


#define WORDBITS	(8 * WORDBYTES)






#ifndef LIBEXPORT
#  define LIBEXPORT
#endif


#ifndef inline
#  define inline
#endif


#ifndef forceinline
#  define forceinline inline
#endif


#ifndef restrict
#  define restrict
#endif


#ifndef likely
#  define likely(expr)		(expr)
#endif


#ifndef unlikely
#  define unlikely(expr)	(expr)
#endif


#ifndef prefetchr
#  define prefetchr(addr)
#endif


#ifndef prefetchw
#  define prefetchw(addr)
#endif


#ifndef COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE
#  define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE 0
#endif


#ifndef COMPILER_SUPPORTS_BMI2_TARGET
#  define COMPILER_SUPPORTS_BMI2_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX_TARGET
#  define COMPILER_SUPPORTS_AVX_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET
#  define COMPILER_SUPPORTS_AVX512BW_TARGET 0
#endif


#ifndef COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 0
#endif


#ifndef _aligned_attribute
#endif





#define ARRAY_LEN(A)		(sizeof(A) / sizeof((A)[0]))
#define MIN(a, b)		((a) <= (b) ? (a) : (b))
#define MAX(a, b)		((a) >= (b) ? (a) : (b))
#define DIV_ROUND_UP(n, d)	(((n) + (d) - 1) / (d))
#define STATIC_ASSERT(expr)	((void)sizeof(char[1 - 2 * !(expr)]))
#define ALIGN(n, a)		(((n) + (a) - 1) & ~((a) - 1))






#ifndef CPU_IS_LITTLE_ENDIAN
static forceinline int CPU_IS_LITTLE_ENDIAN(void)
{
	union {
		unsigned int v;
		unsigned char b;
	} u;
	u.v = 1;
	return u.b;
}
#endif


#ifndef bswap16
static forceinline u16 bswap16(u16 n)
{
	return (n << 8) | (n >> 8);
}
#endif


#ifndef bswap32
static forceinline u32 bswap32(u32 n)
{
	return ((n & 0x000000FF) << 24) |
	       ((n & 0x0000FF00) << 8) |
	       ((n & 0x00FF0000) >> 8) |
	       ((n & 0xFF000000) >> 24);
}
#endif


#ifndef bswap64
static forceinline u64 bswap64(u64 n)
{
	return ((n & 0x00000000000000FF) << 56) |
	       ((n & 0x000000000000FF00) << 40) |
	       ((n & 0x0000000000FF0000) << 24) |
	       ((n & 0x00000000FF000000) << 8) |
	       ((n & 0x000000FF00000000) >> 8) |
	       ((n & 0x0000FF0000000000) >> 24) |
	       ((n & 0x00FF000000000000) >> 40) |
	       ((n & 0xFF00000000000000) >> 56);
}
#endif

#define le16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap16(n))
#define le32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap32(n))
#define le64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap64(n))
#define be16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap16(n) : (n))
#define be32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap32(n) : (n))
#define be64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap64(n) : (n))






#ifndef UNALIGNED_ACCESS_IS_FAST
#  define UNALIGNED_ACCESS_IS_FAST 0
#endif







#ifndef bsr32
static forceinline unsigned
bsr32(u32 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

#ifndef bsr64
static forceinline unsigned
bsr64(u64 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

static forceinline unsigned
bsrw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsr32(n);
	else
		return bsr64(n);
}



#ifndef bsf32
static forceinline unsigned
bsf32(u32 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

#ifndef bsf64
static forceinline unsigned
bsf64(u64 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

static forceinline unsigned
bsfw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsf32(n);
	else
		return bsf64(n);
}

#endif 



#define SYM_FIXUP(sym)			_libdeflate_##sym
#define deflate_get_compression_level	SYM_FIXUP(deflate_get_compression_level)
#define _cpu_features			SYM_FIXUP(_cpu_features)
#define setup_cpu_features		SYM_FIXUP(setup_cpu_features)

void *libdeflate_malloc(size_t size);
void libdeflate_free(void *ptr);

void *libdeflate_aligned_malloc(size_t alignment, size_t size);
void libdeflate_aligned_free(void *ptr);

#ifdef FREESTANDING

void *memset(void *s, int c, size_t n);
#define memset(s, c, n)		__builtin_memset((s), (c), (n))

void *memcpy(void *dest, const void *src, size_t n);
#define memcpy(dest, src, n)	__builtin_memcpy((dest), (src), (n))

void *memmove(void *dest, const void *src, size_t n);
#define memmove(dest, src, n)	__builtin_memmove((dest), (src), (n))

int memcmp(const void *s1, const void *s2, size_t n);
#define memcmp(s1, s2, n)	__builtin_memcmp((s1), (s2), (n))
#else
#include <string.h>
#endif

#endif 






#define DEFINE_UNALIGNED_TYPE(type)				\
static forceinline type						\
load_##type##_unaligned(const void *p)				\
{								\
	type v;							\
	memcpy(&v, p, sizeof(v));				\
	return v;						\
}								\
								\
static forceinline void						\
store_##type##_unaligned(type v, void *p)			\
{								\
	memcpy(p, &v, sizeof(v));				\
}

DEFINE_UNALIGNED_TYPE(u16)
DEFINE_UNALIGNED_TYPE(u32)
DEFINE_UNALIGNED_TYPE(u64)
DEFINE_UNALIGNED_TYPE(machine_word_t)

#define load_word_unaligned	load_machine_word_t_unaligned
#define store_word_unaligned	store_machine_word_t_unaligned



static forceinline u16
get_unaligned_le16(const u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST)
		return le16_bswap(load_u16_unaligned(p));
	else
		return ((u16)p[1] << 8) | p[0];
}

static forceinline u16
get_unaligned_be16(const u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST)
		return be16_bswap(load_u16_unaligned(p));
	else
		return ((u16)p[0] << 8) | p[1];
}

static forceinline u32
get_unaligned_le32(const u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST)
		return le32_bswap(load_u32_unaligned(p));
	else
		return ((u32)p[3] << 24) | ((u32)p[2] << 16) |
			((u32)p[1] << 8) | p[0];
}

static forceinline u32
get_unaligned_be32(const u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST)
		return be32_bswap(load_u32_unaligned(p));
	else
		return ((u32)p[0] << 24) | ((u32)p[1] << 16) |
			((u32)p[2] << 8) | p[3];
}

static forceinline u64
get_unaligned_le64(const u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST)
		return le64_bswap(load_u64_unaligned(p));
	else
		return ((u64)p[7] << 56) | ((u64)p[6] << 48) |
			((u64)p[5] << 40) | ((u64)p[4] << 32) |
			((u64)p[3] << 24) | ((u64)p[2] << 16) |
			((u64)p[1] << 8) | p[0];
}

static forceinline machine_word_t
get_unaligned_leword(const u8 *p)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return get_unaligned_le32(p);
	else
		return get_unaligned_le64(p);
}



static forceinline void
put_unaligned_le16(u16 v, u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST) {
		store_u16_unaligned(le16_bswap(v), p);
	} else {
		p[0] = (u8)(v >> 0);
		p[1] = (u8)(v >> 8);
	}
}

static forceinline void
put_unaligned_be16(u16 v, u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST) {
		store_u16_unaligned(be16_bswap(v), p);
	} else {
		p[0] = (u8)(v >> 8);
		p[1] = (u8)(v >> 0);
	}
}

static forceinline void
put_unaligned_le32(u32 v, u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST) {
		store_u32_unaligned(le32_bswap(v), p);
	} else {
		p[0] = (u8)(v >> 0);
		p[1] = (u8)(v >> 8);
		p[2] = (u8)(v >> 16);
		p[3] = (u8)(v >> 24);
	}
}

static forceinline void
put_unaligned_be32(u32 v, u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST) {
		store_u32_unaligned(be32_bswap(v), p);
	} else {
		p[0] = (u8)(v >> 24);
		p[1] = (u8)(v >> 16);
		p[2] = (u8)(v >> 8);
		p[3] = (u8)(v >> 0);
	}
}

static forceinline void
put_unaligned_le64(u64 v, u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST) {
		store_u64_unaligned(le64_bswap(v), p);
	} else {
		p[0] = (u8)(v >> 0);
		p[1] = (u8)(v >> 8);
		p[2] = (u8)(v >> 16);
		p[3] = (u8)(v >> 24);
		p[4] = (u8)(v >> 32);
		p[5] = (u8)(v >> 40);
		p[6] = (u8)(v >> 48);
		p[7] = (u8)(v >> 56);
	}
}

static forceinline void
put_unaligned_leword(machine_word_t v, u8 *p)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		put_unaligned_le32(v, p);
	else
		put_unaligned_le64(v, p);
}




static forceinline u32
loaded_u32_to_u24(u32 v)
{
	if (CPU_IS_LITTLE_ENDIAN())
		return v & 0xFFFFFF;
	else
		return v >> 8;
}


static forceinline u32
load_u24_unaligned(const u8 *p)
{
#if UNALIGNED_ACCESS_IS_FAST
#  define LOAD_U24_REQUIRED_NBYTES 4
	return loaded_u32_to_u24(load_u32_unaligned(p));
#else
#  define LOAD_U24_REQUIRED_NBYTES 3
	if (CPU_IS_LITTLE_ENDIAN())
		return ((u32)p[0] << 0) | ((u32)p[1] << 8) | ((u32)p[2] << 16);
	else
		return ((u32)p[2] << 0) | ((u32)p[1] << 8) | ((u32)p[0] << 16);
#endif
}

#endif 


#ifndef MATCHFINDER_WINDOW_ORDER
#  error "MATCHFINDER_WINDOW_ORDER must be defined!"
#endif

#define MATCHFINDER_WINDOW_SIZE (1UL << MATCHFINDER_WINDOW_ORDER)

typedef s16 mf_pos_t;

#define MATCHFINDER_INITVAL ((mf_pos_t)-MATCHFINDER_WINDOW_SIZE)


#define MATCHFINDER_MEM_ALIGNMENT	32
#define MATCHFINDER_SIZE_ALIGNMENT	128

#undef matchfinder_init
#undef matchfinder_rebase
#ifdef _aligned_attribute
#  if defined(__arm__) || defined(__aarch64__)
/* #    include "arm/matchfinder_impl.h" */


#ifdef __ARM_NEON
#  include <arm_neon.h>
static forceinline void
matchfinder_init_neon(mf_pos_t *data, size_t size)
{
	int16x8_t *p = (int16x8_t *)data;
	int16x8_t v = (int16x8_t) {
		MATCHFINDER_INITVAL, MATCHFINDER_INITVAL, MATCHFINDER_INITVAL,
		MATCHFINDER_INITVAL, MATCHFINDER_INITVAL, MATCHFINDER_INITVAL,
		MATCHFINDER_INITVAL, MATCHFINDER_INITVAL,
	};

	STATIC_ASSERT(MATCHFINDER_MEM_ALIGNMENT % sizeof(*p) == 0);
	STATIC_ASSERT(MATCHFINDER_SIZE_ALIGNMENT % (4 * sizeof(*p)) == 0);
	STATIC_ASSERT(sizeof(mf_pos_t) == 2);

	do {
		p[0] = v;
		p[1] = v;
		p[2] = v;
		p[3] = v;
		p += 4;
		size -= 4 * sizeof(*p);
	} while (size != 0);
}
#define matchfinder_init matchfinder_init_neon

static forceinline void
matchfinder_rebase_neon(mf_pos_t *data, size_t size)
{
	int16x8_t *p = (int16x8_t *)data;
	int16x8_t v = (int16x8_t) {
		(u16)-MATCHFINDER_WINDOW_SIZE, (u16)-MATCHFINDER_WINDOW_SIZE,
		(u16)-MATCHFINDER_WINDOW_SIZE, (u16)-MATCHFINDER_WINDOW_SIZE,
		(u16)-MATCHFINDER_WINDOW_SIZE, (u16)-MATCHFINDER_WINDOW_SIZE,
		(u16)-MATCHFINDER_WINDOW_SIZE, (u16)-MATCHFINDER_WINDOW_SIZE,
	};

	STATIC_ASSERT(MATCHFINDER_MEM_ALIGNMENT % sizeof(*p) == 0);
	STATIC_ASSERT(MATCHFINDER_SIZE_ALIGNMENT % (4 * sizeof(*p)) == 0);
	STATIC_ASSERT(sizeof(mf_pos_t) == 2);

	do {
		p[0] = vqaddq_s16(p[0], v);
		p[1] = vqaddq_s16(p[1], v);
		p[2] = vqaddq_s16(p[2], v);
		p[3] = vqaddq_s16(p[3], v);
		p += 4;
		size -= 4 * sizeof(*p);
	} while (size != 0);
}
#define matchfinder_rebase matchfinder_rebase_neon

#endif 

#  elif defined(__i386__) || defined(__x86_64__)
/* #    include "x86/matchfinder_impl.h" */


#ifdef __AVX2__
#  include <immintrin.h>
static forceinline void
matchfinder_init_avx2(mf_pos_t *data, size_t size)
{
	__m256i *p = (__m256i *)data;
	__m256i v = _mm256_set1_epi16(MATCHFINDER_INITVAL);

	STATIC_ASSERT(MATCHFINDER_MEM_ALIGNMENT % sizeof(*p) == 0);
	STATIC_ASSERT(MATCHFINDER_SIZE_ALIGNMENT % (4 * sizeof(*p)) == 0);
	STATIC_ASSERT(sizeof(mf_pos_t) == 2);

	do {
		p[0] = v;
		p[1] = v;
		p[2] = v;
		p[3] = v;
		p += 4;
		size -= 4 * sizeof(*p);
	} while (size != 0);
}
#define matchfinder_init matchfinder_init_avx2

static forceinline void
matchfinder_rebase_avx2(mf_pos_t *data, size_t size)
{
	__m256i *p = (__m256i *)data;
	__m256i v = _mm256_set1_epi16((u16)-MATCHFINDER_WINDOW_SIZE);

	STATIC_ASSERT(MATCHFINDER_MEM_ALIGNMENT % sizeof(*p) == 0);
	STATIC_ASSERT(MATCHFINDER_SIZE_ALIGNMENT % (4 * sizeof(*p)) == 0);
	STATIC_ASSERT(sizeof(mf_pos_t) == 2);

	do {
		
		p[0] = _mm256_adds_epi16(p[0], v);
		p[1] = _mm256_adds_epi16(p[1], v);
		p[2] = _mm256_adds_epi16(p[2], v);
		p[3] = _mm256_adds_epi16(p[3], v);
		p += 4;
		size -= 4 * sizeof(*p);
	} while (size != 0);
}
#define matchfinder_rebase matchfinder_rebase_avx2

#elif defined(__SSE2__)
#  include <emmintrin.h>
static forceinline void
matchfinder_init_sse2(mf_pos_t *data, size_t size)
{
	__m128i *p = (__m128i *)data;
	__m128i v = _mm_set1_epi16(MATCHFINDER_INITVAL);

	STATIC_ASSERT(MATCHFINDER_MEM_ALIGNMENT % sizeof(*p) == 0);
	STATIC_ASSERT(MATCHFINDER_SIZE_ALIGNMENT % (4 * sizeof(*p)) == 0);
	STATIC_ASSERT(sizeof(mf_pos_t) == 2);

	do {
		p[0] = v;
		p[1] = v;
		p[2] = v;
		p[3] = v;
		p += 4;
		size -= 4 * sizeof(*p);
	} while (size != 0);
}
#define matchfinder_init matchfinder_init_sse2

static forceinline void
matchfinder_rebase_sse2(mf_pos_t *data, size_t size)
{
	__m128i *p = (__m128i *)data;
	__m128i v = _mm_set1_epi16((u16)-MATCHFINDER_WINDOW_SIZE);

	STATIC_ASSERT(MATCHFINDER_MEM_ALIGNMENT % sizeof(*p) == 0);
	STATIC_ASSERT(MATCHFINDER_SIZE_ALIGNMENT % (4 * sizeof(*p)) == 0);
	STATIC_ASSERT(sizeof(mf_pos_t) == 2);

	do {
		
		p[0] = _mm_adds_epi16(p[0], v);
		p[1] = _mm_adds_epi16(p[1], v);
		p[2] = _mm_adds_epi16(p[2], v);
		p[3] = _mm_adds_epi16(p[3], v);
		p += 4;
		size -= 4 * sizeof(*p);
	} while (size != 0);
}
#define matchfinder_rebase matchfinder_rebase_sse2
#endif 

#  endif
#endif


#ifndef matchfinder_init
static forceinline void
matchfinder_init(mf_pos_t *data, size_t size)
{
	size_t num_entries = size / sizeof(*data);
	size_t i;

	for (i = 0; i < num_entries; i++)
		data[i] = MATCHFINDER_INITVAL;
}
#endif


#ifndef matchfinder_rebase
static forceinline void
matchfinder_rebase(mf_pos_t *data, size_t size)
{
	size_t num_entries = size / sizeof(*data);
	size_t i;

	if (MATCHFINDER_WINDOW_SIZE == 32768) {
		
		for (i = 0; i < num_entries; i++) {
			u16 v = data[i];
			u16 sign_bit = v & 0x8000;
			v &= sign_bit - ((sign_bit >> 15) ^ 1);
			v |= 0x8000;
			data[i] = v;
		}
		return;
	}

	for (i = 0; i < num_entries; i++) {
		if (data[i] >= 0)
			data[i] -= (mf_pos_t)-MATCHFINDER_WINDOW_SIZE;
		else
			data[i] = (mf_pos_t)-MATCHFINDER_WINDOW_SIZE;
	}
}
#endif


static forceinline u32
lz_hash(u32 seq, unsigned num_bits)
{
	return (u32)(seq * 0x1E35A7BD) >> (32 - num_bits);
}


static forceinline unsigned
lz_extend(const u8 * const strptr, const u8 * const matchptr,
	  const unsigned start_len, const unsigned max_len)
{
	unsigned len = start_len;
	machine_word_t v_word;

	if (UNALIGNED_ACCESS_IS_FAST) {

		if (likely(max_len - len >= 4 * WORDBYTES)) {

		#define COMPARE_WORD_STEP				\
			v_word = load_word_unaligned(&matchptr[len]) ^	\
				 load_word_unaligned(&strptr[len]);	\
			if (v_word != 0)				\
				goto word_differs;			\
			len += WORDBYTES;				\

			COMPARE_WORD_STEP
			COMPARE_WORD_STEP
			COMPARE_WORD_STEP
			COMPARE_WORD_STEP
		#undef COMPARE_WORD_STEP
		}

		while (len + WORDBYTES <= max_len) {
			v_word = load_word_unaligned(&matchptr[len]) ^
				 load_word_unaligned(&strptr[len]);
			if (v_word != 0)
				goto word_differs;
			len += WORDBYTES;
		}
	}

	while (len < max_len && matchptr[len] == strptr[len])
		len++;
	return len;

word_differs:
	if (CPU_IS_LITTLE_ENDIAN())
		len += (bsfw(v_word) >> 3);
	else
		len += (WORDBITS - 1 - bsrw(v_word)) >> 3;
	return len;
}

#endif 


#define BT_MATCHFINDER_HASH3_ORDER 16
#define BT_MATCHFINDER_HASH3_WAYS  2
#define BT_MATCHFINDER_HASH4_ORDER 16

#define BT_MATCHFINDER_TOTAL_HASH_SIZE		\
	(((1UL << BT_MATCHFINDER_HASH3_ORDER) * BT_MATCHFINDER_HASH3_WAYS + \
	  (1UL << BT_MATCHFINDER_HASH4_ORDER)) * sizeof(mf_pos_t))


struct lz_match {

	
	u16 length;

	
	u16 offset;
};

struct bt_matchfinder {

	
	mf_pos_t hash3_tab[1UL << BT_MATCHFINDER_HASH3_ORDER][BT_MATCHFINDER_HASH3_WAYS];

	
	mf_pos_t hash4_tab[1UL << BT_MATCHFINDER_HASH4_ORDER];

	
	mf_pos_t child_tab[2UL * MATCHFINDER_WINDOW_SIZE];

}
#ifdef _aligned_attribute
_aligned_attribute(MATCHFINDER_MEM_ALIGNMENT)
#endif
;


static forceinline void
bt_matchfinder_init(struct bt_matchfinder *mf)
{
	STATIC_ASSERT(BT_MATCHFINDER_TOTAL_HASH_SIZE %
		      MATCHFINDER_SIZE_ALIGNMENT == 0);

	matchfinder_init((mf_pos_t *)mf, BT_MATCHFINDER_TOTAL_HASH_SIZE);
}

static forceinline void
bt_matchfinder_slide_window(struct bt_matchfinder *mf)
{
	STATIC_ASSERT(sizeof(*mf) % MATCHFINDER_SIZE_ALIGNMENT == 0);

	matchfinder_rebase((mf_pos_t *)mf, sizeof(*mf));
}

static forceinline mf_pos_t *
bt_left_child(struct bt_matchfinder *mf, s32 node)
{
	return &mf->child_tab[2 * (node & (MATCHFINDER_WINDOW_SIZE - 1)) + 0];
}

static forceinline mf_pos_t *
bt_right_child(struct bt_matchfinder *mf, s32 node)
{
	return &mf->child_tab[2 * (node & (MATCHFINDER_WINDOW_SIZE - 1)) + 1];
}


#define BT_MATCHFINDER_REQUIRED_NBYTES	5


static forceinline struct lz_match *
bt_matchfinder_advance_one_byte(struct bt_matchfinder * const restrict mf,
				const u8 * const restrict in_base,
				const ptrdiff_t cur_pos,
				const u32 max_len,
				const u32 nice_len,
				const u32 max_search_depth,
				u32 * const restrict next_hashes,
				u32 * const restrict best_len_ret,
				struct lz_match * restrict lz_matchptr,
				const bool record_matches)
{
	const u8 *in_next = in_base + cur_pos;
	u32 depth_remaining = max_search_depth;
	const s32 cutoff = cur_pos - MATCHFINDER_WINDOW_SIZE;
	u32 next_hashseq;
	u32 hash3;
	u32 hash4;
	s32 cur_node;
#if BT_MATCHFINDER_HASH3_WAYS >= 2
	s32 cur_node_2;
#endif
	const u8 *matchptr;
	mf_pos_t *pending_lt_ptr, *pending_gt_ptr;
	u32 best_lt_len, best_gt_len;
	u32 len;
	u32 best_len = 3;

	STATIC_ASSERT(BT_MATCHFINDER_HASH3_WAYS >= 1 &&
		      BT_MATCHFINDER_HASH3_WAYS <= 2);

	next_hashseq = get_unaligned_le32(in_next + 1);

	hash3 = next_hashes[0];
	hash4 = next_hashes[1];

	next_hashes[0] = lz_hash(next_hashseq & 0xFFFFFF, BT_MATCHFINDER_HASH3_ORDER);
	next_hashes[1] = lz_hash(next_hashseq, BT_MATCHFINDER_HASH4_ORDER);
	prefetchw(&mf->hash3_tab[next_hashes[0]]);
	prefetchw(&mf->hash4_tab[next_hashes[1]]);

	cur_node = mf->hash3_tab[hash3][0];
	mf->hash3_tab[hash3][0] = cur_pos;
#if BT_MATCHFINDER_HASH3_WAYS >= 2
	cur_node_2 = mf->hash3_tab[hash3][1];
	mf->hash3_tab[hash3][1] = cur_node;
#endif
	if (record_matches && cur_node > cutoff) {
		u32 seq3 = load_u24_unaligned(in_next);
		if (seq3 == load_u24_unaligned(&in_base[cur_node])) {
			lz_matchptr->length = 3;
			lz_matchptr->offset = in_next - &in_base[cur_node];
			lz_matchptr++;
		}
	#if BT_MATCHFINDER_HASH3_WAYS >= 2
		else if (cur_node_2 > cutoff &&
			seq3 == load_u24_unaligned(&in_base[cur_node_2]))
		{
			lz_matchptr->length = 3;
			lz_matchptr->offset = in_next - &in_base[cur_node_2];
			lz_matchptr++;
		}
	#endif
	}

	cur_node = mf->hash4_tab[hash4];
	mf->hash4_tab[hash4] = cur_pos;

	pending_lt_ptr = bt_left_child(mf, cur_pos);
	pending_gt_ptr = bt_right_child(mf, cur_pos);

	if (cur_node <= cutoff) {
		*pending_lt_ptr = MATCHFINDER_INITVAL;
		*pending_gt_ptr = MATCHFINDER_INITVAL;
		*best_len_ret = best_len;
		return lz_matchptr;
	}

	best_lt_len = 0;
	best_gt_len = 0;
	len = 0;

	for (;;) {
		matchptr = &in_base[cur_node];

		if (matchptr[len] == in_next[len]) {
			len = lz_extend(in_next, matchptr, len + 1, max_len);
			if (!record_matches || len > best_len) {
				if (record_matches) {
					best_len = len;
					lz_matchptr->length = len;
					lz_matchptr->offset = in_next - matchptr;
					lz_matchptr++;
				}
				if (len >= nice_len) {
					*pending_lt_ptr = *bt_left_child(mf, cur_node);
					*pending_gt_ptr = *bt_right_child(mf, cur_node);
					*best_len_ret = best_len;
					return lz_matchptr;
				}
			}
		}

		if (matchptr[len] < in_next[len]) {
			*pending_lt_ptr = cur_node;
			pending_lt_ptr = bt_right_child(mf, cur_node);
			cur_node = *pending_lt_ptr;
			best_lt_len = len;
			if (best_gt_len < len)
				len = best_gt_len;
		} else {
			*pending_gt_ptr = cur_node;
			pending_gt_ptr = bt_left_child(mf, cur_node);
			cur_node = *pending_gt_ptr;
			best_gt_len = len;
			if (best_lt_len < len)
				len = best_lt_len;
		}

		if (cur_node <= cutoff || !--depth_remaining) {
			*pending_lt_ptr = MATCHFINDER_INITVAL;
			*pending_gt_ptr = MATCHFINDER_INITVAL;
			*best_len_ret = best_len;
			return lz_matchptr;
		}
	}
}


static forceinline struct lz_match *
bt_matchfinder_get_matches(struct bt_matchfinder *mf,
			   const u8 *in_base,
			   ptrdiff_t cur_pos,
			   u32 max_len,
			   u32 nice_len,
			   u32 max_search_depth,
			   u32 next_hashes[2],
			   u32 *best_len_ret,
			   struct lz_match *lz_matchptr)
{
	return bt_matchfinder_advance_one_byte(mf,
					       in_base,
					       cur_pos,
					       max_len,
					       nice_len,
					       max_search_depth,
					       next_hashes,
					       best_len_ret,
					       lz_matchptr,
					       true);
}


static forceinline void
bt_matchfinder_skip_position(struct bt_matchfinder *mf,
			     const u8 *in_base,
			     ptrdiff_t cur_pos,
			     u32 nice_len,
			     u32 max_search_depth,
			     u32 next_hashes[2])
{
	u32 best_len;
	bt_matchfinder_advance_one_byte(mf,
					in_base,
					cur_pos,
					nice_len,
					nice_len,
					max_search_depth,
					next_hashes,
					&best_len,
					NULL,
					false);
}

#endif


#define MIN_BLOCK_LENGTH	10000


#define SOFT_MAX_BLOCK_LENGTH	300000


#define NUM_OBSERVATIONS_PER_BLOCK_CHECK       512


#if SUPPORT_NEAR_OPTIMAL_PARSING



#  define MAX_MATCHES_PER_POS	(DEFLATE_MAX_MATCH_LEN - DEFLATE_MIN_MATCH_LEN + 1)


#  define CACHE_LENGTH      (SOFT_MAX_BLOCK_LENGTH * 5)

#endif 


#define MAX_LITLEN_CODEWORD_LEN		14
#define MAX_OFFSET_CODEWORD_LEN		DEFLATE_MAX_OFFSET_CODEWORD_LEN
#define MAX_PRE_CODEWORD_LEN		DEFLATE_MAX_PRE_CODEWORD_LEN


static const unsigned deflate_length_slot_base[] = {
	3   , 4   , 5   , 6   , 7   , 8   , 9   , 10  ,
	11  , 13  , 15  , 17  , 19  , 23  , 27  , 31  ,
	35  , 43  , 51  , 59  , 67  , 83  , 99  , 115 ,
	131 , 163 , 195 , 227 , 258 ,
};


static const u8 deflate_extra_length_bits[] = {
	0   , 0   , 0   , 0   , 0   , 0   , 0   , 0 ,
	1   , 1   , 1   , 1   , 2   , 2   , 2   , 2 ,
	3   , 3   , 3   , 3   , 4   , 4   , 4   , 4 ,
	5   , 5   , 5   , 5   , 0   ,
};


static const unsigned deflate_offset_slot_base[] = {
	1    , 2    , 3    , 4     , 5     , 7     , 9     , 13    ,
	17   , 25   , 33   , 49    , 65    , 97    , 129   , 193   ,
	257  , 385  , 513  , 769   , 1025  , 1537  , 2049  , 3073  ,
	4097 , 6145 , 8193 , 12289 , 16385 , 24577 ,
};


static const u8 deflate_extra_offset_bits[] = {
	0    , 0    , 0    , 0     , 1     , 1     , 2     , 2     ,
	3    , 3    , 4    , 4     , 5     , 5     , 6     , 6     ,
	7    , 7    , 8    , 8     , 9     , 9     , 10    , 10    ,
	11   , 11   , 12   , 12    , 13    , 13    ,
};


static const u8 deflate_length_slot[DEFLATE_MAX_MATCH_LEN + 1] = {
	0, 0, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 12,
	12, 13, 13, 13, 13, 14, 14, 14, 14, 15, 15, 15, 15, 16, 16, 16, 16, 16,
	16, 16, 16, 17, 17, 17, 17, 17, 17, 17, 17, 18, 18, 18, 18, 18, 18, 18,
	18, 19, 19, 19, 19, 19, 19, 19, 19, 20, 20, 20, 20, 20, 20, 20, 20, 20,
	20, 20, 20, 20, 20, 20, 20, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21,
	21, 21, 21, 21, 21, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22,
	22, 22, 22, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23,
	23, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24,
	24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 25, 25, 25,
	25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25,
	25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 26, 26, 26, 26, 26, 26, 26,
	26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26,
	26, 26, 26, 26, 26, 26, 26, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27,
	27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27,
	27, 27, 28,
};


static const u8 deflate_precode_lens_permutation[DEFLATE_NUM_PRECODE_SYMS] = {
	16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15
};


struct deflate_codewords {
	u32 litlen[DEFLATE_NUM_LITLEN_SYMS];
	u32 offset[DEFLATE_NUM_OFFSET_SYMS];
};


struct deflate_lens {
	u8 litlen[DEFLATE_NUM_LITLEN_SYMS];
	u8 offset[DEFLATE_NUM_OFFSET_SYMS];
};


struct deflate_codes {
	struct deflate_codewords codewords;
	struct deflate_lens lens;
};


struct deflate_freqs {
	u32 litlen[DEFLATE_NUM_LITLEN_SYMS];
	u32 offset[DEFLATE_NUM_OFFSET_SYMS];
};

#if SUPPORT_NEAR_OPTIMAL_PARSING


struct deflate_costs {

	
	u32 literal[DEFLATE_NUM_LITERALS];

	
	u32 length[DEFLATE_MAX_MATCH_LEN + 1];

	
	u32 offset_slot[DEFLATE_NUM_OFFSET_SYMS];
};


#define COST_SHIFT	3


#define LITERAL_NOSTAT_BITS	13
#define LENGTH_NOSTAT_BITS	13
#define OFFSET_NOSTAT_BITS	10

#endif 


struct deflate_sequence {

	
	u32 litrunlen_and_length;

	
	u16 offset;

	
	u8 offset_symbol;

	
	u8 length_slot;
};

#if SUPPORT_NEAR_OPTIMAL_PARSING


struct deflate_optimum_node {

	u32 cost_to_end;

	
#define OPTIMUM_OFFSET_SHIFT 9
#define OPTIMUM_LEN_MASK (((u32)1 << OPTIMUM_OFFSET_SHIFT) - 1)
	u32 item;

};

#endif 


#define NUM_LITERAL_OBSERVATION_TYPES 8
#define NUM_MATCH_OBSERVATION_TYPES 2
#define NUM_OBSERVATION_TYPES (NUM_LITERAL_OBSERVATION_TYPES + NUM_MATCH_OBSERVATION_TYPES)
struct block_split_stats {
	u32 new_observations[NUM_OBSERVATION_TYPES];
	u32 observations[NUM_OBSERVATION_TYPES];
	u32 num_new_observations;
	u32 num_observations;
};


struct libdeflate_compressor {

	
	size_t (*impl)(struct libdeflate_compressor *,
		       const u8 *, size_t, u8 *, size_t);

	
	struct deflate_freqs freqs;

	
	struct deflate_codes codes;

	
	struct deflate_codes static_codes;

	
	struct block_split_stats split_stats;

	
#if USE_FULL_OFFSET_SLOT_FAST
	u8 offset_slot_fast[DEFLATE_MAX_MATCH_OFFSET + 1];
#else
	u8 offset_slot_fast[512];
#endif

	
	unsigned nice_match_length;

	
	unsigned max_search_depth;

	
	unsigned compression_level;

	
	unsigned min_size_to_compress;

	
	u32 precode_freqs[DEFLATE_NUM_PRECODE_SYMS];
	u8 precode_lens[DEFLATE_NUM_PRECODE_SYMS];
	u32 precode_codewords[DEFLATE_NUM_PRECODE_SYMS];
	unsigned precode_items[DEFLATE_NUM_LITLEN_SYMS + DEFLATE_NUM_OFFSET_SYMS];
	unsigned num_litlen_syms;
	unsigned num_offset_syms;
	unsigned num_explicit_lens;
	unsigned num_precode_items;

	union {
		
		struct {
			
			struct hc_matchfinder hc_mf;

			
			struct deflate_sequence sequences[
				DIV_ROUND_UP(SOFT_MAX_BLOCK_LENGTH,
					     DEFLATE_MIN_MATCH_LEN) + 1];
		} g; 

	#if SUPPORT_NEAR_OPTIMAL_PARSING
		
		struct {

			
			struct bt_matchfinder bt_mf;

			
			struct lz_match match_cache[CACHE_LENGTH +
						    MAX_MATCHES_PER_POS +
						    DEFLATE_MAX_MATCH_LEN - 1];

			
			struct deflate_optimum_node optimum_nodes[SOFT_MAX_BLOCK_LENGTH - 1 +
								  DEFLATE_MAX_MATCH_LEN + 1];

			
			struct deflate_costs costs;

			unsigned num_optim_passes;
		} n; 
	#endif 

	} p; 
};


typedef machine_word_t bitbuf_t;
#define COMPRESS_BITBUF_NBITS	(8 * sizeof(bitbuf_t))


#define CAN_BUFFER(n)	((n) <= COMPRESS_BITBUF_NBITS - 7)


struct deflate_output_bitstream {

	
	bitbuf_t bitbuf;

	
	unsigned bitcount;

	
	u8 *begin;

	
	u8 *next;

	
	u8 *end;
};


#define OUTPUT_END_PADDING	8


static void
deflate_init_output(struct deflate_output_bitstream *os,
		    void *buffer, size_t size)
{
	os->bitbuf = 0;
	os->bitcount = 0;
	os->begin = buffer;
	os->next = os->begin;
	os->end = os->begin + size - OUTPUT_END_PADDING;
}


static forceinline void
deflate_add_bits(struct deflate_output_bitstream *os,
		 const bitbuf_t bits, const unsigned num_bits)
{
	os->bitbuf |= bits << os->bitcount;
	os->bitcount += num_bits;
}


static forceinline void
deflate_flush_bits(struct deflate_output_bitstream *os)
{
	if (UNALIGNED_ACCESS_IS_FAST) {
		
		put_unaligned_leword(os->bitbuf, os->next);
		os->bitbuf >>= os->bitcount & ~7;
		os->next += MIN(os->end - os->next, os->bitcount >> 3);
		os->bitcount &= 7;
	} else {
		
		while (os->bitcount >= 8) {
			*os->next = os->bitbuf;
			if (os->next != os->end)
				os->next++;
			os->bitcount -= 8;
			os->bitbuf >>= 8;
		}
	}
}


static forceinline void
deflate_align_bitstream(struct deflate_output_bitstream *os)
{
	os->bitcount += -os->bitcount & 7;
	deflate_flush_bits(os);
}


static size_t
deflate_flush_output(struct deflate_output_bitstream *os)
{
	if (os->next == os->end) 
		return 0;

	while ((int)os->bitcount > 0) {
		*os->next++ = os->bitbuf;
		os->bitcount -= 8;
		os->bitbuf >>= 8;
	}

	return os->next - os->begin;
}


static void
heapify_subtree(u32 A[], unsigned length, unsigned subtree_idx)
{
	unsigned parent_idx;
	unsigned child_idx;
	u32 v;

	v = A[subtree_idx];
	parent_idx = subtree_idx;
	while ((child_idx = parent_idx * 2) <= length) {
		if (child_idx < length && A[child_idx + 1] > A[child_idx])
			child_idx++;
		if (v >= A[child_idx])
			break;
		A[parent_idx] = A[child_idx];
		parent_idx = child_idx;
	}
	A[parent_idx] = v;
}


static void
heapify_array(u32 A[], unsigned length)
{
	unsigned subtree_idx;

	for (subtree_idx = length / 2; subtree_idx >= 1; subtree_idx--)
		heapify_subtree(A, length, subtree_idx);
}


static void
heap_sort(u32 A[], unsigned length)
{
	A--; 

	heapify_array(A, length);

	while (length >= 2) {
		u32 tmp = A[length];
		A[length] = A[1];
		A[1] = tmp;
		length--;
		heapify_subtree(A, length, 1);
	}
}

#define NUM_SYMBOL_BITS 10
#define SYMBOL_MASK ((1 << NUM_SYMBOL_BITS) - 1)

#define GET_NUM_COUNTERS(num_syms)	((((num_syms) + 3 / 4) + 3) & ~3)

static unsigned
sort_symbols(unsigned num_syms, const u32 freqs[restrict],
	     u8 lens[restrict], u32 symout[restrict])
{
	unsigned sym;
	unsigned i;
	unsigned num_used_syms;
	unsigned num_counters;
	unsigned counters[GET_NUM_COUNTERS(DEFLATE_MAX_NUM_SYMS)];

	

	num_counters = GET_NUM_COUNTERS(num_syms);

	memset(counters, 0, num_counters * sizeof(counters[0]));

	
	for (sym = 0; sym < num_syms; sym++)
		counters[MIN(freqs[sym], num_counters - 1)]++;

	
	num_used_syms = 0;
	for (i = 1; i < num_counters; i++) {
		unsigned count = counters[i];
		counters[i] = num_used_syms;
		num_used_syms += count;
	}

	
	for (sym = 0; sym < num_syms; sym++) {
		u32 freq = freqs[sym];
		if (freq != 0) {
			symout[counters[MIN(freq, num_counters - 1)]++] =
				sym | (freq << NUM_SYMBOL_BITS);
		} else {
			lens[sym] = 0;
		}
	}

	
	heap_sort(symout + counters[num_counters - 2],
		  counters[num_counters - 1] - counters[num_counters - 2]);

	return num_used_syms;
}


static void
build_tree(u32 A[], unsigned sym_count)
{
	
	unsigned i = 0;

	
	unsigned b = 0;

	
	unsigned e = 0;

	do {
		unsigned m, n;
		u32 freq_shifted;

		

		if (i != sym_count &&
		    (b == e || (A[i] >> NUM_SYMBOL_BITS) <= (A[b] >> NUM_SYMBOL_BITS)))
			m = i++;
		else
			m = b++;

		if (i != sym_count &&
		    (b == e || (A[i] >> NUM_SYMBOL_BITS) <= (A[b] >> NUM_SYMBOL_BITS)))
			n = i++;
		else
			n = b++;

		

		freq_shifted = (A[m] & ~SYMBOL_MASK) + (A[n] & ~SYMBOL_MASK);

		A[m] = (A[m] & SYMBOL_MASK) | (e << NUM_SYMBOL_BITS);
		A[n] = (A[n] & SYMBOL_MASK) | (e << NUM_SYMBOL_BITS);
		A[e] = (A[e] & SYMBOL_MASK) | freq_shifted;
		e++;
	} while (sym_count - e > 1);
		
}


static void
compute_length_counts(u32 A[restrict], unsigned root_idx,
		      unsigned len_counts[restrict], unsigned max_codeword_len)
{
	unsigned len;
	int node;

	

	for (len = 0; len <= max_codeword_len; len++)
		len_counts[len] = 0;
	len_counts[1] = 2;

	
	A[root_idx] &= SYMBOL_MASK;

	for (node = root_idx - 1; node >= 0; node--) {

		

		unsigned parent = A[node] >> NUM_SYMBOL_BITS;
		unsigned parent_depth = A[parent] >> NUM_SYMBOL_BITS;
		unsigned depth = parent_depth + 1;
		unsigned len = depth;

		

		A[node] = (A[node] & SYMBOL_MASK) | (depth << NUM_SYMBOL_BITS);

		
		if (len >= max_codeword_len) {
			len = max_codeword_len;
			do {
				len--;
			} while (len_counts[len] == 0);
		}

		
		len_counts[len]--;
		len_counts[len + 1] += 2;
	}
}


static void
gen_codewords(u32 A[restrict], u8 lens[restrict],
	      const unsigned len_counts[restrict],
	      unsigned max_codeword_len, unsigned num_syms)
{
	u32 next_codewords[DEFLATE_MAX_CODEWORD_LEN + 1];
	unsigned i;
	unsigned len;
	unsigned sym;

	
	for (i = 0, len = max_codeword_len; len >= 1; len--) {
		unsigned count = len_counts[len];
		while (count--)
			lens[A[i++] & SYMBOL_MASK] = len;
	}

	
	next_codewords[0] = 0;
	next_codewords[1] = 0;
	for (len = 2; len <= max_codeword_len; len++)
		next_codewords[len] =
			(next_codewords[len - 1] + len_counts[len - 1]) << 1;

	for (sym = 0; sym < num_syms; sym++)
		A[sym] = next_codewords[lens[sym]]++;
}


static void
make_canonical_huffman_code(unsigned num_syms, unsigned max_codeword_len,
			    const u32 freqs[restrict],
			    u8 lens[restrict], u32 codewords[restrict])
{
	u32 *A = codewords;
	unsigned num_used_syms;

	STATIC_ASSERT(DEFLATE_MAX_NUM_SYMS <= 1 << NUM_SYMBOL_BITS);

	

	num_used_syms = sort_symbols(num_syms, freqs, lens, A);

	

	

	if (unlikely(num_used_syms == 0)) {
		
		return;
	}

	if (unlikely(num_used_syms == 1)) {
		

		unsigned sym = A[0] & SYMBOL_MASK;
		unsigned nonzero_idx = sym ? sym : 1;

		codewords[0] = 0;
		lens[0] = 1;
		codewords[nonzero_idx] = 1;
		lens[nonzero_idx] = 1;
		return;
	}

	

	build_tree(A, num_used_syms);

	{
		unsigned len_counts[DEFLATE_MAX_CODEWORD_LEN + 1];

		compute_length_counts(A, num_used_syms - 2,
				      len_counts, max_codeword_len);

		gen_codewords(A, lens, len_counts, max_codeword_len, num_syms);
	}
}


static void
deflate_reset_symbol_frequencies(struct libdeflate_compressor *c)
{
	memset(&c->freqs, 0, sizeof(c->freqs));
}


static u32
deflate_reverse_codeword(u32 codeword, u8 len)
{
	
	STATIC_ASSERT(DEFLATE_MAX_CODEWORD_LEN <= 16);

	
	codeword = ((codeword & 0x5555) << 1) | ((codeword & 0xAAAA) >> 1);

	
	codeword = ((codeword & 0x3333) << 2) | ((codeword & 0xCCCC) >> 2);

	
	codeword = ((codeword & 0x0F0F) << 4) | ((codeword & 0xF0F0) >> 4);

	
	codeword = ((codeword & 0x00FF) << 8) | ((codeword & 0xFF00) >> 8);

	
	return codeword >> (16 - len);
}


static void
deflate_make_huffman_code(unsigned num_syms, unsigned max_codeword_len,
			  const u32 freqs[], u8 lens[], u32 codewords[])
{
	unsigned sym;

	make_canonical_huffman_code(num_syms, max_codeword_len,
				    freqs, lens, codewords);

	for (sym = 0; sym < num_syms; sym++)
		codewords[sym] = deflate_reverse_codeword(codewords[sym], lens[sym]);
}


static void
deflate_make_huffman_codes(const struct deflate_freqs *freqs,
			   struct deflate_codes *codes)
{
	STATIC_ASSERT(MAX_LITLEN_CODEWORD_LEN <= DEFLATE_MAX_LITLEN_CODEWORD_LEN);
	STATIC_ASSERT(MAX_OFFSET_CODEWORD_LEN <= DEFLATE_MAX_OFFSET_CODEWORD_LEN);

	deflate_make_huffman_code(DEFLATE_NUM_LITLEN_SYMS,
				  MAX_LITLEN_CODEWORD_LEN,
				  freqs->litlen,
				  codes->lens.litlen,
				  codes->codewords.litlen);

	deflate_make_huffman_code(DEFLATE_NUM_OFFSET_SYMS,
				  MAX_OFFSET_CODEWORD_LEN,
				  freqs->offset,
				  codes->lens.offset,
				  codes->codewords.offset);
}


static void
deflate_init_static_codes(struct libdeflate_compressor *c)
{
	unsigned i;

	for (i = 0; i < 144; i++)
		c->freqs.litlen[i] = 1 << (9 - 8);
	for (; i < 256; i++)
		c->freqs.litlen[i] = 1 << (9 - 9);
	for (; i < 280; i++)
		c->freqs.litlen[i] = 1 << (9 - 7);
	for (; i < 288; i++)
		c->freqs.litlen[i] = 1 << (9 - 8);

	for (i = 0; i < 32; i++)
		c->freqs.offset[i] = 1 << (5 - 5);

	deflate_make_huffman_codes(&c->freqs, &c->static_codes);
}


static forceinline unsigned
deflate_get_offset_slot(struct libdeflate_compressor *c, unsigned offset)
{
#if USE_FULL_OFFSET_SLOT_FAST
	return c->offset_slot_fast[offset];
#else
	if (offset <= 256)
		return c->offset_slot_fast[offset - 1];
	else
		return c->offset_slot_fast[256 + ((offset - 1) >> 7)];
#endif
}


static void
deflate_write_block_header(struct deflate_output_bitstream *os,
			   bool is_final_block, unsigned block_type)
{
	deflate_add_bits(os, is_final_block, 1);
	deflate_add_bits(os, block_type, 2);
	deflate_flush_bits(os);
}

static unsigned
deflate_compute_precode_items(const u8 lens[restrict],
			      const unsigned num_lens,
			      u32 precode_freqs[restrict],
			      unsigned precode_items[restrict])
{
	unsigned *itemptr;
	unsigned run_start;
	unsigned run_end;
	unsigned extra_bits;
	u8 len;

	memset(precode_freqs, 0,
	       DEFLATE_NUM_PRECODE_SYMS * sizeof(precode_freqs[0]));

	itemptr = precode_items;
	run_start = 0;
	do {
		

		
		len = lens[run_start];

		
		run_end = run_start;
		do {
			run_end++;
		} while (run_end != num_lens && len == lens[run_end]);

		if (len == 0) {
			

			
			while ((run_end - run_start) >= 11) {
				extra_bits = MIN((run_end - run_start) - 11, 0x7F);
				precode_freqs[18]++;
				*itemptr++ = 18 | (extra_bits << 5);
				run_start += 11 + extra_bits;
			}

			
			if ((run_end - run_start) >= 3) {
				extra_bits = MIN((run_end - run_start) - 3, 0x7);
				precode_freqs[17]++;
				*itemptr++ = 17 | (extra_bits << 5);
				run_start += 3 + extra_bits;
			}
		} else {

			

			
			if ((run_end - run_start) >= 4) {
				precode_freqs[len]++;
				*itemptr++ = len;
				run_start++;
				do {
					extra_bits = MIN((run_end - run_start) - 3, 0x3);
					precode_freqs[16]++;
					*itemptr++ = 16 | (extra_bits << 5);
					run_start += 3 + extra_bits;
				} while ((run_end - run_start) >= 3);
			}
		}

		
		while (run_start != run_end) {
			precode_freqs[len]++;
			*itemptr++ = len;
			run_start++;
		}
	} while (run_start != num_lens);

	return itemptr - precode_items;
}




static void
deflate_precompute_huffman_header(struct libdeflate_compressor *c)
{
	

	for (c->num_litlen_syms = DEFLATE_NUM_LITLEN_SYMS;
	     c->num_litlen_syms > 257;
	     c->num_litlen_syms--)
		if (c->codes.lens.litlen[c->num_litlen_syms - 1] != 0)
			break;

	for (c->num_offset_syms = DEFLATE_NUM_OFFSET_SYMS;
	     c->num_offset_syms > 1;
	     c->num_offset_syms--)
		if (c->codes.lens.offset[c->num_offset_syms - 1] != 0)
			break;

	

	STATIC_ASSERT(offsetof(struct deflate_lens, offset) ==
		      DEFLATE_NUM_LITLEN_SYMS);

	if (c->num_litlen_syms != DEFLATE_NUM_LITLEN_SYMS) {
		memmove((u8 *)&c->codes.lens + c->num_litlen_syms,
			(u8 *)&c->codes.lens + DEFLATE_NUM_LITLEN_SYMS,
			c->num_offset_syms);
	}

	
	c->num_precode_items =
		deflate_compute_precode_items((u8 *)&c->codes.lens,
					      c->num_litlen_syms +
							c->num_offset_syms,
					      c->precode_freqs,
					      c->precode_items);

	
	STATIC_ASSERT(MAX_PRE_CODEWORD_LEN <= DEFLATE_MAX_PRE_CODEWORD_LEN);
	deflate_make_huffman_code(DEFLATE_NUM_PRECODE_SYMS,
				  MAX_PRE_CODEWORD_LEN,
				  c->precode_freqs, c->precode_lens,
				  c->precode_codewords);

	
	for (c->num_explicit_lens = DEFLATE_NUM_PRECODE_SYMS;
	     c->num_explicit_lens > 4;
	     c->num_explicit_lens--)
		if (c->precode_lens[deflate_precode_lens_permutation[
						c->num_explicit_lens - 1]] != 0)
			break;

	
	if (c->num_litlen_syms != DEFLATE_NUM_LITLEN_SYMS) {
		memmove((u8 *)&c->codes.lens + DEFLATE_NUM_LITLEN_SYMS,
			(u8 *)&c->codes.lens + c->num_litlen_syms,
			c->num_offset_syms);
	}
}


static void
deflate_write_huffman_header(struct libdeflate_compressor *c,
			     struct deflate_output_bitstream *os)
{
	unsigned i;

	deflate_add_bits(os, c->num_litlen_syms - 257, 5);
	deflate_add_bits(os, c->num_offset_syms - 1, 5);
	deflate_add_bits(os, c->num_explicit_lens - 4, 4);
	deflate_flush_bits(os);

	
	for (i = 0; i < c->num_explicit_lens; i++) {
		deflate_add_bits(os, c->precode_lens[
				       deflate_precode_lens_permutation[i]], 3);
		deflate_flush_bits(os);
	}

	
	for (i = 0; i < c->num_precode_items; i++) {
		unsigned precode_item = c->precode_items[i];
		unsigned precode_sym = precode_item & 0x1F;
		deflate_add_bits(os, c->precode_codewords[precode_sym],
				 c->precode_lens[precode_sym]);
		if (precode_sym >= 16) {
			if (precode_sym == 16)
				deflate_add_bits(os, precode_item >> 5, 2);
			else if (precode_sym == 17)
				deflate_add_bits(os, precode_item >> 5, 3);
			else
				deflate_add_bits(os, precode_item >> 5, 7);
		}
		STATIC_ASSERT(CAN_BUFFER(DEFLATE_MAX_PRE_CODEWORD_LEN + 7));
		deflate_flush_bits(os);
	}
}

static void
deflate_write_sequences(struct deflate_output_bitstream * restrict os,
			const struct deflate_codes * restrict codes,
			const struct deflate_sequence sequences[restrict],
			const u8 * restrict in_next)
{
	const struct deflate_sequence *seq = sequences;

	for (;;) {
		u32 litrunlen = seq->litrunlen_and_length & 0x7FFFFF;
		unsigned length = seq->litrunlen_and_length >> 23;
		unsigned length_slot;
		unsigned litlen_symbol;
		unsigned offset_symbol;

		if (litrunlen) {
		#if 1
			while (litrunlen >= 4) {
				unsigned lit0 = in_next[0];
				unsigned lit1 = in_next[1];
				unsigned lit2 = in_next[2];
				unsigned lit3 = in_next[3];

				deflate_add_bits(os, codes->codewords.litlen[lit0],
						 codes->lens.litlen[lit0]);
				if (!CAN_BUFFER(2 * MAX_LITLEN_CODEWORD_LEN))
					deflate_flush_bits(os);

				deflate_add_bits(os, codes->codewords.litlen[lit1],
						 codes->lens.litlen[lit1]);
				if (!CAN_BUFFER(4 * MAX_LITLEN_CODEWORD_LEN))
					deflate_flush_bits(os);

				deflate_add_bits(os, codes->codewords.litlen[lit2],
						 codes->lens.litlen[lit2]);
				if (!CAN_BUFFER(2 * MAX_LITLEN_CODEWORD_LEN))
					deflate_flush_bits(os);

				deflate_add_bits(os, codes->codewords.litlen[lit3],
						 codes->lens.litlen[lit3]);
				deflate_flush_bits(os);
				in_next += 4;
				litrunlen -= 4;
			}
			if (litrunlen-- != 0) {
				deflate_add_bits(os, codes->codewords.litlen[*in_next],
						 codes->lens.litlen[*in_next]);
				if (!CAN_BUFFER(3 * MAX_LITLEN_CODEWORD_LEN))
					deflate_flush_bits(os);
				in_next++;
				if (litrunlen-- != 0) {
					deflate_add_bits(os, codes->codewords.litlen[*in_next],
							 codes->lens.litlen[*in_next]);
					if (!CAN_BUFFER(3 * MAX_LITLEN_CODEWORD_LEN))
						deflate_flush_bits(os);
					in_next++;
					if (litrunlen-- != 0) {
						deflate_add_bits(os, codes->codewords.litlen[*in_next],
								 codes->lens.litlen[*in_next]);
						if (!CAN_BUFFER(3 * MAX_LITLEN_CODEWORD_LEN))
							deflate_flush_bits(os);
						in_next++;
					}
				}
				if (CAN_BUFFER(3 * MAX_LITLEN_CODEWORD_LEN))
					deflate_flush_bits(os);
			}
		#else
			do {
				unsigned lit = *in_next++;
				deflate_add_bits(os, codes->codewords.litlen[lit],
						 codes->lens.litlen[lit]);
				deflate_flush_bits(os);
			} while (--litrunlen);
		#endif
		}

		if (length == 0)
			return;

		in_next += length;

		length_slot = seq->length_slot;
		litlen_symbol = 257 + length_slot;

		
		deflate_add_bits(os, codes->codewords.litlen[litlen_symbol],
				 codes->lens.litlen[litlen_symbol]);

		
		STATIC_ASSERT(CAN_BUFFER(MAX_LITLEN_CODEWORD_LEN +
					 DEFLATE_MAX_EXTRA_LENGTH_BITS));
		deflate_add_bits(os, length - deflate_length_slot_base[length_slot],
				 deflate_extra_length_bits[length_slot]);

		if (!CAN_BUFFER(MAX_LITLEN_CODEWORD_LEN +
				DEFLATE_MAX_EXTRA_LENGTH_BITS +
				MAX_OFFSET_CODEWORD_LEN +
				DEFLATE_MAX_EXTRA_OFFSET_BITS))
			deflate_flush_bits(os);

		
		offset_symbol = seq->offset_symbol;
		deflate_add_bits(os, codes->codewords.offset[offset_symbol],
				 codes->lens.offset[offset_symbol]);

		if (!CAN_BUFFER(MAX_OFFSET_CODEWORD_LEN +
				DEFLATE_MAX_EXTRA_OFFSET_BITS))
			deflate_flush_bits(os);

		
		deflate_add_bits(os, seq->offset - deflate_offset_slot_base[offset_symbol],
				 deflate_extra_offset_bits[offset_symbol]);

		deflate_flush_bits(os);

		seq++;
	}
}

#if SUPPORT_NEAR_OPTIMAL_PARSING

static void
deflate_write_item_list(struct deflate_output_bitstream *os,
			const struct deflate_codes *codes,
			struct libdeflate_compressor *c,
			u32 block_length)
{
	struct deflate_optimum_node *cur_node = &c->p.n.optimum_nodes[0];
	struct deflate_optimum_node * const end_node = &c->p.n.optimum_nodes[block_length];
	do {
		unsigned length = cur_node->item & OPTIMUM_LEN_MASK;
		unsigned offset = cur_node->item >> OPTIMUM_OFFSET_SHIFT;
		unsigned litlen_symbol;
		unsigned length_slot;
		unsigned offset_slot;

		if (length == 1) {
			
			litlen_symbol = offset;
			deflate_add_bits(os, codes->codewords.litlen[litlen_symbol],
					 codes->lens.litlen[litlen_symbol]);
			deflate_flush_bits(os);
		} else {
			
			length_slot = deflate_length_slot[length];
			litlen_symbol = 257 + length_slot;
			deflate_add_bits(os, codes->codewords.litlen[litlen_symbol],
					 codes->lens.litlen[litlen_symbol]);

			deflate_add_bits(os, length - deflate_length_slot_base[length_slot],
					 deflate_extra_length_bits[length_slot]);

			if (!CAN_BUFFER(MAX_LITLEN_CODEWORD_LEN +
					DEFLATE_MAX_EXTRA_LENGTH_BITS +
					MAX_OFFSET_CODEWORD_LEN +
					DEFLATE_MAX_EXTRA_OFFSET_BITS))
				deflate_flush_bits(os);


			
			offset_slot = deflate_get_offset_slot(c, offset);
			deflate_add_bits(os, codes->codewords.offset[offset_slot],
					 codes->lens.offset[offset_slot]);

			if (!CAN_BUFFER(MAX_OFFSET_CODEWORD_LEN +
					DEFLATE_MAX_EXTRA_OFFSET_BITS))
				deflate_flush_bits(os);

			deflate_add_bits(os, offset - deflate_offset_slot_base[offset_slot],
					 deflate_extra_offset_bits[offset_slot]);

			deflate_flush_bits(os);
		}
		cur_node += length;
	} while (cur_node != end_node);
}
#endif 


static void
deflate_write_end_of_block(struct deflate_output_bitstream *os,
			   const struct deflate_codes *codes)
{
	deflate_add_bits(os, codes->codewords.litlen[DEFLATE_END_OF_BLOCK],
			 codes->lens.litlen[DEFLATE_END_OF_BLOCK]);
	deflate_flush_bits(os);
}

static void
deflate_write_uncompressed_block(struct deflate_output_bitstream *os,
				 const u8 *data, u16 len,
				 bool is_final_block)
{
	deflate_write_block_header(os, is_final_block,
				   DEFLATE_BLOCKTYPE_UNCOMPRESSED);
	deflate_align_bitstream(os);

	if (4 + (u32)len >= os->end - os->next) {
		os->next = os->end;
		return;
	}

	put_unaligned_le16(len, os->next);
	os->next += 2;
	put_unaligned_le16(~len, os->next);
	os->next += 2;
	memcpy(os->next, data, len);
	os->next += len;
}

static void
deflate_write_uncompressed_blocks(struct deflate_output_bitstream *os,
				  const u8 *data, size_t data_length,
				  bool is_final_block)
{
	do {
		u16 len = MIN(data_length, UINT16_MAX);

		deflate_write_uncompressed_block(os, data, len,
					is_final_block && len == data_length);
		data += len;
		data_length -= len;
	} while (data_length != 0);
}


static void
deflate_flush_block(struct libdeflate_compressor * restrict c,
		    struct deflate_output_bitstream * restrict os,
		    const u8 * restrict block_begin, u32 block_length,
		    bool is_final_block, bool use_item_list)
{
	static const u8 deflate_extra_precode_bits[DEFLATE_NUM_PRECODE_SYMS] = {
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 3, 7,
	};

	
	u32 dynamic_cost = 0;
	u32 static_cost = 0;
	u32 uncompressed_cost = 0;
	struct deflate_codes *codes;
	int block_type;
	unsigned sym;

	
	c->freqs.litlen[DEFLATE_END_OF_BLOCK]++;

	
	deflate_make_huffman_codes(&c->freqs, &c->codes);

	
	deflate_precompute_huffman_header(c);
	dynamic_cost += 5 + 5 + 4 + (3 * c->num_explicit_lens);
	for (sym = 0; sym < DEFLATE_NUM_PRECODE_SYMS; sym++) {
		u32 extra = deflate_extra_precode_bits[sym];
		dynamic_cost += c->precode_freqs[sym] *
				(extra + c->precode_lens[sym]);
	}

	
	for (sym = 0; sym < 256; sym++) {
		dynamic_cost += c->freqs.litlen[sym] *
				c->codes.lens.litlen[sym];
	}
	for (sym = 0; sym < 144; sym++)
		static_cost += c->freqs.litlen[sym] * 8;
	for (; sym < 256; sym++)
		static_cost += c->freqs.litlen[sym] * 9;

	
	dynamic_cost += c->codes.lens.litlen[256];
	static_cost += 7;

	
	for (sym = 257; sym < 257 + ARRAY_LEN(deflate_extra_length_bits); sym++) {
		u32 extra = deflate_extra_length_bits[sym - 257];
		dynamic_cost += c->freqs.litlen[sym] *
				(extra + c->codes.lens.litlen[sym]);
		static_cost += c->freqs.litlen[sym] *
				(extra + c->static_codes.lens.litlen[sym]);
	}

	
	for (sym = 0; sym < ARRAY_LEN(deflate_extra_offset_bits); sym++) {
		u32 extra = deflate_extra_offset_bits[sym];
		dynamic_cost += c->freqs.offset[sym] *
				(extra + c->codes.lens.offset[sym]);
		static_cost += c->freqs.offset[sym] * (extra + 5);
	}

	
	uncompressed_cost += (-(os->bitcount + 3) & 7) + 32 +
			     (40 * (DIV_ROUND_UP(block_length,
						 UINT16_MAX) - 1)) +
			     (8 * block_length);

	
	if (dynamic_cost < MIN(static_cost, uncompressed_cost)) {
		block_type = DEFLATE_BLOCKTYPE_DYNAMIC_HUFFMAN;
		codes = &c->codes;
	} else if (static_cost < uncompressed_cost) {
		block_type = DEFLATE_BLOCKTYPE_STATIC_HUFFMAN;
		codes = &c->static_codes;
	} else {
		block_type = DEFLATE_BLOCKTYPE_UNCOMPRESSED;
	}

	

	if (block_type == DEFLATE_BLOCKTYPE_UNCOMPRESSED) {
		
		deflate_write_uncompressed_blocks(os, block_begin, block_length,
						  is_final_block);
	} else {
		
		deflate_write_block_header(os, is_final_block, block_type);

		
		if (block_type == DEFLATE_BLOCKTYPE_DYNAMIC_HUFFMAN)
			deflate_write_huffman_header(c, os);

		
	#if SUPPORT_NEAR_OPTIMAL_PARSING
		if (use_item_list)
			deflate_write_item_list(os, codes, c, block_length);
		else
	#endif
			deflate_write_sequences(os, codes, c->p.g.sequences,
						block_begin);
		deflate_write_end_of_block(os, codes);
	}
}

static forceinline void
deflate_choose_literal(struct libdeflate_compressor *c, unsigned literal,
		       u32 *litrunlen_p)
{
	c->freqs.litlen[literal]++;
	++*litrunlen_p;
}

static forceinline void
deflate_choose_match(struct libdeflate_compressor *c,
		     unsigned length, unsigned offset,
		     u32 *litrunlen_p, struct deflate_sequence **next_seq_p)
{
	struct deflate_sequence *seq = *next_seq_p;
	unsigned length_slot = deflate_length_slot[length];
	unsigned offset_slot = deflate_get_offset_slot(c, offset);

	c->freqs.litlen[257 + length_slot]++;
	c->freqs.offset[offset_slot]++;

	seq->litrunlen_and_length = ((u32)length << 23) | *litrunlen_p;
	seq->offset = offset;
	seq->length_slot = length_slot;
	seq->offset_symbol = offset_slot;

	*litrunlen_p = 0;
	*next_seq_p = seq + 1;
}

static forceinline void
deflate_finish_sequence(struct deflate_sequence *seq, u32 litrunlen)
{
	seq->litrunlen_and_length = litrunlen; 
}






static void
init_block_split_stats(struct block_split_stats *stats)
{
	int i;

	for (i = 0; i < NUM_OBSERVATION_TYPES; i++) {
		stats->new_observations[i] = 0;
		stats->observations[i] = 0;
	}
	stats->num_new_observations = 0;
	stats->num_observations = 0;
}


static forceinline void
observe_literal(struct block_split_stats *stats, u8 lit)
{
	stats->new_observations[((lit >> 5) & 0x6) | (lit & 1)]++;
	stats->num_new_observations++;
}


static forceinline void
observe_match(struct block_split_stats *stats, unsigned length)
{
	stats->new_observations[NUM_LITERAL_OBSERVATION_TYPES + (length >= 9)]++;
	stats->num_new_observations++;
}

static bool
do_end_block_check(struct block_split_stats *stats, u32 block_length)
{
	int i;

	if (stats->num_observations > 0) {

		
		u32 total_delta = 0;
		for (i = 0; i < NUM_OBSERVATION_TYPES; i++) {
			u32 expected = stats->observations[i] * stats->num_new_observations;
			u32 actual = stats->new_observations[i] * stats->num_observations;
			u32 delta = (actual > expected) ? actual - expected :
							  expected - actual;
			total_delta += delta;
		}

		
		if (total_delta + (block_length / 4096) * stats->num_observations >=
		    NUM_OBSERVATIONS_PER_BLOCK_CHECK * 200 / 512 * stats->num_observations)
			return true;
	}

	for (i = 0; i < NUM_OBSERVATION_TYPES; i++) {
		stats->num_observations += stats->new_observations[i];
		stats->observations[i] += stats->new_observations[i];
		stats->new_observations[i] = 0;
	}
	stats->num_new_observations = 0;
	return false;
}

static forceinline bool
should_end_block(struct block_split_stats *stats,
		 const u8 *in_block_begin, const u8 *in_next, const u8 *in_end)
{
	
	if (stats->num_new_observations < NUM_OBSERVATIONS_PER_BLOCK_CHECK ||
	    in_next - in_block_begin < MIN_BLOCK_LENGTH ||
	    in_end - in_next < MIN_BLOCK_LENGTH)
		return false;

	return do_end_block_check(stats, in_next - in_block_begin);
}




static size_t
deflate_compress_none(struct libdeflate_compressor * restrict c,
		      const u8 * restrict in, size_t in_nbytes,
		      u8 * restrict out, size_t out_nbytes_avail)
{
	struct deflate_output_bitstream os;

	deflate_init_output(&os, out, out_nbytes_avail);

	deflate_write_uncompressed_blocks(&os, in, in_nbytes, true);

	return deflate_flush_output(&os);
}


static size_t
deflate_compress_greedy(struct libdeflate_compressor * restrict c,
			const u8 * restrict in, size_t in_nbytes,
			u8 * restrict out, size_t out_nbytes_avail)
{
	const u8 *in_next = in;
	const u8 *in_end = in_next + in_nbytes;
	struct deflate_output_bitstream os;
	const u8 *in_cur_base = in_next;
	unsigned max_len = DEFLATE_MAX_MATCH_LEN;
	unsigned nice_len = MIN(c->nice_match_length, max_len);
	u32 next_hashes[2] = {0, 0};

	deflate_init_output(&os, out, out_nbytes_avail);
	hc_matchfinder_init(&c->p.g.hc_mf);

	do {
		

		const u8 * const in_block_begin = in_next;
		const u8 * const in_max_block_end =
			in_next + MIN(in_end - in_next, SOFT_MAX_BLOCK_LENGTH);
		u32 litrunlen = 0;
		struct deflate_sequence *next_seq = c->p.g.sequences;

		init_block_split_stats(&c->split_stats);
		deflate_reset_symbol_frequencies(c);

		do {
			u32 length;
			u32 offset;

			
			if (unlikely(max_len > in_end - in_next)) {
				max_len = in_end - in_next;
				nice_len = MIN(nice_len, max_len);
			}

			length = hc_matchfinder_longest_match(&c->p.g.hc_mf,
							      &in_cur_base,
							      in_next,
							      DEFLATE_MIN_MATCH_LEN - 1,
							      max_len,
							      nice_len,
							      c->max_search_depth,
							      next_hashes,
							      &offset);

			if (length >= DEFLATE_MIN_MATCH_LEN) {
				
				deflate_choose_match(c, length, offset,
						     &litrunlen, &next_seq);
				observe_match(&c->split_stats, length);
				in_next = hc_matchfinder_skip_positions(&c->p.g.hc_mf,
									&in_cur_base,
									in_next + 1,
									in_end,
									length - 1,
									next_hashes);
			} else {
				
				deflate_choose_literal(c, *in_next, &litrunlen);
				observe_literal(&c->split_stats, *in_next);
				in_next++;
			}

			
		} while (in_next < in_max_block_end &&
			 !should_end_block(&c->split_stats, in_block_begin, in_next, in_end));

		deflate_finish_sequence(next_seq, litrunlen);
		deflate_flush_block(c, &os, in_block_begin,
				    in_next - in_block_begin,
				    in_next == in_end, false);
	} while (in_next != in_end);

	return deflate_flush_output(&os);
}


static size_t
deflate_compress_lazy(struct libdeflate_compressor * restrict c,
		      const u8 * restrict in, size_t in_nbytes,
		      u8 * restrict out, size_t out_nbytes_avail)
{
	const u8 *in_next = in;
	const u8 *in_end = in_next + in_nbytes;
	struct deflate_output_bitstream os;
	const u8 *in_cur_base = in_next;
	unsigned max_len = DEFLATE_MAX_MATCH_LEN;
	unsigned nice_len = MIN(c->nice_match_length, max_len);
	u32 next_hashes[2] = {0, 0};

	deflate_init_output(&os, out, out_nbytes_avail);
	hc_matchfinder_init(&c->p.g.hc_mf);

	do {
		

		const u8 * const in_block_begin = in_next;
		const u8 * const in_max_block_end =
			in_next + MIN(in_end - in_next, SOFT_MAX_BLOCK_LENGTH);
		u32 litrunlen = 0;
		struct deflate_sequence *next_seq = c->p.g.sequences;

		init_block_split_stats(&c->split_stats);
		deflate_reset_symbol_frequencies(c);

		do {
			unsigned cur_len;
			unsigned cur_offset;
			unsigned next_len;
			unsigned next_offset;

			if (unlikely(in_end - in_next < DEFLATE_MAX_MATCH_LEN)) {
				max_len = in_end - in_next;
				nice_len = MIN(nice_len, max_len);
			}

			
			cur_len = hc_matchfinder_longest_match(&c->p.g.hc_mf,
							       &in_cur_base,
							       in_next,
							       DEFLATE_MIN_MATCH_LEN - 1,
							       max_len,
							       nice_len,
							       c->max_search_depth,
							       next_hashes,
							       &cur_offset);
			in_next += 1;

			if (cur_len < DEFLATE_MIN_MATCH_LEN) {
				
				deflate_choose_literal(c, *(in_next - 1), &litrunlen);
				observe_literal(&c->split_stats, *(in_next - 1));
				continue;
			}

		have_cur_match:
			observe_match(&c->split_stats, cur_len);

			

			
			if (cur_len >= nice_len) {
				deflate_choose_match(c, cur_len, cur_offset,
						     &litrunlen, &next_seq);
				in_next = hc_matchfinder_skip_positions(&c->p.g.hc_mf,
									&in_cur_base,
									in_next,
									in_end,
									cur_len - 1,
									next_hashes);
				continue;
			}

			
			if (unlikely(in_end - in_next < DEFLATE_MAX_MATCH_LEN)) {
				max_len = in_end - in_next;
				nice_len = MIN(nice_len, max_len);
			}
			next_len = hc_matchfinder_longest_match(&c->p.g.hc_mf,
								&in_cur_base,
								in_next,
								cur_len,
								max_len,
								nice_len,
								c->max_search_depth / 2,
								next_hashes,
								&next_offset);
			in_next += 1;

			if (next_len > cur_len) {
				
				deflate_choose_literal(c, *(in_next - 2), &litrunlen);
				cur_len = next_len;
				cur_offset = next_offset;
				goto have_cur_match;
			}

			
			deflate_choose_match(c, cur_len, cur_offset,
					     &litrunlen, &next_seq);
			in_next = hc_matchfinder_skip_positions(&c->p.g.hc_mf,
								&in_cur_base,
								in_next,
								in_end,
								cur_len - 2,
								next_hashes);

			
		} while (in_next < in_max_block_end &&
			 !should_end_block(&c->split_stats, in_block_begin, in_next, in_end));

		deflate_finish_sequence(next_seq, litrunlen);
		deflate_flush_block(c, &os, in_block_begin,
				    in_next - in_block_begin,
				    in_next == in_end, false);
	} while (in_next != in_end);

	return deflate_flush_output(&os);
}

#if SUPPORT_NEAR_OPTIMAL_PARSING


static void
deflate_tally_item_list(struct libdeflate_compressor *c, u32 block_length)
{
	struct deflate_optimum_node *cur_node = &c->p.n.optimum_nodes[0];
	struct deflate_optimum_node *end_node = &c->p.n.optimum_nodes[block_length];
	do {
		unsigned length = cur_node->item & OPTIMUM_LEN_MASK;
		unsigned offset = cur_node->item >> OPTIMUM_OFFSET_SHIFT;

		if (length == 1) {
			
			c->freqs.litlen[offset]++;
		} else {
			
			c->freqs.litlen[257 + deflate_length_slot[length]]++;
			c->freqs.offset[deflate_get_offset_slot(c, offset)]++;
		}
		cur_node += length;
	} while (cur_node != end_node);
}


static void
deflate_set_costs_from_codes(struct libdeflate_compressor *c,
			     const struct deflate_lens *lens)
{
	unsigned i;

	
	for (i = 0; i < DEFLATE_NUM_LITERALS; i++) {
		u32 bits = (lens->litlen[i] ? lens->litlen[i] : LITERAL_NOSTAT_BITS);
		c->p.n.costs.literal[i] = bits << COST_SHIFT;
	}

	
	for (i = DEFLATE_MIN_MATCH_LEN; i <= DEFLATE_MAX_MATCH_LEN; i++) {
		unsigned length_slot = deflate_length_slot[i];
		unsigned litlen_sym = 257 + length_slot;
		u32 bits = (lens->litlen[litlen_sym] ? lens->litlen[litlen_sym] : LENGTH_NOSTAT_BITS);
		bits += deflate_extra_length_bits[length_slot];
		c->p.n.costs.length[i] = bits << COST_SHIFT;
	}

	
	for (i = 0; i < ARRAY_LEN(deflate_offset_slot_base); i++) {
		u32 bits = (lens->offset[i] ? lens->offset[i] : OFFSET_NOSTAT_BITS);
		bits += deflate_extra_offset_bits[i];
		c->p.n.costs.offset_slot[i] = bits << COST_SHIFT;
	}
}

static forceinline u32
deflate_default_literal_cost(unsigned literal)
{
	STATIC_ASSERT(COST_SHIFT == 3);
	
	return 66;
}

static forceinline u32
deflate_default_length_slot_cost(unsigned length_slot)
{
	STATIC_ASSERT(COST_SHIFT == 3);
	
	return 60 + ((u32)deflate_extra_length_bits[length_slot] << COST_SHIFT);
}

static forceinline u32
deflate_default_offset_slot_cost(unsigned offset_slot)
{
	STATIC_ASSERT(COST_SHIFT == 3);
	
	return 39 + ((u32)deflate_extra_offset_bits[offset_slot] << COST_SHIFT);
}


static void
deflate_set_default_costs(struct libdeflate_compressor *c)
{
	unsigned i;

	
	for (i = 0; i < DEFLATE_NUM_LITERALS; i++)
		c->p.n.costs.literal[i] = deflate_default_literal_cost(i);

	
	for (i = DEFLATE_MIN_MATCH_LEN; i <= DEFLATE_MAX_MATCH_LEN; i++)
		c->p.n.costs.length[i] = deflate_default_length_slot_cost(
						deflate_length_slot[i]);

	
	for (i = 0; i < ARRAY_LEN(deflate_offset_slot_base); i++)
		c->p.n.costs.offset_slot[i] = deflate_default_offset_slot_cost(i);
}

static forceinline void
deflate_adjust_cost(u32 *cost_p, u32 default_cost)
{
	*cost_p += ((s32)default_cost - (s32)*cost_p) >> 1;
}


static void
deflate_adjust_costs(struct libdeflate_compressor *c)
{
	unsigned i;

	
	for (i = 0; i < DEFLATE_NUM_LITERALS; i++)
		deflate_adjust_cost(&c->p.n.costs.literal[i],
				    deflate_default_literal_cost(i));

	
	for (i = DEFLATE_MIN_MATCH_LEN; i <= DEFLATE_MAX_MATCH_LEN; i++)
		deflate_adjust_cost(&c->p.n.costs.length[i],
				    deflate_default_length_slot_cost(
						deflate_length_slot[i]));

	
	for (i = 0; i < ARRAY_LEN(deflate_offset_slot_base); i++)
		deflate_adjust_cost(&c->p.n.costs.offset_slot[i],
				    deflate_default_offset_slot_cost(i));
}


static void
deflate_find_min_cost_path(struct libdeflate_compressor *c,
			   const u32 block_length,
			   const struct lz_match *cache_ptr)
{
	struct deflate_optimum_node *end_node = &c->p.n.optimum_nodes[block_length];
	struct deflate_optimum_node *cur_node = end_node;

	cur_node->cost_to_end = 0;
	do {
		unsigned num_matches;
		unsigned literal;
		u32 best_cost_to_end;

		cur_node--;
		cache_ptr--;

		num_matches = cache_ptr->length;
		literal = cache_ptr->offset;

		
		best_cost_to_end = c->p.n.costs.literal[literal] +
				   (cur_node + 1)->cost_to_end;
		cur_node->item = ((u32)literal << OPTIMUM_OFFSET_SHIFT) | 1;

		
		if (num_matches) {
			const struct lz_match *match;
			unsigned len;
			unsigned offset;
			unsigned offset_slot;
			u32 offset_cost;
			u32 cost_to_end;

			
			match = cache_ptr - num_matches;
			len = DEFLATE_MIN_MATCH_LEN;
			do {
				offset = match->offset;
				offset_slot = deflate_get_offset_slot(c, offset);
				offset_cost = c->p.n.costs.offset_slot[offset_slot];
				do {
					cost_to_end = offset_cost +
						      c->p.n.costs.length[len] +
						      (cur_node + len)->cost_to_end;
					if (cost_to_end < best_cost_to_end) {
						best_cost_to_end = cost_to_end;
						cur_node->item = ((u32)offset << OPTIMUM_OFFSET_SHIFT) | len;
					}
				} while (++len <= match->length);
			} while (++match != cache_ptr);
			cache_ptr -= num_matches;
		}
		cur_node->cost_to_end = best_cost_to_end;
	} while (cur_node != &c->p.n.optimum_nodes[0]);
}


static void
deflate_optimize_block(struct libdeflate_compressor *c, u32 block_length,
		       const struct lz_match *cache_ptr, bool is_first_block)
{
	unsigned num_passes_remaining = c->p.n.num_optim_passes;
	u32 i;

	
	for (i = block_length; i <= MIN(block_length - 1 + DEFLATE_MAX_MATCH_LEN,
					ARRAY_LEN(c->p.n.optimum_nodes) - 1); i++)
		c->p.n.optimum_nodes[i].cost_to_end = 0x80000000;

	
	if (is_first_block)
		deflate_set_default_costs(c);
	else
		deflate_adjust_costs(c);

	for (;;) {
		
		deflate_find_min_cost_path(c, block_length, cache_ptr);

		
		deflate_reset_symbol_frequencies(c);
		deflate_tally_item_list(c, block_length);

		if (--num_passes_remaining == 0)
			break;

		
		deflate_make_huffman_codes(&c->freqs, &c->codes);
		deflate_set_costs_from_codes(c, &c->codes.lens);
	}
}


static size_t
deflate_compress_near_optimal(struct libdeflate_compressor * restrict c,
			      const u8 * restrict in, size_t in_nbytes,
			      u8 * restrict out, size_t out_nbytes_avail)
{
	const u8 *in_next = in;
	const u8 *in_end = in_next + in_nbytes;
	struct deflate_output_bitstream os;
	const u8 *in_cur_base = in_next;
	const u8 *in_next_slide = in_next + MIN(in_end - in_next, MATCHFINDER_WINDOW_SIZE);
	unsigned max_len = DEFLATE_MAX_MATCH_LEN;
	unsigned nice_len = MIN(c->nice_match_length, max_len);
	u32 next_hashes[2] = {0, 0};

	deflate_init_output(&os, out, out_nbytes_avail);
	bt_matchfinder_init(&c->p.n.bt_mf);

	do {
		

		struct lz_match *cache_ptr = c->p.n.match_cache;
		const u8 * const in_block_begin = in_next;
		const u8 * const in_max_block_end =
			in_next + MIN(in_end - in_next, SOFT_MAX_BLOCK_LENGTH);
		const u8 *next_observation = in_next;

		init_block_split_stats(&c->split_stats);

		
		do {
			struct lz_match *matches;
			unsigned best_len;

			
			if (in_next == in_next_slide) {
				bt_matchfinder_slide_window(&c->p.n.bt_mf);
				in_cur_base = in_next;
				in_next_slide = in_next + MIN(in_end - in_next,
							      MATCHFINDER_WINDOW_SIZE);
			}

			
			if (unlikely(max_len > in_end - in_next)) {
				max_len = in_end - in_next;
				nice_len = MIN(nice_len, max_len);
			}

			
			matches = cache_ptr;
			best_len = 0;
			if (likely(max_len >= BT_MATCHFINDER_REQUIRED_NBYTES)) {
				cache_ptr = bt_matchfinder_get_matches(&c->p.n.bt_mf,
								       in_cur_base,
								       in_next - in_cur_base,
								       max_len,
								       nice_len,
								       c->max_search_depth,
								       next_hashes,
								       &best_len,
								       matches);
			}

			if (in_next >= next_observation) {
				if (best_len >= 4) {
					observe_match(&c->split_stats, best_len);
					next_observation = in_next + best_len;
				} else {
					observe_literal(&c->split_stats, *in_next);
					next_observation = in_next + 1;
				}
			}

			cache_ptr->length = cache_ptr - matches;
			cache_ptr->offset = *in_next;
			in_next++;
			cache_ptr++;

			
			if (best_len >= DEFLATE_MIN_MATCH_LEN && best_len >= nice_len) {
				--best_len;
				do {
					if (in_next == in_next_slide) {
						bt_matchfinder_slide_window(&c->p.n.bt_mf);
						in_cur_base = in_next;
						in_next_slide = in_next + MIN(in_end - in_next,
									      MATCHFINDER_WINDOW_SIZE);
					}
					if (unlikely(max_len > in_end - in_next)) {
						max_len = in_end - in_next;
						nice_len = MIN(nice_len, max_len);
					}
					if (max_len >= BT_MATCHFINDER_REQUIRED_NBYTES) {
						bt_matchfinder_skip_position(&c->p.n.bt_mf,
									     in_cur_base,
									     in_next - in_cur_base,
									     nice_len,
									     c->max_search_depth,
									     next_hashes);
					}
					cache_ptr->length = 0;
					cache_ptr->offset = *in_next;
					in_next++;
					cache_ptr++;
				} while (--best_len);
			}
		} while (in_next < in_max_block_end &&
			 cache_ptr < &c->p.n.match_cache[CACHE_LENGTH] &&
			 !should_end_block(&c->split_stats, in_block_begin, in_next, in_end));

		
		deflate_optimize_block(c, in_next - in_block_begin, cache_ptr,
				       in_block_begin == in);
		deflate_flush_block(c, &os, in_block_begin, in_next - in_block_begin,
				    in_next == in_end, true);
	} while (in_next != in_end);

	return deflate_flush_output(&os);
}

#endif 


static void
deflate_init_offset_slot_fast(struct libdeflate_compressor *c)
{
	unsigned offset_slot;
	unsigned offset;
	unsigned offset_end;

	for (offset_slot = 0;
	     offset_slot < ARRAY_LEN(deflate_offset_slot_base);
	     offset_slot++)
	{
		offset = deflate_offset_slot_base[offset_slot];
	#if USE_FULL_OFFSET_SLOT_FAST
		offset_end = offset + (1 << deflate_extra_offset_bits[offset_slot]);
		do {
			c->offset_slot_fast[offset] = offset_slot;
		} while (++offset != offset_end);
	#else
		if (offset <= 256) {
			offset_end = offset + (1 << deflate_extra_offset_bits[offset_slot]);
			do {
				c->offset_slot_fast[offset - 1] = offset_slot;
			} while (++offset != offset_end);
		} else {
			offset_end = offset + (1 << deflate_extra_offset_bits[offset_slot]);
			do {
				c->offset_slot_fast[256 + ((offset - 1) >> 7)] = offset_slot;
			} while ((offset += (1 << 7)) != offset_end);
		}
	#endif
	}
}

LIBDEFLATEEXPORT struct libdeflate_compressor * LIBDEFLATEAPI
libdeflate_alloc_compressor(int compression_level)
{
	struct libdeflate_compressor *c;
	size_t size = offsetof(struct libdeflate_compressor, p);

	if (compression_level < 0 || compression_level > 12)
		return NULL;

#if SUPPORT_NEAR_OPTIMAL_PARSING
	if (compression_level >= 8)
		size += sizeof(c->p.n);
	else if (compression_level >= 1)
		size += sizeof(c->p.g);
#else
	if (compression_level >= 1)
		size += sizeof(c->p.g);
#endif

	c = libdeflate_aligned_malloc(MATCHFINDER_MEM_ALIGNMENT, size);
	if (!c)
		return NULL;

	c->compression_level = compression_level;

	
	c->min_size_to_compress = 56 - (compression_level * 4);

	switch (compression_level) {
	case 0:
		c->impl = deflate_compress_none;
		break;
	case 1:
		c->impl = deflate_compress_greedy;
		c->max_search_depth = 2;
		c->nice_match_length = 8;
		break;
	case 2:
		c->impl = deflate_compress_greedy;
		c->max_search_depth = 6;
		c->nice_match_length = 10;
		break;
	case 3:
		c->impl = deflate_compress_greedy;
		c->max_search_depth = 12;
		c->nice_match_length = 14;
		break;
	case 4:
		c->impl = deflate_compress_greedy;
		c->max_search_depth = 24;
		c->nice_match_length = 24;
		break;
	case 5:
		c->impl = deflate_compress_lazy;
		c->max_search_depth = 20;
		c->nice_match_length = 30;
		break;
	case 6:
		c->impl = deflate_compress_lazy;
		c->max_search_depth = 40;
		c->nice_match_length = 65;
		break;
	case 7:
		c->impl = deflate_compress_lazy;
		c->max_search_depth = 100;
		c->nice_match_length = 130;
		break;
#if SUPPORT_NEAR_OPTIMAL_PARSING
	case 8:
		c->impl = deflate_compress_near_optimal;
		c->max_search_depth = 12;
		c->nice_match_length = 20;
		c->p.n.num_optim_passes = 1;
		break;
	case 9:
		c->impl = deflate_compress_near_optimal;
		c->max_search_depth = 16;
		c->nice_match_length = 26;
		c->p.n.num_optim_passes = 2;
		break;
	case 10:
		c->impl = deflate_compress_near_optimal;
		c->max_search_depth = 30;
		c->nice_match_length = 50;
		c->p.n.num_optim_passes = 2;
		break;
	case 11:
		c->impl = deflate_compress_near_optimal;
		c->max_search_depth = 60;
		c->nice_match_length = 80;
		c->p.n.num_optim_passes = 3;
		break;
	default:
		c->impl = deflate_compress_near_optimal;
		c->max_search_depth = 100;
		c->nice_match_length = 133;
		c->p.n.num_optim_passes = 4;
		break;
#else
	case 8:
		c->impl = deflate_compress_lazy;
		c->max_search_depth = 150;
		c->nice_match_length = 200;
		break;
	default:
		c->impl = deflate_compress_lazy;
		c->max_search_depth = 200;
		c->nice_match_length = DEFLATE_MAX_MATCH_LEN;
		break;
#endif
	}

	deflate_init_offset_slot_fast(c);
	deflate_init_static_codes(c);

	return c;
}

LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_deflate_compress(struct libdeflate_compressor *c,
			    const void *in, size_t in_nbytes,
			    void *out, size_t out_nbytes_avail)
{
	if (unlikely(out_nbytes_avail < OUTPUT_END_PADDING))
		return 0;

	
	if (unlikely(in_nbytes < c->min_size_to_compress)) {
		struct deflate_output_bitstream os;
		deflate_init_output(&os, out, out_nbytes_avail);
		if (in_nbytes == 0)
			in = &os; 
		deflate_write_uncompressed_block(&os, in, in_nbytes, true);
		return deflate_flush_output(&os);
	}

	return (*c->impl)(c, in, in_nbytes, out, out_nbytes_avail);
}

LIBDEFLATEEXPORT void LIBDEFLATEAPI
libdeflate_free_compressor(struct libdeflate_compressor *c)
{
	libdeflate_aligned_free(c);
}

unsigned int
deflate_get_compression_level(struct libdeflate_compressor *c)
{
	return c->compression_level;
}

LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_deflate_compress_bound(struct libdeflate_compressor *c,
				  size_t in_nbytes)
{
	
	size_t max_num_blocks = MAX(DIV_ROUND_UP(in_nbytes, MIN_BLOCK_LENGTH), 1);
	return (5 * max_num_blocks) + in_nbytes + 1 + OUTPUT_END_PADDING;
}
/* /usr/home/ben/projects/gzip-libdeflate/../../software/libdeflate-1.7/lib/deflate_decompress.c */


#include <limits.h>

/* #include "deflate_constants.h" */


#ifndef LIB_DEFLATE_CONSTANTS_H
#define LIB_DEFLATE_CONSTANTS_H


#define DEFLATE_BLOCKTYPE_UNCOMPRESSED		0
#define DEFLATE_BLOCKTYPE_STATIC_HUFFMAN	1
#define DEFLATE_BLOCKTYPE_DYNAMIC_HUFFMAN	2


#define DEFLATE_MIN_MATCH_LEN			3
#define DEFLATE_MAX_MATCH_LEN			258


#define DEFLATE_MIN_MATCH_OFFSET		1
#define DEFLATE_MAX_MATCH_OFFSET		32768

#define DEFLATE_MAX_WINDOW_SIZE			32768


#define DEFLATE_NUM_PRECODE_SYMS		19
#define DEFLATE_NUM_LITLEN_SYMS			288
#define DEFLATE_NUM_OFFSET_SYMS			32


#define DEFLATE_MAX_NUM_SYMS			288


#define DEFLATE_NUM_LITERALS			256
#define DEFLATE_END_OF_BLOCK			256
#define DEFLATE_NUM_LEN_SYMS			31


#define DEFLATE_MAX_PRE_CODEWORD_LEN		7
#define DEFLATE_MAX_LITLEN_CODEWORD_LEN		15
#define DEFLATE_MAX_OFFSET_CODEWORD_LEN		15


#define DEFLATE_MAX_CODEWORD_LEN		15


#define DEFLATE_MAX_LENS_OVERRUN		137


#define DEFLATE_MAX_EXTRA_LENGTH_BITS		5
#define DEFLATE_MAX_EXTRA_OFFSET_BITS		14


#define DEFLATE_MAX_MATCH_BITS	\
	(DEFLATE_MAX_LITLEN_CODEWORD_LEN + DEFLATE_MAX_EXTRA_LENGTH_BITS + \
	DEFLATE_MAX_OFFSET_CODEWORD_LEN + DEFLATE_MAX_EXTRA_OFFSET_BITS)

#endif 

/* #include "unaligned.h" */


#ifndef LIB_UNALIGNED_H
#define LIB_UNALIGNED_H

/* #include "lib_common.h" */


#ifndef LIB_LIB_COMMON_H
#define LIB_LIB_COMMON_H

#ifdef LIBDEFLATE_H
#  error "lib_common.h must always be included before libdeflate.h"
   
#endif

#define BUILDING_LIBDEFLATE

/* #include "../common/common_defs.h" */


#ifndef COMMON_COMMON_DEFS_H
#define COMMON_COMMON_DEFS_H

#ifdef __GNUC__
/* #  include "compiler_gcc.h" */


#if !defined(__clang__) && !defined(__INTEL_COMPILER)
#  define GCC_PREREQ(major, minor)		\
	(__GNUC__ > (major) ||			\
	 (__GNUC__ == (major) && __GNUC_MINOR__ >= (minor)))
#else
#  define GCC_PREREQ(major, minor)	0
#endif


#ifdef __clang__
#  ifdef __apple_build_version__
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__apple_build_version__ >= (apple_version))
#  else
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__clang_major__ > (major) ||			\
	 (__clang_major__ == (major) && __clang_minor__ >= (minor)))
#  endif
#else
#  define CLANG_PREREQ(major, minor, apple_version)	0
#endif

#ifndef __has_attribute
#  define __has_attribute(attribute)	0
#endif
#ifndef __has_feature
#  define __has_feature(feature)	0
#endif
#ifndef __has_builtin
#  define __has_builtin(builtin)	0
#endif

#ifdef _WIN32
#  define LIBEXPORT __declspec(dllexport)
#else
#  define LIBEXPORT __attribute__((visibility("default")))
#endif

#define inline			inline
#define forceinline		inline __attribute__((always_inline))
#define restrict		__restrict__
#define likely(expr)		__builtin_expect(!!(expr), 1)
#define unlikely(expr)		__builtin_expect(!!(expr), 0)
#define prefetchr(addr)		__builtin_prefetch((addr), 0)
#define prefetchw(addr)		__builtin_prefetch((addr), 1)
#define _aligned_attribute(n)	__attribute__((aligned(n)))

#define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE	\
	(GCC_PREREQ(4, 4) || __has_attribute(target))

#if COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE

#  if defined(__i386__) || defined(__x86_64__)

#    define COMPILER_SUPPORTS_PCLMUL_TARGET	\
	(GCC_PREREQ(4, 4) || __has_builtin(__builtin_ia32_pclmulqdq128))

#    define COMPILER_SUPPORTS_AVX_TARGET	\
	(GCC_PREREQ(4, 6) || __has_builtin(__builtin_ia32_maxps256))

#    define COMPILER_SUPPORTS_BMI2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_pdep_di))

#    define COMPILER_SUPPORTS_AVX2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_psadbw256))

#    define COMPILER_SUPPORTS_AVX512BW_TARGET	\
	(GCC_PREREQ(5, 1) || __has_builtin(__builtin_ia32_psadbw512))

	
#    if GCC_PREREQ(4, 9) || CLANG_PREREQ(3, 8, 7030000)
#      define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS	1
#      define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_PCLMUL_TARGET
#      define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX2_TARGET
#      define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX512BW_TARGET
#    endif

#  elif defined(__arm__) || defined(__aarch64__)

    
#    if (GCC_PREREQ(6, 1) && defined(__ARM_FP)) || \
        (defined(__clang__) && defined(__ARM_NEON))
#      define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 1
       
#      if defined(__clang__) && defined(__arm__)
#        undef __ARM_FEATURE_CRYPTO
#      elif __has_builtin(__builtin_neon_vmull_p64) || !defined(__clang__)
#        define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 1
#      endif
#    endif

     
#    if GCC_PREREQ(10, 1) || \
        (GCC_PREREQ(9, 3) && !GCC_PREREQ(10, 0)) || \
        (GCC_PREREQ(8, 4) && !GCC_PREREQ(9, 0)) || \
        (defined(__clang__) && __has_builtin(__builtin_arm_crc32b))
#      define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 1
#    endif

#  endif 

#endif 


#if (GCC_PREREQ(4, 0) && !GCC_PREREQ(5, 1)) || \
    (defined(__clang__) && !CLANG_PREREQ(3, 9, 8020000))
typedef unsigned long long  __v2du __attribute__((__vector_size__(16)));
typedef unsigned int        __v4su __attribute__((__vector_size__(16)));
typedef unsigned short      __v8hu __attribute__((__vector_size__(16)));
typedef unsigned char      __v16qu __attribute__((__vector_size__(16)));
typedef unsigned long long  __v4du __attribute__((__vector_size__(32)));
typedef unsigned int        __v8su __attribute__((__vector_size__(32)));
typedef unsigned short     __v16hu __attribute__((__vector_size__(32)));
typedef unsigned char      __v32qu __attribute__((__vector_size__(32)));
#endif


#ifdef __BYTE_ORDER__
#  define CPU_IS_LITTLE_ENDIAN() (__BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__)
#endif

#if GCC_PREREQ(4, 8) || __has_builtin(__builtin_bswap16)
#  define bswap16	__builtin_bswap16
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap32)
#  define bswap32	__builtin_bswap32
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap64)
#  define bswap64	__builtin_bswap64
#endif

#if defined(__x86_64__) || defined(__i386__) || defined(__ARM_FEATURE_UNALIGNED) || defined(__powerpc64__)
#  define UNALIGNED_ACCESS_IS_FAST 1
#endif

#define bsr32(n)	(31 - __builtin_clz(n))
#define bsr64(n)	(63 - __builtin_clzll(n))
#define bsf32(n)	__builtin_ctz(n)
#define bsf64(n)	__builtin_ctzll(n)

#elif defined(_MSC_VER)
/* #  include "compiler_msc.h" */


#include <stdint.h>
#include <stdlib.h> 

#define LIBEXPORT	__declspec(dllexport)


typedef int bool;
#define true 1
#define false 0
#define __bool_true_false_are_defined 1


#ifdef _WIN64
typedef long long ssize_t;
#else
typedef int ssize_t;
#endif


#define CPU_IS_LITTLE_ENDIAN()		1
#define UNALIGNED_ACCESS_IS_FAST	1


#define restrict


#define inline		__inline
#define forceinline	__forceinline


#define bswap16	_byteswap_ushort
#define bswap32	_byteswap_ulong
#define bswap64	_byteswap_uint64



static forceinline unsigned
bsr32(uint32_t n)
{
	_BitScanReverse(&n, n);
	return n;
}
#define bsr32 bsr32

static forceinline unsigned
bsf32(uint32_t n)
{
	_BitScanForward(&n, n);
	return n;
}
#define bsf32 bsf32

#ifdef _M_X64 

static forceinline unsigned
bsr64(uint64_t n)
{
	_BitScanReverse64(&n, n);
	return n;
}
#define bsr64 bsr64

static forceinline unsigned
bsf64(uint64_t n)
{
	_BitScanForward64(&n, n);
	return n;
}
#define bsf64 bsf64

#endif 

#else
#  pragma message("Unrecognized compiler.  Please add a header file for your compiler.  Compilation will proceed, but performance may suffer!")
#endif





#include <stddef.h> 

#ifndef __bool_true_false_are_defined
#  include <stdbool.h> 
#endif


#include <stdint.h>
typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
typedef int8_t s8;
typedef int16_t s16;
typedef int32_t s32;
typedef int64_t s64;


typedef size_t machine_word_t;


#define WORDBYTES	((int)sizeof(machine_word_t))


#define WORDBITS	(8 * WORDBYTES)






#ifndef LIBEXPORT
#  define LIBEXPORT
#endif


#ifndef inline
#  define inline
#endif


#ifndef forceinline
#  define forceinline inline
#endif


#ifndef restrict
#  define restrict
#endif


#ifndef likely
#  define likely(expr)		(expr)
#endif


#ifndef unlikely
#  define unlikely(expr)	(expr)
#endif


#ifndef prefetchr
#  define prefetchr(addr)
#endif


#ifndef prefetchw
#  define prefetchw(addr)
#endif


#ifndef COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE
#  define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE 0
#endif


#ifndef COMPILER_SUPPORTS_BMI2_TARGET
#  define COMPILER_SUPPORTS_BMI2_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX_TARGET
#  define COMPILER_SUPPORTS_AVX_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET
#  define COMPILER_SUPPORTS_AVX512BW_TARGET 0
#endif


#ifndef COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 0
#endif


#ifndef _aligned_attribute
#endif





#define ARRAY_LEN(A)		(sizeof(A) / sizeof((A)[0]))
#define MIN(a, b)		((a) <= (b) ? (a) : (b))
#define MAX(a, b)		((a) >= (b) ? (a) : (b))
#define DIV_ROUND_UP(n, d)	(((n) + (d) - 1) / (d))
#define STATIC_ASSERT(expr)	((void)sizeof(char[1 - 2 * !(expr)]))
#define ALIGN(n, a)		(((n) + (a) - 1) & ~((a) - 1))






#ifndef CPU_IS_LITTLE_ENDIAN
static forceinline int CPU_IS_LITTLE_ENDIAN(void)
{
	union {
		unsigned int v;
		unsigned char b;
	} u;
	u.v = 1;
	return u.b;
}
#endif


#ifndef bswap16
static forceinline u16 bswap16(u16 n)
{
	return (n << 8) | (n >> 8);
}
#endif


#ifndef bswap32
static forceinline u32 bswap32(u32 n)
{
	return ((n & 0x000000FF) << 24) |
	       ((n & 0x0000FF00) << 8) |
	       ((n & 0x00FF0000) >> 8) |
	       ((n & 0xFF000000) >> 24);
}
#endif


#ifndef bswap64
static forceinline u64 bswap64(u64 n)
{
	return ((n & 0x00000000000000FF) << 56) |
	       ((n & 0x000000000000FF00) << 40) |
	       ((n & 0x0000000000FF0000) << 24) |
	       ((n & 0x00000000FF000000) << 8) |
	       ((n & 0x000000FF00000000) >> 8) |
	       ((n & 0x0000FF0000000000) >> 24) |
	       ((n & 0x00FF000000000000) >> 40) |
	       ((n & 0xFF00000000000000) >> 56);
}
#endif

#define le16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap16(n))
#define le32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap32(n))
#define le64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap64(n))
#define be16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap16(n) : (n))
#define be32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap32(n) : (n))
#define be64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap64(n) : (n))






#ifndef UNALIGNED_ACCESS_IS_FAST
#  define UNALIGNED_ACCESS_IS_FAST 0
#endif







#ifndef bsr32
static forceinline unsigned
bsr32(u32 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

#ifndef bsr64
static forceinline unsigned
bsr64(u64 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

static forceinline unsigned
bsrw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsr32(n);
	else
		return bsr64(n);
}



#ifndef bsf32
static forceinline unsigned
bsf32(u32 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

#ifndef bsf64
static forceinline unsigned
bsf64(u64 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

static forceinline unsigned
bsfw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsf32(n);
	else
		return bsf64(n);
}

#endif 



#define SYM_FIXUP(sym)			_libdeflate_##sym
#define deflate_get_compression_level	SYM_FIXUP(deflate_get_compression_level)
#define _cpu_features			SYM_FIXUP(_cpu_features)
#define setup_cpu_features		SYM_FIXUP(setup_cpu_features)

void *libdeflate_malloc(size_t size);
void libdeflate_free(void *ptr);

void *libdeflate_aligned_malloc(size_t alignment, size_t size);
void libdeflate_aligned_free(void *ptr);

#ifdef FREESTANDING

void *memset(void *s, int c, size_t n);
#define memset(s, c, n)		__builtin_memset((s), (c), (n))

void *memcpy(void *dest, const void *src, size_t n);
#define memcpy(dest, src, n)	__builtin_memcpy((dest), (src), (n))

void *memmove(void *dest, const void *src, size_t n);
#define memmove(dest, src, n)	__builtin_memmove((dest), (src), (n))

int memcmp(const void *s1, const void *s2, size_t n);
#define memcmp(s1, s2, n)	__builtin_memcmp((s1), (s2), (n))
#else
#include <string.h>
#endif

#endif 






#define DEFINE_UNALIGNED_TYPE(type)				\
static forceinline type						\
load_##type##_unaligned(const void *p)				\
{								\
	type v;							\
	memcpy(&v, p, sizeof(v));				\
	return v;						\
}								\
								\
static forceinline void						\
store_##type##_unaligned(type v, void *p)			\
{								\
	memcpy(p, &v, sizeof(v));				\
}

DEFINE_UNALIGNED_TYPE(u16)
DEFINE_UNALIGNED_TYPE(u32)
DEFINE_UNALIGNED_TYPE(u64)
DEFINE_UNALIGNED_TYPE(machine_word_t)

#define load_word_unaligned	load_machine_word_t_unaligned
#define store_word_unaligned	store_machine_word_t_unaligned



static forceinline u16
get_unaligned_le16(const u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST)
		return le16_bswap(load_u16_unaligned(p));
	else
		return ((u16)p[1] << 8) | p[0];
}

static forceinline u16
get_unaligned_be16(const u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST)
		return be16_bswap(load_u16_unaligned(p));
	else
		return ((u16)p[0] << 8) | p[1];
}

static forceinline u32
get_unaligned_le32(const u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST)
		return le32_bswap(load_u32_unaligned(p));
	else
		return ((u32)p[3] << 24) | ((u32)p[2] << 16) |
			((u32)p[1] << 8) | p[0];
}

static forceinline u32
get_unaligned_be32(const u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST)
		return be32_bswap(load_u32_unaligned(p));
	else
		return ((u32)p[0] << 24) | ((u32)p[1] << 16) |
			((u32)p[2] << 8) | p[3];
}

static forceinline u64
get_unaligned_le64(const u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST)
		return le64_bswap(load_u64_unaligned(p));
	else
		return ((u64)p[7] << 56) | ((u64)p[6] << 48) |
			((u64)p[5] << 40) | ((u64)p[4] << 32) |
			((u64)p[3] << 24) | ((u64)p[2] << 16) |
			((u64)p[1] << 8) | p[0];
}

static forceinline machine_word_t
get_unaligned_leword(const u8 *p)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return get_unaligned_le32(p);
	else
		return get_unaligned_le64(p);
}



static forceinline void
put_unaligned_le16(u16 v, u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST) {
		store_u16_unaligned(le16_bswap(v), p);
	} else {
		p[0] = (u8)(v >> 0);
		p[1] = (u8)(v >> 8);
	}
}

static forceinline void
put_unaligned_be16(u16 v, u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST) {
		store_u16_unaligned(be16_bswap(v), p);
	} else {
		p[0] = (u8)(v >> 8);
		p[1] = (u8)(v >> 0);
	}
}

static forceinline void
put_unaligned_le32(u32 v, u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST) {
		store_u32_unaligned(le32_bswap(v), p);
	} else {
		p[0] = (u8)(v >> 0);
		p[1] = (u8)(v >> 8);
		p[2] = (u8)(v >> 16);
		p[3] = (u8)(v >> 24);
	}
}

static forceinline void
put_unaligned_be32(u32 v, u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST) {
		store_u32_unaligned(be32_bswap(v), p);
	} else {
		p[0] = (u8)(v >> 24);
		p[1] = (u8)(v >> 16);
		p[2] = (u8)(v >> 8);
		p[3] = (u8)(v >> 0);
	}
}

static forceinline void
put_unaligned_le64(u64 v, u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST) {
		store_u64_unaligned(le64_bswap(v), p);
	} else {
		p[0] = (u8)(v >> 0);
		p[1] = (u8)(v >> 8);
		p[2] = (u8)(v >> 16);
		p[3] = (u8)(v >> 24);
		p[4] = (u8)(v >> 32);
		p[5] = (u8)(v >> 40);
		p[6] = (u8)(v >> 48);
		p[7] = (u8)(v >> 56);
	}
}

static forceinline void
put_unaligned_leword(machine_word_t v, u8 *p)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		put_unaligned_le32(v, p);
	else
		put_unaligned_le64(v, p);
}




static forceinline u32
loaded_u32_to_u24(u32 v)
{
	if (CPU_IS_LITTLE_ENDIAN())
		return v & 0xFFFFFF;
	else
		return v >> 8;
}


static forceinline u32
load_u24_unaligned(const u8 *p)
{
#if UNALIGNED_ACCESS_IS_FAST
#  define LOAD_U24_REQUIRED_NBYTES 4
	return loaded_u32_to_u24(load_u32_unaligned(p));
#else
#  define LOAD_U24_REQUIRED_NBYTES 3
	if (CPU_IS_LITTLE_ENDIAN())
		return ((u32)p[0] << 0) | ((u32)p[1] << 8) | ((u32)p[2] << 16);
	else
		return ((u32)p[2] << 0) | ((u32)p[1] << 8) | ((u32)p[0] << 16);
#endif
}

#endif 


/* #include "libdeflate.h" */


#ifndef LIBDEFLATE_H
#define LIBDEFLATE_H

#ifdef __cplusplus
extern "C" {
#endif

#define LIBDEFLATE_VERSION_MAJOR	1
#define LIBDEFLATE_VERSION_MINOR	7
#define LIBDEFLATE_VERSION_STRING	"1.7"

#include <stddef.h>
#include <stdint.h>


#ifdef LIBDEFLATE_DLL
#  ifdef BUILDING_LIBDEFLATE
#    define LIBDEFLATEEXPORT	LIBEXPORT
#  elif defined(_WIN32) || defined(__CYGWIN__)
#    define LIBDEFLATEEXPORT	__declspec(dllimport)
#  endif
#endif
#ifndef LIBDEFLATEEXPORT
#  define LIBDEFLATEEXPORT
#endif

#if defined(_WIN32) && !defined(_WIN64)
#  define LIBDEFLATEAPI_ABI	__stdcall
#else
#  define LIBDEFLATEAPI_ABI
#endif

#if defined(BUILDING_LIBDEFLATE) && defined(__GNUC__) && \
	defined(_WIN32) && !defined(_WIN64)
    
#  define LIBDEFLATEAPI_STACKALIGN	__attribute__((force_align_arg_pointer))
#else
#  define LIBDEFLATEAPI_STACKALIGN
#endif

#define LIBDEFLATEAPI	LIBDEFLATEAPI_ABI LIBDEFLATEAPI_STACKALIGN





struct libdeflate_compressor;


LIBDEFLATEEXPORT struct libdeflate_compressor * LIBDEFLATEAPI
libdeflate_alloc_compressor(int compression_level);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_deflate_compress(struct libdeflate_compressor *compressor,
			    const void *in, size_t in_nbytes,
			    void *out, size_t out_nbytes_avail);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_deflate_compress_bound(struct libdeflate_compressor *compressor,
				  size_t in_nbytes);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_zlib_compress(struct libdeflate_compressor *compressor,
			 const void *in, size_t in_nbytes,
			 void *out, size_t out_nbytes_avail);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_zlib_compress_bound(struct libdeflate_compressor *compressor,
			       size_t in_nbytes);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_gzip_compress(struct libdeflate_compressor *compressor,
			 const void *in, size_t in_nbytes,
			 void *out, size_t out_nbytes_avail);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_gzip_compress_bound(struct libdeflate_compressor *compressor,
			       size_t in_nbytes);


LIBDEFLATEEXPORT void LIBDEFLATEAPI
libdeflate_free_compressor(struct libdeflate_compressor *compressor);





struct libdeflate_decompressor;


LIBDEFLATEEXPORT struct libdeflate_decompressor * LIBDEFLATEAPI
libdeflate_alloc_decompressor(void);


enum libdeflate_result {
	
	LIBDEFLATE_SUCCESS = 0,

	
	LIBDEFLATE_BAD_DATA = 1,

	
	LIBDEFLATE_SHORT_OUTPUT = 2,

	
	LIBDEFLATE_INSUFFICIENT_SPACE = 3,
};


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_deflate_decompress(struct libdeflate_decompressor *decompressor,
			      const void *in, size_t in_nbytes,
			      void *out, size_t out_nbytes_avail,
			      size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_deflate_decompress_ex(struct libdeflate_decompressor *decompressor,
				 const void *in, size_t in_nbytes,
				 void *out, size_t out_nbytes_avail,
				 size_t *actual_in_nbytes_ret,
				 size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_zlib_decompress(struct libdeflate_decompressor *decompressor,
			   const void *in, size_t in_nbytes,
			   void *out, size_t out_nbytes_avail,
			   size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_zlib_decompress_ex(struct libdeflate_decompressor *decompressor,
			      const void *in, size_t in_nbytes,
			      void *out, size_t out_nbytes_avail,
			      size_t *actual_in_nbytes_ret,
			      size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_gzip_decompress(struct libdeflate_decompressor *decompressor,
			   const void *in, size_t in_nbytes,
			   void *out, size_t out_nbytes_avail,
			   size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_gzip_decompress_ex(struct libdeflate_decompressor *decompressor,
			      const void *in, size_t in_nbytes,
			      void *out, size_t out_nbytes_avail,
			      size_t *actual_in_nbytes_ret,
			      size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT void LIBDEFLATEAPI
libdeflate_free_decompressor(struct libdeflate_decompressor *decompressor);






LIBDEFLATEEXPORT uint32_t LIBDEFLATEAPI
libdeflate_adler32(uint32_t adler, const void *buffer, size_t len);



LIBDEFLATEEXPORT uint32_t LIBDEFLATEAPI
libdeflate_crc32(uint32_t crc, const void *buffer, size_t len);






LIBDEFLATEEXPORT void LIBDEFLATEAPI
libdeflate_set_memory_allocator(void *(*malloc_func)(size_t),
				void (*free_func)(void *));

#ifdef __cplusplus
}
#endif

#endif 



#if 0
#  pragma message("UNSAFE DECOMPRESSION IS ENABLED. THIS MUST ONLY BE USED IF THE DECOMPRESSOR INPUT WILL ALWAYS BE TRUSTED!")
#  define SAFETY_CHECK(expr)	(void)(expr)
#else
#  define SAFETY_CHECK(expr)	if (unlikely(!(expr))) return LIBDEFLATE_BAD_DATA
#endif


#define PRECODE_TABLEBITS	7
#define LITLEN_TABLEBITS	10
#define OFFSET_TABLEBITS	8


#define PRECODE_ENOUGH		128	
#define LITLEN_ENOUGH		1334	
#define OFFSET_ENOUGH		402	


typedef u8 libdeflate_len_t;


struct libdeflate_decompressor {

	

	union {
		libdeflate_len_t precode_lens[DEFLATE_NUM_PRECODE_SYMS];

		struct {
			libdeflate_len_t lens[DEFLATE_NUM_LITLEN_SYMS +
				   DEFLATE_NUM_OFFSET_SYMS +
				   DEFLATE_MAX_LENS_OVERRUN];

			u32 precode_decode_table[PRECODE_ENOUGH];
		} l;

		u32 litlen_decode_table[LITLEN_ENOUGH];
	} u;

	u32 offset_decode_table[OFFSET_ENOUGH];

	
	u16 sorted_syms[DEFLATE_MAX_NUM_SYMS];

	bool static_codes_loaded;
};






/* typedef machine_word_t bitbuf_t; */


#define DECOMPRESS_BITBUF_NBITS	(8 * sizeof(bitbuf_t) - 1)


#define MAX_ENSURE	(DECOMPRESS_BITBUF_NBITS - 7)


#define CAN_ENSURE(n)	((n) <= MAX_ENSURE)


#define FILL_BITS_BYTEWISE()					\
do {								\
	if (likely(in_next != in_end))				\
		bitbuf |= (bitbuf_t)*in_next++ << bitsleft;	\
	else							\
		overrun_count++;				\
	bitsleft += 8;						\
} while (bitsleft <= DECOMPRESS_BITBUF_NBITS - 8)


#define FILL_BITS_WORDWISE()					\
do {								\
		\
	STATIC_ASSERT((DECOMPRESS_BITBUF_NBITS & (DECOMPRESS_BITBUF_NBITS + 1)) == 0);\
								\
	bitbuf |= get_unaligned_leword(in_next) << bitsleft;	\
	in_next += (bitsleft ^ DECOMPRESS_BITBUF_NBITS) >> 3;		\
	bitsleft |= DECOMPRESS_BITBUF_NBITS & ~7;				\
} while (0)


#define HAVE_BITS(n) (bitsleft >= (n))


#define ENSURE_BITS(n)						\
if (!HAVE_BITS(n)) {						\
	if (CPU_IS_LITTLE_ENDIAN() &&				\
	    UNALIGNED_ACCESS_IS_FAST &&				\
	    likely(in_end - in_next >= sizeof(bitbuf_t)))	\
		FILL_BITS_WORDWISE();				\
	else							\
		FILL_BITS_BYTEWISE();				\
}


#define BITS(n) ((u32)bitbuf & (((u32)1 << (n)) - 1))


#define REMOVE_BITS(n) (bitbuf >>= (n), bitsleft -= (n))


#define POP_BITS(n) (tmp32 = BITS(n), REMOVE_BITS(n), tmp32)


#define ALIGN_INPUT()							\
do {									\
	SAFETY_CHECK(overrun_count <= (bitsleft >> 3));			\
	in_next -= (bitsleft >> 3) - overrun_count;			\
	overrun_count = 0;						\
	bitbuf = 0;							\
	bitsleft = 0;							\
} while(0)


#define READ_U16() (tmp16 = get_unaligned_le16(in_next), in_next += 2, tmp16)






#define HUFFDEC_SUBTABLE_POINTER	0x80000000


#define HUFFDEC_LITERAL			0x40000000


#define HUFFDEC_LENGTH_MASK		0xFF


#define HUFFDEC_RESULT_SHIFT		8


#define HUFFDEC_RESULT_ENTRY(result)	((u32)(result) << HUFFDEC_RESULT_SHIFT)


static const u32 precode_decode_results[DEFLATE_NUM_PRECODE_SYMS] = {
#define ENTRY(presym)	HUFFDEC_RESULT_ENTRY(presym)
	ENTRY(0)   , ENTRY(1)   , ENTRY(2)   , ENTRY(3)   ,
	ENTRY(4)   , ENTRY(5)   , ENTRY(6)   , ENTRY(7)   ,
	ENTRY(8)   , ENTRY(9)   , ENTRY(10)  , ENTRY(11)  ,
	ENTRY(12)  , ENTRY(13)  , ENTRY(14)  , ENTRY(15)  ,
	ENTRY(16)  , ENTRY(17)  , ENTRY(18)  ,
#undef ENTRY
};


static const u32 litlen_decode_results[DEFLATE_NUM_LITLEN_SYMS] = {

	
#define ENTRY(literal)	(HUFFDEC_LITERAL | HUFFDEC_RESULT_ENTRY(literal))
	ENTRY(0)   , ENTRY(1)   , ENTRY(2)   , ENTRY(3)   ,
	ENTRY(4)   , ENTRY(5)   , ENTRY(6)   , ENTRY(7)   ,
	ENTRY(8)   , ENTRY(9)   , ENTRY(10)  , ENTRY(11)  ,
	ENTRY(12)  , ENTRY(13)  , ENTRY(14)  , ENTRY(15)  ,
	ENTRY(16)  , ENTRY(17)  , ENTRY(18)  , ENTRY(19)  ,
	ENTRY(20)  , ENTRY(21)  , ENTRY(22)  , ENTRY(23)  ,
	ENTRY(24)  , ENTRY(25)  , ENTRY(26)  , ENTRY(27)  ,
	ENTRY(28)  , ENTRY(29)  , ENTRY(30)  , ENTRY(31)  ,
	ENTRY(32)  , ENTRY(33)  , ENTRY(34)  , ENTRY(35)  ,
	ENTRY(36)  , ENTRY(37)  , ENTRY(38)  , ENTRY(39)  ,
	ENTRY(40)  , ENTRY(41)  , ENTRY(42)  , ENTRY(43)  ,
	ENTRY(44)  , ENTRY(45)  , ENTRY(46)  , ENTRY(47)  ,
	ENTRY(48)  , ENTRY(49)  , ENTRY(50)  , ENTRY(51)  ,
	ENTRY(52)  , ENTRY(53)  , ENTRY(54)  , ENTRY(55)  ,
	ENTRY(56)  , ENTRY(57)  , ENTRY(58)  , ENTRY(59)  ,
	ENTRY(60)  , ENTRY(61)  , ENTRY(62)  , ENTRY(63)  ,
	ENTRY(64)  , ENTRY(65)  , ENTRY(66)  , ENTRY(67)  ,
	ENTRY(68)  , ENTRY(69)  , ENTRY(70)  , ENTRY(71)  ,
	ENTRY(72)  , ENTRY(73)  , ENTRY(74)  , ENTRY(75)  ,
	ENTRY(76)  , ENTRY(77)  , ENTRY(78)  , ENTRY(79)  ,
	ENTRY(80)  , ENTRY(81)  , ENTRY(82)  , ENTRY(83)  ,
	ENTRY(84)  , ENTRY(85)  , ENTRY(86)  , ENTRY(87)  ,
	ENTRY(88)  , ENTRY(89)  , ENTRY(90)  , ENTRY(91)  ,
	ENTRY(92)  , ENTRY(93)  , ENTRY(94)  , ENTRY(95)  ,
	ENTRY(96)  , ENTRY(97)  , ENTRY(98)  , ENTRY(99)  ,
	ENTRY(100) , ENTRY(101) , ENTRY(102) , ENTRY(103) ,
	ENTRY(104) , ENTRY(105) , ENTRY(106) , ENTRY(107) ,
	ENTRY(108) , ENTRY(109) , ENTRY(110) , ENTRY(111) ,
	ENTRY(112) , ENTRY(113) , ENTRY(114) , ENTRY(115) ,
	ENTRY(116) , ENTRY(117) , ENTRY(118) , ENTRY(119) ,
	ENTRY(120) , ENTRY(121) , ENTRY(122) , ENTRY(123) ,
	ENTRY(124) , ENTRY(125) , ENTRY(126) , ENTRY(127) ,
	ENTRY(128) , ENTRY(129) , ENTRY(130) , ENTRY(131) ,
	ENTRY(132) , ENTRY(133) , ENTRY(134) , ENTRY(135) ,
	ENTRY(136) , ENTRY(137) , ENTRY(138) , ENTRY(139) ,
	ENTRY(140) , ENTRY(141) , ENTRY(142) , ENTRY(143) ,
	ENTRY(144) , ENTRY(145) , ENTRY(146) , ENTRY(147) ,
	ENTRY(148) , ENTRY(149) , ENTRY(150) , ENTRY(151) ,
	ENTRY(152) , ENTRY(153) , ENTRY(154) , ENTRY(155) ,
	ENTRY(156) , ENTRY(157) , ENTRY(158) , ENTRY(159) ,
	ENTRY(160) , ENTRY(161) , ENTRY(162) , ENTRY(163) ,
	ENTRY(164) , ENTRY(165) , ENTRY(166) , ENTRY(167) ,
	ENTRY(168) , ENTRY(169) , ENTRY(170) , ENTRY(171) ,
	ENTRY(172) , ENTRY(173) , ENTRY(174) , ENTRY(175) ,
	ENTRY(176) , ENTRY(177) , ENTRY(178) , ENTRY(179) ,
	ENTRY(180) , ENTRY(181) , ENTRY(182) , ENTRY(183) ,
	ENTRY(184) , ENTRY(185) , ENTRY(186) , ENTRY(187) ,
	ENTRY(188) , ENTRY(189) , ENTRY(190) , ENTRY(191) ,
	ENTRY(192) , ENTRY(193) , ENTRY(194) , ENTRY(195) ,
	ENTRY(196) , ENTRY(197) , ENTRY(198) , ENTRY(199) ,
	ENTRY(200) , ENTRY(201) , ENTRY(202) , ENTRY(203) ,
	ENTRY(204) , ENTRY(205) , ENTRY(206) , ENTRY(207) ,
	ENTRY(208) , ENTRY(209) , ENTRY(210) , ENTRY(211) ,
	ENTRY(212) , ENTRY(213) , ENTRY(214) , ENTRY(215) ,
	ENTRY(216) , ENTRY(217) , ENTRY(218) , ENTRY(219) ,
	ENTRY(220) , ENTRY(221) , ENTRY(222) , ENTRY(223) ,
	ENTRY(224) , ENTRY(225) , ENTRY(226) , ENTRY(227) ,
	ENTRY(228) , ENTRY(229) , ENTRY(230) , ENTRY(231) ,
	ENTRY(232) , ENTRY(233) , ENTRY(234) , ENTRY(235) ,
	ENTRY(236) , ENTRY(237) , ENTRY(238) , ENTRY(239) ,
	ENTRY(240) , ENTRY(241) , ENTRY(242) , ENTRY(243) ,
	ENTRY(244) , ENTRY(245) , ENTRY(246) , ENTRY(247) ,
	ENTRY(248) , ENTRY(249) , ENTRY(250) , ENTRY(251) ,
	ENTRY(252) , ENTRY(253) , ENTRY(254) , ENTRY(255) ,
#undef ENTRY

#define HUFFDEC_EXTRA_LENGTH_BITS_MASK	0xFF
#define HUFFDEC_LENGTH_BASE_SHIFT	8
#define HUFFDEC_END_OF_BLOCK_LENGTH	0

#define ENTRY(length_base, num_extra_bits)	HUFFDEC_RESULT_ENTRY(	\
	((u32)(length_base) << HUFFDEC_LENGTH_BASE_SHIFT) | (num_extra_bits))

	
	ENTRY(HUFFDEC_END_OF_BLOCK_LENGTH, 0),

	
	ENTRY(3  , 0) , ENTRY(4  , 0) , ENTRY(5  , 0) , ENTRY(6  , 0),
	ENTRY(7  , 0) , ENTRY(8  , 0) , ENTRY(9  , 0) , ENTRY(10 , 0),
	ENTRY(11 , 1) , ENTRY(13 , 1) , ENTRY(15 , 1) , ENTRY(17 , 1),
	ENTRY(19 , 2) , ENTRY(23 , 2) , ENTRY(27 , 2) , ENTRY(31 , 2),
	ENTRY(35 , 3) , ENTRY(43 , 3) , ENTRY(51 , 3) , ENTRY(59 , 3),
	ENTRY(67 , 4) , ENTRY(83 , 4) , ENTRY(99 , 4) , ENTRY(115, 4),
	ENTRY(131, 5) , ENTRY(163, 5) , ENTRY(195, 5) , ENTRY(227, 5),
	ENTRY(258, 0) , ENTRY(258, 0) , ENTRY(258, 0) ,
#undef ENTRY
};


static const u32 offset_decode_results[DEFLATE_NUM_OFFSET_SYMS] = {

#define HUFFDEC_EXTRA_OFFSET_BITS_SHIFT 16
#define HUFFDEC_OFFSET_BASE_MASK (((u32)1 << HUFFDEC_EXTRA_OFFSET_BITS_SHIFT) - 1)

#define ENTRY(offset_base, num_extra_bits)	HUFFDEC_RESULT_ENTRY(	\
		((u32)(num_extra_bits) << HUFFDEC_EXTRA_OFFSET_BITS_SHIFT) | \
		(offset_base))
	ENTRY(1     , 0)  , ENTRY(2     , 0)  , ENTRY(3     , 0)  , ENTRY(4     , 0)  ,
	ENTRY(5     , 1)  , ENTRY(7     , 1)  , ENTRY(9     , 2)  , ENTRY(13    , 2) ,
	ENTRY(17    , 3)  , ENTRY(25    , 3)  , ENTRY(33    , 4)  , ENTRY(49    , 4)  ,
	ENTRY(65    , 5)  , ENTRY(97    , 5)  , ENTRY(129   , 6)  , ENTRY(193   , 6)  ,
	ENTRY(257   , 7)  , ENTRY(385   , 7)  , ENTRY(513   , 8)  , ENTRY(769   , 8)  ,
	ENTRY(1025  , 9)  , ENTRY(1537  , 9)  , ENTRY(2049  , 10) , ENTRY(3073  , 10) ,
	ENTRY(4097  , 11) , ENTRY(6145  , 11) , ENTRY(8193  , 12) , ENTRY(12289 , 12) ,
	ENTRY(16385 , 13) , ENTRY(24577 , 13) , ENTRY(32769 , 14) , ENTRY(49153 , 14) ,
#undef ENTRY
};


static bool
build_decode_table(u32 decode_table[],
		   const libdeflate_len_t lens[],
		   const unsigned num_syms,
		   const u32 decode_results[],
		   const unsigned table_bits,
		   const unsigned max_codeword_len,
		   u16 *sorted_syms)
{
	unsigned len_counts[DEFLATE_MAX_CODEWORD_LEN + 1];
	unsigned offsets[DEFLATE_MAX_CODEWORD_LEN + 1];
	unsigned sym;		
	unsigned codeword;	
	unsigned len;		
	unsigned count;		
	u32 codespace_used;	
	unsigned cur_table_end; 
	unsigned subtable_prefix; 
	unsigned subtable_start;  
	unsigned subtable_bits;   

	
	for (len = 0; len <= max_codeword_len; len++)
		len_counts[len] = 0;
	for (sym = 0; sym < num_syms; sym++)
		len_counts[lens[sym]]++;

	

	
	STATIC_ASSERT(sizeof(codespace_used) == 4);
	STATIC_ASSERT(UINT32_MAX / (1U << (DEFLATE_MAX_CODEWORD_LEN - 1)) >=
		      DEFLATE_MAX_NUM_SYMS);

	offsets[0] = 0;
	offsets[1] = len_counts[0];
	codespace_used = 0;
	for (len = 1; len < max_codeword_len; len++) {
		offsets[len + 1] = offsets[len] + len_counts[len];
		codespace_used = (codespace_used << 1) + len_counts[len];
	}
	codespace_used = (codespace_used << 1) + len_counts[len];

	for (sym = 0; sym < num_syms; sym++)
		sorted_syms[offsets[lens[sym]]++] = sym;

	sorted_syms += offsets[0]; 

	

	

	
	if (unlikely(codespace_used > (1U << max_codeword_len)))
		return false;

	
	if (unlikely(codespace_used < (1U << max_codeword_len))) {
		u32 entry;
		unsigned i;

		if (codespace_used == 0) {
			

			
			entry = decode_results[0] | 1;
		} else {
			
			if (codespace_used != (1U << (max_codeword_len - 1)) ||
			    len_counts[1] != 1)
				return false;
			entry = decode_results[*sorted_syms] | 1;
		}
		
		for (i = 0; i < (1U << table_bits); i++)
			decode_table[i] = entry;
		return true;
	}

	
	codeword = 0;
	len = 1;
	while ((count = len_counts[len]) == 0)
		len++;
	cur_table_end = 1U << len;
	while (len <= table_bits) {
		
		do {
			unsigned bit;

			
			decode_table[codeword] =
				decode_results[*sorted_syms++] | len;

			if (codeword == cur_table_end - 1) {
				
				for (; len < table_bits; len++) {
					memcpy(&decode_table[cur_table_end],
					       decode_table,
					       cur_table_end *
						sizeof(decode_table[0]));
					cur_table_end <<= 1;
				}
				return true;
			}
			
			bit = 1U << bsr32(codeword ^ (cur_table_end - 1));
			codeword &= bit - 1;
			codeword |= bit;
		} while (--count);

		
		do {
			if (++len <= table_bits) {
				memcpy(&decode_table[cur_table_end],
				       decode_table,
				       cur_table_end * sizeof(decode_table[0]));
				cur_table_end <<= 1;
			}
		} while ((count = len_counts[len]) == 0);
	}

	
	cur_table_end = 1U << table_bits;
	subtable_prefix = -1;
	subtable_start = 0;
	for (;;) {
		u32 entry;
		unsigned i;
		unsigned stride;
		unsigned bit;

		
		if ((codeword & ((1U << table_bits) - 1)) != subtable_prefix) {
			subtable_prefix = (codeword & ((1U << table_bits) - 1));
			subtable_start = cur_table_end;
			
			subtable_bits = len - table_bits;
			codespace_used = count;
			while (codespace_used < (1U << subtable_bits)) {
				subtable_bits++;
				codespace_used = (codespace_used << 1) +
					len_counts[table_bits + subtable_bits];
			}
			cur_table_end = subtable_start + (1U << subtable_bits);

			
			decode_table[subtable_prefix] =
				HUFFDEC_SUBTABLE_POINTER |
				HUFFDEC_RESULT_ENTRY(subtable_start) |
				subtable_bits;
		}

		
		entry = decode_results[*sorted_syms++] | (len - table_bits);
		i = subtable_start + (codeword >> table_bits);
		stride = 1U << (len - table_bits);
		do {
			decode_table[i] = entry;
			i += stride;
		} while (i < cur_table_end);

		
		if (codeword == (1U << len) - 1) 
			return true;
		bit = 1U << bsr32(codeword ^ ((1U << len) - 1));
		codeword &= bit - 1;
		codeword |= bit;
		count--;
		while (count == 0)
			count = len_counts[++len];
	}
}


static bool
build_precode_decode_table(struct libdeflate_decompressor *d)
{
	
	STATIC_ASSERT(PRECODE_TABLEBITS == 7 && PRECODE_ENOUGH == 128);

	return build_decode_table(d->u.l.precode_decode_table,
				  d->u.precode_lens,
				  DEFLATE_NUM_PRECODE_SYMS,
				  precode_decode_results,
				  PRECODE_TABLEBITS,
				  DEFLATE_MAX_PRE_CODEWORD_LEN,
				  d->sorted_syms);
}


static bool
build_litlen_decode_table(struct libdeflate_decompressor *d,
			  unsigned num_litlen_syms, unsigned num_offset_syms)
{
	
	STATIC_ASSERT(LITLEN_TABLEBITS == 10 && LITLEN_ENOUGH == 1334);

	return build_decode_table(d->u.litlen_decode_table,
				  d->u.l.lens,
				  num_litlen_syms,
				  litlen_decode_results,
				  LITLEN_TABLEBITS,
				  DEFLATE_MAX_LITLEN_CODEWORD_LEN,
				  d->sorted_syms);
}


static bool
build_offset_decode_table(struct libdeflate_decompressor *d,
			  unsigned num_litlen_syms, unsigned num_offset_syms)
{
	
	STATIC_ASSERT(OFFSET_TABLEBITS == 8 && OFFSET_ENOUGH == 402);

	return build_decode_table(d->offset_decode_table,
				  d->u.l.lens + num_litlen_syms,
				  num_offset_syms,
				  offset_decode_results,
				  OFFSET_TABLEBITS,
				  DEFLATE_MAX_OFFSET_CODEWORD_LEN,
				  d->sorted_syms);
}

static forceinline machine_word_t
repeat_byte(u8 b)
{
	machine_word_t v;

	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);

	v = b;
	v |= v << 8;
	v |= v << 16;
	v |= v << ((WORDBITS == 64) ? 32 : 0);
	return v;
}

static forceinline void
copy_word_unaligned(const void *src, void *dst)
{
	store_word_unaligned(load_word_unaligned(src), dst);
}



typedef enum libdeflate_result (*decompress_func_t)
	(struct libdeflate_decompressor * restrict d,
	 const void * restrict in, size_t in_nbytes,
	 void * restrict out, size_t out_nbytes_avail,
	 size_t *actual_in_nbytes_ret, size_t *actual_out_nbytes_ret);

#undef DEFAULT_IMPL
#undef DISPATCH
#if defined(__i386__) || defined(__x86_64__)
/* #  include "x86/decompress_impl.h" */
/* #include "x86-cpu_features.h" */


#ifndef LIB_X86_CPU_FEATURES_H
#define LIB_X86_CPU_FEATURES_H

/* #include "lib_common.h" */


#ifndef LIB_LIB_COMMON_H
#define LIB_LIB_COMMON_H

#ifdef LIBDEFLATE_H
#  error "lib_common.h must always be included before libdeflate.h"
   
#endif

#define BUILDING_LIBDEFLATE

/* #include "../common/common_defs.h" */


#ifndef COMMON_COMMON_DEFS_H
#define COMMON_COMMON_DEFS_H

#ifdef __GNUC__
/* #  include "compiler_gcc.h" */


#if !defined(__clang__) && !defined(__INTEL_COMPILER)
#  define GCC_PREREQ(major, minor)		\
	(__GNUC__ > (major) ||			\
	 (__GNUC__ == (major) && __GNUC_MINOR__ >= (minor)))
#else
#  define GCC_PREREQ(major, minor)	0
#endif


#ifdef __clang__
#  ifdef __apple_build_version__
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__apple_build_version__ >= (apple_version))
#  else
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__clang_major__ > (major) ||			\
	 (__clang_major__ == (major) && __clang_minor__ >= (minor)))
#  endif
#else
#  define CLANG_PREREQ(major, minor, apple_version)	0
#endif

#ifndef __has_attribute
#  define __has_attribute(attribute)	0
#endif
#ifndef __has_feature
#  define __has_feature(feature)	0
#endif
#ifndef __has_builtin
#  define __has_builtin(builtin)	0
#endif

#ifdef _WIN32
#  define LIBEXPORT __declspec(dllexport)
#else
#  define LIBEXPORT __attribute__((visibility("default")))
#endif

#define inline			inline
#define forceinline		inline __attribute__((always_inline))
#define restrict		__restrict__
#define likely(expr)		__builtin_expect(!!(expr), 1)
#define unlikely(expr)		__builtin_expect(!!(expr), 0)
#define prefetchr(addr)		__builtin_prefetch((addr), 0)
#define prefetchw(addr)		__builtin_prefetch((addr), 1)
#define _aligned_attribute(n)	__attribute__((aligned(n)))

#define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE	\
	(GCC_PREREQ(4, 4) || __has_attribute(target))

#if COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE

#  if defined(__i386__) || defined(__x86_64__)

#    define COMPILER_SUPPORTS_PCLMUL_TARGET	\
	(GCC_PREREQ(4, 4) || __has_builtin(__builtin_ia32_pclmulqdq128))

#    define COMPILER_SUPPORTS_AVX_TARGET	\
	(GCC_PREREQ(4, 6) || __has_builtin(__builtin_ia32_maxps256))

#    define COMPILER_SUPPORTS_BMI2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_pdep_di))

#    define COMPILER_SUPPORTS_AVX2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_psadbw256))

#    define COMPILER_SUPPORTS_AVX512BW_TARGET	\
	(GCC_PREREQ(5, 1) || __has_builtin(__builtin_ia32_psadbw512))

	
#    if GCC_PREREQ(4, 9) || CLANG_PREREQ(3, 8, 7030000)
#      define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS	1
#      define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_PCLMUL_TARGET
#      define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX2_TARGET
#      define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX512BW_TARGET
#    endif

#  elif defined(__arm__) || defined(__aarch64__)

    
#    if (GCC_PREREQ(6, 1) && defined(__ARM_FP)) || \
        (defined(__clang__) && defined(__ARM_NEON))
#      define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 1
       
#      if defined(__clang__) && defined(__arm__)
#        undef __ARM_FEATURE_CRYPTO
#      elif __has_builtin(__builtin_neon_vmull_p64) || !defined(__clang__)
#        define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 1
#      endif
#    endif

     
#    if GCC_PREREQ(10, 1) || \
        (GCC_PREREQ(9, 3) && !GCC_PREREQ(10, 0)) || \
        (GCC_PREREQ(8, 4) && !GCC_PREREQ(9, 0)) || \
        (defined(__clang__) && __has_builtin(__builtin_arm_crc32b))
#      define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 1
#    endif

#  endif 

#endif 


#if (GCC_PREREQ(4, 0) && !GCC_PREREQ(5, 1)) || \
    (defined(__clang__) && !CLANG_PREREQ(3, 9, 8020000))
typedef unsigned long long  __v2du __attribute__((__vector_size__(16)));
typedef unsigned int        __v4su __attribute__((__vector_size__(16)));
typedef unsigned short      __v8hu __attribute__((__vector_size__(16)));
typedef unsigned char      __v16qu __attribute__((__vector_size__(16)));
typedef unsigned long long  __v4du __attribute__((__vector_size__(32)));
typedef unsigned int        __v8su __attribute__((__vector_size__(32)));
typedef unsigned short     __v16hu __attribute__((__vector_size__(32)));
typedef unsigned char      __v32qu __attribute__((__vector_size__(32)));
#endif


#ifdef __BYTE_ORDER__
#  define CPU_IS_LITTLE_ENDIAN() (__BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__)
#endif

#if GCC_PREREQ(4, 8) || __has_builtin(__builtin_bswap16)
#  define bswap16	__builtin_bswap16
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap32)
#  define bswap32	__builtin_bswap32
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap64)
#  define bswap64	__builtin_bswap64
#endif

#if defined(__x86_64__) || defined(__i386__) || defined(__ARM_FEATURE_UNALIGNED) || defined(__powerpc64__)
#  define UNALIGNED_ACCESS_IS_FAST 1
#endif

#define bsr32(n)	(31 - __builtin_clz(n))
#define bsr64(n)	(63 - __builtin_clzll(n))
#define bsf32(n)	__builtin_ctz(n)
#define bsf64(n)	__builtin_ctzll(n)

#elif defined(_MSC_VER)
/* #  include "compiler_msc.h" */


#include <stdint.h>
#include <stdlib.h> 

#define LIBEXPORT	__declspec(dllexport)


typedef int bool;
#define true 1
#define false 0
#define __bool_true_false_are_defined 1


#ifdef _WIN64
typedef long long ssize_t;
#else
typedef int ssize_t;
#endif


#define CPU_IS_LITTLE_ENDIAN()		1
#define UNALIGNED_ACCESS_IS_FAST	1


#define restrict


#define inline		__inline
#define forceinline	__forceinline


#define bswap16	_byteswap_ushort
#define bswap32	_byteswap_ulong
#define bswap64	_byteswap_uint64



static forceinline unsigned
bsr32(uint32_t n)
{
	_BitScanReverse(&n, n);
	return n;
}
#define bsr32 bsr32

static forceinline unsigned
bsf32(uint32_t n)
{
	_BitScanForward(&n, n);
	return n;
}
#define bsf32 bsf32

#ifdef _M_X64 

static forceinline unsigned
bsr64(uint64_t n)
{
	_BitScanReverse64(&n, n);
	return n;
}
#define bsr64 bsr64

static forceinline unsigned
bsf64(uint64_t n)
{
	_BitScanForward64(&n, n);
	return n;
}
#define bsf64 bsf64

#endif 

#else
#  pragma message("Unrecognized compiler.  Please add a header file for your compiler.  Compilation will proceed, but performance may suffer!")
#endif





#include <stddef.h> 

#ifndef __bool_true_false_are_defined
#  include <stdbool.h> 
#endif


#include <stdint.h>
typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
typedef int8_t s8;
typedef int16_t s16;
typedef int32_t s32;
typedef int64_t s64;


typedef size_t machine_word_t;


#define WORDBYTES	((int)sizeof(machine_word_t))


#define WORDBITS	(8 * WORDBYTES)






#ifndef LIBEXPORT
#  define LIBEXPORT
#endif


#ifndef inline
#  define inline
#endif


#ifndef forceinline
#  define forceinline inline
#endif


#ifndef restrict
#  define restrict
#endif


#ifndef likely
#  define likely(expr)		(expr)
#endif


#ifndef unlikely
#  define unlikely(expr)	(expr)
#endif


#ifndef prefetchr
#  define prefetchr(addr)
#endif


#ifndef prefetchw
#  define prefetchw(addr)
#endif


#ifndef COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE
#  define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE 0
#endif


#ifndef COMPILER_SUPPORTS_BMI2_TARGET
#  define COMPILER_SUPPORTS_BMI2_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX_TARGET
#  define COMPILER_SUPPORTS_AVX_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET
#  define COMPILER_SUPPORTS_AVX512BW_TARGET 0
#endif


#ifndef COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 0
#endif


#ifndef _aligned_attribute
#endif





#define ARRAY_LEN(A)		(sizeof(A) / sizeof((A)[0]))
#define MIN(a, b)		((a) <= (b) ? (a) : (b))
#define MAX(a, b)		((a) >= (b) ? (a) : (b))
#define DIV_ROUND_UP(n, d)	(((n) + (d) - 1) / (d))
#define STATIC_ASSERT(expr)	((void)sizeof(char[1 - 2 * !(expr)]))
#define ALIGN(n, a)		(((n) + (a) - 1) & ~((a) - 1))






#ifndef CPU_IS_LITTLE_ENDIAN
static forceinline int CPU_IS_LITTLE_ENDIAN(void)
{
	union {
		unsigned int v;
		unsigned char b;
	} u;
	u.v = 1;
	return u.b;
}
#endif


#ifndef bswap16
static forceinline u16 bswap16(u16 n)
{
	return (n << 8) | (n >> 8);
}
#endif


#ifndef bswap32
static forceinline u32 bswap32(u32 n)
{
	return ((n & 0x000000FF) << 24) |
	       ((n & 0x0000FF00) << 8) |
	       ((n & 0x00FF0000) >> 8) |
	       ((n & 0xFF000000) >> 24);
}
#endif


#ifndef bswap64
static forceinline u64 bswap64(u64 n)
{
	return ((n & 0x00000000000000FF) << 56) |
	       ((n & 0x000000000000FF00) << 40) |
	       ((n & 0x0000000000FF0000) << 24) |
	       ((n & 0x00000000FF000000) << 8) |
	       ((n & 0x000000FF00000000) >> 8) |
	       ((n & 0x0000FF0000000000) >> 24) |
	       ((n & 0x00FF000000000000) >> 40) |
	       ((n & 0xFF00000000000000) >> 56);
}
#endif

#define le16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap16(n))
#define le32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap32(n))
#define le64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap64(n))
#define be16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap16(n) : (n))
#define be32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap32(n) : (n))
#define be64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap64(n) : (n))






#ifndef UNALIGNED_ACCESS_IS_FAST
#  define UNALIGNED_ACCESS_IS_FAST 0
#endif







#ifndef bsr32
static forceinline unsigned
bsr32(u32 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

#ifndef bsr64
static forceinline unsigned
bsr64(u64 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

static forceinline unsigned
bsrw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsr32(n);
	else
		return bsr64(n);
}



#ifndef bsf32
static forceinline unsigned
bsf32(u32 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

#ifndef bsf64
static forceinline unsigned
bsf64(u64 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

static forceinline unsigned
bsfw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsf32(n);
	else
		return bsf64(n);
}

#endif 



#define SYM_FIXUP(sym)			_libdeflate_##sym
#define deflate_get_compression_level	SYM_FIXUP(deflate_get_compression_level)
#define _cpu_features			SYM_FIXUP(_cpu_features)
#define setup_cpu_features		SYM_FIXUP(setup_cpu_features)

void *libdeflate_malloc(size_t size);
void libdeflate_free(void *ptr);

void *libdeflate_aligned_malloc(size_t alignment, size_t size);
void libdeflate_aligned_free(void *ptr);

#ifdef FREESTANDING

void *memset(void *s, int c, size_t n);
#define memset(s, c, n)		__builtin_memset((s), (c), (n))

void *memcpy(void *dest, const void *src, size_t n);
#define memcpy(dest, src, n)	__builtin_memcpy((dest), (src), (n))

void *memmove(void *dest, const void *src, size_t n);
#define memmove(dest, src, n)	__builtin_memmove((dest), (src), (n))

int memcmp(const void *s1, const void *s2, size_t n);
#define memcmp(s1, s2, n)	__builtin_memcmp((s1), (s2), (n))
#else
#include <string.h>
#endif

#endif 


#if (defined(__i386__) || defined(__x86_64__)) && \
	COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE
#  define X86_CPU_FEATURES_ENABLED 1
#else
#  define X86_CPU_FEATURES_ENABLED 0
#endif

#if X86_CPU_FEATURES_ENABLED

#define X86_CPU_FEATURE_SSE2		0x00000001
#define X86_CPU_FEATURE_PCLMUL		0x00000002
#define X86_CPU_FEATURE_AVX		0x00000004
#define X86_CPU_FEATURE_AVX2		0x00000008
#define X86_CPU_FEATURE_BMI2		0x00000010
#define X86_CPU_FEATURE_AVX512BW	0x00000020

#define X86_CPU_FEATURES_KNOWN		0x80000000

extern volatile u32 _cpu_features;

void setup_cpu_features(void);

static inline u32 get_cpu_features(void)
{
	if (_cpu_features == 0)
		setup_cpu_features();
	return _cpu_features;
}

#endif 

#endif 



#undef DISPATCH_BMI2
#if !defined(__BMI2__) && X86_CPU_FEATURES_ENABLED && \
	COMPILER_SUPPORTS_BMI2_TARGET
#  define FUNCNAME	deflate_decompress_bmi2
#  define ATTRIBUTES	__attribute__((target("bmi2")))
#  define DISPATCH	1
#  define DISPATCH_BMI2	1
/* #include "decompress_template.h" */




static enum libdeflate_result ATTRIBUTES
FUNCNAME(struct libdeflate_decompressor * restrict d,
	 const void * restrict in, size_t in_nbytes,
	 void * restrict out, size_t out_nbytes_avail,
	 size_t *actual_in_nbytes_ret, size_t *actual_out_nbytes_ret)
{
	u8 *out_next = out;
	u8 * const out_end = out_next + out_nbytes_avail;
	const u8 *in_next = in;
	const u8 * const in_end = in_next + in_nbytes;
	bitbuf_t bitbuf = 0;
	unsigned bitsleft = 0;
	size_t overrun_count = 0;
	unsigned i;
	unsigned is_final_block;
	unsigned block_type;
	u16 len;
	u16 nlen;
	unsigned num_litlen_syms;
	unsigned num_offset_syms;
	u16 tmp16;
	u32 tmp32;

next_block:
	
	;

	STATIC_ASSERT(CAN_ENSURE(1 + 2 + 5 + 5 + 4));
	ENSURE_BITS(1 + 2 + 5 + 5 + 4);

	
	is_final_block = POP_BITS(1);

	
	block_type = POP_BITS(2);

	if (block_type == DEFLATE_BLOCKTYPE_DYNAMIC_HUFFMAN) {

		

		
		static const u8 deflate_precode_lens_permutation[DEFLATE_NUM_PRECODE_SYMS] = {
			16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15
		};

		unsigned num_explicit_precode_lens;

		

		STATIC_ASSERT(DEFLATE_NUM_LITLEN_SYMS == ((1 << 5) - 1) + 257);
		num_litlen_syms = POP_BITS(5) + 257;

		STATIC_ASSERT(DEFLATE_NUM_OFFSET_SYMS == ((1 << 5) - 1) + 1);
		num_offset_syms = POP_BITS(5) + 1;

		STATIC_ASSERT(DEFLATE_NUM_PRECODE_SYMS == ((1 << 4) - 1) + 4);
		num_explicit_precode_lens = POP_BITS(4) + 4;

		d->static_codes_loaded = false;

		
		STATIC_ASSERT(DEFLATE_MAX_PRE_CODEWORD_LEN == (1 << 3) - 1);
		for (i = 0; i < num_explicit_precode_lens; i++) {
			ENSURE_BITS(3);
			d->u.precode_lens[deflate_precode_lens_permutation[i]] = POP_BITS(3);
		}

		for (; i < DEFLATE_NUM_PRECODE_SYMS; i++)
			d->u.precode_lens[deflate_precode_lens_permutation[i]] = 0;

		
		SAFETY_CHECK(build_precode_decode_table(d));

		
		for (i = 0; i < num_litlen_syms + num_offset_syms; ) {
			u32 entry;
			unsigned presym;
			u8 rep_val;
			unsigned rep_count;

			ENSURE_BITS(DEFLATE_MAX_PRE_CODEWORD_LEN + 7);

			
			STATIC_ASSERT(PRECODE_TABLEBITS == DEFLATE_MAX_PRE_CODEWORD_LEN);

			
			entry = d->u.l.precode_decode_table[BITS(DEFLATE_MAX_PRE_CODEWORD_LEN)];
			REMOVE_BITS(entry & HUFFDEC_LENGTH_MASK);
			presym = entry >> HUFFDEC_RESULT_SHIFT;

			if (presym < 16) {
				
				d->u.l.lens[i++] = presym;
				continue;
			}

			

			
			STATIC_ASSERT(DEFLATE_MAX_LENS_OVERRUN == 138 - 1);

			if (presym == 16) {
				
				SAFETY_CHECK(i != 0);
				rep_val = d->u.l.lens[i - 1];
				STATIC_ASSERT(3 + ((1 << 2) - 1) == 6);
				rep_count = 3 + POP_BITS(2);
				d->u.l.lens[i + 0] = rep_val;
				d->u.l.lens[i + 1] = rep_val;
				d->u.l.lens[i + 2] = rep_val;
				d->u.l.lens[i + 3] = rep_val;
				d->u.l.lens[i + 4] = rep_val;
				d->u.l.lens[i + 5] = rep_val;
				i += rep_count;
			} else if (presym == 17) {
				
				STATIC_ASSERT(3 + ((1 << 3) - 1) == 10);
				rep_count = 3 + POP_BITS(3);
				d->u.l.lens[i + 0] = 0;
				d->u.l.lens[i + 1] = 0;
				d->u.l.lens[i + 2] = 0;
				d->u.l.lens[i + 3] = 0;
				d->u.l.lens[i + 4] = 0;
				d->u.l.lens[i + 5] = 0;
				d->u.l.lens[i + 6] = 0;
				d->u.l.lens[i + 7] = 0;
				d->u.l.lens[i + 8] = 0;
				d->u.l.lens[i + 9] = 0;
				i += rep_count;
			} else {
				
				STATIC_ASSERT(11 + ((1 << 7) - 1) == 138);
				rep_count = 11 + POP_BITS(7);
				memset(&d->u.l.lens[i], 0,
				       rep_count * sizeof(d->u.l.lens[i]));
				i += rep_count;
			}
		}
	} else if (block_type == DEFLATE_BLOCKTYPE_UNCOMPRESSED) {

		

		ALIGN_INPUT();

		SAFETY_CHECK(in_end - in_next >= 4);

		len = READ_U16();
		nlen = READ_U16();

		SAFETY_CHECK(len == (u16)~nlen);
		if (unlikely(len > out_end - out_next))
			return LIBDEFLATE_INSUFFICIENT_SPACE;
		SAFETY_CHECK(len <= in_end - in_next);

		memcpy(out_next, in_next, len);
		in_next += len;
		out_next += len;

		goto block_done;

	} else {
		SAFETY_CHECK(block_type == DEFLATE_BLOCKTYPE_STATIC_HUFFMAN);

		

		if (d->static_codes_loaded)
			goto have_decode_tables;

		d->static_codes_loaded = true;

		STATIC_ASSERT(DEFLATE_NUM_LITLEN_SYMS == 288);
		STATIC_ASSERT(DEFLATE_NUM_OFFSET_SYMS == 32);

		for (i = 0; i < 144; i++)
			d->u.l.lens[i] = 8;
		for (; i < 256; i++)
			d->u.l.lens[i] = 9;
		for (; i < 280; i++)
			d->u.l.lens[i] = 7;
		for (; i < 288; i++)
			d->u.l.lens[i] = 8;

		for (; i < 288 + 32; i++)
			d->u.l.lens[i] = 5;

		num_litlen_syms = 288;
		num_offset_syms = 32;
	}

	

	SAFETY_CHECK(build_offset_decode_table(d, num_litlen_syms, num_offset_syms));
	SAFETY_CHECK(build_litlen_decode_table(d, num_litlen_syms, num_offset_syms));
have_decode_tables:

	
	for (;;) {
		u32 entry;
		u32 length;
		u32 offset;
		const u8 *src;
		u8 *dst;

		
		ENSURE_BITS(DEFLATE_MAX_LITLEN_CODEWORD_LEN);
		entry = d->u.litlen_decode_table[BITS(LITLEN_TABLEBITS)];
		if (entry & HUFFDEC_SUBTABLE_POINTER) {
			
			REMOVE_BITS(LITLEN_TABLEBITS);
			entry = d->u.litlen_decode_table[
				((entry >> HUFFDEC_RESULT_SHIFT) & 0xFFFF) +
				BITS(entry & HUFFDEC_LENGTH_MASK)];
		}
		REMOVE_BITS(entry & HUFFDEC_LENGTH_MASK);
		if (entry & HUFFDEC_LITERAL) {
			
			if (unlikely(out_next == out_end))
				return LIBDEFLATE_INSUFFICIENT_SPACE;
			*out_next++ = (u8)(entry >> HUFFDEC_RESULT_SHIFT);
			continue;
		}

		

		entry >>= HUFFDEC_RESULT_SHIFT;
		ENSURE_BITS(MAX_ENSURE);

		
		length = (entry >> HUFFDEC_LENGTH_BASE_SHIFT) +
			 POP_BITS(entry & HUFFDEC_EXTRA_LENGTH_BITS_MASK);

		
		STATIC_ASSERT(HUFFDEC_END_OF_BLOCK_LENGTH == 0);
		if (unlikely((size_t)length - 1 >= out_end - out_next)) {
			if (unlikely(length != HUFFDEC_END_OF_BLOCK_LENGTH))
				return LIBDEFLATE_INSUFFICIENT_SPACE;
			goto block_done;
		}

		

		entry = d->offset_decode_table[BITS(OFFSET_TABLEBITS)];
		if (entry & HUFFDEC_SUBTABLE_POINTER) {
			
			REMOVE_BITS(OFFSET_TABLEBITS);
			entry = d->offset_decode_table[
				((entry >> HUFFDEC_RESULT_SHIFT) & 0xFFFF) +
				BITS(entry & HUFFDEC_LENGTH_MASK)];
		}
		REMOVE_BITS(entry & HUFFDEC_LENGTH_MASK);
		entry >>= HUFFDEC_RESULT_SHIFT;

		STATIC_ASSERT(CAN_ENSURE(DEFLATE_MAX_EXTRA_LENGTH_BITS +
					 DEFLATE_MAX_OFFSET_CODEWORD_LEN) &&
			      CAN_ENSURE(DEFLATE_MAX_EXTRA_OFFSET_BITS));
		if (!CAN_ENSURE(DEFLATE_MAX_EXTRA_LENGTH_BITS +
				DEFLATE_MAX_OFFSET_CODEWORD_LEN +
				DEFLATE_MAX_EXTRA_OFFSET_BITS))
			ENSURE_BITS(DEFLATE_MAX_EXTRA_OFFSET_BITS);

		
		offset = (entry & HUFFDEC_OFFSET_BASE_MASK) +
			 POP_BITS(entry >> HUFFDEC_EXTRA_OFFSET_BITS_SHIFT);

		
		SAFETY_CHECK(offset <= out_next - (const u8 *)out);

		

		src = out_next - offset;
		dst = out_next;
		out_next += length;

		if (UNALIGNED_ACCESS_IS_FAST &&
		    
		    likely(out_end - out_next >=
			   3 * WORDBYTES - DEFLATE_MIN_MATCH_LEN)) {
			if (offset >= WORDBYTES) { 
				copy_word_unaligned(src, dst);
				src += WORDBYTES;
				dst += WORDBYTES;
				copy_word_unaligned(src, dst);
				src += WORDBYTES;
				dst += WORDBYTES;
				do {
					copy_word_unaligned(src, dst);
					src += WORDBYTES;
					dst += WORDBYTES;
				} while (dst < out_next);
			} else if (offset == 1) {
				
				machine_word_t v = repeat_byte(*src);

				store_word_unaligned(v, dst);
				dst += WORDBYTES;
				store_word_unaligned(v, dst);
				dst += WORDBYTES;
				do {
					store_word_unaligned(v, dst);
					dst += WORDBYTES;
				} while (dst < out_next);
			} else {
				*dst++ = *src++;
				*dst++ = *src++;
				do {
					*dst++ = *src++;
				} while (dst < out_next);
			}
		} else {
			STATIC_ASSERT(DEFLATE_MIN_MATCH_LEN == 3);
			*dst++ = *src++;
			*dst++ = *src++;
			do {
				*dst++ = *src++;
			} while (dst < out_next);
		}
	}

block_done:
	

	if (!is_final_block)
		goto next_block;

	

	
	ALIGN_INPUT();

	
	if (actual_in_nbytes_ret)
		*actual_in_nbytes_ret = in_next - (u8 *)in;

	
	if (actual_out_nbytes_ret) {
		*actual_out_nbytes_ret = out_next - (u8 *)out;
	} else {
		if (out_next != out_end)
			return LIBDEFLATE_SHORT_OUTPUT;
	}
	return LIBDEFLATE_SUCCESS;
}

#undef FUNCNAME
#undef ATTRIBUTES

#endif

#ifdef DISPATCH
static inline decompress_func_t
arch_select_decompress_func(void)
{
	u32 features = get_cpu_features();

#ifdef DISPATCH_BMI2
	if (features & X86_CPU_FEATURE_BMI2)
		return deflate_decompress_bmi2;
#endif
	return NULL;
}
#endif 

#endif

#ifndef DEFAULT_IMPL
#  define FUNCNAME deflate_decompress_default
#  define ATTRIBUTES
/* #  include "decompress_template.h" */




static enum libdeflate_result ATTRIBUTES
FUNCNAME(struct libdeflate_decompressor * restrict d,
	 const void * restrict in, size_t in_nbytes,
	 void * restrict out, size_t out_nbytes_avail,
	 size_t *actual_in_nbytes_ret, size_t *actual_out_nbytes_ret)
{
	u8 *out_next = out;
	u8 * const out_end = out_next + out_nbytes_avail;
	const u8 *in_next = in;
	const u8 * const in_end = in_next + in_nbytes;
	bitbuf_t bitbuf = 0;
	unsigned bitsleft = 0;
	size_t overrun_count = 0;
	unsigned i;
	unsigned is_final_block;
	unsigned block_type;
	u16 len;
	u16 nlen;
	unsigned num_litlen_syms;
	unsigned num_offset_syms;
	u16 tmp16;
	u32 tmp32;

next_block:
	
	;

	STATIC_ASSERT(CAN_ENSURE(1 + 2 + 5 + 5 + 4));
	ENSURE_BITS(1 + 2 + 5 + 5 + 4);

	
	is_final_block = POP_BITS(1);

	
	block_type = POP_BITS(2);

	if (block_type == DEFLATE_BLOCKTYPE_DYNAMIC_HUFFMAN) {

		

		
		static const u8 deflate_precode_lens_permutation[DEFLATE_NUM_PRECODE_SYMS] = {
			16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15
		};

		unsigned num_explicit_precode_lens;

		

		STATIC_ASSERT(DEFLATE_NUM_LITLEN_SYMS == ((1 << 5) - 1) + 257);
		num_litlen_syms = POP_BITS(5) + 257;

		STATIC_ASSERT(DEFLATE_NUM_OFFSET_SYMS == ((1 << 5) - 1) + 1);
		num_offset_syms = POP_BITS(5) + 1;

		STATIC_ASSERT(DEFLATE_NUM_PRECODE_SYMS == ((1 << 4) - 1) + 4);
		num_explicit_precode_lens = POP_BITS(4) + 4;

		d->static_codes_loaded = false;

		
		STATIC_ASSERT(DEFLATE_MAX_PRE_CODEWORD_LEN == (1 << 3) - 1);
		for (i = 0; i < num_explicit_precode_lens; i++) {
			ENSURE_BITS(3);
			d->u.precode_lens[deflate_precode_lens_permutation[i]] = POP_BITS(3);
		}

		for (; i < DEFLATE_NUM_PRECODE_SYMS; i++)
			d->u.precode_lens[deflate_precode_lens_permutation[i]] = 0;

		
		SAFETY_CHECK(build_precode_decode_table(d));

		
		for (i = 0; i < num_litlen_syms + num_offset_syms; ) {
			u32 entry;
			unsigned presym;
			u8 rep_val;
			unsigned rep_count;

			ENSURE_BITS(DEFLATE_MAX_PRE_CODEWORD_LEN + 7);

			
			STATIC_ASSERT(PRECODE_TABLEBITS == DEFLATE_MAX_PRE_CODEWORD_LEN);

			
			entry = d->u.l.precode_decode_table[BITS(DEFLATE_MAX_PRE_CODEWORD_LEN)];
			REMOVE_BITS(entry & HUFFDEC_LENGTH_MASK);
			presym = entry >> HUFFDEC_RESULT_SHIFT;

			if (presym < 16) {
				
				d->u.l.lens[i++] = presym;
				continue;
			}

			

			
			STATIC_ASSERT(DEFLATE_MAX_LENS_OVERRUN == 138 - 1);

			if (presym == 16) {
				
				SAFETY_CHECK(i != 0);
				rep_val = d->u.l.lens[i - 1];
				STATIC_ASSERT(3 + ((1 << 2) - 1) == 6);
				rep_count = 3 + POP_BITS(2);
				d->u.l.lens[i + 0] = rep_val;
				d->u.l.lens[i + 1] = rep_val;
				d->u.l.lens[i + 2] = rep_val;
				d->u.l.lens[i + 3] = rep_val;
				d->u.l.lens[i + 4] = rep_val;
				d->u.l.lens[i + 5] = rep_val;
				i += rep_count;
			} else if (presym == 17) {
				
				STATIC_ASSERT(3 + ((1 << 3) - 1) == 10);
				rep_count = 3 + POP_BITS(3);
				d->u.l.lens[i + 0] = 0;
				d->u.l.lens[i + 1] = 0;
				d->u.l.lens[i + 2] = 0;
				d->u.l.lens[i + 3] = 0;
				d->u.l.lens[i + 4] = 0;
				d->u.l.lens[i + 5] = 0;
				d->u.l.lens[i + 6] = 0;
				d->u.l.lens[i + 7] = 0;
				d->u.l.lens[i + 8] = 0;
				d->u.l.lens[i + 9] = 0;
				i += rep_count;
			} else {
				
				STATIC_ASSERT(11 + ((1 << 7) - 1) == 138);
				rep_count = 11 + POP_BITS(7);
				memset(&d->u.l.lens[i], 0,
				       rep_count * sizeof(d->u.l.lens[i]));
				i += rep_count;
			}
		}
	} else if (block_type == DEFLATE_BLOCKTYPE_UNCOMPRESSED) {

		

		ALIGN_INPUT();

		SAFETY_CHECK(in_end - in_next >= 4);

		len = READ_U16();
		nlen = READ_U16();

		SAFETY_CHECK(len == (u16)~nlen);
		if (unlikely(len > out_end - out_next))
			return LIBDEFLATE_INSUFFICIENT_SPACE;
		SAFETY_CHECK(len <= in_end - in_next);

		memcpy(out_next, in_next, len);
		in_next += len;
		out_next += len;

		goto block_done;

	} else {
		SAFETY_CHECK(block_type == DEFLATE_BLOCKTYPE_STATIC_HUFFMAN);

		

		if (d->static_codes_loaded)
			goto have_decode_tables;

		d->static_codes_loaded = true;

		STATIC_ASSERT(DEFLATE_NUM_LITLEN_SYMS == 288);
		STATIC_ASSERT(DEFLATE_NUM_OFFSET_SYMS == 32);

		for (i = 0; i < 144; i++)
			d->u.l.lens[i] = 8;
		for (; i < 256; i++)
			d->u.l.lens[i] = 9;
		for (; i < 280; i++)
			d->u.l.lens[i] = 7;
		for (; i < 288; i++)
			d->u.l.lens[i] = 8;

		for (; i < 288 + 32; i++)
			d->u.l.lens[i] = 5;

		num_litlen_syms = 288;
		num_offset_syms = 32;
	}

	

	SAFETY_CHECK(build_offset_decode_table(d, num_litlen_syms, num_offset_syms));
	SAFETY_CHECK(build_litlen_decode_table(d, num_litlen_syms, num_offset_syms));
have_decode_tables:

	
	for (;;) {
		u32 entry;
		u32 length;
		u32 offset;
		const u8 *src;
		u8 *dst;

		
		ENSURE_BITS(DEFLATE_MAX_LITLEN_CODEWORD_LEN);
		entry = d->u.litlen_decode_table[BITS(LITLEN_TABLEBITS)];
		if (entry & HUFFDEC_SUBTABLE_POINTER) {
			
			REMOVE_BITS(LITLEN_TABLEBITS);
			entry = d->u.litlen_decode_table[
				((entry >> HUFFDEC_RESULT_SHIFT) & 0xFFFF) +
				BITS(entry & HUFFDEC_LENGTH_MASK)];
		}
		REMOVE_BITS(entry & HUFFDEC_LENGTH_MASK);
		if (entry & HUFFDEC_LITERAL) {
			
			if (unlikely(out_next == out_end))
				return LIBDEFLATE_INSUFFICIENT_SPACE;
			*out_next++ = (u8)(entry >> HUFFDEC_RESULT_SHIFT);
			continue;
		}

		

		entry >>= HUFFDEC_RESULT_SHIFT;
		ENSURE_BITS(MAX_ENSURE);

		
		length = (entry >> HUFFDEC_LENGTH_BASE_SHIFT) +
			 POP_BITS(entry & HUFFDEC_EXTRA_LENGTH_BITS_MASK);

		
		STATIC_ASSERT(HUFFDEC_END_OF_BLOCK_LENGTH == 0);
		if (unlikely((size_t)length - 1 >= out_end - out_next)) {
			if (unlikely(length != HUFFDEC_END_OF_BLOCK_LENGTH))
				return LIBDEFLATE_INSUFFICIENT_SPACE;
			goto block_done;
		}

		

		entry = d->offset_decode_table[BITS(OFFSET_TABLEBITS)];
		if (entry & HUFFDEC_SUBTABLE_POINTER) {
			
			REMOVE_BITS(OFFSET_TABLEBITS);
			entry = d->offset_decode_table[
				((entry >> HUFFDEC_RESULT_SHIFT) & 0xFFFF) +
				BITS(entry & HUFFDEC_LENGTH_MASK)];
		}
		REMOVE_BITS(entry & HUFFDEC_LENGTH_MASK);
		entry >>= HUFFDEC_RESULT_SHIFT;

		STATIC_ASSERT(CAN_ENSURE(DEFLATE_MAX_EXTRA_LENGTH_BITS +
					 DEFLATE_MAX_OFFSET_CODEWORD_LEN) &&
			      CAN_ENSURE(DEFLATE_MAX_EXTRA_OFFSET_BITS));
		if (!CAN_ENSURE(DEFLATE_MAX_EXTRA_LENGTH_BITS +
				DEFLATE_MAX_OFFSET_CODEWORD_LEN +
				DEFLATE_MAX_EXTRA_OFFSET_BITS))
			ENSURE_BITS(DEFLATE_MAX_EXTRA_OFFSET_BITS);

		
		offset = (entry & HUFFDEC_OFFSET_BASE_MASK) +
			 POP_BITS(entry >> HUFFDEC_EXTRA_OFFSET_BITS_SHIFT);

		
		SAFETY_CHECK(offset <= out_next - (const u8 *)out);

		

		src = out_next - offset;
		dst = out_next;
		out_next += length;

		if (UNALIGNED_ACCESS_IS_FAST &&
		    
		    likely(out_end - out_next >=
			   3 * WORDBYTES - DEFLATE_MIN_MATCH_LEN)) {
			if (offset >= WORDBYTES) { 
				copy_word_unaligned(src, dst);
				src += WORDBYTES;
				dst += WORDBYTES;
				copy_word_unaligned(src, dst);
				src += WORDBYTES;
				dst += WORDBYTES;
				do {
					copy_word_unaligned(src, dst);
					src += WORDBYTES;
					dst += WORDBYTES;
				} while (dst < out_next);
			} else if (offset == 1) {
				
				machine_word_t v = repeat_byte(*src);

				store_word_unaligned(v, dst);
				dst += WORDBYTES;
				store_word_unaligned(v, dst);
				dst += WORDBYTES;
				do {
					store_word_unaligned(v, dst);
					dst += WORDBYTES;
				} while (dst < out_next);
			} else {
				*dst++ = *src++;
				*dst++ = *src++;
				do {
					*dst++ = *src++;
				} while (dst < out_next);
			}
		} else {
			STATIC_ASSERT(DEFLATE_MIN_MATCH_LEN == 3);
			*dst++ = *src++;
			*dst++ = *src++;
			do {
				*dst++ = *src++;
			} while (dst < out_next);
		}
	}

block_done:
	

	if (!is_final_block)
		goto next_block;

	

	
	ALIGN_INPUT();

	
	if (actual_in_nbytes_ret)
		*actual_in_nbytes_ret = in_next - (u8 *)in;

	
	if (actual_out_nbytes_ret) {
		*actual_out_nbytes_ret = out_next - (u8 *)out;
	} else {
		if (out_next != out_end)
			return LIBDEFLATE_SHORT_OUTPUT;
	}
	return LIBDEFLATE_SUCCESS;
}

#undef FUNCNAME
#undef ATTRIBUTES

#  define DEFAULT_IMPL deflate_decompress_default
#endif

#ifdef DISPATCH
static enum libdeflate_result
dispatch(struct libdeflate_decompressor * restrict d,
	 const void * restrict in, size_t in_nbytes,
	 void * restrict out, size_t out_nbytes_avail,
	 size_t *actual_in_nbytes_ret, size_t *actual_out_nbytes_ret);

static volatile decompress_func_t decompress_impl = dispatch;


static enum libdeflate_result
dispatch(struct libdeflate_decompressor * restrict d,
	 const void * restrict in, size_t in_nbytes,
	 void * restrict out, size_t out_nbytes_avail,
	 size_t *actual_in_nbytes_ret, size_t *actual_out_nbytes_ret)
{
	decompress_func_t f = arch_select_decompress_func();

	if (f == NULL)
		f = DEFAULT_IMPL;

	decompress_impl = f;
	return (*f)(d, in, in_nbytes, out, out_nbytes_avail,
		    actual_in_nbytes_ret, actual_out_nbytes_ret);
}
#else
#  define decompress_impl DEFAULT_IMPL 
#endif



LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_deflate_decompress_ex(struct libdeflate_decompressor * restrict d,
				 const void * restrict in, size_t in_nbytes,
				 void * restrict out, size_t out_nbytes_avail,
				 size_t *actual_in_nbytes_ret,
				 size_t *actual_out_nbytes_ret)
{
	return decompress_impl(d, in, in_nbytes, out, out_nbytes_avail,
			       actual_in_nbytes_ret, actual_out_nbytes_ret);
}

LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_deflate_decompress(struct libdeflate_decompressor * restrict d,
			      const void * restrict in, size_t in_nbytes,
			      void * restrict out, size_t out_nbytes_avail,
			      size_t *actual_out_nbytes_ret)
{
	return libdeflate_deflate_decompress_ex(d, in, in_nbytes,
						out, out_nbytes_avail,
						NULL, actual_out_nbytes_ret);
}

LIBDEFLATEEXPORT struct libdeflate_decompressor * LIBDEFLATEAPI
libdeflate_alloc_decompressor(void)
{
	
	struct libdeflate_decompressor *d = libdeflate_malloc(sizeof(*d));

	if (d == NULL)
		return NULL;
	memset(d, 0, sizeof(*d));
	return d;
}

LIBDEFLATEEXPORT void LIBDEFLATEAPI
libdeflate_free_decompressor(struct libdeflate_decompressor *d)
{
	libdeflate_free(d);
}
/* /usr/home/ben/projects/gzip-libdeflate/../../software/libdeflate-1.7/lib/gzip_compress.c */


/* #include "deflate_compress.h" */
#ifndef LIB_DEFLATE_COMPRESS_H
#define LIB_DEFLATE_COMPRESS_H

/* #include "lib_common.h" */


#ifndef LIB_LIB_COMMON_H
#define LIB_LIB_COMMON_H

#ifdef LIBDEFLATE_H
#  error "lib_common.h must always be included before libdeflate.h"
   
#endif

#define BUILDING_LIBDEFLATE

/* #include "../common/common_defs.h" */


#ifndef COMMON_COMMON_DEFS_H
#define COMMON_COMMON_DEFS_H

#ifdef __GNUC__
/* #  include "compiler_gcc.h" */


#if !defined(__clang__) && !defined(__INTEL_COMPILER)
#  define GCC_PREREQ(major, minor)		\
	(__GNUC__ > (major) ||			\
	 (__GNUC__ == (major) && __GNUC_MINOR__ >= (minor)))
#else
#  define GCC_PREREQ(major, minor)	0
#endif


#ifdef __clang__
#  ifdef __apple_build_version__
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__apple_build_version__ >= (apple_version))
#  else
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__clang_major__ > (major) ||			\
	 (__clang_major__ == (major) && __clang_minor__ >= (minor)))
#  endif
#else
#  define CLANG_PREREQ(major, minor, apple_version)	0
#endif

#ifndef __has_attribute
#  define __has_attribute(attribute)	0
#endif
#ifndef __has_feature
#  define __has_feature(feature)	0
#endif
#ifndef __has_builtin
#  define __has_builtin(builtin)	0
#endif

#ifdef _WIN32
#  define LIBEXPORT __declspec(dllexport)
#else
#  define LIBEXPORT __attribute__((visibility("default")))
#endif

#define inline			inline
#define forceinline		inline __attribute__((always_inline))
#define restrict		__restrict__
#define likely(expr)		__builtin_expect(!!(expr), 1)
#define unlikely(expr)		__builtin_expect(!!(expr), 0)
#define prefetchr(addr)		__builtin_prefetch((addr), 0)
#define prefetchw(addr)		__builtin_prefetch((addr), 1)
#define _aligned_attribute(n)	__attribute__((aligned(n)))

#define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE	\
	(GCC_PREREQ(4, 4) || __has_attribute(target))

#if COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE

#  if defined(__i386__) || defined(__x86_64__)

#    define COMPILER_SUPPORTS_PCLMUL_TARGET	\
	(GCC_PREREQ(4, 4) || __has_builtin(__builtin_ia32_pclmulqdq128))

#    define COMPILER_SUPPORTS_AVX_TARGET	\
	(GCC_PREREQ(4, 6) || __has_builtin(__builtin_ia32_maxps256))

#    define COMPILER_SUPPORTS_BMI2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_pdep_di))

#    define COMPILER_SUPPORTS_AVX2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_psadbw256))

#    define COMPILER_SUPPORTS_AVX512BW_TARGET	\
	(GCC_PREREQ(5, 1) || __has_builtin(__builtin_ia32_psadbw512))

	
#    if GCC_PREREQ(4, 9) || CLANG_PREREQ(3, 8, 7030000)
#      define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS	1
#      define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_PCLMUL_TARGET
#      define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX2_TARGET
#      define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX512BW_TARGET
#    endif

#  elif defined(__arm__) || defined(__aarch64__)

    
#    if (GCC_PREREQ(6, 1) && defined(__ARM_FP)) || \
        (defined(__clang__) && defined(__ARM_NEON))
#      define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 1
       
#      if defined(__clang__) && defined(__arm__)
#        undef __ARM_FEATURE_CRYPTO
#      elif __has_builtin(__builtin_neon_vmull_p64) || !defined(__clang__)
#        define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 1
#      endif
#    endif

     
#    if GCC_PREREQ(10, 1) || \
        (GCC_PREREQ(9, 3) && !GCC_PREREQ(10, 0)) || \
        (GCC_PREREQ(8, 4) && !GCC_PREREQ(9, 0)) || \
        (defined(__clang__) && __has_builtin(__builtin_arm_crc32b))
#      define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 1
#    endif

#  endif 

#endif 


#if (GCC_PREREQ(4, 0) && !GCC_PREREQ(5, 1)) || \
    (defined(__clang__) && !CLANG_PREREQ(3, 9, 8020000))
typedef unsigned long long  __v2du __attribute__((__vector_size__(16)));
typedef unsigned int        __v4su __attribute__((__vector_size__(16)));
typedef unsigned short      __v8hu __attribute__((__vector_size__(16)));
typedef unsigned char      __v16qu __attribute__((__vector_size__(16)));
typedef unsigned long long  __v4du __attribute__((__vector_size__(32)));
typedef unsigned int        __v8su __attribute__((__vector_size__(32)));
typedef unsigned short     __v16hu __attribute__((__vector_size__(32)));
typedef unsigned char      __v32qu __attribute__((__vector_size__(32)));
#endif


#ifdef __BYTE_ORDER__
#  define CPU_IS_LITTLE_ENDIAN() (__BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__)
#endif

#if GCC_PREREQ(4, 8) || __has_builtin(__builtin_bswap16)
#  define bswap16	__builtin_bswap16
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap32)
#  define bswap32	__builtin_bswap32
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap64)
#  define bswap64	__builtin_bswap64
#endif

#if defined(__x86_64__) || defined(__i386__) || defined(__ARM_FEATURE_UNALIGNED) || defined(__powerpc64__)
#  define UNALIGNED_ACCESS_IS_FAST 1
#endif

#define bsr32(n)	(31 - __builtin_clz(n))
#define bsr64(n)	(63 - __builtin_clzll(n))
#define bsf32(n)	__builtin_ctz(n)
#define bsf64(n)	__builtin_ctzll(n)

#elif defined(_MSC_VER)
/* #  include "compiler_msc.h" */


#include <stdint.h>
#include <stdlib.h> 

#define LIBEXPORT	__declspec(dllexport)


typedef int bool;
#define true 1
#define false 0
#define __bool_true_false_are_defined 1


#ifdef _WIN64
typedef long long ssize_t;
#else
typedef int ssize_t;
#endif


#define CPU_IS_LITTLE_ENDIAN()		1
#define UNALIGNED_ACCESS_IS_FAST	1


#define restrict


#define inline		__inline
#define forceinline	__forceinline


#define bswap16	_byteswap_ushort
#define bswap32	_byteswap_ulong
#define bswap64	_byteswap_uint64



static forceinline unsigned
bsr32(uint32_t n)
{
	_BitScanReverse(&n, n);
	return n;
}
#define bsr32 bsr32

static forceinline unsigned
bsf32(uint32_t n)
{
	_BitScanForward(&n, n);
	return n;
}
#define bsf32 bsf32

#ifdef _M_X64 

static forceinline unsigned
bsr64(uint64_t n)
{
	_BitScanReverse64(&n, n);
	return n;
}
#define bsr64 bsr64

static forceinline unsigned
bsf64(uint64_t n)
{
	_BitScanForward64(&n, n);
	return n;
}
#define bsf64 bsf64

#endif 

#else
#  pragma message("Unrecognized compiler.  Please add a header file for your compiler.  Compilation will proceed, but performance may suffer!")
#endif





#include <stddef.h> 

#ifndef __bool_true_false_are_defined
#  include <stdbool.h> 
#endif


#include <stdint.h>
typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
typedef int8_t s8;
typedef int16_t s16;
typedef int32_t s32;
typedef int64_t s64;


typedef size_t machine_word_t;


#define WORDBYTES	((int)sizeof(machine_word_t))


#define WORDBITS	(8 * WORDBYTES)






#ifndef LIBEXPORT
#  define LIBEXPORT
#endif


#ifndef inline
#  define inline
#endif


#ifndef forceinline
#  define forceinline inline
#endif


#ifndef restrict
#  define restrict
#endif


#ifndef likely
#  define likely(expr)		(expr)
#endif


#ifndef unlikely
#  define unlikely(expr)	(expr)
#endif


#ifndef prefetchr
#  define prefetchr(addr)
#endif


#ifndef prefetchw
#  define prefetchw(addr)
#endif


#ifndef COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE
#  define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE 0
#endif


#ifndef COMPILER_SUPPORTS_BMI2_TARGET
#  define COMPILER_SUPPORTS_BMI2_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX_TARGET
#  define COMPILER_SUPPORTS_AVX_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET
#  define COMPILER_SUPPORTS_AVX512BW_TARGET 0
#endif


#ifndef COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 0
#endif


#ifndef _aligned_attribute
#endif





#define ARRAY_LEN(A)		(sizeof(A) / sizeof((A)[0]))
#define MIN(a, b)		((a) <= (b) ? (a) : (b))
#define MAX(a, b)		((a) >= (b) ? (a) : (b))
#define DIV_ROUND_UP(n, d)	(((n) + (d) - 1) / (d))
#define STATIC_ASSERT(expr)	((void)sizeof(char[1 - 2 * !(expr)]))
#define ALIGN(n, a)		(((n) + (a) - 1) & ~((a) - 1))






#ifndef CPU_IS_LITTLE_ENDIAN
static forceinline int CPU_IS_LITTLE_ENDIAN(void)
{
	union {
		unsigned int v;
		unsigned char b;
	} u;
	u.v = 1;
	return u.b;
}
#endif


#ifndef bswap16
static forceinline u16 bswap16(u16 n)
{
	return (n << 8) | (n >> 8);
}
#endif


#ifndef bswap32
static forceinline u32 bswap32(u32 n)
{
	return ((n & 0x000000FF) << 24) |
	       ((n & 0x0000FF00) << 8) |
	       ((n & 0x00FF0000) >> 8) |
	       ((n & 0xFF000000) >> 24);
}
#endif


#ifndef bswap64
static forceinline u64 bswap64(u64 n)
{
	return ((n & 0x00000000000000FF) << 56) |
	       ((n & 0x000000000000FF00) << 40) |
	       ((n & 0x0000000000FF0000) << 24) |
	       ((n & 0x00000000FF000000) << 8) |
	       ((n & 0x000000FF00000000) >> 8) |
	       ((n & 0x0000FF0000000000) >> 24) |
	       ((n & 0x00FF000000000000) >> 40) |
	       ((n & 0xFF00000000000000) >> 56);
}
#endif

#define le16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap16(n))
#define le32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap32(n))
#define le64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap64(n))
#define be16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap16(n) : (n))
#define be32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap32(n) : (n))
#define be64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap64(n) : (n))






#ifndef UNALIGNED_ACCESS_IS_FAST
#  define UNALIGNED_ACCESS_IS_FAST 0
#endif







#ifndef bsr32
static forceinline unsigned
bsr32(u32 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

#ifndef bsr64
static forceinline unsigned
bsr64(u64 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

static forceinline unsigned
bsrw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsr32(n);
	else
		return bsr64(n);
}



#ifndef bsf32
static forceinline unsigned
bsf32(u32 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

#ifndef bsf64
static forceinline unsigned
bsf64(u64 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

static forceinline unsigned
bsfw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsf32(n);
	else
		return bsf64(n);
}

#endif 



#define SYM_FIXUP(sym)			_libdeflate_##sym
#define deflate_get_compression_level	SYM_FIXUP(deflate_get_compression_level)
#define _cpu_features			SYM_FIXUP(_cpu_features)
#define setup_cpu_features		SYM_FIXUP(setup_cpu_features)

void *libdeflate_malloc(size_t size);
void libdeflate_free(void *ptr);

void *libdeflate_aligned_malloc(size_t alignment, size_t size);
void libdeflate_aligned_free(void *ptr);

#ifdef FREESTANDING

void *memset(void *s, int c, size_t n);
#define memset(s, c, n)		__builtin_memset((s), (c), (n))

void *memcpy(void *dest, const void *src, size_t n);
#define memcpy(dest, src, n)	__builtin_memcpy((dest), (src), (n))

void *memmove(void *dest, const void *src, size_t n);
#define memmove(dest, src, n)	__builtin_memmove((dest), (src), (n))

int memcmp(const void *s1, const void *s2, size_t n);
#define memcmp(s1, s2, n)	__builtin_memcmp((s1), (s2), (n))
#else
#include <string.h>
#endif

#endif 




struct libdeflate_compressor;

unsigned int deflate_get_compression_level(struct libdeflate_compressor *c);

#endif 

/* #include "gzip_constants.h" */


#ifndef LIB_GZIP_CONSTANTS_H
#define LIB_GZIP_CONSTANTS_H

#define GZIP_MIN_HEADER_SIZE	10
#define GZIP_FOOTER_SIZE	8
#define GZIP_MIN_OVERHEAD	(GZIP_MIN_HEADER_SIZE + GZIP_FOOTER_SIZE)

#define GZIP_ID1		0x1F
#define GZIP_ID2		0x8B

#define GZIP_CM_DEFLATE		8

#define GZIP_FTEXT		0x01
#define GZIP_FHCRC		0x02
#define GZIP_FEXTRA		0x04
#define GZIP_FNAME		0x08
#define GZIP_FCOMMENT		0x10
#define GZIP_FRESERVED		0xE0

#define GZIP_MTIME_UNAVAILABLE	0

#define GZIP_XFL_SLOWEST_COMPRESSION	0x02
#define GZIP_XFL_FASTEST_COMPRESSION	0x04

#define GZIP_OS_FAT		0
#define GZIP_OS_AMIGA		1
#define GZIP_OS_VMS		2
#define GZIP_OS_UNIX		3
#define GZIP_OS_VM_CMS		4
#define GZIP_OS_ATARI_TOS	5
#define GZIP_OS_HPFS		6
#define GZIP_OS_MACINTOSH	7
#define GZIP_OS_Z_SYSTEM	8
#define GZIP_OS_CP_M		9
#define GZIP_OS_TOPS_20		10
#define GZIP_OS_NTFS		11
#define GZIP_OS_QDOS		12
#define GZIP_OS_RISCOS		13
#define GZIP_OS_UNKNOWN		255

#endif 

/* #include "unaligned.h" */


#ifndef LIB_UNALIGNED_H
#define LIB_UNALIGNED_H

/* #include "lib_common.h" */


#ifndef LIB_LIB_COMMON_H
#define LIB_LIB_COMMON_H

#ifdef LIBDEFLATE_H
#  error "lib_common.h must always be included before libdeflate.h"
   
#endif

#define BUILDING_LIBDEFLATE

/* #include "../common/common_defs.h" */


#ifndef COMMON_COMMON_DEFS_H
#define COMMON_COMMON_DEFS_H

#ifdef __GNUC__
/* #  include "compiler_gcc.h" */


#if !defined(__clang__) && !defined(__INTEL_COMPILER)
#  define GCC_PREREQ(major, minor)		\
	(__GNUC__ > (major) ||			\
	 (__GNUC__ == (major) && __GNUC_MINOR__ >= (minor)))
#else
#  define GCC_PREREQ(major, minor)	0
#endif


#ifdef __clang__
#  ifdef __apple_build_version__
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__apple_build_version__ >= (apple_version))
#  else
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__clang_major__ > (major) ||			\
	 (__clang_major__ == (major) && __clang_minor__ >= (minor)))
#  endif
#else
#  define CLANG_PREREQ(major, minor, apple_version)	0
#endif

#ifndef __has_attribute
#  define __has_attribute(attribute)	0
#endif
#ifndef __has_feature
#  define __has_feature(feature)	0
#endif
#ifndef __has_builtin
#  define __has_builtin(builtin)	0
#endif

#ifdef _WIN32
#  define LIBEXPORT __declspec(dllexport)
#else
#  define LIBEXPORT __attribute__((visibility("default")))
#endif

#define inline			inline
#define forceinline		inline __attribute__((always_inline))
#define restrict		__restrict__
#define likely(expr)		__builtin_expect(!!(expr), 1)
#define unlikely(expr)		__builtin_expect(!!(expr), 0)
#define prefetchr(addr)		__builtin_prefetch((addr), 0)
#define prefetchw(addr)		__builtin_prefetch((addr), 1)
#define _aligned_attribute(n)	__attribute__((aligned(n)))

#define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE	\
	(GCC_PREREQ(4, 4) || __has_attribute(target))

#if COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE

#  if defined(__i386__) || defined(__x86_64__)

#    define COMPILER_SUPPORTS_PCLMUL_TARGET	\
	(GCC_PREREQ(4, 4) || __has_builtin(__builtin_ia32_pclmulqdq128))

#    define COMPILER_SUPPORTS_AVX_TARGET	\
	(GCC_PREREQ(4, 6) || __has_builtin(__builtin_ia32_maxps256))

#    define COMPILER_SUPPORTS_BMI2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_pdep_di))

#    define COMPILER_SUPPORTS_AVX2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_psadbw256))

#    define COMPILER_SUPPORTS_AVX512BW_TARGET	\
	(GCC_PREREQ(5, 1) || __has_builtin(__builtin_ia32_psadbw512))

	
#    if GCC_PREREQ(4, 9) || CLANG_PREREQ(3, 8, 7030000)
#      define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS	1
#      define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_PCLMUL_TARGET
#      define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX2_TARGET
#      define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX512BW_TARGET
#    endif

#  elif defined(__arm__) || defined(__aarch64__)

    
#    if (GCC_PREREQ(6, 1) && defined(__ARM_FP)) || \
        (defined(__clang__) && defined(__ARM_NEON))
#      define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 1
       
#      if defined(__clang__) && defined(__arm__)
#        undef __ARM_FEATURE_CRYPTO
#      elif __has_builtin(__builtin_neon_vmull_p64) || !defined(__clang__)
#        define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 1
#      endif
#    endif

     
#    if GCC_PREREQ(10, 1) || \
        (GCC_PREREQ(9, 3) && !GCC_PREREQ(10, 0)) || \
        (GCC_PREREQ(8, 4) && !GCC_PREREQ(9, 0)) || \
        (defined(__clang__) && __has_builtin(__builtin_arm_crc32b))
#      define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 1
#    endif

#  endif 

#endif 


#if (GCC_PREREQ(4, 0) && !GCC_PREREQ(5, 1)) || \
    (defined(__clang__) && !CLANG_PREREQ(3, 9, 8020000))
typedef unsigned long long  __v2du __attribute__((__vector_size__(16)));
typedef unsigned int        __v4su __attribute__((__vector_size__(16)));
typedef unsigned short      __v8hu __attribute__((__vector_size__(16)));
typedef unsigned char      __v16qu __attribute__((__vector_size__(16)));
typedef unsigned long long  __v4du __attribute__((__vector_size__(32)));
typedef unsigned int        __v8su __attribute__((__vector_size__(32)));
typedef unsigned short     __v16hu __attribute__((__vector_size__(32)));
typedef unsigned char      __v32qu __attribute__((__vector_size__(32)));
#endif


#ifdef __BYTE_ORDER__
#  define CPU_IS_LITTLE_ENDIAN() (__BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__)
#endif

#if GCC_PREREQ(4, 8) || __has_builtin(__builtin_bswap16)
#  define bswap16	__builtin_bswap16
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap32)
#  define bswap32	__builtin_bswap32
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap64)
#  define bswap64	__builtin_bswap64
#endif

#if defined(__x86_64__) || defined(__i386__) || defined(__ARM_FEATURE_UNALIGNED) || defined(__powerpc64__)
#  define UNALIGNED_ACCESS_IS_FAST 1
#endif

#define bsr32(n)	(31 - __builtin_clz(n))
#define bsr64(n)	(63 - __builtin_clzll(n))
#define bsf32(n)	__builtin_ctz(n)
#define bsf64(n)	__builtin_ctzll(n)

#elif defined(_MSC_VER)
/* #  include "compiler_msc.h" */


#include <stdint.h>
#include <stdlib.h> 

#define LIBEXPORT	__declspec(dllexport)


typedef int bool;
#define true 1
#define false 0
#define __bool_true_false_are_defined 1


#ifdef _WIN64
typedef long long ssize_t;
#else
typedef int ssize_t;
#endif


#define CPU_IS_LITTLE_ENDIAN()		1
#define UNALIGNED_ACCESS_IS_FAST	1


#define restrict


#define inline		__inline
#define forceinline	__forceinline


#define bswap16	_byteswap_ushort
#define bswap32	_byteswap_ulong
#define bswap64	_byteswap_uint64



static forceinline unsigned
bsr32(uint32_t n)
{
	_BitScanReverse(&n, n);
	return n;
}
#define bsr32 bsr32

static forceinline unsigned
bsf32(uint32_t n)
{
	_BitScanForward(&n, n);
	return n;
}
#define bsf32 bsf32

#ifdef _M_X64 

static forceinline unsigned
bsr64(uint64_t n)
{
	_BitScanReverse64(&n, n);
	return n;
}
#define bsr64 bsr64

static forceinline unsigned
bsf64(uint64_t n)
{
	_BitScanForward64(&n, n);
	return n;
}
#define bsf64 bsf64

#endif 

#else
#  pragma message("Unrecognized compiler.  Please add a header file for your compiler.  Compilation will proceed, but performance may suffer!")
#endif





#include <stddef.h> 

#ifndef __bool_true_false_are_defined
#  include <stdbool.h> 
#endif


#include <stdint.h>
typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
typedef int8_t s8;
typedef int16_t s16;
typedef int32_t s32;
typedef int64_t s64;


typedef size_t machine_word_t;


#define WORDBYTES	((int)sizeof(machine_word_t))


#define WORDBITS	(8 * WORDBYTES)






#ifndef LIBEXPORT
#  define LIBEXPORT
#endif


#ifndef inline
#  define inline
#endif


#ifndef forceinline
#  define forceinline inline
#endif


#ifndef restrict
#  define restrict
#endif


#ifndef likely
#  define likely(expr)		(expr)
#endif


#ifndef unlikely
#  define unlikely(expr)	(expr)
#endif


#ifndef prefetchr
#  define prefetchr(addr)
#endif


#ifndef prefetchw
#  define prefetchw(addr)
#endif


#ifndef COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE
#  define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE 0
#endif


#ifndef COMPILER_SUPPORTS_BMI2_TARGET
#  define COMPILER_SUPPORTS_BMI2_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX_TARGET
#  define COMPILER_SUPPORTS_AVX_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET
#  define COMPILER_SUPPORTS_AVX512BW_TARGET 0
#endif


#ifndef COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 0
#endif


#ifndef _aligned_attribute
#endif





#define ARRAY_LEN(A)		(sizeof(A) / sizeof((A)[0]))
#define MIN(a, b)		((a) <= (b) ? (a) : (b))
#define MAX(a, b)		((a) >= (b) ? (a) : (b))
#define DIV_ROUND_UP(n, d)	(((n) + (d) - 1) / (d))
#define STATIC_ASSERT(expr)	((void)sizeof(char[1 - 2 * !(expr)]))
#define ALIGN(n, a)		(((n) + (a) - 1) & ~((a) - 1))






#ifndef CPU_IS_LITTLE_ENDIAN
static forceinline int CPU_IS_LITTLE_ENDIAN(void)
{
	union {
		unsigned int v;
		unsigned char b;
	} u;
	u.v = 1;
	return u.b;
}
#endif


#ifndef bswap16
static forceinline u16 bswap16(u16 n)
{
	return (n << 8) | (n >> 8);
}
#endif


#ifndef bswap32
static forceinline u32 bswap32(u32 n)
{
	return ((n & 0x000000FF) << 24) |
	       ((n & 0x0000FF00) << 8) |
	       ((n & 0x00FF0000) >> 8) |
	       ((n & 0xFF000000) >> 24);
}
#endif


#ifndef bswap64
static forceinline u64 bswap64(u64 n)
{
	return ((n & 0x00000000000000FF) << 56) |
	       ((n & 0x000000000000FF00) << 40) |
	       ((n & 0x0000000000FF0000) << 24) |
	       ((n & 0x00000000FF000000) << 8) |
	       ((n & 0x000000FF00000000) >> 8) |
	       ((n & 0x0000FF0000000000) >> 24) |
	       ((n & 0x00FF000000000000) >> 40) |
	       ((n & 0xFF00000000000000) >> 56);
}
#endif

#define le16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap16(n))
#define le32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap32(n))
#define le64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap64(n))
#define be16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap16(n) : (n))
#define be32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap32(n) : (n))
#define be64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap64(n) : (n))






#ifndef UNALIGNED_ACCESS_IS_FAST
#  define UNALIGNED_ACCESS_IS_FAST 0
#endif







#ifndef bsr32
static forceinline unsigned
bsr32(u32 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

#ifndef bsr64
static forceinline unsigned
bsr64(u64 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

static forceinline unsigned
bsrw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsr32(n);
	else
		return bsr64(n);
}



#ifndef bsf32
static forceinline unsigned
bsf32(u32 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

#ifndef bsf64
static forceinline unsigned
bsf64(u64 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

static forceinline unsigned
bsfw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsf32(n);
	else
		return bsf64(n);
}

#endif 



#define SYM_FIXUP(sym)			_libdeflate_##sym
#define deflate_get_compression_level	SYM_FIXUP(deflate_get_compression_level)
#define _cpu_features			SYM_FIXUP(_cpu_features)
#define setup_cpu_features		SYM_FIXUP(setup_cpu_features)

void *libdeflate_malloc(size_t size);
void libdeflate_free(void *ptr);

void *libdeflate_aligned_malloc(size_t alignment, size_t size);
void libdeflate_aligned_free(void *ptr);

#ifdef FREESTANDING

void *memset(void *s, int c, size_t n);
#define memset(s, c, n)		__builtin_memset((s), (c), (n))

void *memcpy(void *dest, const void *src, size_t n);
#define memcpy(dest, src, n)	__builtin_memcpy((dest), (src), (n))

void *memmove(void *dest, const void *src, size_t n);
#define memmove(dest, src, n)	__builtin_memmove((dest), (src), (n))

int memcmp(const void *s1, const void *s2, size_t n);
#define memcmp(s1, s2, n)	__builtin_memcmp((s1), (s2), (n))
#else
#include <string.h>
#endif

#endif 






#define DEFINE_UNALIGNED_TYPE(type)				\
static forceinline type						\
load_##type##_unaligned(const void *p)				\
{								\
	type v;							\
	memcpy(&v, p, sizeof(v));				\
	return v;						\
}								\
								\
static forceinline void						\
store_##type##_unaligned(type v, void *p)			\
{								\
	memcpy(p, &v, sizeof(v));				\
}

DEFINE_UNALIGNED_TYPE(u16)
DEFINE_UNALIGNED_TYPE(u32)
DEFINE_UNALIGNED_TYPE(u64)
DEFINE_UNALIGNED_TYPE(machine_word_t)

#define load_word_unaligned	load_machine_word_t_unaligned
#define store_word_unaligned	store_machine_word_t_unaligned



static forceinline u16
get_unaligned_le16(const u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST)
		return le16_bswap(load_u16_unaligned(p));
	else
		return ((u16)p[1] << 8) | p[0];
}

static forceinline u16
get_unaligned_be16(const u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST)
		return be16_bswap(load_u16_unaligned(p));
	else
		return ((u16)p[0] << 8) | p[1];
}

static forceinline u32
get_unaligned_le32(const u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST)
		return le32_bswap(load_u32_unaligned(p));
	else
		return ((u32)p[3] << 24) | ((u32)p[2] << 16) |
			((u32)p[1] << 8) | p[0];
}

static forceinline u32
get_unaligned_be32(const u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST)
		return be32_bswap(load_u32_unaligned(p));
	else
		return ((u32)p[0] << 24) | ((u32)p[1] << 16) |
			((u32)p[2] << 8) | p[3];
}

static forceinline u64
get_unaligned_le64(const u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST)
		return le64_bswap(load_u64_unaligned(p));
	else
		return ((u64)p[7] << 56) | ((u64)p[6] << 48) |
			((u64)p[5] << 40) | ((u64)p[4] << 32) |
			((u64)p[3] << 24) | ((u64)p[2] << 16) |
			((u64)p[1] << 8) | p[0];
}

static forceinline machine_word_t
get_unaligned_leword(const u8 *p)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return get_unaligned_le32(p);
	else
		return get_unaligned_le64(p);
}



static forceinline void
put_unaligned_le16(u16 v, u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST) {
		store_u16_unaligned(le16_bswap(v), p);
	} else {
		p[0] = (u8)(v >> 0);
		p[1] = (u8)(v >> 8);
	}
}

static forceinline void
put_unaligned_be16(u16 v, u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST) {
		store_u16_unaligned(be16_bswap(v), p);
	} else {
		p[0] = (u8)(v >> 8);
		p[1] = (u8)(v >> 0);
	}
}

static forceinline void
put_unaligned_le32(u32 v, u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST) {
		store_u32_unaligned(le32_bswap(v), p);
	} else {
		p[0] = (u8)(v >> 0);
		p[1] = (u8)(v >> 8);
		p[2] = (u8)(v >> 16);
		p[3] = (u8)(v >> 24);
	}
}

static forceinline void
put_unaligned_be32(u32 v, u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST) {
		store_u32_unaligned(be32_bswap(v), p);
	} else {
		p[0] = (u8)(v >> 24);
		p[1] = (u8)(v >> 16);
		p[2] = (u8)(v >> 8);
		p[3] = (u8)(v >> 0);
	}
}

static forceinline void
put_unaligned_le64(u64 v, u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST) {
		store_u64_unaligned(le64_bswap(v), p);
	} else {
		p[0] = (u8)(v >> 0);
		p[1] = (u8)(v >> 8);
		p[2] = (u8)(v >> 16);
		p[3] = (u8)(v >> 24);
		p[4] = (u8)(v >> 32);
		p[5] = (u8)(v >> 40);
		p[6] = (u8)(v >> 48);
		p[7] = (u8)(v >> 56);
	}
}

static forceinline void
put_unaligned_leword(machine_word_t v, u8 *p)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		put_unaligned_le32(v, p);
	else
		put_unaligned_le64(v, p);
}




static forceinline u32
loaded_u32_to_u24(u32 v)
{
	if (CPU_IS_LITTLE_ENDIAN())
		return v & 0xFFFFFF;
	else
		return v >> 8;
}


static forceinline u32
load_u24_unaligned(const u8 *p)
{
#if UNALIGNED_ACCESS_IS_FAST
#  define LOAD_U24_REQUIRED_NBYTES 4
	return loaded_u32_to_u24(load_u32_unaligned(p));
#else
#  define LOAD_U24_REQUIRED_NBYTES 3
	if (CPU_IS_LITTLE_ENDIAN())
		return ((u32)p[0] << 0) | ((u32)p[1] << 8) | ((u32)p[2] << 16);
	else
		return ((u32)p[2] << 0) | ((u32)p[1] << 8) | ((u32)p[0] << 16);
#endif
}

#endif 


/* #include "libdeflate.h" */


#ifndef LIBDEFLATE_H
#define LIBDEFLATE_H

#ifdef __cplusplus
extern "C" {
#endif

#define LIBDEFLATE_VERSION_MAJOR	1
#define LIBDEFLATE_VERSION_MINOR	7
#define LIBDEFLATE_VERSION_STRING	"1.7"

#include <stddef.h>
#include <stdint.h>


#ifdef LIBDEFLATE_DLL
#  ifdef BUILDING_LIBDEFLATE
#    define LIBDEFLATEEXPORT	LIBEXPORT
#  elif defined(_WIN32) || defined(__CYGWIN__)
#    define LIBDEFLATEEXPORT	__declspec(dllimport)
#  endif
#endif
#ifndef LIBDEFLATEEXPORT
#  define LIBDEFLATEEXPORT
#endif

#if defined(_WIN32) && !defined(_WIN64)
#  define LIBDEFLATEAPI_ABI	__stdcall
#else
#  define LIBDEFLATEAPI_ABI
#endif

#if defined(BUILDING_LIBDEFLATE) && defined(__GNUC__) && \
	defined(_WIN32) && !defined(_WIN64)
    
#  define LIBDEFLATEAPI_STACKALIGN	__attribute__((force_align_arg_pointer))
#else
#  define LIBDEFLATEAPI_STACKALIGN
#endif

#define LIBDEFLATEAPI	LIBDEFLATEAPI_ABI LIBDEFLATEAPI_STACKALIGN





struct libdeflate_compressor;


LIBDEFLATEEXPORT struct libdeflate_compressor * LIBDEFLATEAPI
libdeflate_alloc_compressor(int compression_level);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_deflate_compress(struct libdeflate_compressor *compressor,
			    const void *in, size_t in_nbytes,
			    void *out, size_t out_nbytes_avail);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_deflate_compress_bound(struct libdeflate_compressor *compressor,
				  size_t in_nbytes);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_zlib_compress(struct libdeflate_compressor *compressor,
			 const void *in, size_t in_nbytes,
			 void *out, size_t out_nbytes_avail);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_zlib_compress_bound(struct libdeflate_compressor *compressor,
			       size_t in_nbytes);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_gzip_compress(struct libdeflate_compressor *compressor,
			 const void *in, size_t in_nbytes,
			 void *out, size_t out_nbytes_avail);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_gzip_compress_bound(struct libdeflate_compressor *compressor,
			       size_t in_nbytes);


LIBDEFLATEEXPORT void LIBDEFLATEAPI
libdeflate_free_compressor(struct libdeflate_compressor *compressor);





struct libdeflate_decompressor;


LIBDEFLATEEXPORT struct libdeflate_decompressor * LIBDEFLATEAPI
libdeflate_alloc_decompressor(void);


enum libdeflate_result {
	
	LIBDEFLATE_SUCCESS = 0,

	
	LIBDEFLATE_BAD_DATA = 1,

	
	LIBDEFLATE_SHORT_OUTPUT = 2,

	
	LIBDEFLATE_INSUFFICIENT_SPACE = 3,
};


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_deflate_decompress(struct libdeflate_decompressor *decompressor,
			      const void *in, size_t in_nbytes,
			      void *out, size_t out_nbytes_avail,
			      size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_deflate_decompress_ex(struct libdeflate_decompressor *decompressor,
				 const void *in, size_t in_nbytes,
				 void *out, size_t out_nbytes_avail,
				 size_t *actual_in_nbytes_ret,
				 size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_zlib_decompress(struct libdeflate_decompressor *decompressor,
			   const void *in, size_t in_nbytes,
			   void *out, size_t out_nbytes_avail,
			   size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_zlib_decompress_ex(struct libdeflate_decompressor *decompressor,
			      const void *in, size_t in_nbytes,
			      void *out, size_t out_nbytes_avail,
			      size_t *actual_in_nbytes_ret,
			      size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_gzip_decompress(struct libdeflate_decompressor *decompressor,
			   const void *in, size_t in_nbytes,
			   void *out, size_t out_nbytes_avail,
			   size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_gzip_decompress_ex(struct libdeflate_decompressor *decompressor,
			      const void *in, size_t in_nbytes,
			      void *out, size_t out_nbytes_avail,
			      size_t *actual_in_nbytes_ret,
			      size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT void LIBDEFLATEAPI
libdeflate_free_decompressor(struct libdeflate_decompressor *decompressor);






LIBDEFLATEEXPORT uint32_t LIBDEFLATEAPI
libdeflate_adler32(uint32_t adler, const void *buffer, size_t len);



LIBDEFLATEEXPORT uint32_t LIBDEFLATEAPI
libdeflate_crc32(uint32_t crc, const void *buffer, size_t len);






LIBDEFLATEEXPORT void LIBDEFLATEAPI
libdeflate_set_memory_allocator(void *(*malloc_func)(size_t),
				void (*free_func)(void *));

#ifdef __cplusplus
}
#endif

#endif 


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_gzip_compress(struct libdeflate_compressor *c,
			 const void *in, size_t in_nbytes,
			 void *out, size_t out_nbytes_avail)
{
	u8 *out_next = out;
	unsigned compression_level;
	u8 xfl;
	size_t deflate_size;

	if (out_nbytes_avail <= GZIP_MIN_OVERHEAD)
		return 0;

	
	*out_next++ = GZIP_ID1;
	
	*out_next++ = GZIP_ID2;
	
	*out_next++ = GZIP_CM_DEFLATE;
	
	*out_next++ = 0;
	
	put_unaligned_le32(GZIP_MTIME_UNAVAILABLE, out_next);
	out_next += 4;
	
	xfl = 0;
	compression_level = deflate_get_compression_level(c);
	if (compression_level < 2)
		xfl |= GZIP_XFL_FASTEST_COMPRESSION;
	else if (compression_level >= 8)
		xfl |= GZIP_XFL_SLOWEST_COMPRESSION;
	*out_next++ = xfl;
	
	*out_next++ = GZIP_OS_UNKNOWN;	

	
	deflate_size = libdeflate_deflate_compress(c, in, in_nbytes, out_next,
					out_nbytes_avail - GZIP_MIN_OVERHEAD);
	if (deflate_size == 0)
		return 0;
	out_next += deflate_size;

	
	put_unaligned_le32(libdeflate_crc32(0, in, in_nbytes), out_next);
	out_next += 4;

	
	put_unaligned_le32((u32)in_nbytes, out_next);
	out_next += 4;

	return out_next - (u8 *)out;
}

LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_gzip_compress_bound(struct libdeflate_compressor *c,
			       size_t in_nbytes)
{
	return GZIP_MIN_OVERHEAD +
	       libdeflate_deflate_compress_bound(c, in_nbytes);
}
/* /usr/home/ben/projects/gzip-libdeflate/../../software/libdeflate-1.7/lib/gzip_decompress.c */


/* #include "gzip_constants.h" */


#ifndef LIB_GZIP_CONSTANTS_H
#define LIB_GZIP_CONSTANTS_H

#define GZIP_MIN_HEADER_SIZE	10
#define GZIP_FOOTER_SIZE	8
#define GZIP_MIN_OVERHEAD	(GZIP_MIN_HEADER_SIZE + GZIP_FOOTER_SIZE)

#define GZIP_ID1		0x1F
#define GZIP_ID2		0x8B

#define GZIP_CM_DEFLATE		8

#define GZIP_FTEXT		0x01
#define GZIP_FHCRC		0x02
#define GZIP_FEXTRA		0x04
#define GZIP_FNAME		0x08
#define GZIP_FCOMMENT		0x10
#define GZIP_FRESERVED		0xE0

#define GZIP_MTIME_UNAVAILABLE	0

#define GZIP_XFL_SLOWEST_COMPRESSION	0x02
#define GZIP_XFL_FASTEST_COMPRESSION	0x04

#define GZIP_OS_FAT		0
#define GZIP_OS_AMIGA		1
#define GZIP_OS_VMS		2
#define GZIP_OS_UNIX		3
#define GZIP_OS_VM_CMS		4
#define GZIP_OS_ATARI_TOS	5
#define GZIP_OS_HPFS		6
#define GZIP_OS_MACINTOSH	7
#define GZIP_OS_Z_SYSTEM	8
#define GZIP_OS_CP_M		9
#define GZIP_OS_TOPS_20		10
#define GZIP_OS_NTFS		11
#define GZIP_OS_QDOS		12
#define GZIP_OS_RISCOS		13
#define GZIP_OS_UNKNOWN		255

#endif 

/* #include "unaligned.h" */


#ifndef LIB_UNALIGNED_H
#define LIB_UNALIGNED_H

/* #include "lib_common.h" */


#ifndef LIB_LIB_COMMON_H
#define LIB_LIB_COMMON_H

#ifdef LIBDEFLATE_H
#  error "lib_common.h must always be included before libdeflate.h"
   
#endif

#define BUILDING_LIBDEFLATE

/* #include "../common/common_defs.h" */


#ifndef COMMON_COMMON_DEFS_H
#define COMMON_COMMON_DEFS_H

#ifdef __GNUC__
/* #  include "compiler_gcc.h" */


#if !defined(__clang__) && !defined(__INTEL_COMPILER)
#  define GCC_PREREQ(major, minor)		\
	(__GNUC__ > (major) ||			\
	 (__GNUC__ == (major) && __GNUC_MINOR__ >= (minor)))
#else
#  define GCC_PREREQ(major, minor)	0
#endif


#ifdef __clang__
#  ifdef __apple_build_version__
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__apple_build_version__ >= (apple_version))
#  else
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__clang_major__ > (major) ||			\
	 (__clang_major__ == (major) && __clang_minor__ >= (minor)))
#  endif
#else
#  define CLANG_PREREQ(major, minor, apple_version)	0
#endif

#ifndef __has_attribute
#  define __has_attribute(attribute)	0
#endif
#ifndef __has_feature
#  define __has_feature(feature)	0
#endif
#ifndef __has_builtin
#  define __has_builtin(builtin)	0
#endif

#ifdef _WIN32
#  define LIBEXPORT __declspec(dllexport)
#else
#  define LIBEXPORT __attribute__((visibility("default")))
#endif

#define inline			inline
#define forceinline		inline __attribute__((always_inline))
#define restrict		__restrict__
#define likely(expr)		__builtin_expect(!!(expr), 1)
#define unlikely(expr)		__builtin_expect(!!(expr), 0)
#define prefetchr(addr)		__builtin_prefetch((addr), 0)
#define prefetchw(addr)		__builtin_prefetch((addr), 1)
#define _aligned_attribute(n)	__attribute__((aligned(n)))

#define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE	\
	(GCC_PREREQ(4, 4) || __has_attribute(target))

#if COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE

#  if defined(__i386__) || defined(__x86_64__)

#    define COMPILER_SUPPORTS_PCLMUL_TARGET	\
	(GCC_PREREQ(4, 4) || __has_builtin(__builtin_ia32_pclmulqdq128))

#    define COMPILER_SUPPORTS_AVX_TARGET	\
	(GCC_PREREQ(4, 6) || __has_builtin(__builtin_ia32_maxps256))

#    define COMPILER_SUPPORTS_BMI2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_pdep_di))

#    define COMPILER_SUPPORTS_AVX2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_psadbw256))

#    define COMPILER_SUPPORTS_AVX512BW_TARGET	\
	(GCC_PREREQ(5, 1) || __has_builtin(__builtin_ia32_psadbw512))

	
#    if GCC_PREREQ(4, 9) || CLANG_PREREQ(3, 8, 7030000)
#      define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS	1
#      define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_PCLMUL_TARGET
#      define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX2_TARGET
#      define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX512BW_TARGET
#    endif

#  elif defined(__arm__) || defined(__aarch64__)

    
#    if (GCC_PREREQ(6, 1) && defined(__ARM_FP)) || \
        (defined(__clang__) && defined(__ARM_NEON))
#      define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 1
       
#      if defined(__clang__) && defined(__arm__)
#        undef __ARM_FEATURE_CRYPTO
#      elif __has_builtin(__builtin_neon_vmull_p64) || !defined(__clang__)
#        define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 1
#      endif
#    endif

     
#    if GCC_PREREQ(10, 1) || \
        (GCC_PREREQ(9, 3) && !GCC_PREREQ(10, 0)) || \
        (GCC_PREREQ(8, 4) && !GCC_PREREQ(9, 0)) || \
        (defined(__clang__) && __has_builtin(__builtin_arm_crc32b))
#      define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 1
#    endif

#  endif 

#endif 


#if (GCC_PREREQ(4, 0) && !GCC_PREREQ(5, 1)) || \
    (defined(__clang__) && !CLANG_PREREQ(3, 9, 8020000))
typedef unsigned long long  __v2du __attribute__((__vector_size__(16)));
typedef unsigned int        __v4su __attribute__((__vector_size__(16)));
typedef unsigned short      __v8hu __attribute__((__vector_size__(16)));
typedef unsigned char      __v16qu __attribute__((__vector_size__(16)));
typedef unsigned long long  __v4du __attribute__((__vector_size__(32)));
typedef unsigned int        __v8su __attribute__((__vector_size__(32)));
typedef unsigned short     __v16hu __attribute__((__vector_size__(32)));
typedef unsigned char      __v32qu __attribute__((__vector_size__(32)));
#endif


#ifdef __BYTE_ORDER__
#  define CPU_IS_LITTLE_ENDIAN() (__BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__)
#endif

#if GCC_PREREQ(4, 8) || __has_builtin(__builtin_bswap16)
#  define bswap16	__builtin_bswap16
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap32)
#  define bswap32	__builtin_bswap32
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap64)
#  define bswap64	__builtin_bswap64
#endif

#if defined(__x86_64__) || defined(__i386__) || defined(__ARM_FEATURE_UNALIGNED) || defined(__powerpc64__)
#  define UNALIGNED_ACCESS_IS_FAST 1
#endif

#define bsr32(n)	(31 - __builtin_clz(n))
#define bsr64(n)	(63 - __builtin_clzll(n))
#define bsf32(n)	__builtin_ctz(n)
#define bsf64(n)	__builtin_ctzll(n)

#elif defined(_MSC_VER)
/* #  include "compiler_msc.h" */


#include <stdint.h>
#include <stdlib.h> 

#define LIBEXPORT	__declspec(dllexport)


typedef int bool;
#define true 1
#define false 0
#define __bool_true_false_are_defined 1


#ifdef _WIN64
typedef long long ssize_t;
#else
typedef int ssize_t;
#endif


#define CPU_IS_LITTLE_ENDIAN()		1
#define UNALIGNED_ACCESS_IS_FAST	1


#define restrict


#define inline		__inline
#define forceinline	__forceinline


#define bswap16	_byteswap_ushort
#define bswap32	_byteswap_ulong
#define bswap64	_byteswap_uint64



static forceinline unsigned
bsr32(uint32_t n)
{
	_BitScanReverse(&n, n);
	return n;
}
#define bsr32 bsr32

static forceinline unsigned
bsf32(uint32_t n)
{
	_BitScanForward(&n, n);
	return n;
}
#define bsf32 bsf32

#ifdef _M_X64 

static forceinline unsigned
bsr64(uint64_t n)
{
	_BitScanReverse64(&n, n);
	return n;
}
#define bsr64 bsr64

static forceinline unsigned
bsf64(uint64_t n)
{
	_BitScanForward64(&n, n);
	return n;
}
#define bsf64 bsf64

#endif 

#else
#  pragma message("Unrecognized compiler.  Please add a header file for your compiler.  Compilation will proceed, but performance may suffer!")
#endif





#include <stddef.h> 

#ifndef __bool_true_false_are_defined
#  include <stdbool.h> 
#endif


#include <stdint.h>
typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
typedef int8_t s8;
typedef int16_t s16;
typedef int32_t s32;
typedef int64_t s64;


typedef size_t machine_word_t;


#define WORDBYTES	((int)sizeof(machine_word_t))


#define WORDBITS	(8 * WORDBYTES)






#ifndef LIBEXPORT
#  define LIBEXPORT
#endif


#ifndef inline
#  define inline
#endif


#ifndef forceinline
#  define forceinline inline
#endif


#ifndef restrict
#  define restrict
#endif


#ifndef likely
#  define likely(expr)		(expr)
#endif


#ifndef unlikely
#  define unlikely(expr)	(expr)
#endif


#ifndef prefetchr
#  define prefetchr(addr)
#endif


#ifndef prefetchw
#  define prefetchw(addr)
#endif


#ifndef COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE
#  define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE 0
#endif


#ifndef COMPILER_SUPPORTS_BMI2_TARGET
#  define COMPILER_SUPPORTS_BMI2_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX_TARGET
#  define COMPILER_SUPPORTS_AVX_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET
#  define COMPILER_SUPPORTS_AVX512BW_TARGET 0
#endif


#ifndef COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 0
#endif


#ifndef _aligned_attribute
#endif





#define ARRAY_LEN(A)		(sizeof(A) / sizeof((A)[0]))
#define MIN(a, b)		((a) <= (b) ? (a) : (b))
#define MAX(a, b)		((a) >= (b) ? (a) : (b))
#define DIV_ROUND_UP(n, d)	(((n) + (d) - 1) / (d))
#define STATIC_ASSERT(expr)	((void)sizeof(char[1 - 2 * !(expr)]))
#define ALIGN(n, a)		(((n) + (a) - 1) & ~((a) - 1))






#ifndef CPU_IS_LITTLE_ENDIAN
static forceinline int CPU_IS_LITTLE_ENDIAN(void)
{
	union {
		unsigned int v;
		unsigned char b;
	} u;
	u.v = 1;
	return u.b;
}
#endif


#ifndef bswap16
static forceinline u16 bswap16(u16 n)
{
	return (n << 8) | (n >> 8);
}
#endif


#ifndef bswap32
static forceinline u32 bswap32(u32 n)
{
	return ((n & 0x000000FF) << 24) |
	       ((n & 0x0000FF00) << 8) |
	       ((n & 0x00FF0000) >> 8) |
	       ((n & 0xFF000000) >> 24);
}
#endif


#ifndef bswap64
static forceinline u64 bswap64(u64 n)
{
	return ((n & 0x00000000000000FF) << 56) |
	       ((n & 0x000000000000FF00) << 40) |
	       ((n & 0x0000000000FF0000) << 24) |
	       ((n & 0x00000000FF000000) << 8) |
	       ((n & 0x000000FF00000000) >> 8) |
	       ((n & 0x0000FF0000000000) >> 24) |
	       ((n & 0x00FF000000000000) >> 40) |
	       ((n & 0xFF00000000000000) >> 56);
}
#endif

#define le16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap16(n))
#define le32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap32(n))
#define le64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap64(n))
#define be16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap16(n) : (n))
#define be32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap32(n) : (n))
#define be64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap64(n) : (n))






#ifndef UNALIGNED_ACCESS_IS_FAST
#  define UNALIGNED_ACCESS_IS_FAST 0
#endif







#ifndef bsr32
static forceinline unsigned
bsr32(u32 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

#ifndef bsr64
static forceinline unsigned
bsr64(u64 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

static forceinline unsigned
bsrw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsr32(n);
	else
		return bsr64(n);
}



#ifndef bsf32
static forceinline unsigned
bsf32(u32 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

#ifndef bsf64
static forceinline unsigned
bsf64(u64 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

static forceinline unsigned
bsfw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsf32(n);
	else
		return bsf64(n);
}

#endif 



#define SYM_FIXUP(sym)			_libdeflate_##sym
#define deflate_get_compression_level	SYM_FIXUP(deflate_get_compression_level)
#define _cpu_features			SYM_FIXUP(_cpu_features)
#define setup_cpu_features		SYM_FIXUP(setup_cpu_features)

void *libdeflate_malloc(size_t size);
void libdeflate_free(void *ptr);

void *libdeflate_aligned_malloc(size_t alignment, size_t size);
void libdeflate_aligned_free(void *ptr);

#ifdef FREESTANDING

void *memset(void *s, int c, size_t n);
#define memset(s, c, n)		__builtin_memset((s), (c), (n))

void *memcpy(void *dest, const void *src, size_t n);
#define memcpy(dest, src, n)	__builtin_memcpy((dest), (src), (n))

void *memmove(void *dest, const void *src, size_t n);
#define memmove(dest, src, n)	__builtin_memmove((dest), (src), (n))

int memcmp(const void *s1, const void *s2, size_t n);
#define memcmp(s1, s2, n)	__builtin_memcmp((s1), (s2), (n))
#else
#include <string.h>
#endif

#endif 






#define DEFINE_UNALIGNED_TYPE(type)				\
static forceinline type						\
load_##type##_unaligned(const void *p)				\
{								\
	type v;							\
	memcpy(&v, p, sizeof(v));				\
	return v;						\
}								\
								\
static forceinline void						\
store_##type##_unaligned(type v, void *p)			\
{								\
	memcpy(p, &v, sizeof(v));				\
}

DEFINE_UNALIGNED_TYPE(u16)
DEFINE_UNALIGNED_TYPE(u32)
DEFINE_UNALIGNED_TYPE(u64)
DEFINE_UNALIGNED_TYPE(machine_word_t)

#define load_word_unaligned	load_machine_word_t_unaligned
#define store_word_unaligned	store_machine_word_t_unaligned



static forceinline u16
get_unaligned_le16(const u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST)
		return le16_bswap(load_u16_unaligned(p));
	else
		return ((u16)p[1] << 8) | p[0];
}

static forceinline u16
get_unaligned_be16(const u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST)
		return be16_bswap(load_u16_unaligned(p));
	else
		return ((u16)p[0] << 8) | p[1];
}

static forceinline u32
get_unaligned_le32(const u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST)
		return le32_bswap(load_u32_unaligned(p));
	else
		return ((u32)p[3] << 24) | ((u32)p[2] << 16) |
			((u32)p[1] << 8) | p[0];
}

static forceinline u32
get_unaligned_be32(const u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST)
		return be32_bswap(load_u32_unaligned(p));
	else
		return ((u32)p[0] << 24) | ((u32)p[1] << 16) |
			((u32)p[2] << 8) | p[3];
}

static forceinline u64
get_unaligned_le64(const u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST)
		return le64_bswap(load_u64_unaligned(p));
	else
		return ((u64)p[7] << 56) | ((u64)p[6] << 48) |
			((u64)p[5] << 40) | ((u64)p[4] << 32) |
			((u64)p[3] << 24) | ((u64)p[2] << 16) |
			((u64)p[1] << 8) | p[0];
}

static forceinline machine_word_t
get_unaligned_leword(const u8 *p)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return get_unaligned_le32(p);
	else
		return get_unaligned_le64(p);
}



static forceinline void
put_unaligned_le16(u16 v, u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST) {
		store_u16_unaligned(le16_bswap(v), p);
	} else {
		p[0] = (u8)(v >> 0);
		p[1] = (u8)(v >> 8);
	}
}

static forceinline void
put_unaligned_be16(u16 v, u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST) {
		store_u16_unaligned(be16_bswap(v), p);
	} else {
		p[0] = (u8)(v >> 8);
		p[1] = (u8)(v >> 0);
	}
}

static forceinline void
put_unaligned_le32(u32 v, u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST) {
		store_u32_unaligned(le32_bswap(v), p);
	} else {
		p[0] = (u8)(v >> 0);
		p[1] = (u8)(v >> 8);
		p[2] = (u8)(v >> 16);
		p[3] = (u8)(v >> 24);
	}
}

static forceinline void
put_unaligned_be32(u32 v, u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST) {
		store_u32_unaligned(be32_bswap(v), p);
	} else {
		p[0] = (u8)(v >> 24);
		p[1] = (u8)(v >> 16);
		p[2] = (u8)(v >> 8);
		p[3] = (u8)(v >> 0);
	}
}

static forceinline void
put_unaligned_le64(u64 v, u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST) {
		store_u64_unaligned(le64_bswap(v), p);
	} else {
		p[0] = (u8)(v >> 0);
		p[1] = (u8)(v >> 8);
		p[2] = (u8)(v >> 16);
		p[3] = (u8)(v >> 24);
		p[4] = (u8)(v >> 32);
		p[5] = (u8)(v >> 40);
		p[6] = (u8)(v >> 48);
		p[7] = (u8)(v >> 56);
	}
}

static forceinline void
put_unaligned_leword(machine_word_t v, u8 *p)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		put_unaligned_le32(v, p);
	else
		put_unaligned_le64(v, p);
}




static forceinline u32
loaded_u32_to_u24(u32 v)
{
	if (CPU_IS_LITTLE_ENDIAN())
		return v & 0xFFFFFF;
	else
		return v >> 8;
}


static forceinline u32
load_u24_unaligned(const u8 *p)
{
#if UNALIGNED_ACCESS_IS_FAST
#  define LOAD_U24_REQUIRED_NBYTES 4
	return loaded_u32_to_u24(load_u32_unaligned(p));
#else
#  define LOAD_U24_REQUIRED_NBYTES 3
	if (CPU_IS_LITTLE_ENDIAN())
		return ((u32)p[0] << 0) | ((u32)p[1] << 8) | ((u32)p[2] << 16);
	else
		return ((u32)p[2] << 0) | ((u32)p[1] << 8) | ((u32)p[0] << 16);
#endif
}

#endif 


/* #include "libdeflate.h" */


#ifndef LIBDEFLATE_H
#define LIBDEFLATE_H

#ifdef __cplusplus
extern "C" {
#endif

#define LIBDEFLATE_VERSION_MAJOR	1
#define LIBDEFLATE_VERSION_MINOR	7
#define LIBDEFLATE_VERSION_STRING	"1.7"

#include <stddef.h>
#include <stdint.h>


#ifdef LIBDEFLATE_DLL
#  ifdef BUILDING_LIBDEFLATE
#    define LIBDEFLATEEXPORT	LIBEXPORT
#  elif defined(_WIN32) || defined(__CYGWIN__)
#    define LIBDEFLATEEXPORT	__declspec(dllimport)
#  endif
#endif
#ifndef LIBDEFLATEEXPORT
#  define LIBDEFLATEEXPORT
#endif

#if defined(_WIN32) && !defined(_WIN64)
#  define LIBDEFLATEAPI_ABI	__stdcall
#else
#  define LIBDEFLATEAPI_ABI
#endif

#if defined(BUILDING_LIBDEFLATE) && defined(__GNUC__) && \
	defined(_WIN32) && !defined(_WIN64)
    
#  define LIBDEFLATEAPI_STACKALIGN	__attribute__((force_align_arg_pointer))
#else
#  define LIBDEFLATEAPI_STACKALIGN
#endif

#define LIBDEFLATEAPI	LIBDEFLATEAPI_ABI LIBDEFLATEAPI_STACKALIGN





struct libdeflate_compressor;


LIBDEFLATEEXPORT struct libdeflate_compressor * LIBDEFLATEAPI
libdeflate_alloc_compressor(int compression_level);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_deflate_compress(struct libdeflate_compressor *compressor,
			    const void *in, size_t in_nbytes,
			    void *out, size_t out_nbytes_avail);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_deflate_compress_bound(struct libdeflate_compressor *compressor,
				  size_t in_nbytes);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_zlib_compress(struct libdeflate_compressor *compressor,
			 const void *in, size_t in_nbytes,
			 void *out, size_t out_nbytes_avail);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_zlib_compress_bound(struct libdeflate_compressor *compressor,
			       size_t in_nbytes);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_gzip_compress(struct libdeflate_compressor *compressor,
			 const void *in, size_t in_nbytes,
			 void *out, size_t out_nbytes_avail);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_gzip_compress_bound(struct libdeflate_compressor *compressor,
			       size_t in_nbytes);


LIBDEFLATEEXPORT void LIBDEFLATEAPI
libdeflate_free_compressor(struct libdeflate_compressor *compressor);





struct libdeflate_decompressor;


LIBDEFLATEEXPORT struct libdeflate_decompressor * LIBDEFLATEAPI
libdeflate_alloc_decompressor(void);


enum libdeflate_result {
	
	LIBDEFLATE_SUCCESS = 0,

	
	LIBDEFLATE_BAD_DATA = 1,

	
	LIBDEFLATE_SHORT_OUTPUT = 2,

	
	LIBDEFLATE_INSUFFICIENT_SPACE = 3,
};


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_deflate_decompress(struct libdeflate_decompressor *decompressor,
			      const void *in, size_t in_nbytes,
			      void *out, size_t out_nbytes_avail,
			      size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_deflate_decompress_ex(struct libdeflate_decompressor *decompressor,
				 const void *in, size_t in_nbytes,
				 void *out, size_t out_nbytes_avail,
				 size_t *actual_in_nbytes_ret,
				 size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_zlib_decompress(struct libdeflate_decompressor *decompressor,
			   const void *in, size_t in_nbytes,
			   void *out, size_t out_nbytes_avail,
			   size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_zlib_decompress_ex(struct libdeflate_decompressor *decompressor,
			      const void *in, size_t in_nbytes,
			      void *out, size_t out_nbytes_avail,
			      size_t *actual_in_nbytes_ret,
			      size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_gzip_decompress(struct libdeflate_decompressor *decompressor,
			   const void *in, size_t in_nbytes,
			   void *out, size_t out_nbytes_avail,
			   size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_gzip_decompress_ex(struct libdeflate_decompressor *decompressor,
			      const void *in, size_t in_nbytes,
			      void *out, size_t out_nbytes_avail,
			      size_t *actual_in_nbytes_ret,
			      size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT void LIBDEFLATEAPI
libdeflate_free_decompressor(struct libdeflate_decompressor *decompressor);






LIBDEFLATEEXPORT uint32_t LIBDEFLATEAPI
libdeflate_adler32(uint32_t adler, const void *buffer, size_t len);



LIBDEFLATEEXPORT uint32_t LIBDEFLATEAPI
libdeflate_crc32(uint32_t crc, const void *buffer, size_t len);






LIBDEFLATEEXPORT void LIBDEFLATEAPI
libdeflate_set_memory_allocator(void *(*malloc_func)(size_t),
				void (*free_func)(void *));

#ifdef __cplusplus
}
#endif

#endif 


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_gzip_decompress_ex(struct libdeflate_decompressor *d,
			      const void *in, size_t in_nbytes,
			      void *out, size_t out_nbytes_avail,
			      size_t *actual_in_nbytes_ret,
			      size_t *actual_out_nbytes_ret)
{
	const u8 *in_next = in;
	const u8 * const in_end = in_next + in_nbytes;
	u8 flg;
	size_t actual_in_nbytes;
	size_t actual_out_nbytes;
	enum libdeflate_result result;

	if (in_nbytes < GZIP_MIN_OVERHEAD)
		return LIBDEFLATE_BAD_DATA;

	
	if (*in_next++ != GZIP_ID1)
		return LIBDEFLATE_BAD_DATA;
	
	if (*in_next++ != GZIP_ID2)
		return LIBDEFLATE_BAD_DATA;
	
	if (*in_next++ != GZIP_CM_DEFLATE)
		return LIBDEFLATE_BAD_DATA;
	flg = *in_next++;
	
	in_next += 4;
	
	in_next += 1;
	
	in_next += 1;

	if (flg & GZIP_FRESERVED)
		return LIBDEFLATE_BAD_DATA;

	
	if (flg & GZIP_FEXTRA) {
		u16 xlen = get_unaligned_le16(in_next);
		in_next += 2;

		if (in_end - in_next < (u32)xlen + GZIP_FOOTER_SIZE)
			return LIBDEFLATE_BAD_DATA;

		in_next += xlen;
	}

	
	if (flg & GZIP_FNAME) {
		while (*in_next++ != 0 && in_next != in_end)
			;
		if (in_end - in_next < GZIP_FOOTER_SIZE)
			return LIBDEFLATE_BAD_DATA;
	}

	
	if (flg & GZIP_FCOMMENT) {
		while (*in_next++ != 0 && in_next != in_end)
			;
		if (in_end - in_next < GZIP_FOOTER_SIZE)
			return LIBDEFLATE_BAD_DATA;
	}

	
	if (flg & GZIP_FHCRC) {
		in_next += 2;
		if (in_end - in_next < GZIP_FOOTER_SIZE)
			return LIBDEFLATE_BAD_DATA;
	}

	
	result = libdeflate_deflate_decompress_ex(d, in_next,
					in_end - GZIP_FOOTER_SIZE - in_next,
					out, out_nbytes_avail,
					&actual_in_nbytes,
					actual_out_nbytes_ret);
	if (result != LIBDEFLATE_SUCCESS)
		return result;

	if (actual_out_nbytes_ret)
		actual_out_nbytes = *actual_out_nbytes_ret;
	else
		actual_out_nbytes = out_nbytes_avail;

	in_next += actual_in_nbytes;

	
	if (libdeflate_crc32(0, out, actual_out_nbytes) !=
	    get_unaligned_le32(in_next))
		return LIBDEFLATE_BAD_DATA;
	in_next += 4;

	
	if ((u32)actual_out_nbytes != get_unaligned_le32(in_next))
		return LIBDEFLATE_BAD_DATA;
	in_next += 4;

	if (actual_in_nbytes_ret)
		*actual_in_nbytes_ret = in_next - (u8 *)in;

	return LIBDEFLATE_SUCCESS;
}

LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_gzip_decompress(struct libdeflate_decompressor *d,
			   const void *in, size_t in_nbytes,
			   void *out, size_t out_nbytes_avail,
			   size_t *actual_out_nbytes_ret)
{
	return libdeflate_gzip_decompress_ex(d, in, in_nbytes,
					     out, out_nbytes_avail,
					     NULL, actual_out_nbytes_ret);
}
/* /usr/home/ben/projects/gzip-libdeflate/../../software/libdeflate-1.7/lib/utils.c */


/* #include "lib_common.h" */


#ifndef LIB_LIB_COMMON_H
#define LIB_LIB_COMMON_H

#ifdef LIBDEFLATE_H
#  error "lib_common.h must always be included before libdeflate.h"
   
#endif

#define BUILDING_LIBDEFLATE

/* #include "../common/common_defs.h" */


#ifndef COMMON_COMMON_DEFS_H
#define COMMON_COMMON_DEFS_H

#ifdef __GNUC__
/* #  include "compiler_gcc.h" */


#if !defined(__clang__) && !defined(__INTEL_COMPILER)
#  define GCC_PREREQ(major, minor)		\
	(__GNUC__ > (major) ||			\
	 (__GNUC__ == (major) && __GNUC_MINOR__ >= (minor)))
#else
#  define GCC_PREREQ(major, minor)	0
#endif


#ifdef __clang__
#  ifdef __apple_build_version__
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__apple_build_version__ >= (apple_version))
#  else
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__clang_major__ > (major) ||			\
	 (__clang_major__ == (major) && __clang_minor__ >= (minor)))
#  endif
#else
#  define CLANG_PREREQ(major, minor, apple_version)	0
#endif

#ifndef __has_attribute
#  define __has_attribute(attribute)	0
#endif
#ifndef __has_feature
#  define __has_feature(feature)	0
#endif
#ifndef __has_builtin
#  define __has_builtin(builtin)	0
#endif

#ifdef _WIN32
#  define LIBEXPORT __declspec(dllexport)
#else
#  define LIBEXPORT __attribute__((visibility("default")))
#endif

#define inline			inline
#define forceinline		inline __attribute__((always_inline))
#define restrict		__restrict__
#define likely(expr)		__builtin_expect(!!(expr), 1)
#define unlikely(expr)		__builtin_expect(!!(expr), 0)
#define prefetchr(addr)		__builtin_prefetch((addr), 0)
#define prefetchw(addr)		__builtin_prefetch((addr), 1)
#define _aligned_attribute(n)	__attribute__((aligned(n)))

#define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE	\
	(GCC_PREREQ(4, 4) || __has_attribute(target))

#if COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE

#  if defined(__i386__) || defined(__x86_64__)

#    define COMPILER_SUPPORTS_PCLMUL_TARGET	\
	(GCC_PREREQ(4, 4) || __has_builtin(__builtin_ia32_pclmulqdq128))

#    define COMPILER_SUPPORTS_AVX_TARGET	\
	(GCC_PREREQ(4, 6) || __has_builtin(__builtin_ia32_maxps256))

#    define COMPILER_SUPPORTS_BMI2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_pdep_di))

#    define COMPILER_SUPPORTS_AVX2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_psadbw256))

#    define COMPILER_SUPPORTS_AVX512BW_TARGET	\
	(GCC_PREREQ(5, 1) || __has_builtin(__builtin_ia32_psadbw512))

	
#    if GCC_PREREQ(4, 9) || CLANG_PREREQ(3, 8, 7030000)
#      define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS	1
#      define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_PCLMUL_TARGET
#      define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX2_TARGET
#      define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX512BW_TARGET
#    endif

#  elif defined(__arm__) || defined(__aarch64__)

    
#    if (GCC_PREREQ(6, 1) && defined(__ARM_FP)) || \
        (defined(__clang__) && defined(__ARM_NEON))
#      define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 1
       
#      if defined(__clang__) && defined(__arm__)
#        undef __ARM_FEATURE_CRYPTO
#      elif __has_builtin(__builtin_neon_vmull_p64) || !defined(__clang__)
#        define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 1
#      endif
#    endif

     
#    if GCC_PREREQ(10, 1) || \
        (GCC_PREREQ(9, 3) && !GCC_PREREQ(10, 0)) || \
        (GCC_PREREQ(8, 4) && !GCC_PREREQ(9, 0)) || \
        (defined(__clang__) && __has_builtin(__builtin_arm_crc32b))
#      define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 1
#    endif

#  endif 

#endif 


#if (GCC_PREREQ(4, 0) && !GCC_PREREQ(5, 1)) || \
    (defined(__clang__) && !CLANG_PREREQ(3, 9, 8020000))
typedef unsigned long long  __v2du __attribute__((__vector_size__(16)));
typedef unsigned int        __v4su __attribute__((__vector_size__(16)));
typedef unsigned short      __v8hu __attribute__((__vector_size__(16)));
typedef unsigned char      __v16qu __attribute__((__vector_size__(16)));
typedef unsigned long long  __v4du __attribute__((__vector_size__(32)));
typedef unsigned int        __v8su __attribute__((__vector_size__(32)));
typedef unsigned short     __v16hu __attribute__((__vector_size__(32)));
typedef unsigned char      __v32qu __attribute__((__vector_size__(32)));
#endif


#ifdef __BYTE_ORDER__
#  define CPU_IS_LITTLE_ENDIAN() (__BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__)
#endif

#if GCC_PREREQ(4, 8) || __has_builtin(__builtin_bswap16)
#  define bswap16	__builtin_bswap16
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap32)
#  define bswap32	__builtin_bswap32
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap64)
#  define bswap64	__builtin_bswap64
#endif

#if defined(__x86_64__) || defined(__i386__) || defined(__ARM_FEATURE_UNALIGNED) || defined(__powerpc64__)
#  define UNALIGNED_ACCESS_IS_FAST 1
#endif

#define bsr32(n)	(31 - __builtin_clz(n))
#define bsr64(n)	(63 - __builtin_clzll(n))
#define bsf32(n)	__builtin_ctz(n)
#define bsf64(n)	__builtin_ctzll(n)

#elif defined(_MSC_VER)
/* #  include "compiler_msc.h" */


#include <stdint.h>
#include <stdlib.h> 

#define LIBEXPORT	__declspec(dllexport)


typedef int bool;
#define true 1
#define false 0
#define __bool_true_false_are_defined 1


#ifdef _WIN64
typedef long long ssize_t;
#else
typedef int ssize_t;
#endif


#define CPU_IS_LITTLE_ENDIAN()		1
#define UNALIGNED_ACCESS_IS_FAST	1


#define restrict


#define inline		__inline
#define forceinline	__forceinline


#define bswap16	_byteswap_ushort
#define bswap32	_byteswap_ulong
#define bswap64	_byteswap_uint64



static forceinline unsigned
bsr32(uint32_t n)
{
	_BitScanReverse(&n, n);
	return n;
}
#define bsr32 bsr32

static forceinline unsigned
bsf32(uint32_t n)
{
	_BitScanForward(&n, n);
	return n;
}
#define bsf32 bsf32

#ifdef _M_X64 

static forceinline unsigned
bsr64(uint64_t n)
{
	_BitScanReverse64(&n, n);
	return n;
}
#define bsr64 bsr64

static forceinline unsigned
bsf64(uint64_t n)
{
	_BitScanForward64(&n, n);
	return n;
}
#define bsf64 bsf64

#endif 

#else
#  pragma message("Unrecognized compiler.  Please add a header file for your compiler.  Compilation will proceed, but performance may suffer!")
#endif





#include <stddef.h> 

#ifndef __bool_true_false_are_defined
#  include <stdbool.h> 
#endif


#include <stdint.h>
typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
typedef int8_t s8;
typedef int16_t s16;
typedef int32_t s32;
typedef int64_t s64;


typedef size_t machine_word_t;


#define WORDBYTES	((int)sizeof(machine_word_t))


#define WORDBITS	(8 * WORDBYTES)






#ifndef LIBEXPORT
#  define LIBEXPORT
#endif


#ifndef inline
#  define inline
#endif


#ifndef forceinline
#  define forceinline inline
#endif


#ifndef restrict
#  define restrict
#endif


#ifndef likely
#  define likely(expr)		(expr)
#endif


#ifndef unlikely
#  define unlikely(expr)	(expr)
#endif


#ifndef prefetchr
#  define prefetchr(addr)
#endif


#ifndef prefetchw
#  define prefetchw(addr)
#endif


#ifndef COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE
#  define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE 0
#endif


#ifndef COMPILER_SUPPORTS_BMI2_TARGET
#  define COMPILER_SUPPORTS_BMI2_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX_TARGET
#  define COMPILER_SUPPORTS_AVX_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET
#  define COMPILER_SUPPORTS_AVX512BW_TARGET 0
#endif


#ifndef COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 0
#endif


#ifndef _aligned_attribute
#endif





#define ARRAY_LEN(A)		(sizeof(A) / sizeof((A)[0]))
#define MIN(a, b)		((a) <= (b) ? (a) : (b))
#define MAX(a, b)		((a) >= (b) ? (a) : (b))
#define DIV_ROUND_UP(n, d)	(((n) + (d) - 1) / (d))
#define STATIC_ASSERT(expr)	((void)sizeof(char[1 - 2 * !(expr)]))
#define ALIGN(n, a)		(((n) + (a) - 1) & ~((a) - 1))






#ifndef CPU_IS_LITTLE_ENDIAN
static forceinline int CPU_IS_LITTLE_ENDIAN(void)
{
	union {
		unsigned int v;
		unsigned char b;
	} u;
	u.v = 1;
	return u.b;
}
#endif


#ifndef bswap16
static forceinline u16 bswap16(u16 n)
{
	return (n << 8) | (n >> 8);
}
#endif


#ifndef bswap32
static forceinline u32 bswap32(u32 n)
{
	return ((n & 0x000000FF) << 24) |
	       ((n & 0x0000FF00) << 8) |
	       ((n & 0x00FF0000) >> 8) |
	       ((n & 0xFF000000) >> 24);
}
#endif


#ifndef bswap64
static forceinline u64 bswap64(u64 n)
{
	return ((n & 0x00000000000000FF) << 56) |
	       ((n & 0x000000000000FF00) << 40) |
	       ((n & 0x0000000000FF0000) << 24) |
	       ((n & 0x00000000FF000000) << 8) |
	       ((n & 0x000000FF00000000) >> 8) |
	       ((n & 0x0000FF0000000000) >> 24) |
	       ((n & 0x00FF000000000000) >> 40) |
	       ((n & 0xFF00000000000000) >> 56);
}
#endif

#define le16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap16(n))
#define le32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap32(n))
#define le64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap64(n))
#define be16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap16(n) : (n))
#define be32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap32(n) : (n))
#define be64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap64(n) : (n))






#ifndef UNALIGNED_ACCESS_IS_FAST
#  define UNALIGNED_ACCESS_IS_FAST 0
#endif







#ifndef bsr32
static forceinline unsigned
bsr32(u32 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

#ifndef bsr64
static forceinline unsigned
bsr64(u64 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

static forceinline unsigned
bsrw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsr32(n);
	else
		return bsr64(n);
}



#ifndef bsf32
static forceinline unsigned
bsf32(u32 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

#ifndef bsf64
static forceinline unsigned
bsf64(u64 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

static forceinline unsigned
bsfw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsf32(n);
	else
		return bsf64(n);
}

#endif 



#define SYM_FIXUP(sym)			_libdeflate_##sym
#define deflate_get_compression_level	SYM_FIXUP(deflate_get_compression_level)
#define _cpu_features			SYM_FIXUP(_cpu_features)
#define setup_cpu_features		SYM_FIXUP(setup_cpu_features)

void *libdeflate_malloc(size_t size);
void libdeflate_free(void *ptr);

void *libdeflate_aligned_malloc(size_t alignment, size_t size);
void libdeflate_aligned_free(void *ptr);

#ifdef FREESTANDING

void *memset(void *s, int c, size_t n);
#define memset(s, c, n)		__builtin_memset((s), (c), (n))

void *memcpy(void *dest, const void *src, size_t n);
#define memcpy(dest, src, n)	__builtin_memcpy((dest), (src), (n))

void *memmove(void *dest, const void *src, size_t n);
#define memmove(dest, src, n)	__builtin_memmove((dest), (src), (n))

int memcmp(const void *s1, const void *s2, size_t n);
#define memcmp(s1, s2, n)	__builtin_memcmp((s1), (s2), (n))
#else
#include <string.h>
#endif

#endif 


/* #include "libdeflate.h" */


#ifndef LIBDEFLATE_H
#define LIBDEFLATE_H

#ifdef __cplusplus
extern "C" {
#endif

#define LIBDEFLATE_VERSION_MAJOR	1
#define LIBDEFLATE_VERSION_MINOR	7
#define LIBDEFLATE_VERSION_STRING	"1.7"

#include <stddef.h>
#include <stdint.h>


#ifdef LIBDEFLATE_DLL
#  ifdef BUILDING_LIBDEFLATE
#    define LIBDEFLATEEXPORT	LIBEXPORT
#  elif defined(_WIN32) || defined(__CYGWIN__)
#    define LIBDEFLATEEXPORT	__declspec(dllimport)
#  endif
#endif
#ifndef LIBDEFLATEEXPORT
#  define LIBDEFLATEEXPORT
#endif

#if defined(_WIN32) && !defined(_WIN64)
#  define LIBDEFLATEAPI_ABI	__stdcall
#else
#  define LIBDEFLATEAPI_ABI
#endif

#if defined(BUILDING_LIBDEFLATE) && defined(__GNUC__) && \
	defined(_WIN32) && !defined(_WIN64)
    
#  define LIBDEFLATEAPI_STACKALIGN	__attribute__((force_align_arg_pointer))
#else
#  define LIBDEFLATEAPI_STACKALIGN
#endif

#define LIBDEFLATEAPI	LIBDEFLATEAPI_ABI LIBDEFLATEAPI_STACKALIGN





struct libdeflate_compressor;


LIBDEFLATEEXPORT struct libdeflate_compressor * LIBDEFLATEAPI
libdeflate_alloc_compressor(int compression_level);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_deflate_compress(struct libdeflate_compressor *compressor,
			    const void *in, size_t in_nbytes,
			    void *out, size_t out_nbytes_avail);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_deflate_compress_bound(struct libdeflate_compressor *compressor,
				  size_t in_nbytes);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_zlib_compress(struct libdeflate_compressor *compressor,
			 const void *in, size_t in_nbytes,
			 void *out, size_t out_nbytes_avail);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_zlib_compress_bound(struct libdeflate_compressor *compressor,
			       size_t in_nbytes);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_gzip_compress(struct libdeflate_compressor *compressor,
			 const void *in, size_t in_nbytes,
			 void *out, size_t out_nbytes_avail);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_gzip_compress_bound(struct libdeflate_compressor *compressor,
			       size_t in_nbytes);


LIBDEFLATEEXPORT void LIBDEFLATEAPI
libdeflate_free_compressor(struct libdeflate_compressor *compressor);





struct libdeflate_decompressor;


LIBDEFLATEEXPORT struct libdeflate_decompressor * LIBDEFLATEAPI
libdeflate_alloc_decompressor(void);


enum libdeflate_result {
	
	LIBDEFLATE_SUCCESS = 0,

	
	LIBDEFLATE_BAD_DATA = 1,

	
	LIBDEFLATE_SHORT_OUTPUT = 2,

	
	LIBDEFLATE_INSUFFICIENT_SPACE = 3,
};


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_deflate_decompress(struct libdeflate_decompressor *decompressor,
			      const void *in, size_t in_nbytes,
			      void *out, size_t out_nbytes_avail,
			      size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_deflate_decompress_ex(struct libdeflate_decompressor *decompressor,
				 const void *in, size_t in_nbytes,
				 void *out, size_t out_nbytes_avail,
				 size_t *actual_in_nbytes_ret,
				 size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_zlib_decompress(struct libdeflate_decompressor *decompressor,
			   const void *in, size_t in_nbytes,
			   void *out, size_t out_nbytes_avail,
			   size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_zlib_decompress_ex(struct libdeflate_decompressor *decompressor,
			      const void *in, size_t in_nbytes,
			      void *out, size_t out_nbytes_avail,
			      size_t *actual_in_nbytes_ret,
			      size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_gzip_decompress(struct libdeflate_decompressor *decompressor,
			   const void *in, size_t in_nbytes,
			   void *out, size_t out_nbytes_avail,
			   size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_gzip_decompress_ex(struct libdeflate_decompressor *decompressor,
			      const void *in, size_t in_nbytes,
			      void *out, size_t out_nbytes_avail,
			      size_t *actual_in_nbytes_ret,
			      size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT void LIBDEFLATEAPI
libdeflate_free_decompressor(struct libdeflate_decompressor *decompressor);






LIBDEFLATEEXPORT uint32_t LIBDEFLATEAPI
libdeflate_adler32(uint32_t adler, const void *buffer, size_t len);



LIBDEFLATEEXPORT uint32_t LIBDEFLATEAPI
libdeflate_crc32(uint32_t crc, const void *buffer, size_t len);






LIBDEFLATEEXPORT void LIBDEFLATEAPI
libdeflate_set_memory_allocator(void *(*malloc_func)(size_t),
				void (*free_func)(void *));

#ifdef __cplusplus
}
#endif

#endif 


#ifdef FREESTANDING
#  define malloc NULL
#  define free NULL
#else
#  include <stdlib.h>
#endif

static void *(*libdeflate_malloc_func)(size_t) = malloc;
static void (*libdeflate_free_func)(void *) = free;

void *
libdeflate_malloc(size_t size)
{
	return (*libdeflate_malloc_func)(size);
}

void
libdeflate_free(void *ptr)
{
	(*libdeflate_free_func)(ptr);
}

void *
libdeflate_aligned_malloc(size_t alignment, size_t size)
{
	void *ptr = libdeflate_malloc(sizeof(void *) + alignment - 1 + size);
	if (ptr) {
		void *orig_ptr = ptr;
		ptr = (void *)ALIGN((uintptr_t)ptr + sizeof(void *), alignment);
		((void **)ptr)[-1] = orig_ptr;
	}
	return ptr;
}

void
libdeflate_aligned_free(void *ptr)
{
	if (ptr)
		libdeflate_free(((void **)ptr)[-1]);
}

LIBDEFLATEEXPORT void LIBDEFLATEAPI
libdeflate_set_memory_allocator(void *(*malloc_func)(size_t),
				void (*free_func)(void *))
{
	libdeflate_malloc_func = malloc_func;
	libdeflate_free_func = free_func;
}


#ifdef FREESTANDING
#undef memset
void *memset(void *s, int c, size_t n)
{
	u8 *p = s;
	size_t i;

	for (i = 0; i < n; i++)
		p[i] = c;
	return s;
}

#undef memcpy
void *memcpy(void *dest, const void *src, size_t n)
{
	u8 *d = dest;
	const u8 *s = src;
	size_t i;

	for (i = 0; i < n; i++)
		d[i] = s[i];
	return dest;
}

#undef memmove
void *memmove(void *dest, const void *src, size_t n)
{
	u8 *d = dest;
	const u8 *s = src;
	size_t i;

	if (d <= s)
		return memcpy(d, s, n);

	for (i = n; i > 0; i--)
		d[i - 1] = s[i - 1];
	return dest;
}

#undef memcmp
int memcmp(const void *s1, const void *s2, size_t n)
{
	const u8 *p1 = s1;
	const u8 *p2 = s2;
	size_t i;

	for (i = 0; i < n; i++) {
		if (p1[i] != p2[i])
			return (int)p1[i] - (int)p2[i];
	}
	return 0;
}
#endif 
/* /usr/home/ben/projects/gzip-libdeflate/../../software/libdeflate-1.7/lib/zlib_compress.c */


/* #include "deflate_compress.h" */
#ifndef LIB_DEFLATE_COMPRESS_H
#define LIB_DEFLATE_COMPRESS_H

/* #include "lib_common.h" */


#ifndef LIB_LIB_COMMON_H
#define LIB_LIB_COMMON_H

#ifdef LIBDEFLATE_H
#  error "lib_common.h must always be included before libdeflate.h"
   
#endif

#define BUILDING_LIBDEFLATE

/* #include "../common/common_defs.h" */


#ifndef COMMON_COMMON_DEFS_H
#define COMMON_COMMON_DEFS_H

#ifdef __GNUC__
/* #  include "compiler_gcc.h" */


#if !defined(__clang__) && !defined(__INTEL_COMPILER)
#  define GCC_PREREQ(major, minor)		\
	(__GNUC__ > (major) ||			\
	 (__GNUC__ == (major) && __GNUC_MINOR__ >= (minor)))
#else
#  define GCC_PREREQ(major, minor)	0
#endif


#ifdef __clang__
#  ifdef __apple_build_version__
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__apple_build_version__ >= (apple_version))
#  else
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__clang_major__ > (major) ||			\
	 (__clang_major__ == (major) && __clang_minor__ >= (minor)))
#  endif
#else
#  define CLANG_PREREQ(major, minor, apple_version)	0
#endif

#ifndef __has_attribute
#  define __has_attribute(attribute)	0
#endif
#ifndef __has_feature
#  define __has_feature(feature)	0
#endif
#ifndef __has_builtin
#  define __has_builtin(builtin)	0
#endif

#ifdef _WIN32
#  define LIBEXPORT __declspec(dllexport)
#else
#  define LIBEXPORT __attribute__((visibility("default")))
#endif

#define inline			inline
#define forceinline		inline __attribute__((always_inline))
#define restrict		__restrict__
#define likely(expr)		__builtin_expect(!!(expr), 1)
#define unlikely(expr)		__builtin_expect(!!(expr), 0)
#define prefetchr(addr)		__builtin_prefetch((addr), 0)
#define prefetchw(addr)		__builtin_prefetch((addr), 1)
#define _aligned_attribute(n)	__attribute__((aligned(n)))

#define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE	\
	(GCC_PREREQ(4, 4) || __has_attribute(target))

#if COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE

#  if defined(__i386__) || defined(__x86_64__)

#    define COMPILER_SUPPORTS_PCLMUL_TARGET	\
	(GCC_PREREQ(4, 4) || __has_builtin(__builtin_ia32_pclmulqdq128))

#    define COMPILER_SUPPORTS_AVX_TARGET	\
	(GCC_PREREQ(4, 6) || __has_builtin(__builtin_ia32_maxps256))

#    define COMPILER_SUPPORTS_BMI2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_pdep_di))

#    define COMPILER_SUPPORTS_AVX2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_psadbw256))

#    define COMPILER_SUPPORTS_AVX512BW_TARGET	\
	(GCC_PREREQ(5, 1) || __has_builtin(__builtin_ia32_psadbw512))

	
#    if GCC_PREREQ(4, 9) || CLANG_PREREQ(3, 8, 7030000)
#      define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS	1
#      define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_PCLMUL_TARGET
#      define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX2_TARGET
#      define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX512BW_TARGET
#    endif

#  elif defined(__arm__) || defined(__aarch64__)

    
#    if (GCC_PREREQ(6, 1) && defined(__ARM_FP)) || \
        (defined(__clang__) && defined(__ARM_NEON))
#      define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 1
       
#      if defined(__clang__) && defined(__arm__)
#        undef __ARM_FEATURE_CRYPTO
#      elif __has_builtin(__builtin_neon_vmull_p64) || !defined(__clang__)
#        define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 1
#      endif
#    endif

     
#    if GCC_PREREQ(10, 1) || \
        (GCC_PREREQ(9, 3) && !GCC_PREREQ(10, 0)) || \
        (GCC_PREREQ(8, 4) && !GCC_PREREQ(9, 0)) || \
        (defined(__clang__) && __has_builtin(__builtin_arm_crc32b))
#      define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 1
#    endif

#  endif 

#endif 


#if (GCC_PREREQ(4, 0) && !GCC_PREREQ(5, 1)) || \
    (defined(__clang__) && !CLANG_PREREQ(3, 9, 8020000))
typedef unsigned long long  __v2du __attribute__((__vector_size__(16)));
typedef unsigned int        __v4su __attribute__((__vector_size__(16)));
typedef unsigned short      __v8hu __attribute__((__vector_size__(16)));
typedef unsigned char      __v16qu __attribute__((__vector_size__(16)));
typedef unsigned long long  __v4du __attribute__((__vector_size__(32)));
typedef unsigned int        __v8su __attribute__((__vector_size__(32)));
typedef unsigned short     __v16hu __attribute__((__vector_size__(32)));
typedef unsigned char      __v32qu __attribute__((__vector_size__(32)));
#endif


#ifdef __BYTE_ORDER__
#  define CPU_IS_LITTLE_ENDIAN() (__BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__)
#endif

#if GCC_PREREQ(4, 8) || __has_builtin(__builtin_bswap16)
#  define bswap16	__builtin_bswap16
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap32)
#  define bswap32	__builtin_bswap32
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap64)
#  define bswap64	__builtin_bswap64
#endif

#if defined(__x86_64__) || defined(__i386__) || defined(__ARM_FEATURE_UNALIGNED) || defined(__powerpc64__)
#  define UNALIGNED_ACCESS_IS_FAST 1
#endif

#define bsr32(n)	(31 - __builtin_clz(n))
#define bsr64(n)	(63 - __builtin_clzll(n))
#define bsf32(n)	__builtin_ctz(n)
#define bsf64(n)	__builtin_ctzll(n)

#elif defined(_MSC_VER)
/* #  include "compiler_msc.h" */


#include <stdint.h>
#include <stdlib.h> 

#define LIBEXPORT	__declspec(dllexport)


typedef int bool;
#define true 1
#define false 0
#define __bool_true_false_are_defined 1


#ifdef _WIN64
typedef long long ssize_t;
#else
typedef int ssize_t;
#endif


#define CPU_IS_LITTLE_ENDIAN()		1
#define UNALIGNED_ACCESS_IS_FAST	1


#define restrict


#define inline		__inline
#define forceinline	__forceinline


#define bswap16	_byteswap_ushort
#define bswap32	_byteswap_ulong
#define bswap64	_byteswap_uint64



static forceinline unsigned
bsr32(uint32_t n)
{
	_BitScanReverse(&n, n);
	return n;
}
#define bsr32 bsr32

static forceinline unsigned
bsf32(uint32_t n)
{
	_BitScanForward(&n, n);
	return n;
}
#define bsf32 bsf32

#ifdef _M_X64 

static forceinline unsigned
bsr64(uint64_t n)
{
	_BitScanReverse64(&n, n);
	return n;
}
#define bsr64 bsr64

static forceinline unsigned
bsf64(uint64_t n)
{
	_BitScanForward64(&n, n);
	return n;
}
#define bsf64 bsf64

#endif 

#else
#  pragma message("Unrecognized compiler.  Please add a header file for your compiler.  Compilation will proceed, but performance may suffer!")
#endif





#include <stddef.h> 

#ifndef __bool_true_false_are_defined
#  include <stdbool.h> 
#endif


#include <stdint.h>
typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
typedef int8_t s8;
typedef int16_t s16;
typedef int32_t s32;
typedef int64_t s64;


typedef size_t machine_word_t;


#define WORDBYTES	((int)sizeof(machine_word_t))


#define WORDBITS	(8 * WORDBYTES)






#ifndef LIBEXPORT
#  define LIBEXPORT
#endif


#ifndef inline
#  define inline
#endif


#ifndef forceinline
#  define forceinline inline
#endif


#ifndef restrict
#  define restrict
#endif


#ifndef likely
#  define likely(expr)		(expr)
#endif


#ifndef unlikely
#  define unlikely(expr)	(expr)
#endif


#ifndef prefetchr
#  define prefetchr(addr)
#endif


#ifndef prefetchw
#  define prefetchw(addr)
#endif


#ifndef COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE
#  define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE 0
#endif


#ifndef COMPILER_SUPPORTS_BMI2_TARGET
#  define COMPILER_SUPPORTS_BMI2_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX_TARGET
#  define COMPILER_SUPPORTS_AVX_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET
#  define COMPILER_SUPPORTS_AVX512BW_TARGET 0
#endif


#ifndef COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 0
#endif


#ifndef _aligned_attribute
#endif





#define ARRAY_LEN(A)		(sizeof(A) / sizeof((A)[0]))
#define MIN(a, b)		((a) <= (b) ? (a) : (b))
#define MAX(a, b)		((a) >= (b) ? (a) : (b))
#define DIV_ROUND_UP(n, d)	(((n) + (d) - 1) / (d))
#define STATIC_ASSERT(expr)	((void)sizeof(char[1 - 2 * !(expr)]))
#define ALIGN(n, a)		(((n) + (a) - 1) & ~((a) - 1))






#ifndef CPU_IS_LITTLE_ENDIAN
static forceinline int CPU_IS_LITTLE_ENDIAN(void)
{
	union {
		unsigned int v;
		unsigned char b;
	} u;
	u.v = 1;
	return u.b;
}
#endif


#ifndef bswap16
static forceinline u16 bswap16(u16 n)
{
	return (n << 8) | (n >> 8);
}
#endif


#ifndef bswap32
static forceinline u32 bswap32(u32 n)
{
	return ((n & 0x000000FF) << 24) |
	       ((n & 0x0000FF00) << 8) |
	       ((n & 0x00FF0000) >> 8) |
	       ((n & 0xFF000000) >> 24);
}
#endif


#ifndef bswap64
static forceinline u64 bswap64(u64 n)
{
	return ((n & 0x00000000000000FF) << 56) |
	       ((n & 0x000000000000FF00) << 40) |
	       ((n & 0x0000000000FF0000) << 24) |
	       ((n & 0x00000000FF000000) << 8) |
	       ((n & 0x000000FF00000000) >> 8) |
	       ((n & 0x0000FF0000000000) >> 24) |
	       ((n & 0x00FF000000000000) >> 40) |
	       ((n & 0xFF00000000000000) >> 56);
}
#endif

#define le16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap16(n))
#define le32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap32(n))
#define le64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap64(n))
#define be16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap16(n) : (n))
#define be32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap32(n) : (n))
#define be64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap64(n) : (n))






#ifndef UNALIGNED_ACCESS_IS_FAST
#  define UNALIGNED_ACCESS_IS_FAST 0
#endif







#ifndef bsr32
static forceinline unsigned
bsr32(u32 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

#ifndef bsr64
static forceinline unsigned
bsr64(u64 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

static forceinline unsigned
bsrw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsr32(n);
	else
		return bsr64(n);
}



#ifndef bsf32
static forceinline unsigned
bsf32(u32 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

#ifndef bsf64
static forceinline unsigned
bsf64(u64 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

static forceinline unsigned
bsfw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsf32(n);
	else
		return bsf64(n);
}

#endif 



#define SYM_FIXUP(sym)			_libdeflate_##sym
#define deflate_get_compression_level	SYM_FIXUP(deflate_get_compression_level)
#define _cpu_features			SYM_FIXUP(_cpu_features)
#define setup_cpu_features		SYM_FIXUP(setup_cpu_features)

void *libdeflate_malloc(size_t size);
void libdeflate_free(void *ptr);

void *libdeflate_aligned_malloc(size_t alignment, size_t size);
void libdeflate_aligned_free(void *ptr);

#ifdef FREESTANDING

void *memset(void *s, int c, size_t n);
#define memset(s, c, n)		__builtin_memset((s), (c), (n))

void *memcpy(void *dest, const void *src, size_t n);
#define memcpy(dest, src, n)	__builtin_memcpy((dest), (src), (n))

void *memmove(void *dest, const void *src, size_t n);
#define memmove(dest, src, n)	__builtin_memmove((dest), (src), (n))

int memcmp(const void *s1, const void *s2, size_t n);
#define memcmp(s1, s2, n)	__builtin_memcmp((s1), (s2), (n))
#else
#include <string.h>
#endif

#endif 




struct libdeflate_compressor;

unsigned int deflate_get_compression_level(struct libdeflate_compressor *c);

#endif 

/* #include "unaligned.h" */


#ifndef LIB_UNALIGNED_H
#define LIB_UNALIGNED_H

/* #include "lib_common.h" */


#ifndef LIB_LIB_COMMON_H
#define LIB_LIB_COMMON_H

#ifdef LIBDEFLATE_H
#  error "lib_common.h must always be included before libdeflate.h"
   
#endif

#define BUILDING_LIBDEFLATE

/* #include "../common/common_defs.h" */


#ifndef COMMON_COMMON_DEFS_H
#define COMMON_COMMON_DEFS_H

#ifdef __GNUC__
/* #  include "compiler_gcc.h" */


#if !defined(__clang__) && !defined(__INTEL_COMPILER)
#  define GCC_PREREQ(major, minor)		\
	(__GNUC__ > (major) ||			\
	 (__GNUC__ == (major) && __GNUC_MINOR__ >= (minor)))
#else
#  define GCC_PREREQ(major, minor)	0
#endif


#ifdef __clang__
#  ifdef __apple_build_version__
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__apple_build_version__ >= (apple_version))
#  else
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__clang_major__ > (major) ||			\
	 (__clang_major__ == (major) && __clang_minor__ >= (minor)))
#  endif
#else
#  define CLANG_PREREQ(major, minor, apple_version)	0
#endif

#ifndef __has_attribute
#  define __has_attribute(attribute)	0
#endif
#ifndef __has_feature
#  define __has_feature(feature)	0
#endif
#ifndef __has_builtin
#  define __has_builtin(builtin)	0
#endif

#ifdef _WIN32
#  define LIBEXPORT __declspec(dllexport)
#else
#  define LIBEXPORT __attribute__((visibility("default")))
#endif

#define inline			inline
#define forceinline		inline __attribute__((always_inline))
#define restrict		__restrict__
#define likely(expr)		__builtin_expect(!!(expr), 1)
#define unlikely(expr)		__builtin_expect(!!(expr), 0)
#define prefetchr(addr)		__builtin_prefetch((addr), 0)
#define prefetchw(addr)		__builtin_prefetch((addr), 1)
#define _aligned_attribute(n)	__attribute__((aligned(n)))

#define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE	\
	(GCC_PREREQ(4, 4) || __has_attribute(target))

#if COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE

#  if defined(__i386__) || defined(__x86_64__)

#    define COMPILER_SUPPORTS_PCLMUL_TARGET	\
	(GCC_PREREQ(4, 4) || __has_builtin(__builtin_ia32_pclmulqdq128))

#    define COMPILER_SUPPORTS_AVX_TARGET	\
	(GCC_PREREQ(4, 6) || __has_builtin(__builtin_ia32_maxps256))

#    define COMPILER_SUPPORTS_BMI2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_pdep_di))

#    define COMPILER_SUPPORTS_AVX2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_psadbw256))

#    define COMPILER_SUPPORTS_AVX512BW_TARGET	\
	(GCC_PREREQ(5, 1) || __has_builtin(__builtin_ia32_psadbw512))

	
#    if GCC_PREREQ(4, 9) || CLANG_PREREQ(3, 8, 7030000)
#      define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS	1
#      define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_PCLMUL_TARGET
#      define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX2_TARGET
#      define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX512BW_TARGET
#    endif

#  elif defined(__arm__) || defined(__aarch64__)

    
#    if (GCC_PREREQ(6, 1) && defined(__ARM_FP)) || \
        (defined(__clang__) && defined(__ARM_NEON))
#      define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 1
       
#      if defined(__clang__) && defined(__arm__)
#        undef __ARM_FEATURE_CRYPTO
#      elif __has_builtin(__builtin_neon_vmull_p64) || !defined(__clang__)
#        define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 1
#      endif
#    endif

     
#    if GCC_PREREQ(10, 1) || \
        (GCC_PREREQ(9, 3) && !GCC_PREREQ(10, 0)) || \
        (GCC_PREREQ(8, 4) && !GCC_PREREQ(9, 0)) || \
        (defined(__clang__) && __has_builtin(__builtin_arm_crc32b))
#      define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 1
#    endif

#  endif 

#endif 


#if (GCC_PREREQ(4, 0) && !GCC_PREREQ(5, 1)) || \
    (defined(__clang__) && !CLANG_PREREQ(3, 9, 8020000))
typedef unsigned long long  __v2du __attribute__((__vector_size__(16)));
typedef unsigned int        __v4su __attribute__((__vector_size__(16)));
typedef unsigned short      __v8hu __attribute__((__vector_size__(16)));
typedef unsigned char      __v16qu __attribute__((__vector_size__(16)));
typedef unsigned long long  __v4du __attribute__((__vector_size__(32)));
typedef unsigned int        __v8su __attribute__((__vector_size__(32)));
typedef unsigned short     __v16hu __attribute__((__vector_size__(32)));
typedef unsigned char      __v32qu __attribute__((__vector_size__(32)));
#endif


#ifdef __BYTE_ORDER__
#  define CPU_IS_LITTLE_ENDIAN() (__BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__)
#endif

#if GCC_PREREQ(4, 8) || __has_builtin(__builtin_bswap16)
#  define bswap16	__builtin_bswap16
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap32)
#  define bswap32	__builtin_bswap32
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap64)
#  define bswap64	__builtin_bswap64
#endif

#if defined(__x86_64__) || defined(__i386__) || defined(__ARM_FEATURE_UNALIGNED) || defined(__powerpc64__)
#  define UNALIGNED_ACCESS_IS_FAST 1
#endif

#define bsr32(n)	(31 - __builtin_clz(n))
#define bsr64(n)	(63 - __builtin_clzll(n))
#define bsf32(n)	__builtin_ctz(n)
#define bsf64(n)	__builtin_ctzll(n)

#elif defined(_MSC_VER)
/* #  include "compiler_msc.h" */


#include <stdint.h>
#include <stdlib.h> 

#define LIBEXPORT	__declspec(dllexport)


typedef int bool;
#define true 1
#define false 0
#define __bool_true_false_are_defined 1


#ifdef _WIN64
typedef long long ssize_t;
#else
typedef int ssize_t;
#endif


#define CPU_IS_LITTLE_ENDIAN()		1
#define UNALIGNED_ACCESS_IS_FAST	1


#define restrict


#define inline		__inline
#define forceinline	__forceinline


#define bswap16	_byteswap_ushort
#define bswap32	_byteswap_ulong
#define bswap64	_byteswap_uint64



static forceinline unsigned
bsr32(uint32_t n)
{
	_BitScanReverse(&n, n);
	return n;
}
#define bsr32 bsr32

static forceinline unsigned
bsf32(uint32_t n)
{
	_BitScanForward(&n, n);
	return n;
}
#define bsf32 bsf32

#ifdef _M_X64 

static forceinline unsigned
bsr64(uint64_t n)
{
	_BitScanReverse64(&n, n);
	return n;
}
#define bsr64 bsr64

static forceinline unsigned
bsf64(uint64_t n)
{
	_BitScanForward64(&n, n);
	return n;
}
#define bsf64 bsf64

#endif 

#else
#  pragma message("Unrecognized compiler.  Please add a header file for your compiler.  Compilation will proceed, but performance may suffer!")
#endif





#include <stddef.h> 

#ifndef __bool_true_false_are_defined
#  include <stdbool.h> 
#endif


#include <stdint.h>
typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
typedef int8_t s8;
typedef int16_t s16;
typedef int32_t s32;
typedef int64_t s64;


typedef size_t machine_word_t;


#define WORDBYTES	((int)sizeof(machine_word_t))


#define WORDBITS	(8 * WORDBYTES)






#ifndef LIBEXPORT
#  define LIBEXPORT
#endif


#ifndef inline
#  define inline
#endif


#ifndef forceinline
#  define forceinline inline
#endif


#ifndef restrict
#  define restrict
#endif


#ifndef likely
#  define likely(expr)		(expr)
#endif


#ifndef unlikely
#  define unlikely(expr)	(expr)
#endif


#ifndef prefetchr
#  define prefetchr(addr)
#endif


#ifndef prefetchw
#  define prefetchw(addr)
#endif


#ifndef COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE
#  define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE 0
#endif


#ifndef COMPILER_SUPPORTS_BMI2_TARGET
#  define COMPILER_SUPPORTS_BMI2_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX_TARGET
#  define COMPILER_SUPPORTS_AVX_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET
#  define COMPILER_SUPPORTS_AVX512BW_TARGET 0
#endif


#ifndef COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 0
#endif


#ifndef _aligned_attribute
#endif





#define ARRAY_LEN(A)		(sizeof(A) / sizeof((A)[0]))
#define MIN(a, b)		((a) <= (b) ? (a) : (b))
#define MAX(a, b)		((a) >= (b) ? (a) : (b))
#define DIV_ROUND_UP(n, d)	(((n) + (d) - 1) / (d))
#define STATIC_ASSERT(expr)	((void)sizeof(char[1 - 2 * !(expr)]))
#define ALIGN(n, a)		(((n) + (a) - 1) & ~((a) - 1))






#ifndef CPU_IS_LITTLE_ENDIAN
static forceinline int CPU_IS_LITTLE_ENDIAN(void)
{
	union {
		unsigned int v;
		unsigned char b;
	} u;
	u.v = 1;
	return u.b;
}
#endif


#ifndef bswap16
static forceinline u16 bswap16(u16 n)
{
	return (n << 8) | (n >> 8);
}
#endif


#ifndef bswap32
static forceinline u32 bswap32(u32 n)
{
	return ((n & 0x000000FF) << 24) |
	       ((n & 0x0000FF00) << 8) |
	       ((n & 0x00FF0000) >> 8) |
	       ((n & 0xFF000000) >> 24);
}
#endif


#ifndef bswap64
static forceinline u64 bswap64(u64 n)
{
	return ((n & 0x00000000000000FF) << 56) |
	       ((n & 0x000000000000FF00) << 40) |
	       ((n & 0x0000000000FF0000) << 24) |
	       ((n & 0x00000000FF000000) << 8) |
	       ((n & 0x000000FF00000000) >> 8) |
	       ((n & 0x0000FF0000000000) >> 24) |
	       ((n & 0x00FF000000000000) >> 40) |
	       ((n & 0xFF00000000000000) >> 56);
}
#endif

#define le16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap16(n))
#define le32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap32(n))
#define le64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap64(n))
#define be16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap16(n) : (n))
#define be32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap32(n) : (n))
#define be64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap64(n) : (n))






#ifndef UNALIGNED_ACCESS_IS_FAST
#  define UNALIGNED_ACCESS_IS_FAST 0
#endif







#ifndef bsr32
static forceinline unsigned
bsr32(u32 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

#ifndef bsr64
static forceinline unsigned
bsr64(u64 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

static forceinline unsigned
bsrw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsr32(n);
	else
		return bsr64(n);
}



#ifndef bsf32
static forceinline unsigned
bsf32(u32 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

#ifndef bsf64
static forceinline unsigned
bsf64(u64 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

static forceinline unsigned
bsfw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsf32(n);
	else
		return bsf64(n);
}

#endif 



#define SYM_FIXUP(sym)			_libdeflate_##sym
#define deflate_get_compression_level	SYM_FIXUP(deflate_get_compression_level)
#define _cpu_features			SYM_FIXUP(_cpu_features)
#define setup_cpu_features		SYM_FIXUP(setup_cpu_features)

void *libdeflate_malloc(size_t size);
void libdeflate_free(void *ptr);

void *libdeflate_aligned_malloc(size_t alignment, size_t size);
void libdeflate_aligned_free(void *ptr);

#ifdef FREESTANDING

void *memset(void *s, int c, size_t n);
#define memset(s, c, n)		__builtin_memset((s), (c), (n))

void *memcpy(void *dest, const void *src, size_t n);
#define memcpy(dest, src, n)	__builtin_memcpy((dest), (src), (n))

void *memmove(void *dest, const void *src, size_t n);
#define memmove(dest, src, n)	__builtin_memmove((dest), (src), (n))

int memcmp(const void *s1, const void *s2, size_t n);
#define memcmp(s1, s2, n)	__builtin_memcmp((s1), (s2), (n))
#else
#include <string.h>
#endif

#endif 






#define DEFINE_UNALIGNED_TYPE(type)				\
static forceinline type						\
load_##type##_unaligned(const void *p)				\
{								\
	type v;							\
	memcpy(&v, p, sizeof(v));				\
	return v;						\
}								\
								\
static forceinline void						\
store_##type##_unaligned(type v, void *p)			\
{								\
	memcpy(p, &v, sizeof(v));				\
}

DEFINE_UNALIGNED_TYPE(u16)
DEFINE_UNALIGNED_TYPE(u32)
DEFINE_UNALIGNED_TYPE(u64)
DEFINE_UNALIGNED_TYPE(machine_word_t)

#define load_word_unaligned	load_machine_word_t_unaligned
#define store_word_unaligned	store_machine_word_t_unaligned



static forceinline u16
get_unaligned_le16(const u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST)
		return le16_bswap(load_u16_unaligned(p));
	else
		return ((u16)p[1] << 8) | p[0];
}

static forceinline u16
get_unaligned_be16(const u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST)
		return be16_bswap(load_u16_unaligned(p));
	else
		return ((u16)p[0] << 8) | p[1];
}

static forceinline u32
get_unaligned_le32(const u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST)
		return le32_bswap(load_u32_unaligned(p));
	else
		return ((u32)p[3] << 24) | ((u32)p[2] << 16) |
			((u32)p[1] << 8) | p[0];
}

static forceinline u32
get_unaligned_be32(const u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST)
		return be32_bswap(load_u32_unaligned(p));
	else
		return ((u32)p[0] << 24) | ((u32)p[1] << 16) |
			((u32)p[2] << 8) | p[3];
}

static forceinline u64
get_unaligned_le64(const u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST)
		return le64_bswap(load_u64_unaligned(p));
	else
		return ((u64)p[7] << 56) | ((u64)p[6] << 48) |
			((u64)p[5] << 40) | ((u64)p[4] << 32) |
			((u64)p[3] << 24) | ((u64)p[2] << 16) |
			((u64)p[1] << 8) | p[0];
}

static forceinline machine_word_t
get_unaligned_leword(const u8 *p)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return get_unaligned_le32(p);
	else
		return get_unaligned_le64(p);
}



static forceinline void
put_unaligned_le16(u16 v, u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST) {
		store_u16_unaligned(le16_bswap(v), p);
	} else {
		p[0] = (u8)(v >> 0);
		p[1] = (u8)(v >> 8);
	}
}

static forceinline void
put_unaligned_be16(u16 v, u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST) {
		store_u16_unaligned(be16_bswap(v), p);
	} else {
		p[0] = (u8)(v >> 8);
		p[1] = (u8)(v >> 0);
	}
}

static forceinline void
put_unaligned_le32(u32 v, u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST) {
		store_u32_unaligned(le32_bswap(v), p);
	} else {
		p[0] = (u8)(v >> 0);
		p[1] = (u8)(v >> 8);
		p[2] = (u8)(v >> 16);
		p[3] = (u8)(v >> 24);
	}
}

static forceinline void
put_unaligned_be32(u32 v, u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST) {
		store_u32_unaligned(be32_bswap(v), p);
	} else {
		p[0] = (u8)(v >> 24);
		p[1] = (u8)(v >> 16);
		p[2] = (u8)(v >> 8);
		p[3] = (u8)(v >> 0);
	}
}

static forceinline void
put_unaligned_le64(u64 v, u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST) {
		store_u64_unaligned(le64_bswap(v), p);
	} else {
		p[0] = (u8)(v >> 0);
		p[1] = (u8)(v >> 8);
		p[2] = (u8)(v >> 16);
		p[3] = (u8)(v >> 24);
		p[4] = (u8)(v >> 32);
		p[5] = (u8)(v >> 40);
		p[6] = (u8)(v >> 48);
		p[7] = (u8)(v >> 56);
	}
}

static forceinline void
put_unaligned_leword(machine_word_t v, u8 *p)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		put_unaligned_le32(v, p);
	else
		put_unaligned_le64(v, p);
}




static forceinline u32
loaded_u32_to_u24(u32 v)
{
	if (CPU_IS_LITTLE_ENDIAN())
		return v & 0xFFFFFF;
	else
		return v >> 8;
}


static forceinline u32
load_u24_unaligned(const u8 *p)
{
#if UNALIGNED_ACCESS_IS_FAST
#  define LOAD_U24_REQUIRED_NBYTES 4
	return loaded_u32_to_u24(load_u32_unaligned(p));
#else
#  define LOAD_U24_REQUIRED_NBYTES 3
	if (CPU_IS_LITTLE_ENDIAN())
		return ((u32)p[0] << 0) | ((u32)p[1] << 8) | ((u32)p[2] << 16);
	else
		return ((u32)p[2] << 0) | ((u32)p[1] << 8) | ((u32)p[0] << 16);
#endif
}

#endif 

/* #include "zlib_constants.h" */


#ifndef LIB_ZLIB_CONSTANTS_H
#define LIB_ZLIB_CONSTANTS_H

#define ZLIB_MIN_HEADER_SIZE	2
#define ZLIB_FOOTER_SIZE	4
#define ZLIB_MIN_OVERHEAD	(ZLIB_MIN_HEADER_SIZE + ZLIB_FOOTER_SIZE)

#define ZLIB_CM_DEFLATE		8

#define ZLIB_CINFO_32K_WINDOW	7

#define ZLIB_FASTEST_COMPRESSION	0
#define ZLIB_FAST_COMPRESSION		1
#define ZLIB_DEFAULT_COMPRESSION	2
#define ZLIB_SLOWEST_COMPRESSION	3

#endif 


/* #include "libdeflate.h" */


#ifndef LIBDEFLATE_H
#define LIBDEFLATE_H

#ifdef __cplusplus
extern "C" {
#endif

#define LIBDEFLATE_VERSION_MAJOR	1
#define LIBDEFLATE_VERSION_MINOR	7
#define LIBDEFLATE_VERSION_STRING	"1.7"

#include <stddef.h>
#include <stdint.h>


#ifdef LIBDEFLATE_DLL
#  ifdef BUILDING_LIBDEFLATE
#    define LIBDEFLATEEXPORT	LIBEXPORT
#  elif defined(_WIN32) || defined(__CYGWIN__)
#    define LIBDEFLATEEXPORT	__declspec(dllimport)
#  endif
#endif
#ifndef LIBDEFLATEEXPORT
#  define LIBDEFLATEEXPORT
#endif

#if defined(_WIN32) && !defined(_WIN64)
#  define LIBDEFLATEAPI_ABI	__stdcall
#else
#  define LIBDEFLATEAPI_ABI
#endif

#if defined(BUILDING_LIBDEFLATE) && defined(__GNUC__) && \
	defined(_WIN32) && !defined(_WIN64)
    
#  define LIBDEFLATEAPI_STACKALIGN	__attribute__((force_align_arg_pointer))
#else
#  define LIBDEFLATEAPI_STACKALIGN
#endif

#define LIBDEFLATEAPI	LIBDEFLATEAPI_ABI LIBDEFLATEAPI_STACKALIGN





struct libdeflate_compressor;


LIBDEFLATEEXPORT struct libdeflate_compressor * LIBDEFLATEAPI
libdeflate_alloc_compressor(int compression_level);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_deflate_compress(struct libdeflate_compressor *compressor,
			    const void *in, size_t in_nbytes,
			    void *out, size_t out_nbytes_avail);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_deflate_compress_bound(struct libdeflate_compressor *compressor,
				  size_t in_nbytes);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_zlib_compress(struct libdeflate_compressor *compressor,
			 const void *in, size_t in_nbytes,
			 void *out, size_t out_nbytes_avail);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_zlib_compress_bound(struct libdeflate_compressor *compressor,
			       size_t in_nbytes);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_gzip_compress(struct libdeflate_compressor *compressor,
			 const void *in, size_t in_nbytes,
			 void *out, size_t out_nbytes_avail);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_gzip_compress_bound(struct libdeflate_compressor *compressor,
			       size_t in_nbytes);


LIBDEFLATEEXPORT void LIBDEFLATEAPI
libdeflate_free_compressor(struct libdeflate_compressor *compressor);





struct libdeflate_decompressor;


LIBDEFLATEEXPORT struct libdeflate_decompressor * LIBDEFLATEAPI
libdeflate_alloc_decompressor(void);


enum libdeflate_result {
	
	LIBDEFLATE_SUCCESS = 0,

	
	LIBDEFLATE_BAD_DATA = 1,

	
	LIBDEFLATE_SHORT_OUTPUT = 2,

	
	LIBDEFLATE_INSUFFICIENT_SPACE = 3,
};


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_deflate_decompress(struct libdeflate_decompressor *decompressor,
			      const void *in, size_t in_nbytes,
			      void *out, size_t out_nbytes_avail,
			      size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_deflate_decompress_ex(struct libdeflate_decompressor *decompressor,
				 const void *in, size_t in_nbytes,
				 void *out, size_t out_nbytes_avail,
				 size_t *actual_in_nbytes_ret,
				 size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_zlib_decompress(struct libdeflate_decompressor *decompressor,
			   const void *in, size_t in_nbytes,
			   void *out, size_t out_nbytes_avail,
			   size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_zlib_decompress_ex(struct libdeflate_decompressor *decompressor,
			      const void *in, size_t in_nbytes,
			      void *out, size_t out_nbytes_avail,
			      size_t *actual_in_nbytes_ret,
			      size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_gzip_decompress(struct libdeflate_decompressor *decompressor,
			   const void *in, size_t in_nbytes,
			   void *out, size_t out_nbytes_avail,
			   size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_gzip_decompress_ex(struct libdeflate_decompressor *decompressor,
			      const void *in, size_t in_nbytes,
			      void *out, size_t out_nbytes_avail,
			      size_t *actual_in_nbytes_ret,
			      size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT void LIBDEFLATEAPI
libdeflate_free_decompressor(struct libdeflate_decompressor *decompressor);






LIBDEFLATEEXPORT uint32_t LIBDEFLATEAPI
libdeflate_adler32(uint32_t adler, const void *buffer, size_t len);



LIBDEFLATEEXPORT uint32_t LIBDEFLATEAPI
libdeflate_crc32(uint32_t crc, const void *buffer, size_t len);






LIBDEFLATEEXPORT void LIBDEFLATEAPI
libdeflate_set_memory_allocator(void *(*malloc_func)(size_t),
				void (*free_func)(void *));

#ifdef __cplusplus
}
#endif

#endif 


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_zlib_compress(struct libdeflate_compressor *c,
			 const void *in, size_t in_nbytes,
			 void *out, size_t out_nbytes_avail)
{
	u8 *out_next = out;
	u16 hdr;
	unsigned compression_level;
	unsigned level_hint;
	size_t deflate_size;

	if (out_nbytes_avail <= ZLIB_MIN_OVERHEAD)
		return 0;

	
	hdr = (ZLIB_CM_DEFLATE << 8) | (ZLIB_CINFO_32K_WINDOW << 12);
	compression_level = deflate_get_compression_level(c);
	if (compression_level < 2)
		level_hint = ZLIB_FASTEST_COMPRESSION;
	else if (compression_level < 6)
		level_hint = ZLIB_FAST_COMPRESSION;
	else if (compression_level < 8)
		level_hint = ZLIB_DEFAULT_COMPRESSION;
	else
		level_hint = ZLIB_SLOWEST_COMPRESSION;
	hdr |= level_hint << 6;
	hdr |= 31 - (hdr % 31);

	put_unaligned_be16(hdr, out_next);
	out_next += 2;

	
	deflate_size = libdeflate_deflate_compress(c, in, in_nbytes, out_next,
					out_nbytes_avail - ZLIB_MIN_OVERHEAD);
	if (deflate_size == 0)
		return 0;
	out_next += deflate_size;

	
	put_unaligned_be32(libdeflate_adler32(1, in, in_nbytes), out_next);
	out_next += 4;

	return out_next - (u8 *)out;
}

LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_zlib_compress_bound(struct libdeflate_compressor *c,
			       size_t in_nbytes)
{
	return ZLIB_MIN_OVERHEAD +
	       libdeflate_deflate_compress_bound(c, in_nbytes);
}
/* /usr/home/ben/projects/gzip-libdeflate/../../software/libdeflate-1.7/lib/zlib_decompress.c */


/* #include "unaligned.h" */


#ifndef LIB_UNALIGNED_H
#define LIB_UNALIGNED_H

/* #include "lib_common.h" */


#ifndef LIB_LIB_COMMON_H
#define LIB_LIB_COMMON_H

#ifdef LIBDEFLATE_H
#  error "lib_common.h must always be included before libdeflate.h"
   
#endif

#define BUILDING_LIBDEFLATE

/* #include "../common/common_defs.h" */


#ifndef COMMON_COMMON_DEFS_H
#define COMMON_COMMON_DEFS_H

#ifdef __GNUC__
/* #  include "compiler_gcc.h" */


#if !defined(__clang__) && !defined(__INTEL_COMPILER)
#  define GCC_PREREQ(major, minor)		\
	(__GNUC__ > (major) ||			\
	 (__GNUC__ == (major) && __GNUC_MINOR__ >= (minor)))
#else
#  define GCC_PREREQ(major, minor)	0
#endif


#ifdef __clang__
#  ifdef __apple_build_version__
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__apple_build_version__ >= (apple_version))
#  else
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__clang_major__ > (major) ||			\
	 (__clang_major__ == (major) && __clang_minor__ >= (minor)))
#  endif
#else
#  define CLANG_PREREQ(major, minor, apple_version)	0
#endif

#ifndef __has_attribute
#  define __has_attribute(attribute)	0
#endif
#ifndef __has_feature
#  define __has_feature(feature)	0
#endif
#ifndef __has_builtin
#  define __has_builtin(builtin)	0
#endif

#ifdef _WIN32
#  define LIBEXPORT __declspec(dllexport)
#else
#  define LIBEXPORT __attribute__((visibility("default")))
#endif

#define inline			inline
#define forceinline		inline __attribute__((always_inline))
#define restrict		__restrict__
#define likely(expr)		__builtin_expect(!!(expr), 1)
#define unlikely(expr)		__builtin_expect(!!(expr), 0)
#define prefetchr(addr)		__builtin_prefetch((addr), 0)
#define prefetchw(addr)		__builtin_prefetch((addr), 1)
#define _aligned_attribute(n)	__attribute__((aligned(n)))

#define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE	\
	(GCC_PREREQ(4, 4) || __has_attribute(target))

#if COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE

#  if defined(__i386__) || defined(__x86_64__)

#    define COMPILER_SUPPORTS_PCLMUL_TARGET	\
	(GCC_PREREQ(4, 4) || __has_builtin(__builtin_ia32_pclmulqdq128))

#    define COMPILER_SUPPORTS_AVX_TARGET	\
	(GCC_PREREQ(4, 6) || __has_builtin(__builtin_ia32_maxps256))

#    define COMPILER_SUPPORTS_BMI2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_pdep_di))

#    define COMPILER_SUPPORTS_AVX2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_psadbw256))

#    define COMPILER_SUPPORTS_AVX512BW_TARGET	\
	(GCC_PREREQ(5, 1) || __has_builtin(__builtin_ia32_psadbw512))

	
#    if GCC_PREREQ(4, 9) || CLANG_PREREQ(3, 8, 7030000)
#      define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS	1
#      define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_PCLMUL_TARGET
#      define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX2_TARGET
#      define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX512BW_TARGET
#    endif

#  elif defined(__arm__) || defined(__aarch64__)

    
#    if (GCC_PREREQ(6, 1) && defined(__ARM_FP)) || \
        (defined(__clang__) && defined(__ARM_NEON))
#      define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 1
       
#      if defined(__clang__) && defined(__arm__)
#        undef __ARM_FEATURE_CRYPTO
#      elif __has_builtin(__builtin_neon_vmull_p64) || !defined(__clang__)
#        define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 1
#      endif
#    endif

     
#    if GCC_PREREQ(10, 1) || \
        (GCC_PREREQ(9, 3) && !GCC_PREREQ(10, 0)) || \
        (GCC_PREREQ(8, 4) && !GCC_PREREQ(9, 0)) || \
        (defined(__clang__) && __has_builtin(__builtin_arm_crc32b))
#      define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 1
#    endif

#  endif 

#endif 


#if (GCC_PREREQ(4, 0) && !GCC_PREREQ(5, 1)) || \
    (defined(__clang__) && !CLANG_PREREQ(3, 9, 8020000))
typedef unsigned long long  __v2du __attribute__((__vector_size__(16)));
typedef unsigned int        __v4su __attribute__((__vector_size__(16)));
typedef unsigned short      __v8hu __attribute__((__vector_size__(16)));
typedef unsigned char      __v16qu __attribute__((__vector_size__(16)));
typedef unsigned long long  __v4du __attribute__((__vector_size__(32)));
typedef unsigned int        __v8su __attribute__((__vector_size__(32)));
typedef unsigned short     __v16hu __attribute__((__vector_size__(32)));
typedef unsigned char      __v32qu __attribute__((__vector_size__(32)));
#endif


#ifdef __BYTE_ORDER__
#  define CPU_IS_LITTLE_ENDIAN() (__BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__)
#endif

#if GCC_PREREQ(4, 8) || __has_builtin(__builtin_bswap16)
#  define bswap16	__builtin_bswap16
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap32)
#  define bswap32	__builtin_bswap32
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap64)
#  define bswap64	__builtin_bswap64
#endif

#if defined(__x86_64__) || defined(__i386__) || defined(__ARM_FEATURE_UNALIGNED) || defined(__powerpc64__)
#  define UNALIGNED_ACCESS_IS_FAST 1
#endif

#define bsr32(n)	(31 - __builtin_clz(n))
#define bsr64(n)	(63 - __builtin_clzll(n))
#define bsf32(n)	__builtin_ctz(n)
#define bsf64(n)	__builtin_ctzll(n)

#elif defined(_MSC_VER)
/* #  include "compiler_msc.h" */


#include <stdint.h>
#include <stdlib.h> 

#define LIBEXPORT	__declspec(dllexport)


typedef int bool;
#define true 1
#define false 0
#define __bool_true_false_are_defined 1


#ifdef _WIN64
typedef long long ssize_t;
#else
typedef int ssize_t;
#endif


#define CPU_IS_LITTLE_ENDIAN()		1
#define UNALIGNED_ACCESS_IS_FAST	1


#define restrict


#define inline		__inline
#define forceinline	__forceinline


#define bswap16	_byteswap_ushort
#define bswap32	_byteswap_ulong
#define bswap64	_byteswap_uint64



static forceinline unsigned
bsr32(uint32_t n)
{
	_BitScanReverse(&n, n);
	return n;
}
#define bsr32 bsr32

static forceinline unsigned
bsf32(uint32_t n)
{
	_BitScanForward(&n, n);
	return n;
}
#define bsf32 bsf32

#ifdef _M_X64 

static forceinline unsigned
bsr64(uint64_t n)
{
	_BitScanReverse64(&n, n);
	return n;
}
#define bsr64 bsr64

static forceinline unsigned
bsf64(uint64_t n)
{
	_BitScanForward64(&n, n);
	return n;
}
#define bsf64 bsf64

#endif 

#else
#  pragma message("Unrecognized compiler.  Please add a header file for your compiler.  Compilation will proceed, but performance may suffer!")
#endif





#include <stddef.h> 

#ifndef __bool_true_false_are_defined
#  include <stdbool.h> 
#endif


#include <stdint.h>
typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
typedef int8_t s8;
typedef int16_t s16;
typedef int32_t s32;
typedef int64_t s64;


typedef size_t machine_word_t;


#define WORDBYTES	((int)sizeof(machine_word_t))


#define WORDBITS	(8 * WORDBYTES)






#ifndef LIBEXPORT
#  define LIBEXPORT
#endif


#ifndef inline
#  define inline
#endif


#ifndef forceinline
#  define forceinline inline
#endif


#ifndef restrict
#  define restrict
#endif


#ifndef likely
#  define likely(expr)		(expr)
#endif


#ifndef unlikely
#  define unlikely(expr)	(expr)
#endif


#ifndef prefetchr
#  define prefetchr(addr)
#endif


#ifndef prefetchw
#  define prefetchw(addr)
#endif


#ifndef COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE
#  define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE 0
#endif


#ifndef COMPILER_SUPPORTS_BMI2_TARGET
#  define COMPILER_SUPPORTS_BMI2_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX_TARGET
#  define COMPILER_SUPPORTS_AVX_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET
#  define COMPILER_SUPPORTS_AVX512BW_TARGET 0
#endif


#ifndef COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 0
#endif


#ifndef _aligned_attribute
#endif





#define ARRAY_LEN(A)		(sizeof(A) / sizeof((A)[0]))
#define MIN(a, b)		((a) <= (b) ? (a) : (b))
#define MAX(a, b)		((a) >= (b) ? (a) : (b))
#define DIV_ROUND_UP(n, d)	(((n) + (d) - 1) / (d))
#define STATIC_ASSERT(expr)	((void)sizeof(char[1 - 2 * !(expr)]))
#define ALIGN(n, a)		(((n) + (a) - 1) & ~((a) - 1))






#ifndef CPU_IS_LITTLE_ENDIAN
static forceinline int CPU_IS_LITTLE_ENDIAN(void)
{
	union {
		unsigned int v;
		unsigned char b;
	} u;
	u.v = 1;
	return u.b;
}
#endif


#ifndef bswap16
static forceinline u16 bswap16(u16 n)
{
	return (n << 8) | (n >> 8);
}
#endif


#ifndef bswap32
static forceinline u32 bswap32(u32 n)
{
	return ((n & 0x000000FF) << 24) |
	       ((n & 0x0000FF00) << 8) |
	       ((n & 0x00FF0000) >> 8) |
	       ((n & 0xFF000000) >> 24);
}
#endif


#ifndef bswap64
static forceinline u64 bswap64(u64 n)
{
	return ((n & 0x00000000000000FF) << 56) |
	       ((n & 0x000000000000FF00) << 40) |
	       ((n & 0x0000000000FF0000) << 24) |
	       ((n & 0x00000000FF000000) << 8) |
	       ((n & 0x000000FF00000000) >> 8) |
	       ((n & 0x0000FF0000000000) >> 24) |
	       ((n & 0x00FF000000000000) >> 40) |
	       ((n & 0xFF00000000000000) >> 56);
}
#endif

#define le16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap16(n))
#define le32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap32(n))
#define le64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap64(n))
#define be16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap16(n) : (n))
#define be32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap32(n) : (n))
#define be64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap64(n) : (n))






#ifndef UNALIGNED_ACCESS_IS_FAST
#  define UNALIGNED_ACCESS_IS_FAST 0
#endif







#ifndef bsr32
static forceinline unsigned
bsr32(u32 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

#ifndef bsr64
static forceinline unsigned
bsr64(u64 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

static forceinline unsigned
bsrw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsr32(n);
	else
		return bsr64(n);
}



#ifndef bsf32
static forceinline unsigned
bsf32(u32 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

#ifndef bsf64
static forceinline unsigned
bsf64(u64 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

static forceinline unsigned
bsfw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsf32(n);
	else
		return bsf64(n);
}

#endif 



#define SYM_FIXUP(sym)			_libdeflate_##sym
#define deflate_get_compression_level	SYM_FIXUP(deflate_get_compression_level)
#define _cpu_features			SYM_FIXUP(_cpu_features)
#define setup_cpu_features		SYM_FIXUP(setup_cpu_features)

void *libdeflate_malloc(size_t size);
void libdeflate_free(void *ptr);

void *libdeflate_aligned_malloc(size_t alignment, size_t size);
void libdeflate_aligned_free(void *ptr);

#ifdef FREESTANDING

void *memset(void *s, int c, size_t n);
#define memset(s, c, n)		__builtin_memset((s), (c), (n))

void *memcpy(void *dest, const void *src, size_t n);
#define memcpy(dest, src, n)	__builtin_memcpy((dest), (src), (n))

void *memmove(void *dest, const void *src, size_t n);
#define memmove(dest, src, n)	__builtin_memmove((dest), (src), (n))

int memcmp(const void *s1, const void *s2, size_t n);
#define memcmp(s1, s2, n)	__builtin_memcmp((s1), (s2), (n))
#else
#include <string.h>
#endif

#endif 






#define DEFINE_UNALIGNED_TYPE(type)				\
static forceinline type						\
load_##type##_unaligned(const void *p)				\
{								\
	type v;							\
	memcpy(&v, p, sizeof(v));				\
	return v;						\
}								\
								\
static forceinline void						\
store_##type##_unaligned(type v, void *p)			\
{								\
	memcpy(p, &v, sizeof(v));				\
}

DEFINE_UNALIGNED_TYPE(u16)
DEFINE_UNALIGNED_TYPE(u32)
DEFINE_UNALIGNED_TYPE(u64)
DEFINE_UNALIGNED_TYPE(machine_word_t)

#define load_word_unaligned	load_machine_word_t_unaligned
#define store_word_unaligned	store_machine_word_t_unaligned



static forceinline u16
get_unaligned_le16(const u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST)
		return le16_bswap(load_u16_unaligned(p));
	else
		return ((u16)p[1] << 8) | p[0];
}

static forceinline u16
get_unaligned_be16(const u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST)
		return be16_bswap(load_u16_unaligned(p));
	else
		return ((u16)p[0] << 8) | p[1];
}

static forceinline u32
get_unaligned_le32(const u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST)
		return le32_bswap(load_u32_unaligned(p));
	else
		return ((u32)p[3] << 24) | ((u32)p[2] << 16) |
			((u32)p[1] << 8) | p[0];
}

static forceinline u32
get_unaligned_be32(const u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST)
		return be32_bswap(load_u32_unaligned(p));
	else
		return ((u32)p[0] << 24) | ((u32)p[1] << 16) |
			((u32)p[2] << 8) | p[3];
}

static forceinline u64
get_unaligned_le64(const u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST)
		return le64_bswap(load_u64_unaligned(p));
	else
		return ((u64)p[7] << 56) | ((u64)p[6] << 48) |
			((u64)p[5] << 40) | ((u64)p[4] << 32) |
			((u64)p[3] << 24) | ((u64)p[2] << 16) |
			((u64)p[1] << 8) | p[0];
}

static forceinline machine_word_t
get_unaligned_leword(const u8 *p)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return get_unaligned_le32(p);
	else
		return get_unaligned_le64(p);
}



static forceinline void
put_unaligned_le16(u16 v, u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST) {
		store_u16_unaligned(le16_bswap(v), p);
	} else {
		p[0] = (u8)(v >> 0);
		p[1] = (u8)(v >> 8);
	}
}

static forceinline void
put_unaligned_be16(u16 v, u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST) {
		store_u16_unaligned(be16_bswap(v), p);
	} else {
		p[0] = (u8)(v >> 8);
		p[1] = (u8)(v >> 0);
	}
}

static forceinline void
put_unaligned_le32(u32 v, u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST) {
		store_u32_unaligned(le32_bswap(v), p);
	} else {
		p[0] = (u8)(v >> 0);
		p[1] = (u8)(v >> 8);
		p[2] = (u8)(v >> 16);
		p[3] = (u8)(v >> 24);
	}
}

static forceinline void
put_unaligned_be32(u32 v, u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST) {
		store_u32_unaligned(be32_bswap(v), p);
	} else {
		p[0] = (u8)(v >> 24);
		p[1] = (u8)(v >> 16);
		p[2] = (u8)(v >> 8);
		p[3] = (u8)(v >> 0);
	}
}

static forceinline void
put_unaligned_le64(u64 v, u8 *p)
{
	if (UNALIGNED_ACCESS_IS_FAST) {
		store_u64_unaligned(le64_bswap(v), p);
	} else {
		p[0] = (u8)(v >> 0);
		p[1] = (u8)(v >> 8);
		p[2] = (u8)(v >> 16);
		p[3] = (u8)(v >> 24);
		p[4] = (u8)(v >> 32);
		p[5] = (u8)(v >> 40);
		p[6] = (u8)(v >> 48);
		p[7] = (u8)(v >> 56);
	}
}

static forceinline void
put_unaligned_leword(machine_word_t v, u8 *p)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		put_unaligned_le32(v, p);
	else
		put_unaligned_le64(v, p);
}




static forceinline u32
loaded_u32_to_u24(u32 v)
{
	if (CPU_IS_LITTLE_ENDIAN())
		return v & 0xFFFFFF;
	else
		return v >> 8;
}


static forceinline u32
load_u24_unaligned(const u8 *p)
{
#if UNALIGNED_ACCESS_IS_FAST
#  define LOAD_U24_REQUIRED_NBYTES 4
	return loaded_u32_to_u24(load_u32_unaligned(p));
#else
#  define LOAD_U24_REQUIRED_NBYTES 3
	if (CPU_IS_LITTLE_ENDIAN())
		return ((u32)p[0] << 0) | ((u32)p[1] << 8) | ((u32)p[2] << 16);
	else
		return ((u32)p[2] << 0) | ((u32)p[1] << 8) | ((u32)p[0] << 16);
#endif
}

#endif 

/* #include "zlib_constants.h" */


#ifndef LIB_ZLIB_CONSTANTS_H
#define LIB_ZLIB_CONSTANTS_H

#define ZLIB_MIN_HEADER_SIZE	2
#define ZLIB_FOOTER_SIZE	4
#define ZLIB_MIN_OVERHEAD	(ZLIB_MIN_HEADER_SIZE + ZLIB_FOOTER_SIZE)

#define ZLIB_CM_DEFLATE		8

#define ZLIB_CINFO_32K_WINDOW	7

#define ZLIB_FASTEST_COMPRESSION	0
#define ZLIB_FAST_COMPRESSION		1
#define ZLIB_DEFAULT_COMPRESSION	2
#define ZLIB_SLOWEST_COMPRESSION	3

#endif 


/* #include "libdeflate.h" */


#ifndef LIBDEFLATE_H
#define LIBDEFLATE_H

#ifdef __cplusplus
extern "C" {
#endif

#define LIBDEFLATE_VERSION_MAJOR	1
#define LIBDEFLATE_VERSION_MINOR	7
#define LIBDEFLATE_VERSION_STRING	"1.7"

#include <stddef.h>
#include <stdint.h>


#ifdef LIBDEFLATE_DLL
#  ifdef BUILDING_LIBDEFLATE
#    define LIBDEFLATEEXPORT	LIBEXPORT
#  elif defined(_WIN32) || defined(__CYGWIN__)
#    define LIBDEFLATEEXPORT	__declspec(dllimport)
#  endif
#endif
#ifndef LIBDEFLATEEXPORT
#  define LIBDEFLATEEXPORT
#endif

#if defined(_WIN32) && !defined(_WIN64)
#  define LIBDEFLATEAPI_ABI	__stdcall
#else
#  define LIBDEFLATEAPI_ABI
#endif

#if defined(BUILDING_LIBDEFLATE) && defined(__GNUC__) && \
	defined(_WIN32) && !defined(_WIN64)
    
#  define LIBDEFLATEAPI_STACKALIGN	__attribute__((force_align_arg_pointer))
#else
#  define LIBDEFLATEAPI_STACKALIGN
#endif

#define LIBDEFLATEAPI	LIBDEFLATEAPI_ABI LIBDEFLATEAPI_STACKALIGN





struct libdeflate_compressor;


LIBDEFLATEEXPORT struct libdeflate_compressor * LIBDEFLATEAPI
libdeflate_alloc_compressor(int compression_level);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_deflate_compress(struct libdeflate_compressor *compressor,
			    const void *in, size_t in_nbytes,
			    void *out, size_t out_nbytes_avail);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_deflate_compress_bound(struct libdeflate_compressor *compressor,
				  size_t in_nbytes);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_zlib_compress(struct libdeflate_compressor *compressor,
			 const void *in, size_t in_nbytes,
			 void *out, size_t out_nbytes_avail);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_zlib_compress_bound(struct libdeflate_compressor *compressor,
			       size_t in_nbytes);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_gzip_compress(struct libdeflate_compressor *compressor,
			 const void *in, size_t in_nbytes,
			 void *out, size_t out_nbytes_avail);


LIBDEFLATEEXPORT size_t LIBDEFLATEAPI
libdeflate_gzip_compress_bound(struct libdeflate_compressor *compressor,
			       size_t in_nbytes);


LIBDEFLATEEXPORT void LIBDEFLATEAPI
libdeflate_free_compressor(struct libdeflate_compressor *compressor);





struct libdeflate_decompressor;


LIBDEFLATEEXPORT struct libdeflate_decompressor * LIBDEFLATEAPI
libdeflate_alloc_decompressor(void);


enum libdeflate_result {
	
	LIBDEFLATE_SUCCESS = 0,

	
	LIBDEFLATE_BAD_DATA = 1,

	
	LIBDEFLATE_SHORT_OUTPUT = 2,

	
	LIBDEFLATE_INSUFFICIENT_SPACE = 3,
};


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_deflate_decompress(struct libdeflate_decompressor *decompressor,
			      const void *in, size_t in_nbytes,
			      void *out, size_t out_nbytes_avail,
			      size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_deflate_decompress_ex(struct libdeflate_decompressor *decompressor,
				 const void *in, size_t in_nbytes,
				 void *out, size_t out_nbytes_avail,
				 size_t *actual_in_nbytes_ret,
				 size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_zlib_decompress(struct libdeflate_decompressor *decompressor,
			   const void *in, size_t in_nbytes,
			   void *out, size_t out_nbytes_avail,
			   size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_zlib_decompress_ex(struct libdeflate_decompressor *decompressor,
			      const void *in, size_t in_nbytes,
			      void *out, size_t out_nbytes_avail,
			      size_t *actual_in_nbytes_ret,
			      size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_gzip_decompress(struct libdeflate_decompressor *decompressor,
			   const void *in, size_t in_nbytes,
			   void *out, size_t out_nbytes_avail,
			   size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_gzip_decompress_ex(struct libdeflate_decompressor *decompressor,
			      const void *in, size_t in_nbytes,
			      void *out, size_t out_nbytes_avail,
			      size_t *actual_in_nbytes_ret,
			      size_t *actual_out_nbytes_ret);


LIBDEFLATEEXPORT void LIBDEFLATEAPI
libdeflate_free_decompressor(struct libdeflate_decompressor *decompressor);






LIBDEFLATEEXPORT uint32_t LIBDEFLATEAPI
libdeflate_adler32(uint32_t adler, const void *buffer, size_t len);



LIBDEFLATEEXPORT uint32_t LIBDEFLATEAPI
libdeflate_crc32(uint32_t crc, const void *buffer, size_t len);






LIBDEFLATEEXPORT void LIBDEFLATEAPI
libdeflate_set_memory_allocator(void *(*malloc_func)(size_t),
				void (*free_func)(void *));

#ifdef __cplusplus
}
#endif

#endif 


LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_zlib_decompress_ex(struct libdeflate_decompressor *d,
			      const void *in, size_t in_nbytes,
			      void *out, size_t out_nbytes_avail,
			      size_t *actual_in_nbytes_ret,
			      size_t *actual_out_nbytes_ret)
{
	const u8 *in_next = in;
	const u8 * const in_end = in_next + in_nbytes;
	u16 hdr;
	size_t actual_in_nbytes;
	size_t actual_out_nbytes;
	enum libdeflate_result result;

	if (in_nbytes < ZLIB_MIN_OVERHEAD)
		return LIBDEFLATE_BAD_DATA;

	
	hdr = get_unaligned_be16(in_next);
	in_next += 2;

	
	if ((hdr % 31) != 0)
		return LIBDEFLATE_BAD_DATA;

	
	if (((hdr >> 8) & 0xF) != ZLIB_CM_DEFLATE)
		return LIBDEFLATE_BAD_DATA;

	
	if ((hdr >> 12) > ZLIB_CINFO_32K_WINDOW)
		return LIBDEFLATE_BAD_DATA;

	
	if ((hdr >> 5) & 1)
		return LIBDEFLATE_BAD_DATA;

	
	result = libdeflate_deflate_decompress_ex(d, in_next,
					in_end - ZLIB_FOOTER_SIZE - in_next,
					out, out_nbytes_avail,
					&actual_in_nbytes, actual_out_nbytes_ret);
	if (result != LIBDEFLATE_SUCCESS)
		return result;

	if (actual_out_nbytes_ret)
		actual_out_nbytes = *actual_out_nbytes_ret;
	else
		actual_out_nbytes = out_nbytes_avail;

	in_next += actual_in_nbytes;

	
	if (libdeflate_adler32(1, out, actual_out_nbytes) !=
	    get_unaligned_be32(in_next))
		return LIBDEFLATE_BAD_DATA;
	in_next += 4;

	if (actual_in_nbytes_ret)
		*actual_in_nbytes_ret = in_next - (u8 *)in;

	return LIBDEFLATE_SUCCESS;
}

LIBDEFLATEEXPORT enum libdeflate_result LIBDEFLATEAPI
libdeflate_zlib_decompress(struct libdeflate_decompressor *d,
			   const void *in, size_t in_nbytes,
			   void *out, size_t out_nbytes_avail,
			   size_t *actual_out_nbytes_ret)
{
	return libdeflate_zlib_decompress_ex(d, in, in_nbytes,
					     out, out_nbytes_avail,
					     NULL, actual_out_nbytes_ret);
}
/* /usr/home/ben/projects/gzip-libdeflate/../../software/libdeflate-1.7/lib/arm/cpu_features.c */




/* #include "cpu_features_common.h" */


#if defined(TEST_SUPPORT__DO_NOT_USE) && !defined(FREESTANDING)
#  define _GNU_SOURCE 1 
#  include <stdio.h>
#  include <stdlib.h>
#  include <string.h>
#endif

/* #include "lib_common.h" */


#ifndef LIB_LIB_COMMON_H
#define LIB_LIB_COMMON_H

#ifdef LIBDEFLATE_H
#  error "lib_common.h must always be included before libdeflate.h"
   
#endif

#define BUILDING_LIBDEFLATE

/* #include "../common/common_defs.h" */


#ifndef COMMON_COMMON_DEFS_H
#define COMMON_COMMON_DEFS_H

#ifdef __GNUC__
/* #  include "compiler_gcc.h" */


#if !defined(__clang__) && !defined(__INTEL_COMPILER)
#  define GCC_PREREQ(major, minor)		\
	(__GNUC__ > (major) ||			\
	 (__GNUC__ == (major) && __GNUC_MINOR__ >= (minor)))
#else
#  define GCC_PREREQ(major, minor)	0
#endif


#ifdef __clang__
#  ifdef __apple_build_version__
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__apple_build_version__ >= (apple_version))
#  else
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__clang_major__ > (major) ||			\
	 (__clang_major__ == (major) && __clang_minor__ >= (minor)))
#  endif
#else
#  define CLANG_PREREQ(major, minor, apple_version)	0
#endif

#ifndef __has_attribute
#  define __has_attribute(attribute)	0
#endif
#ifndef __has_feature
#  define __has_feature(feature)	0
#endif
#ifndef __has_builtin
#  define __has_builtin(builtin)	0
#endif

#ifdef _WIN32
#  define LIBEXPORT __declspec(dllexport)
#else
#  define LIBEXPORT __attribute__((visibility("default")))
#endif

#define inline			inline
#define forceinline		inline __attribute__((always_inline))
#define restrict		__restrict__
#define likely(expr)		__builtin_expect(!!(expr), 1)
#define unlikely(expr)		__builtin_expect(!!(expr), 0)
#define prefetchr(addr)		__builtin_prefetch((addr), 0)
#define prefetchw(addr)		__builtin_prefetch((addr), 1)
#define _aligned_attribute(n)	__attribute__((aligned(n)))

#define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE	\
	(GCC_PREREQ(4, 4) || __has_attribute(target))

#if COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE

#  if defined(__i386__) || defined(__x86_64__)

#    define COMPILER_SUPPORTS_PCLMUL_TARGET	\
	(GCC_PREREQ(4, 4) || __has_builtin(__builtin_ia32_pclmulqdq128))

#    define COMPILER_SUPPORTS_AVX_TARGET	\
	(GCC_PREREQ(4, 6) || __has_builtin(__builtin_ia32_maxps256))

#    define COMPILER_SUPPORTS_BMI2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_pdep_di))

#    define COMPILER_SUPPORTS_AVX2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_psadbw256))

#    define COMPILER_SUPPORTS_AVX512BW_TARGET	\
	(GCC_PREREQ(5, 1) || __has_builtin(__builtin_ia32_psadbw512))

	
#    if GCC_PREREQ(4, 9) || CLANG_PREREQ(3, 8, 7030000)
#      define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS	1
#      define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_PCLMUL_TARGET
#      define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX2_TARGET
#      define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX512BW_TARGET
#    endif

#  elif defined(__arm__) || defined(__aarch64__)

    
#    if (GCC_PREREQ(6, 1) && defined(__ARM_FP)) || \
        (defined(__clang__) && defined(__ARM_NEON))
#      define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 1
       
#      if defined(__clang__) && defined(__arm__)
#        undef __ARM_FEATURE_CRYPTO
#      elif __has_builtin(__builtin_neon_vmull_p64) || !defined(__clang__)
#        define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 1
#      endif
#    endif

     
#    if GCC_PREREQ(10, 1) || \
        (GCC_PREREQ(9, 3) && !GCC_PREREQ(10, 0)) || \
        (GCC_PREREQ(8, 4) && !GCC_PREREQ(9, 0)) || \
        (defined(__clang__) && __has_builtin(__builtin_arm_crc32b))
#      define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 1
#    endif

#  endif 

#endif 


#if (GCC_PREREQ(4, 0) && !GCC_PREREQ(5, 1)) || \
    (defined(__clang__) && !CLANG_PREREQ(3, 9, 8020000))
typedef unsigned long long  __v2du __attribute__((__vector_size__(16)));
typedef unsigned int        __v4su __attribute__((__vector_size__(16)));
typedef unsigned short      __v8hu __attribute__((__vector_size__(16)));
typedef unsigned char      __v16qu __attribute__((__vector_size__(16)));
typedef unsigned long long  __v4du __attribute__((__vector_size__(32)));
typedef unsigned int        __v8su __attribute__((__vector_size__(32)));
typedef unsigned short     __v16hu __attribute__((__vector_size__(32)));
typedef unsigned char      __v32qu __attribute__((__vector_size__(32)));
#endif


#ifdef __BYTE_ORDER__
#  define CPU_IS_LITTLE_ENDIAN() (__BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__)
#endif

#if GCC_PREREQ(4, 8) || __has_builtin(__builtin_bswap16)
#  define bswap16	__builtin_bswap16
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap32)
#  define bswap32	__builtin_bswap32
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap64)
#  define bswap64	__builtin_bswap64
#endif

#if defined(__x86_64__) || defined(__i386__) || defined(__ARM_FEATURE_UNALIGNED) || defined(__powerpc64__)
#  define UNALIGNED_ACCESS_IS_FAST 1
#endif

#define bsr32(n)	(31 - __builtin_clz(n))
#define bsr64(n)	(63 - __builtin_clzll(n))
#define bsf32(n)	__builtin_ctz(n)
#define bsf64(n)	__builtin_ctzll(n)

#elif defined(_MSC_VER)
/* #  include "compiler_msc.h" */


#include <stdint.h>
#include <stdlib.h> 

#define LIBEXPORT	__declspec(dllexport)


typedef int bool;
#define true 1
#define false 0
#define __bool_true_false_are_defined 1


#ifdef _WIN64
typedef long long ssize_t;
#else
typedef int ssize_t;
#endif


#define CPU_IS_LITTLE_ENDIAN()		1
#define UNALIGNED_ACCESS_IS_FAST	1


#define restrict


#define inline		__inline
#define forceinline	__forceinline


#define bswap16	_byteswap_ushort
#define bswap32	_byteswap_ulong
#define bswap64	_byteswap_uint64



static forceinline unsigned
bsr32(uint32_t n)
{
	_BitScanReverse(&n, n);
	return n;
}
#define bsr32 bsr32

static forceinline unsigned
bsf32(uint32_t n)
{
	_BitScanForward(&n, n);
	return n;
}
#define bsf32 bsf32

#ifdef _M_X64 

static forceinline unsigned
bsr64(uint64_t n)
{
	_BitScanReverse64(&n, n);
	return n;
}
#define bsr64 bsr64

static forceinline unsigned
bsf64(uint64_t n)
{
	_BitScanForward64(&n, n);
	return n;
}
#define bsf64 bsf64

#endif 

#else
#  pragma message("Unrecognized compiler.  Please add a header file for your compiler.  Compilation will proceed, but performance may suffer!")
#endif





#include <stddef.h> 

#ifndef __bool_true_false_are_defined
#  include <stdbool.h> 
#endif


#include <stdint.h>
typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
typedef int8_t s8;
typedef int16_t s16;
typedef int32_t s32;
typedef int64_t s64;


typedef size_t machine_word_t;


#define WORDBYTES	((int)sizeof(machine_word_t))


#define WORDBITS	(8 * WORDBYTES)






#ifndef LIBEXPORT
#  define LIBEXPORT
#endif


#ifndef inline
#  define inline
#endif


#ifndef forceinline
#  define forceinline inline
#endif


#ifndef restrict
#  define restrict
#endif


#ifndef likely
#  define likely(expr)		(expr)
#endif


#ifndef unlikely
#  define unlikely(expr)	(expr)
#endif


#ifndef prefetchr
#  define prefetchr(addr)
#endif


#ifndef prefetchw
#  define prefetchw(addr)
#endif


#ifndef COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE
#  define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE 0
#endif


#ifndef COMPILER_SUPPORTS_BMI2_TARGET
#  define COMPILER_SUPPORTS_BMI2_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX_TARGET
#  define COMPILER_SUPPORTS_AVX_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET
#  define COMPILER_SUPPORTS_AVX512BW_TARGET 0
#endif


#ifndef COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 0
#endif


#ifndef _aligned_attribute
#endif





#define ARRAY_LEN(A)		(sizeof(A) / sizeof((A)[0]))
#define MIN(a, b)		((a) <= (b) ? (a) : (b))
#define MAX(a, b)		((a) >= (b) ? (a) : (b))
#define DIV_ROUND_UP(n, d)	(((n) + (d) - 1) / (d))
#define STATIC_ASSERT(expr)	((void)sizeof(char[1 - 2 * !(expr)]))
#define ALIGN(n, a)		(((n) + (a) - 1) & ~((a) - 1))






#ifndef CPU_IS_LITTLE_ENDIAN
static forceinline int CPU_IS_LITTLE_ENDIAN(void)
{
	union {
		unsigned int v;
		unsigned char b;
	} u;
	u.v = 1;
	return u.b;
}
#endif


#ifndef bswap16
static forceinline u16 bswap16(u16 n)
{
	return (n << 8) | (n >> 8);
}
#endif


#ifndef bswap32
static forceinline u32 bswap32(u32 n)
{
	return ((n & 0x000000FF) << 24) |
	       ((n & 0x0000FF00) << 8) |
	       ((n & 0x00FF0000) >> 8) |
	       ((n & 0xFF000000) >> 24);
}
#endif


#ifndef bswap64
static forceinline u64 bswap64(u64 n)
{
	return ((n & 0x00000000000000FF) << 56) |
	       ((n & 0x000000000000FF00) << 40) |
	       ((n & 0x0000000000FF0000) << 24) |
	       ((n & 0x00000000FF000000) << 8) |
	       ((n & 0x000000FF00000000) >> 8) |
	       ((n & 0x0000FF0000000000) >> 24) |
	       ((n & 0x00FF000000000000) >> 40) |
	       ((n & 0xFF00000000000000) >> 56);
}
#endif

#define le16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap16(n))
#define le32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap32(n))
#define le64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap64(n))
#define be16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap16(n) : (n))
#define be32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap32(n) : (n))
#define be64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap64(n) : (n))






#ifndef UNALIGNED_ACCESS_IS_FAST
#  define UNALIGNED_ACCESS_IS_FAST 0
#endif







#ifndef bsr32
static forceinline unsigned
bsr32(u32 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

#ifndef bsr64
static forceinline unsigned
bsr64(u64 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

static forceinline unsigned
bsrw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsr32(n);
	else
		return bsr64(n);
}



#ifndef bsf32
static forceinline unsigned
bsf32(u32 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

#ifndef bsf64
static forceinline unsigned
bsf64(u64 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

static forceinline unsigned
bsfw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsf32(n);
	else
		return bsf64(n);
}

#endif 



#define SYM_FIXUP(sym)			_libdeflate_##sym
#define deflate_get_compression_level	SYM_FIXUP(deflate_get_compression_level)
#define _cpu_features			SYM_FIXUP(_cpu_features)
#define setup_cpu_features		SYM_FIXUP(setup_cpu_features)

void *libdeflate_malloc(size_t size);
void libdeflate_free(void *ptr);

void *libdeflate_aligned_malloc(size_t alignment, size_t size);
void libdeflate_aligned_free(void *ptr);

#ifdef FREESTANDING

void *memset(void *s, int c, size_t n);
#define memset(s, c, n)		__builtin_memset((s), (c), (n))

void *memcpy(void *dest, const void *src, size_t n);
#define memcpy(dest, src, n)	__builtin_memcpy((dest), (src), (n))

void *memmove(void *dest, const void *src, size_t n);
#define memmove(dest, src, n)	__builtin_memmove((dest), (src), (n))

int memcmp(const void *s1, const void *s2, size_t n);
#define memcmp(s1, s2, n)	__builtin_memcmp((s1), (s2), (n))
#else
#include <string.h>
#endif

#endif 


struct cpu_feature {
	u32 bit;
	const char *name;
};

#if defined(TEST_SUPPORT__DO_NOT_USE) && !defined(FREESTANDING)

static inline void
disable_cpu_features_for_testing(u32 *features,
				 const struct cpu_feature *feature_table,
				 size_t feature_table_length)
{
	char *env_value, *strbuf, *p, *saveptr = NULL;
	size_t i;

	env_value = getenv("LIBDEFLATE_DISABLE_CPU_FEATURES");
	if (!env_value)
		return;
	strbuf = strdup(env_value);
	if (!strbuf)
		abort();
	p = strtok_r(strbuf, ",", &saveptr);
	while (p) {
		for (i = 0; i < feature_table_length; i++) {
			if (strcmp(p, feature_table[i].name) == 0) {
				*features &= ~feature_table[i].bit;
				break;
			}
		}
		if (i == feature_table_length) {
			fprintf(stderr,
				"unrecognized feature in LIBDEFLATE_DISABLE_CPU_FEATURES: \"%s\"\n",
				p);
			abort();
		}
		p = strtok_r(NULL, ",", &saveptr);
	}
	free(strbuf);
}
#else 
static inline void
disable_cpu_features_for_testing(u32 *features,
				 const struct cpu_feature *feature_table,
				 size_t feature_table_length)
{
}
#endif 
 
/* #include "arm-cpu_features.h" */


#ifndef LIB_ARM_CPU_FEATURES_H
#define LIB_ARM_CPU_FEATURES_H

/* #include "lib_common.h" */


#ifndef LIB_LIB_COMMON_H
#define LIB_LIB_COMMON_H

#ifdef LIBDEFLATE_H
#  error "lib_common.h must always be included before libdeflate.h"
   
#endif

#define BUILDING_LIBDEFLATE

/* #include "../common/common_defs.h" */


#ifndef COMMON_COMMON_DEFS_H
#define COMMON_COMMON_DEFS_H

#ifdef __GNUC__
/* #  include "compiler_gcc.h" */


#if !defined(__clang__) && !defined(__INTEL_COMPILER)
#  define GCC_PREREQ(major, minor)		\
	(__GNUC__ > (major) ||			\
	 (__GNUC__ == (major) && __GNUC_MINOR__ >= (minor)))
#else
#  define GCC_PREREQ(major, minor)	0
#endif


#ifdef __clang__
#  ifdef __apple_build_version__
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__apple_build_version__ >= (apple_version))
#  else
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__clang_major__ > (major) ||			\
	 (__clang_major__ == (major) && __clang_minor__ >= (minor)))
#  endif
#else
#  define CLANG_PREREQ(major, minor, apple_version)	0
#endif

#ifndef __has_attribute
#  define __has_attribute(attribute)	0
#endif
#ifndef __has_feature
#  define __has_feature(feature)	0
#endif
#ifndef __has_builtin
#  define __has_builtin(builtin)	0
#endif

#ifdef _WIN32
#  define LIBEXPORT __declspec(dllexport)
#else
#  define LIBEXPORT __attribute__((visibility("default")))
#endif

#define inline			inline
#define forceinline		inline __attribute__((always_inline))
#define restrict		__restrict__
#define likely(expr)		__builtin_expect(!!(expr), 1)
#define unlikely(expr)		__builtin_expect(!!(expr), 0)
#define prefetchr(addr)		__builtin_prefetch((addr), 0)
#define prefetchw(addr)		__builtin_prefetch((addr), 1)
#define _aligned_attribute(n)	__attribute__((aligned(n)))

#define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE	\
	(GCC_PREREQ(4, 4) || __has_attribute(target))

#if COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE

#  if defined(__i386__) || defined(__x86_64__)

#    define COMPILER_SUPPORTS_PCLMUL_TARGET	\
	(GCC_PREREQ(4, 4) || __has_builtin(__builtin_ia32_pclmulqdq128))

#    define COMPILER_SUPPORTS_AVX_TARGET	\
	(GCC_PREREQ(4, 6) || __has_builtin(__builtin_ia32_maxps256))

#    define COMPILER_SUPPORTS_BMI2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_pdep_di))

#    define COMPILER_SUPPORTS_AVX2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_psadbw256))

#    define COMPILER_SUPPORTS_AVX512BW_TARGET	\
	(GCC_PREREQ(5, 1) || __has_builtin(__builtin_ia32_psadbw512))

	
#    if GCC_PREREQ(4, 9) || CLANG_PREREQ(3, 8, 7030000)
#      define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS	1
#      define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_PCLMUL_TARGET
#      define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX2_TARGET
#      define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX512BW_TARGET
#    endif

#  elif defined(__arm__) || defined(__aarch64__)

    
#    if (GCC_PREREQ(6, 1) && defined(__ARM_FP)) || \
        (defined(__clang__) && defined(__ARM_NEON))
#      define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 1
       
#      if defined(__clang__) && defined(__arm__)
#        undef __ARM_FEATURE_CRYPTO
#      elif __has_builtin(__builtin_neon_vmull_p64) || !defined(__clang__)
#        define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 1
#      endif
#    endif

     
#    if GCC_PREREQ(10, 1) || \
        (GCC_PREREQ(9, 3) && !GCC_PREREQ(10, 0)) || \
        (GCC_PREREQ(8, 4) && !GCC_PREREQ(9, 0)) || \
        (defined(__clang__) && __has_builtin(__builtin_arm_crc32b))
#      define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 1
#    endif

#  endif 

#endif 


#if (GCC_PREREQ(4, 0) && !GCC_PREREQ(5, 1)) || \
    (defined(__clang__) && !CLANG_PREREQ(3, 9, 8020000))
typedef unsigned long long  __v2du __attribute__((__vector_size__(16)));
typedef unsigned int        __v4su __attribute__((__vector_size__(16)));
typedef unsigned short      __v8hu __attribute__((__vector_size__(16)));
typedef unsigned char      __v16qu __attribute__((__vector_size__(16)));
typedef unsigned long long  __v4du __attribute__((__vector_size__(32)));
typedef unsigned int        __v8su __attribute__((__vector_size__(32)));
typedef unsigned short     __v16hu __attribute__((__vector_size__(32)));
typedef unsigned char      __v32qu __attribute__((__vector_size__(32)));
#endif


#ifdef __BYTE_ORDER__
#  define CPU_IS_LITTLE_ENDIAN() (__BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__)
#endif

#if GCC_PREREQ(4, 8) || __has_builtin(__builtin_bswap16)
#  define bswap16	__builtin_bswap16
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap32)
#  define bswap32	__builtin_bswap32
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap64)
#  define bswap64	__builtin_bswap64
#endif

#if defined(__x86_64__) || defined(__i386__) || defined(__ARM_FEATURE_UNALIGNED) || defined(__powerpc64__)
#  define UNALIGNED_ACCESS_IS_FAST 1
#endif

#define bsr32(n)	(31 - __builtin_clz(n))
#define bsr64(n)	(63 - __builtin_clzll(n))
#define bsf32(n)	__builtin_ctz(n)
#define bsf64(n)	__builtin_ctzll(n)

#elif defined(_MSC_VER)
/* #  include "compiler_msc.h" */


#include <stdint.h>
#include <stdlib.h> 

#define LIBEXPORT	__declspec(dllexport)


typedef int bool;
#define true 1
#define false 0
#define __bool_true_false_are_defined 1


#ifdef _WIN64
typedef long long ssize_t;
#else
typedef int ssize_t;
#endif


#define CPU_IS_LITTLE_ENDIAN()		1
#define UNALIGNED_ACCESS_IS_FAST	1


#define restrict


#define inline		__inline
#define forceinline	__forceinline


#define bswap16	_byteswap_ushort
#define bswap32	_byteswap_ulong
#define bswap64	_byteswap_uint64



static forceinline unsigned
bsr32(uint32_t n)
{
	_BitScanReverse(&n, n);
	return n;
}
#define bsr32 bsr32

static forceinline unsigned
bsf32(uint32_t n)
{
	_BitScanForward(&n, n);
	return n;
}
#define bsf32 bsf32

#ifdef _M_X64 

static forceinline unsigned
bsr64(uint64_t n)
{
	_BitScanReverse64(&n, n);
	return n;
}
#define bsr64 bsr64

static forceinline unsigned
bsf64(uint64_t n)
{
	_BitScanForward64(&n, n);
	return n;
}
#define bsf64 bsf64

#endif 

#else
#  pragma message("Unrecognized compiler.  Please add a header file for your compiler.  Compilation will proceed, but performance may suffer!")
#endif





#include <stddef.h> 

#ifndef __bool_true_false_are_defined
#  include <stdbool.h> 
#endif


#include <stdint.h>
typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
typedef int8_t s8;
typedef int16_t s16;
typedef int32_t s32;
typedef int64_t s64;


typedef size_t machine_word_t;


#define WORDBYTES	((int)sizeof(machine_word_t))


#define WORDBITS	(8 * WORDBYTES)






#ifndef LIBEXPORT
#  define LIBEXPORT
#endif


#ifndef inline
#  define inline
#endif


#ifndef forceinline
#  define forceinline inline
#endif


#ifndef restrict
#  define restrict
#endif


#ifndef likely
#  define likely(expr)		(expr)
#endif


#ifndef unlikely
#  define unlikely(expr)	(expr)
#endif


#ifndef prefetchr
#  define prefetchr(addr)
#endif


#ifndef prefetchw
#  define prefetchw(addr)
#endif


#ifndef COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE
#  define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE 0
#endif


#ifndef COMPILER_SUPPORTS_BMI2_TARGET
#  define COMPILER_SUPPORTS_BMI2_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX_TARGET
#  define COMPILER_SUPPORTS_AVX_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET
#  define COMPILER_SUPPORTS_AVX512BW_TARGET 0
#endif


#ifndef COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 0
#endif


#ifndef _aligned_attribute
#endif





#define ARRAY_LEN(A)		(sizeof(A) / sizeof((A)[0]))
#define MIN(a, b)		((a) <= (b) ? (a) : (b))
#define MAX(a, b)		((a) >= (b) ? (a) : (b))
#define DIV_ROUND_UP(n, d)	(((n) + (d) - 1) / (d))
#define STATIC_ASSERT(expr)	((void)sizeof(char[1 - 2 * !(expr)]))
#define ALIGN(n, a)		(((n) + (a) - 1) & ~((a) - 1))






#ifndef CPU_IS_LITTLE_ENDIAN
static forceinline int CPU_IS_LITTLE_ENDIAN(void)
{
	union {
		unsigned int v;
		unsigned char b;
	} u;
	u.v = 1;
	return u.b;
}
#endif


#ifndef bswap16
static forceinline u16 bswap16(u16 n)
{
	return (n << 8) | (n >> 8);
}
#endif


#ifndef bswap32
static forceinline u32 bswap32(u32 n)
{
	return ((n & 0x000000FF) << 24) |
	       ((n & 0x0000FF00) << 8) |
	       ((n & 0x00FF0000) >> 8) |
	       ((n & 0xFF000000) >> 24);
}
#endif


#ifndef bswap64
static forceinline u64 bswap64(u64 n)
{
	return ((n & 0x00000000000000FF) << 56) |
	       ((n & 0x000000000000FF00) << 40) |
	       ((n & 0x0000000000FF0000) << 24) |
	       ((n & 0x00000000FF000000) << 8) |
	       ((n & 0x000000FF00000000) >> 8) |
	       ((n & 0x0000FF0000000000) >> 24) |
	       ((n & 0x00FF000000000000) >> 40) |
	       ((n & 0xFF00000000000000) >> 56);
}
#endif

#define le16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap16(n))
#define le32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap32(n))
#define le64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap64(n))
#define be16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap16(n) : (n))
#define be32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap32(n) : (n))
#define be64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap64(n) : (n))






#ifndef UNALIGNED_ACCESS_IS_FAST
#  define UNALIGNED_ACCESS_IS_FAST 0
#endif







#ifndef bsr32
static forceinline unsigned
bsr32(u32 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

#ifndef bsr64
static forceinline unsigned
bsr64(u64 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

static forceinline unsigned
bsrw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsr32(n);
	else
		return bsr64(n);
}



#ifndef bsf32
static forceinline unsigned
bsf32(u32 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

#ifndef bsf64
static forceinline unsigned
bsf64(u64 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

static forceinline unsigned
bsfw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsf32(n);
	else
		return bsf64(n);
}

#endif 



#define SYM_FIXUP(sym)			_libdeflate_##sym
#define deflate_get_compression_level	SYM_FIXUP(deflate_get_compression_level)
#define _cpu_features			SYM_FIXUP(_cpu_features)
#define setup_cpu_features		SYM_FIXUP(setup_cpu_features)

void *libdeflate_malloc(size_t size);
void libdeflate_free(void *ptr);

void *libdeflate_aligned_malloc(size_t alignment, size_t size);
void libdeflate_aligned_free(void *ptr);

#ifdef FREESTANDING

void *memset(void *s, int c, size_t n);
#define memset(s, c, n)		__builtin_memset((s), (c), (n))

void *memcpy(void *dest, const void *src, size_t n);
#define memcpy(dest, src, n)	__builtin_memcpy((dest), (src), (n))

void *memmove(void *dest, const void *src, size_t n);
#define memmove(dest, src, n)	__builtin_memmove((dest), (src), (n))

int memcmp(const void *s1, const void *s2, size_t n);
#define memcmp(s1, s2, n)	__builtin_memcmp((s1), (s2), (n))
#else
#include <string.h>
#endif

#endif 


#if (defined(__arm__) || defined(__aarch64__)) && \
	defined(__linux__) && \
	COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE && \
	!defined(FREESTANDING)
#  define ARM_CPU_FEATURES_ENABLED 1
#else
#  define ARM_CPU_FEATURES_ENABLED 0
#endif

#if ARM_CPU_FEATURES_ENABLED

#define ARM_CPU_FEATURE_NEON		0x00000001
#define ARM_CPU_FEATURE_PMULL		0x00000002
#define ARM_CPU_FEATURE_CRC32		0x00000004

#define ARM_CPU_FEATURES_KNOWN		0x80000000

extern volatile u32 _cpu_features;

void setup_cpu_features(void);

static inline u32 get_cpu_features(void)
{
	if (_cpu_features == 0)
		setup_cpu_features();
	return _cpu_features;
}

#endif 

#endif 


#if ARM_CPU_FEATURES_ENABLED

#include <errno.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>

#define AT_HWCAP	16
#define AT_HWCAP2	26

volatile u32 _cpu_features = 0;

static void scan_auxv(unsigned long *hwcap, unsigned long *hwcap2)
{
	int fd;
	unsigned long auxbuf[32];
	int filled = 0;
	int i;

	fd = open("/proc/self/auxv", O_RDONLY);
	if (fd < 0)
		return;

	for (;;) {
		do {
			int ret = read(fd, &((char *)auxbuf)[filled],
				       sizeof(auxbuf) - filled);
			if (ret <= 0) {
				if (ret < 0 && errno == EINTR)
					continue;
				goto out;
			}
			filled += ret;
		} while (filled < 2 * sizeof(long));

		i = 0;
		do {
			unsigned long type = auxbuf[i];
			unsigned long value = auxbuf[i + 1];

			if (type == AT_HWCAP)
				*hwcap = value;
			else if (type == AT_HWCAP2)
				*hwcap2 = value;
			i += 2;
			filled -= 2 * sizeof(long);
		} while (filled >= 2 * sizeof(long));

		memmove(auxbuf, &auxbuf[i], filled);
	}
out:
	close(fd);
}

static const struct cpu_feature arm_cpu_feature_table[] = {
	{ARM_CPU_FEATURE_NEON,		"neon"},
	{ARM_CPU_FEATURE_PMULL,		"pmull"},
	{ARM_CPU_FEATURE_CRC32,		"crc32"},
};

void setup_cpu_features(void)
{
	u32 features = 0;
	unsigned long hwcap = 0;
	unsigned long hwcap2 = 0;

	scan_auxv(&hwcap, &hwcap2);

#ifdef __arm__
	STATIC_ASSERT(sizeof(long) == 4);
	if (hwcap & (1 << 12))	
		features |= ARM_CPU_FEATURE_NEON;
	if (hwcap2 & (1 << 1))	
		features |= ARM_CPU_FEATURE_PMULL;
	if (hwcap2 & (1 << 4))	
		features |= ARM_CPU_FEATURE_CRC32;
#else
	STATIC_ASSERT(sizeof(long) == 8);
	if (hwcap & (1 << 1))	
		features |= ARM_CPU_FEATURE_NEON;
	if (hwcap & (1 << 4))	
		features |= ARM_CPU_FEATURE_PMULL;
	if (hwcap & (1 << 7))	
		features |= ARM_CPU_FEATURE_CRC32;
#endif

	disable_cpu_features_for_testing(&features, arm_cpu_feature_table,
					 ARRAY_LEN(arm_cpu_feature_table));

	_cpu_features = features | ARM_CPU_FEATURES_KNOWN;
}

#endif 
/* /usr/home/ben/projects/gzip-libdeflate/../../software/libdeflate-1.7/lib/x86/cpu_features.c */


/* #include "cpu_features_common.h" - no include guard */ 
/* #include "x86-cpu_features.h" */


#ifndef LIB_X86_CPU_FEATURES_H
#define LIB_X86_CPU_FEATURES_H

/* #include "lib_common.h" */


#ifndef LIB_LIB_COMMON_H
#define LIB_LIB_COMMON_H

#ifdef LIBDEFLATE_H
#  error "lib_common.h must always be included before libdeflate.h"
   
#endif

#define BUILDING_LIBDEFLATE

/* #include "../common/common_defs.h" */


#ifndef COMMON_COMMON_DEFS_H
#define COMMON_COMMON_DEFS_H

#ifdef __GNUC__
/* #  include "compiler_gcc.h" */


#if !defined(__clang__) && !defined(__INTEL_COMPILER)
#  define GCC_PREREQ(major, minor)		\
	(__GNUC__ > (major) ||			\
	 (__GNUC__ == (major) && __GNUC_MINOR__ >= (minor)))
#else
#  define GCC_PREREQ(major, minor)	0
#endif


#ifdef __clang__
#  ifdef __apple_build_version__
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__apple_build_version__ >= (apple_version))
#  else
#    define CLANG_PREREQ(major, minor, apple_version)	\
	(__clang_major__ > (major) ||			\
	 (__clang_major__ == (major) && __clang_minor__ >= (minor)))
#  endif
#else
#  define CLANG_PREREQ(major, minor, apple_version)	0
#endif

#ifndef __has_attribute
#  define __has_attribute(attribute)	0
#endif
#ifndef __has_feature
#  define __has_feature(feature)	0
#endif
#ifndef __has_builtin
#  define __has_builtin(builtin)	0
#endif

#ifdef _WIN32
#  define LIBEXPORT __declspec(dllexport)
#else
#  define LIBEXPORT __attribute__((visibility("default")))
#endif

#define inline			inline
#define forceinline		inline __attribute__((always_inline))
#define restrict		__restrict__
#define likely(expr)		__builtin_expect(!!(expr), 1)
#define unlikely(expr)		__builtin_expect(!!(expr), 0)
#define prefetchr(addr)		__builtin_prefetch((addr), 0)
#define prefetchw(addr)		__builtin_prefetch((addr), 1)
#define _aligned_attribute(n)	__attribute__((aligned(n)))

#define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE	\
	(GCC_PREREQ(4, 4) || __has_attribute(target))

#if COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE

#  if defined(__i386__) || defined(__x86_64__)

#    define COMPILER_SUPPORTS_PCLMUL_TARGET	\
	(GCC_PREREQ(4, 4) || __has_builtin(__builtin_ia32_pclmulqdq128))

#    define COMPILER_SUPPORTS_AVX_TARGET	\
	(GCC_PREREQ(4, 6) || __has_builtin(__builtin_ia32_maxps256))

#    define COMPILER_SUPPORTS_BMI2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_pdep_di))

#    define COMPILER_SUPPORTS_AVX2_TARGET	\
	(GCC_PREREQ(4, 7) || __has_builtin(__builtin_ia32_psadbw256))

#    define COMPILER_SUPPORTS_AVX512BW_TARGET	\
	(GCC_PREREQ(5, 1) || __has_builtin(__builtin_ia32_psadbw512))

	
#    if GCC_PREREQ(4, 9) || CLANG_PREREQ(3, 8, 7030000)
#      define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS	1
#      define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_PCLMUL_TARGET
#      define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX2_TARGET
#      define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS	\
		COMPILER_SUPPORTS_AVX512BW_TARGET
#    endif

#  elif defined(__arm__) || defined(__aarch64__)

    
#    if (GCC_PREREQ(6, 1) && defined(__ARM_FP)) || \
        (defined(__clang__) && defined(__ARM_NEON))
#      define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 1
       
#      if defined(__clang__) && defined(__arm__)
#        undef __ARM_FEATURE_CRYPTO
#      elif __has_builtin(__builtin_neon_vmull_p64) || !defined(__clang__)
#        define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 1
#      endif
#    endif

     
#    if GCC_PREREQ(10, 1) || \
        (GCC_PREREQ(9, 3) && !GCC_PREREQ(10, 0)) || \
        (GCC_PREREQ(8, 4) && !GCC_PREREQ(9, 0)) || \
        (defined(__clang__) && __has_builtin(__builtin_arm_crc32b))
#      define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 1
#    endif

#  endif 

#endif 


#if (GCC_PREREQ(4, 0) && !GCC_PREREQ(5, 1)) || \
    (defined(__clang__) && !CLANG_PREREQ(3, 9, 8020000))
typedef unsigned long long  __v2du __attribute__((__vector_size__(16)));
typedef unsigned int        __v4su __attribute__((__vector_size__(16)));
typedef unsigned short      __v8hu __attribute__((__vector_size__(16)));
typedef unsigned char      __v16qu __attribute__((__vector_size__(16)));
typedef unsigned long long  __v4du __attribute__((__vector_size__(32)));
typedef unsigned int        __v8su __attribute__((__vector_size__(32)));
typedef unsigned short     __v16hu __attribute__((__vector_size__(32)));
typedef unsigned char      __v32qu __attribute__((__vector_size__(32)));
#endif


#ifdef __BYTE_ORDER__
#  define CPU_IS_LITTLE_ENDIAN() (__BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__)
#endif

#if GCC_PREREQ(4, 8) || __has_builtin(__builtin_bswap16)
#  define bswap16	__builtin_bswap16
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap32)
#  define bswap32	__builtin_bswap32
#endif

#if GCC_PREREQ(4, 3) || __has_builtin(__builtin_bswap64)
#  define bswap64	__builtin_bswap64
#endif

#if defined(__x86_64__) || defined(__i386__) || defined(__ARM_FEATURE_UNALIGNED) || defined(__powerpc64__)
#  define UNALIGNED_ACCESS_IS_FAST 1
#endif

#define bsr32(n)	(31 - __builtin_clz(n))
#define bsr64(n)	(63 - __builtin_clzll(n))
#define bsf32(n)	__builtin_ctz(n)
#define bsf64(n)	__builtin_ctzll(n)

#elif defined(_MSC_VER)
/* #  include "compiler_msc.h" */


#include <stdint.h>
#include <stdlib.h> 

#define LIBEXPORT	__declspec(dllexport)


typedef int bool;
#define true 1
#define false 0
#define __bool_true_false_are_defined 1


#ifdef _WIN64
typedef long long ssize_t;
#else
typedef int ssize_t;
#endif


#define CPU_IS_LITTLE_ENDIAN()		1
#define UNALIGNED_ACCESS_IS_FAST	1


#define restrict


#define inline		__inline
#define forceinline	__forceinline


#define bswap16	_byteswap_ushort
#define bswap32	_byteswap_ulong
#define bswap64	_byteswap_uint64



static forceinline unsigned
bsr32(uint32_t n)
{
	_BitScanReverse(&n, n);
	return n;
}
#define bsr32 bsr32

static forceinline unsigned
bsf32(uint32_t n)
{
	_BitScanForward(&n, n);
	return n;
}
#define bsf32 bsf32

#ifdef _M_X64 

static forceinline unsigned
bsr64(uint64_t n)
{
	_BitScanReverse64(&n, n);
	return n;
}
#define bsr64 bsr64

static forceinline unsigned
bsf64(uint64_t n)
{
	_BitScanForward64(&n, n);
	return n;
}
#define bsf64 bsf64

#endif 

#else
#  pragma message("Unrecognized compiler.  Please add a header file for your compiler.  Compilation will proceed, but performance may suffer!")
#endif





#include <stddef.h> 

#ifndef __bool_true_false_are_defined
#  include <stdbool.h> 
#endif


#include <stdint.h>
typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
typedef int8_t s8;
typedef int16_t s16;
typedef int32_t s32;
typedef int64_t s64;


typedef size_t machine_word_t;


#define WORDBYTES	((int)sizeof(machine_word_t))


#define WORDBITS	(8 * WORDBYTES)






#ifndef LIBEXPORT
#  define LIBEXPORT
#endif


#ifndef inline
#  define inline
#endif


#ifndef forceinline
#  define forceinline inline
#endif


#ifndef restrict
#  define restrict
#endif


#ifndef likely
#  define likely(expr)		(expr)
#endif


#ifndef unlikely
#  define unlikely(expr)	(expr)
#endif


#ifndef prefetchr
#  define prefetchr(addr)
#endif


#ifndef prefetchw
#  define prefetchw(addr)
#endif


#ifndef COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE
#  define COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE 0
#endif


#ifndef COMPILER_SUPPORTS_BMI2_TARGET
#  define COMPILER_SUPPORTS_BMI2_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX_TARGET
#  define COMPILER_SUPPORTS_AVX_TARGET 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET
#  define COMPILER_SUPPORTS_AVX512BW_TARGET 0
#endif


#ifndef COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_SSE2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PCLMUL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX2_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_AVX512BW_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_NEON_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_PMULL_TARGET_INTRINSICS 0
#endif
#ifndef COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS
#  define COMPILER_SUPPORTS_CRC32_TARGET_INTRINSICS 0
#endif


#ifndef _aligned_attribute
#endif





#define ARRAY_LEN(A)		(sizeof(A) / sizeof((A)[0]))
#define MIN(a, b)		((a) <= (b) ? (a) : (b))
#define MAX(a, b)		((a) >= (b) ? (a) : (b))
#define DIV_ROUND_UP(n, d)	(((n) + (d) - 1) / (d))
#define STATIC_ASSERT(expr)	((void)sizeof(char[1 - 2 * !(expr)]))
#define ALIGN(n, a)		(((n) + (a) - 1) & ~((a) - 1))






#ifndef CPU_IS_LITTLE_ENDIAN
static forceinline int CPU_IS_LITTLE_ENDIAN(void)
{
	union {
		unsigned int v;
		unsigned char b;
	} u;
	u.v = 1;
	return u.b;
}
#endif


#ifndef bswap16
static forceinline u16 bswap16(u16 n)
{
	return (n << 8) | (n >> 8);
}
#endif


#ifndef bswap32
static forceinline u32 bswap32(u32 n)
{
	return ((n & 0x000000FF) << 24) |
	       ((n & 0x0000FF00) << 8) |
	       ((n & 0x00FF0000) >> 8) |
	       ((n & 0xFF000000) >> 24);
}
#endif


#ifndef bswap64
static forceinline u64 bswap64(u64 n)
{
	return ((n & 0x00000000000000FF) << 56) |
	       ((n & 0x000000000000FF00) << 40) |
	       ((n & 0x0000000000FF0000) << 24) |
	       ((n & 0x00000000FF000000) << 8) |
	       ((n & 0x000000FF00000000) >> 8) |
	       ((n & 0x0000FF0000000000) >> 24) |
	       ((n & 0x00FF000000000000) >> 40) |
	       ((n & 0xFF00000000000000) >> 56);
}
#endif

#define le16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap16(n))
#define le32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap32(n))
#define le64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? (n) : bswap64(n))
#define be16_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap16(n) : (n))
#define be32_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap32(n) : (n))
#define be64_bswap(n) (CPU_IS_LITTLE_ENDIAN() ? bswap64(n) : (n))






#ifndef UNALIGNED_ACCESS_IS_FAST
#  define UNALIGNED_ACCESS_IS_FAST 0
#endif







#ifndef bsr32
static forceinline unsigned
bsr32(u32 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

#ifndef bsr64
static forceinline unsigned
bsr64(u64 n)
{
	unsigned i = 0;
	while ((n >>= 1) != 0)
		i++;
	return i;
}
#endif

static forceinline unsigned
bsrw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsr32(n);
	else
		return bsr64(n);
}



#ifndef bsf32
static forceinline unsigned
bsf32(u32 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

#ifndef bsf64
static forceinline unsigned
bsf64(u64 n)
{
	unsigned i = 0;
	while ((n & 1) == 0) {
		i++;
		n >>= 1;
	}
	return i;
}
#endif

static forceinline unsigned
bsfw(machine_word_t n)
{
	STATIC_ASSERT(WORDBITS == 32 || WORDBITS == 64);
	if (WORDBITS == 32)
		return bsf32(n);
	else
		return bsf64(n);
}

#endif 



#define SYM_FIXUP(sym)			_libdeflate_##sym
#define deflate_get_compression_level	SYM_FIXUP(deflate_get_compression_level)
#define _cpu_features			SYM_FIXUP(_cpu_features)
#define setup_cpu_features		SYM_FIXUP(setup_cpu_features)

void *libdeflate_malloc(size_t size);
void libdeflate_free(void *ptr);

void *libdeflate_aligned_malloc(size_t alignment, size_t size);
void libdeflate_aligned_free(void *ptr);

#ifdef FREESTANDING

void *memset(void *s, int c, size_t n);
#define memset(s, c, n)		__builtin_memset((s), (c), (n))

void *memcpy(void *dest, const void *src, size_t n);
#define memcpy(dest, src, n)	__builtin_memcpy((dest), (src), (n))

void *memmove(void *dest, const void *src, size_t n);
#define memmove(dest, src, n)	__builtin_memmove((dest), (src), (n))

int memcmp(const void *s1, const void *s2, size_t n);
#define memcmp(s1, s2, n)	__builtin_memcmp((s1), (s2), (n))
#else
#include <string.h>
#endif

#endif 


#if (defined(__i386__) || defined(__x86_64__)) && \
	COMPILER_SUPPORTS_TARGET_FUNCTION_ATTRIBUTE
#  define X86_CPU_FEATURES_ENABLED 1
#else
#  define X86_CPU_FEATURES_ENABLED 0
#endif

#if X86_CPU_FEATURES_ENABLED

#define X86_CPU_FEATURE_SSE2		0x00000001
#define X86_CPU_FEATURE_PCLMUL		0x00000002
#define X86_CPU_FEATURE_AVX		0x00000004
#define X86_CPU_FEATURE_AVX2		0x00000008
#define X86_CPU_FEATURE_BMI2		0x00000010
#define X86_CPU_FEATURE_AVX512BW	0x00000020

#define X86_CPU_FEATURES_KNOWN		0x80000000

extern volatile u32 _cpu_features;

void setup_cpu_features(void);

static inline u32 get_cpu_features(void)
{
	if (_cpu_features == 0)
		setup_cpu_features();
	return _cpu_features;
}

#endif 

#endif 


#if X86_CPU_FEATURES_ENABLED

volatile u32 _cpu_features = 0;


#if defined(__i386__) && defined(__PIC__)
#  define EBX_CONSTRAINT "=&r"
#else
#  define EBX_CONSTRAINT "=b"
#endif


static inline void
cpuid(u32 leaf, u32 subleaf, u32 *a, u32 *b, u32 *c, u32 *d)
{
	__asm__(".ifnc %%ebx, %1; mov  %%ebx, %1; .endif\n"
		"cpuid                                  \n"
		".ifnc %%ebx, %1; xchg %%ebx, %1; .endif\n"
		: "=a" (*a), EBX_CONSTRAINT (*b), "=c" (*c), "=d" (*d)
		: "a" (leaf), "c" (subleaf));
}


static inline u64
read_xcr(u32 index)
{
	u32 edx, eax;

	
	__asm__ (".byte 0x0f, 0x01, 0xd0" : "=d" (edx), "=a" (eax) : "c" (index));

	return ((u64)edx << 32) | eax;
}

#undef BIT
#define BIT(nr)			(1UL << (nr))

#define XCR0_BIT_SSE		BIT(1)
#define XCR0_BIT_AVX		BIT(2)
#define XCR0_BIT_OPMASK		BIT(5)
#define XCR0_BIT_ZMM_HI256	BIT(6)
#define XCR0_BIT_HI16_ZMM	BIT(7)

#define IS_SET(reg, nr)		((reg) & BIT(nr))
#define IS_ALL_SET(reg, mask)	(((reg) & (mask)) == (mask))

static const struct cpu_feature x86_cpu_feature_table[] = {
	{X86_CPU_FEATURE_SSE2,		"sse2"},
	{X86_CPU_FEATURE_PCLMUL,	"pclmul"},
	{X86_CPU_FEATURE_AVX,		"avx"},
	{X86_CPU_FEATURE_AVX2,		"avx2"},
	{X86_CPU_FEATURE_BMI2,		"bmi2"},
	{X86_CPU_FEATURE_AVX512BW,	"avx512bw"},
};


void setup_cpu_features(void)
{
	u32 features = 0;
	u32 dummy1, dummy2, dummy3, dummy4;
	u32 max_function;
	u32 features_1, features_2, features_3, features_4;
	bool os_avx_support = false;
	bool os_avx512_support = false;

	
	cpuid(0, 0, &max_function, &dummy2, &dummy3, &dummy4);
	if (max_function < 1)
		goto out;

	
	cpuid(1, 0, &dummy1, &dummy2, &features_2, &features_1);

	if (IS_SET(features_1, 26))
		features |= X86_CPU_FEATURE_SSE2;

	if (IS_SET(features_2, 1))
		features |= X86_CPU_FEATURE_PCLMUL;

	if (IS_SET(features_2, 27)) { 
		u64 xcr0 = read_xcr(0);

		os_avx_support = IS_ALL_SET(xcr0,
					    XCR0_BIT_SSE |
					    XCR0_BIT_AVX);

		os_avx512_support = IS_ALL_SET(xcr0,
					       XCR0_BIT_SSE |
					       XCR0_BIT_AVX |
					       XCR0_BIT_OPMASK |
					       XCR0_BIT_ZMM_HI256 |
					       XCR0_BIT_HI16_ZMM);
	}

	if (os_avx_support && IS_SET(features_2, 28))
		features |= X86_CPU_FEATURE_AVX;

	if (max_function < 7)
		goto out;

	
	cpuid(7, 0, &dummy1, &features_3, &features_4, &dummy4);

	if (os_avx_support && IS_SET(features_3, 5))
		features |= X86_CPU_FEATURE_AVX2;

	if (IS_SET(features_3, 8))
		features |= X86_CPU_FEATURE_BMI2;

	if (os_avx512_support && IS_SET(features_3, 30))
		features |= X86_CPU_FEATURE_AVX512BW;

out:
	disable_cpu_features_for_testing(&features, x86_cpu_feature_table,
					 ARRAY_LEN(x86_cpu_feature_table));

	_cpu_features = features | X86_CPU_FEATURES_KNOWN;
}

#endif 
