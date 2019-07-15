///////////////////////////////////////////////////////////////////////////////////////
// File          bcm2835/BCM2385.xs
// Description:  XS module for HiPi::Device::BCM2385
// Created       Fri Nov 23 12:13:43 2012
// SVN Id        $Id:$
// Copyright:    Copyright (c) 2012-2019 Mark Dootson
// Licence:      This work is free software; you can redistribute it and/or modify it 
//               under the terms of the GNU General Public License as published by the 
//               Free Software Foundation; either version 2 of the License, or any later 
//               version.
///////////////////////////////////////////////////////////////////////////////////////

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "mylib/include/ppport.h"
#define BCM2835_NO_DELAY_COMPATIBILITY
#include "BCM2835/src/src/bcm2835.h"
#include <sys/mman.h>

#define XSRPI_INT_FALL    0x01
#define XSRPI_INT_RISE    0x02
#define XSRPI_INT_AFALL   0x04
#define XSRPI_INT_ARISE   0x08
#define XSRPI_INT_HIGH    0x10
#define XSRPI_INT_LOW     0x20

/*----------------------------------------------------------------
 * C CODE SECTION
 *
 * why replace base bcm2835 sections?
 * because I wanted to be able to specify
 * different BSC peripherals for I2C
 *----------------------------------------------------------------*/

uint8_t hipi_i2c_write( volatile uint32_t* baseaddress, const char * buf, uint32_t len );
uint8_t hipi_i2c_read( volatile uint32_t* baseaddress, char* buf, uint32_t len );
uint8_t hipi_i2c_read_register_rs( volatile uint32_t* baseaddress, char* regaddr, char* readbuf, uint32_t len );


uint8_t hipi_i2c_write( volatile uint32_t* baseaddress, const char* buf, uint32_t len )
{
    volatile uint32_t* dlen    = baseaddress + BCM2835_BSC_DLEN/4;
    volatile uint32_t* fifo    = baseaddress + BCM2835_BSC_FIFO/4;
    volatile uint32_t* status  = baseaddress + BCM2835_BSC_S/4;
    volatile uint32_t* control = baseaddress + BCM2835_BSC_C/4;
    volatile uint32_t* divaddr = baseaddress + BCM2835_BSC_DIV/4;
    
    uint16_t divider = bcm2835_peri_read(divaddr);
    int i2c_byte_wait_us = ((float)divider / BCM2835_CORE_CLK_HZ) * 1000000 * 9;

    uint32_t remaining = len;
    uint32_t i = 0;
    uint8_t reason = BCM2835_I2C_REASON_OK;

    // Clear FIFO
    bcm2835_peri_set_bits(control, BCM2835_BSC_C_CLEAR_1 , BCM2835_BSC_C_CLEAR_1 );
    // Clear Status
	bcm2835_peri_write_nb(status, BCM2835_BSC_S_CLKT | BCM2835_BSC_S_ERR | BCM2835_BSC_S_DONE);
	// Set Data Length
    bcm2835_peri_write_nb(dlen, len);
    // pre populate FIFO with max buffer
    while( remaining && ( i < BCM2835_BSC_FIFO_SIZE ) )
    {
        bcm2835_peri_write_nb(fifo, buf[i]);
        i++;
        remaining--;
    }
    
    // Enable device and start transfer
    bcm2835_peri_write_nb(control, BCM2835_BSC_C_I2CEN | BCM2835_BSC_C_ST);
    
    // Transfer is over when BCM2835_BSC_S_DONE
    while(!(bcm2835_peri_read_nb(status) & BCM2835_BSC_S_DONE ))
    {
        while ( remaining && (bcm2835_peri_read_nb(status) & BCM2835_BSC_S_TXD ))
        {
            // Write to FIFO, no barrier
            bcm2835_peri_write_nb(fifo, buf[i]);
            i++;
            remaining--;
        }
    }
    
    // Received a NACK
    if (bcm2835_peri_read(status) & BCM2835_BSC_S_ERR)
    {
		reason = BCM2835_I2C_REASON_ERROR_NACK;
    }

    // Received Clock Stretch Timeout
    else if (bcm2835_peri_read(status) & BCM2835_BSC_S_CLKT)
    {
		reason = BCM2835_I2C_REASON_ERROR_CLKT;
    }

    // Not all data is sent
    else if (remaining)
    {
		reason = BCM2835_I2C_REASON_ERROR_DATA;
    }

    bcm2835_peri_set_bits(control, BCM2835_BSC_S_DONE , BCM2835_BSC_S_DONE);

    return reason;
}


