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
const shp_polyline_t *polyline;

size_t record_number;

/*
 * Main file tests
 */

static int
test_header_shape_type(void)
{
    return shp_header.type == SHP_TYPE_POLYLINE;
}

static int
test_record_shape_type(void)
{
    return shp_record->type == SHP_TYPE_POLYLINE;
}

static int
test_ranges(void)
{
    return polyline->x_min == 1 && polyline->y_min == 1 &&
           polyline->x_max == 3 && polyline->y_max == 3;
}

static int
test_has_two_parts(void)
{
    return polyline->num_parts == 2;
}

static int
test_has_four_points(void)
{
    return polyline->num_points == 4;
}

static int
test_has_six_points(void)
{
    return polyline->num_points == 6;
}

static int
test_diagonal_cross_matches(void)
{
    size_t part_num, i, j, n;
    shp_point_t p;
    const shp_point_t points[4] = {{1, 1}, {3, 3}, {1, 3}, {3, 1}};

    if (polyline->num_parts != 2) {
        return 0;
    }

    j = 0;
    for (part_num = 0; part_num < polyline->num_parts; ++part_num) {
        shp_polyline_points(polyline, part_num, &i, &n);
        while (i < n) {
            shp_polyline_point(polyline, i, &p);
            if (p.x != points[j].x || p.y != points[j].y) {
                return 0;
            }
            ++j;
            ++i;
        }
    }
    return 1;
}

static int
test_greek_cross_matches(void)
{
    size_t part_num, i, j, n;
    shp_point_t p;
    const shp_point_t points[6] = {{1, 2}, {2, 2}, {2, 3},
                                   {2, 1}, {2, 2}, {3, 2}};

    if (polyline->num_parts != 2) {
        return 0;
    }

    j = 0;
    for (part_num = 0; part_num < polyline->num_parts; ++part_num) {
        shp_polyline_points(polyline, part_num, &i, &n);
        while (i < n) {
            shp_polyline_point(polyline, i, &p);
            if (p.x != points[j].x || p.y != points[j].y) {
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
    ok(test_record_shape_type, "record shape type is polyline");
    polyline = &shp_record->shape.polyline;
    switch (record_number) {
    case 0:
        ok(test_ranges, "ranges match");
        ok(test_has_two_parts, "diagonal cross has two parts");
        ok(test_has_four_points, "diagonal cross has four points");
        ok(test_diagonal_cross_matches, "diagonal cross matches");
        break;
    case 1:
        ok(test_has_two_parts, "greek cross has two parts");
        ok(test_has_six_points, "greek cross has six points");
        ok(test_greek_cross_matches, "greek cross matches");
        break;
    }
}

int
main(void)
{
    const char *filename = "polyline.shp";
    FILE *stream;
    shp_file_t fh;

    plan(10);

    stream = fopen(filename, "rb");
    if (stream == NULL) {
        fprintf(stderr, "# Cannot open file \"%s\": %s\n", filename,
                strerror(errno));
        return 1;
    }

    shp_init_file(&fh, stream, NULL);

    if (shp_read_header(&fh, &shp_header) > 0) {
        ok(test_header_shape_type, "header shape type is polyline");
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
