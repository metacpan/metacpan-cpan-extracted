///////////////////////////////////////////////////////////////////////////////////////
// File          GPIO.xs
// Description:  XS module for HiPi::GPIO
// Copyright:    Copyright (c) 2017 Mark Dootson
// License:      This is free software; you can redistribute it and/or modify it under
//               the same terms as the Perl 5 programming language system itself.
//
//               Some of this work is based on pigpio - see
//               https://github.com/joan2937/pigpio
///////////////////////////////////////////////////////////////////////////////////////

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "mylib/include/ppport.h"

#include <sys/mman.h>
#include <stdio.h>

#define GPIO_BASE     0x200000
#define GPIO_LEN      0xB4
#define GPIO_LEN_PI4  0xF4

#define PI_INIT_FAILED -1

#define BANK (gpio>>5)
#define BIT  (1<<(gpio&0x1F))

/* gpio: 0-53 */

#define PI_MIN_GPIO       0
#define PI_MAX_GPIO      53
#define PI_PIN_ERROR     -1
#define PI_EDGE_ERROR     -1

/* user_gpio: 0-31 */

#define PI_MAX_USER_GPIO 31

/* level: 0-1 */

#define PI_OFF   0
#define PI_ON    1

#define PI_CLEAR 0
#define PI_SET   1

#define PI_LOW   0
#define PI_HIGH  1

/* mode: 0-7 */

#define PI_INPUT  0
#define PI_OUTPUT 1
#define PI_ALT0   4
#define PI_ALT1   5
#define PI_ALT2   6
#define PI_ALT3   7
#define PI_ALT4   3
#define PI_ALT5   2
#define PI_MAX_MODE 7

/* pud: 0-2 */

#define PI_PUD_OFF  0
#define PI_PUD_DOWN 1
#define PI_PUD_UP   2
#define PI_PUD_UNSET 0x08

/* locations */

#define GPFSEL0    0

#define GPSET0     7
#define GPSET1     8

#define GPCLR0    10
#define GPCLR1    11

#define GPLEV0    13
#define GPLEV1    14

#define GPEDS0    16
#define GPEDS1    17

#define GPREN0    19
#define GPREN1    20
#define GPFEN0    22
#define GPFEN1    23
#define GPHEN0    25
#define GPHEN1    26
#define GPLEN0    28
#define GPLEN1    29
#define GPAREN0   31
#define GPAREN1   32
#define GPAFEN0   34
#define GPAFEN1   35

#define GPPUD     37
#define GPPUDCLK0 38
#define GPPUDCLK1 39

#define GPPUPPDN0 57
#define GPPUPPDN1 58
#define GPPUPPDN2 59
#define GPPUPPDN3 60

#define RPI_1_BASE 0x20000000
#define RPI_2_BASE 0x3F000000
#define RPI_3_BASE 0x3F000000
#define RPI_4_BASE 0xFE000000


static int fdMem = -1;
static volatile uint32_t * gpio_register = MAP_FAILED;
static volatile uint32_t pi_is_2711    = 0;
static volatile uint32_t alt_gpio_len  = GPIO_LEN;
static volatile uint32_t base_address = 0;

// pre-declares required
static int  do_initialise(void);
static void do_uninitialise(void);
static void send_module_error( char * error );

// init peripherals
static int set_perhipherals(void)
{
    const char *ranges_file = "/proc/device-tree/soc/ranges";
    uint8_t ranges[12];
    FILE *fd;
    
    memset(ranges, 0, sizeof(ranges));

    if ((fd = fopen(ranges_file, "rb")) == NULL)
    {
        return PI_INIT_FAILED;
    }
    else if (fread(ranges, 1, sizeof(ranges), fd) >= 8)
    {
        base_address = (ranges[4] << 24) |
              (ranges[5] << 16) |
              (ranges[6] << 8) |
              (ranges[7] << 0);
        if (!base_address)
            base_address = (ranges[8] << 24) |
                  (ranges[9] << 16) |
                  (ranges[10] << 8) |
                  (ranges[11] << 0);
        if ((ranges[0] != 0x7e) ||
                (ranges[1] != 0x00) ||
                (ranges[2] != 0x00) ||
                (ranges[3] != 0x00) ||
                ((base_address != RPI_1_BASE) && (base_address != RPI_2_BASE) && (base_address != RPI_4_BASE)))
        {
             return PI_INIT_FAILED;
        }
    }
    else
    {
	    return PI_INIT_FAILED;
    }

    fclose(fd);
    
    if( base_address == RPI_4_BASE )
    {
        pi_is_2711 = 1;
        alt_gpio_len = GPIO_LEN_PI4;
    }

    return 0;
}


