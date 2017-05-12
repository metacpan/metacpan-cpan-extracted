#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include <mcp23s17.h>
#include <pifacedigital.h>
#include "const-c.inc"

MODULE = Device::PiFace		PACKAGE = Device::PiFace		

PROTOTYPES: ENABLE

INCLUDE: const-xs.inc

# mcp23s17 functions
int
mcp23s17_open(int bus, int chip_select)

uint8_t
mcp23s17_read_reg(uint8_t reg, uint8_t hw_addr, int fd)

void
mcp23s17_write_reg(uint8_t data, uint8_t reg, uint8_t hw_addr, int fd)

uint8_t
mcp23s17_read_bit(uint8_t bit_num, uint8_t reg, uint8_t hw_addr, int fd)

void
mcp23s17_write_bit(uint8_t data, uint8_t bit_num, uint8_t reg, uint8_t hw_addr, int fd)

int
mcp23s17_enable_interrupts()

int
mcp23s17_disable_interrupts()

int
mcp23s17_wait_for_interrupt(int timeout)

# libpifacedigital functions

int
pifacedigital_open(uint8_t hw_addr)

int
pifacedigital_open_noinit(uint8_t hw_addr)

void
pifacedigital_close(uint8_t hw_addr)

uint8_t
pifacedigital_read_reg(uint8_t reg, uint8_t hw_addr)

void
pifacedigital_write_reg(uint8_t data, uint8_t reg, uint8_t hw_addr)

uint8_t
pifacedigital_read_bit(uint8_t bit_num, uint8_t reg, uint8_t hw_addr)

void
pifacedigital_write_bit(uint8_t data, uint8_t bit_num, uint8_t reg, uint8_t hw_addr)

uint8_t
pifacedigital_digital_read(uint8_t pin_num)

void
pifacedigital_digital_write(uint8_t pin_num, uint8_t value)

int
pifacedigital_enable_interrupts()

int
pifacedigital_disable_interrupts()

int
pifacedigital_wait_for_input(uint8_t &data, int timeout, uint8_t hw_addr)
    OUTPUT:
        data
