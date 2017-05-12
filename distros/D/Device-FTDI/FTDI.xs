#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_newRV_noinc
#define NEED_sv_2pv_flags
#include "ppport.h"

/*#undef MARK*/
#include <ftdi.h>

struct device_strings {
    char manufacturer[256];
    char description[256];
    char serial[256];
    struct device_strings *next;
};

void _dftdi_free_device_strings(struct device_strings *ptr)
{
    struct device_strings *next;
    while (ptr != NULL) {
        next = ptr->next;
	free(ptr);
	ptr = next;
    }
}

struct device_strings *_dftdi_get_device_strings(int vendor, int product, char **error_str)
{
    int ret, i;
    struct ftdi_context *ftdi;
    struct ftdi_device_list *devlist = NULL, *curdev;
    struct device_strings *strings_head = NULL, *cur_strings, *last_strings;

    if ((ftdi = ftdi_new()) == NULL) {
        *error_str = "Couldn't initialize fdti context";
	return NULL;
    }

    if (ftdi_usb_find_all(ftdi, &devlist, vendor, product) < 0) {
    	*error_str = ftdi_get_error_string(ftdi);
    	goto ERROR_EXIT;
    }

    for (curdev = devlist; curdev != NULL; curdev = curdev->next) {
        cur_strings = calloc(1, sizeof(struct device_strings));
	if (cur_strings == NULL) {
	    *error_str = "Couldn't allocate memory";
	    goto ERROR_EXIT;
	}

	if (ftdi_usb_get_strings(ftdi, curdev->dev, cur_strings->manufacturer, 256,
		cur_strings->description, 256, cur_strings->serial, 256) < 0)
	{
	    *error_str = ftdi_get_error_string(ftdi);
	    goto ERROR_EXIT;
	}

	if(strings_head == NULL) {
	    strings_head = cur_strings;
	}
	else {
	    last_strings->next = cur_strings;
	}
	last_strings = cur_strings;
    }

    goto EXIT;

ERROR_EXIT:
    if (strings_head != NULL)
        _dftdi_free_device_strings(strings_head);
    strings_head == NULL;
EXIT:
    if (devlist != NULL)
        ftdi_list_free(&devlist);
    if (ftdi)
        ftdi_free(ftdi);
    return strings_head;
}

void _dftdi_hv_store(HV* hv, char* key, char* value)
{
    SV *val, **ret;
    size_t len;
    if ((len = strnlen(value, 256)) > 0) {
        val = newSVpvn(value, len);
	ret = hv_store(hv, key, strnlen(key, 16), val, 0);
	if (ret == NULL) {
	    SvREFCNT_dec(val);
	}
    }
}

MODULE = Device::FTDI PACKAGE = Device::FTDI PREFIX = dftdi
PROTOTYPES: DISABLE

INCLUDE: const_xs.inc

void
dftdi_find_all(vendor, product)
	int vendor;
	int product;
    INIT:
        struct device_strings *devs, *curdev;
	char *error_str = NULL;
	HV *dev_descr;
	SV *descr_ref;
    PPCODE:
        devs = _dftdi_get_device_strings(vendor, product, &error_str);
	if (devs == NULL && error_str != NULL) {
	    croak("Failed to get list of devices: %s", error_str);
	}
	curdev = devs;
	while (curdev != NULL) {
	    dev_descr = newHV();
	    printf("Serial: %s\n", curdev->serial);
	    _dftdi_hv_store(dev_descr, "manufacturer", curdev->manufacturer);
	    _dftdi_hv_store(dev_descr, "description", curdev->description);
	    _dftdi_hv_store(dev_descr, "serial", curdev->serial);
	    descr_ref = newRV_noinc((SV*)dev_descr);
	    XPUSHs(sv_2mortal(descr_ref));
	    curdev = curdev->next;
	}

struct ftdi_context *
dftdi_open_device(vendor, product, description, serial, index)
	int vendor;
	int product;
	SV* description;
	SV* serial;
	int index;
    INIT:
        struct ftdi_context* ftdi;
	char *_description = NULL, *_serial = NULL;
	char *error_str;
    CODE:
	if(SvOK(description)) {
	    _description = SvPV_nolen(description);
	}
	if(SvOK(serial)) {
	    _serial = SvPV_nolen(serial);
	}
        if ((ftdi = ftdi_new()) == NULL) {
            croak("Couldn't initialize fdti context");
        }
	if (ftdi_usb_open_desc_index(ftdi, vendor, product, _description, _serial, index) < 0) {
	    error_str = ftdi_get_error_string(ftdi);
	    ftdi_free(ftdi);
	    croak("Couldn't open specified device: %s", error_str);
	}
	RETVAL = ftdi;
    OUTPUT:
        RETVAL

int
dftdi_set_interface(ftdi, interface)
	struct ftdi_context *ftdi;
	int interface;
    CODE:
        RETVAL = ftdi_set_interface(ftdi, interface);
    OUTPUT:
        RETVAL

