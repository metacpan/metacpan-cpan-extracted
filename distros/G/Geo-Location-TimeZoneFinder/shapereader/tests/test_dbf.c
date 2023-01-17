#ifdef HAVE_CONFIG_H
#include "config.h"
#else
#define HAVE_UNISTD_H 1
#define HAVE_CHDIR 1
#endif
#include "../shapereader.h"
#include "tap.h"
#include <errno.h>
#include <stdio.h>
#include <string.h>
#if HAVE_UNISTD_H
#include <unistd.h>
#endif

#define FESTIVAL 0
#define FROM 1
#define TO 2
#define LOCATION 3
#define LATITUDE 4
#define LONGITUDE 5
#define BANDS 6
#define ADMISSION 7
#define BEER_PRICE 8
#define FOOD_PRICE 9
#define SOLD_OUT 10

#define SUNDAY 0
#define MONDAY 1
#define TUESDAY 2
#define WEDNESDAY 3
#define THURSDAY 4
#define FRIDAY 5
#define SATURDAY 6

int tests_planned = 0;
int tests_run = 0;
int tests_failed = 0;

const dbf_header_t *header;
const dbf_record_t *record;

dbf_file_t fh;
size_t record_number = 0;

/*
 * Header tests
 */

static int
test_database_version(void)
{
    return header->version == DBFV_VISUAL_FOXPRO;
}

static int
test_num_records(void)
{
    return header->num_records > 0;
}

static int
test_header_size(void)
{
    return header->header_size == 32 + header->num_fields * 32 + 1;
}

static int
test_record_size(void)
{
    return header->record_size > 0;
}

static int
test_num_fields(void)
{
    return header->num_fields == 11;
}

static int
test_field_festival(void)
{
    dbf_field_t *field = &header->fields[FESTIVAL];
    return (field->type == DBFT_CHARACTER);
}

static int
test_field_from(void)
{
    dbf_field_t *field = &header->fields[FROM];
    return (field->type == DBFT_DATE);
}

static int
test_field_to(void)
{
    dbf_field_t *field = &header->fields[TO];
    return (field->type == DBFT_DATETIME);
}

static int
test_field_location(void)
{
    dbf_field_t *field = &header->fields[LOCATION];
    return (strcmp(field->name, "LOCATION") == 0);
}

static int
test_field_latitude(void)
{
    dbf_field_t *field = &header->fields[LATITUDE];
    return (field->type == DBFT_FLOAT);
}

static int
test_field_longitude(void)
{
    dbf_field_t *field = &header->fields[LONGITUDE];
    return (field->type == 'B');
}

static int
test_field_bands(void)
{
    dbf_field_t *field = &header->fields[BANDS];
    return (field->type == DBFT_INTEGER);
}

static int
test_field_admission(void)
{
    dbf_field_t *field = &header->fields[ADMISSION];
    return (field->type == DBFT_NUMBER && field->decimal_places == 0);
}

static int
test_field_beer_price(void)
{
    dbf_field_t *field = &header->fields[BEER_PRICE];
    return (field->type == DBFT_CURRENCY && field->decimal_places == 4);
}

static int
test_field_food_price(void)
{
    dbf_field_t *field = &header->fields[FOOD_PRICE];
    return (field->type == DBFT_NUMBER);
}

static int
test_field_sold_out(void)
{
    dbf_field_t *field = &header->fields[SOLD_OUT];
    return (field->type == DBFT_LOGICAL && field->length == 1);
}

/*
 * Record tests
 */

static int
test_is_graspop(void)
{
    int ok = 0;
    dbf_field_t *field = &header->fields[FESTIVAL];
    char *s;

    s = dbf_record_strdup(record, field);
    if (s != NULL) {
        ok = (strcmp(s, "Graspop Metal Meeting") == 0);
        free(s);
    }
    return ok;
}

static int
test_from_date(void)
{
    dbf_field_t *field = &header->fields[FROM];
    struct tm tm;

    return (dbf_record_date(record, field, &tm) && tm.tm_mday == 16 &&
            tm.tm_mon + 1 == 6 && tm.tm_year + 1900 == 2022 &&
            tm.tm_wday == THURSDAY && tm.tm_yday + 1 == 167 &&
            tm.tm_hour == 0 && tm.tm_min == 0 && tm.tm_sec == 0 &&
            tm.tm_isdst == -1);
}

