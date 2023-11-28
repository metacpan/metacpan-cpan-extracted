///////////////////////////////////////////////////////////////////////////////////////
// File          RP1.xs
// Description:  XS module for HiPi::GPIO -on Pi5 with RP1
// Copyright:    Copyright (c) 2023 Mark Dootson
// License:      This is free software; you can redistribute it and/or modify it under
//               the same terms as the Perl 5 programming language system itself.
//
//               RP1 use details from pinctrl util
//               https://github.com/raspberrypi/utils/blob/master/pinctrl/gpiochip_rp1.c
///////////////////////////////////////////////////////////////////////////////////////

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "mylib/include/ppport.h"

#include <sys/mman.h>
#include <stdio.h>
#include <string.h>

#define PI_INIT_FAILED -1

/* gpio: 0-53 */

#define PI_MIN_GPIO       0
#define PI_MAX_GPIO      53
#define PI_PIN_ERROR     -1
#define PI_EDGE_ERROR    -1

/* level: 0-1 */

#define PI_OFF   0
#define PI_ON    1

#define PI_CLEAR 0
#define PI_SET   1

#define PI_LOW   0
#define PI_HIGH  1

/* mode: 0-9 */

#define PI_MAX_MODE 9

/* pud: 0-2 */

#define PI_PUD_OFF  0
#define PI_PUD_DOWN 1
#define PI_PUD_UP   2
#define PI_PUD_UNSET 0x08

/* FSEL MAPING */

#define HIPI_MODE_INPUT  0x00
#define HIPI_MODE_OUTPUT 0x01
#define HIPI_MODE_ALT0   0x04
#define HIPI_MODE_ALT1   0x05
#define HIPI_MODE_ALT2   0x06
#define HIPI_MODE_ALT3   0x07
#define HIPI_MODE_ALT4   0x03
#define HIPI_MODE_ALT5   0x02
#define HIPI_MODE_ALT6   0x08
#define HIPI_MODE_ALT7   0x09
#define HIPI_MODE_ALT8   0x0a
#define HIPI_MODE_NONE   0x0b

/* locations and offsets */

#define GPIO_BASE     0x200000
#define GPIO_LEN      0x030000

/* Just hard code this so we can output */
/* It has no use. */
#define PERI_BASE_ADDRESS 0x1f000d0000

static int fdMem = -1;
static volatile uint32_t * gpio_register = MAP_FAILED;

// pre-declares required
static int  do_initialise(void);
static void do_uninitialise(void);
static void send_module_error( char * error );

#define RP1_NUM_GPIOS 54

#define RP1_IO_BANK0_OFFSET      0x00000000
#define RP1_IO_BANK1_OFFSET      0x00004000
#define RP1_IO_BANK2_OFFSET      0x00008000
#define RP1_SYS_RIO_BANK0_OFFSET 0x00010000
#define RP1_SYS_RIO_BANK1_OFFSET 0x00014000
#define RP1_SYS_RIO_BANK2_OFFSET 0x00018000
#define RP1_PADS_BANK0_OFFSET    0x00020000
#define RP1_PADS_BANK1_OFFSET    0x00024000
#define RP1_PADS_BANK2_OFFSET    0x00028000

#define RP1_RW_OFFSET  0x0000
#define RP1_XOR_OFFSET 0x1000
#define RP1_SET_OFFSET 0x2000
#define RP1_CLR_OFFSET 0x3000

#define RP1_GPIO_CTRL_FSEL_LSB     0
#define RP1_GPIO_CTRL_FSEL_MASK    (0x1f << RP1_GPIO_CTRL_FSEL_LSB)     // 5 bits
#define RP1_GPIO_CTRL_F_M_LSB      5
#define RP1_GPIO_CTRL_F_M_MASK     (0x7f << RP1_GPIO_CTRL_F_M_LSB)      // 7 bits
#define RP1_GPIO_CTRL_OUTOVER_LSB  12
#define RP1_GPIO_CTRL_OUTOVER_MASK (0x03 << RP1_GPIO_CTRL_OUTOVER_LSB)  // 2 bits
#define RP1_GPIO_CTRL_OEOVER_LSB   14
#define RP1_GPIO_CTRL_OEOVER_MASK  (0x03 << RP1_GPIO_CTRL_OEOVER_LSB)   // 2 bits
#define RP1_GPIO_CTRL_INOVER_LSB   16
#define RP1_GPIO_CTRL_INOVER_MASK  (0x03 << RP1_GPIO_CTRL_INOVER_LSB)   // 2 bits

#define RP1_PADS_OD_SET       (1 << 7)
#define RP1_PADS_IE_SET       (1 << 6)
#define RP1_PADS_PUE_SET      (1 << 3)
#define RP1_PADS_PDE_SET      (1 << 2)
#define RP1_PADS_SCHMITT_SET  (1 << 1)
#define RP1_PADS_SLEW_SET     (1 << 0)

#define RP1_GPIO_IO_REG_STATUS_OFFSET(offset) (((offset * 2) + 0) * sizeof(uint32_t))
#define RP1_GPIO_IO_REG_CTRL_OFFSET(offset)   (((offset * 2) + 1) * sizeof(uint32_t))
#define RP1_GPIO_PADS_REG_OFFSET(offset)      (sizeof(uint32_t) + (offset * sizeof(uint32_t)))

#define RP1_GPIO_SYS_RIO_REG_OUT_OFFSET        0x0
#define RP1_GPIO_SYS_RIO_REG_OE_OFFSET         0x4
#define RP1_GPIO_SYS_RIO_REG_SYNC_IN_OFFSET    0x8

