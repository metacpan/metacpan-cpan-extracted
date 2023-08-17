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

static int
test_header_shape_type(void)
{
    return shp_header->type == SHP_TYPE_NULL;
}

static int
test_record_shape_type(void)
{
    return shp_record->type == SHP_TYPE_NULL;
}

static int
test_record_size(void)
{
    return shp_record->record_size == 4;
}

static int
handle_shp_header(shp_file_t *fh, const shp_header_t *h)
{
    UNUSED(fh);
    shp_header = h;
    ok(test_header_shape_type, "shape type is null");
    return 1;
}

static int
handle_shp_record(shp_file_t *fh, const shp_header_t *h,
                  const shp_record_t *r, size_t offset)
{
    UNUSED(fh);
    UNUSED(offset);
    shp_header = h;
    shp_record = r;
    ok(test_record_shape_type, "shape type is null");
    ok(test_record_size, "record size is 4");
    return 1;
}

int
main(void)
{
    const char *shp_filename = "null.shp";
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

    if (shp_read(&shp_fh, handle_shp_header, handle_shp_record) == -1) {
        fprintf(stderr, "# Cannot read file \"%s\": %s\n", shp_filename,
                shp_fh.error);
    }

    fclose(shp_stream);

    done_testing();
}