static int
test_to_date(void)
{
    dbf_field_t *field = &header->fields[TO];
    struct tm tm;

    return (dbf_record_datetime(record, field, &tm) && tm.tm_mday == 19 &&
            tm.tm_mon + 1 == 6 && tm.tm_year + 1900 == 2022 &&
            tm.tm_wday == SUNDAY && tm.tm_yday + 1 == 170 &&
            tm.tm_hour == 23 && tm.tm_min == 59 && tm.tm_sec == 59 &&
            tm.tm_isdst == -1);
}

static int
test_is_dessel(void)
{
    dbf_field_t *field = &header->fields[LOCATION];
    const char *s;
    size_t n;

    dbf_record_string(record, field, &s, &n);
    return (n == 6 && memcmp(s, "Dessel", n) == 0);
}

static int
test_latitude(void)
{
    dbf_field_t *field = &header->fields[LATITUDE];
    double d;

    return (dbf_record_strtod(record, field, &d) && d == 51.2395);
}

static int
test_longitude(void)
{
    dbf_field_t *field = &header->fields[LONGITUDE];
    double d;

    return (dbf_record_double(record, field, &d) && d == 5.1132);
}

static int
test_bands(void)
{
    dbf_field_t *field = &header->fields[BANDS];
    int32_t i;

    return (dbf_record_int32(record, field, &i) && i == 129);
}

static int
test_admission_strtol(void)
{
    dbf_field_t *field = &header->fields[ADMISSION];
    long l;

    return (dbf_record_strtol(record, field, 10, &l) && l == 249);
}

static int
test_admission_strtoll(void)
{
    dbf_field_t *field = &header->fields[ADMISSION];
    long long ll;

    return (dbf_record_strtoll(record, field, 10, &ll) && ll == 249);
}

static int
test_admission_strtoul(void)
{
    dbf_field_t *field = &header->fields[ADMISSION];
    unsigned long ul;

    return (dbf_record_strtoul(record, field, 10, &ul) && ul == 249);
}

static int
test_admission_strtoull(void)
{
    dbf_field_t *field = &header->fields[ADMISSION];
    unsigned long long ull;

    return (dbf_record_strtoull(record, field, 10, &ull) && ull == 249);
}

static int
test_beer_price(void)
{
    dbf_field_t *field = &header->fields[BEER_PRICE];
    int64_t i;

    return (dbf_record_int64(record, field, &i) && i == 55000);
}

static int
test_food_price(void)
{
    dbf_field_t *field = &header->fields[FOOD_PRICE];
    long double ld;

    return (dbf_record_strtold(record, field, &ld) && ld == 8.25);
}

static int
test_is_sold_out(void)
{
    dbf_field_t *field = &header->fields[SOLD_OUT];

    return dbf_record_logical_is_true(record, field) &&
           !dbf_record_logical_is_false(record, field);
}

static int
test_is_deleted(void)
{
    return dbf_record_is_deleted(record);
}

static int
test_festival_is_null(void)
{
    dbf_field_t *field = &header->fields[FESTIVAL];

    return dbf_record_is_null(record, field);
}

static int
test_from_date_is_null(void)
{
    dbf_field_t *field = &header->fields[FROM];

    return dbf_record_is_null(record, field);
}

static int
test_to_date_is_zero(void)
{
    dbf_field_t *field = &header->fields[TO];
    const char *s;
    size_t n;

    dbf_record_bytes(record, field, &s, &n);
    return (n == 8 && memcmp(s, "\0\0\0\0\0\0\0\0", n) == 0);
}

static int
test_location_is_filled(void)
{
    dbf_field_t *field = &header->fields[LOCATION];
    const char *s;
    size_t n;

    dbf_record_string(record, field, &s, &n);
    return (n == 254);
}

static int
test_latitude_is_null(void)
{
    dbf_field_t *field = &header->fields[LATITUDE];

    return dbf_record_is_null(record, field);
}

static int
test_longitude_is_negative(void)
{
    dbf_field_t *field = &header->fields[LONGITUDE];
    double d;

    return (dbf_record_double(record, field, &d) && d == -179.999999);
}

static int
test_bands_is_negative(void)
{
    dbf_field_t *field = &header->fields[BANDS];
    int32_t i;

    return (dbf_record_int32(record, field, &i) && i == INT32_MIN);
}

