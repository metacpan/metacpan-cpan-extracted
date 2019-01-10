#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Future;

use Future::AsyncAwait;

my @f;

sub set_dc { push @f, my $f = Future->new; return $f; }
sub readwrite { Future->done( $_[0] ) }

# Inspired by Device::Chip::SSD1306::SPI4::send_cmd
async sub send_cmd
{
   my $self = shift;
   my @vals = @_;

   await set_dc();
   await readwrite( join "", map { chr } @vals );
}

# Inspired by Device::Chip::SSD1306::init
async sub init
{
   my $self = shift;

   await $self->send_cmd( 1, 2 );
   await $self->send_cmd( 3, 4 );
}

{
   my $f = __PACKAGE__->init;

   # Pump Futures
   ( shift @f )->done() while @f;

   is( $f->get, "\x03\x04", 'result' );
}

done_testing;