// map a memory block
static uint32_t *  map_gpiomem(int fd, uint32_t addr, uint32_t len)
{
    return (uint32_t *) mmap(0, len, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED|MAP_LOCKED, fd, addr);
}

// open /dev/gpiomem
static int open_gpiomen(void)
{
    if ((fdMem = open("/dev/gpiomem", O_RDWR | O_SYNC) ) < 0)
    {
        return PI_INIT_FAILED;
    }
    
    return 0;
}

// initialise lib
static int do_initialise(void)
{
    if(set_perhipherals() == PI_INIT_FAILED)
    {
        send_module_error("HiPi::GPIO failed to set peripherals");
        return 0;
    }
    
    if(open_gpiomen() == PI_INIT_FAILED)
    {
        send_module_error("HiPi::GPIO failed to open memory device /dev/gpiomem");
        do_uninitialise();
        return 0;
    }
    
    gpio_register = map_gpiomem(fdMem, GPIO_BASE, alt_gpio_len);

    if (gpio_register == MAP_FAILED)
    {
        send_module_error("HiPi::GPIO failed to map gpio memory block");
        do_uninitialise();
        return 0;
    }
    
    return 1;
}

// uninitialise lib
static void do_uninitialise(void)
{
    if (gpio_register != MAP_FAILED) munmap((void *)gpio_register, alt_gpio_len);
    gpio_register == MAP_FAILED;
    
    if (fdMem != -1)
    {
       close(fdMem);
       fdMem = -1;
    }
}

// delay microseconds
static void delay_microseconds(uint32_t inputmicros)
{
    struct timespec ts, rem;
    int seconds = inputmicros / 1000000;
    int micros  = inputmicros % 1000000;
    
    ts.tv_sec  = seconds;
    ts.tv_nsec = micros * 1000;
 
    while ( clock_nanosleep(CLOCK_REALTIME, 0, &ts, &rem) )
    {
       ts = rem;
    } 
}

// set pud mode

static void do_gpio_set_pud(unsigned gpio, unsigned pud)
{
    
    int shift = (gpio & 0xf) << 1;
    uint32_t bits;
    uint32_t pull;
    
    if( pi_is_2711 ) {
        
        switch (pud)
        {
           case PI_PUD_OFF:  pull = 0; break;
           case PI_PUD_UP:   pull = 1; break;
           case PI_PUD_DOWN: pull = 2; break;
        }
  
        bits = *(gpio_register + GPPUPPDN0 + (gpio>>4));
        bits &= ~(3 << shift);
        bits |= (pull << shift);
        *(gpio_register + GPPUPPDN0 + (gpio>>4)) = bits;
     
    } else {
        *(gpio_register + GPPUD) = pud;
       
        delay_microseconds(20);
     
        *(gpio_register + GPPUDCLK0 + BANK) = BIT;
     
        delay_microseconds(20);
     
        *(gpio_register + GPPUD) = 0;
     
        *(gpio_register + GPPUDCLK0 + BANK) = 0;
    }
   
}

// get pud mode

int do_gpio_get_pud(unsigned gpio)
{
    int retval = PI_PUD_UNSET;   
    if( pi_is_2711 )
    {
        int pull_bits = (*(gpio_register + GPPUPPDN0 + (gpio >> 4)) >> ((gpio & 0xf)<<1)) & 0x3;
        switch (pull_bits)
        {
            case 0: retval = PI_PUD_OFF; break;
            case 1: retval = PI_PUD_UP; break;
            case 2: retval = PI_PUD_DOWN; break;
            default: retval = PI_PUD_UNSET; break;
        } 
    }
    return retval;
}

// set pin mode

