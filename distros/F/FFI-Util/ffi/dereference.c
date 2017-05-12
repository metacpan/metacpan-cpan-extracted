#include <ffi_util.h>
#include "ffi_util_config.h"

/*

=head2 deref_ptr_get

 my $ptr2 = deref_ptr_get($ptr1);

equivalent to

 void *ptr1;
 void *ptr2;
 *ptr2 = *ptr1;

=cut

*/
FFI_UTIL_EXPORT void *
deref_ptr_get(void **ptr)
{
  return *ptr;
}

/*

=head2 deref_ptr_set

 deref_ptr_set($ptr1, $ptr2);

equivalent to

 void **ptr1;
 void *ptr2;
 *ptr1 = ptr2;

=cut

*/

FFI_UTIL_EXPORT void
deref_ptr_set(void **ptr, void *value)
{
  *ptr = value;
}

/*

=head2 deref_str_get

 my $string = deref_str_get($ptr);

equivalent to

 const char *string;
 const char **ptr;
 string = *ptr;

=cut

*/

FFI_UTIL_EXPORT const char *
deref_str_get(const char **ptr)
{
  return *ptr;
}

/*

=head2 deref_str_set

 deref_str_set($ptr, $string);

equivalent to

 const char **ptr;
 const char *string;
 *ptr = string;

=cut

*/

FFI_UTIL_EXPORT void
deref_str_set(const char **ptr, const char *value)
{
  *ptr = value;
}

/*

=head2 deref_int_get

 my $integer = deref_int_get($ptr);

equivalent to

 int *ptr;
 int integer;
 integer = *ptr;

=cut

*/

FFI_UTIL_EXPORT int
deref_int_get(int *ptr)
{
  return *ptr;
}

/*

=head2 deref_int_set

 deref_int_set($ptr, $integer);

equivalent to

 int *ptr;
 int integer;
 *ptr = integer;

=cut

*/

FFI_UTIL_EXPORT void
deref_int_set(int *ptr, int value)
{
  *ptr = value;
}

/*

=head2 deref_uint_get

 my $unsigned_integer = deref_uint_get($ptr);

equivalent to

 unsigned int unsigned_integer;
 unsigned int *ptr;
 unsigned_integer = *ptr;

=cut

*/

FFI_UTIL_EXPORT unsigned int
deref_uint_get(unsigned int *ptr)
{
  return *ptr;
}

/*

=head2 deref_uint_set

 deref_uint_set($ptr, $unsigned_integer);

equivalent to

 unsigned int *ptr;
 unsigned int unsigned_integer;
 *ptr = unsigned_integer;

=cut

*/

FFI_UTIL_EXPORT void
deref_uint_set(unsigned int *ptr, unsigned int value)
{
  *ptr = value;
}

/*

=head2 deref_short_get

 my $short_integer = deref_short_get($ptr);

equivalent to

 short short_integer;
 short *ptr;
 short_integer = *ptr;

=cut

*/

FFI_UTIL_EXPORT short
deref_short_get(short *ptr)
{
  return *ptr;
}

/*

=head2 deref_short_set

 deref_short_set($ptr, $short_integer);

equivalent to

 short *ptr;
 short short_integer;
 *ptr = short_integer;

=cut

*/

FFI_UTIL_EXPORT void
deref_short_set(short *ptr, short value)
{
  *ptr = value;
}

/*

=head2 deref_ushort_get

 my $unsigned_short_integer = deref_ushort_get($ptr);

equivalent to

 unsigned short unsigned_short_integer;
 unsigned short *ptr;
 unsigned unsigned_short_integer = *ptr;

=cut

*/

FFI_UTIL_EXPORT unsigned short
deref_ushort_get(unsigned short *ptr)
{
  return *ptr;
}

/*

=head2 deref_ushort_set

 deref_ushort_set($ptr, $unsigned_short_integer);

equivalent to

 unsigned short *ptr;
 unsigned short unsigned_short_integer;
 *ptr = unsigned_short_integer;

=cut

*/

FFI_UTIL_EXPORT void
deref_ushort_set(unsigned short *ptr, unsigned short value)
{
  *ptr = value;
}

/*

=head2 deref_long_get

 my $long_integer = deref_long_get($ptr);

equivalent to

 long long_integer;
 long *ptr;
 long_integer = *ptr;

=cut

*/

FFI_UTIL_EXPORT long
deref_long_get(long *ptr)
{
  return *ptr;
}

/*

=head2 deref_long_set

 deref_long_set($ptr, $long_integer);

equivalent to

 long *ptr;
 long long_integer;
 *ptr = long_integer;

=cut

*/

FFI_UTIL_EXPORT void
deref_long_set(long *ptr, long value)
{
  *ptr = value;
}

/*

=head2 deref_ulong_get

 my $unsigned_long_integer = deref_ulong_get($ptr);

equivalent to

 unsigned long unsigned_long_integer;
 unsigned long *ptr;
 unsigned unsigned_long_integer = *ptr;

=cut

*/

FFI_UTIL_EXPORT unsigned long
deref_ulong_get(unsigned long *ptr)
{
  return *ptr;
}

/*

=head2 deref_ulong_set

 deref_ulong_set($ptr, $unsigned_long_integer);

equivalent to

 unsigned long *ptr;
 unsigned long unsigned_long_integer;
 *ptr = unsigned_long_integer;

=cut

*/

