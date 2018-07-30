#include <ffi_util.h>
#include <string.h>

FFI_UTIL_EXPORT const char *
get_string_from_array(const char **array, int index)
{
  static char buffer[512];
  if(array[index] == NULL)
    return NULL;
  strcpy(buffer, array[index]);
  return buffer;
}

FFI_UTIL_EXPORT const char **
null()
{
  return NULL;
}

FFI_UTIL_EXPORT const char **
onetwothree3()
{
  static char *buffer[3] = {
    "one",
    "two",
    "three"
  };
  return buffer;
}

FFI_UTIL_EXPORT const char **
onetwothree4()
{
  static char *buffer[4] = {
    "one",
    "two",
    "three",
    NULL
  };
  return buffer;
}

FFI_UTIL_EXPORT const char **
onenullthree3()
{
  static char *buffer[3] = {
    "one",
    NULL,
    "three"
  };
  return buffer;
}

FFI_UTIL_EXPORT const char **
ptrnull()
{
  static char *buffer[1] = {
    NULL
  };
  return buffer;
}
