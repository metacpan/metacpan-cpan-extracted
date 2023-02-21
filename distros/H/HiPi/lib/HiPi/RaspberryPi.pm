###############################################################################
# Distribution : HiPi Modules for Raspberry Pi
# File         : lib/HiPi/RaspberryPi.pm
# Description  : Information about host Raspberry Pi
# Copyright    : Copyright (c) 2013-2023 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::RaspberryPi;

###############################################################################
use strict;
use warnings;
use Carp;

our $VERSION ='0.88';

my ( $btype1, $btype2, $btype3, $btype4) = ( 1, 2, 3, 4 );

my $israspberry = 0;
my $israspberry2 = 0;
my $israspberry3 = 0;
my $israspberry4 = 0;
my $hasdevicetree = 0;
my $homedir = '/tmp';

my $_min_gpio = 0;
my $_max_gpio = 53;

my @_alt_func_names_2708 =
(
    [ 'SDA0'      , 'SA5'        , 'PCLK'      , 'AVEOUT_VCLK'   , 'AVEIN_VCLK' , '-'         ],
    [ 'SCL0'      , 'SA4'        , 'DE'        , 'AVEOUT_DSYNC'  , 'AVEIN_DSYNC', '-'         ],
    [ 'SDA1'      , 'SA3'        , 'LCD_VSYNC' , 'AVEOUT_VSYNC'  , 'AVEIN_VSYNC', '-'         ],
    [ 'SCL1'      , 'SA2'        , 'LCD_HSYNC' , 'AVEOUT_HSYNC'  , 'AVEIN_HSYNC', '-'         ],
    [ 'GPCLK0'    , 'SA1'        , 'DPI_D0'    , 'AVEOUT_VID0'   , 'AVEIN_VID0' , 'ARM_TDI'   ],
    [ 'GPCLK1'    , 'SA0'        , 'DPI_D1'    , 'AVEOUT_VID1'   , 'AVEIN_VID1' , 'ARM_TDO'   ],
    [ 'GPCLK2'    , 'SOE_N_SE'   , 'DPI_D2'    , 'AVEOUT_VID2'   , 'AVEIN_VID2' , 'ARM_RTCK'  ],
    [ 'SPI0_CE1_N', 'SWE_N_SRW_N', 'DPI_D3'    , 'AVEOUT_VID3'   , 'AVEIN_VID3' , '-'         ],
    [ 'SPI0_CE0_N', 'SD0'        , 'DPI_D4'    , 'AVEOUT_VID4'   , 'AVEIN_VID4' , '-'         ],
    [ 'SPI0_MISO' , 'SD1'        , 'DPI_D5'    , 'AVEOUT_VID5'   , 'AVEIN_VID5' , '-'         ],
    [ 'SPI0_MOSI' , 'SD2'        , 'DPI_D6'    , 'AVEOUT_VID6'   , 'AVEIN_VID6' , '-'         ],
    [ 'SPI0_SCLK' , 'SD3'        , 'DPI_D7'    , 'AVEOUT_VID7'   , 'AVEIN_VID7' , '-'         ],
    [ 'PWM0'      , 'SD4'        , 'DPI_D8'    , 'AVEOUT_VID8'   , 'AVEIN_VID8' , 'ARM_TMS'   ],
    [ 'PWM1'      , 'SD5'        , 'DPI_D9'    , 'AVEOUT_VID9'   , 'AVEIN_VID9' , 'ARM_TCK'   ],
    [ 'TXD0'      , 'SD6'        , 'DPI_D10'   , 'AVEOUT_VID10'  , 'AVEIN_VID10', 'TXD1'      ],
    [ 'RXD0'      , 'SD7'        , 'DPI_D11'   , 'AVEOUT_VID11'  , 'AVEIN_VID11', 'RXD1'      ],
    [ 'FL0'       , 'SD8'        , 'DPI_D12'   , 'CTS0'          , 'SPI1_CE2_N' , 'CTS1'      ],
    [ 'FL1'       , 'SD9'        , 'DPI_D13'   , 'RTS0'          , 'SPI1_CE1_N' , 'RTS1'      ],
    [ 'PCM_CLK'   , 'SD10'       , 'DPI_D14'   , 'I2CSL_SDA_MOSI', 'SPI1_CE0_N' , 'PWM0'      ],
    [ 'PCM_FS'    , 'SD11'       , 'DPI_D15'   , 'I2CSL_SCL_SCLK', 'SPI1_MISO'  , 'PWM1'      ],
    [ 'PCM_DIN'   , 'SD12'       , 'DPI_D16'   , 'I2CSL_MISO'    , 'SPI1_MOSI'  , 'GPCLK0'    ],
    [ 'PCM_DOUT'  , 'SD13'       , 'DPI_D17'   , 'I2CSL_CE_N'    , 'SPI1_SCLK'  , 'GPCLK1'    ],
    [ 'SD0_CLK'   , 'SD14'       , 'DPI_D18'   , 'SD1_CLK'       , 'ARM_TRST'   , '-'         ],
    [ 'SD0_CMD'   , 'SD15'       , 'DPI_D19'   , 'SD1_CMD'       , 'ARM_RTCK'   , '-'         ],
    [ 'SD0_DAT0'  , 'SD16'       , 'DPI_D20'   , 'SD1_DAT0'      , 'ARM_TDO'    , '-'         ],
    [ 'SD0_DAT1'  , 'SD17'       , 'DPI_D21'   , 'SD1_DAT1'      , 'ARM_TCK'    , '-'         ],
    [ 'SD0_DAT2'  , 'TE0'        , 'DPI_D22'   , 'SD1_DAT2'      , 'ARM_TDI'    , '-'         ],
    [ 'SD0_DAT3'  , 'TE1'        , 'DPI_D23'   , 'SD1_DAT3'      , 'ARM_TMS'    , '-'         ],
    [ 'SDA0'      , 'SA5'        , 'PCM_CLK'   , 'FL0'           , '-'          , '-'         ],
    [ 'SCL0'      , 'SA4'        , 'PCM_FS'    , 'FL1'           , '-'          , '-'         ],
    [ 'TE0'       , 'SA3'        , 'PCM_DIN'   , 'CTS0'          , '-'          , 'CTS1'      ],
    [ 'FL0'       , 'SA2'        , 'PCM_DOUT'  , 'RTS0'          , '-'          , 'RTS1'      ],
    [ 'GPCLK0'    , 'SA1'        , 'RING_OCLK' , 'TXD0'          , '-'          , 'TXD1'      ],
    [ 'FL1'       , 'SA0'        , 'TE1'       , 'RXD0'          , '-'          , 'RXD1'      ],
    [ 'GPCLK0'    , 'SOE_N_SE'   , 'TE2'       , 'SD1_CLK'       , '-'          , '-'         ],
    [ 'SPI0_CE1_N', 'SWE_N_SRW_N', '-'         , 'SD1_CMD'       , '-'          , '-'         ],
    [ 'SPI0_CE0_N', 'SD0'        , 'TXD0'      , 'SD1_DAT0'      , '-'          , '-'         ],
    [ 'SPI0_MISO' , 'SD1'        , 'RXD0'      , 'SD1_DAT1'      , '-'          , '-'         ],
    [ 'SPI0_MOSI' , 'SD2'        , 'RTS0'      , 'SD1_DAT2'      , '-'          , '-'         ],
    [ 'SPI0_SCLK' , 'SD3'        , 'CTS0'      , 'SD1_DAT3'      , '-'          , '-'         ],
    [ 'PWM0'      , 'SD4'        , '-'         , 'SD1_DAT4'      , 'SPI2_MISO'  , 'TXD1'      ],
    [ 'PWM1'      , 'SD5'        , 'TE0'       , 'SD1_DAT5'      , 'SPI2_MOSI'  , 'RXD1'      ],
    [ 'GPCLK1'    , 'SD6'        , 'TE1'       , 'SD1_DAT6'      , 'SPI2_SCLK'  , 'RTS1'      ],
    [ 'GPCLK2'    , 'SD7'        , 'TE2'       , 'SD1_DAT7'      , 'SPI2_CE0_N' , 'CTS1'      ],
    [ 'GPCLK1'    , 'SDA0'       , 'SDA1'      , 'TE0'           , 'SPI2_CE1_N' , '-'         ],
    [ 'PWM1'      , 'SCL0'       , 'SCL1'      , 'TE1'           , 'SPI2_CE2_N' , '-'         ],
    [ 'SDA0'      , 'SDA1'       , 'SPI0_CE0_N', '-'             , '-'          , 'SPI2_CE1_N'],
    [ 'SCL0'      , 'SCL1'       , 'SPI0_MISO' , '-'             , '-'          , 'SPI2_CE0_N'],
    [ 'SD0_CLK'   , 'FL0'        , 'SPI0_MOSI' , 'SD1_CLK'       , 'ARM_TRST'   , 'SPI2_SCLK' ],
    [ 'SD0_CMD'   , 'GPCLK0'     , 'SPI0_SCLK' , 'SD1_CMD'       , 'ARM_RTCK'   , 'SPI2_MOSI' ],
    [ 'SD0_DAT0'  , 'GPCLK1'     , 'PCM_CLK'   , 'SD1_DAT0'      , 'ARM_TDO'    , '-'         ],
    [ 'SD0_DAT1'  , 'GPCLK2'     , 'PCM_FS'    , 'SD1_DAT1'      , 'ARM_TCK'    , '-'         ],
    [ 'SD0_DAT2'  , 'PWM0'       , 'PCM_DIN'   , 'SD1_DAT2'      , 'ARM_TDI'    , '-'         ],
    [ 'SD0_DAT3'  , 'PWM1'       , 'PCM_DOUT'  , 'SD1_DAT3'      , 'ARM_TMS'    , '-'         ],
);

