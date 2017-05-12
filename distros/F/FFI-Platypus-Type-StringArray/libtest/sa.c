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
