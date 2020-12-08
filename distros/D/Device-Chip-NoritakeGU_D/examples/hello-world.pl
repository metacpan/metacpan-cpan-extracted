#!/usr/bin/perl

use v5.26;
use warnings;

use Device::Chip::NoritakeGU_D;
use Device::Chip::Adapter;

use Future::AsyncAwait;
use Getopt::Long qw( :config no_ignore_case );
use Time::HiRes qw( sleep );

GetOptions(
   'i|interface=s' => \(my $INTERFACE = "I2C"),
   'adapter|A=s' => \( my $ADAPTER ),
   'mount|M=s'   => \( my $MOUNTPARAMS ),
) or exit 1;

my $chip = Device::Chip::NoritakeGU_D->new( interface => $INTERFACE );

await $chip->mount_from_paramstr(
   Device::Chip::Adapter->new_from_description( $ADAPTER ),
   $MOUNTPARAMS,
);

await $chip->power(1);

await $chip->initialise;

# Default font
await $chip->cursor_goto( 20, 0 );
await $chip->text( "Hello, world" );

# Proportional font
await $chip->set_font_width( "prop2" );
await $chip->cursor_goto( 26, 1 );
await $chip->text( "Hello, world" );

# Large font
await $chip->set_font_size( "8x16" );
await $chip->cursor_goto( 15, 2 );
await $chip->text( "Hello, world" );
