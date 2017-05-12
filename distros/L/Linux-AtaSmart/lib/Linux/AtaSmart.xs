#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "atasmart.h"

/*
const char* sk_smart_overall_to_string(SkSmartOverall overall);
int sk_disk_identify_is_available(SkDisk *d, SkBool *available);
int sk_disk_identify_parse(SkDisk *d, const SkIdentifyParsedData **data);
typedef void (*SkSmartAttributeParseCallback)(SkDisk *d, const SkSmartAttributeParsedData *a, void* userdata);
int sk_disk_get_blob(SkDisk *d, const void **blob, size_t *size);
int sk_disk_set_blob(SkDisk *d, const void *blob, size_t size);
int sk_disk_smart_parse_attributes(SkDisk *d, SkSmartAttributeParseCallback cb, void* userdata);
*/
MODULE = Linux::AtaSmart	PACKAGE = Linux::AtaSmart

PROTOTYPES: DISABLE

SkDisk *
__disk_open(const char *device)
    CODE:
        if ( sk_disk_open(device, &RETVAL) == -1 ) {
            croak("Failed to open disk '%s': %s\n", device, strerror(errno));
        }
    OUTPUT:
        RETVAL

NO_OUTPUT void
__get_smart_data(SkDisk *disk)
    CODE:
        const SkSmartParsedData *parsed_data;

        if (sk_disk_smart_read_data(disk) < 0) {
            croak("Failed to read SMART data: %s\n", strerror(errno));
        }

        if (sk_disk_smart_parse(disk, &parsed_data) < 0) {
            croak("Failed to parse SMART data: %s\n", strerror(errno));
        }

int
__smart_is_available(SkDisk *disk)
    CODE:
        SkBool available;
        if (sk_disk_smart_is_available(disk, &available) < 0) {
            if (errno == ENOTSUP)
                croak("This device lacks SMART capability\n");
            else
                croak("Failed to determine SMART availability: %s\n", strerror(errno));
        }
        RETVAL = 1;
    OUTPUT:
        RETVAL

uint64_t
__get_size (SkDisk *disk)
    CODE:
        if (sk_disk_get_size(disk, &RETVAL) < 0)
            croak("Failed to retrieve disk size: %s\n", strerror(errno));
    OUTPUT:
        RETVAL

SkBool
__check_sleep_mode(SkDisk *disk)
    CODE:
        if (sk_disk_check_sleep_mode(disk, &RETVAL) < 0)
            croak("Failed to retrieve disk size: %s\n", strerror(errno));
    OUTPUT:
        RETVAL

NO_OUTPUT void
__disk_dump(SkDisk *disk)
	CODE:
        sk_disk_dump(disk);

SkBool
__smart_status(SkDisk *disk)
    CODE:
        if (sk_disk_smart_status(disk, &RETVAL) < 0)
            croak("Failed to retrieve disk size: %s\n", strerror(errno));
    OUTPUT:
        RETVAL

uint64_t
__get_temperature(SkDisk *disk)
    CODE:
        if (sk_disk_smart_get_temperature(disk, &RETVAL) == -1 && errno != ENOENT) {
            croak("Failed to retrieve disk temperature: %s\n", strerror(errno));
        }
    OUTPUT:
        RETVAL

uint64_t
__get_bad(SkDisk *disk)
    CODE:
        if (sk_disk_smart_get_bad(disk, &RETVAL) < 0)
            croak("Failed to retrieve bad sector count: %s\n", strerror(errno));
    OUTPUT:
        RETVAL

SkSmartOverall
__get_overall(SkDisk *disk)
    CODE:
        if (sk_disk_smart_get_overall(disk, &RETVAL) < 0)
            croak("Failed to retrieve overall status: %s\n", strerror(errno));
    OUTPUT:
        RETVAL

uint64_t
__get_power_cycle(SkDisk *disk)
    CODE:
        if (sk_disk_smart_get_power_cycle(disk, &RETVAL) < 0 && errno != ENOENT)
           croak("Failed to retrieve power cycle count: %s\n", strerror(errno));
    OUTPUT:
        RETVAL

uint64_t
__get_power_on(SkDisk *disk)
    CODE:
        if (sk_disk_smart_get_power_on(disk, &RETVAL) < 0 && errno != ENOENT)
            croak("Failed to retrieve power on ms: %s\n", strerror(errno));
    OUTPUT:
        RETVAL

NO_OUTPUT void
__self_test(SkDisk *disk, SkSmartSelfTest test)
    CODE:
        if (sk_disk_smart_self_test(disk, test) < 0)
             croak("Failed to start self test: %s\n", strerror(errno));

NO_OUTPUT void
__disk_free(SkDisk *disk)
    CODE:
        sk_disk_free(disk);