#define rp1_gpio_write32(base, peri_offset, reg_offset, value) \
    base[(peri_offset + reg_offset)/4] = value

#define rp1_gpio_read32(base, peri_offset, reg_offset) \
    base[(peri_offset + reg_offset)/4]

typedef struct
{
   uint32_t io[3];
   uint32_t pads[3];
   uint32_t sys_rio[3];
} GPIO_STATE_T;

typedef enum
{
    RP1_FSEL_ALT0       = 0x0,
    RP1_FSEL_ALT1       = 0x1,
    RP1_FSEL_ALT2       = 0x2,
    RP1_FSEL_ALT3       = 0x3,
    RP1_FSEL_ALT4       = 0x4,
    RP1_FSEL_ALT5       = 0x5,
    RP1_FSEL_ALT6       = 0x6,
    RP1_FSEL_ALT7       = 0x7,
    RP1_FSEL_ALT8       = 0x8,
    RP1_FSEL_COUNT,
    RP1_FSEL_SYS_RIO    = RP1_FSEL_ALT5,
    RP1_FSEL_NULL       = 0x1f
} RP1_FSEL_T;

typedef enum
{
    GPIO_FSEL_FUNC0,
    GPIO_FSEL_FUNC1,
    GPIO_FSEL_FUNC2,
    GPIO_FSEL_FUNC3,
    GPIO_FSEL_FUNC4,
    GPIO_FSEL_FUNC5,
    GPIO_FSEL_FUNC6,
    GPIO_FSEL_FUNC7,
    GPIO_FSEL_FUNC8,
    /* ... */
    GPIO_FSEL_INPUT = 0x10,
    GPIO_FSEL_OUTPUT,
    GPIO_FSEL_GPIO, /* Preserves direction if possible, else input */
    GPIO_FSEL_NONE, /* If possible, else input */
    GPIO_FSEL_MAX
} GPIO_FSEL_T;

typedef enum
{
    PULL_NONE,
    PULL_DOWN,
    PULL_UP,
    PULL_MAX
} GPIO_PULL_T;

typedef enum
{
    DIR_INPUT,
    DIR_OUTPUT,
    DIR_MAX,
} GPIO_DIR_T;

typedef enum
{
    DRIVE_LOW,
    DRIVE_HIGH,
    DRIVE_MAX
} GPIO_DRIVE_T;

typedef enum
{
    SCHMITT_OFF,
    SCHMITT_ON,
    SCHMITT_MAX,
} GPIO_SCHMITT_T;

typedef enum
{
    SLEW_SLOW,
    SLEW_FAST,
    SLEW_MAX,
} GPIO_SLEW_T;

static const GPIO_STATE_T gpio_state = {
    .io = {RP1_IO_BANK0_OFFSET, RP1_IO_BANK1_OFFSET, RP1_IO_BANK2_OFFSET},
    .pads = {RP1_PADS_BANK0_OFFSET, RP1_PADS_BANK1_OFFSET, RP1_PADS_BANK2_OFFSET},
    .sys_rio = {RP1_SYS_RIO_BANK0_OFFSET, RP1_SYS_RIO_BANK1_OFFSET, RP1_SYS_RIO_BANK2_OFFSET},
};

static const int rp1_bank_base[] = {0, 28, 34};