my @_alt_func_names_2711 =
(
    # BANK 0
    [ 'SDA0'            , 'SA5'             , 'PCLK'            , 'SPI3_CE0_N'      , 'TXD2'            , 'SDA6'            ], # 0
    [ 'SCL0'            , 'SA4'             , 'DE'              , 'SPI3_MISO'       , 'RXD2'            , 'SCL6'            ], # 1
    [ 'SDA1'            , 'SA3'             , 'LCD_VSYNC'       , 'SPI3_MOSI'       , 'CTS2'            , 'SDA3'            ], # 2
    [ 'SCL1'            , 'SA2'             , 'LCD_HSYNC'       , 'SPI3_SCLK'       , 'RTS2'            , 'SCL3'            ], # 3
    [ 'GPCLK0'          , 'SA1'             , 'DPI_D0'          , 'SPI4_CE0_N'      , 'TXD3'            , 'SDA3'            ], # 4
    [ 'GPCLK1'          , 'SA0'             , 'DPI_D1'          , 'SPI4_MISO'       , 'RXD3'            , 'SCL3'            ], # 5
    [ 'GPCLK2'          , 'SOE_N_SE'        , 'DPI_D2'          , 'SPI4_MOSI'       , 'CTS3'            , 'SDA4'            ], # 6
    [ 'SPI0_CE1_N'      , 'SWE_N_SRW_N'     , 'DPI_D3'          , 'SPI4_SCLK'       , 'RTS3'            , 'SCL4'            ], # 7
    [ 'SPI0_CE0_N'      , 'SD0'             , 'DPI_D4'          , 'I2CSL_CE_N'      , 'TXD4'            , 'SDA4'            ], # 8
    [ 'SPI0_MISO'       , 'SD1'             , 'DPI_D5'          , 'I2CSL_SDI_MISO'  , 'RXD4'            , 'SCL4'            ], # 9
    [ 'SPI0_MOSI'       , 'SD2'             , 'DPI_D6'          , 'I2CSL_SDA_MOSI'  , 'CTS4'            , 'SDA5'            ], # 10
    [ 'SPI0_SCLK'       , 'SD3'             , 'DPI_D7'          , 'I2CSL_SCL_SCLK'  , 'RTS4'            , 'SCL5'            ], # 11
    [ 'PWM0_0'          , 'SD4'             , 'DPI_D8'          , 'SPI5_CE0_N'      , 'TXD5'            , 'SDA5'            ], # 12
    [ 'PWM0_1'          , 'SD5'             , 'DPI_D9'          , 'SPI5_MISO'       , 'RXD5'            , 'SCL5'            ], # 13
    [ 'TXD0'            , 'SD6'             , 'DPI_D10'         , 'SPI5_MOSI'       , 'CTS5'            , 'TXD1'            ], # 14
    [ 'RXD0'            , 'SD7'             , 'DPI_D11'         , 'SPI5_SCLK'       , 'RTS5'            , 'RXD1'            ], # 15
    [ '-'               , 'SD8'             , 'DPI_D12'         , 'CTS0'            , 'SPI1_CE2_N'      , 'CTS1'            ], # 16
    [ '-'               , 'SD9'             , 'DPI_D13'         , 'RTS0'            , 'SPI1_CE1_N'      , 'RTS1'            ], # 17
    [ 'PCM_CLK'         , 'SD10'            , 'DPI_D14'         , 'SPI6_CE0_N'      , 'SPI1_CE0_N'      , 'PWM0_0'          ], # 18
    [ 'PCM_FS'          , 'SD11'            , 'DPI_D15'         , 'SPI6_MISO'       , 'SPI1_MISO'       , 'PWM0_1'          ], # 19
    [ 'PCM_DIN'         , 'SD12'            , 'DPI_D16'         , 'SPI6_MOSI'       , 'SPI1_MOSI'       , 'GPCLK0'          ], # 20
    [ 'PCM_DOUT'        , 'SD13'            , 'DPI_D17'         , 'SPI6_SCLK'       , 'SPI1_SCLK'       , 'GPCLK1'          ], # 21
    [ 'SD0_CLK'         , 'SD14'            , 'DPI_D18'         , 'SD1_CLK'         , 'ARM_TRST'        , 'SDA6'            ], # 22
    [ 'SD0_CMD'         , 'SD15'            , 'DPI_D19'         , 'SD1_CMD'         , 'ARM_RTCK'        , 'SCL6'            ], # 23
    [ 'SD0_DAT0'        , 'SD16'            , 'DPI_D20'         , 'SD1_DAT0'        , 'ARM_TDO'         , 'SPI3_CE1_N'      ], # 24
    [ 'SD0_DAT1'        , 'SD17'            , 'DPI_D21'         , 'SD1_DAT1'        , 'ARM_TCK'         , 'SPI4_CE1_N'      ], # 25
    [ 'SD0_DAT2'        , '-'               , 'DPI_D22'         , 'SD1_DAT2'        , 'ARM_TDI'         , 'SPI5_CE1_N'      ], # 26
    [ 'SD0_DAT3'        , '-'               , 'DPI_D23'         , 'SD1_DAT3'        , 'ARM_TMS'         , 'SPI6_CE1_N'      ], # 27
    
    # BANK 1
    [ 'SDA0'            , 'SA5'             , 'PCM_CLK'         , '-'               , 'MII_A_RX_ERR'    , 'RGMII_MDIO'      ], # 28
    [ 'SCL0'            , 'SA4'             , 'PCM_FS'          , '-'               , 'MII_A_TX_ERR'    , 'RGMII_MDC'       ], # 29
    [ '-'               , 'SA3'             , 'PCM_DIN'         , 'CTS0'            , 'MII_A_CRS'       , 'CTS1'            ], # 30
    [ '-'               , 'SA2'             , 'PCM_DOUT'        , 'RTS0'            , 'MII_A_COL'       , 'RTS1'            ], # 31
    [ 'GPCLK0'          , 'SA1'             , '-'               , 'TXD0'            , 'SD_CARD_PRES'    , 'TXD1'            ], # 32
    [ '-'               , 'SA0'             , '-'               , 'RXD0'            , 'SD_CARD_WRPROT'  , 'RXD1'            ], # 33
    [ 'GPCLK0'          , 'SOE_N_SE'        , '-'               , 'SD1_CLK'         , 'SD_CARD_LED'     , 'RGMII_IRQ'       ], # 34
    [ 'SPI0_CE1_N'      , 'SWE_N_SRW_N'     , '-'               , 'SD1_CMD'         , 'RGMII_START_STOP', '-'               ], # 35
    [ 'SPI0_CE0_N'      , 'SD0'             , 'TXD0'            , 'SD1_DAT0'        , 'RGMII_RX_OK'     , 'MII_A_RX_ERR'    ], # 36
    [ 'SPI0_MISO'       , 'SD1'             , 'RXD0'            , 'SD1_DAT1'        , 'RGMII_MDIO'      , 'MII_A_TX_ERR'    ], # 37
    [ 'SPI0_MOSI'       , 'SD2'             , 'RTS0'            , 'SD1_DAT2'        , 'RGMII_MDC'       , 'MII_A_CRS'       ], # 38
    [ 'SPI0_SCLK'       , 'SD3'             , 'CTS0'            , 'SD1_DAT3'        , 'RGMII_IRQ'       , 'MII_A_COL'       ], # 39
    [ 'PWM1_0'          , 'SD4'             , '-'               , 'SD1_DAT4'        , 'SPI0_MISO'       , 'TXD1'            ], # 40
    [ 'PWM1_1'          , 'SD5'             , '-'               , 'SD1_DAT5'        , 'SPI0_MOSI'       , 'RXD1'            ], # 41
    [ 'GPCLK1'          , 'SD6'             , '-'               , 'SD1_DAT6'        , 'SPI0_SCLK'       , 'RTS1'            ], # 42
    [ 'GPCLK2'          , 'SD7'             , '-'               , 'SD1_DAT7'        , 'SPI0_CE0_N'      , 'CTS1'            ], # 43
    [ 'GPCLK1'          , 'SDA0'            , 'SDA1'            , '-'               , 'SPI0_CE1_N'      , 'SD_CARD_VOLT'    ], # 44
    [ 'PWM0_1'          , 'SCL0'            , 'SCL1'            , '-'               , 'SPI0_CE2_N'      , 'SD_CARD_PWR0'    ], # 45
    
    # BANK 2
    [ 'SDA0'            , 'SDA1'            , 'SPI0_CE0_N'      , '-'               , '-'               , 'SPI2_CE1_N'      ], # 46
    [ 'SCL0'            , 'SCL1'            , 'SPI0_MISO'       , '-'               , '-'               , 'SPI2_CE0_N'      ], # 47
    [ 'SD0_CLK'         , '-'               , 'SPI0_MOSI'       , 'SD1_CLK'         , 'ARM_TRST'        , 'SPI2_SCLK'       ], # 48
    [ 'SD0_CMD'         , 'GPCLK0'          , 'SPI0_SCLK'       , 'SD1_CMD'         , 'ARM_RTCK'        , 'SPI2_MOSI'       ], # 49
    [ 'SD0_DAT0'        , 'GPCLK1'          , 'PCM_CLK'         , 'SD1_DAT0'        , 'ARM_TDO'         , 'SPI2_MISO'       ], # 50
    [ 'SD0_DAT1'        , 'GPCLK2'          , 'PCM_FS'          , 'SD1_DAT1'        , 'ARM_TCK'         , 'SD_CARD_LED'     ], # 51
    [ 'SD0_DAT2'        , 'PWM0_0'          , 'PCM_DIN'         , 'SD1_DAT2'        , 'ARM_TDI'         , '-'               ], # 52
    [ 'SD0_DAT3'        , 'PWM0_1'          , 'PCM_DOUT'        , 'SD1_DAT3'        , 'ARM_TMS'         , '-'               ], # 53
);

