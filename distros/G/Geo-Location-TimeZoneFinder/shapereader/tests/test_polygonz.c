#include "../shapereader.h"
#include "tap.h"
#include <errno.h>
#include <stdio.h>
#include <string.h>

int tests_planned = 0;
int tests_run = 0;
int tests_failed = 0;

shp_header_t shp_header;
shp_record_t *shp_record;
const shp_polygonz_t *polygonz;

size_t record_number;

/*
 * Main file tests
 */

static int
test_header_shape_type(void)
{
    return shp_header.type == SHP_TYPE_POLYGONZ;
}

static int
test_record_shape_type(void)
{
    return shp_record->type == SHP_TYPE_POLYGONZ;
}

static int
test_ranges(void)
{
    return polygonz->x_min == 0 && polygonz->y_min == 0 &&
           polygonz->x_max == 1 && polygonz->y_max == 1 &&
           polygonz->z_min == 0 && polygonz->z_max == 1 &&
           polygonz->m_min == 0 && polygonz->m_max == 29;
}

static int
test_num_parts(void)
{
    return polygonz->num_parts == 6;
}

static int
test_num_points(void)
{
    return polygonz->num_points == 30;
}

static int
test_points_match(void)
{
    size_t part_num, i, j, n;
    shp_pointz_t p;
    const shp_pointz_t points[30] = {
        {0, 0, 0, 0},  {0, 1, 0, 1},  {0, 1, 1, 2},  {0, 0, 1, 3},
        {0, 0, 0, 4},  {0, 0, 0, 5},  {0, 0, 1, 6},  {1, 0, 1, 7},
        {1, 0, 0, 8},  {0, 0, 0, 9},  {0, 0, 1, 20}, {0, 1, 1, 21},
        {1, 1, 1, 22}, {1, 0, 1, 23}, {0, 0, 1, 24}, {1, 1, 0, 10},
        {1, 1, 1, 11}, {0, 1, 1, 12}, {0, 1, 0, 13}, {1, 1, 0, 14},
        {1, 0, 0, 15}, {1, 0, 1, 16}, {1, 1, 1, 17}, {1, 1, 0, 18},
        {1, 0, 0, 19}, {0, 0, 0, 25}, {0, 1, 0, 26}, {1, 1, 0, 27},
        {1, 0, 0, 28}, {0, 0, 0, 29}};

    if (polygonz->num_points != 30) {
        return 0;
    }

    j = 0;
    for (part_num = 0; part_num < polygonz->num_parts; ++part_num) {
        shp_polygonz_points(polygonz, part_num, &i, &n);
        while (i < n) {
            shp_polygonz_pointz(polygonz, i, &p);
            if (p.x != points[j].x || p.y != points[j].y ||
                p.m != points[j].m) {
                return 0;
            }
            ++j;
            ++i;
        }
    }
    return 1;
}

static void
test_shp(void)
{
    ok(test_record_shape_type, "record shape type is polygonz");
    polygonz = &shp_record->shape.polygonz;
    switch (record_number) {
    case 0:
        ok(test_ranges, "ranges match");
        ok(test_num_parts, "num_parts matches");
        ok(test_num_points, "num_points matches");
        ok(test_points_match, "points match");
        break;
    }
}

int
main(void)
{
    const char *filename = "polygonz.shp";
    FILE *stream;
    shp_file_t fh;

    plan(6);

    stream = fopen(filename, "rb");
    if (stream == NULL) {
        fprintf(stderr, "# Cannot open file \"%s\": %s\n", filename,
                strerror(errno));
        return 1;
    }

    shp_init_file(&fh, stream, NULL);

    if (shp_read_header(&fh, &shp_header) > 0) {
        ok(test_header_shape_type, "header shape type is polygonz");
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