uint8_t hipi_i2c_read( volatile uint32_t* baseaddress, char* buf, uint32_t len )
{
    volatile uint32_t* dlen    = baseaddress + BCM2835_BSC_DLEN/4;
    volatile uint32_t* fifo    = baseaddress + BCM2835_BSC_FIFO/4;
    volatile uint32_t* status  = baseaddress + BCM2835_BSC_S/4;
    volatile uint32_t* control = baseaddress + BCM2835_BSC_C/4;
    volatile uint32_t* divaddr = baseaddress + BCM2835_BSC_DIV/4;
    
    uint16_t divider = bcm2835_peri_read(divaddr);
    int i2c_byte_wait_us = ((float)divider / BCM2835_CORE_CLK_HZ) * 1000000 * 9;

    uint32_t remaining = len;
    uint32_t i = 0;
    uint8_t reason = BCM2835_I2C_REASON_OK;
    
    // Clear FIFO
    bcm2835_peri_set_bits(control, BCM2835_BSC_C_CLEAR_1 , BCM2835_BSC_C_CLEAR_1 );
    // Clear Status
	bcm2835_peri_write_nb(status, BCM2835_BSC_S_CLKT | BCM2835_BSC_S_ERR | BCM2835_BSC_S_DONE);
	// Set Data Length
    bcm2835_peri_write_nb(dlen, len);
    // Start read
    bcm2835_peri_write_nb(control, BCM2835_BSC_C_I2CEN | BCM2835_BSC_C_ST | BCM2835_BSC_C_READ);
    
    // wait for transfer to complete
    while (!(bcm2835_peri_read_nb(status) & BCM2835_BSC_S_DONE))
    {
        // we must empty the FIFO as it is populated and not use any delay
        while (bcm2835_peri_read_nb(status) & BCM2835_BSC_S_RXD)
        {
            // Read from FIFO, no barrier
            buf[i] = bcm2835_peri_read_nb(fifo);
            i++;
            remaining--;
        }
    }
    
    // transfer has finished - grab any remaining stuff in FIFO
    while (remaining && (bcm2835_peri_read_nb(status) & BCM2835_BSC_S_RXD))
    {
        // Read from FIFO, no barrier
        buf[i] = bcm2835_peri_read_nb(fifo);
        i++;
        remaining--;
    }
    
    // Received a NACK
    if (bcm2835_peri_read(status) & BCM2835_BSC_S_ERR)
    {
		reason = BCM2835_I2C_REASON_ERROR_NACK;
    }

    // Received Clock Stretch Timeout
    else if (bcm2835_peri_read(status) & BCM2835_BSC_S_CLKT)
    {
		reason = BCM2835_I2C_REASON_ERROR_CLKT;
    }

    // Not all data is received
    else if (remaining)
    {
		reason = BCM2835_I2C_REASON_ERROR_DATA;
    }

    bcm2835_peri_set_bits(control, BCM2835_BSC_S_DONE , BCM2835_BSC_S_DONE);

    return reason;
}


