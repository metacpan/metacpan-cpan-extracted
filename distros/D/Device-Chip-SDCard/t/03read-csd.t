#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter 0.05;  # ->expect_assert_ss, etc..

use Future::AsyncAwait;

use Device::Chip::SDCard;

my $chip = Device::Chip::SDCard->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# v0 reply
{
   $adapter->expect_assert_ss;
   $adapter->expect_write_no_ss( "\x49\x00\x00\x00\x00\xFF\xFF" );
   $adapter->expect_readwrite_no_ss( "\xFF" x 8 )
      ->returns( "\xFF\x00\xFF\xFF\xFF\xFF\xFF\xFE" );
   $adapter->expect_readwrite_no_ss( "\xFF" x 18 )
      ->returns( "\x00\x6F\x00\x32\x5B\x5A\x83\xC0\x76\xDB\xDF\xFF\x0A\x80" . "\xFF\xFF" );
   $adapter->expect_release_ss;

   is( await $chip->read_csd,
      {
         TAAC                => "60ms",
         NSAC                => "0ck",
         TRAN_SPEED          => "25Mbit/s",
         CCC                 => [ 0, 2, 4, 5, 7, 8, 10 ],
         READ_BL_LEN         => 1024,
         READ_BL_LEN_PARTIAL => 1,
         WRITE_BLK_MISALIGN  => 0,
         READ_BLK_MISALIGN   => 0,
         DSR_IMP             => 0,
         C_SIZE              => 3841,
         VDD_R_CURR_MIN      => "60mA",
         VDD_R_CURR_MAX      => "80mA",
         VDD_W_CURR_MIN      => "60mA",
         VDD_W_CURR_MAX      => "80mA",
         C_SIZE_MULT         => 7,
         ERASE_BLK_EN        => 1,
         SECTOR_SIZE         => 64,
         WP_GRP_SIZE         => 128,
         WP_GRP_ENABLE       => 0,
         R2W_FACTOR          => 4,
         WRITE_BL_LEN        => 1024,
         WRITE_BL_PARTIAL    => 0,
         FILE_FORMAT_GRP     => 1,
         COPY                => 1,
         PERM_WRITE_PROTECT  => 1,
         TEMP_WRITE_PROTECT  => 1,
         FILE_FORMAT         => 3,

         # derived fields
         blocks => 1967104,
         bytes  => 2014314496,
      },
      '$chip->read_csd returns CSD fields' );

   $adapter->check_and_clear( '$chip->read_csd' );
}

done_testing;