static const char *rp1_gpio_fsel_names[RP1_NUM_GPIOS][RP1_FSEL_COUNT] =
{
    { "SPI0_SIO3" , "DPI_PCLK"     , "TXD1"         , "SDA0"         , 0              , "SYS_RIO00" , "PROC_RIO00" , "PIO0"       , "SPI2_CE0" , }, // 0
    { "SPI0_SIO2" , "DPI_DE"       , "RXD1"         , "SCL0"         , 0              , "SYS_RIO01" , "PROC_RIO01" , "PIO1"       , "SPI2_SIO1", }, // 1
    { "SPI0_CE3"  , "DPI_VSYNC"    , "CTS1"         , "SDA1"         , "IR_RX0"       , "SYS_RIO02" , "PROC_RIO02" , "PIO2"       , "SPI2_SIO0", }, // 2
    { "SPI0_CE2"  , "DPI_HSYNC"    , "RTS1"         , "SCL1"         , "IR_TX0"       , "SYS_RIO03" , "PROC_RIO03" , "PIO3"       , "SPI2_SCLK", }, // 3
    { "GPCLK0"    , "DPI_D0"       , "TXD2"         , "SDA2"         , "RI0"          , "SYS_RIO04" , "PROC_RIO04" , "PIO4"       , "SPI3_CE0" , }, // 4
    { "GPCLK1"    , "DPI_D1"       , "RXD2"         , "SCL2"         , "DTR0"         , "SYS_RIO05" , "PROC_RIO05" , "PIO5"       , "SPI3_SIO1", }, // 5
    { "GPCLK2"    , "DPI_D2"       , "CTS2"         , "SDA3"         , "DCD0"         , "SYS_RIO06" , "PROC_RIO06" , "PIO6"       , "SPI3_SIO0", }, // 6
    { "SPI0_CE1"  , "DPI_D3"       , "RTS2"         , "SCL3"         , "DSR0"         , "SYS_RIO07" , "PROC_RIO07" , "PIO7"       , "SPI3_SCLK", }, // 7
    { "SPI0_CE0"  , "DPI_D4"       , "TXD3"         , "SDA0"         , 0              , "SYS_RIO08" , "PROC_RIO08" , "PIO8"       , "SPI4_CE0" , }, // 8
    { "SPI0_MISO" , "DPI_D5"       , "RXD3"         , "SCL0"         , 0              , "SYS_RIO09" , "PROC_RIO09" , "PIO9"       , "SPI4_SIO0", }, // 9
    { "SPI0_MOSI" , "DPI_D6"       , "CTS3"         , "SDA1"         , 0              , "SYS_RIO010", "PROC_RIO010", "PIO10"      , "SPI4_SIO1", }, // 10    
    { "SPI0_SCLK" , "DPI_D7"       , "RTS3"         , "SCL1"         , 0              , "SYS_RIO011", "PROC_RIO011", "PIO11"      , "SPI4_SCLK", }, // 11
    { "PWM0_CHAN0", "DPI_D8"       , "TXD4"         , "SDA2"         , "AAUD_LEFT"    , "SYS_RIO012", "PROC_RIO012", "PIO12"      , "SPI5_CE0" , }, // 12
    { "PWM0_CHAN1", "DPI_D9"       , "RXD4"         , "SCL2"         , "AAUD_RIGHT"   , "SYS_RIO013", "PROC_RIO013", "PIO13"      , "SPI5_SIO1", }, // 13
    { "PWM0_CHAN2", "DPI_D10"      , "CTS4"         , "SDA3"         , "TXD0"         , "SYS_RIO014", "PROC_RIO014", "PIO14"      , "SPI5_SIO0", }, // 14
    { "PWM0_CHAN3", "DPI_D11"      , "RTS4"         , "SCL3"         , "RXD0"         , "SYS_RIO015", "PROC_RIO015", "PIO15"      , "SPI5_SCLK", }, // 15
    { "SPI1_CE2"  , "DPI_D12"      , "DSI0_TE_EXT"  , 0              , "CTS0"         , "SYS_RIO016", "PROC_RIO016", "PIO16"      , },              // 16
    { "SPI1_CE1"  , "DPI_D13"      , "DSI1_TE_EXT"  , 0              , "RTS0"         , "SYS_RIO017", "PROC_RIO017", "PIO17"      , },              // 17
    { "SPI1_CE0"  , "DPI_D14"      , "I2S0_SCLK"    , "PWM0_CHAN2"   , "I2S1_SCLK"    , "SYS_RIO018", "PROC_RIO018", "PIO18"      , "GPCLK1",   },  // 18
    { "SPI1_MISO" , "DPI_D15"      , "I2S0_WS"      , "PWM0_CHAN3"   , "I2S1_WS"      , "SYS_RIO019", "PROC_RIO019", "PIO19"      , },              // 19
    { "SPI1_MOSI" , "DPI_D16"      , "I2S0_SDI0"    , "GPCLK0"       , "I2S1_SDI0"    , "SYS_RIO020", "PROC_RIO020", "PIO20"      , },              // 20
    { "SPI1_SCLK" , "DPI_D17"      , "I2S0_SDO0"    , "GPCLK1"       , "I2S1_SDO0"    , "SYS_RIO021", "PROC_RIO021", "PIO21"      , },              // 21
    { "SD0CLK"    , "DPI_D18"      , "I2S0_SDI1"    , "SDA3"         , "I2S1_SDI1"    , "SYS_RIO022", "PROC_RIO022", "PIO22"      , },              // 22
    { "SD0_CMD"   , "DPI_D19"      , "I2S0_SDO1"    , "SCL3"         , "I2S1_SDO1"    , "SYS_RIO023", "PROC_RIO023", "PIO23"      , },              // 23
    { "SD0_DAT0"  , "DPI_D20"      , "I2S0_SDI2"    , 0              , "I2S1_SDI2"    , "SYS_RIO024", "PROC_RIO024", "PIO24"      , "SPI2_CE1" , }, // 24
    { "SD0_DAT1"  , "DPI_D21"      , "I2S0_SDO2"    , "MIC_CLK"      , "I2S1_SDO2"    , "SYS_RIO025", "PROC_RIO025", "PIO25"      , "SPI3_CE1" , }, // 25
    { "SD0_DAT2"  , "DPI_D22"      , "I2S0_SDI3"    , "MIC_DAT0"     , "I2S1_SDI3"    , "SYS_RIO026", "PROC_RIO026", "PIO26"      , "SPI5_CE1" , }, // 26
    { "SD0_DAT3"  , "DPI_D23"      , "I2S0_SDO3"    , "MIC_DAT1"     , "I2S1_SDO3"    , "SYS_RIO027", "PROC_RIO027", "PIO27"      , "SPI1_CE1" , }, // 27
    { "SD1CLK"    , "SDA4"         , "I2S2_SCLK"    , "SPI6_MISO"    , "VBUS_EN0"     , "SYS_RIO10" , "PROC_RIO10" , },                             // 28
    { "SD1_CMD"   , "SCL4"         , "I2S2_WS"      , "SPI6_MOSI"    , "VBUS_OC0"     , "SYS_RIO11" , "PROC_RIO11" , },                             // 29
    { "SD1_DAT0"  , "SDA5"         , "I2S2_SDI0"    , "SPI6_SCLK"    , "TXD5"         , "SYS_RIO12" , "PROC_RIO12" , },                             // 30
    { "SD1_DAT1"  , "SCL5"         , "I2S2_SDO0"    , "SPI6_CE0"     , "RXD5"         , "SYS_RIO13" , "PROC_RIO13" , },                             // 31
    { "SD1_DAT2"  , "GPCLK3"       , "I2S2_SDI1"    , "SPI6_CE1"     , "CTS5"         , "SYS_RIO14" , "PROC_RIO14" , },                             // 32
    { "SD1_DAT3"  , "GPCLK4"       , "I2S2_SDO1"    , "SPI6_CE2"     , "RTS5"         , "SYS_RIO15" , "PROC_RIO15" , },                             // 33
    { "PWM1_CHAN2", "GPCLK3"       , "VBUS_EN0"     , "SDA4"         , "MIC_CLK"      , "SYS_RIO20" , "PROC_RIO20" , },                             // 34
    { "SPI8_CE1"  , "PWM1_CHAN0"   , "VBUS_OC0"     , "SCL4"         , "MIC_DAT0"     , "SYS_RIO21" , "PROC_RIO21" , },                             // 35
    { "SPI8_CE0"  , "TXD5"         , "PCIE_CLKREQ_N", "SDA5"         , "MIC_DAT1"     , "SYS_RIO22" , "PROC_RIO22" , },                             // 36
    { "SPI8_MISO" , "RXD5"         , "MIC_CLK"      , "SCL5"         , "PCIE_CLKREQ_N", "SYS_RIO23" , "PROC_RIO23" , },                             // 37
    { "SPI8_MOSI" , "RTS5"         , "MIC_DAT0"     , "SDA6"         , "AAUD_LEFT"    , "SYS_RIO24" , "PROC_RIO24" , "DSI0_TE_EXT", },              // 38
    { "SPI8_SCLK" , "CTS5"         , "MIC_DAT1"     , "SCL6"         , "AAUD_RIGHT"   , "SYS_RIO25" , "PROC_RIO25" , "DSI1_TE_EXT", },              // 39
    { "PWM1_CHAN1", "TXD5"         , "SDA4"         , "SPI6_MISO"    , "AAUD_LEFT"    , "SYS_RIO26" , "PROC_RIO26" , },                             // 40
    { "PWM1_CHAN2", "RXD5"         , "SCL4"         , "SPI6_MOSI"    , "AAUD_RIGHT"   , "SYS_RIO27" , "PROC_RIO27" , },                             // 41
    { "GPCLK5"    , "RTS5"         , "VBUS_EN1"     , "SPI6_SCLK"    , "I2S2_SCLK"    , "SYS_RIO28" , "PROC_RIO28" , },                             // 42
    { "GPCLK4"    , "CTS5"         , "VBUS_OC1"     , "SPI6_CE0"     , "I2S2_WS"      , "SYS_RIO29" , "PROC_RIO29" , },                             // 43
    { "GPCLK5"    , "SDA5"         , "PWM1_CHAN0"   , "SPI6_CE1"     , "I2S2_SDI0"    , "SYS_RIO210", "PROC_RIO210", },                             // 44
    { "PWM1_CHAN3", "SCL5"         , "SPI7_CE0"     , "SPI6_CE2"     , "I2S2_SDO0"    , "SYS_RIO211", "PROC_RIO211", },                             // 45
    { "GPCLK3"    , "SDA4"         , "SPI7_MOSI"    , "MIC_CLK"      , "I2S2_SDI1"    , "SYS_RIO212", "PROC_RIO212", "DSI0_TE_EXT", },              // 46
    { "GPCLK5"    , "SCL4"         , "SPI7_MISO"    , "MIC_DAT0"     , "I2S2_SDO1"    , "SYS_RIO213", "PROC_RIO213", "DSI1_TE_EXT", },              // 47
    { "PWM1_CHAN0", "PCIE_CLKREQ_N", "SPI7_SCLK"    , "MIC_DAT1"     , "TXD5"         , "SYS_RIO214", "PROC_RIO214", },                             // 48
    { "SPI8_SCLK" , "SPI7_SCLK"    , "SDA5"         , "AAUD_LEFT"    , "RXD5"         , "SYS_RIO215", "PROC_RIO215", },                             // 49
    { "SPI8_MISO" , "SPI7_MOSI"    , "SCL5"         , "AAUD_RIGHT"   , "VBUS_EN2"     , "SYS_RIO216", "PROC_RIO216", },                             // 50
    { "SPI8_MOSI" , "SPI7_MISO"    , "SDA6"         , "AAUD_LEFT"    , "VBUS_OC2"     , "SYS_RIO217", "PROC_RIO217", },                             // 51
    { "SPI8_CE0"  , 0              , "SCL6"         , "AAUD_RIGHT"   , "VBUS_EN3"     , "SYS_RIO218", "PROC_RIO218", },                             // 52
    { "SPI8_CE1"  , "SPI7_CE0"     , 0              , "PCIE_CLKREQ_N", "VBUS_OC3"     , "SYS_RIO219", "PROC_RIO219", },                             // 53 
};