my $_alt_function_names;
my $_alt_function_names_version;

my %_revstash = (
    'beta'      => { release => 'Q1 2012', model_name => 'Raspberry Pi Model B Revision beta', revision => 'beta', board_type => $btype1, memory => 256, manufacturer => 'Generic' },
    '0002'      => { release => 'Q1 2012', model_name => 'Raspberry Pi Model B Revision 1.0',  revision => '0002', board_type => $btype1, memory => 256, manufacturer => 'Generic' },
    '0003'      => { release => 'Q3 2012', model_name => 'Raspberry Pi Model B Revision 1.0',  revision => '0003', board_type => $btype1, memory => 256, manufacturer => 'Generic' },
    '0004'      => { release => 'Q3 2012', model_name => 'Raspberry Pi Model B Revision 2.0',  revision => '0004', board_type => $btype2, memory => 256, manufacturer => 'Sony' },
    '0005'      => { release => 'Q4 2012', model_name => 'Raspberry Pi Model B Revision 2.0',  revision => '0005', board_type => $btype2, memory => 256, manufacturer => 'Qisda' },
    '0006'      => { release => 'Q4 2012', model_name => 'Raspberry Pi Model B Revision 2.0',  revision => '0006', board_type => $btype2, memory => 256, manufacturer => 'Egoman' },
    '0007'      => { release => 'Q1 2013', model_name => 'Raspberry Pi Model A', revision => '0007', board_type => $btype2, memory => 256, manufacturer => 'Egoman' },
    '0008'      => { release => 'Q1 2013', model_name => 'Raspberry Pi Model A', revision => '0008', board_type => $btype2, memory => 256, manufacturer => 'Sony' },
    '0009'      => { release => 'Q1 2013', model_name => 'Raspberry Pi Model A', revision => '0009', board_type => $btype2, memory => 256, manufacturer => 'Qisda' },
    
    '000d'      => { release => 'Q4 2012', model_name => 'Raspberry Pi Model B Revision 2.0', revision => '000d', board_type => $btype2, memory => 512, manufacturer => 'Egoman' },
    '000e'      => { release => 'Q4 2012', model_name => 'Raspberry Pi Model B Revision 2.0', revision => '000e', board_type => $btype2, memory => 512, manufacturer => 'Sony' },
    '000f'      => { release => 'Q4 2012', model_name => 'Raspberry Pi Model B Revision 2.0', revision => '000f', board_type => $btype2, memory => 512, manufacturer => 'Qisda' },
    
    '0010'      => { release => 'Q3 2014', model_name => 'Raspberry Pi Model B +', revision => '0010', board_type => $btype3, memory => 512, manufacturer => 'Sony' },
    '0011'      => { release => 'Q2 2013', model_name => 'Compute Module', revision => '0011', board_type => $btype2, memory => 512, manufacturer => 'Sony' },
    '0012'      => { release => 'Q4 2014', model_name => 'Raspberry Pi Model A +', revision => '0012', board_type => $btype3, memory => 256, manufacturer => 'Sony' },
    
    '0014'      => { release => 'Q2 2015', model_name => 'Compute Module', revision => '0014', board_type => $btype2, memory => 512, manufacturer => 'Sony' },
    '0015'      => { release => 'Q4 2015', model_name => 'Raspberry Pi Model A +', revision => '0015', board_type => $btype3, memory => 512, manufacturer => 'Sony' },
    'unknown'   => { release => 'Q1 2012', model_name => 'Virtual or Unknown Raspberry Pi', revision => 'UNKNOWN', board_type => $btype2, memory => 512,  manufacturer => 'HiPi Virtual' },
    'unknownex' => { release => 'Q1 2012', model_name => 'Virtual or Unknown Raspberry Pi', revision => 'UNKNOWN', board_type => $btype3, memory => 1024, manufacturer => 'HiPi Virtual' },
);

