#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

# writes operate directly over UART so this is the easiest to unit test
use Device::Chip::NoritakeGU_D;

my $chip = Device::Chip::NoritakeGU_D->new( interface => "UART" );

$chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
)->get;

# We won't test -everything- because they're all quite simple and largely just
# copy-paste implementations. But a few separate ones would be good

# A bool-taking command
{
   $adapter->expect_write( "\x1F\x43\x01" );

   $chip->set_cursor_visible( 1 )->get;

   $adapter->check_and_clear( '$chip->set_cursor_visible' );
}

# An int-taking command
{
   $adapter->expect_write( "\x1F\x58\x04" );

   $chip->set_brightness( 4 )->get;

   $adapter->check_and_clear( '$chip->set_brightness' );
}

# An enum-taking command
{
   $adapter->expect_write( "\x1F\x77\x01" );

   $chip->set_write_mixture_display_mode( "or" )->get;

   $adapter->check_and_clear( '$chip->set_write_mixture_display_mode' );
}

# Now the special ones

{
   $adapter->expect_write( "\x1F\x24\x0F\x00\x02\x00" );
   $chip->cursor_goto( 15, 2 )->get;
   $adapter->check_and_clear( '$chip->cursor_goto' );
}

done_testing;