void
dftdi_close_device(ftdi)
	struct ftdi_context *ftdi;
    CODE:
        ftdi_free(ftdi);

SV*
dftdi_error_string(ftdi)
	struct ftdi_context *ftdi;
    CODE:
        RETVAL = newSVpv(ftdi_get_error_string(ftdi), 0);
    OUTPUT:
        RETVAL

int
dftdi_reset(ftdi)
	struct ftdi_context *ftdi;
    CODE:
        RETVAL = ftdi_usb_reset(ftdi);
    OUTPUT:
        RETVAL

int
dftdi_purge_rx_buffer(ftdi)
	struct ftdi_context *ftdi;
    CODE:
        RETVAL = ftdi_usb_purge_rx_buffer(ftdi);
    OUTPUT:
        RETVAL

int
dftdi_purge_tx_buffer(ftdi)
	struct ftdi_context *ftdi;
    CODE:
        RETVAL = ftdi_usb_purge_tx_buffer(ftdi);
    OUTPUT:
        RETVAL

int
dftdi_purge_buffers(ftdi)
	struct ftdi_context *ftdi;
    CODE:
        RETVAL = ftdi_usb_purge_buffers(ftdi);
    OUTPUT:
        RETVAL

int
dftdi_setflowctrl(ftdi, flowctrl)
	struct ftdi_context *ftdi;
	int flowctrl;
    CODE:
        RETVAL = ftdi_setflowctrl(ftdi, flowctrl);
    OUTPUT:
        RETVAL

int
dftdi_set_line_property2(ftdi, bits, stopbits, parity, break_type)
	struct ftdi_context *ftdi;
	int bits;
	int stopbits;
	int parity;
	int break_type;
    CODE:
        RETVAL = ftdi_set_line_property2(ftdi, bits, stopbits, parity, break_type);
    OUTPUT:
        RETVAL

int
dftdi_set_baudrate(ftdi, baudrate)
	struct ftdi_context *ftdi;
	int baudrate;
    CODE:
        RETVAL = ftdi_set_baudrate(ftdi, baudrate);
    OUTPUT:
        RETVAL

int
dftdi_set_latency_timer(ftdi, latency)
	struct ftdi_context *ftdi;
	int latency;
    CODE:
        RETVAL = ftdi_set_latency_timer(ftdi, latency);
    OUTPUT:
        RETVAL

int
dftdi_get_latency_timer(ftdi)
	struct ftdi_context *ftdi;
    INIT:
        unsigned char latency;
	int res;
    CODE:
        RETVAL = ftdi_get_latency_timer(ftdi, &latency);
	if (RETVAL == 0) {
	    RETVAL = latency;
	}
    OUTPUT:
        RETVAL

int
dftdi_write_data_set_chunksize(ftdi, chunksize)
	struct ftdi_context *ftdi;
	unsigned int chunksize;
    CODE:
    	RETVAL = ftdi_write_data_set_chunksize(ftdi, chunksize);
    OUTPUT:
        RETVAL

int
dftdi_write_data_get_chunksize(ftdi)
	struct ftdi_context *ftdi;
    INIT:
	unsigned int chunksize;
    CODE:
    	RETVAL = ftdi_write_data_get_chunksize(ftdi, &chunksize);
	if(RETVAL == 0) {
	    RETVAL = chunksize;
	}
    OUTPUT:
        RETVAL

int
dftdi_read_data_set_chunksize(ftdi, chunksize)
	struct ftdi_context *ftdi;
	unsigned int chunksize;
    CODE:
    	RETVAL = ftdi_read_data_set_chunksize(ftdi, chunksize);
    OUTPUT:
        RETVAL

int
dftdi_read_data_get_chunksize(ftdi)
	struct ftdi_context *ftdi;
    INIT:
	unsigned int chunksize;
    CODE:
    	RETVAL = ftdi_read_data_get_chunksize(ftdi, &chunksize);
	if(RETVAL == 0) {
	    RETVAL = chunksize;
	}
    OUTPUT:
        RETVAL

int
dftdi_write_data(ftdi, data)
	struct ftdi_context *ftdi;
	SV* data;
    INIT:
        unsigned char *buf;
	STRLEN len;
    CODE:
        buf = SvPV(data, len);
	RETVAL = ftdi_write_data(ftdi, buf, len);
    OUTPUT:
        RETVAL

int
dftdi_read_data(ftdi, buffer, size)
	struct ftdi_context *ftdi;
	SV* buffer;
	int size;
    INIT:
        unsigned char *tmp;
    CODE:
        tmp = calloc(1, size);
	RETVAL = ftdi_read_data(ftdi, tmp, size);
	if(RETVAL >= 0) {
	    sv_setpvn(buffer, tmp, RETVAL);
	}
	free(tmp);
    OUTPUT:
        RETVAL

int
dftdi_set_bitmode(ftdi, mask, mode)
	struct ftdi_context *ftdi;
	unsigned char mask;
	unsigned char mode;
    CODE:
        RETVAL = ftdi_set_bitmode(ftdi, mask, mode);
    OUTPUT:
        RETVAL
