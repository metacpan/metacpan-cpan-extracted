#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <hidapi.h>

MODULE = Device::HID::XS		PACKAGE = Device::HID::XS		

int
hid_init()

int
hid_exit()

struct hid_device_info *
hid_enumerate(vendor_id, product_id)
    unsigned short vendor_id
    unsigned short product_id

void
hid_free_enumeration(devs)
    struct hid_device_info *devs

hid_device *
hid_open(vendor_id, product_id, serial_number)
    unsigned short vendor_id
    unsigned short product_id
    const wchar_t *serial_number

hid_device *
hid_open_path(path)
    const char *path

int
hid_write(device, data, length)
    hid_device *device
    const unsigned char *data
    size_t length

int
hid_read_timeout(dev, data, length, milliseconds)
    hid_device *dev
    SV *data
    size_t length
    int milliseconds
    INIT:
        unsigned char *tmp;
    CODE:
        tmp = calloc(1, length);
        RETVAL = hid_read_timeout(dev, tmp, length, milliseconds);
        if(RETVAL >= 0) {
            sv_setpvn(data, (void*)tmp, RETVAL);
        }
        free(tmp);

    OUTPUT:
        RETVAL

int
hid_read(device, data, length)
    hid_device *device
    unsigned char *data
    size_t length

int
hid_set_nonblocking(device, nonblock)
    hid_device *device
    int nonblock

int
hid_send_feature_report(device, data, length)
    hid_device *device
    const unsigned char *data
    size_t length

int
hid_get_feature_report(device, data, length)
    hid_device *device
    unsigned char *data
    size_t length

void
hid_close(device)
    hid_device *device

int
hid_get_manufacturer_string(device, string, maxlen)
    hid_device *device
    wchar_t *string
    size_t maxlen

int
hid_get_product_string(device, string, maxlen)
    hid_device *device
    wchar_t *string
    size_t maxlen

int
hid_get_serial_number_string(device, string, maxlen)
    hid_device *device
    wchar_t *string
    size_t maxlen

int
hid_get_indexed_string(device, string_index, string, maxlen)
    hid_device *device
    int string_index
    wchar_t *string
    size_t maxlen

const wchar_t*
hid_error(device)
    hid_device *device