static void rp1_gpio_get_bank(int num, int *bank, int *offset)
{
    *bank = *offset = 0;
    if (num >= RP1_NUM_GPIOS)
    {
        assert(0);
        return;
    }

    if (num < rp1_bank_base[1])
        *bank = 0;
    else if (num < rp1_bank_base[2])
        *bank = 1;
    else
        *bank = 2;

   *offset = num - rp1_bank_base[*bank];
}

static uint32_t rp1_gpio_ctrl_read( int bank, int offset)
{
    return rp1_gpio_read32(gpio_register, gpio_state.io[bank], RP1_GPIO_IO_REG_CTRL_OFFSET(offset));
}

static void rp1_gpio_ctrl_write( int bank, int offset, uint32_t value)
{
    rp1_gpio_write32(gpio_register, gpio_state.io[bank], RP1_GPIO_IO_REG_CTRL_OFFSET(offset), value);
}

static uint32_t rp1_gpio_pads_read( int bank, int offset)
{
    return rp1_gpio_read32(gpio_register, gpio_state.pads[bank], RP1_GPIO_PADS_REG_OFFSET(offset));
}

static void rp1_gpio_pads_write( int bank, int offset, uint32_t value)
{
    rp1_gpio_write32(gpio_register, gpio_state.pads[bank], RP1_GPIO_PADS_REG_OFFSET(offset), value);
}

