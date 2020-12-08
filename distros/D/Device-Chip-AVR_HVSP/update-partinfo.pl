#!/usr/bin/perl

use v5.26;
use warnings;
use 5.010;

use Device::AVR::Info;
use File::Find;
use List::UtilsBy qw( sort_by );

my $pmpath = "lib/Device/BusPirate/Chip/AVR_HVSP.pm";
my $devpath = shift @ARGV;

open my $in, "<", $pmpath or
   die "Cannot read $pmpath - $!";

print STDERR "Loading devices from $devpath...\n";

my @devices;
find( sub {
   return unless m/\.xml/;

   my $avr = Device::AVR::Info->new_from_file( $_ );
   return unless $avr->can_interface( 'HVSP' );

   push @devices, $avr;
}, $devpath );

print STDERR "Updating file...\n";

open my $out, ">", "$pmpath.NEW" or
   die "Cannot write $pmpath.NEW - $!";

while( <$in> ) {
   print $out $_;
   last if m/^__DATA__$/;
}

print $out "# name       = Sig    Flash sz EEPROM sz efuse\n";

my %have_sig;
foreach my $avr ( sort_by { $_->name } @devices ) {
   next if $have_sig{$avr->signature}++;

   my $flash  = ( $avr->can_memory( 'prog' )->segments )[0];
   my $eeprom = ( $avr->can_memory( 'eeprom' )->segments )[0];
   my $fuses  = $avr->can_memory( 'fuses' );

   printf $out "%-12s = %s %5d %2d   %4d %2d %d\n",
      $avr->name,
      uc $avr->signature,
      $flash->size / 2,     # words
      $flash->pagesize / 2, # words/page
      $eeprom->size,
      $eeprom->pagesize,
      $fuses->size > 2;
}

rename $pmpath, "$pmpath.bak" and rename "$pmpath.NEW", $pmpath or
   die "Cannot rename - $!";

print STDERR "Done\n";
