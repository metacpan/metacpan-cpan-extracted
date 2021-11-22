#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <gpiod.h>
#include <stdio.h>
#include <stdlib.h>

MODULE = Device::Chip::Adapter::Gpiod	PACKAGE = Device::Chip::Adapter::Gpiod

SV*
gpiod_open(device)
    char *device
  CODE:
    struct gpiod_chip *chip = gpiod_chip_open_lookup(device);
    RETVAL = newSViv((IV)chip);
  OUTPUT:
    RETVAL

void
gpiod_close(chip_ptr)
    SV *chip_ptr
  CODE:
    struct gpiod_chip *chip = (struct gpiod_chip*)SvIV(chip_ptr);
    gpiod_chip_close(chip);

int
gpiod_num_lines(chip_ptr)
    SV *chip_ptr
  CODE:
    struct gpiod_chip *chip = (struct gpiod_chip*)SvIV(chip_ptr);
    RETVAL = gpiod_chip_num_lines(chip);
  OUTPUT:
    RETVAL

void
gpiod_read_lines(chip_ptr, ...)
    SV *chip_ptr
  PPCODE:
    struct gpiod_chip *chip = (struct gpiod_chip*)SvIV(chip_ptr);
    int *values;
    unsigned int *offsets;
    int num_lines = items - 1;
    struct gpiod_line_bulk lines;
    struct gpiod_line_request_config config;

    Newx(values, num_lines, int);
    Newx(offsets, num_lines, unsigned int);

    for (int i=0; i<num_lines; i++)
    {
        offsets[i] = SvUV(ST(i + 1));
    }

    if (gpiod_chip_get_lines(chip, offsets, num_lines, &lines) == 0)
    {
        memset(&config, 0, sizeof(config));
        config.consumer = "Device::Chip";
        config.request_type = GPIOD_LINE_REQUEST_DIRECTION_INPUT;
        if (gpiod_line_request_bulk(&lines, &config, NULL) == 0)
        {
            if (gpiod_line_get_value_bulk(&lines, values) == 0)
            {
                EXTEND(SP, items);
                for (int i=0; i<num_lines; i++)
                {
                    PUSHs(sv_2mortal(newSViv(values[i])));
                }
            }
        }
    }

    Safefree(values);
    Safefree(offsets);

void
gpiod_write_lines(chip_ptr, ...)
    SV *chip_ptr
  PPCODE:
    struct gpiod_chip *chip = (struct gpiod_chip*)SvIV(chip_ptr);
    int *values;
    unsigned int *offsets;
    int num_lines = (items - 1) / 2;
    struct gpiod_line_bulk lines;
    struct gpiod_line_request_config config;

    Newx(values, num_lines, int);
    Newx(offsets, num_lines, unsigned int);

    for (int i=0; i<num_lines; i++)
    {
        offsets[i] = SvUV(ST(i*2 + 1));
        values[i] = SvUV(ST(i*2 + 2));
    }

    if (gpiod_chip_get_lines(chip, offsets, num_lines, &lines) == 0)
    {
        memset(&config, 0, sizeof(config));
        config.consumer = "Device::Chip";
        config.request_type = GPIOD_LINE_REQUEST_DIRECTION_OUTPUT;
        gpiod_line_request_bulk(&lines, &config, values);
        gpiod_line_set_value_bulk(&lines, values);
    }

    Safefree(values);
    Safefree(offsets);