static uint32_t rp1_gpio_sys_rio_out_read( int bank )
{
    return rp1_gpio_read32(gpio_register, gpio_state.sys_rio[bank], RP1_GPIO_SYS_RIO_REG_OUT_OFFSET);
}

static uint32_t rp1_gpio_sys_rio_sync_in_read( int bank )
{
    return rp1_gpio_read32(gpio_register, gpio_state.sys_rio[bank], RP1_GPIO_SYS_RIO_REG_SYNC_IN_OFFSET);
}

static void rp1_gpio_sys_rio_out_write( int bank, uint32_t value)
{
    rp1_gpio_write32(gpio_register, gpio_state.sys_rio[bank], RP1_GPIO_SYS_RIO_REG_OUT_OFFSET, value);
}

static void rp1_gpio_sys_rio_out_clr( int bank, int offset )
{
    rp1_gpio_write32(gpio_register, gpio_state.sys_rio[bank],
                     RP1_GPIO_SYS_RIO_REG_OUT_OFFSET + RP1_CLR_OFFSET,
                     1U << offset);
}

static void rp1_gpio_sys_rio_out_set( int bank, int offset )
{
    rp1_gpio_write32(gpio_register, gpio_state.sys_rio[bank],
                     RP1_GPIO_SYS_RIO_REG_OUT_OFFSET + RP1_SET_OFFSET,
                     1U << offset);
}

static uint32_t rp1_gpio_sys_rio_oe_read(int bank)
{
    return rp1_gpio_read32(gpio_register, gpio_state.sys_rio[bank], RP1_GPIO_SYS_RIO_REG_OE_OFFSET);
}

// set direction INPUT
static void rp1_gpio_sys_rio_oe_clr( int bank, int offset)
{
    rp1_gpio_write32(gpio_register, gpio_state.sys_rio[bank],
                     RP1_GPIO_SYS_RIO_REG_OE_OFFSET + RP1_CLR_OFFSET,
                     1U << offset);
}

// set direction OUTPUT
static void rp1_gpio_sys_rio_oe_set( int bank, int offset)
{
    rp1_gpio_write32(gpio_register, gpio_state.sys_rio[bank],
                     RP1_GPIO_SYS_RIO_REG_OE_OFFSET + RP1_SET_OFFSET,
                     1U << offset);
}

static void rp1_gpio_set_dir(uint32_t gpio, GPIO_DIR_T dir)
{
    int bank, offset;

    rp1_gpio_get_bank(gpio, &bank, &offset);

    if (dir == DIR_INPUT)
        rp1_gpio_sys_rio_oe_clr(bank, offset);
    else if (dir == DIR_OUTPUT)
        rp1_gpio_sys_rio_oe_set(bank, offset);
    else
        assert(0);
}

static GPIO_DIR_T rp1_gpio_get_dir(unsigned gpio)
{
    int bank, offset;
    GPIO_DIR_T dir;
    uint32_t reg;

    rp1_gpio_get_bank(gpio, &bank, &offset);
    reg = rp1_gpio_sys_rio_oe_read(bank);

    dir = (reg & (1U << offset)) ? DIR_OUTPUT : DIR_INPUT;

    return dir;
}

static GPIO_FSEL_T rp1_gpio_get_fsel(unsigned gpio)
{
    int bank, offset;
    uint32_t reg;
    GPIO_FSEL_T fsel;
    RP1_FSEL_T rsel;

    rp1_gpio_get_bank(gpio, &bank, &offset);
    reg = rp1_gpio_ctrl_read( bank, offset);
    rsel = ((reg & RP1_GPIO_CTRL_FSEL_MASK) >> RP1_GPIO_CTRL_FSEL_LSB);
    if (rsel == RP1_FSEL_SYS_RIO)
        fsel = GPIO_FSEL_GPIO;
    else if (rsel == RP1_FSEL_NULL)
        fsel = GPIO_FSEL_NONE;
    else if (rsel < RP1_FSEL_COUNT)
        fsel = (GPIO_FSEL_T)rsel;
    else
        fsel = GPIO_FSEL_MAX;

    return fsel;
}

