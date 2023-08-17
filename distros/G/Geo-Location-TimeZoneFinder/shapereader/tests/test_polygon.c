#include "../shapereader.h"
#include "tap.h"
#include <errno.h>
#include <stdio.h>
#include <string.h>

#define UNUSED(x) (void)(x)

int tests_planned = 0;
int tests_run = 0;
int tests_failed = 0;

const shp_header_t *shp_header;
const shp_record_t *shp_record;
const shp_polygon_t *polygon;

const shx_header_t *shx_header;
shx_record_t shx_records[6];

size_t file_offset;
size_t record_number;

size_t num_bytes;
size_t file_size;

int rc;

/*
 * Header tests
 */

static int
test_file_code(void)
{
    return shp_header->file_code == 9994;
}

static int
test_file_length(void)
{
    return shp_header->file_size == file_size;
}

static int
test_entire_file_read(void)
{
    return num_bytes == file_size;
}

static int
test_version(void)
{
    return shp_header->version == 1000;
}

static int
test_header_shape_type(void)
{
    return shp_header->type == SHP_TYPE_POLYGON;
}

static int
test_x_min(void)
{
    return shp_header->x_min == -180.0;
}

static int
test_y_min(void)
{
    return shp_header->y_min == -90.0;
}

static int
test_x_max(void)
{
    return shp_header->x_max == 180.0;
}

static int
test_y_max(void)
{
    return shp_header->y_max == 90.0;
}

/*
 * Rectangle tests
 */

static int
test_is_polygon(void)
{
    return shp_record->type == SHP_TYPE_POLYGON;
}

static int
test_is_inside(void)
{
    shp_point_t point = {0.5, 0.5};
    return shp_point_in_polygon(&point, polygon) == 1;
}

static int
test_is_outside(void)
{
    shp_point_t point = {0.1, 0.5};
    return shp_point_in_polygon(&point, polygon) == 0;
}

static int
test_is_on_top_edge(void)
{
    shp_point_t point = {0.5, 0.8};
    return shp_point_in_polygon(&point, polygon) == -1;
}

static int
test_is_on_bottom_edge(void)
{
    shp_point_t point = {0.5, 0.2};
    return shp_point_in_polygon(&point, polygon) == -1;
}

static int
test_is_on_left_edge(void)
{
    shp_point_t point = {0.2, 0.5};
    return shp_point_in_polygon(&point, polygon) == -1;
}

static int
test_is_on_right_edge(void)
{
    shp_point_t point = {0.8, 0.5};
    return shp_point_in_polygon(&point, polygon) == -1;
}

static int
test_is_outside_box(void)
{
    shp_point_t point = {1.1, 0.5};
    return shp_point_in_polygon(&point, polygon) == 0;
}

/*
 * Triangle tests
 */

static int
test_has_two_parts(void)
{
    return polygon->num_parts == 2;
}

static int
test_has_eight_points(void)
{
    return polygon->num_points == 8;
}

static int
test_is_inside_with_hole(void)
{
    shp_point_t point = {0.3, 0.3};
    return shp_point_in_polygon(&point, polygon) == 1;
}

static int
test_is_outside_with_hole(void)
{
    shp_point_t point = {0.3, 0.7};
    return shp_point_in_polygon(&point, polygon) == 0;
}

static int
test_is_in_the_hole(void)
{
    shp_point_t point = {0.5, 0.5};
    return shp_point_in_polygon(&point, polygon) == 0;
}

static int
test_is_on_inside_edge(void)
{
    shp_point_t point = {0.45, 0.4};
    return shp_point_in_polygon(&point, polygon) == -1;
}

static int
test_is_on_outside_egde(void)
{
    shp_point_t point = {0.65, 0.2};
    return shp_point_in_polygon(&point, polygon) == -1;
}

/*
 * Location tests
 */

static int
test_is_los_angeles(void)
{
    shp_point_t point = {-122.35007, 47.650499};
    return shp_point_in_polygon(&point, polygon) == 1;
}

static int
test_is_africa_juba(void)
{
    shp_point_t point = {28.0, 9.5}; /* Disputed area */
    return shp_point_in_polygon(&point, polygon) == 1;
}

static int
test_is_africa_khartoum(void)
{
    shp_point_t point = {28.0, 9.5}; /* Disputed area */
    return shp_point_in_polygon(&point, polygon) == 1;
}

static int
test_is_oslo(void)
{
    shp_point_t point = {10.757933, 59.911491};
    return shp_point_in_polygon(&point, polygon) == 1;
}

/**
 * Other tests
 */

static int
test_record_shape_type(void)
{
    return shp_record->type == SHP_TYPE_POLYGON;
}

static int
test_index_shape_type(void)
{
    return shx_header->type == SHP_TYPE_POLYGON;
}

static int
test_file_offset(void)
{
    return file_offset == shx_records[record_number].file_offset;
}

static int
test_record_size(void)
{
    return shp_record->record_size == shx_records[record_number].record_size;
}

static int
test_seek_first(void)
{
    return rc == 1;
}

static int
test_seek_eof(void)
{
    return rc == 0;
}

