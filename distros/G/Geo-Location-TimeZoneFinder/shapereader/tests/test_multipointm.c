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
const shp_multipointm_t *multipointm;

size_t file_offset;
size_t record_number;

/*
 * Main file tests
 */

static int
test_header_shape_type(void)
{
    return shp_header.type == SHP_TYPE_MULTIPOINTM;
}

static int
test_header_measure_range(void)
{
    return shp_header.m_min == -5 && shp_header.m_max == 31;
}

static int
test_record_shape_type(void)
{
    return shp_record->type == SHP_TYPE_MULTIPOINTM;
}

static int
compare_points(size_t num_points, const shp_pointm_t points[])
{
    int ok = 0;
    size_t i;
    shp_pointm_t point;

    if (multipointm->num_points == num_points) {
        ok = 1;
        for (i = 0; i < num_points; ++i) {
            shp_multipointm_pointm(multipointm, i, &point);
            if (point.x != points[i].x || point.y != points[i].y ||
                point.m != points[i].m) {
                ok = 0;
                break;
            }
        }
    }
    return ok;
}

static int
test_measure_range_in_africa(void)
{
    return multipointm->m_min == 20 && multipointm->m_max == 31;
}

static int
test_points_in_africa(void)
{
    const shp_pointm_t points[3] = {
        {-0.2059, 5.6148, 31},   /* Accra */
        {31.2333, 30.0333, 20},  /* Cairo */
        {18.4233, -33.9189, 23}, /* Cape Town */
    };

    return compare_points(3, points);
}

static int
test_measure_range_in_europe(void)
{
    return multipointm->m_min == -5 && multipointm->m_max == 15;
}

static int
test_points_in_europe(void)
{
    const shp_pointm_t points[3] = {
        {-9.1427, 38.7369, 15}, /* Lisbon */
        {37.6184, 55.7512, -5}, /* Moscow */
        {-21.8277, 64.1283, 1}, /* Reykjavík */
    };

    return compare_points(3, points);
}

static void
test_shp(void)
{
    ok(test_record_shape_type, "record shape type is multipointm");
    multipointm = &shp_record->shape.multipointm;
    switch (record_number) {
    case 0:
        ok(test_measure_range_in_africa, "measure range in Africa");
        ok(test_points_in_africa, "points in Africa");
        break;
    case 1:
        ok(test_measure_range_in_europe, "measure range in Europe");
        ok(test_points_in_europe, "points in Europe");
        break;
    }
}

int
main(void)
{
    const char *shp_filename = "multipointm.shp";
    FILE *shp_stream;
    shp_file_t shp_fh;

    plan(8);

    shp_stream = fopen(shp_filename, "rb");
    if (shp_stream == NULL) {
        fprintf(stderr, "# Cannot open file \"%s\": %s\n", shp_filename,
                strerror(errno));
        return 1;
    }

    shp_init_file(&shp_fh, shp_stream, NULL);

    if (shp_read_header(&shp_fh, &shp_header) > 0) {
        ok(test_header_shape_type, "header shape type is multipointm");
        ok(test_header_measure_range, "measure range in header");
        record_number = 0;
        while (shp_read_record(&shp_fh, &shp_record) > 0) {
            test_shp();
            free(shp_record);
            ++record_number;
        }
    }

    fclose(shp_stream);

    done_testing();
}