static void rp1_gpio_set_fsel(unsigned gpio, const GPIO_FSEL_T func)
{
    
    int bank, offset;
    uint32_t ctrl_reg;
    uint32_t pad_reg;
    uint32_t old_pad_reg;
    RP1_FSEL_T rsel;

    if (func < (GPIO_FSEL_T)RP1_FSEL_COUNT)
        rsel = (RP1_FSEL_T)func;
    else if (func == GPIO_FSEL_INPUT ||
             func == GPIO_FSEL_OUTPUT ||
             func == GPIO_FSEL_GPIO)
        rsel = RP1_FSEL_SYS_RIO;
    else if (func == GPIO_FSEL_NONE)
        rsel = RP1_FSEL_NULL;
    else
        return;

    rp1_gpio_get_bank(gpio, &bank, &offset);
    if (func == GPIO_FSEL_INPUT)
        rp1_gpio_set_dir(gpio, DIR_INPUT);
    else if (func == GPIO_FSEL_OUTPUT)
        rp1_gpio_set_dir(gpio, DIR_OUTPUT);

    ctrl_reg = rp1_gpio_ctrl_read(bank, offset) & ~RP1_GPIO_CTRL_FSEL_MASK;
    ctrl_reg |= rsel << RP1_GPIO_CTRL_FSEL_LSB;
    rp1_gpio_ctrl_write(bank, offset, ctrl_reg);

    pad_reg = rp1_gpio_pads_read(bank, offset);
    old_pad_reg = pad_reg;
    if (rsel == RP1_FSEL_NULL)
    {
        // Disable input
        pad_reg &= ~RP1_PADS_IE_SET;
    }
    else
    {
        // Enable input
        pad_reg |= RP1_PADS_IE_SET;
    }

    if (rsel != RP1_FSEL_NULL)
    {
        // Enable peripheral func output
        pad_reg &= ~RP1_PADS_OD_SET;
    }
    else
    {
        // Disable peripheral func output
        pad_reg |= RP1_PADS_OD_SET;
    }

    if (pad_reg != old_pad_reg)
        rp1_gpio_pads_write(bank, offset, pad_reg);
}

static int rp1_gpio_get_level(unsigned gpio)
{
    int bank, offset;
    uint32_t pad_reg;
    uint32_t reg;
    int level;

    rp1_gpio_get_bank(gpio, &bank, &offset);
    pad_reg = rp1_gpio_pads_read(bank, offset);
    if (!(pad_reg & RP1_PADS_IE_SET))
	return -1;
    reg = rp1_gpio_sys_rio_sync_in_read(bank);
    level = (reg & (1U << offset)) ? 1 : 0;

    return level;
}

static void rp1_gpio_set_drive(unsigned gpio, GPIO_DRIVE_T drv)
{
    uint32_t reg;
    int bank, offset;

    rp1_gpio_get_bank(gpio, &bank, &offset);
    
    //reg = rp1_gpio_sys_rio_out_read(bank);
    //if (drv == DRIVE_HIGH)
    //    reg |= (1U << offset);
    //else if (drv == DRIVE_LOW)
    //    reg &= ~(1U << offset);
    //rp1_gpio_sys_rio_out_write(bank, reg);
    
    if (drv == DRIVE_HIGH)
        rp1_gpio_sys_rio_out_set(bank, offset);
    else if (drv == DRIVE_LOW)
        rp1_gpio_sys_rio_out_clr(bank, offset);
    else
        assert(0);
    
}

static void rp1_gpio_set_pull( unsigned gpio, GPIO_PULL_T pull)
{
    uint32_t reg;
    int bank, offset;

    rp1_gpio_get_bank(gpio, &bank, &offset);
    reg = rp1_gpio_pads_read(bank, offset);
    reg &= ~(RP1_PADS_PDE_SET | RP1_PADS_PUE_SET);
    if (pull == PULL_UP)
        reg |= RP1_PADS_PUE_SET;
    else if (pull == PULL_DOWN)
        reg |= RP1_PADS_PDE_SET;
    rp1_gpio_pads_write(bank, offset, reg);
}

static GPIO_PULL_T rp1_gpio_get_pull(unsigned gpio)
{
    uint32_t reg;
    GPIO_PULL_T pull = PULL_NONE;
    int bank, offset;

    rp1_gpio_get_bank(gpio, &bank, &offset);
    reg = rp1_gpio_pads_read(bank, offset);
    if (reg & RP1_PADS_PUE_SET)
        pull = PULL_UP;
    else if (reg & RP1_PADS_PDE_SET)
        pull = PULL_DOWN;

    return pull;
}

static void rp1_gpio_set_schmitt( unsigned gpio, GPIO_SCHMITT_T schmitt )
{
    uint32_t reg;
    int bank, offset;

    rp1_gpio_get_bank(gpio, &bank, &offset);
    reg = rp1_gpio_pads_read(bank, offset);
    reg &= ~RP1_PADS_SCHMITT_SET;
    
    if( schmitt == SCHMITT_ON) {
        reg |= RP1_PADS_SCHMITT_SET;
    }
        
    rp1_gpio_pads_write(bank, offset, reg);
}

static GPIO_SCHMITT_T rp1_gpio_get_schmitt(unsigned gpio)
{
    uint32_t reg;
    int bank, offset;

    rp1_gpio_get_bank(gpio, &bank, &offset);
    reg = rp1_gpio_pads_read(bank, offset);
    
    return ( reg & RP1_PADS_SCHMITT_SET ) ? SCHMITT_ON : SCHMITT_OFF;
}

static void rp1_gpio_set_slew( unsigned gpio, GPIO_SLEW_T slew )
{
    uint32_t reg;
    int bank, offset;

    rp1_gpio_get_bank(gpio, &bank, &offset);
    reg = rp1_gpio_pads_read(bank, offset);
    reg &= ~RP1_PADS_SLEW_SET;
    
    if( slew == SLEW_FAST) {
        reg |= RP1_PADS_SLEW_SET;
    }
        
    rp1_gpio_pads_write(bank, offset, reg);
}

static GPIO_SLEW_T rp1_gpio_get_slew(unsigned gpio)
{
    uint32_t reg;
    int bank, offset;

    rp1_gpio_get_bank(gpio, &bank, &offset);
    reg = rp1_gpio_pads_read(bank, offset);
    
    return ( reg & RP1_PADS_SLEW_SET ) ? SLEW_FAST : SLEW_SLOW;
}

