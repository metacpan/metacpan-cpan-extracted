#include "../shapereader.h"
#include "tap.h"
#include <errno.h>
#include <stdio.h>
#include <string.h>

#define BUENOS_AIRES 0
#define LOS_ANGELES 1
#define OSLO 2
#define SYDNEY 3

int tests_planned = 0;
int tests_run = 0;
int tests_failed = 0;

shp_header_t shp_header;
shp_record_t *shp_record;
shp_pointm_t point[4];

size_t record_number;

/*
 * Main file tests
 */

static int
test_header_shape_type(void)
{
    return shp_header.type == SHP_TYPE_POINTM;
}

static int
test_record_shape_type(void)
{
    return shp_record->type == SHP_TYPE_POINTM;
}

static int
test_buenos_aires(void)
{
    return point[BUENOS_AIRES].x == -58.3772 &&
           point[BUENOS_AIRES].y == -34.6132 && point[BUENOS_AIRES].m == 29;
}

static int
test_los_angeles(void)
{
    return point[LOS_ANGELES].x == -118.2437 &&
           point[LOS_ANGELES].y == 34.0522 && point[LOS_ANGELES].m == 26;
}

static int
test_oslo(void)
{
    return point[OSLO].x == 10.7461 && point[OSLO].y == 59.9127 &&
           point[OSLO].m == -13;
}

static int
test_sydney(void)
{
    return point[SYDNEY].x == 151.2073 && point[SYDNEY].y == -33.8679 &&
           point[SYDNEY].m == 17;
}

static void
test_shp(void)
{
    ok(test_record_shape_type, "record shape type is pointm");
    point[record_number] = shp_record->shape.pointm;
    switch (record_number) {
    case BUENOS_AIRES:
        ok(test_buenos_aires, "temperature in Buenos Aires");
        break;
    case LOS_ANGELES:
        ok(test_los_angeles, "temperature in Los Angeles");
        break;
    case OSLO:
        ok(test_oslo, "temperature in Oslo");
        break;
    case SYDNEY:
        ok(test_sydney, "temperature in Sydney");
        break;
    }
}

int
main(void)
{
    const char *filename = "pointm.shp";
    FILE *stream;
    shp_file_t fh;

    plan(9);

    stream = fopen(filename, "rb");
    if (stream == NULL) {
        fprintf(stderr, "# Cannot open file \"%s\": %s\n", filename,
                strerror(errno));
        return 1;
    }

    shp_init_file(&fh, stream, NULL);

    if (shp_read_header(&fh, &shp_header) > 0) {
        ok(test_header_shape_type, "header shape type is pointm");
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
