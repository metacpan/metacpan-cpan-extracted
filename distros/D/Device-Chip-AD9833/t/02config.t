#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Device::Chip::AD9833;

my $chip = Device::Chip::AD9833->new;

$chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
)->get;

# ->read_config
{
   # Chip can't read back config; we just store this in memory

   is_deeply( $chip->read_config->get,
      {
         B28     => !!0,
         HLB     => !!0,
         FSELECT => !!0,
         PSELECT => !!0,
         SLEEP1  => !!0,
         SLEEP12 => !!0,
         OPBITEN => !!0,
         DIV2    => !!0,
         MODE    => !!0,

         # derived fields
         wave => "sine",
      },
      '$chip->read_config'
   );

   $adapter->check_and_clear( '->read_config' );
}

# ->change_config
{
   $adapter->expect_write( "\x20\x02" ); # B28, MODE

   $chip->change_config( MODE => 1 )->get;

   $adapter->check_and_clear( '->change_config' );
}

# 'wave' derived field
{
   $adapter->expect_write( "\x20\x28" ); # B28, OPBITEN, DIV2

   $chip->change_config( wave => "square" )->get;

   $adapter->check_and_clear( '->change_config' );
}

done_testing;