static void do_gpio_set_mode(unsigned gpio, unsigned mode)
{
   int reg, shift;
   
   reg   =  gpio/10;
   shift = (gpio%10) * 3;

   gpio_register[reg] = (gpio_register[reg] & ~(7<<shift)) | (mode<<shift);
}

// get pin mode
int do_gpio_get_mode(unsigned gpio)
{
   int reg, shift;
   
   reg   =  gpio/10;
   shift = (gpio%10) * 3;

   return (gpio_register[reg] >> shift) & 7;
}

// read pin value
static int do_gpio_read(unsigned gpio)
{
    if ((*(gpio_register + GPLEV0 + BANK) & BIT) != 0)
    {
        return PI_ON;
    } else {
        return PI_OFF;
    }
}

// write pin value
static void do_gpio_write(unsigned gpio, unsigned level)
{
    if (level == PI_ON) {
        *(gpio_register + GPSET0 + BANK) = BIT;
    } else {
        *(gpio_register + GPCLR0 + BANK) = BIT;
    }
}

// set bits

static void do_gpio_set_bits( uint32_t offset, uint32_t value, uint32_t mask )
{
    uint32_t val = *(gpio_register + offset);
    val = (val & ~mask) | (value & mask);
    *(gpio_register + offset) = val;
}

// edge detection register settings
static void do_gpio_set_egdereg_pin_bit(unsigned gpio, unsigned reg)
{
    
    uint32_t value   = BIT;
    uint32_t mask    = BIT;
    uint32_t offset  = reg + BANK;
    
    do_gpio_set_bits( offset, value, mask );
}

static int do_gpio_get_egdereg_pin_bit(unsigned gpio, unsigned reg)
{
    if ((*(gpio_register + reg + BANK) & BIT) != 0)
    {
        return PI_SET;
    } else {
        return PI_CLEAR;
    }
}

static void do_gpio_clear_edgereg_pin_bit(unsigned gpio, unsigned reg)
{
    
    uint32_t value   = 0;
    uint32_t mask    = BIT;
    uint32_t offset  = reg + BANK;
    do_gpio_set_bits( offset, value, mask );
}

static int do_gpio_get_eds(unsigned gpio)
{
    if ((*(gpio_register + GPEDS0 + BANK) & BIT) != 0)
    {
        return PI_SET;
    } else {
        return PI_CLEAR;
    }
}

static void do_gpio_set_eds(unsigned gpio)
{
    *(gpio_register + GPEDS0 + BANK) = BIT;
}
// send error to module

static void send_module_error( char * error )
{
    dSP;
	ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        EXTEND(SP, 1);
        PUSHs(sv_2mortal(newSVpv(error, 0)));
        PUTBACK;
        call_pv("HiPi::GPIO::error_report", G_DISCARD);
        FREETMPS;
        LEAVE;
}

MODULE = HiPi::GPIO  PACKAGE = HiPi::GPIO

int
xs_initialise_gpio_block()
  CODE:
    RETVAL = do_initialise();
  OUTPUT: RETVAL


void
xs_release_gpio_block()
  CODE:
    do_uninitialise();


int
xs_gpio_write( gpio, level )
    unsigned gpio
    unsigned level
  CODE:
    
    if (gpio > PI_MAX_GPIO) {
        send_module_error("bad gpio number specified");
        RETVAL = PI_PIN_ERROR;
    } else if (level > PI_ON) {
        send_module_error("bad level specified");
        RETVAL = PI_PIN_ERROR;
    } else {
        // if (do_gpio_getmode(gpio) != PI_OUTPUT) do_gpio_setmode(gpio, PI_OUTPUT);
        do_gpio_write( gpio, level );
        RETVAL = (int)level;
    }
    
  OUTPUT: RETVAL


int
xs_gpio_read( gpio )
    unsigned gpio
  CODE:
  
    if (gpio > PI_MAX_GPIO) {
        send_module_error("bad gpio number specified");
        RETVAL = PI_PIN_ERROR;
    } else {
        RETVAL = do_gpio_read(gpio);
    }
    
  OUTPUT: RETVAL