FFI_UTIL_EXPORT void
deref_ulong_set(unsigned long *ptr, unsigned long value)
{
  *ptr = value;
}

/*

=head2 deref_char_get

 my $char_integer = deref_char_get($ptr);

equivalent to

 char char_integer;
 char *ptr;
 char_integer = *ptr;

=cut

*/

FFI_UTIL_EXPORT char
deref_char_get(char *ptr)
{
  return *ptr;
}

/*

=head2 deref_char_set

 deref_char_set($ptr, $char_integer);

equivalent to

 char *ptr;
 char char_integer;
 *ptr = char_integer;

=cut

*/

FFI_UTIL_EXPORT void
deref_char_set(char *ptr, char value)
{
  *ptr = value;
}

/*

=head2 deref_uchar_get

 my $unsigned_char_integer = deref_uchar_get($ptr);

equivalent to

 unsigned char unsigned char_integer;
 unsigned char *ptr;
 unsigned_char_integer = *ptr;

=cut

*/

FFI_UTIL_EXPORT unsigned char
deref_uchar_get(unsigned char *ptr)
{
  return *ptr;
}

/*

=head2 deref_uchar_set

 deref_uchar_set($ptr, $unsigned_char_integer);

equivalent to

 unsigned char *ptr;
 unsigned char unsigned_char_integer;
 *ptr = unsigned_char_integer;

=cut

*/

FFI_UTIL_EXPORT void
deref_uchar_set(unsigned char *ptr, unsigned char value)
{
  *ptr = value;
}

/*

=head2 deref_float_get

 my $single_float = deref_float_get($ptr);

equivalent to

 float single_float;
 float *ptr;
 single_float = *ptr;

=cut

*/

FFI_UTIL_EXPORT float
deref_float_get(float *ptr)
{
  return *ptr;
}

/*

=head2 deref_float_set

 deref_float_set($ptr, $single_float);

equivalent to

 float *ptr;
 float single_float;
 *ptr = single_float;

=cut

*/

FFI_UTIL_EXPORT void
deref_float_set(float *ptr, float value)
{
  *ptr = value;
}

/*

=head2 deref_double_get

 my $double_float = deref_double_get($ptr);

equivalent to

 double double_float;
 double *ptr;
 double_float = *ptr;

=cut

*/

FFI_UTIL_EXPORT double
deref_double_get(double *ptr)
{
  return *ptr;
}

/*

=head2 deref_double_set

 deref_double_set($ptr, $double_float);

equivalent to

 double *ptr;
 double double_float;
 *ptr = double_float;

=cut

*/

FFI_UTIL_EXPORT void
deref_double_set(float *ptr, double value)
{
  *ptr = value;
}

/*

=head2 deref_int64_get

 my $int64 = deref_int64_get($ptr);

equivalent to

 int64_t int64;
 int64_t *ptr;
 int64 = *ptr;

=cut

*/

FFI_UTIL_EXPORT int64_t
deref_int64_get(int64_t *ptr)
{
  return *ptr;
}

/*

=head2 deref_int64_set

 deref_int64_set($ptr, $int64);

equivalent to

 int64_t *ptr;
 int64_t int64;
 *ptr = int64;

=cut

*/

FFI_UTIL_EXPORT void
deref_int64_set(int64_t *ptr, int64_t value)
{
  *ptr = value;
}

/*

=head2 deref_uint64_get

 my $uint64 = deref_uint64_get($ptr);

equivalent to

 uint64_t uint64;
 uint64_t *ptr;
 uint64 = *ptr;

=cut

*/

FFI_UTIL_EXPORT uint64_t
deref_uint64_get(uint64_t *ptr)
{
  return *ptr;
}

/*

=head2 deref_uint64_set

 deref_uint64_set($ptr, $uint64);

equivalent to

 uint64_t *ptr;
 uint64_t uint64;
 *ptr = uint64;

=cut

*/

FFI_UTIL_EXPORT void
deref_uint64_set(uint64_t *ptr, uint64_t value)
{
  *ptr = value;
}

/*

=head2 deref_dev_t_get

Alias for appropriate C<derf_..._get> if dev_t is provided by your compiler.

=head2 deref_dev_t_set

Alias for appropriate C<derf_..._set> if dev_t is provided by your compiler.

=head2 deref_gid_t_get

Alias for appropriate C<derf_..._get> if gid_t is provided by your compiler.

=head2 deref_gid_t_set

Alias for appropriate C<derf_..._set> if gid_t is provided by your compiler.

=head2 deref_size_t_get

Alias for appropriate C<derf_..._get> if size_t is provided by your compiler.

=head2 deref_size_t_set

Alias for appropriate C<derf_..._set> if size_t is provided by your compiler.

=head2 deref_time_t_get

Alias for appropriate C<derf_..._get> if time_t is provided by your compiler.

=head2 deref_time_t_set

Alias for appropriate C<derf_..._set> if time_t is provided by your compiler.

=head2 deref_uid_t_get

Alias for appropriate C<derf_..._get> if uid_t is provided by your compiler.

=head2 deref_uid_t_set

Alias for appropriate C<derf_..._set> if uid_t is provided by your compiler.

=head1 SEE ALSO

=over 4

=item L<Module::Build::FFI>

=item L<FFI::Platypus>

=back

=cut

*/

