#!/usr/bin/perl

# USAGE:
# to get flags and save in local directory './flags'
#	./get_flags.pl
#
# to print list of Country Codes, CIA codes => Country Name
#	./get_flags.pl names	{any text will do}
#
# routine gets flags from CIA and stores as country code flagname
#
# version 1.01, 9-15-06, michael@bizsystems.com

use Geo::CountryFlags;
use Geo::CountryFlags::ISO;
use Geo::CountryFlags::I2C;
my $iso = hashptr Geo::CountryFlags::ISO;
my $i2c = hashptr Geo::CountryFlags::I2C;
my %riso = reverse %$iso;

my $gf = new Geo::CountryFlags;

unless (@ARGV) {
  foreach(keys %$i2c) {
    $gf->get_flag($_);
  }
} else {
  my %riso = reverse %$iso;
  foreach (sort keys %riso) {
    my $cc	= $riso{$_};
    next unless exists $i2c->{$cc};
    my $cia	= $i2c->{$cc};
    print "$cc => cia $cia, => $_\n";
  }
}
