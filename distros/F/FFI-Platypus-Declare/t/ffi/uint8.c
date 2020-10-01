#include <stdint.h>
#include <stdlib.h>

typedef uint8_t (*closure_t)(uint8_t);
static closure_t my_closure;

void
uint8_set_closure(closure_t closure)
{
  my_closure = closure;
}

uint8_t
uint8_call_closure(uint8_t value)
{
  return my_closure(value);
}
