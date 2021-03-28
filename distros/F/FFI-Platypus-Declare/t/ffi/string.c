#include <stdint.h>
#include <stdlib.h>
#include <string.h>

int
string_matches_foobarbaz(const char *value)
{
  return !strcmp(value, "foobarbaz");
}

const char *
string_return_foobarbaz(void)
{
  return "foobarbaz";
}

typedef const char *my_string_t;
typedef void (*closure_t)(my_string_t);
static closure_t my_closure;

void
string_set_closure(closure_t closure)
{
  my_closure = closure;
}

void
string_call_closure(const char *value)
{
  my_closure(value);
}
