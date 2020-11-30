##########################################################################################
# Distribution : HiPi Modules for Raspberry Pi
# File         : lib/HiPi/Constant.pm
# Description  : Constants for HiPi
# Copyright    : Copyright (c) 2013-2020 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Constant;

#########################################################################################
use strict;
use warnings;
use parent qw( Exporter );
use HiPi::RaspberryPi;

our $VERSION ='0.82';

our @EXPORT_OK = ( qw( hipi_export_ok  hipi_export_constants hipi_export_tags ) );
our %EXPORT_TAGS = ( hipi => \@EXPORT_OK );

my $MCP_DAC_RESOLUTION_08 = 0x010;
my $MCP_DAC_RESOLUTION_10 = 0x020;
my $MCP_DAC_RESOLUTION_12 = 0x030;
my $MCP_DAC_DUAL_CHANNEL  = 0x001;
my $MCP_DAC_CAN_BUFFER    = 0x002;

my $legacyboard = ( HiPi::RaspberryPi::board_type() == 1 ) ? 1 : 0;

my $const = {
    i2c => {
        I2C_READMODE_SYSTEM => 0,
        I2C_READMODE_REPEATED_START => 1,
        I2C_READMODE_START_STOP => 2,
        
        I2C_SCANMODE_AUTO  => 0,
        I2C_SCANMODE_QUICK => 1,
        I2C_SCANMODE_READ  => 2,
        
        I2C_RETRIES     => 0x0701,
        I2C_TIMEOUT     => 0x0702,
        I2C_SLAVE       => 0x0703,
        I2C_TENBIT      => 0x0704,
        I2C_FUNCS       => 0x0705,
        I2C_SLAVE_FORCE => 0x0706,
        I2C_RDWR        => 0x0707,
        I2C_PEC         => 0x0708,
        I2C_SMBUS       => 0x0720,
        
        I2C_M_TEN          => 0x0010,
        I2C_M_RD		   => 0x0001,
        I2C_M_NOSTART	   => 0x4000,
        I2C_M_REV_DIR_ADDR => 0x2000,
        I2C_M_IGNORE_NAK   => 0x1000,
        I2C_M_NO_RD_ACK	   => 0x0800,
        I2C_M_RECV_LEN	   => 0x0400,
        
        I2C0_SDA	       => ( $legacyboard ) ? 0 : 28,
        I2C0_SCL	       => ( $legacyboard ) ? 1 : 29,
        I2C1_SDA	       => 2,
        I2C1_SCL	       => 3,
        I2C_SDA	           => ( $legacyboard ) ? 0 : 2,
        I2C_SCL	           => ( $legacyboard ) ? 1 : 3,
        ID_SD	           => 0,
        ID_SC	           => 1,
    },
    
    rpi => {
        
        
        
        RPI_PIN_3  =>  ( $legacyboard ) ? 0 : 2,
        RPI_PIN_5  =>  ( $legacyboard ) ? 1 : 3,
        RPI_PIN_7  =>  4,
        RPI_PIN_8  => 14,
        RPI_PIN_10 => 15,
        RPI_PIN_11 => 17,
        RPI_PIN_12 => 18,
        RPI_PIN_13 => 27,
        RPI_PIN_15 => 22,
        RPI_PIN_16 => 23,
        RPI_PIN_18 => 24,
        RPI_PIN_19 => 10,
        RPI_PIN_21 =>  9,
        RPI_PIN_22 => 25,
        RPI_PIN_23 => 11,
        RPI_PIN_24 =>  8,
        RPI_PIN_26 =>  7,
        RPI_PIN_27 => 0,
        RPI_PIN_28 => 1,
        RPI_PIN_29 => 5,
        RPI_PIN_31 => 6,
        RPI_PIN_32 => 12,
        RPI_PIN_33 => 13,
        RPI_PIN_35 => 19,
        RPI_PIN_36 => 16,
        RPI_PIN_37 => 26,
        RPI_PIN_38 => 20,
        RPI_PIN_40 => 21,
        
        RPI_OUTPUT => 1,
        RPI_INPUT  => 0,
        
        RPI_MODE_INPUT  => 0,
        RPI_MODE_OUTPUT => 1,
        RPI_MODE_ALT0   => 4,
        RPI_MODE_ALT1   => 5,
        RPI_MODE_ALT2   => 6,
        RPI_MODE_ALT3   => 7,
        RPI_MODE_ALT4   => 3,
        RPI_MODE_ALT5   => 2,
        
        RPI_ALT_FUNCTION_VERSION_2708 => 1,
        RPI_ALT_FUNCTION_VERSION_2711 => 2,
        
        RPI_INT_NONE           => 0x00,
        RPI_INT_FALL           => 0x01,
        RPI_INT_RISE           => 0x02,
        RPI_INT_BOTH           => 0x03,
        RPI_INT_AFALL          => 0x04,
        RPI_INT_ARISE          => 0x08,
        RPI_INT_HIGH           => 0x10,
        RPI_INT_LOW            => 0x20,
        
        # legacy
        RPI_PINMODE_INPT       => 0,
        RPI_PINMODE_OUTP       => 1,
        RPI_PINMODE_ALT0       => 4,
        RPI_PINMODE_ALT1       => 5,
        RPI_PINMODE_ALT2       => 6,
        RPI_PINMODE_ALT3       => 7,
        RPI_PINMODE_ALT4       => 3,
        RPI_PINMODE_ALT5       => 2,
        
        RPI_HIGH   => 1,
        RPI_LOW    => 0,
        
        RPI_BOARD_TYPE_1 => 1,
        RPI_BOARD_TYPE_2 => 2,
        RPI_BOARD_TYPE_3 => 3,
        
        RPI_PUD_NULL           => -1,
        RPI_PUD_OFF            => 0,
        RPI_PUD_DOWN           => 1,
        RPI_PUD_UP             => 2,
        RPI_PUD_UNSET          => 0x08,
        
        RPI_BOARD_REVISION     => HiPi::RaspberryPi::board_type(),
        
        DEV_GPIO_PIN_STATUS_NONE         => 0x00,
        DEV_GPIO_PIN_STATUS_EXPORTED     => 0x01,
    },
    
    spi => {
        SPI_CPHA        => 0x01,
        SPI_CPOL        => 0x02,
        SPI_MODE_0      => 0x00,
        SPI_MODE_1      => 0x01,
        SPI_MODE_2      => 0x02,
        SPI_MODE_3      => 0x03,
        SPI_CS_HIGH     => 0x04,
        SPI_LSB_FIRST   => 0x08,
        SPI_3WIRE       => 0x10,
        SPI_LOOP        => 0x20,
        SPI_NO_CS       => 0x40,
        SPI_READY       => 0x80,
        SPI_SPEED_KHZ_500 => 500000,
        SPI_SPEED_MHZ_1   => 1000000,
        SPI_SPEED_MHZ_2   => 2000000,
        SPI_SPEED_MHZ_4   => 4000000,
        SPI_SPEED_MHZ_8   => 8000000,
        SPI_SPEED_MHZ_16  => 16000000,
        SPI_SPEED_MHZ_32  => 32000000,
    },
    
    mcp23x17 => {
        MCP23S17_A0     => 0x1000,
        MCP23S17_A1     => 0x1001,
        MCP23S17_A2     => 0x1002,
        MCP23S17_A3     => 0x1003,
        MCP23S17_A4     => 0x1004,
        MCP23S17_A5     => 0x1005,
        MCP23S17_A6     => 0x1006,
        MCP23S17_A7     => 0x1007,
        MCP23S17_B0     => 0x1010,
        MCP23S17_B1     => 0x1011,
        MCP23S17_B2     => 0x1012,
        MCP23S17_B3     => 0x1013,
        MCP23S17_B4     => 0x1014,
        MCP23S17_B5     => 0x1015,
        MCP23S17_B6     => 0x1016,
        MCP23S17_B7     => 0x1017,
        
        MCP23S17_BANK   => 7,
        MCP23S17_MIRROR => 6,
        MCP23S17_SEQOP  => 5,
        MCP23S17_DISSLW => 4,
        MCP23S17_HAEN   => 3,
        MCP23S17_ODR    => 2,
        MCP23S17_INTPOL => 1,
        
        MCP23S17_INPUT  => 1,
        MCP23S17_OUTPUT => 0,
        
        MCP23S17_HIGH   => 1,
        MCP23S17_LOW    => 0,
    
        MCP23017_A0     => 0x1000,
        MCP23017_A1     => 0x1001,
        MCP23017_A2     => 0x1002,
        MCP23017_A3     => 0x1003,
        MCP23017_A4     => 0x1004,
        MCP23017_A5     => 0x1005,
        MCP23017_A6     => 0x1006,
        MCP23017_A7     => 0x1007,
        MCP23017_B0     => 0x1010,
        MCP23017_B1     => 0x1011,
        MCP23017_B2     => 0x1012,
        MCP23017_B3     => 0x1013,
        MCP23017_B4     => 0x1014,
        MCP23017_B5     => 0x1015,
        MCP23017_B6     => 0x1016,
        MCP23017_B7     => 0x1017,
        
        MCP23017_BANK   => 7,
        MCP23017_MIRROR => 6,
        MCP23017_SEQOP  => 5,
        MCP23017_DISSLW => 4,
        MCP23017_HAEN   => 3,
        MCP23017_ODR    => 2,
        MCP23017_INTPOL => 1,
        
        MCP23017_INPUT  => 1,
        MCP23017_OUTPUT => 0,
        
        MCP23017_HIGH   => 1,
        MCP23017_LOW    => 0,
    
        MCP_PIN_A0     => 'A0',
        MCP_PIN_A1     => 'A1',
        MCP_PIN_A2     => 'A2',
        MCP_PIN_A3     => 'A3',
        MCP_PIN_A4     => 'A4',
        MCP_PIN_A5     => 'A5',
        MCP_PIN_A6     => 'A6',
        MCP_PIN_A7     => 'A7',
        MCP_PIN_B0     => 'B0',
        MCP_PIN_B1     => 'B1',
        MCP_PIN_B2     => 'B2',
        MCP_PIN_B3     => 'B3',
        MCP_PIN_B4     => 'B4',
        MCP_PIN_B5     => 'B5',
        MCP_PIN_B6     => 'B6',
        MCP_PIN_B7     => 'B7',
    },
    
    mpl3115a2 => {
        MPL_REG_STATUS              => 0x00,
        MPL_REG_OUT_P_MSB           => 0x01,
        MPL_REG_OUT_P_CSB           => 0x02,
        MPL_REG_OUT_P_LSB           => 0x03,
        MPL_REG_OUT_T_MSB           => 0x04,
        MPL_REG_OUT_T_LSB           => 0x05,
        MPL_REG_DR_STATUS           => 0x06,
        MPL_REG_OUT_P_DELTA_MSB     => 0x07,
        MPL_REG_OUT_P_DELTA_CSB     => 0x08,
        MPL_REG_OUT_P_DELTA_LSB     => 0x09,
        MPL_REG_OUT_T_DELTA_MSB     => 0x0A,
        MPL_REG_OUT_T_DELTA_LSB     => 0x0B,
        MPL_REG_WHO_AM_I            => 0x0C,
        MPL_REG_F_STATUS            => 0x0D,
        MPL_REG_F_DATA              => 0x0E,
        MPL_REG_F_SETUP             => 0x0F,
        MPL_REG_TIME_DLY            => 0x10,
        MPL_REG_SYSMOD              => 0x11,
        MPL_REG_INT_SOURCE          => 0x12,
        MPL_REG_PT_DATA_CFG         => 0x13,
        MPL_REG_BAR_IN_MSB          => 0x14,
        MPL_REG_MAR_IN_LSB          => 0x15,
        MPL_REG_P_TGT_MSB           => 0x16,
        MPL_REG_P_TGT_LSB           => 0x17,
        MPL_REG_T_TGT               => 0x18,
        MPL_REG_P_WND_MSB           => 0x19,
        MPL_REG_P_WND_LSB           => 0x1A,
        MPL_REG_T_WND               => 0x1B,
        MPL_REG_P_MIN_MSB           => 0x1C,
        MPL_REG_P_MIN_CSB           => 0x1D,
        MPL_REG_P_MIN_LSB           => 0x1E,
        MPL_REG_T_MIN_MSB           => 0x1F,
        MPL_REG_T_MIN_LSB           => 0x20,
        MPL_REG_P_MAX_MSB           => 0x21,
        MPL_REG_P_MAX_CSB           => 0x22,
        MPL_REG_P_MAX_LSB           => 0x23,
        MPL_REG_T_MAX_MSB           => 0x24,
        MPL_REG_T_MAX_LSB           => 0x25,
        MPL_REG_CTRL_REG1           => 0x26,
        MPL_REG_CTRL_REG2           => 0x27,
        MPL_REG_CTRL_REG3           => 0x28,
        MPL_REG_CTRL_REG4           => 0x29,
        MPL_REG_CTRL_REG5           => 0x2A,
        MPL_REG_OFF_P               => 0x2B,
        MPL_REG_OFF_T               => 0x2C,
        MPL_REG_OFF_H               => 0x2D,
        
        MPL_CTRL_REG1_SBYB          => 0x01,
        MPL_CTRL_REG1_OST           => 0x02,
        MPL_CTRL_REG1_RST           => 0x04,
        MPL_CTRL_REG1_OS0           => 0x08,
        MPL_CTRL_REG1_OS1           => 0x10,
        MPL_CTRL_REG1_OS2           => 0x20,
        MPL_CTRL_REG1_RAW           => 0x40,
        MPL_CTRL_REG1_ALT           => 0x80,
        
        MPL_CTRL_REG1_MASK          => 0xFF,
        
        MPL_CTRL_REG2_ST0           => 0x01,
        MPL_CTRL_REG2_ST1           => 0x02,
        MPL_CTRL_REG2_ST2           => 0x04,
        MPL_CTRL_REG2_ST3           => 0x08,
        MPL_CTRL_REG2_ALARM_SEL     => 0x10,
        MPL_CTRL_REG2_LOAD_OUTPUT   => 0x20,
        
        MPL_CTRL_REG2_MASK          => 0x3F,
        
        MPL_CTRL_REG3_PP_0D2        => 0x01,
        MPL_CTRL_REG3_IPOL2         => 0x02,
        MPL_CTRL_REG3_PP_OD1        => 0x10,
        MPL_CTRL_REG3_IPOL1         => 0x20,
      
        MPL_CTRL_REG3_MASK          => 0x33,
        
        MPL_CTRL_REG4_INT_EN_DRDY   => 0x80,
        MPL_CTRL_REG4_INT_EN_FIFO   => 0x40,
        MPL_CTRL_REG4_INT_EN_PW     => 0x20,
        MPL_CTRL_REG4_INT_EN_TW     => 0x10,
        MPL_CTRL_REG4_INT_EN_PTH    => 0x08,
        MPL_CTRL_REG4_INT_EN_TTH    => 0x04,
        MPL_CTRL_REG4_INT_EN_PCHG   => 0x02,
        MPL_CTRL_REG4_INT_EN_TCHG   => 0x01,
        
        MPL_CTRL_REG4_MASK          => 0xFF,
        
        MPL_INTREGS_DRDY  => 0x80,
        MPL_INTREGS_FIFO  => 0x40,
        MPL_INTREGS_PW    => 0x20,
        MPL_INTREGS_TW    => 0x10,
        MPL_INTREGS_PTH   => 0x08,
        MPL_INTREGS_TTH   => 0x04,
        MPL_INTREGS_PCHG  => 0x02,
        MPL_INTREGS_TCHG  => 0x01,
        
        MPL_INTREGS_MASK          => 0xFF,
        
        MPL_DR_STATUS_PTOW          => 0x80,
        MPL_DR_STATUS_POW           => 0x40,
        MPL_DR_STATUS_TOW           => 0x20,
        MPL_DR_STATUS_PTDR          => 0x08,
        MPL_DR_STATUS_PDR           => 0x04,
        MPL_DR_STATUS_TDR           => 0x02,
        
        MPL_DR_STATUS_MASK          => 0xEE,
        
        MPL_F_STATUS_F_OVF          => 0x80,
        MPL_F_STATUS_F_WMRK_FLAG    => 0x40,
        MPL_F_STATUS_F_CNT5         => 0x20,
        MPL_F_STATUS_F_CNT4         => 0x10,
        MPL_F_STATUS_F_CNT3         => 0x08,
        MPL_F_STATUS_F_CNT2         => 0x04,
        MPL_F_STATUS_F_CNT1         => 0x02,
        MPL_F_STATUS_F_CNT0         => 0x01,
        
        MPL_F_STATUS_MASK           => 0xFF,
        
        MPL_PT_DATA_CFG_DREM        => 0x04,
        MPL_PT_DATA_CFG_PDEFE       => 0x02,
        MPL_PT_DATA_CFG_TDEFE       => 0x01,
        
        MPL_PT_DATA_CFG_MASK        => 0x07,
        
        MPL_BIT_SBYB          => 0,
        MPL_BIT_OST           => 1,
        MPL_BIT_RST           => 2,
        MPL_BIT_OS0           => 3,
        MPL_BIT_OS1           => 4,
        MPL_BIT_OS2           => 5,
        MPL_BIT_RAW           => 6,
        MPL_BIT_ALT           => 7,
        
        MPL_BIT_ST0           => 0,
        MPL_BIT_ST1           => 1,
        MPL_BIT_ST2           => 2,
        MPL_BIT_ST3           => 3,
        MPL_BIT_ALARM_SEL     => 4,
        MPL_BIT_LOAD_OUTPUT   => 5,
        
        MPL_BIT_PP_0D2        => 0,
        MPL_BIT_IPOL2         => 1,
        MPL_BIT_PP_OD1        => 4,
        MPL_BIT_IPOL1         => 5,
        
        # interrupt bits for CTRL_REG5,
        # INT_SOURCE
        
        MPL_BIT_DRDY          => 7,
        MPL_BIT_FIFO          => 6,
        MPL_BIT_PW            => 5,
        MPL_BIT_TW            => 4,
        MPL_BIT_PTH           => 3,
        MPL_BIT_TTH           => 2,
        MPL_BIT_PCHG          => 1,
        MPL_BIT_TCHG          => 0,
        
        MPL_BIT_PTOW          => 7,
        MPL_BIT_POW           => 6,
        MPL_BIT_TOW           => 5,
        MPL_BIT_PTDR          => 3,
        MPL_BIT_PDR           => 2,
        MPL_BIT_TDR           => 1,
        
        MPL_BIT_F_OVF        => 7,
        MPL_BIT_F_WMRK_FLAG  => 6,
        MPL_BIT_F_CNT5       => 5,
        MPL_BIT_F_CNT4       => 4,
        MPL_BIT_F_CNT3       => 3,
        MPL_BIT_F_CNT2       => 2,
        MPL_BIT_F_CNT1       => 1,
        MPL_BIT_F_CNT0       => 0,
        
        MPL_BIT_DREM         => 2,
        MPL_BIT_PDEFE        => 1,
        MPL_BIT_TDEFE        => 0,
        
        
        MPL_OSREAD_DELAY     => 1060, # left for compatibility with code that uses it.
                                      
        MPL_FUNC_ALTITUDE    => 1,
        MPL_FUNC_PRESSURE    => 2,
        MPL3115A2_ID         => 0xC4,
        
        
        MPL_CONTROL_MASK     => 0b00111000, #128 oversampling
        MPL_BYTE_MASK        => 0xFF,
        MPL_WORD_MASK        => 0xFFFF,
        
        MPL_OVERSAMPLE_1     => 0b00000000,
        MPL_OVERSAMPLE_2     => 0b00001000,
        MPL_OVERSAMPLE_4     => 0b00010000,
        MPL_OVERSAMPLE_8     => 0b00011000,
        MPL_OVERSAMPLE_16    => 0b00100000,
        MPL_OVERSAMPLE_32    => 0b00101000,
        MPL_OVERSAMPLE_64    => 0b00110000,
        MPL_OVERSAMPLE_128   => 0b00111000,
        
        MPL_OVERSAMPLE_MASK  => 0b00111000,
        
        MPL_BB_I2C_PERI_0    => 0x10,
        MPL_BB_I2C_PERI_1    => 0x20,
        
    },
    
    lcd => {
        HD44780_CLEAR_DISPLAY           => 0x01,
        HD44780_HOME_UNSHIFT            => 0x02,
        HD44780_CURSOR_MODE_LEFT        => 0x04,
        HD44780_CURSOR_MODE_LEFT_SHIFT  => 0x05,
        HD44780_CURSOR_MODE_RIGHT       => 0x06,
        HD44780_CURSOR_MODE_RIGHT_SHIFT => 0x07,
        HD44780_DISPLAY_OFF             => 0x08,
        
        HD44780_DISPLAY_ON              => 0x0C,
        HD44780_CURSOR_OFF              => 0x0C,
        HD44780_CURSOR_UNDERLINE        => 0x0E,
        HD44780_CURSOR_BLINK            => 0x0F,
        
        HD44780_SHIFT_CURSOR_LEFT       => 0x10,
        HD44780_SHIFT_CURSOR_RIGHT      => 0x14,
        HD44780_SHIFT_DISPLAY_LEFT      => 0x18,
        HD44780_SHIFT_DISPLAY_RIGHT     => 0x1C,
        
        HD44780_CURSOR_POSITION         => 0x80,
        
        SRX_CURSOR_OFF       => 0x0C,
        SRX_CURSOR_BLINK     => 0x0F,
        SRX_CURSOR_UNDERLINE => 0x0E,
        
        HTV2_END_SERIALRX_COMMAND    => chr(0xFF),
    
        HTV2_BAUD_2400    => 0,
        HTV2_BAUD_4800    => 1,
        HTV2_BAUD_9600    => 2,
        HTV2_BAUD_14400   => 3,
        HTV2_BAUD_19200   => 4,
        HTV2_BAUD_28800   => 5,
        HTV2_BAUD_57600   => 6,
        HTV2_BAUD_115200  => 7,
        
        HTV2_CMD_PRINT          => 1,
        HTV2_CMD_SET_CURSOR_POS => 2,
        HTV2_CMD_CLEAR_LINE     => 3,
        HTV2_CMD_CLEAR_DISPLAY  => 4,
        HTV2_CMD_LCD_TYPE       => 5,
        HTV2_CMD_HD44780_CMD    => 6,
        HTV2_CMD_BACKLIGHT      => 7,
        HTV2_CMD_WRITE_CHAR     => 10,
        HTV2_CMD_I2C_ADDRESS    => 32,
        HTV2_CMD_BAUD_RATE      => 33,
        HTV2_CMD_CUSTOM_CHAR    => 64,
        
        SLCD_START_COMMAND    => chr(0xFE),
        SLCD_SPECIAL_COMMAND  => chr(0x7C),
    },
    
    hrf69 => {
        RF69_REG_FIFO			=> 0x00,
        RF69_REG_OPMODE			=> 0x01,
        RF69_REG_REGDATAMODUL	=> 0x02,
        RF69_REG_BITRATEMSB		=> 0x03,
        RF69_REG_BITRATELSB		=> 0x04,
        RF69_REG_FDEVMSB		=> 0x05,
        RF69_REG_FDEVLSB		=> 0x06,
        RF69_REG_FRMSB			=> 0x07,
        RF69_REG_FRMID			=> 0x08,
        RF69_REG_FRLSB			=> 0x09,
        RF69_REG_CALLIB         => 0x0A,
        RF69_REG_AFCCTRL		=> 0x0B,
        RF69_REG_LISTEN1        => 0x0D,
        RF69_REG_LISTEN2        => 0x0E,
        RF69_REG_LISTEN3        => 0x0F,
        RF69_REG_VERSION        => 0x10,
        RF69_REG_PALEVEL        => 0x11,
        RF69_REG_PARAMP         => 0x12,
        RF69_REG_OCP            => 0x13,
        RF69_REG_LNA            => 0x18,
        RF69_REG_RXBW			=> 0x19,
        RF69_REG_AFCBW          => 0x1A,
        RF69_REG_OOKPEAK        => 0x1B,
        RF69_REG_OOKAVG         => 0x1C,
        RF69_REG_OOKFIX         => 0x1D,
        RF69_REG_AFCFEI			=> 0x1E,
        RF69_REG_AFCMSB         => 0x1F,
        RF69_REG_AFCLSB         => 0x20,
        RF69_REG_FEIMSB         => 0x21,
        RF69_REG_FEILSB         => 0x22,
        RF69_REG_RSSICONFIG     => 0x23,
        RF69_REG_RSSIVALUE      => 0x24,
        RF69_REG_DIOMAPPING1    => 0x25,
        RF69_REG_DIOMAPPING2    => 0x26,
        RF69_REG_IRQFLAGS1		=> 0x27,
        RF69_REG_IRQFLAGS2		=> 0x28,
        RF69_REG_RSSITHRESH		=> 0x29,
        RF69_REG_RXTIMEOUT1     => 0x2A,
        RF69_REG_RXTIMEOUT2     => 0x2B,
        RF69_REG_PREAMBLEMSB    => 0x2C,
        RF69_REG_PREAMBLELSB	=> 0x2D,
        RF69_REG_SYNCCONFIG		=> 0x2E,
        RF69_REG_SYNCVALUE1		=> 0x2F,
        RF69_REG_SYNCVALUE2		=> 0x30,
        RF69_REG_SYNCVALUE3		=> 0x31,
        RF69_REG_SYNCVALUE4		=> 0x32,
        RF69_REG_SYNCVALUE5     => 0x33,
        RF69_REG_SYNCVALUE6     => 0x34,
        RF69_REG_SYNCVALUE7     => 0x35,
        RF69_REG_SYNCVALUE8     => 0x36,
        RF69_REG_PACKETCONFIG1  => 0x37,
        RF69_REG_PAYLOADLEN     => 0x38,
        RF69_REG_NODEADDRESS    => 0x39,
        RF69_REG_BROADCASTADDRESS => 0x3A,
        RF69_REG_AUTOMODES      => 0x3B,
        RF69_REG_FIFOTHRESH     => 0x3C,
        RF69_REG_PACKETCONFIG2  => 0x3D,
        RF69_REG_AESKEY1        => 0x3E,
        RF69_REG_AESKEY2        => 0x3F,
        RF69_REG_AESKEY3        => 0x40,
        RF69_REG_AESKEY4        => 0x41,
        RF69_REG_AESKEY5        => 0x42,
        RF69_REG_AESKEY6        => 0x43,
        RF69_REG_AESKEY7        => 0x44,
        RF69_REG_AESKEY8        => 0x45,
        RF69_REG_AESKEY9        => 0x46,
        RF69_REG_AESKEY10       => 0x47,
        RF69_REG_AESKEY11       => 0x48,
        RF69_REG_AESKEY12       => 0x49,
        RF69_REG_AESKEY13       => 0x4A,
        RF69_REG_AESKEY14       => 0x4B,
        RF69_REG_AESKEY15       => 0x4C,
        RF69_REG_AESKEY16       => 0x4D,
        RF69_REG_TEMP1          => 0x4E,
        RF69_REG_TEMP2          => 0x4F,
        
        RF69_REG_TESTLNA        => 0x58,
        RF69_REG_TESTPA1        => 0x5A,
        RF69_REG_TESTPA2        => 0x5C,
        RF69_REG_TESTDAGC       => 0x6F,
        
        RF69_REG_TESTAFC        => 0x71,
        
        RF69_MASK_REG_WRITE          => 0x80,
    
        RF69_TRUE                    => 1,
        RF69_FALSE                   => 0,
        
        RF69_MASK_OPMODE_SEQOFF      => 0x80,
        RF69_MASK_OPMODE_LISTENON    => 0x40,
        RF69_MASK_OPMODE_LISTENABORT => 0x20,
        RF69_MASK_OPMODE_RX          => 0x10,
        RF69_MASK_OPMODE_TX          => 0x0C,
        RF69_MASK_OPMODE_FS          => 0x08,
        RF69_MASK_OPMODE_SB          => 0x04,
        
        RF69_MASK_MODEREADY          => 0x80,
        RF69_MASK_FIFONOTEMPTY       => 0x40,
        
        RF69_MASK_FIFOLEVEL		    => 0x20,
        RF69_MASK_FIFOOVERRUN	    => 0x10,
        RF69_MASK_PACKETSENT		=> 0x08,
        RF69_MASK_TXREADY		    => 0x20,
        RF69_MASK_PACKETMODE		=> 0x60,
        RF69_MASK_MODULATION		=> 0x18,
        RF69_MASK_PAYLOADRDY		=> 0x04,
        RF69_MASK_REGDATAMODUL_FSK	=> 0x00,  # Modulation scheme FSK
        RF69_MASK_REGDATAMODUL_OOK	=> 0x08,  # Modulation scheme OOK
        
        RF69_VAL_AFCCTRLS		=> 0x00,  # standard AFC routine
        RF69_VAL_AFCCTRLI		=> 0x20,  # improved AFC routine
        RF69_VAL_LNA50			=> 0x08,  # LNA input impedance 50 ohms
        RF69_VAL_LNA50G			=> 0x0E,  # LNA input impedance 50 ohms, LNA gain -> 48db
        RF69_VAL_LNA200			=> 0x88,  # LNA input impedance 200 ohms
        RF69_VAL_RXBW60			=> 0x43,  # channel filter bandwidth 10kHz -> 60kHz  page:26
        RF69_VAL_RXBW120		=> 0x41,  # channel filter bandwidth 120kHz
        RF69_VAL_AFCFEIRX		=> 0x04,  # AFC is performed each time RX mode is entered
        RF69_VAL_RSSITHRESH220	=> 0xDC,  # RSSI threshold => 0xE4 -> => 0xDC (220)
        RF69_VAL_PREAMBLELSB3	=> 0x03,  # preamble size LSB 3
        RF69_VAL_PREAMBLELSB5	=> 0x05,  # preamble size LSB 5
        
        RF69_VAL_OCP_OFF        => 0x0F,
        RF69_VAL_OCP_ON         => 0x1A,  # default
        RF69_PALEVEL_PA0_ON     => 0x80,  # Default
        RF69_PALEVEL_PA0_OFF    => 0x00,
        RF69_PALEVEL_PA1_ON     => 0x40,
        RF69_PALEVEL_PA1_OFF    => 0x00,  # Default
        RF69_PALEVEL_PA2_ON     => 0x20,
        RF69_PALEVEL_PA2_OFF    => 0x00,  # Default
    },
    
    mcp3adc => {
        # msb = channels, lsb = hsb return value mask - 10 bit = 0x03, 12 bit = 0x0F
        MCP3004 => 0x0403, # 4 channels, 10 bit
        MCP3008 => 0x0803, # 8 channels, 10 bit
        MCP3204 => 0x040F, # 4 channels, 12 bit
        MCP3208 => 0x080F, # 8 channels, 12 bit
        
        MCP3ADC_CHAN_0    => 0b00001000,  # single-ended CH0
        MCP3ADC_CHAN_1    => 0b00001001,  # single-ended CH1
        MCP3ADC_CHAN_2    => 0b00001010,  # single-ended CH2
        MCP3ADC_CHAN_3    => 0b00001011,  # single-ended CH3
        MCP3ADC_CHAN_4    => 0b00001100,  # single-ended CH4
        MCP3ADC_CHAN_5    => 0b00001101,  # single-ended CH5
        MCP3ADC_CHAN_6    => 0b00001110,  # single-ended CH6
        MCP3ADC_CHAN_7    => 0b00001111,  # single-ended CH7
        MCP3ADC_DIFF_0_1  => 0b00000000,  # differential +CH0 -CH1
        MCP3ADC_DIFF_1_0  => 0b00000001,  # differential -CH0 +CH1
        MCP3ADC_DIFF_2_3  => 0b00000010,  # differential +CH2 -CH3
        MCP3ADC_DIFF_3_2  => 0b00000011,  # differential -CH2 +CH3
        MCP3ADC_DIFF_4_5  => 0b00000100,  # differential +CH4 -CH5
        MCP3ADC_DIFF_5_4  => 0b00000101,  # differential -CH4 +CH5
        MCP3ADC_DIFF_6_7  => 0b00000110,  # differential +CH6 -CH7
        MCP3ADC_DIFF_7_6  => 0b00000111,  # differential -CH6 +CH7
        
        MCP3008_S0        => 0b00001000,  # single-ended CH0
        MCP3008_S1        => 0b00001001,  # single-ended CH1
        MCP3008_S2        => 0b00001010,  # single-ended CH2
        MCP3008_S3        => 0b00001011,  # single-ended CH3
        MCP3008_S4        => 0b00001100,  # single-ended CH4
        MCP3008_S5        => 0b00001101,  # single-ended CH5
        MCP3008_S6        => 0b00001110,  # single-ended CH6
        MCP3008_S7        => 0b00001111,  # single-ended CH7
        MCP3008_DIFF_0_1  => 0b00000000,  # differential +CH0 -CH1
        MCP3008_DIFF_1_0  => 0b00000001,  # differential -CH0 +CH1
        MCP3008_DIFF_2_3  => 0b00000010,  # differential +CH2 -CH3
        MCP3008_DIFF_3_2  => 0b00000011,  # differential -CH2 +CH3
        MCP3008_DIFF_4_5  => 0b00000100,  # differential +CH4 -CH5
        MCP3008_DIFF_5_4  => 0b00000101,  # differential -CH4 +CH5
        MCP3008_DIFF_6_7  => 0b00000110,  # differential +CH6 -CH7
        MCP3008_DIFF_7_6  => 0b00000110,  # differential -CH6 +CH7
        
        MCP3208_S0        => 0b00001000,  # single-ended CH0
        MCP3208_S1        => 0b00001001,  # single-ended CH1
        MCP3208_S2        => 0b00001010,  # single-ended CH2
        MCP3208_S3        => 0b00001011,  # single-ended CH3
        MCP3208_S4        => 0b00001100,  # single-ended CH4
        MCP3208_S5        => 0b00001101,  # single-ended CH5
        MCP3208_S6        => 0b00001110,  # single-ended CH6
        MCP3208_S7        => 0b00001111,  # single-ended CH7
        MCP3208_DIFF_0_1  => 0b00000000,  # differential +CH0 -CH1
        MCP3208_DIFF_1_0  => 0b00000001,  # differential -CH0 +CH1
        MCP3208_DIFF_2_3  => 0b00000010,  # differential +CH2 -CH3
        MCP3208_DIFF_3_2  => 0b00000011,  # differential -CH2 +CH3
        MCP3208_DIFF_4_5  => 0b00000100,  # differential +CH4 -CH5
        MCP3208_DIFF_5_4  => 0b00000101,  # differential -CH4 +CH5
        MCP3208_DIFF_6_7  => 0b00000110,  # differential +CH6 -CH7
        MCP3208_DIFF_7_6  => 0b00000110,  # differential -CH6 +CH7
        
        MCP3004_S0        => 0b00001000,  # single-ended CH0
        MCP3004_S1        => 0b00001001,  # single-ended CH1
        MCP3004_S2        => 0b00001010,  # single-ended CH2
        MCP3004_S3        => 0b00001011,  # single-ended CH3
        MCP3004_DIFF_0_1  => 0b00000000,  # differential +CH0 -CH1
        MCP3004_DIFF_1_0  => 0b00000001,  # differential -CH0 +CH1
        MCP3004_DIFF_2_3  => 0b00000010,  # differential +CH2 -CH3
        MCP3004_DIFF_3_2  => 0b00000011,  # differential -CH2 +CH3
        
        MCP3204_S0        => 0b00001000,  # single-ended CH0
        MCP3204_S1        => 0b00001001,  # single-ended CH1
        MCP3204_S2        => 0b00001010,  # single-ended CH2
        MCP3204_S3        => 0b00001011,  # single-ended CH3
        MCP3204_DIFF_0_1  => 0b00000000,  # differential +CH0 -CH1
        MCP3204_DIFF_1_0  => 0b00000001,  # differential -CH0 +CH1
        MCP3204_DIFF_2_3  => 0b00000010,  # differential +CH2 -CH3
        MCP3204_DIFF_3_2  => 0b00000011,  # differential -CH2 +CH3
        
    },
    
    mcp4dac => {
        MCP_DAC_RESOLUTION_08 => $MCP_DAC_RESOLUTION_08,
        MCP_DAC_RESOLUTION_10 => $MCP_DAC_RESOLUTION_10,
        MCP_DAC_RESOLUTION_12 => $MCP_DAC_RESOLUTION_12,
        MCP_DAC_CAN_BUFFER    => $MCP_DAC_CAN_BUFFER,
        MCP_DAC_DUAL_CHANNEL  => $MCP_DAC_DUAL_CHANNEL,
    
        MCP_DAC_CHANNEL_A => 0x00,
        MCP_DAC_CHANNEL_B => 0x8000,
        MCP_DAC_BUFFER    => 0x4000,
        MCP_DAC_GAIN      => 0x00,
        MCP_DAC_NO_GAIN   => 0x2000,
        MCP_DAC_LIVE      => 0x1000,
        MCP_DAC_SHUTDOWN  => 0x00,
        
        MCP4801 =>  0x100|$MCP_DAC_RESOLUTION_08,
        MCP4811 =>  0x200|$MCP_DAC_RESOLUTION_10,
        MCP4821 =>  0x300|$MCP_DAC_RESOLUTION_12,
        MCP4802 =>  0x400|$MCP_DAC_RESOLUTION_08|$MCP_DAC_DUAL_CHANNEL,
        MCP4812 =>  0x500|$MCP_DAC_RESOLUTION_10|$MCP_DAC_DUAL_CHANNEL,
        MCP4822 =>  0x600|$MCP_DAC_RESOLUTION_12|$MCP_DAC_DUAL_CHANNEL,
        MCP4901 =>  0x700|$MCP_DAC_RESOLUTION_08|$MCP_DAC_CAN_BUFFER,
        MCP4911 =>  0x800|$MCP_DAC_RESOLUTION_10|$MCP_DAC_CAN_BUFFER,
        MCP4921 =>  0x900|$MCP_DAC_RESOLUTION_12|$MCP_DAC_CAN_BUFFER,
        MCP4902 =>  0xA00|$MCP_DAC_RESOLUTION_08|$MCP_DAC_DUAL_CHANNEL|$MCP_DAC_CAN_BUFFER,
        MCP4912 =>  0xB00|$MCP_DAC_RESOLUTION_10|$MCP_DAC_DUAL_CHANNEL|$MCP_DAC_CAN_BUFFER,
        MCP4922 =>  0xC00|$MCP_DAC_RESOLUTION_12|$MCP_DAC_DUAL_CHANNEL|$MCP_DAC_CAN_BUFFER,
    },
    
    openthings => {
        
        OPENTHINGS_MANUFACTURER_ENERGENIE   => 0x04,
        OPENTHINGS_MANUFACTURER_SENTEC      => 0x01,
        OPENTHINGS_MANUFACTURER_HILDERBRAND => 0x02,
        OPENTHINGS_MANUFACTURER_RASPBERRY   => 0x3F,
        
        OPENTHINGS_PARAM_ALARM           => 0x21,
        OPENTHINGS_PARAM_DEBUG_OUTPUT    => 0x2D,
        OPENTHINGS_PARAM_IDENTIFY        => 0x3F,
        OPENTHINGS_PARAM_SOURCE_SELECTOR => 0x40,
        OPENTHINGS_PARAM_WATER_DETECTOR  => 0x41,
        OPENTHINGS_PARAM_GLASS_BREAKAGE  => 0x42,
        OPENTHINGS_PARAM_CLOSURES        => 0x43,
        OPENTHINGS_PARAM_DOOR_BELL       => 0x44,
        OPENTHINGS_PARAM_ENERGY          => 0x45,
        OPENTHINGS_PARAM_FALL_SENSOR     => 0x46,
        OPENTHINGS_PARAM_GAS_VOLUME      => 0x47,
        OPENTHINGS_PARAM_AIR_PRESSURE    => 0x48,
        OPENTHINGS_PARAM_ILLUMINANCE     => 0x49,
        OPENTHINGS_PARAM_LEVEL           => 0x4C,
        OPENTHINGS_PARAM_RAINFALL        => 0x4D,
        OPENTHINGS_PARAM_APPARENT_POWER  => 0x50,
        OPENTHINGS_PARAM_POWER_FACTOR    => 0x51,
        OPENTHINGS_PARAM_REPORT_PERIOD   => 0x52,
        OPENTHINGS_PARAM_SMOKE_DETECTOR  => 0x53,
        OPENTHINGS_PARAM_TIME_AND_DATE   => 0x54,
        OPENTHINGS_PARAM_VIBRATION       => 0x56,
        OPENTHINGS_PARAM_WATER_VOLUME    => 0x57,
        OPENTHINGS_PARAM_WIND_SPEED      => 0x58,
        OPENTHINGS_PARAM_GAS_PRESSURE    => 0x61,
        OPENTHINGS_PARAM_BATTERY_LEVEL   => 0x62,
        OPENTHINGS_PARAM_CO_DETECTOR     => 0x63,
        OPENTHINGS_PARAM_DOOR_SENSOR     => 0x64,
        OPENTHINGS_PARAM_EMERGENCY       => 0x65,
        OPENTHINGS_PARAM_FREQUENCY       => 0x66,
        OPENTHINGS_PARAM_GAS_FLOW_RATE   => 0x67,
        OPENTHINGS_PARAM_RELATIVE_HUMIDITY =>0x68,
        OPENTHINGS_PARAM_CURRENT         => 0x69,
        OPENTHINGS_PARAM_JOIN            => 0x6A,
        OPENTHINGS_PARAM_LIGHT_LEVEL     => 0x6C,
        OPENTHINGS_PARAM_MOTION_DETECTOR => 0x6D,
        OPENTHINGS_PARAM_OCCUPANCY       => 0x6F,
        OPENTHINGS_PARAM_REAL_POWER      => 0x70,
        OPENTHINGS_PARAM_REACTIVE_POWER  => 0x71,
        OPENTHINGS_PARAM_ROTATION_SPEED  => 0x72,
        OPENTHINGS_PARAM_SWITCH_STATE    => 0x73,
        OPENTHINGS_PARAM_TEMPERATURE     => 0x74,
        OPENTHINGS_PARAM_VOLTAGE         => 0x76,
        OPENTHINGS_PARAM_WATER_FLOW_RATE => 0x77,
        OPENTHINGS_PARAM_WATER_PRESSURE  => 0x78,
        OPENTHINGS_PARAM_PHASE_1_POWER   => 0x79,
        OPENTHINGS_PARAM_PHASE_2_POWER   => 0x7A,
        OPENTHINGS_PARAM_PHASE_3_POWER   => 0x7B,
        OPENTHINGS_PARAM_3_PHASE_TOTAL   => 0x7C,
        
        # from Energenie examples
        OPENTHINGS_PARAM_TEST            => 0xAA,
        OPENTHINGS_WRITE_MASK            => 0x80,
        
        OPENTHINGS_UINT        => 0x00,
        OPENTHINGS_UINT_BP4    => 0x10,
        OPENTHINGS_UINT_BP8    => 0x20,
        OPENTHINGS_UINT_BP12   => 0x30,
        OPENTHINGS_UINT_BP16   => 0x40,
        OPENTHINGS_UINT_BP20   => 0x50,
        OPENTHINGS_UINT_BP24   => 0x60,
        OPENTHINGS_CHAR        => 0x70,
        OPENTHINGS_SINT        => 0x80,
        OPENTHINGS_SINT_BP8    => 0x90,
        OPENTHINGS_SINT_BP16   => 0xA0,
        OPENTHINGS_SINT_BP24   => 0xB0,
        OPENTHINGS_ENUMERATION => 0xC0,
        # D0,E0 RESERVED
        OPENTHINGS_FLOAT       => 0xF0,
    },
    
    energenie => {
        ENERGENIE_ENER314_DUMMY_GROUP => 0xFFFFFF,
        
        ENERGENIE_MANUFACTURER_ID    => 0x04,
    
        ENERGENIE_PRODUCT_ID_MIHO004 => 0x01,
        ENERGENIE_PRODUCT_ID_MIHO005 => 0x02,
        ENERGENIE_PRODUCT_ID_MIHO013 => 0x03,
        ENERGENIE_PRODUCT_ID_MIHO006 => 0x05,
        
        ENERGENIE_PRODUCT_ID_MIHO032 => 0x0C,
        ENERGENIE_PRODUCT_ID_MIHO033 => 0x0D,
        
        ENERGENIE_DEFAULT_CRYPTSEED  => 242,
        ENERGENIE_DEFAULT_CRYPTPIP   => 0x0100,
        
        ENERGENIE_FIFOTHRESH_FSK    => 0x81, # Condition to start packet transmission: at least one byte in FIFO
        ENERGENIE_FIFOTHRESH_OOK    => 0x1E, # Condition to start packet transmission: wait for 30 bytes in FIFO
        ENERGENIE_TXOOK_REPEAT_RATE => 25,
        ENERGENIE_MESSAGE_BUF_SIZE  => 66,
        ENERGENIE_MAX_FIFO_SIZE     => 66,
        ENERGENIE_NODEADDRESS01	 => 0x01,  # Node address used in address filtering
        ENERGENIE_NODEADDRESS04	 => 0x04,  # Node address used in address filtering
        ENERGENIE_FDEVMSB_FSK	     => 0x01,  # frequency deviation 5kHz => 0x0052 -> 30kHz => 0x01EC
        ENERGENIE_FDEVLSB_FSK		 => 0xEC,  # frequency deviation 5kHz => 0x0052 -> 30kHz => 0x01EC
        ENERGENIE_FDEVMSB_OOK	     => 0,
        ENERGENIE_FDEVLSB_OOK		 => 0,
        ENERGENIE_FRMSB_434		 => 0x6C,  # carrier freq -> 434.3MHz => 0x6C9333
        ENERGENIE_FRMID_434		 => 0x93,  # carrier freq -> 434.3MHz => 0x6C9333
        ENERGENIE_FRLSB_434		 => 0x33,  # carrier freq -> 434.3MHz => 0x6C9333
        ENERGENIE_FRMSB_433		 => 0x6C,  # carrier freq -> 433.92MHz => 0x6C7AE1
        ENERGENIE_FRMID_433		 => 0x7A,  # carrier freq -> 433.92MHz => 0x6C7AE1
        ENERGENIE_FRLSB_433		 => 0xE1,  # carrier freq -> 433.92MHz => 0x6C7AE1
        ENERGENIE_SYNCVALUE1_FSK	 => 0x2D,  # 1st byte of Sync word
        ENERGENIE_SYNCVALUE2_FSK	 => 0xD4,  # 2nd byte of Sync word
        ENERGENIE_SYNCVALUE1_OOK	 => 0x80,  # 1nd byte of Sync word
        
        ENERGENIE_SYNC_SIZE_2		=> 0x88,  # Size of the Synch word = 2 (SyncSize + 1)
        ENERGENIE_SYNC_SIZE_4		=> 0x98,  # Size of the Synch word = 4 (SyncSize + 1)
        
        ENERGENIE_PACKETCONFIG1_FSK	      => 0xA2,  # Variable length, Manchester coding, Addr must match NodeAddress
        ENERGENIE_PACKETCONFIG1_FSK_NOADDR   => 0xA0,  # Variable length, Manchester coding
        ENERGENIE_PACKETCONFIG1_OOK	      => 0,  # Fixed length, no Manchester coding
        ENERGENIE_NODEADDRESS                => 0x06, # Node address used in address filtering ( when enabled )
        
        ENERGENIE_PAYLOADLEN_OOK	=> 13 + 8 * 17,  # fixed OOK Payload Length
    },
    
    si470n => {
        SI4701 => 1,
        SI4702 => 2,
        SI4703 => 3,
    },
    
    pca9685 => {
        PCA_9685_SERVOTYPE_DEFAULT  => 1,
        PCA_9685_SERVOTYPE_EXT_1    => 2,
        PCA_9685_SERVOTYPE_EXT_2    => 3,
        PCA_9685_SERVOTYPE_SG90     => 4,
        
        PCA_9685_SERVO_CHANNEL_MASK => 0x0FFF,
        PCA_9685_FULL_MASK  => 0x1000,
        
        PCA_9685_SERVO_DIRECTION_CW => 1,
        PCA_9685_SERVO_DIRECTION_AC => 2,
    },
    
    oled => {                 #  ic     cols   rows   intf
        SSD1306_128_X_64_I2C  => 0x001 + 0x04 + 0x08 + 0x20,
        SSD1306_128_X_32_I2C  => 0x001 + 0x04 + 0x10 + 0x20,
        
        SH1106_128_X_64_I2C   => 0x002 + 0x04 + 0x08 + 0x20,
        SH1106_128_X_32_I2C   => 0x002 + 0x04 + 0x10 + 0x20,
        
        SSD1306_128_X_64_SPI  => 0x001 + 0x04 + 0x08 + 0x40,
        SSD1306_128_X_32_SPI  => 0x001 + 0x04 + 0x10 + 0x40,
        
        SH1106_128_X_64_SPI   => 0x002 + 0x04 + 0x08 + 0x40,
        SH1106_128_X_32_SPI   => 0x002 + 0x04 + 0x10 + 0x40,
        
        SSD1322_128_X_64_SPI  => 0x100 + 0x04 + 0x08 + 0x40,
        SSD1322_256_X_64_SPI  => 0x100 + 0x80 + 0x08 + 0x40,
        
    },
    
    ms5611 => {
        MS5611_OSR_256  => 0x00, # // ADC OSR=256
        MS5611_OSR_512  => 0x02, # // ADC OSR=512
        MS5611_OSR_1024 => 0x04, # // ADC OSR=1024
        MS5611_OSR_2048 => 0x06, # // ADC OSR=2048
        MS5611_OSR_4096 => 0x08, #  // ADC OSR=4096  
    },
    
    tmp102 => {
        TMP102_CR_0_25HZ => 0,
        TMP102_CR_1HZ    => 1,
        TMP102_CR_4HZ    => 2,
        TMP102_CR_8HZ    => 3,
        
        TMP102_FAULTS_1   => 0,
        TMP102_FAULTS_2   => 1,
        TMP102_FAULTS_4   => 2,
        TMP102_FAULTS_6   => 3,
    },
    
    epaper => {
        EPD_WS_1_54_200_X_200_A => 0x01,
        EPD_WS_1_54_200_X_200_B => 0x02,
        EPD_WS_1_54_152_X_152_C => 0x03,
        EPD_WS_2_13_250_X_122_A => 0x04,
        EPD_WS_2_13_212_X_104_B => 0x05,
        EPD_WS_2_90_296_X_128_A => 0x06,
        EPD_WS_2_90_296_X_128_B => 0x07,
        
        EPD_PIMORONI_INKY_PHAT_V2 => 0x80,
        
        EPD_ROTATION_0     => 0,
        EPD_ROTATION_90    => 90,
        EPD_ROTATION_180   => 180,
        EPD_ROTATION_270   => 270,
        
        EPD_FRAME_BPP_1       => 0x01,
        EPD_FRAME_BPP_2       => 0x02,
        EPD_FRAME_TYPE_BLACK  => 0x01,
        EPD_FRAME_TYPE_COLOUR => 0x02,
        EPD_FRAME_TYPE_COLOR  => 0x02,
        EPD_FRAME_TYPE_WHITE  => 0x03,
        EPD_FRAME_TYPE_UNUSED => 0x04,
        
        EPD_BLACK_PEN         => 0x01,
        EPD_COLOUR_PEN        => 0x02,
        EPD_COLOR_PEN         => 0x02,
        EPD_RED_PEN           => 0x02,
        EPD_YELLOW_PEN        => 0x02,
        
        EPD_UPD_MODE_FIXED    => 0x01,
        EPD_UPD_MODE_FULL     => 0x02,
        EPD_UPD_MODE_PARTIAL  => 0x03,
        
        EPD_BORDER_FLOAT      => 0x00,
        EPD_BORDER_WHITE      => 0x01,
        EPD_BORDER_BLACK      => 0x02,
        EPD_BORDER_COLOUR     => 0x03,
        EPD_BORDER_COLOR      => 0x03,
        EPD_BORDER_RED        => 0x03,
        EPD_BORDER_YELLOW     => 0x03,
        
        EPD_BORDER_POR        => 0xFF,
    },
    
    fl3730 => {
        # CONFIGURATION REG 0x00
        FL3730_SSD_NORMAL     => 0b00000000,
        FL3730_SSD_SHUTDOWN   => 0b10000000,
        
        FL3730_DM_MATRIX_1    =>    0b00000,
        FL3730_DM_MATRIX_2    =>    0b01000,
        FL3730_DM_MATRIX_BOTH =>    0b11000,
        
        FL3730_AEN_OFF        =>      0b000,
        FL3730_AEN_ON         =>      0b100,
        
        FL3730_ADM_8X8        =>       0b00,
        FL3730_ADM_7X9        =>       0b01,
        FL3730_ADM_6X10       =>       0b10,
        FL3730_ADM_5X11       =>       0b11,
        
        # LIGHTING EFFECT REG 0x0D
        FL3730_AGS_0_DB       =>  0b0000000,
        FL3730_AGS_3_DB       =>  0b0010000,
        FL3730_AGS_6_DB       =>  0b0100000,
        FL3730_AGS_9_DB       =>  0b0110000,
        FL3730_AGS_12_DB      =>  0b1000000,
        FL3730_AGS_15_DB      =>  0b1010000,
        FL3730_AGS_18_DB      =>  0b1100000,
        FL3730_AGS_M6_DB      =>  0b1110000,
        
        FL3730_CS_05_MA       =>     0b1000,
        FL3730_CS_10_MA       =>     0b1001,
        FL3730_CS_15_MA       =>     0b1010,
        FL3730_CS_20_MA       =>     0b1011,
        FL3730_CS_25_MA       =>     0b1100,
        FL3730_CS_30_MA       =>     0b1101,
        FL3730_CS_35_MA       =>     0b1110,
        FL3730_CS_40_MA       =>     0b0000,
        FL3730_CS_45_MA       =>     0b0001,
        FL3730_CS_50_MA       =>     0b0010,
        FL3730_CS_55_MA       =>     0b0011,
        FL3730_CS_60_MA       =>     0b0100,
        FL3730_CS_65_MA       =>     0b0101,
        FL3730_CS_70_MA       =>     0b0110,
        FL3730_CS_75_MA       =>     0b0111,       
    },
    
    max7219 => {
        MAX7219_FLAG_FLIPPED  => 0x01,
        MAX7219_FLAG_MIRROR   => 0x02,
        MAX7219_FLAG_DECIMAL  => 0x04,
        
        MAX7219_REG_NOOP        => 0x00,
        MAX7219_REG_DIGIT_0     => 0x01,
        MAX7219_REG_DIGIT_1     => 0x02,
        MAX7219_REG_DIGIT_2     => 0x03,
        MAX7219_REG_DIGIT_3     => 0x04,
        MAX7219_REG_DIGIT_4     => 0x05,
        MAX7219_REG_DIGIT_5     => 0x06,
        MAX7219_REG_DIGIT_6     => 0x07,
        MAX7219_REG_DIGIT_7     => 0x08,
        MAX7219_REG_DECODE_MODE => 0x09,
        MAX7219_REG_INTENSITY   => 0x0A,
        MAX7219_REG_SCAN_LIMIT  => 0x0B,
        MAX7219_REG_SHUTDOWN    => 0x0C,
        MAX7219_REG_TEST        => 0x0F,
    },
    
    hilink => {
        HILINK_CONNSTATUS_CONNECTING     => 900,
        HILINK_CONNSTATUS_CONNECTED      => 901,
        HILINK_CONNSTATUS_DISCONNECTED   => 902,
        HILINK_CONNSTATUS_DISCONNECTING  => 903,
    },
    
    mfrc522 => {
        ## MIFARE STATUS CODES
        MFRC522_STATUS_OK                => 1,	#// Success
		MFRC522_STATUS_ERROR             => 2,	#// Error in communication
		MFRC522_STATUS_COLLISION         => 3,	#// Collission detected
		MFRC522_STATUS_TIMEOUT           => 4,	#// Timeout in communication.
		MFRC522_STATUS_NO_ROOM           => 5,	#// A buffer is not big enough.
		MFRC522_STATUS_INTERNAL_ERROR    => 6,	#// Internal error in the code. Should not happen ;-)
		MFRC522_STATUS_INVALID           => 7,	#// Invalid argument.
		MFRC522_STATUS_CRC_WRONG         => 8,	#// The CRC_A does not match
        
        MFRC522_STATUS_UNSUPPORTED_TYPE  => 9,
        MFRC522_STATUS_BLOCK_NOT_ALLOWED => 10,
        MFRC522_STATUS_BAD_PARAM         => 11,
        
		MFRC522_STATUS_MIFARE_NACK       => 0xff, #// A MIFARE PICC responded with NAK.
        
        ## MF522 MFRC522 error codes.
        MFRC522_ERROR_OK         => 0,         # Everything A-OK.
        MFRC522_ERROR_NOTAGERR   => 1,         # No tag error
        MFRC522_ERROR_ERR        => 2,         # General error

        # MF522 Command word
        MFRC522_IDLE          => 0x00,      # NO action; Cancel the current command
        MFRC522_MEM           => 0x01,      # Store 25 byte into the internal buffer.
        MFRC522_GENID         => 0x02,      # Generates a 10 byte random ID number.
        MFRC522_CALCCRC       => 0x03,      # CRC Calculate or selftest.
        MFRC522_TRANSMIT      => 0x04,      # Transmit data
        MFRC522_NOCMDCH       => 0x07,      # No command change.
        MFRC522_RECEIVE       => 0x08,      # Receive Data
        MFRC522_TRANSCEIVE    => 0x0C,      # Transmit and receive data,
        MFRC522_AUTHENT       => 0x0E,      # Authentication Key
        MFRC522_SOFTRESET     => 0x0F,      # Reset

        # Mifare_One tag command word
        MIFARE_REQIDL            => 0x26,      # find the antenna area does not enter hibernation
        MIFARE_REQALL            => 0x52,      # find all the tags antenna area
        MIFARE_ANTICOLL          => 0x88,      # anti-collision
        MIFARE_CASCADE           => 0x88,      # cascade tag
        MIFARE_SELECTTAG         => 0x93,      # selection tag
        MIFARE_SELECT_CL1        => 0x93,
        MIFARE_SELECT_CL2        => 0x95,
        MIFARE_SELECT_CL3        => 0x97,
        MIFARE_AUTHENT1A         => 0x60,      # authentication key A
        MIFARE_AUTHENT1B         => 0x61,      # authentication key B
        MIFARE_READ              => 0x30,      # Read Block
        MIFARE_WRITE             => 0xA0,      # write block
        MIFARE_DECREMENT         => 0xC0,      # debit
        MIFARE_INCREMENT         => 0xC1,      # recharge
        MIFARE_RESTORE           => 0xC2,      # transfer block data to the buffer
        MIFARE_TRANSFER          => 0xB0,      # save the data in the buffer
        MIFARE_HALT              => 0x50,      # Sleep


        #------------------ MFRC522 registers---------------
        #Page 0:Command and Status
        MFRC522_REG_Reserved00            => 0x00,
        MFRC522_REG_CommandReg            => 0x01,
        MFRC522_REG_CommIEnReg            => 0x02,
        MFRC522_REG_DivIEnReg             => 0x03,
        MFRC522_REG_CommIrqReg            => 0x04,
        MFRC522_REG_DivIrqReg             => 0x05,
        MFRC522_REG_ErrorReg              => 0x06,
        MFRC522_REG_Status1Reg            => 0x07,
        MFRC522_REG_Status2Reg            => 0x08,
        MFRC522_REG_FIFODataReg           => 0x09,
        MFRC522_REG_FIFOLevelReg          => 0x0A,
        MFRC522_REG_WaterLevelReg         => 0x0B,
        MFRC522_REG_ControlReg            => 0x0C,
        MFRC522_REG_BitFramingReg         => 0x0D,
        MFRC522_REG_CollReg               => 0x0E,
        MFRC522_REG_Reserved01            => 0x0F,
        #Page 1:Command
        MFRC522_REG_Reserved10            => 0x10,
        MFRC522_REG_ModeReg               => 0x11,
        MFRC522_REG_TxModeReg             => 0x12,
        MFRC522_REG_RxModeReg             => 0x13,
        MFRC522_REG_TxControlReg          => 0x14,
        MFRC522_REG_TxAutoReg             => 0x15,
        MFRC522_REG_TxSelReg              => 0x16,
        MFRC522_REG_RxSelReg              => 0x17,
        MFRC522_REG_RxThresholdReg        => 0x18,
        MFRC522_REG_DemodReg              => 0x19,
        MFRC522_REG_Reserved11            => 0x1A,
        MFRC522_REG_Reserved12            => 0x1B,
        MFRC522_REG_MifareReg             => 0x1C,
        MFRC522_REG_Reserved13            => 0x1D,
        MFRC522_REG_Reserved14            => 0x1E,
        MFRC522_REG_SerialSpeedReg        => 0x1F,
        #Page 2:CFG
        MFRC522_REG_Reserved20            => 0x20,
        MFRC522_REG_CRCResultRegM         => 0x21,
        MFRC522_REG_CRCResultRegH         => 0x21,
        MFRC522_REG_CRCResultRegL         => 0x22,
        MFRC522_REG_Reserved21            => 0x23,
        MFRC522_REG_ModWidthReg           => 0x24,
        MFRC522_REG_Reserved22            => 0x25,
        MFRC522_REG_RFCfgReg              => 0x26,
        MFRC522_REG_GsNReg                => 0x27,
        MFRC522_REG_CWGsPReg              => 0x28,
        MFRC522_REG_ModGsPReg             => 0x29,
        MFRC522_REG_TModeReg              => 0x2A,
        MFRC522_REG_TPrescalerReg         => 0x2B,
        MFRC522_REG_TReloadRegH           => 0x2C,
        MFRC522_REG_TReloadRegL           => 0x2D,
        MFRC522_REG_TCounterValueRegH     => 0x2E,
        MFRC522_REG_TCounterValueRegL     => 0x2F,
        #Page 3:TestRegister
        MFRC522_REG_Reserved30            => 0x30,
        MFRC522_REG_TestSel1Reg           => 0x31,
        MFRC522_REG_TestSel2Reg           => 0x32,
        MFRC522_REG_TestPinEnReg          => 0x33,
        MFRC522_REG_TestPinValueReg       => 0x34,
        MFRC522_REG_TestBusReg            => 0x35,
        MFRC522_REG_AutoTestReg           => 0x36,
        MFRC522_REG_VersionReg            => 0x37,
        MFRC522_REG_AnalogTestReg         => 0x38,
        MFRC522_REG_TestDAC1Reg           => 0x39,
        MFRC522_REG_TestDAC2Reg           => 0x3A,
        MFRC522_REG_TestADCReg            => 0x3B,
        MFRC522_REG_Reserved31            => 0x3C,
        MFRC522_REG_Reserved32            => 0x3D,
        MFRC522_REG_Reserved33            => 0x3E,
        MFRC522_REG_Reserved34            => 0x3F,
        
        MFRC522_PICC_TYPE_UNKNOWN	        => 0,
		MFRC522_PICC_TYPE_ISO_14443_4	    => 1,	#// PICC compliant with ISO/IEC 14443-4 
		MFRC522_PICC_TYPE_ISO_18092         => 2, 	#// PICC compliant with ISO/IEC 18092 (NFC)
		MFRC522_PICC_TYPE_MIFARE_MINI       => 3,	#// MIFARE Classic protocol, 320 bytes
		MFRC522_PICC_TYPE_MIFARE_1K         => 4,	#// MIFARE Classic protocol, 1KB
		MFRC522_PICC_TYPE_MIFARE_4K         => 5,	#// MIFARE Classic protocol, 4KB
		MFRC522_PICC_TYPE_MIFARE_UL         => 6,	#// MIFARE Ultralight or Ultralight C
		MFRC522_PICC_TYPE_MIFARE_PLUS       => 7,	#// MIFARE Plus
		MFRC522_PICC_TYPE_MIFARE_DESFIRE    => 8,	#// MIFARE DESFire
		MFRC522_PICC_TYPE_TNP3XXX           => 9,	#// Only mentioned in NXP AN 10833 MIFARE Type Identification Procedure
		MFRC522_PICC_TYPE_NOT_COMPLETE      => 0xff,	#// SAK indicates UID is not complete.
        
        MIFARE_MF_ACK					=> 0xA,		#// The MIFARE Classic uses a 4 bit ACK/NAK. Any other value than 0xA is NAK.
		MIFARE_MF_KEY_SIZE				=> 6,		#// A Mifare Crypto1 key is 6 bytes.
        
        MFCR522_RXGAIN_18dB				=> 0x00 << 4,	# // 000b - 18 dB, minimum
		MFCR522_RXGAIN_23dB				=> 0x01 << 4,	# // 001b - 23 dB
		MFCR522_RXGAIN_18dB_2			=> 0x02 << 4,	# // 010b - 18 dB, it seems 010b is a duplicate for 000b
		MFCR522_RXGAIN_23dB_2			=> 0x03 << 4,	# // 011b - 23 dB, it seems 011b is a duplicate for 001b
		MFCR522_RXGAIN_33dB				=> 0x04 << 4,	# // 100b - 33 dB, average, and typical default
		MFCR522_RXGAIN_38dB				=> 0x05 << 4,	# // 101b - 38 dB
		MFCR522_RXGAIN_43dB				=> 0x06 << 4,	# // 110b - 43 dB
		MFCR522_RXGAIN_48dB				=> 0x07 << 4,	# // 111b - 48 dB, maximum
		MFCR522_RXGAIN_MIN				=> 0x00 << 4,	# // 000b - 18 dB, minimum, convenience for MFCR522_RXGAIN_18dB
		MFCR522_RXGAIN_AVG				=> 0x04 << 4,	# // 100b - 33 dB, average, convenience for MFCR522_RXGAIN_33dB
		MFCR522_RXGAIN_MAX				=> 0x07 << 4	# // 111b - 48 dB, maximum, convenience for MFCR522_RXGAIN_48dB
        
    },
    
    bmx280 => {
        BM280_REG_CALIB1            => 0x88,
    
        BM280_REG_ID                => 0xD0,
        BM280_REG_RESET             => 0xE0,
        
        BM280_REG_CALIB2            => 0xE1,  # BME280 only
        
        BM280_REG_CTRL_HUM          => 0xF2,  # BME280 only
        BM280_REG_STATUS            => 0xF3,
        BM280_REG_CTRL_MEAS         => 0xF4,
        BM280_REG_CONFIG            => 0xF5,
        
        BM280_REG_PRESS_MSB         => 0xF7,
        BM280_REG_PRESS_LSB         => 0xF8,
        BM280_REG_PRESS_XLSB        => 0xF9,
        BM280_REG_TEMP_MSB          => 0xFA,
        BM280_REG_TEMP_LSB          => 0xFB,
        BM280_REG_TEMP_XLSB         => 0xFC,
        BM280_REG_HUM_MSB           => 0xFD,  # BME280 only
        BM280_REG_HUM_LSB           => 0xFE,  # BME280 only
        
        BM280_VAL_RESET             => 0xB6,
        
        BM280_VAL_BMP_CALIB1LEN      => 0x18, # 24
        BM280_VAL_BME_CALIB1LEN      => 0x19, # 25
        BM280_VAL_BME_CALIB2LEN      => 0x07, #  7
        
        BM280_TYPE_BME280           => 0x60,
        BM280_TYPE_BMP280           => 0x58,
        
        BM280_COMP_DIG_T1 => 0,
        BM280_COMP_DIG_T2 => 1,
        BM280_COMP_DIG_T3 => 2,
        
        BM280_COMP_DIG_P1 => 3,
        BM280_COMP_DIG_P2 => 4,
        BM280_COMP_DIG_P3 => 5,
        BM280_COMP_DIG_P4 => 6,
        BM280_COMP_DIG_P5 => 7,
        BM280_COMP_DIG_P6 => 8,
        BM280_COMP_DIG_P7 => 9,
        BM280_COMP_DIG_P8 => 10,
        BM280_COMP_DIG_P9 => 11,
        
        BM280_COMP_DIG_H1 => 12,
        BM280_COMP_DIG_H2 => 13,
        BM280_COMP_DIG_H3 => 14,
        BM280_COMP_DIG_H4 => 15,
        BM280_COMP_DIG_H5 => 16,
        BM280_COMP_DIG_H6 => 17,
        
        BM280_MODE_SLEEP  => 0b00,
        BM280_MODE_NORMAL => 0b11,
        BM280_MODE_FORCED => 0b01,
        
        BM280_OSRS_SKIP => 0b000,
        BM280_OSRS_X1   => 0b001,
        BM280_OSRS_X2   => 0b010,
        BM280_OSRS_X4   => 0b011,
        BM280_OSRS_X8   => 0b100,
        BM280_OSRS_X16  => 0b101,
        
        BM280_FILTER_OFF => 0b000,
        BM280_FILTER_2   => 0b001,
        BM280_FILTER_4   => 0b010,
        BM280_FILTER_8   => 0b011,
        BM280_FILTER_16  => 0b100,
        
        BM280_STANDBY_0     => 0b000,
        BM280_BME_STANDBY_10 => 0b110,
        BM280_BME_STANDBY_20 => 0b111,
        BM280_STANDBY_62    => 0b001,
        BM280_STANDBY_125   => 0b010,
        BM280_STANDBY_250   => 0b011,
        BM280_STANDBY_500   => 0b100,
        BM280_STANDBY_1000  => 0b101,
        BM280_BMP_STANDBY_1000 => 0b110,
        BM280_BMP_STANDBY_2000 => 0b111,
        
    },
    
    seesaw => {
        
        SEESAW_ATSAMD09         => 0x01,
        
        SEESAW_STATUS_BASE      => 0x00,
        SEESAW_GPIO_BASE        => 0x01,
        SEESAW_SERCOM0_BASE     => 0x02,
        SEESAW_TIMER_BASE       => 0x08,
        SEESAW_ADC_BASE         => 0x09,
        SEESAW_DAC_BASE         => 0x0A,
        SEESAW_INTERRUPT_BASE   => 0x0B,
        SEESAW_DAP_BASE         => 0x0C,
        SEESAW_EEPROM_BASE      => 0x0D,
        SEESAW_NEOPIXEL_BASE    => 0x0E,
        SEESAW_TOUCH_BASE       => 0x0F,
        
        SEESAW_STATUS_HW_ID     => 0x01,
        SEESAW_STATUS_VERSION   => 0x02,
        SEESAW_STATUS_OPTIONS   => 0x03,
        SEESAW_STATUS_TEMP      => 0x04,
        SEESAW_STATUS_SWRST     => 0x7F,
        
        SEESAW_GPIO_DIRSET_BULK => 0x02,
        SEESAW_GPIO_DIRCLR_BULK => 0x03,
        SEESAW_GPIO_BULK        => 0x04,
        SEESAW_GPIO_BULK_SET    => 0x05,
        SEESAW_GPIO_BULK_CLR    => 0x06,
        SEESAW_GPIO_BULK_TOGGLE => 0x07,
        SEESAW_GPIO_INTENSET    => 0x08,
        SEESAW_GPIO_INTENCLR    => 0x09,
        SEESAW_GPIO_INTFLAG     => 0x0A,
        SEESAW_GPIO_PULLENSET   => 0x0B,
        SEESAW_GPIO_PULLENCLR   => 0x0C,
        
        SEESAW_TIMER_STATUS     => 0x00,
        SEESAW_TIMER_PWM        => 0x01,
        SEESAW_TIMER_FREQ       => 0x02,
        
        SEESAW_ADC_STATUS       => 0x00,
        SEESAW_ADC_INTEN        => 0x02,
        SEESAW_ADC_INTENCLR     => 0x03,
        SEESAW_ADC_WINMODE      => 0x04,
        SEESAW_ADC_WINTHRESH    => 0x05,
        SEESAW_ADC_CHANNEL_OFFSET => 0x07,
        
        SEESAW_SERCOM_STATUS    => 0x00,
        SEESAW_SERCOM_INTEN     => 0x02,
        SEESAW_SERCOM_INTENCLR  => 0x03,
        SEESAW_SERCOM_BAUD      => 0x04,
        SEESAW_SERCOM_DATA      => 0x05,
        
        SEESAW_NEOPIXEL_STATUS  => 0x00,
        SEESAW_NEOPIXEL_PIN     => 0x01,
        SEESAW_NEOPIXEL_SPEED   => 0x02,
        SEESAW_NEOPIXEL_BUF_LENGTH => 0x03,
        SEESAW_NEOPIXEL_BUF     => 0x04,
        SEESAW_NEOPIXEL_SHOW    => 0x05,
        
        SEESAW_NEOPIXEL_KHZ800  => 0x01,
        SEESAW_NEOPIXEL_KHZ400  => 0x00,
        
        SEESAW_NEOPIXEL_RGB     => 0x01,
        SEESAW_NEOPIXEL_GRB     => 0x02,
        SEESAW_NEOPIXEL_RGBW    => 0x03,
        SEESAW_NEOPIXEL_GRBW    => 0x04,

        SEESAW_TOUCH_CHANNEL_OFFSET => 0x10,
        
        SEESAW_HW_ID_CODE       => 0x55,
        SEESAW_EEPROM_I2C_ADDR  => 0x3F,
        
        SEESAW_INPUT            => 0x00,
        SEESAW_OUTPUT           => 0x01,
        SEESAW_INPUT_PULLUP     => 0x02,
        SEESAW_INPUT_PULLDOWN   => 0x03,
        
        # ADC
        SEESAW_PA02             => 2,
        SEESAW_PA03             => 3,
        SEESAW_PA04             => 4,
        
        # PWM
        SEESAW_PA05             => 5,
        SEESAW_PA06             => 6,
        SEESAW_PA07             => 7,

        SEESAW_IRQ              => 8,
        
        #GPIO
        SEESAW_PA09             => 9,
        SEESAW_PA010            => 10,
        SEESAW_PA011            => 11,
        SEESAW_PA014            => 14,
        SEESAW_PA015            => 15,
        SEESAW_PA024            => 24,
        SEESAW_PA025            => 25,
        
    },
};

my $tagaliases = {
    mcp23x17 => [ qw( mcp23017 mcp23S17 ) ],
    rpi      => [ qw( raspberry ) ],
    fl3730   => [ qw( is31fl3730 )],
    bmx280   => [ qw( bmp280 bme280 ) ],
};

sub hipi_export_ok {
    my @names = ();
    for my $tag ( keys %$const ) {
        for my $cname ( keys %{$const->{$tag}} ) {
            push @names, $cname;
        }
    }
    return @names;
}

sub hipi_export_constants {
    my $constants = {};
    for my $tag ( keys %$const ) {
        for my $cname ( keys %{$const->{$tag}} ) {
            $constants->{$cname} = $const->{$tag}->{$cname};
        }
    }
    return $constants;
}

sub hipi_export_tags {
    my %tags = ();
    for my $tag ( keys %$const ) {
        my @names = ();
        for my $cname ( keys %{$const->{$tag}} ) {
            push @names, $cname;
        }
        $tags{$tag} = \@names;
        if(exists($tagaliases->{$tag})) {
            for my $alias ( @{ $tagaliases->{$tag} } ) {
                $tags{$alias} = \@names;
            }
        }
    }
    return %tags;
}

1;

__END__