# MAP 24 bits of Revision  NEW:1, MEMSIZE:3, MANUFACTURER:4, PROCESSOR:4, MODEL:8, BOARD REVISION:4

my %_revinfostash = (
    memsize => {
        '0' => 256,
        '1' => 512,
        '2' => 1024,
        '3' => 2048,
        '4' => 4096,
        '5' => 8192,
    },
    manufacturer => {
        '0' => 'Sony UK',
        '1' => 'Egoman',
        '2' => 'Embest',
        '3' => 'Sony Japan',
        '4' => 'Embest',
        '5' => 'Stadium',
    },
    processor => {
        '0' => 'BCM2835',
        '1' => 'BCM2836',
        '2' => 'BCM2837',
        '3' => 'BCM2711',
    },
    processor_info => {
        'BCM2835' => {
            arm                 => 'ARM1176',
            cores               => 1,
            architecture_width  => 32,
            raspios_supported   => [ 'armhf' ],
        },
        'BCM2836' => {
            arm                 => 'Cortex-A7',
            cores               => 4,
            architecture_width  => 32,
            raspios_supported   => [ 'armhf' ],
        },
        'BCM2837' => {
            arm                 => 'Cortex-A53',
            cores               => 4,
            architecture_width  => 64,
            raspios_supported   => [ 'armhf', 'arm64' ],
        },
        'BCM2711' => {
            arm                 => 'Cortex-A72',
            cores               => 4,
            architecture_width  => 64,
            raspios_supported   => [ 'armhf', 'arm64' ],
        },
    },
    type => {
        '0'  => 'Raspberry Pi Model A',                 # 00
        '1'  => 'Raspberry Pi Model B',                 # 01
        '2'  => 'Raspberry Pi Model A Plus',            # 02
        '3'  => 'Raspberry Pi Model B Plus',            # 03
        '4'  => 'Raspberry Pi 2 Model B',               # 04
        '5'  => 'Raspberry Pi Alpha',                   # 05
        '6'  => 'Raspberry Pi Compute Module 1',        # 06
        '7'  => 'UNKNOWN Raspberry Pi Model 07',        # 07
        '8'  => 'Raspberry Pi 3 Model B',               # 08
        '9'  => 'Raspberry Pi Zero',                    # 09
        '10' => 'Raspberry Pi Compute Module 3',        # 0A
        '11' => 'UNKNOWN Raspberry Pi Model 11',        # 0B
        '12' => 'Raspberry Pi Zero W',                  # 0C
        '13' => 'Raspberry Pi 3 Model B Plus',          # 0D
        '14' => 'Raspberry Pi 3 Model A Plus',          # 0E
        '15' => 'UNKNOWN Rasberry Pi Model 15',         # 0F
        '16' => 'Raspberry Pi Compute Module 3 Plus',   # 10
        '17' => 'Raspberry Pi 4 Model B',               # 11
        '18' => 'Raspberry Pi Zero 2 W',                # 12
        '19' => 'Raspberry Pi Model 400',               # 13
        '20' => 'Raspberry Pi Compute Module 4',        # 14
        '21' => 'Raspberry Pi Compute Module 4S',       # 15
    },
    board_type => {
        '0'  => $btype2,
        '1'  => $btype2,
        '2'  => $btype3,
        '3'  => $btype3,
        '4'  => $btype3,
        '5'  => $btype1,
        '6'  => $btype2,
        '7'  => $btype3,
        '8'  => $btype3,
        '9'  => $btype3,
        '10' => $btype4,
        '11' => $btype3,
        '12' => $btype3,
        '13' => $btype3,
        '14' => $btype3,
        '15' => $btype3,
        '16' => $btype4,
        '17' => $btype3,
        '18' => $btype3,
        '19' => $btype3,
        '20' => $btype4,
        '21' => $btype4,
    },
    release => {
        '0'  => 'Q1 2013',
        '1'  => 'Q3 2012',
        '2'  => 'Q4 2014',
        '3'  => 'Q3 2014',
        '4'  => 'Q1 2015',
        '5'  => 'Q1 2012',
        '6'  => 'Q2 2013',
        '7'  => 'Q2 2015',
        '8'  => 'Q1 2016',
        '9'  => 'Q4 2015',
        '10' => 'Q1 2017',
        '11' => 'unknown',
        '12' => 'Q1 2017',
        '13' => 'Q1 2018',
        '14' => 'Q4 2018',
        '15' => 'unknown',
        '16' => 'Q1 2019',
        '17' => 'Q2 2019',
        '18' => 'Q4 2021',
        '19' => 'Q4 2020',
        '20' => 'Q4 2020',
        '21' => 'Q4 2020',
    },
    extended_release => {
        'a03111' => 'Q2 2019', #	4B	1.1	1GB	Sony UK
        
        'b03111' => 'Q2 2019', #	4B	1.1	2GB	Sony UK
        'b03112' => 'Q1 2020', #	4B	1.2	2GB	Sony UK
        'b03114' => 'Q3 2020', #	4B	1.4	2GB	Sony UK
        'b03115' => 'Q1 2022', #	4B	1.5	2GB	Sony UK
        
        'c03111' => 'Q2 2019', # 	4B	1.1	4GB	Sony UK
        'c03112' => 'Q1 2020', #	4B	1.2	4GB	Sony UK
        'c03114' => 'Q2 2020', #	4B	1.4	4GB	Sony UK
        'c03115' => 'Q1 2022', #	4B	1.5	4GB	Sony UK
        
        'd03114' => 'Q2 2020', #	4B	1.4	8GB	Sony UK
        'd03115' => 'Q1 2022', #	4B	1.5	8GB	Sony UK
    },
);

