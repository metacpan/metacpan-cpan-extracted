#include "../shapereader.h"
#include "tap.h"
#include <errno.h>
#include <stdio.h>
#include <string.h>

#define NUM_RECORDS 2

#define NUM_DBF_RECORD_TESTS 1
#define NUM_SHP_RECORD_TESTS 2
#define NUM_SHX_RECORD_TESTS 2

int tests_planned = 0;
int tests_run = 0;
int tests_failed = 0;

dbf_header_t *dbf_header;
dbf_record_t *dbf_record;

shp_header_t shp_header;
shp_record_t *shp_record;
const shp_multipoint_t *multipoint;

shx_header_t shx_header;
shx_record_t shx_record;

size_t file_offset;
size_t record_number;

/*
 * Database file tests
 */

static int
test_num_records(void)
{
    return dbf_header->num_records == NUM_RECORDS;
}

static int
compare_area(const char *area)
{
    int ok = 0;
    char *s;
    const dbf_field_t *field;

    field = &dbf_header->fields[0];
    switch (field->type) {
    case DBF_TYPE_CHARACTER:
        s = dbf_record_strdup(dbf_record, field);
        if (s != NULL) {
            ok = (strcmp(s, area) == 0);
            free(s);
        }
        break;
    default:
        break;
    }
    return ok;
}

static int
test_is_baerensee(void)
{
    return compare_area("B\xe4rensee");
}

static int
test_is_schoenbuch(void)
{
    return compare_area("Sch\xf6nbuch");
}

static void
test_dbf(void)
{
    switch (record_number) {
    case 0:
        ok(test_is_baerensee, "area is Bärensee");
        break;
    case 1:
        ok(test_is_schoenbuch, "area is Schönbuch");
        break;
    }
}

/*
 * Main file tests
 */

static int
test_header_shape_type(void)
{
    return shp_header.type == SHP_TYPE_MULTIPOINT;
}

static int
test_record_shape_type(void)
{
    return shp_record->type == SHP_TYPE_MULTIPOINT;
}

static int
compare_points(size_t num_points, const shp_point_t points[])
{
    int ok = 0;
    size_t i;
    shp_point_t point;

    if (multipoint->num_points == num_points) {
        ok = 1;
        for (i = 0; i < num_points; ++i) {
            shp_multipoint_point(multipoint, i, &point);
            if (point.x != points[i].x || point.y != points[i].y) {
                ok = 0;
                break;
            }
        }
    }
    return ok;
}

static int
test_baerensee(void)
{
    const shp_point_t points[2] = {
        {9.0909, 48.7642}, /* Grillplatz am Wapitiweg */
        {9.0911, 48.7719}, /* Pappelgartengrillhütte */
    };

    return compare_points(2, points);
}

static int
test_schoenbuch(void)
{
    const shp_point_t points[4] = {
        {8.9973, 48.5851}, /* Feuerstelle Ziegelweiher */
        {9.0611, 48.5763}, /* Grillstelle Brühlweiher */
        {9.0607, 48.5671}, /* Zwergeles Feuerstelle */
        {9.0504, 48.6091}, /* Feuerstelle Zweites Häusle */
    };

    return compare_points(4, points);
}

static void
test_shp(void)
{
    ok(test_record_shape_type, "record shape type is multipoint");
    multipoint = &shp_record->shape.multipoint;
    switch (record_number) {
    case 0:
        ok(test_baerensee, "BBQ areas in the Bärensee area");
        break;
    case 1:
        ok(test_schoenbuch, "BBQ areas in the Schönbuch forest");
        break;
    }
}

/**
 * Index file tests
 */

static int
test_file_offset(void)
{
    return shx_record.file_offset == file_offset;
}

static int
test_content_length(void)
{
    return shx_record.record_size == shp_record->record_size;
}

static void
test_shx(void)
{
    ok(test_file_offset, "file offsets match");
    ok(test_content_length, "content lengths match");
}

int
main(void)
{
    const char *dbf_filename = "multipoint.dbf";
    const char *shp_filename = "multipoint.shp";
    const char *shx_filename = "multipoint.shx";
    FILE *dbf_stream, *shp_stream, *shx_stream;
    dbf_file_t dbf_fh;
    shp_file_t shp_fh;
    shx_file_t shx_fh;

    plan(2 + NUM_RECORDS * (NUM_DBF_RECORD_TESTS +
                            (NUM_SHP_RECORD_TESTS * NUM_RECORDS) +
                            NUM_SHX_RECORD_TESTS));

    dbf_stream = fopen(dbf_filename, "rb");
    if (dbf_stream == NULL) {
        fprintf(stderr, "# Cannot open file \"%s\": %s\n", dbf_filename,
                strerror(errno));
        return 1;
    }

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

    dbf_init_file(&dbf_fh, dbf_stream, NULL);
    shp_init_file(&shp_fh, shp_stream, NULL);
    shx_init_file(&shx_fh, shx_stream, NULL);

    if (dbf_read_header(&dbf_fh, &dbf_header) > 0) {
        ok(test_num_records, "number of records");
        if (shp_read_header(&shp_fh, &shp_header) > 0 &&
            shx_read_header(&shx_fh, &shx_header) > 0) {
            ok(test_header_shape_type, "header shape type is multipoint");
            record_number = 0;
            while (dbf_read_record(&dbf_fh, &dbf_record) > 0) {
                if (!dbf_record_is_deleted(dbf_record)) {
                    file_offset = (size_t) ftell(shp_stream);
                    if (shp_read_record(&shp_fh, &shp_record) > 0) {
                        if (shx_read_record(&shx_fh, &shx_record) > 0) {
                            test_dbf();
                            test_shp();
                            test_shx();
                        }
                        free(shp_record);
                    }
                    ++record_number;
                }
                free(dbf_record);
            }
        }
        free(dbf_header);
    }

    for (record_number = 0; record_number < NUM_RECORDS; ++record_number) {
        if (shx_seek_record(&shx_fh, record_number, &shx_record) > 0) {
            file_offset = shx_record.file_offset;
            if (shp_seek_record(&shp_fh, file_offset, &shp_record) > 0) {
                test_shp();
                free(shp_record);
            }
        }
    }

    fclose(dbf_stream);
    fclose(shp_stream);
    fclose(shx_stream);

    done_testing();
}
