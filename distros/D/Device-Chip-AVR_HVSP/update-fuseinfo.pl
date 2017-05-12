#!/usr/bin/perl

use strict;
use warnings;
use 5.010;

use Device::AVR::Info;
use List::UtilsBy qw( extract_by );

my @devices;
my %output_by_device;

my $pmpath = "lib/Device/BusPirate/Chip/AVR_HVSP/FuseInfo.pm";

open my $in, "<", $pmpath or
   die "Cannot read $pmpath - $!";

print STDERR "Loading devices...\n";

foreach my $devpath ( @ARGV ) {
   my $avr = Device::AVR::Info->new_from_file( $devpath );

   # Only do the HVSP-capable devices
   $avr->interface( "HVSP" ) or next;

   my $fuses = $avr->peripheral( 'FUSE' );
   $fuses->regspace->name eq 'fuses' or
      die "Expected FUSES peripheral to exist in the 'fuses' address space\n";

   my $output = "";

   foreach my $reg ( $fuses->registers ) {
      # Database doesn't give us a combined bitmask. We'll fake it
      my $mask = 0; $mask |= $_->mask for $reg->bitfields;

      $output .= "MASK ${\$reg->offset} $mask\n";

      foreach my $field ( $reg->bitfields ) {
         # It's a bitfield if the count of bits set is 1
         if( 1 == grep { $field->mask & 1<<$_ } 0 .. 7 ) {
            $field->values and die "Expected a bitfield not to have enumerated values\n";
            $output .= "BIT ${\$field->name} ${\$reg->offset} ${\$field->mask}: ${\$field->caption}\n";
         }
         else {
            my @values = $field->values or die "Expected an enum field to have values\n";
            $output .= "ENUM ${\$field->name} ${\$reg->offset} ${\$field->mask}: ${\$field->caption}\n";
            $output .= "  VALUE ${\$_->name} ${\$_->value}: ${\$_->caption}\n" for @values;
         }
      }
   }

   push @devices, $avr->name;
   $output_by_device{$avr->name} = $output;
}

print STDERR "Updating file...\n";

open my $out, ">", "$pmpath.NEW" or
   die "Cannot write $pmpath.NEW - $!";

while( <$in> ) {
   print $out $_;
   last if m/^__DATA__$/;
}

while( @devices ) {
   my $device = shift @devices;
   my $output = $output_by_device{$device};

   print $out "DEVICE name=$device\n";

   # Now find all the other devices with the same info
   print $out "DEVICE name=$_\n" for extract_by { $output_by_device{$_} eq $output } @devices;

   print $out $output;
   print $out "\n";
}

rename $pmpath, "$pmpath.bak" and rename "$pmpath.NEW", $pmpath or
   die "Cannot rename - $!";

print STDERR "Done\n";
