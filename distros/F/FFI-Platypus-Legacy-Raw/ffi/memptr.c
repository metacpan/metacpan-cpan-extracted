#include <stdlib.h>

void *
ffi__platypus__legacy__raw__memptr__new_from_ptr(void *src)
{
  void **dst;

  dst = malloc(sizeof(void*));
  *dst = src;
  return dst;
}