uint8_t hipi_i2c_read_register_rs( volatile uint32_t* baseaddress, char* regaddr, char* buf, uint32_t len )
{   
    volatile uint32_t* dlen    = baseaddress + BCM2835_BSC_DLEN/4;
    volatile uint32_t* fifo    = baseaddress + BCM2835_BSC_FIFO/4;
    volatile uint32_t* status  = baseaddress + BCM2835_BSC_S/4;
    volatile uint32_t* control = baseaddress + BCM2835_BSC_C/4;
    volatile uint32_t* divaddr = baseaddress + BCM2835_BSC_DIV/4;
    
    uint16_t divider = bcm2835_peri_read(divaddr);
    int i2c_byte_wait_us = ((float)divider / BCM2835_CORE_CLK_HZ) * 1000000 * 9;
    int i = 0;
    
    uint32_t remaining = len;
    uint8_t reason = BCM2835_I2C_REASON_OK;
    
    // Clear FIFO
    bcm2835_peri_set_bits(control, BCM2835_BSC_C_CLEAR_1 , BCM2835_BSC_C_CLEAR_1 );
    // Clear Status
	bcm2835_peri_write(status, BCM2835_BSC_S_CLKT | BCM2835_BSC_S_ERR | BCM2835_BSC_S_DONE);
	// Set Data Length
    bcm2835_peri_write(dlen, 1);
    // Enable device and start transfer
    bcm2835_peri_write(control, BCM2835_BSC_C_I2CEN);
    bcm2835_peri_write(fifo, regaddr[0]);
    bcm2835_peri_write(control, BCM2835_BSC_C_I2CEN | BCM2835_BSC_C_ST);
    
    // poll for transfer has started
    while ( !( bcm2835_peri_read(status) & BCM2835_BSC_S_TA ) )
    {
        // Linux may cause us to miss entire transfer stage
        if(bcm2835_peri_read(status) & BCM2835_BSC_S_DONE)
            break;
    }
    
    // Send a start-read
    bcm2835_peri_write(dlen, len);
    bcm2835_peri_write(control, BCM2835_BSC_C_I2CEN | BCM2835_BSC_C_ST  | BCM2835_BSC_C_READ );
    
    // Wait for write to complete and first byte back.
    bcm2835_delayMicroseconds(i2c_byte_wait_us * 3);
    
    // wait for transfer to complete
    while (!(bcm2835_peri_read(status) & BCM2835_BSC_S_DONE))
    {
        // we must empty the FIFO as it is populated and not use any delay
        while (remaining && bcm2835_peri_read(status) & BCM2835_BSC_S_RXD)
        {
            // Read from FIFO, no barrier
            buf[i] = bcm2835_peri_read(fifo);
            i++;
            remaining--;
        }
    }
    
    // transfer has finished - grab any remaining stuff in FIFO
    while (remaining && (bcm2835_peri_read(status) & BCM2835_BSC_S_RXD))
    {
        // Read from FIFO, no barrier
        buf[i] = bcm2835_peri_read(fifo);
        i++;
        remaining--;
    }
    
    // Received a NACK
    if (bcm2835_peri_read(status) & BCM2835_BSC_S_ERR)
    {
		reason = BCM2835_I2C_REASON_ERROR_NACK;
    }

    // Received Clock Stretch Timeout
    else if (bcm2835_peri_read(status) & BCM2835_BSC_S_CLKT)
    {
		reason = BCM2835_I2C_REASON_ERROR_CLKT;
    }

    // Not all data is sent
    else if (remaining)
    {
		reason = BCM2835_I2C_REASON_ERROR_DATA;
    }

    bcm2835_peri_set_bits(control, BCM2835_BSC_S_DONE , BCM2835_BSC_S_DONE);

    return reason;
}


/*----------------------------------------------
 * Perl Section
 *----------------------------------------------*/


MODULE = HiPi::BCM2835  PACKAGE = HiPi::BCM2835

#
# Address Pointers
#

uint32_t
bcm2835_uses_dmb()
  CODE:
    uint32_t myvar;
#ifdef BCM2835_HAVE_DMB
     myvar = 1;
#else
     myvar = 0;
#endif
    RETVAL = myvar;
  OUTPUT: RETVAL

uint32_t
bcm2835_peripherals_base()
  CODE:
    RETVAL = (uint32_t)bcm2835_peripherals_base;
  OUTPUT: RETVAL

uint32_t
bcm2835_peripherals()
  CODE:
    RETVAL = (uint32_t)bcm2835_peripherals;
  OUTPUT: RETVAL