static GPIO_DRIVE_T rp1_gpio_get_drive(unsigned gpio)
{
    uint32_t reg;
    int bank, offset;

    rp1_gpio_get_bank(gpio, &bank, &offset);
    reg = rp1_gpio_sys_rio_out_read(bank);
    return (reg & (1U << offset)) ? DRIVE_HIGH : DRIVE_LOW;
}

static const char *rp1_gpio_get_name(unsigned gpio)
{
    static char name_buf[16];
    
    if (gpio >= RP1_NUM_GPIOS)
        return NULL;

    sprintf(name_buf, "GPIO%d", gpio);
    return name_buf;
}

static const char *rp1_gpio_get_fsel_name(unsigned gpio, GPIO_FSEL_T fsel)
{
    const char *name = NULL;
    switch (fsel)
    {
    case GPIO_FSEL_GPIO:
        name = "GPIO";
        break;
    case GPIO_FSEL_INPUT:
        name = "INPUT";
        break;
    case GPIO_FSEL_OUTPUT:
        name = "OUTPUT";
        break;
    case GPIO_FSEL_NONE:
        name = "NONE";
        break;
    case GPIO_FSEL_FUNC0:
    case GPIO_FSEL_FUNC1:
    case GPIO_FSEL_FUNC2:
    case GPIO_FSEL_FUNC3:
    case GPIO_FSEL_FUNC4:
    case GPIO_FSEL_FUNC5:
    case GPIO_FSEL_FUNC6:
    case GPIO_FSEL_FUNC7:
    case GPIO_FSEL_FUNC8:
        if (gpio < RP1_NUM_GPIOS)
        {
            name = rp1_gpio_fsel_names[gpio][fsel - GPIO_FSEL_FUNC0];
            if (!name)
                name = "-";
        }
        break;
    default:
        return NULL;
    }
    return name;
}

static int rp1_gpio_count()
{
    return RP1_NUM_GPIOS;
}

// map a memory block
static uint32_t *  map_gpiomem(int fd, uint32_t addr, uint32_t len)
{
    return (uint32_t *) mmap(0, len, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED|MAP_LOCKED, fd, addr);
}

// open /dev/gpiomem
static int open_gpiomen(void)
{
    if ((fdMem = open("/dev/gpiomem0", O_RDWR | O_SYNC) ) < 0)
    {
        return PI_INIT_FAILED;
    }
    
    return 0;
}

// initialise lib
static int do_initialise(void)
{    
    if(open_gpiomen() == PI_INIT_FAILED)
    {
        send_module_error("HiPi::GPIO failed to open memory device /dev/gpiomem0");
        do_uninitialise();
        return 0;
    }
    
    gpio_register = map_gpiomem(fdMem, GPIO_BASE, GPIO_LEN);

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
    if (gpio_register != MAP_FAILED) munmap((void *)gpio_register, GPIO_LEN);
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
    
    if( pud == PI_PUD_UNSET )
        pud = PI_PUD_OFF;
    
    rp1_gpio_set_pull( gpio, pud );

}

// get pud mode

int do_gpio_get_pud(unsigned gpio)
{
    return rp1_gpio_get_pull( gpio );
}

// set pin mode

static void do_gpio_set_mode(unsigned gpio, unsigned mode)
{
   rp1_gpio_set_fsel( gpio, mode );
}


// get pin mode
int do_gpio_get_mode(unsigned gpio)
{
   GPIO_DIR_T dir;
   int mode = rp1_gpio_get_fsel( gpio );
   if( mode == GPIO_FSEL_GPIO ) {
      dir = rp1_gpio_get_dir( gpio );
      if( dir == DIR_OUTPUT ) {
        return GPIO_FSEL_OUTPUT;
      } else {
        return GPIO_FSEL_INPUT;
      }
   } else {
      return mode;
   }
}

// read pin value
static int do_gpio_read(unsigned gpio)
{    
    return rp1_gpio_get_level( gpio );   
}

// write pin value
static void do_gpio_write(unsigned gpio, unsigned level)
{    
    rp1_gpio_set_drive( gpio, level );
}

// get schmitt value
static int do_gpio_get_schmitt(unsigned gpio)
{    
    return rp1_gpio_get_schmitt( gpio );
}

// set schmitt value
static void do_gpio_set_schmitt(unsigned gpio, unsigned schmitt)
{    
    rp1_gpio_set_schmitt( gpio, schmitt );
}

// get slew value
static int do_gpio_get_slew(unsigned gpio)
{    
    return rp1_gpio_get_slew( gpio );
}