my $_config = $_revstash{unknownex};

sub os_is_windows { return ( $^O =~ /^mswin/i ) ? 1 : 0; }

sub os_is_osx { return ( $^O =~ /^darwen/i ) ? 1 : 0; }

sub os_is_linux { return ( $^O =~ /^linux/i ) ? 1 : 0; }

sub os_is_other { return ( $^O !~ /^mswin|linux|darwen/i ) ? 1 : 0; }

sub os_supported { return ( $^O =~ /^linux/i ) ? 1 : 0; }

sub is_raspberry { return $israspberry; }

sub is_raspberry_2 { return $israspberry2; }

sub is_raspberry_3 { return $israspberry3; }

sub is_raspberry_4 { return $israspberry4; }

sub has_device_tree { return $hasdevicetree; }

sub home_directory { return $homedir; }

sub board_type { return $_config->{board_type}; }

sub gpio_header_type { return $_config->{board_type}; }

sub manufacturer { return $_config->{manufacturer}; }

sub release_date { return $_config->{release}; }

sub processor { return $_config->{processor}; }

sub hardware { return $_config->{hardware}; }

sub model_name { return $_config->{modelname}; }

sub revision { return $_config->{revision}; }

sub memory { return $_config->{memory}; }

sub serial_number { return $_config->{serial}; }

