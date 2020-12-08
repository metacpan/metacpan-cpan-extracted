#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

# writes operate directly over UART so this is the easiest to unit test
use Device::Chip::NoritakeGU_D;

my $chip = Device::Chip::NoritakeGU_D->new( interface => "UART" );

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# We won't test -everything- because they're all quite simple and largely just
# copy-paste implementations. But a few separate ones would be good

# A bool-taking command
{
   $adapter->expect_write( "\x1F\x43\x01" );

   await $chip->set_cursor_visible( 1 );

   $adapter->check_and_clear( '$chip->set_cursor_visible' );
}

# An int-taking command
{
   $adapter->expect_write( "\x1F\x58\x04" );

   await $chip->set_brightness( 4 );

   $adapter->check_and_clear( '$chip->set_brightness' );
}

# An enum-taking command
{
   $adapter->expect_write( "\x1F\x77\x01" );

   await $chip->set_write_mixture_display_mode( "or" );

   $adapter->check_and_clear( '$chip->set_write_mixture_display_mode' );
}

# Now the special ones

{
   $adapter->expect_write( "\x1F\x24\x0F\x00\x02\x00" );
   await $chip->cursor_goto( 15, 2 );
   $adapter->check_and_clear( '$chip->cursor_goto' );
}

done_testing;