int
xs_gpio_set_mode( gpio, mode )
    unsigned gpio
    unsigned mode
  CODE:
  
    if (gpio > PI_MAX_GPIO) {
        send_module_error("bad gpio number specified");
        RETVAL = PI_PIN_ERROR;
    } else if( mode > PI_MAX_MODE ){
        send_module_error("bad mode specified");
        RETVAL = PI_PIN_ERROR;
    } else {
        do_gpio_set_mode( gpio, mode);
        RETVAL = (int)mode;
    }
    
  OUTPUT: RETVAL


int
xs_gpio_get_mode( gpio )
    unsigned gpio
  CODE:
  
    if (gpio > PI_MAX_GPIO) {
        send_module_error("bad gpio number specified");
        RETVAL = PI_PIN_ERROR;
    } else {
        RETVAL = do_gpio_get_mode( gpio );
    }
    
  OUTPUT: RETVAL


int
xs_gpio_set_pud( gpio, pud )
    unsigned gpio
    unsigned pud
  CODE:
  
    if (gpio > PI_MAX_GPIO) {
        send_module_error("bad gpio number specified");
        RETVAL = PI_PIN_ERROR;
    } else if( pud > PI_PUD_UP ){
        send_module_error("bad pud action specified");
        RETVAL = PI_PIN_ERROR;
    } else {
        // set the pud
        do_gpio_set_pud( gpio, pud);
        RETVAL = (int)pud;
    }
    
  OUTPUT: RETVAL


int
xs_gpio_get_pud( gpio )
    unsigned gpio
  CODE:
  
    if (gpio > PI_MAX_GPIO) {
        send_module_error("bad gpio number specified");
        RETVAL = PI_PIN_ERROR;
    } else {
        // get the pud
        
        RETVAL = do_gpio_get_pud( gpio );
    }
    
  OUTPUT: RETVAL


uint32_t xs_gpio_get_peripheral_base_address()
  CODE:
    RETVAL = base_address;
  
  OUTPUT: RETVAL


int xs_gpio_set_edge_detect( gpio, edge, onoff )
    unsigned gpio
    unsigned edge
    unsigned onoff
  CODE:
    if (gpio > PI_MAX_GPIO) {
        send_module_error("bad gpio number specified");
        RETVAL = PI_PIN_ERROR;
    } else if( edge != GPREN0 && edge != GPFEN0 && edge != GPHEN0 && edge != GPLEN0 && edge != GPAREN0 && edge != GPAFEN0 ) {
        RETVAL = PI_EDGE_ERROR;
        send_module_error("bad edge type specified");
    } else if( onoff > 1 ){
        send_module_error("bad edge setting specified");
        RETVAL = PI_PIN_ERROR;
    } else if( onoff == 1 ) {
        // set the edge
        do_gpio_set_egdereg_pin_bit( gpio, edge );
        RETVAL = (int)gpio;
    } else {
        do_gpio_clear_edgereg_pin_bit( gpio, edge );
        RETVAL = (int)gpio;
    }
  
  OUTPUT: RETVAL


int xs_gpio_get_edge_detect( gpio, edge )
    unsigned gpio
    unsigned edge
  CODE:
    if (gpio > PI_MAX_GPIO) {
        send_module_error("bad gpio number specified");
        RETVAL = PI_PIN_ERROR;
    } else if( edge != GPREN0 && edge != GPFEN0 && edge != GPHEN0 && edge != GPLEN0 && edge != GPAREN0 && edge != GPAFEN0 ) {
        RETVAL = PI_EDGE_ERROR;
        send_module_error("bad edge type specified");
    } else {
        RETVAL = do_gpio_get_egdereg_pin_bit( gpio, edge );
    }

  OUTPUT: RETVAL


int
xs_gpio_clear_edge_detect( gpio )
    unsigned gpio
  CODE:
    if (gpio > PI_MAX_GPIO) {
        send_module_error("bad gpio number specified");
        RETVAL = PI_PIN_ERROR;
    } else {
        do_gpio_set_eds( gpio );
        RETVAL = (int)gpio;
    }
    
  OUTPUT: RETVAL


int
xs_gpio_read_edge_detect( gpio )
    unsigned gpio
  CODE:
    if (gpio > PI_MAX_GPIO) {
        send_module_error("bad gpio number specified");
        RETVAL = PI_PIN_ERROR;
    } else {
        RETVAL = do_gpio_get_eds( gpio );
    }
    
  OUTPUT: RETVAL

