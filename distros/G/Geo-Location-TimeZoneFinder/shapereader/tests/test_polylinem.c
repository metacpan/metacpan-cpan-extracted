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
const shp_polylinem_t *polylinem;

size_t record_number;

/*
 * Main file tests
 */

static int
test_header_shape_type(void)
{
    return shp_header.type == SHP_TYPE_POLYLINEM;
}

static int
test_record_shape_type(void)
{
    return shp_record->type == SHP_TYPE_POLYLINEM;
}

static int
test_ranges(void)
{
    return polylinem->x_min == 1 && polylinem->y_min == 1 &&
           polylinem->x_max == 4 && polylinem->y_max == 2;
}

static int
test_num_parts(void)
{
    return polylinem->num_parts == 2;
}

static int
test_num_points(void)
{
    return polylinem->num_points == 7;
}

static int
test_points_match(void)
{
    size_t part_num, i, j, n;
    shp_pointm_t p;
    const shp_pointm_t points[7] = {{1, 1, 1}, {2, 1, 2}, {2, 2, 3},
                                    {2, 2, 4}, {3, 2, 5}, {3, 1, 6},
                                    {4, 1, 7}};

    if (polylinem->num_points != 7) {
        return 0;
    }

    j = 0;
    for (part_num = 0; part_num < polylinem->num_parts; ++part_num) {
        shp_polylinem_points(polylinem, part_num, &i, &n);
        while (i < n) {
            shp_polylinem_pointm(polylinem, i, &p);
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
    ok(test_record_shape_type, "record shape type is polylinem");
    polylinem = &shp_record->shape.polylinem;
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
    const char *filename = "polylinem.shp";
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
        ok(test_header_shape_type, "header shape type is polylinem");
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