static int
test_seek_invalid(void)
{
    return rc == -1;
}

static int
handle_shp_header(shp_file_t *fh, const shp_header_t *h)
{
    UNUSED(fh);
    shp_header = h;
    record_number = 0;
    ok(test_file_code, "file code is 9994");
    ok(test_file_length, "file length matches file size");
    ok(test_version, "version is 1000");
    ok(test_header_shape_type, "shape type is polygon");
    ok(test_x_min, "x_min is set");
    ok(test_y_min, "y_min is set");
    ok(test_x_max, "x_max is set");
    ok(test_y_max, "y_max is set");
    return 1;
}

static int
handle_shp_record(shp_file_t *fh, const shp_header_t *h,
                  const shp_record_t *r, size_t offset)
{
    UNUSED(fh);
    shp_header = h;
    shp_record = r;
    file_offset = offset;
    polygon = &r->shape.polygon;
    ok(test_record_shape_type, "shape type is polygon");
    switch (record_number) {
    case 0:
        ok(test_is_polygon, "shape is polygon");
        ok(test_is_inside, "point is inside");
        ok(test_is_outside, "point is outside");
        ok(test_is_on_top_edge, "point is on top edge");
        ok(test_is_on_bottom_edge, "point is on bottom edge");
        ok(test_is_on_left_edge, "point is on left edge");
        ok(test_is_on_right_edge, "point is on right edge");
        ok(test_is_outside_box, "point is outside bounding box");
        break;
    case 1:
        ok(test_has_two_parts, "polygon has two parts");
        ok(test_has_eight_points, "polygon has eight points");
        ok(test_is_inside_with_hole, "point is inside polygon with hole");
        ok(test_is_outside_with_hole, "point is outside polygon with hole");
        ok(test_is_in_the_hole, "point is in the hole");
        ok(test_is_on_inside_edge, "point is on inside edge");
        ok(test_is_on_outside_egde, "point is on outside edge");
        break;
    case 2:
        ok(test_is_los_angeles, "location is in America/Los_Angeles");
        break;
    case 3:
        ok(test_is_africa_juba, "location is in Africa/Juba");
        break;
    case 4:
        ok(test_is_africa_khartoum, "location is in Africa/Khartoum");
        break;
    case 5:
        ok(test_is_oslo, "location is in Europe/Oslo");
        break;
    }
    if (record_number < 6) {
        ok(test_file_offset, "file offset matches");
        ok(test_record_size, "record size matches");
    }
    ++record_number;
    return 1;
}

static int
handle_shx_header(shx_file_t *fh, const shx_header_t *h)
{
    UNUSED(fh);
    shx_header = h;
    record_number = 0;
    ok(test_index_shape_type, "shape type is polygon");
    return 1;
}

static int
handle_shx_record(shx_file_t *fh, const shx_header_t *h,
                  const shx_record_t *r)
{
    UNUSED(fh);
    shx_header = h;
    if (record_number < 6) {
        shx_records[record_number] = *r;
    }
    ++record_number;
    return 1;
}

int
main(void)
{
    const char *shp_filename = "polygon.shp";
    const char *shx_filename = "polygon.shx";
    FILE *shp_stream, *shx_stream;
    shp_file_t shp_fh;
    shx_file_t shx_fh;

    plan(50);

    shp_stream = fopen(shp_filename, "rb");
    if (shp_stream == NULL) {
        fprintf(stderr, "# Cannot open file \"%s\": %s\n", shp_filename,
                strerror(errno));
        return 1;
    }

    shx_stream = fopen(shx_filename, "rb");
    if (shx_stream == NULL) {
        fprintf(stderr, "# Cannot open file \"%s\": %s\n", shx_filename,
                strerror(errno));
        return 1;
    }

    fseek(shp_stream, 0, SEEK_END);
    file_size = ftell(shp_stream);
    fseek(shp_stream, 0, SEEK_SET);

    shp_init_file(&shp_fh, shp_stream, NULL);
    shx_init_file(&shx_fh, shx_stream, NULL);

    shp_set_error(&shx_fh, "%s", "");
    shx_set_error(&shx_fh, "%s", "");

    if (shx_read(&shx_fh, handle_shx_header, handle_shx_record) == -1) {
        fprintf(stderr, "# Cannot read file \"%s\": %s\n", shx_filename,
                shx_fh.error);
    }

    if (shp_read(&shp_fh, handle_shp_header, handle_shp_record) == -1) {
        fprintf(stderr, "# Cannot read file \"%s\": %s\n", shp_filename,
                shp_fh.error);
    }

    num_bytes = shp_fh.num_bytes;
    ok(test_entire_file_read, "entire file has been read");

    rc = shx_seek_record(&shx_fh, 1, &shx_records[0]);
    ok(test_seek_first, "seek to first record");

    rc = shx_seek_record(&shx_fh, 715827874UL, &shx_records[0]);
    ok(test_seek_eof, "seek beyond end of file");

    rc = shx_seek_record(&shx_fh, 715827875UL, &shx_records[0]);
    ok(test_seek_invalid, "seek to impossible record number");

    fclose(shp_stream);
    fclose(shx_stream);

    done_testing();
}