uint32_t
bcm2835_gpio()
  CODE:
    RETVAL = (uint32_t)bcm2835_gpio;
  OUTPUT: RETVAL

uint32_t
bcm2835_pwm()
  CODE:
    RETVAL = (uint32_t)bcm2835_pwm;
  OUTPUT: RETVAL

uint32_t
bcm2835_clk()
  CODE:
    RETVAL = (uint32_t)bcm2835_clk;
  OUTPUT: RETVAL

uint32_t
bcm2835_pads()
  CODE:
    RETVAL = (uint32_t)bcm2835_pads;
  OUTPUT: RETVAL

uint32_t
bcm2835_spi0()
  CODE:
    RETVAL = (uint32_t)bcm2835_spi0;
  OUTPUT: RETVAL

uint32_t
bcm2835_bsc0()
  CODE:
    RETVAL = (uint32_t)bcm2835_bsc0;
  OUTPUT: RETVAL

uint32_t
bcm2835_bsc1()
  CODE:
    RETVAL = (uint32_t)bcm2835_bsc1;
  OUTPUT: RETVAL

uint32_t
bcm2835_st()
  CODE:
    RETVAL = (uint32_t)bcm2835_st;
  OUTPUT: RETVAL

#
# Custom Functions
#

uint8_t
hipi_gpio_fget( pin )
    uint8_t pin
  CODE:
    volatile uint32_t* paddr = bcm2835_gpio + BCM2835_GPFSEL0/4 + (pin/10);
    uint8_t  shift  = (pin % 10) * 3;
    uint32_t mask   = BCM2835_GPIO_FSEL_MASK << shift;
    uint32_t result = bcm2835_peri_read(paddr) & mask;
    RETVAL = result >> shift;
  OUTPUT: RETVAL


int
hipi_gpio_get_eds( pin )
    uint8_t pin
  CODE:
    volatile uint32_t* paddr;
    uint8_t shift;
    uint32_t output;
    uint32_t mask;
    RETVAL = 0;

    /* REN */
    paddr = bcm2835_gpio + BCM2835_GPREN0/4 + pin/32;
    shift = pin % 32;
    mask  = 1 << shift;
    output = bcm2835_peri_read(paddr) & mask;
    if( (output >> shift) == 1 ) {
        RETVAL += XSRPI_INT_RISE;
    }

    /* FEN */
    paddr = bcm2835_gpio + BCM2835_GPFEN0/4 + pin/32;
    shift = pin % 32;
    mask  = 1 << shift;
    output = bcm2835_peri_read(paddr) & mask;
    if( (output >> shift) == 1 ) {
        RETVAL += XSRPI_INT_FALL;
    }
    
    /* HEN */
    paddr = bcm2835_gpio + BCM2835_GPHEN0/4 + pin/32;
    shift = pin % 32;
    mask  = 1 << shift;
    output = bcm2835_peri_read(paddr) & mask;
    if( (output >> shift) == 1 ) {
        RETVAL += XSRPI_INT_HIGH;
    }
    
    /* LEN */
    paddr = bcm2835_gpio + BCM2835_GPLEN0/4 + pin/32;
    shift = pin % 32;
    mask  = 1 << shift;
    output = bcm2835_peri_read(paddr) & mask;
    if( (output >> shift) == 1 ) {
        RETVAL += XSRPI_INT_LOW;
    }
    
    /* AFEN */
    paddr = bcm2835_gpio + BCM2835_GPAFEN0/4 + pin/32;
    shift = pin % 32;
    mask  = 1 << shift;
    output = bcm2835_peri_read(paddr) & mask;
    if( (output >> shift) == 1 ) {
        RETVAL += XSRPI_INT_AFALL;
    }

    /* AREN */
    paddr = bcm2835_gpio + BCM2835_GPAREN0/4 + pin/32;
    shift = pin % 32;
    mask  = 1 << shift;
    output = bcm2835_peri_read(paddr) & mask;
    if( (output >> shift) == 1 ) {
        RETVAL += XSRPI_INT_ARISE;
    }
  
  OUTPUT: RETVAL


