#include <stdio.h>

#ifdef _MSC_VER
#define EXPORT __declspec(dllexport)
#else
#define EXPORT
#endif

typedef int (*adder)(int, int);

EXPORT
int
call_adder(adder f, int a, int b)
{
  return f(a,b);
}