sub get_alt_function_names { return $_alt_function_names; }

sub alt_func_version { return $_alt_function_names_version; }

sub architecture_width { return $_config->{processor_info}->{architecture_width}; }

sub arm_core { return $_config->{processor_info}->{arm}; }

sub rasberrypi_os_support {
    return ( wantarray )
        ? @{ $_config->{processor_info}->{raspios_supported} }
        : join(', ', @{ $_config->{processor_info}->{raspios_supported} } );
}

sub number_of_cores { return $_config->{processor_info}->{cores}; }

sub board_description {
    my $description = 'Unknown board type';
    if($_config->{board_type} == $btype1 ) {
        $description = 'Type 1 26 pin GPIO header';
    } elsif($_config->{board_type} == $btype2 ) {
        $description = 'Type 2 26 pin GPIO header';
    } elsif($_config->{board_type} == $btype3 ) {
        $description = 'Type 3 40 pin GPIO header';
    } elsif($_config->{board_type} == $btype4 ) {
        $description = 'Type 4 Compute Module';
    }
    return $description;
}

sub _configure {
    
    my %_cpuinfostash = ();
    
    my $device_tree_boardname = '';
    
    if( os_is_linux() ) {
        # clean our path for safety
        local $ENV{PATH} = '/bin:/usr/bin:/usr/local/bin';
        my $output = qx(cat /proc/cpuinfo);
        
        if( $output ) {
            for ( split(/\n/, $output) ) {
                if( $_ =~ /^([^\s]+)\s*:\s(.+)$/ ) {
                    $_cpuinfostash{$1} = $2;
                }
            }
        }
        
        $hasdevicetree = ( -e '/proc/device-tree/soc/ranges' ) ? 1 : 0;
        if( $hasdevicetree ) {
            my $bname = qx(cat /proc/device-tree/model);
            chomp $bname;
            
            $device_tree_boardname = $bname if( $bname );
        }
    }
    
    my $hardware = ($_cpuinfostash{Hardware}) ?  $_cpuinfostash{Hardware} : 'BCM2709';
    my $serial = ($_cpuinfostash{Serial}) ?  $_cpuinfostash{Serial} : 'UNKNOWN';
    my $board_type = ( $hardware eq 'BCM2708' ) ? 2 : 3;
    my $defaultkey = ( $board_type == 3  ) ? 'unknownex' : 'unknown';
    my $rev = ($_cpuinfostash{Revision}) ?  lc( $_cpuinfostash{Revision} ) : $defaultkey;
    $rev =~ s/^\s+//;
    $rev =~ s/\s+$//;
        
    $israspberry = $_cpuinfostash{Hardware} && $_cpuinfostash{Hardware} =~ /^BCM(27|28)/;
        
    if ( $rev =~ /(beta|unknown|unknownex)$/) {
        my $infokey = exists($_revstash{$rev}) ? $rev : $defaultkey;
        $_config = { %{ $_revstash{$infokey} } };
        $_config->{processor} = 'BCM2835';
        $_config->{revision} = 'UNKNOWN';
    } else {
        # is this a scheme 0 or 1 number
        my $revnum = oct( '0x' . $rev );
        #          NOQuuuWuFMMMCCCCPPPPTTTTTTTTRRRR
        #                  ^
        my $rev_scheme_new_type = ( $revnum >> 23 ) & 1;
        
        if ( $rev_scheme_new_type ) {
            #            NOQuuuWuFMMMCCCCPPPPTTTTTTTTRRRR

            # revision                               RRRR
            my $s_revision  =                      0b1111 & $revnum;
            # raspberry type                 TTTTTTTT
            my $s_raspberry_type =       ( 0b111111110000 & $revnum ) >> 4;
            # processor                  PPPP
            my $s_processor =        ( 0b1111000000000000 & $revnum ) >> 12;
            # manufacturer           CCCC
            my $s_manufacturer = ( 0b11110000000000000000 & $revnum ) >> 16;
            # memory              MMM
            my $s_memory =    ( 0b11100000000000000000000 & $revnum ) >> 20;           
            # warranty   NOQuuuWuFMMMCCCCPPPPTTTTTTTTRRRR
            #                  ^
            my $s_warranty    = ( $revnum >> 25 ) & 1;
            # otp read   NOQuuuWuFMMMCCCCPPPPTTTTTTTTRRRR
            #              ^
            my $s_otp_read    = ( $revnum >> 29 ) & 1;
            # otp prog   NOQuuuWuFMMMCCCCPPPPTTTTTTTTRRRR
            #             ^
            my $s_otp_prog    = ( $revnum >> 30 ) & 1;
            # no o volt  NOQuuuWuFMMMCCCCPPPPTTTTTTTTRRRR
            #            ^
            my $s_no_overvolt = ( $revnum >> 31 ) & 1;
            
            # base type
            my $binfo = $_revstash{$defaultkey};
                        
            $binfo->{release}  = $_revinfostash{extended_release}->{$rev} || $_revinfostash{release}->{$s_raspberry_type} || 'Q1 2015';
            $binfo->{model_name} = $_revinfostash{type}->{$s_raspberry_type} || qq(Unknown Raspberry Pi Type : $s_raspberry_type);
            $binfo->{model_name} = $device_tree_boardname if $device_tree_boardname;
            $binfo->{memory}   = $_revinfostash{memsize}->{$s_memory} || 256;
            $binfo->{manufacturer} = $_revinfostash{manufacturer}->{$s_manufacturer} || 'Sony';
            $binfo->{board_type} =  $_revinfostash{board_type}->{$s_raspberry_type} || $board_type;
            $binfo->{processor} = $_revinfostash{processor}->{$s_processor} || 'BCM2835';
            $binfo->{revision} = $rev;
            $binfo->{revisionnumber} = $s_revision;
            $binfo->{processor_info} = $_revinfostash{processor_info}->{$binfo->{processor}};
            
            $israspberry2 = ( $s_raspberry_type == 4 ) ? 1 : 0;
            $israspberry3 = ( $s_raspberry_type == 8  ||
                              $s_raspberry_type == 10 ||
                              $s_raspberry_type == 13 ||
                              $s_raspberry_type == 14 ||
                              $s_raspberry_type == 16 ||
                              $s_raspberry_type == 18 ) ? 1 : 0;
            $israspberry4 = ( $s_raspberry_type == 17 ) ? 1 : 0;
            
            $_config = { %$binfo };
        } else {
            my $infokey = exists($_revstash{$rev}) ? $rev : $defaultkey;
            $_config = { %{ $_revstash{$infokey} } };
            $_config->{processor} = 'BCM2835';
            $_config->{revisionnumber} = 0;
        }
        
    }    
   
    # Home Dir
    if( os_is_windows ) {
        require Win32;
        $homedir = Win32::GetFolderPath( 0x001C, 1);
        $homedir = Win32::GetShortPathName( $homedir );
        $homedir =~ s/\\/\//g;
    } else {
        $homedir = (getpwuid($<))[7];
    }
    
    $_config->{hardware} = $hardware;
    $_config->{serial}  = $serial;
    
    if($_config->{processor} eq 'BCM2711' ) {
        $_alt_function_names = \@_alt_func_names_2711;
        $_alt_function_names_version = 2;
    } else {
        $_alt_function_names = \@_alt_func_names_2708;
        $_alt_function_names_version = 1;
    }
    
    return;
}



sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return  $self;
}

sub validpins {
    my $type = board_type();
    if ( $type == 1 ) {
        return ( 0, 1, 4, 7, 8, 9, 10, 11, 14, 15, 17, 18, 21, 22, 23, 24, 25 );
    } elsif ( $type == 2 ) {    
        return ( 2, 3, 4, 7, 8, 9, 10, 11, 14, 15, 17, 18, 22, 23, 24, 25, 27, 28, 29, 30, 31 );
    } else {
        # return current latest known pinset
        return ( 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27 );
    }
}

sub dump_board_info {
    my $processor = $_config->{processor};
    my $dump = qq(--------------------------------------------------\n);
    $dump .= qq(Raspberry Pi Board Info\n);
    $dump .= qq(--------------------------------------------------\n);
    $dump .= qq(Model Name       : $_config->{model_name}\n);
    $dump .= qq(Released         : $_config->{release}\n);
    $dump .= qq(Manufacturer     : $_config->{manufacturer}\n);
    $dump .= qq(Memory           : $_config->{memory}\n);
    $dump .= qq(Processor        : $processor\n);
    $dump .= qq(Hardware         : $_config->{hardware}\n);
    my $description = board_description();
    $dump .= qq(Description      : $description\n);
    $dump .= qq(Revision         : $_config->{revision}\n);
    $dump .= qq(Serial Number    : $_config->{serial}\n);
    $dump .= qq(GPIO Header Type : $_config->{board_type}\n);
    $dump .= qq(Revision Number  : $_config->{revisionnumber}\n);
    my $devtree = ( has_device_tree() ) ? 'Yes' : 'No';
    
    $dump .= qq(Device Tree      : $devtree\n);
    $dump .= q(Is Raspberry     : ) . (($israspberry) ? 'Yes' : 'No' ) . qq(\n);
    $dump .= q(Is Raspberry 2   : ) . (($israspberry2) ? 'Yes' : 'No' ) . qq(\n);
    $dump .= q(Is Raspberry 3   : ) . (($israspberry3) ? 'Yes' : 'No' ) . qq(\n);
    $dump .= q(Is Raspberry 4   : ) . (($israspberry4) ? 'Yes' : 'No' ) . qq(\n);
    
    $dump .= q(Alt Function Map : Version ) . alt_func_version() . qq(\n);
    
    $dump .= qq(ARM Core         : ) . arm_core() . qq(\n);
    $dump .= qq(Number of Cores  : ) . number_of_cores() . qq(\n);
    $dump .= qq(Architecture     : Width ) . architecture_width() . qq( bit\n);
    $dump .= qq(OS arch support  : ) . rasberrypi_os_support() . qq(\n);
    
    return $dump;
}

_configure();

1;

__END__