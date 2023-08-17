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
const shp_multipointz_t *multipointz;

size_t file_offset;
size_t record_number;

/*
 * Main file tests
 */

static int
test_header_shape_type(void)
{
    return shp_header.type == SHP_TYPE_MULTIPOINTZ;
}

static int
test_record_shape_type(void)
{
    return shp_record->type == SHP_TYPE_MULTIPOINTZ;
}

static int
compare_points(size_t num_points, const shp_pointz_t points[])
{
    int ok = 0;
    size_t i;
    shp_pointz_t point;

    if (multipointz->num_points == num_points) {
        ok = 1;
        for (i = 0; i < num_points; ++i) {
            shp_multipointz_pointz(multipointz, i, &point);
            if (point.x != points[i].x || point.y != points[i].y ||
                point.z != points[i].z || point.m != points[i].m) {
                ok = 0;
                break;
            }
        }
    }
    return ok;
}

static int
test_north_america(void)
{
    const shp_pointz_t points[3] = {
        {-151.007708, 63.068515, 6190, 7450}, /* Denali */
        {-121.760556, 46.853056, 4392, 1177}, /* Mount Rainier */
        {-98.623056, 19.027778, 5452, 142},   /* Popocatépetl */
    };

    return compare_points(3, points);
}

static int
test_south_america(void)
{
    const shp_pointz_t points[3] = {
        {-70.011667, -32.653333, 6961, 16536}, /* Aconcagua */
        {-78.437131, -0.684067, 5897, 96.67},  /* Cotopaxi */
        {-68.54176, -27.10928, 6893, 630},     /* Ojos del Salado */
    };

    return compare_points(3, points);
}

static void
test_shp(void)
{
    ok(test_record_shape_type, "record shape type is multipointz");
    multipointz = &shp_record->shape.multipointz;
    switch (record_number) {
    case 0:
        ok(test_north_america, "mountaints in North America");
        break;
    case 1:
        ok(test_south_america, "mountains in South America");
        break;
    }
}

int
main(void)
{
    const char *shp_filename = "multipointz.shp";
    FILE *shp_stream;
    shp_file_t shp_fh;

    plan(5);

    shp_stream = fopen(shp_filename, "rb");
    if (shp_stream == NULL) {
        fprintf(stderr, "# Cannot open file \"%s\": %s\n", shp_filename,
                strerror(errno));
        return 1;
    }

    shp_init_file(&shp_fh, shp_stream, NULL);

    if (shp_read_header(&shp_fh, &shp_header) > 0) {
        ok(test_header_shape_type, "header shape type is multipointz");
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