#// void
#// bcm2835_hipi_i2c_setSlaveAddress(volatile uint32_t* baseaddress, uint8_t addr )

#// void
#// bcm2835_hipi_i2c_setClockDivider( volatile uint32_t* baseaddress, uint16_t divider )

#// void
#// bcm2835_hipi_i2c_set_baudrate( volatile uint32_t* baseaddress, uint32_t baudrate)

void
_hipi_i2c_set_transfer_params( baseaddress, addr, divider )
    volatile uint32_t* baseaddress
    uint8_t addr
    uint16_t divider
  CODE:
    bcm2835_hipi_i2c_setSlaveAddress( baseaddress, addr );
    bcm2835_hipi_i2c_setClockDivider( baseaddress, divider );


uint8_t
_hipi_i2c_write( baseaddress, buf, len )
    volatile uint32_t* baseaddress
    const char* buf
    uint32_t len
  CODE:
    RETVAL = hipi_i2c_write( baseaddress, buf, len );
  OUTPUT: RETVAL


uint8_t
_hipi_i2c_read( baseaddress, buf, len )
    volatile uint32_t* baseaddress
    char* buf
    uint32_t len
  CODE:
    RETVAL = hipi_i2c_read( baseaddress, buf, len );
  OUTPUT: RETVAL

uint8_t
_hipi_i2c_read_register( baseaddress, regaddr, readbuf, len )
    volatile uint32_t* baseaddress
    char* regaddr
    char* readbuf
    uint32_t len
  CODE:
    uint8_t reason = hipi_i2c_write( baseaddress, regaddr, 1 );
    if( reason )
    {
        RETVAL = reason;
    }
    else
    {
        RETVAL = hipi_i2c_read( baseaddress, readbuf, len );
    }
  OUTPUT: RETVAL

uint8_t
_hipi_i2c_read_register_rs( baseaddress, regaddr, readbuf, len )
    volatile uint32_t* baseaddress
    char* regaddr
    char* readbuf
    uint32_t len
  CODE:
    RETVAL = hipi_i2c_read_register_rs( baseaddress, regaddr, readbuf, len );
  OUTPUT: RETVAL

#
# Init
#

int
_hipi_bcm2835_init()
  CODE:
    RETVAL = bcm2835_init();
  OUTPUT: RETVAL

int
_hipi_bcm2835_close()
  CODE:
    RETVAL = bcm2835_close();
  OUTPUT: RETVAL

void
bcm2835_set_debug(uint8_t debug)

#
# Low level register access
#

unsigned int
bcm2835_version() 

uint32_t 
bcm2835_peri_read(volatile uint32_t* paddr)

uint32_t 
bcm2835_peri_read_nb(volatile uint32_t* paddr)

void 
bcm2835_peri_write(volatile uint32_t* paddr, uint32_t value)

void 
bcm2835_peri_write_nb(volatile uint32_t* paddr, uint32_t value)

void 
bcm2835_peri_set_bits(volatile uint32_t* paddr, uint32_t value, uint32_t mask)

#
# GPIO register access
#

void 
bcm2835_gpio_fsel(uint8_t pin, uint8_t mode)

void 
bcm2835_gpio_set(uint8_t pin);

void 
bcm2835_gpio_clr(uint8_t pin)

void
bcm2835_gpio_set_multi(uint32_t mask)

void
bcm2835_gpio_clr_multi(uint32_t mask)

uint8_t 
bcm2835_gpio_lev(uint8_t pin)

uint8_t 
bcm2835_gpio_eds(uint8_t pin)

void 
bcm2835_gpio_set_eds(uint8_t pin)

uint32_t
bcm2835_gpio_eds_multi(uint32_t mask);

void
bcm2835_gpio_set_eds_multi(uint32_t mask);

void
bcm2835_gpio_ren(uint8_t pin)

void
bcm2835_gpio_clr_ren(uint8_t pin)

void
bcm2835_gpio_fen(uint8_t pin)

