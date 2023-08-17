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
const shp_multipatch_t *multipatch;

size_t record_number;

/*
 * Main file tests
 */

static int
test_header_shape_type(void)
{
    return shp_header.type == SHP_TYPE_MULTIPATCH;
}

static int
test_record_shape_type(void)
{
    return shp_record->type == SHP_TYPE_MULTIPATCH;
}

static int
test_ranges(void)
{
    return multipatch->x_min == 0 && multipatch->y_min == 0 &&
           multipatch->x_max == 1 && multipatch->y_max == 1 &&
           multipatch->z_min == 0 && multipatch->z_max == 1 &&
           multipatch->m_min == 0 && multipatch->m_max == 29;
}

static int
test_num_parts(void)
{
    return multipatch->num_parts == 6;
}

static int
test_num_points(void)
{
    return multipatch->num_points == 30;
}

static int
test_points_match(void)
{
    size_t part_num, i, j, n;
    shp_part_type_t part_type;
    shp_pointz_t p;
    const shp_part_type_t part_types[6] = {
        SHP_PART_TYPE_RING, SHP_PART_TYPE_RING, SHP_PART_TYPE_RING,
        SHP_PART_TYPE_RING, SHP_PART_TYPE_RING, SHP_PART_TYPE_RING};
    const shp_pointz_t points[30] = {
        {0, 0, 0, 0},  {0, 1, 0, 1},  {0, 1, 1, 2},  {0, 0, 1, 3},
        {0, 0, 0, 4},  {0, 0, 0, 5},  {0, 0, 1, 6},  {1, 0, 1, 7},
        {1, 0, 0, 8},  {0, 0, 0, 9},  {0, 0, 1, 20}, {0, 1, 1, 21},
        {1, 1, 1, 22}, {1, 0, 1, 23}, {0, 0, 1, 24}, {1, 1, 0, 10},
        {1, 1, 1, 11}, {0, 1, 1, 12}, {0, 1, 0, 13}, {1, 1, 0, 14},
        {1, 0, 0, 15}, {1, 0, 1, 16}, {1, 1, 1, 17}, {1, 1, 0, 18},
        {1, 0, 0, 19}, {0, 0, 0, 25}, {0, 1, 0, 26}, {1, 1, 0, 27},
        {1, 0, 0, 28}, {0, 0, 0, 29}};

    if (multipatch->num_points != 30) {
        return 0;
    }

    j = 0;
    for (part_num = 0; part_num < multipatch->num_parts; ++part_num) {
        shp_multipatch_points(multipatch, part_num, &part_type, &i, &n);
        if (part_type != part_types[part_num]) {
            return 0;
        }
        while (i < n) {
            shp_multipatch_pointz(multipatch, i, &p);
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
    ok(test_record_shape_type, "record shape type is multipatch");
    multipatch = &shp_record->shape.multipatch;
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
    const char *filename = "multipatch.shp";
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
        ok(test_header_shape_type, "header shape type is multipatch");
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
