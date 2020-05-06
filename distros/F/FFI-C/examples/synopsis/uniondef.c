#include <stdint.h>
#include <stdio.h>

typedef union {
  uint8_t  u8;
  uint16_t u16;
  uint32_t u32;
} anyint_t;

void
print_anyint_as_u32(anyint_t *any)
{
  printf("0x%x\n", any->u32);
}