static int
test_admission_is_null(void)
{
    dbf_field_t *field = &header->fields[ADMISSION];

    return dbf_record_is_null(record, field);
}

static int
test_beer_price_is_negative(void)
{
    dbf_field_t *field = &header->fields[BEER_PRICE];
    int64_t i;

    return (dbf_record_int64(record, field, &i) && i == INT32_MIN);
}

static int
test_food_price_is_negative(void)
{
    dbf_field_t *field = &header->fields[FOOD_PRICE];
    double d;

    return (dbf_record_strtod(record, field, &d) && d == -1.23);
}

static int
test_sold_out_is_null(void)
{
    dbf_field_t *field = &header->fields[SOLD_OUT];

    return dbf_record_is_null(record, field);
}

/*
 * Record tests
 */

static int
handle_dbf_header(dbf_file_t *fh, const dbf_header_t *h)
{
    header = h;
    ok(test_database_version, "database version matches");
    ok(test_num_records, "number of records is greater than zero");
    ok(test_header_size, "header_size matches");
    ok(test_record_size, "record size is greater than zero");
    ok(test_num_fields, "number of fields matches");
    ok(test_field_festival, "festival field is character field");
    ok(test_field_from, "from field is date field");
    ok(test_field_to, "to field is date and time field");
    ok(test_field_location, "field name matches");
    ok(test_field_latitude, "latitude is float field");
    ok(test_field_longitude, "longitude is double field");
    ok(test_field_bands, "bands is integer field");
    ok(test_field_admission, "admission is number field");
    ok(test_field_beer_price, "beer price field is currency field");
    ok(test_field_food_price, "food price is number field");
    ok(test_field_sold_out, "sold out is logical field");
    header = NULL;
    return 1;
}

static int
handle_dbf_record(dbf_file_t *fh, const dbf_header_t *h,
                  const dbf_record_t *r, size_t file_offset)
{
    header = h;
    record = r;
    switch (record_number) {
    case 0:
        ok(test_is_graspop, "festival is Graspop");
        ok(test_from_date, "from date matches");
        ok(test_to_date, "to date matches");
        ok(test_is_dessel, "location is Dessel");
        ok(test_latitude, "latitude matches");
        ok(test_longitude, "longitude matches");
        ok(test_bands, "number of bands matches");
        ok(test_admission_strtol, "admission with strtol() matches");
        ok(test_admission_strtoll, "admission with strtoll() matches");
        ok(test_admission_strtoul, "admission with strtoul() matches");
        ok(test_admission_strtoull, "admission with strtoull() matches");
        ok(test_beer_price, "beer price matches");
        ok(test_food_price, "food price matches");
        ok(test_is_sold_out, "Graspop is sold out");
        break;
    case 1:
        ok(test_is_deleted, "record is deleted");
        ok(test_festival_is_null, "festival is null");
        ok(test_from_date_is_null, "from date is null");
        ok(test_to_date_is_zero, "to date is zero");
        ok(test_location_is_filled, "location is filled");
        ok(test_latitude_is_null, "latitude is null");
        ok(test_longitude_is_negative, "longitude is negative");
        ok(test_bands_is_negative, "bands is negative");
        ok(test_admission_is_null, "admission is null");
        ok(test_beer_price_is_negative, "beer price is negative");
        ok(test_food_price_is_negative, "food price is negative");
        ok(test_sold_out_is_null, "sold out is null");
        break;
    }
    ++record_number;
    return 1;
}

int
main(int argc, char *argv[])
{
    const char *datadir = getenv("datadir");
    const char *filename = "types.dbf";
    FILE *fp;

    plan(42);

    if (datadir == NULL) {
        fprintf(stderr,
                "# The environment variable \"datadir\" is not set\n");
        return 1;
    }

    if (chdir(datadir) == -1) {
        fprintf(stderr, "# Cannot change directory to \"%s\": %s\n", datadir,
                strerror(errno));
        return 1;
    }

    fp = fopen(filename, "rb");
    if (fp == NULL) {
        fprintf(stderr, "# Cannot open file \"%s\": %s\n", filename,
                strerror(errno));
        return 1;
    }

    dbf_file(&fh, fp, NULL);
    if (dbf_read(&fh, handle_dbf_header, handle_dbf_record) == -1) {
        fprintf(stderr, "# Cannot read file \"%s\": %s\n", filename,
                fh.error);
    }

    fclose(fp);

    done_testing();
}