void
bcm2835_gpio_clr_fen(uint8_t pin)

void 
bcm2835_gpio_hen(uint8_t pin)

void 
bcm2835_gpio_clr_hen(uint8_t pin)

void 
bcm2835_gpio_len(uint8_t pin)

void 
bcm2835_gpio_clr_len(uint8_t pin)

void 
bcm2835_gpio_aren(uint8_t pin)

void 
bcm2835_gpio_clr_aren(uint8_t pin)

void 
bcm2835_gpio_afen(uint8_t pin)

void 
bcm2835_gpio_clr_afen(uint8_t pin)

void 
bcm2835_gpio_pud(uint8_t pud)

void 
bcm2835_gpio_pudclk(uint8_t pin, uint8_t on)

uint32_t 
bcm2835_gpio_pad(uint8_t group)

void 
bcm2835_gpio_set_pad(uint8_t group, uint32_t control)

void 
bcm2835_delay(unsigned int millis)

void
bcm2835_delayMicroseconds(uint64_t micros)

void
bcm2835_gpio_write(uint8_t pin, uint8_t on)

void
bcm2835_gpio_write_multi(uint32_t mask, uint8_t on)

void
bcm2835_gpio_write_mask(uint32_t value, uint32_t mask)

void
bcm2835_gpio_set_pud(uint8_t pin, uint8_t pud)

uint8_t 
bcm2835_gpio_get_pud(uint8_t pin)

int 
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
hipi_spi_transfern( tbuf )
    SV* tbuf
  PPCODE:
    SV* rbuf = newSVsv(tbuf);
    bcm2835_spi_transfern( SvPVX(rbuf), (uint32_t)SvCUR(rbuf) );
    
    EXTEND(SP, 1);
    PUSHs(sv_2mortal(rbuf));


void
bcm2835_spi_transfern(char* buf, short length(buf))

void
hipi_spi_transfernb( tbuf )
    SV* tbuf
  PPCODE:
    SV* rbuf = newSVsv(tbuf);
    bcm2835_spi_transfernb( SvPVX(tbuf), SvPVX(rbuf), (uint32_t)SvCUR(tbuf) );
    
    EXTEND(SP, 1);
    PUSHs(sv_2mortal(rbuf));
    

void
bcm2835_spi_transfernb(char* tbuf, char* rbuf, short length(tbuf))

void
hipi_spi_writenb( buf )
    SV* buf
  PPCODE:
    SV* rbuf = sv_2mortal(newSVsv(buf));
    bcm2835_spi_writenb( SvPVX(rbuf), (uint32_t)SvCUR(rbuf) );
    
    EXTEND(SP, 1);
    PUSHs(rbuf);

void
bcm2835_spi_writenb(char* buf, short length(buf))

int
bcm2835_i2c_begin()

int
bcm2835_hipi_i2c_begin(int boardrevision)

void
bcm2835_i2c_end()

int
bcm2835_hipi_i2c_end(int boardrevision)

void
bcm2835_i2c_setSlaveAddress(uint8_t addr)

void
bcm2835_i2c_setClockDivider(uint16_t divider)

uint8_t
bcm2835_i2c_write(const char * buf,  short length(buf));

uint8_t
bcm2835_i2c_read( char* buf, uint32_t len )

uint64_t
bcm2835_st_read()

void
bcm2835_st_delay(uint64_t offset_micros, uint64_t micros)

void
bcm2835_i2c_set_baudrate(uint32_t baudrate)

uint8_t
bcm2835_i2c_read_register_rs(char* regaddr, char* buf, uint32_t len)

uint8_t
bcm2835_i2c_write_read_rs(char* cmds, uint32_t cmds_len, char* buf, uint32_t buf_len)

void
bcm2835_pwm_set_clock(uint32_t divisor)

void
bcm2835_pwm_set_mode(uint8_t channel, uint8_t markspace, uint8_t enabled)

void
bcm2835_pwm_set_range(uint8_t channel, uint32_t range)

void
bcm2835_pwm_set_data(uint8_t channel, uint32_t data)

