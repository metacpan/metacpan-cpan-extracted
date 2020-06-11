#!/usr/bin/perl

use strict;
use warnings;

use Device::Chip::NoritakeGU_D;
use Device::Chip::Adapter;
use Getopt::Long qw( :config no_ignore_case );
use Time::HiRes qw( sleep );

GetOptions(
   'i|interface=s' => \(my $INTERFACE = "I2C"),
   'adapter|A=s' => \( my $ADAPTER ),
   'mount|M=s'   => \( my $MOUNTPARAMS ),
) or exit 1;

my $chip = Device::Chip::NoritakeGU_D->new( interface => $INTERFACE );

$chip->mount_from_paramstr(
   Device::Chip::Adapter->new_from_description( $ADAPTER ),
   $MOUNTPARAMS,
)->get;

$chip->power(1)->get;

$chip->initialise->get;

# Default font
$chip->cursor_goto( 20, 0 )->get;
$chip->text( "Hello, world" )->get;

# Proportional font
$chip->set_font_width( "prop2" )->get;
$chip->cursor_goto( 26, 1 )->get;
$chip->text( "Hello, world" )->get;

# Large font
$chip->set_font_size( "8x16" )->get;
$chip->cursor_goto( 15, 2 )->get;
$chip->text( "Hello, world" )->get;
