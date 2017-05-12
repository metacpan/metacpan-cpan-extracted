#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <bcm2835.h>

#include "const-c.inc"

MODULE = Device::BCM2835		PACKAGE = Device::BCM2835	PREFIX=bcm2835_		

#prototypes are wrong for length(buf) in spi_transfern :-(
#PROTOTYPES: ENABLE
INCLUDE: const-xs.inc

#
# Library management
#

int
bcm2835_init()

void
bcm2835_set_debug(uint8_t debug)

#
# Low level register access
#

uint32_t 
bcm2835_peri_read(volatile uint32_t* paddr)

void 
bcm2835_peri_write(volatile uint32_t* paddr, uint32_t value)

void 
bcm2835_peri_set_bits(volatile uint32_t* paddr, uint32_t value, uint32_t mask)

#
# GPIO register access
#

void 
bcm2835_gpio_fsel(uint8_t pin, uint8_t mode);

void 
bcm2835_gpio_set(uint8_t pin);

void 
bcm2835_gpio_clr(uint8_t pin)

uint8_t 
bcm2835_gpio_lev(uint8_t pin)

uint8_t 
bcm2835_gpio_eds(uint8_t pin)

void 
bcm2835_gpio_set_eds(uint8_t pin)

void
bcm2835_gpio_ren(uint8_t pin)

void
bcm2835_gpio_fen(uint8_t pin)

void 
bcm2835_gpio_hen(uint8_t pin)

void 
bcm2835_gpio_len(uint8_t pin)

void 
bcm2835_gpio_aren(uint8_t pin)

void 
bcm2835_gpio_afen(uint8_t pin)

void 
bcm2835_gpio_pud(uint8_t pud)

void 
bcm2835_gpio_pudclk(uint8_t pin, uint8_t on)

uint32_t 
bcm2835_gpio_pad(uint8_t group)

void 
bcm2835_gpio_set_pad(uint8_t group, uint32_t control)

void 
delay(unsigned int millis)

void 
delayMicroseconds(unsigned int micros)

void
bcm2835_gpio_write(uint8_t pin, uint8_t on)

void
bcm2835_gpio_set_pud(uint8_t pin, uint8_t pud)

void 
bcm2835_spi_begin()

void 
bcm2835_spi_end()

void
bcm2835_spi_setBitOrder(uint8_t order)

void 
bcm2835_spi_setClockDivider(uint16_t divider)

void 
bcm2835_spi_setDataMode(uint8_t mode)

void 
bcm2835_spi_chipSelect(uint8_t cs)

void 
bcm2835_spi_setChipSelectPolarity(uint8_t cs, uint8_t active)

uint8_t 
bcm2835_spi_transfer(uint8_t value)

void 
bcm2835_spi_transfern(char *buf, short length(buf))
