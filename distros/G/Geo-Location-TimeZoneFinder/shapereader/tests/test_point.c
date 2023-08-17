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
const shp_point_t *point;

size_t record_number;

/*
 * Box tests
 */

double x_min = -1.0;
double y_min = -1.0;
double x_max = 1.0;
double y_max = 1.0;

static int
test_is_in_box(void)
{
    shp_point_t p = {0.0, 0.0};
    return shp_point_in_bounding_box(&p, x_min, y_min, x_max, y_max) == 1;
}

static int
test_is_left_of_box(void)
{
    shp_point_t p = {-1.0001, 0.0};
    return shp_point_in_bounding_box(&p, x_min, y_min, x_max, y_max) == 0;
}

static int
test_is_right_of_box(void)
{
    shp_point_t p = {1.0001, 0.0};
    return shp_point_in_bounding_box(&p, x_min, y_min, x_max, y_max) == 0;
}

static int
test_is_below_box(void)
{
    shp_point_t p = {0.0, -1.0001};
    return shp_point_in_bounding_box(&p, x_min, y_min, x_max, y_max) == 0;
}

static int
test_is_above_box(void)
{
    shp_point_t p = {0.0, 1.0001};
    return shp_point_in_bounding_box(&p, x_min, y_min, x_max, y_max) == 0;
}

static int
test_is_on_left_boundary(void)
{
    shp_point_t p = {-1.0, 0.0};
    return shp_point_in_bounding_box(&p, x_min, y_min, x_max, y_max) == -1;
}

static int
test_is_on_right_boundary(void)
{
    shp_point_t p = {1.0, 0.0};
    return shp_point_in_bounding_box(&p, x_min, y_min, x_max, y_max) == -1;
}

static int
test_is_on_bottom_boundary(void)
{
    shp_point_t p = {0.0, -1.0};
    return shp_point_in_bounding_box(&p, x_min, y_min, x_max, y_max) == -1;
}

static int
test_is_on_top_boundary(void)
{
    shp_point_t p = {0.0, 1.0};
    return shp_point_in_bounding_box(&p, x_min, y_min, x_max, y_max) == -1;
}

/*
 * Main file tests
 */

static int
test_header_shape_type(void)
{
    return shp_header.type == SHP_TYPE_POINT;
}

static int
test_record_shape_type(void)
{
    return shp_record->type == SHP_TYPE_POINT;
}

static int
test_freiburg(void)
{
    return point->x == 7.8522 && point->y == 47.9959;
}

static int
test_karlsruhe(void)
{
    return point->x == 8.4044 && point->y == 49.0094;
}

static int
test_mannheim(void)
{
    return point->x == 8.4669 && point->y == 49.4891;
}

static int
test_stuttgart(void)
{
    return point->x == 9.1770 && point->y == 48.7823;
}

static void
test_shp(void)
{
    ok(test_record_shape_type, "record shape type is point");
    point = &shp_record->shape.point;
    switch (record_number) {
    case 0:
        ok(test_freiburg, "location is Freiburg");
        break;
    case 1:
        ok(test_karlsruhe, "location is Karlsruhe");
        break;
    case 2:
        ok(test_mannheim, "location is Mannheim");
        break;
    case 3:
        ok(test_stuttgart, "location is Stuttgart");
        break;
    }
}

int
main(void)
{
    const char *filename = "point.shp";
    FILE *stream;
    shp_file_t fh;

    plan(18);

    ok(test_is_in_box, "point is in box");
    ok(test_is_left_of_box, "point is left of box");
    ok(test_is_right_of_box, "point is right of box");
    ok(test_is_below_box, "point is below box");
    ok(test_is_above_box, "point is above box");
    ok(test_is_on_left_boundary, "point is on left boundary");
    ok(test_is_on_right_boundary, "point is on right boundary");
    ok(test_is_on_bottom_boundary, "point is on bottom boundary");
    ok(test_is_on_top_boundary, "point is on top boundary");

    stream = fopen(filename, "rb");
    if (stream == NULL) {
        fprintf(stderr, "# Cannot open file \"%s\": %s\n", filename,
                strerror(errno));
        return 1;
    }

    shp_init_file(&fh, stream, NULL);

    if (shp_read_header(&fh, &shp_header) > 0) {
        ok(test_header_shape_type, "header shape type is point");
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
