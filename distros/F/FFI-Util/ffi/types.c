#include <ffi_util.h>
#include "ffi_util_config.h"

#define is_signed(type) (((type)-1) < 0)

#define storage(type) \
  if(sizeof(type) == sizeof(short))   \
    return is_signed(type) ? "short" : "ushort"; \
  else if(sizeof(type) == sizeof(int)) \
    return is_signed(type) ? "int" : "uint"; \
  else if(sizeof(type) == sizeof(long)) \
    return is_signed(type) ? "long" : "ulong"; \
  else if(sizeof(type) == sizeof(int64_t)) \
    return is_signed(type) ? "int64" : "uint64";

FFI_UTIL_EXPORT const char *
lookup_type(const char *name)
{
#ifdef HAS_SIZE_T
  if(!strcmp(name, "size_t"))
  {
    storage(size_t);
  }
#endif
#ifdef HAS_TIME_T
  if(!strcmp(name, "time_t"))
  {
    storage(time_t);
  }
#endif
#ifdef HAS_DEV_T
  if(!strcmp(name, "dev_t"))
  {
    storage(dev_t);
  }
#endif
#ifdef HAS_GID_T
  if(!strcmp(name, "gid_t"))
  {
    storage(gid_t);
  }
#endif
#ifdef HAS_UID_T
  if(!strcmp(name, "uid_t"))
  {
    storage(uid_t);
  }
#endif
  return NULL;
}
