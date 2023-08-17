#include "../byteorder.h"
#include "tap.h"
#include <float.h>

#define SUNDAY 0
#define MONDAY 1
#define TUESDAY 2
#define WEDNESDAY 3
#define THURSDAY 4
#define FRIDAY 5
#define SATURDAY 6

int tests_planned = 0;
int tests_run = 0;
int tests_failed = 0;

static int
test_le16_to_uint16(void)
{
    return shp_le16_to_uint16("\x00\x80") == 32768;
}

static int
test_be32_to_int32(void)
{
    return shp_be32_to_int32("\x80\x00\x00\x00") == INT32_MIN;
}

static int
test_le32_to_int32(void)
{
    return shp_le32_to_int32("\x00\x00\x00\x80") == INT32_MIN;
}

static int
test_be32_to_uint32(void)
{
    return shp_be32_to_uint32("\x80\x00\x00\x00") == 2147483648UL;
}

static int
test_le32_to_uint32(void)
{
    return shp_le32_to_uint32("\x00\x00\x00\x80") == 2147483648UL;
}

static int
test_le64_to_int64(void)
{
    return shp_le64_to_int64("\x00\x00\x00\x00\xfe\xff\xff\xff") ==
           -8589934592LL;
}

static int
test_le64_to_double(void)
{
    return shp_le64_to_double("\xff\xff\xff\xff\xff\xff\xef\x7f") == DBL_MAX;
}

int
main(void)
{
    plan(7);
    ok(test_le16_to_uint16, "test shp_le16_to_uint16");
    ok(test_be32_to_int32, "test shp_be32_to_int32");
    ok(test_le32_to_int32, "test shp_le32_to_int32");
    ok(test_be32_to_uint32, "test shp_be32_to_uint32");
    ok(test_le32_to_uint32, "test shp_le32_to_uint32");
    ok(test_le64_to_int64, "test shp_le64_to_int64");
    ok(test_le64_to_double, "test shp_le64_to_double");
    done_testing();
}