// set slew value
static void do_gpio_set_slew(unsigned gpio, unsigned slew)
{    
    rp1_gpio_set_slew( gpio, slew );
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

static uint32_t map_fsel_rp1_to_hipi( GPIO_FSEL_T fsel )
{
    int hipi_mode = HIPI_MODE_NONE;
    switch (fsel)
    {
    case GPIO_FSEL_INPUT:
        hipi_mode = HIPI_MODE_INPUT;
        break;
    case GPIO_FSEL_OUTPUT:
        hipi_mode = HIPI_MODE_OUTPUT;
        break;
    case GPIO_FSEL_GPIO:
        hipi_mode = HIPI_MODE_INPUT;
        break;
    case GPIO_FSEL_FUNC0:
        hipi_mode = HIPI_MODE_ALT0;
        break;
    case GPIO_FSEL_FUNC1:
        hipi_mode = HIPI_MODE_ALT1;
        break;
    case GPIO_FSEL_FUNC2:
        hipi_mode = HIPI_MODE_ALT2;
        break;
    case GPIO_FSEL_FUNC3:
        hipi_mode = HIPI_MODE_ALT3;
        break;
    case GPIO_FSEL_FUNC4:
        hipi_mode = HIPI_MODE_ALT4;
        break;
    case GPIO_FSEL_FUNC5:
        hipi_mode = HIPI_MODE_ALT5;
        break;
    case GPIO_FSEL_FUNC6:
        hipi_mode = HIPI_MODE_ALT6;
        break;
    case GPIO_FSEL_FUNC7:
        hipi_mode = HIPI_MODE_ALT7;
        break;
    case GPIO_FSEL_FUNC8:
        hipi_mode = HIPI_MODE_ALT8;
        break;
    default:
        hipi_mode = HIPI_MODE_NONE;
    }
    return hipi_mode;
}

static GPIO_FSEL_T map_fsel_hipi_to_rp1( int fsel )
{
    GPIO_FSEL_T rp1_mode = GPIO_FSEL_NONE;
    switch (fsel)
    {
    case HIPI_MODE_INPUT:
        rp1_mode = GPIO_FSEL_INPUT;
        break;
    case HIPI_MODE_OUTPUT:
        rp1_mode = GPIO_FSEL_OUTPUT;
        break;
    case HIPI_MODE_ALT0:
        rp1_mode = GPIO_FSEL_FUNC0;
        break;
    case HIPI_MODE_ALT1:
        rp1_mode = GPIO_FSEL_FUNC1;
        break;
    case HIPI_MODE_ALT2:
        rp1_mode = GPIO_FSEL_FUNC2;
        break;
    case HIPI_MODE_ALT3:
        rp1_mode = GPIO_FSEL_FUNC3;
        break;
    case HIPI_MODE_ALT4:
        rp1_mode = GPIO_FSEL_FUNC4;
        break;
    case HIPI_MODE_ALT5:
        rp1_mode = GPIO_FSEL_FUNC5;
        break;
    case HIPI_MODE_ALT6:
        rp1_mode = GPIO_FSEL_FUNC6;
        break;
    case HIPI_MODE_ALT7:
        rp1_mode = GPIO_FSEL_FUNC7;
        break;
    case HIPI_MODE_ALT8:
        rp1_mode = GPIO_FSEL_FUNC8;
        break;
    default:
        rp1_mode = GPIO_FSEL_NONE;
    }
    return rp1_mode;
}

MODULE = HiPi::GPIO::RP1  PACKAGE = HiPi::GPIO

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
        do_gpio_set_mode( gpio, map_fsel_hipi_to_rp1( mode ));
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
        RETVAL = map_fsel_rp1_to_hipi(do_gpio_get_mode( gpio ));
    }
    
  OUTPUT: RETVAL

void
xs_gpio_get_mode_name( gpio, mode )
    unsigned gpio
    int mode
  PPCODE:
    XPUSHs(sv_2mortal(newSVpv(rp1_gpio_get_fsel_name( gpio, map_fsel_hipi_to_rp1( mode ) ), 0)));

void
xs_gpio_get_current_mode_name( gpio )
    unsigned gpio
  PPCODE:
    XPUSHs(sv_2mortal(newSVpv(rp1_gpio_get_fsel_name( gpio, do_gpio_get_mode( gpio ) ), 0)));

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
  
int
xs_gpio_set_schmitt( gpio, schmitt )
    unsigned gpio
    unsigned schmitt
  CODE:
  
    if (gpio > PI_MAX_GPIO) {
        send_module_error("bad gpio number specified");
        RETVAL = PI_PIN_ERROR;
    } else if( schmitt >= SCHMITT_MAX ){
        send_module_error("bad schmitt value specified");
        RETVAL = PI_PIN_ERROR;
    } else {
        do_gpio_set_schmitt( gpio, schmitt);
        RETVAL = (int)schmitt;
    }
    
  OUTPUT: RETVAL


int
xs_gpio_get_schmitt( gpio )
    unsigned gpio
  CODE:
  
    if (gpio > PI_MAX_GPIO) {
        send_module_error("bad gpio number specified");
        RETVAL = PI_PIN_ERROR;
    } else {
        RETVAL = do_gpio_get_schmitt( gpio );
    }
    
  OUTPUT: RETVAL
  
int
xs_gpio_set_slew( gpio, slew )
    unsigned gpio
    unsigned slew
  CODE:
  
    if (gpio > PI_MAX_GPIO) {
        send_module_error("bad gpio number specified");
        RETVAL = PI_PIN_ERROR;
    } else if( slew >= SLEW_MAX ){
        send_module_error("bad slew value specified");
        RETVAL = PI_PIN_ERROR;
    } else {
        do_gpio_set_slew( gpio, slew);
        RETVAL = (int)slew;
    }
    
  OUTPUT: RETVAL


int
xs_gpio_get_slew( gpio )
    unsigned gpio
  CODE:
  
    if (gpio > PI_MAX_GPIO) {
        send_module_error("bad gpio number specified");
        RETVAL = PI_PIN_ERROR;
    } else {        
        RETVAL = do_gpio_get_slew( gpio );
    }
    
  OUTPUT: RETVAL


uint64_t xs_gpio_get_peripheral_base_address()
  CODE:
    RETVAL = PERI_BASE_ADDRESS;
  
  OUTPUT: RETVAL
