#define DEFINED_CONSTANT 10

#include <stdint.h>

enum {
  ENUMERATED_CONSTANT = 20
};

static const int STATIC_CONSTANT = 30;

struct point
{
  int x, y;
};

struct msghdr
{
  int cmd;
  signed char vers; // Be specific on signedness
  /* hope there's a hole here */
};

struct idname
{
  int id;
  char name[12];
};

struct llq
{
  uint32_t l1, l2;
  uint64_t q;
};
