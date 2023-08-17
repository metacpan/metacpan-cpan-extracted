#include "../shapereader.h"
#include "tap.h"
#include <errno.h>
#include <stdio.h>
#include <string.h>

#define GROSSGLOCKNER 0
#define MONT_BLANC 1
#define ZUGSPITZE 2

int tests_planned = 0;
int tests_run = 0;
int tests_failed = 0;

shp_header_t shp_header;
shp_record_t *shp_record;
shp_pointz_t point[3];

size_t record_number;

/*
 * Main file tests
 */

static int
test_header_shape_type(void)
{
    return shp_header.type == SHP_TYPE_POINTZ;
}

static int
test_x_min(void)
{
    return shp_header.x_min == 6.864325;
}

static int
test_x_max(void)
{
    return shp_header.x_max == 12.6939;
}

static int
test_y_min(void)
{
    return shp_header.y_min == 45.832544;
}

static int
test_y_max(void)
{
    return shp_header.y_max == 47.42122;
}

static int
test_z_min(void)
{
    return shp_header.z_min == 2962.06;
}

static int
test_z_max(void)
{
    return shp_header.z_max == 4807.81;
}

static int
test_m_min(void)
{
    return shp_header.m_min == 25.8;
}

static int
test_m_max(void)
{
    return shp_header.m_max == 2812;
}

static int
test_record_shape_type(void)
{
    return shp_record->type == SHP_TYPE_POINTZ;
}

static int
test_grossglockner(void)
{
    return point[GROSSGLOCKNER].x == 12.6939 &&
           point[GROSSGLOCKNER].y == 47.074531 &&
           point[GROSSGLOCKNER].z == 3798 && point[GROSSGLOCKNER].m == 175;
}

static int
test_mont_blanc(void)
{
    return point[MONT_BLANC].x == 6.864325 &&
           point[MONT_BLANC].y == 45.832544 &&
           point[MONT_BLANC].z == 4807.81 && point[MONT_BLANC].m == 2812;
}

static int
test_zugspitze(void)
{
    return point[ZUGSPITZE].x == 10.9863 && point[ZUGSPITZE].y == 47.42122 &&
           point[ZUGSPITZE].z == 2962.06 && point[ZUGSPITZE].m == 25.8;
}

static void
test_shp(void)
{
    ok(test_record_shape_type, "record shape type is pointz");
    point[record_number] = shp_record->shape.pointz;
    switch (record_number) {
    case GROSSGLOCKNER:
        ok(test_grossglockner, "Großglockner");
        break;
    case MONT_BLANC:
        ok(test_mont_blanc, "Mont Blanc");
        break;
    case ZUGSPITZE:
        ok(test_zugspitze, "Zugspitze");
        break;
    }
}

int
main(void)
{
    const char *filename = "pointz.shp";
    FILE *stream;
    shp_file_t fh;

    plan(15);

    stream = fopen(filename, "rb");
    if (stream == NULL) {
        fprintf(stderr, "# Cannot open file \"%s\": %s\n", filename,
                strerror(errno));
        return 1;
    }

    shp_init_file(&fh, stream, NULL);

    if (shp_read_header(&fh, &shp_header) > 0) {
        ok(test_header_shape_type, "header shape type is pointz");
        ok(test_x_min, "x_min matches");
        ok(test_x_max, "x_max matches");
        ok(test_y_min, "y_min matches");
        ok(test_y_max, "y_max matches");
        ok(test_z_min, "z_min matches");
        ok(test_z_max, "z_max matches");
        ok(test_m_min, "m_min matches");
        ok(test_m_max, "m_max matches");
        record_number = 0;
        while (shp_read_record(&fh, &shp_record) > 0) {
            test_shp();
            free(shp_record);
            ++record_number;
        }
        fprintf(stderr, "# %s\n", fh.error);
    }

    fclose(stream);

    done_testing();
}
