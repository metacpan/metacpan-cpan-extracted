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
const shp_polygonm_t *polygonm;

size_t record_number;

/*
 * Main file tests
 */

static int
test_header_shape_type(void)
{
    return shp_header.type == SHP_TYPE_POLYGONM;
}

static int
test_record_shape_type(void)
{
    return shp_record->type == SHP_TYPE_POLYGONM;
}

static int
test_ranges(void)
{
    return polygonm->x_min == 1 && polygonm->y_min == 1 &&
           polygonm->x_max == 4 && polygonm->y_max == 4;
}

static int
test_num_parts(void)
{
    return polygonm->num_parts == 2;
}

static int
test_num_points(void)
{
    return polygonm->num_points == 10;
}

static int
test_points_match(void)
{
    size_t part_num, i, j, n;
    shp_pointm_t p;
    const shp_pointm_t points[10] = {
        {1, 1, 1}, {1, 4, 2}, {4, 4, 3}, {4, 1, 4}, {1, 1, 5},
        {2, 2, 6}, {2, 3, 7}, {3, 3, 8}, {3, 2, 9}, {2, 2, 10},
    };

    if (polygonm->num_points != 10) {
        return 0;
    }

    j = 0;
    for (part_num = 0; part_num < polygonm->num_parts; ++part_num) {
        shp_polygonm_points(polygonm, part_num, &i, &n);
        while (i < n) {
            shp_polygonm_pointm(polygonm, i, &p);
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
    ok(test_record_shape_type, "record shape type is polygonm");
    polygonm = &shp_record->shape.polygonm;
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
    const char *filename = "polygonm.shp";
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
        ok(test_header_shape_type, "header shape type is polygonm");
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
