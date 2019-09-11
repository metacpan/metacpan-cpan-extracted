#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Device::Chip::CC1101;

my $chip = Device::Chip::CC1101->new;

$chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
)->get;

# ->read_config
{
   # Power-up defaults
   # CONFIG
   $adapter->expect_write_then_read( "\xC0", 41 )
      ->returns( "\x29\x2E\x3F\x07\xD3\x91\xFF\x04\x45\x00\x00\x0F\x00\x1E\xC4\xEC" .
                 "\x8C\x22\x02\x22\xF8\x47\x07\x30\x04\x36\x6C\x03\x40\x91\x87\x6B" .
                 "\xF8\x56\x10\xA9\x0A\x20\x0D\x41\x00" );
   # PATABLE
   $adapter->expect_write_then_read( "\xFE", 8 )
      ->returns( "\xC6\x00\x00\x00\x00\x00\x00\x00" );

   my %config = $chip->read_config->get;

   is_deeply(
      { $chip->read_config->get },
      {
         # IOCFG2
         GDO2_INV              => '',
         GDO2_CFG              => "CHIP_RDYn",
         # IOCFG1
         GDO_DS                => "low",
         GDO1_INV              => '',
         GDO1_CFG              => "hiZ",
         # IOCFG0
         TEMP_SENSOR_ENABLE    => '',
         GDO0_INV              => '',
         GDO0_CFG              => "CLK_XOSC/196",
         # FIFOTHR
         ADC_RETENTION         => '',
         CLOSE_IN_RX           => "0dB",
         FIFO_THR              => 7,
         # SYNC
         SYNC                  => 0xD391,
         # PKTLEN
         PACKET_LENGTH         => 255,
         # PKTCTRL1
         PQT                   => 0,
         CRC_AUTOFLUSH         => '',
         APPEND_STATUS         => 1,
         ADR_CHK               => "none",
         # PKTCTRL0
         WHITE_DATA            => 1,
         PKT_FORMAT            => "fifo",
         CRC_EN                => 1,
         LENGTH_CONFIG         => "variable",
         # ADDR
         DEVICE_ADDR           => 0,
         # CHANNR
         CHAN                  => 0,
         # FSCTRL1
         FREQ_IF               => 15,
         # FSCTRL0
         FREQOFF               => 0,
         # FREQ0..2
         FREQ                  => 2016492,
         # MDMCFG4
         CHANBW_E              => 2,
         CHANBW_M              => 0,
         DRATE_E               => 12,
         # MDMCFG3
         DRATE_M               => 34,
         # MDMCFG2
         DEM_DCFILT_OFF        => '',
         MOD_FORMAT            => "2-FSK",
         MANCHESTER_EN         => '',
         SYNC_MODE             => "16/16",
         # MDMCFG1
         FEC_EN                => '',
         NUM_PREAMBLE          => "4B",
         CHANSPC_E             => 2,
         # MDMCFG0
         CHANSPC_M             => 248,
         # DEVIATN
         DEVIATION_E           => 4,
         DEVIATION_M           => 7,
         # MSCM2
         RX_TIME_RSSI          => '',
         RX_TIME_QUAL          => '',
         RX_TIME               => 7,
         # MSCM1
         CCA_MODE              => "rssi-unless-rx",
         RXOFF_MODE            => "IDLE",
         TXOFF_MODE            => "IDLE",
         # MSCM0
         FS_AUTOCAL            => "never",
         PO_TIMEOUT            => "x16",
         PIN_CTRL_EN           => '',
         XOSC_FORCE_ON         => '',
         # FOCCFG
         FOC_BS_CS_GATE        => 1,
         FOC_PRE_K             => "3K",
         FOC_POST_K            => "K/2",
         FOC_LIMIT             => "BW/4",
         # BSCFG
         BS_PRE_KI             => "2KI",
         BS_PRE_KP             => "3KP",
         BS_POST_KI            => "KI/2",
         BS_POST_KP            => "KP",
         BS_LIMIT              => 0,
         # AGCCTRL2
         MAX_DVGA_GAIN         => "max",
         MAX_LNA_GAIN          => "max",
         MAGN_TARGET           => "33dB",
         # AGCCTRL1
         AGC_LNA_PRIORITY      => "lna2-first",
         CARRIER_SENSE_REL_THR => "disabled",
         CARRIER_SENSE_ABS_THR => "at-magn-target",
         # AGCCTRL0
         HYST_LEVEL            => "medium",
         WAIT_TIME             => "16sa",
         AGC_FREEZE            => "never",
         FILTER_LENGTH         => "16sa",
         # WOREVT0..1
         EVENT0                => 0x876B,
         # WORCTRL
         RC_PD                 => 1,
         EVENT1                => "48clk",
         RC_CAL                => 1,
         WOR_RES               => "1P",
         # FREND1
         LNA_CURRENT           => 1,
         LNA2MIX_CURRENT       => 1,
         LODIV_BUF_CURRENT_RX  => 1,
         MIX_CURRENT           => 2,
         # FREND0
         LODIV_BUF_CURRENT_TX  => 1,
         PA_POWER              => 0,
         # FSCAL0..3
         FSCAL                 => 0xA90A200D,
         # RCCTRL0..1
         RCCTRL                => 0x4100,
         # PATABLE
         PATABLE               => "C6.00.00.00.00.00.00.00",

         # Derived fields
         carrier_frequency     => "800.000MHz",
         channel_spacing       => "199.951kHz",
         deviation             => "47.607kHz",
         data_rate             => "115.1kbps",
      },
      '->read_config yields config'
   );

   $adapter->check_and_clear( '->read_config' );
}

# ->change_config
{
   $adapter->expect_write( "\x46" . "\x08\x04\x44" );

   $chip->change_config(
      PACKET_LENGTH => 8,
      LENGTH_CONFIG => "fixed",
   )->get;

   $adapter->check_and_clear( '->change_config' );
}

# ->change_config on PATABLE
{
   $adapter->expect_write( "\x7E" . "\x03\x0F\x1E\x27\x50\x81\xCB\xC2" );

   $chip->change_config(
      PATABLE => "03.0F.1E.27.50.81.CB.C2",
   )->get;

   $adapter->check_and_clear( '->change_config on PATABLE' );
}

# presets
{
   $adapter->expect_write( "\x4B" .
      "\x08\x00\x21\x65\x6A\x5B\xF8\x13\xA0\xF8\x47\x07\x0C\x18\x1D\x1C\xC7\x00\xB2\x87\x6B\xF8\xB6\x17\xEA\x0A\x00\x11"
   );

   $chip->change_config(
      mode => "GFSK-100kb",
   )->get;

   $adapter->check_and_clear( '->change_config preset mode' );
}

# bands
{
   # CONFIG
   $adapter->expect_write( "\x4D" . "\x10\xA7\x62" );
   # PATABLE
   $adapter->expect_write( "\x7E" . "\x12\x0E\x1D\x34\x60\x84\xC8\xC0" );

   $chip->change_config(
      band => "433MHz",
   )->get;

   $adapter->check_and_clear( '->change_config band' );
}

done_testing;
