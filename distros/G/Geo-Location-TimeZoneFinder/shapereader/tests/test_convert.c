#include "../convert.h"
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
    return shp_be32_to_int32("\x80\x00\x00\x00") == -2147483648;
}

static int
test_le32_to_int32(void)
{
    return shp_le32_to_int32("\x00\x00\x00\x80") == -2147483648;
}

static int
test_le32_to_uint32(void)
{
    return shp_le32_to_uint32("\x00\x00\x00\x80") == 2147483648;
}

static int
test_le64_to_int64(void)
{
    return shp_le64_to_int64("\x00\x00\x00\x00\xfe\xff\xff\xff") ==
           -8589934592;
}

static int
test_le64_to_double(void)
{
    return shp_le64_to_double("\xff\xff\xff\xff\xff\xff\xef\x7f") == DBL_MAX;
}

static int
compare_tm(struct tm *tm, int mday, int mon, int year, int hour, int min,
           int sec, int wday, int yday)
{
    return (tm->tm_mday == mday && tm->tm_mon + 1 == mon &&
            tm->tm_year + 1900 == year && tm->tm_hour == hour &&
            tm->tm_min == min && tm->tm_sec == sec && tm->tm_wday == wday &&
            tm->tm_yday + 1 == yday);
}

static int
test_jd_2451545(void)
{
    struct tm tm;

    shp_jd_to_tm(2451545, 43200000, &tm);
    return compare_tm(&tm, 1, 1, 2000, 12, 0, 0, SATURDAY, 1);
}

static int
test_jd_2446823(void)
{
    struct tm tm;

    shp_jd_to_tm(2446823, 0, &tm);
    return compare_tm(&tm, 27, 1, 1987, 0, 0, 0, TUESDAY, 27);
}

static int
test_jd_2446966(void)
{
    struct tm tm;

    shp_jd_to_tm(2446966, 43200000, &tm);
    return compare_tm(&tm, 19, 6, 1987, 12, 0, 0, FRIDAY, 170);
}

static int
test_jd_2447188(void)
{
    struct tm tm;

    shp_jd_to_tm(2447188, 0, &tm);
    return compare_tm(&tm, 27, 1, 1988, 0, 0, 0, WEDNESDAY, 27);
}

static int
test_jd_2447332(void)
{
    struct tm tm;

    shp_jd_to_tm(2447332, 43200000, &tm);
    return compare_tm(&tm, 19, 6, 1988, 12, 0, 0, SUNDAY, 171);
}

static int
test_jd_2415021(void)
{
    struct tm tm;

    shp_jd_to_tm(2415021, 43200000, &tm);
    return compare_tm(&tm, 1, 1, 1900, 12, 0, 0, MONDAY, 1);
}

static int
test_jd_2305448(void)
{
    struct tm tm;

    shp_jd_to_tm(2305448, 43200000, &tm);
    return compare_tm(&tm, 1, 1, 1600, 12, 0, 0, SATURDAY, 1);
}

static int
test_jd_2305813(void)
{
    struct tm tm;

    shp_jd_to_tm(2305813, 43200000, &tm);
    return compare_tm(&tm, 31, 12, 1600, 12, 0, 0, SUNDAY, 366);
}

static int
test_jd_2026872(void)
{
    struct tm tm;

    shp_jd_to_tm(2026872, 25920000, &tm);
    return compare_tm(&tm, 10, 4, 837, 7, 12, 0, TUESDAY, 100);
}

static int
test_jd_1356001(void)
{
    struct tm tm;

    shp_jd_to_tm(1356001, 43200000, &tm);
    return compare_tm(&tm, 12, 7, -1000, 12, 0, 0, THURSDAY, 193);
}

static int
test_jd_1355867(void)
{
    struct tm tm;

    shp_jd_to_tm(1355867, 0, &tm);
    return compare_tm(&tm, 29, 2, -1000, 0, 0, 0, WEDNESDAY, 60);
}

static int
test_jd_1355671(void)
{
    struct tm tm;

    shp_jd_to_tm(1355671, 77760000, &tm);
    return compare_tm(&tm, 17, 8, -1001, 21, 36, 0, WEDNESDAY, 229);
}

static int
test_jd_0(void)
{
    struct tm tm;

    shp_jd_to_tm(0, 43200000, &tm);
    return compare_tm(&tm, 1, 1, -4712, 12, 0, 0, MONDAY, 1);
}

static int
test_yyyymmdd_15821015(void)
{
    struct tm tm;

    shp_yyyymmdd_to_tm("15821015", 8, &tm);
    return compare_tm(&tm, 15, 10, 1582, 0, 0, 0, FRIDAY, 288);
}

int
main(int argc, char *argv[])
{
    plan(20);
    ok(test_le16_to_uint16, "test shp_le16_to_uint16");
    ok(test_be32_to_int32, "test shp_be32_to_int32");
    ok(test_le32_to_int32, "test shp_le32_to_int32");
    ok(test_le32_to_uint32, "test shp_le32_to_uint32");
    ok(test_le64_to_int64, "test shp_le64_to_int64");
    ok(test_le64_to_double, "test shp_le64_to_double");
    ok(test_jd_2451545, "test shp_jd_to_tm with  2000 Jan.  1 12:00");
    ok(test_jd_2446823, "test shp_jd_to_tm with  1987 Jan. 27 00:00");
    ok(test_jd_2446966, "test shp_jd_to_tm with  1987 Jun. 19 12:00");
    ok(test_jd_2447188, "test shp_jd_to_tm with  1988 Jan. 27 00:00");
    ok(test_jd_2447332, "test shp_jd_to_tm with  1988 Jun. 19 12:00");
    ok(test_jd_2415021, "test shp_jd_to_tm with  1900 Jan.  1 12:00");
    ok(test_jd_2305448, "test shp_jd_to_tm with  1600 Jan.  1 12:00");
    ok(test_jd_2305813, "test shp_jd_to_tm with  1600 Dec. 31 12:00");
    ok(test_jd_2026872, "test shp_jd_to_tm with   837 Apr. 10 07:12");
    ok(test_jd_1356001, "test shp_jd_to_tm with -1000 July 12 12:00");
    ok(test_jd_1355867, "test shp_jd_to_tm with -1000 Feb. 29 00:00");
    ok(test_jd_1355671, "test shp_jd_to_tm with -1001 Aug. 17 21:36");
    ok(test_jd_0, "test shp_jd_to_tm with -4712 Jan.  1 12:00");
    ok(test_yyyymmdd_15821015, "test shp_yyyymmdd_to_tm");
    done_testing();
}
