#include <stdio.h>

typedef struct {
  double x, y;
} point_t;

void
print_rectangle(point_t rec[2])
{
  printf("[[%g %g] [%g %g]]\n",
    rec[0].x, rec[0].y,
    rec[1].x, rec[1].y
  );
}
