#include <stdint.h>

typedef struct {
  uint8_t red;
  uint8_t green;
  uint8_t blue;
} color_value_t;

typedef struct {
  char name[22];
  color_value_t value;
} named_color_t;

typedef named_color_t array_named_color_t[4];

typedef union {
  uint8_t  u8;
  uint16_t u16;
  uint32_t u32;
  uint64_t u64;
} anyint_t;
