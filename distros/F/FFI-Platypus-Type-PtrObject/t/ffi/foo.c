#include <string.h>

typedef struct { char buffer[100] } foo_t;

void
set(foo_t *self, const char *value)
{
  strncpy(self->buffer, value, 100);
}

const char *
get(foo_t *self)
{
  return self->buffer;
}

foo_t *
clone(foo_t *self)
{
  foo_t *clone;
  clone = malloc(100);
  memcpy(clone->buffer, self->buffer, 100);
  return clone;
}

foo_t *
null(foo_t *self)
{
  return NULL;
}
