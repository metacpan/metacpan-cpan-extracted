#include <stdint.h>
#include <stdio.h>

typedef struct {
  uint8_t red;
  uint8_t green;
  uint8_t blue;
} color_t;

void
print_color(color_t *c)
{
  printf("[%02x %02x %02x]\n",
    c->red,
    c->green,
    c->blue
  );
}
